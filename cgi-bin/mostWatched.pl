#! /usr/local/bin/perl -w

# mostWatched.pl
# Generates a table listing which programs have the most monitors.

use strict;
no strict 'refs';

use CGI;
use DBI;
use FindBin qw($Bin);
use lib $Bin;
use Utility;
use radutils;
use Getopt::Std;

# Options: (V)erbose.
my %opts;
getopts('vn', \%opts);	
my $verbose = ($opts{'v'}) ? 1 : 0;
my $noheader = ($opts{'n'}) ? 1 : 0;

my $cgi = new CGI;
my $dbh = hostConnect();

my $str = "select monitor.progid, program.name, count(*) as cnt ";
$str   .= "from monitor, program ";
$str   .= "where monitor.progid = program.ident ";
$str   .= "and program.remdate like '0000%' ";
$str   .= "group by progid ";
$str   .= "order by cnt desc ";
$str   .= "limit 10";

my $sh = dbQuery($dbh, $str);

my $outstr = "<table border='1' cellspacing='0' cellpadding='2'>\n";
$outstr .= "<tr>\n";
$outstr .= "<th width='20' class='noborderright'>&nbsp;</th>";
$outstr .= "<th colspan='2' align='left' class='noborderright'>Name</th>";
$outstr .= "<th width='40'>Count</th>";
$outstr .= "</tr>\n";

my $i = 1;
my $odd = -1;
my %g_tipstrs = ();
while (my $prg = $sh->fetchrow_hashref()) {
  my %prg = %$prg;
  my ($progid, $name, $count) = @prg{qw(progid name cnt)};

  my %popts = (
    'ident'  => $progid,
    'dbh'    => $dbh,
    'maxlen' => 15,
    'isnew'  => 0,
  );
  my $proglink = makeProgramLink(\%popts);
  my %proglink = %$proglink;
  my ($progstr, $capstr, $platstr) = @proglink{qw(progstr capstr platstr)};
  # Add tooltip objects to global g_tipvars.
  addCvars($proglink, \%g_tipstrs);
  my $oddclass = ($odd < 0) ? "class='oddrow'" : "class='evenrow'";

  my $noborderbottom = ($i < 10) ? 'noborderbottom' : '';
  $outstr .= "<tr ${oddclass}>\n";
  $outstr .= "<td width='20'  align='left' class='noborderright $noborderbottom'>$i</td>\n";
  $outstr .= "<td width='130' align='left' class='noborderright $noborderbottom'>$progstr</td>\n";
  $outstr .= "<td width='80'  align='left' class='noborderright $noborderbottom'>${capstr}&nbsp;${platstr}</td>\n";
  $outstr .= "<td width='40'  align='center' class='$noborderbottom'>$count</td>\n";
  $outstr .= "</tr>\n";
  $i++;
  $odd *= -1;

  # $outstr .= "<tr>\n";
  # $outstr .= "<td width='20'  align='left' class='noborderright'>$i</td>\n";
  # $outstr .= "<td width='130' align='left' class='noborderright'>$progstr</td>\n";
  # $outstr .= "<td width='80'  align='left' class='noborderright'>${capstr}&nbsp;${platstr}</td>\n";
  # $outstr .= "<td width='40'  align='center'>$count</td>\n";
  # $outstr .= "</tr>\n";

  # $i++;
}
$outstr .= "</table>\n";

unless ($noheader) {
  print $cgi->header();
}
print $outstr;

# Print Javascript content_vars for tip strings.
# Define doAdd = 1 since apending to content_vars object literal in scope of HTML page.
printToolTips(\%g_tipstrs, 1);
