#! /usr/local/bin/perl -w

use CGI;
use CGI::Carp 'fatalsToBrowser';
use DBI;
use FindBin qw($Bin);
use lib $Bin;
use radutils;
use Utilities_new;

my $cgi = new CGI;
my $dbh = hostConnect();
my ($ident, $field, $table) = getParams($cgi, (qw(ident field table)));

unless (hasLen($ident) and hasLen($field) and hasLen($table)) {
  my $referer = $cgi->referer();
  my $redir = (hasLen($referer)) ? $referer : "http://www.idoimaging.com";
  print $cgi->redirect($redir);
  exit;
}
# print $cgi->header();
#      dumpParams($cgi);

# Keep a track of who's going where.
$str = "insert into redirect set tabl = '$table', fld = '$field', progid = '$ident', count = 1, date = now()";
$dbh->do($str);

# Send them on their way.
$str = "select $field from $table where ident = '$ident'";
$sh = dbQuery($dbh, $str);
my ($url) = $sh->fetchrow_array();
$url= "http://${url}" unless ($url =~ /^http/);
print $cgi->redirect($url);
