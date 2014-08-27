#! /usr/local/bin/perl -w

# rmprogram.pl
# Delete a program from the idoimaging.com database listings.
# Actions: 
#   1. Set 'remdate' for this ident in 'programs' table to current date.
# Related/dependent actions:
#   1. In programs listing all files, add 'where remdate != '0000-00-00'.

use CGI;
use CGI::Carp;
use DBI;
use FindBin qw($Bin);
use lib $Bin;
use Utility;
use radutils;

my $cgi = new CGI;
my $dbh = hostConnect();

my ($ident, $commit) = getParams($cgi, (qw(ident commit)));
exit unless ($ident);
my $str = "select name from program where ident = '$ident'";
my $sh = dbQuery($dbh, $str);
my ($progname) = $sh->fetchrow_array();

print $cgi->header();

printTitle($cgi);
print "<tr><td align='center'>\n";
print $cgi->h1("Remove program: $progname ($ident)") . "\n";
print "</td></tr>\n";

if ($commit) {
  my $today = today();
  $str = "update program set remdate = '$today' where ident = '$ident'";
  my $sh = dbQuery($dbh, $str);
  print "<tr><td>\n";
  tt($str);
  print "</td></tr>\n";
} else {
  print $cgi->startform();
  print $cgi->hidden(-name => 'ident', -value => "$ident") . "\n";
  print "<tr><td>\n";
  print "<table cellspacing=0 cellpadding=2 border=1>\n";
  print "<tr>\n";
  print $cgi->td("Really remove $progname?") . "\n";
  print $cgi->td($cgi->checkbox(
                   -name    => 'commit',
                   -label   => '',
                   -checked => 0,
                 )) . "\n";
  
  print "</tr>\n";
  print "</table>\n";
  print "</td></tr>\n";
  print "<tr><td>\n";
  print $cgi->submit() . "\n";
  print "</td></tr>\n";
  print $cgi->endform() . "\n";
  exit
}
