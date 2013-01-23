#! /usr/local/bin/perl -w

# calculateRanking.pl
# Calculate a metric describing the popularity of this program.
# Factors: Google links, No. of monitors, No of link-tos past week.
# Each factor assigned a percentile of total population.
# Each factor equally weighted.

use DBI;
use FindBin qw($Bin);
use lib $Bin;
use Utility;
use radutils;
use Getopt::Std;

# Options: (V)erbose.
my %opts;
getopts('v', \%opts);	
my $verbose = ($opts{'v'}) ? 1 : 0;
# Ranking weighting.
my ($rlinks, $rmonit, $rvisit, $update) = (0.3,  0.3, 0.3, 0.1);

my $dbh = hostConnect();

my $progstr = (scalar(@ARGV)) ? "and name like '\%$ARGV[0]\%'" : "";
my $query = "select ident, name, linkcnt, percentile from program ";
$query   .= "where ident >= 100 $progstr order by name";
my $psh = dbQuery($dbh, $query);

my %progs = ();
my %newrank = ();
my %oldrank = ();
my $progs = $psh->fetchall_arrayref();
foreach my $prog (@$progs) {
  my ($ident, $name, $linkcnt, $percent) = @$prog;
  $oldrank{$ident} = [$percent, $name];
  # Monitor count
  my $sqlstr = "select count(*) from monitor where progid = '$ident'";
  $sh = dbQuery($dbh, $sqlstr);
  my ($monitors) = $sh->fetchrow_array();
  # Link-to count
  $sqlstr = "select count(*) from redirect where progid = '$ident' and date >= date_add(curdate(), interval - 7 day)";
  $sh = dbQuery($dbh, $sqlstr);
  my ($visits) = $sh->fetchrow_array();
  printf("%3d %-20s l %3d m %3d v %3d\n", $ident, substr($name, 0, 20), $linkcnt, $monitors, $visits);
  $progs{$ident} = [$name, $linkcnt, $monitors, $visits];
}

my @bylinkcnt = sort {$progs{$a}[1] <=> $progs{$b}[1]} keys %progs;
my @bymonitor = sort {$progs{$a}[2] <=> $progs{$b}[2]} keys %progs;
my @byvisitor = sort {$progs{$a}[3] <=> $progs{$b}[3]} keys %progs;

my @idents = sort keys %progs;
foreach my $ident (@idents) {
  my ($ilinks, $imonit, $ivisit) = (-1, -1, -1);
  
  foreach my $i (0..$#idents) {
    $ilinks = $i if (($ilinks < 0) and $bylinkcnt[$i] == $ident);
    $imonit = $i if (($imonit < 0) and $bymonitor[$i] == $ident);
    $ivisit = $i if (($ivisit < 0) and $byvisitor[$i] == $ident);
  }
  # Currently each ranking factor is equally weighted.
  my $rank = ($ilinks + $imonit + $ivisit) / 3;
  $percentile = int($rank * 100 / scalar(@idents));
  $newrank{$ident} = $percentile;
  my $name = substr($progs{$ident}[0], 0, 20);
  printf("%-20s (%3d): lin %3d mon %3d vis %3d: %3d\n", $name, $ident, $ilinks, $imonit, $ivisit, $percentile);
  
  my $sqlstr = "update program set percentile = $percentile where ident = '$ident'";
  dbQuery($dbh, $sqlstr);
}

if ($verbose) {
  print "Ranking summary:\n";
  foreach my $ident (sort {$newrank{$b} <=> $newrank{$a}} keys %newrank) {
    my ($oldpercent, $name) = @{$oldrank{$ident}};
    $name = substr($name, 0, 20);
    my $newpercent = $newrank{$ident};
    my $diff = $newpercent - $oldpercent;
    $diff = "" unless ($diff != 0);
    printf("%3d %-20s oldpc %3d newpc %3d diff %3s\n", $ident, $name, $oldpercent, $newpercent, $diff);
  }
}
