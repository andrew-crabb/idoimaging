#! /usr/local/bin/perl -w

# calculateRanking.pl
# Calculate a metric describing the popularity of this program.
# Factors: Google links, No. of monitors, No of link-tos past week.
# Each factor assigned a percentile of total population.
# Each factor equally weighted.
use strict;

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
# my $query = "select ident, name, linkcnt, percentile, rank_overall "
# $query   .= "from program ";
# $query   .= "where ident >= 100 $progstr order by name";
my $query = "select program.ident, program.name, program.linkcnt, program.percentile, program.rank_overall, ";
$query   .= "count(*) as nmon, ";
$query   .= "(select count(*) from redirect ";
$query   .= "where program.ident = redirect.progid ";
$query   .= "and date >= date_add(curdate(), interval - 7 day)) as nredir ";
$query   .= "from program join monitor on program.ident = monitor.progid ";
$query   .= "where program.ident > 100 $progstr ";
$query   .= "group by program.ident ";
$query   .= "order by name";
my $psh = dbQuery($dbh, $query, $verbose);

my %progs = ();
my %newrank = ();
my %oldrank = ();
my $progs = $psh->fetchall_arrayref();
foreach my $prog (@$progs) {
  my ($ident, $name, $linkcnt, $percent, $rank_overall, $monitors, $visits) = @$prog;
  $oldrank{$ident} = [$percent, $name];
  printf("%3d %-20s link %3d mon %3d vis %3d rank %3d\n", $ident, substr($name, 0, 20), 
    $linkcnt, $monitors, $visits, $rank_overall);
  $progs{$ident} = [$name, $linkcnt, $monitors, $visits, $rank_overall];
}

my @bylinkcnt = sort {$progs{$a}[1] <=> $progs{$b}[1]} keys %progs;
my @bymonitor = sort {$progs{$a}[2] <=> $progs{$b}[2]} keys %progs;
my @byvisitor = sort {$progs{$a}[3] <=> $progs{$b}[3]} keys %progs;

# my @idents = sort keys %progs;
my @idents = sort {$progs{$a}[0] cmp $progs{$b}[0]}  keys %progs;
foreach my $ident (@idents) {
  my ($ilinks, $imonit, $ivisit) = (-1, -1, -1);
  
  my $nprogs = $#idents;
  foreach my $i (0..$nprogs) {
    $ilinks = $i if (($ilinks < 0) and $bylinkcnt[$i] == $ident);
    $imonit = $i if (($imonit < 0) and $bymonitor[$i] == $ident);
    $ivisit = $i if (($ivisit < 0) and $byvisitor[$i] == $ident);
  }

  # Currently each ranking factor is equally weighted.
  my @ranks_overall = (0.0, 0.25, 0.5, 0.85, 1.0);
  my $rank_plain    = ($ilinks + $imonit + $ivisit) / 3;      
  my $percentile_plain    = int($rank_plain    * 100 / scalar(@idents));
  my $rank_overall = $progs{$ident}[4];
  my ($rank_weighted, $percentile_weighted) = (undef, undef);
  if ($rank_overall) {
    my $rank_ahc = $ranks_overall[$rank_overall - 1] * $nprogs;
    $rank_weighted = ($ilinks + $imonit + $ivisit + $rank_ahc) / 4;
    $percentile_weighted = int($rank_weighted * 100 / scalar(@idents));
#    printf("rank_overall %d rank_ahc %d rank_weighted %d percentile_weighted %d\n", 
#      $rank_overall, $rank_ahc, $rank_weighted, $percentile_weighted);
  }

  my $percentile = ($rank_overall) ? $percentile_weighted : $percentile_plain;
  $newrank{$ident} = $percentile;
  my $name = substr($progs{$ident}[0], 0, 20);
  $rank_overall //= '';
  my $weight_str = (has_len($percentile_weighted)) ? sprintf("%3d", $percentile_weighted) : '';
  printf("%-20s (%3d): lin %3d mon %3d vis %3d overall %2d, pc plain %3d, pc weight %3s : %3d\n", 
    $name, $ident, $ilinks, $imonit, $ivisit, $rank_overall, $percentile_plain, $weight_str, $percentile);
  
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
