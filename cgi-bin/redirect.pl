#! /usr/local/bin/perl -w

use CGI;
use CGI::Carp;
use DBI;
use FindBin qw($Bin);
use lib $Bin;
use Utility;
use radutils;

my $cgi = new CGI;
my $dbh = hostConnect();
my ($ident, $field, $table) = getParams($cgi, (qw(ident field table)));

unless (has_len($ident) and has_len($field) and has_len($table)) {
  my $referer = $cgi->referer();
  my $redir = (has_len($referer)) ? $referer : "http://www.idoimaging.com";
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
