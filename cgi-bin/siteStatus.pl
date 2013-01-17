#! /usr/local/bin/perl -w

use CGI;
use CGI::Carp 'fatalsToBrowser';
use DBI;
use FindBin qw($Bin);
use lib $Bin;
use radutils;
use httputils;
use bigint;

$cgi = new CGI;
print $cgi->header();

my $dbh = hostConnect();
my $title = "idoimaging.com - Site Status";

printStartHTML($cgi, $title);
printTitle($cgi);

dumpParams($cgi);
print $cgi->h1($title) . "\n";

our ($listdead) = getParams($cgi, (qw(listdead)));

my $str = "select * from program where urlstat = '0' and ident >= 100 order by name";
my $sh = dbQuery($dbh, $str);
print "<table>\n";
while (my $href = $sh->fetchrow_hashref()) {
  my %hash = %$href;
  my ($ident, $name, $homeurl) = @hash{('ident', 'name', 'homeurl')};
  $homeurl = "http://${homeurl}" unless ($homeurl =~ /^http/);
  my $newstat = checkLinkStatus($homeurl);

  my $stattxt = ($newstat) ? "<font color=#3F3>Site now up</font>" : "Site still down";
  my $url = "<a href = '$homeurl' target='new'>link</a>";
  print "<tr>\n";
  print $cgi->td([$ident, $name, $url, $stattxt]) . "\n";
  print "</tr>\n";

  if ($newstat) {
    my $sstr = "update program set urlstat = '1' where ident = '$ident'";
    my $ssh = dbQuery($dbh, $sstr);
  }
}
print "</table>\n";
