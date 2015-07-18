#! /usr/bin/env perl
use warnings;

use strict;
no strict 'refs';

use CGI;
use CGI::Carp;
use DBI;
use FindBin qw($Bin);
use lib $Bin;
use Utility;
use radutils;


my $cgi = new CGI;
print $cgi->header();

my $dbh = hostConnect();
my $dbh_u = hostConnect('userbase');

# Number of applications.
my $str = "select count(*) from program where ident > 100";
my $nprog = countEntries($dbh, $str);

# Number of distinct authors of applications.
$str = "select distinct author.ident from author, program where author.ident = program.auth and program.ident > 100;";
my $sh = dbQuery($dbh, $str);
# my ($ret) = $sh->fetchrow_array();
my $ret = $sh->fetchall_arrayref();
my @ret = @$ret;
my $nauth = scalar @ret;
# my $nauth = countEntries($dbh, $str);

# Number of subscribers.
$str = "select count(*) from userbase_users";
my $nsubs = countEntries($dbh_u, $str);

# Number of redirections, last 30 days.
$str = "select count(*) from redirect where date > date_add(curdate(), interval - 30 day)";
my $nredir = int(countEntries($dbh, $str) / 30);

# Number of new versions, last 30 days.
$str = "select count(*) from version where adddate > date_add(curdate(), interval - 30 day)";
my $nver = countEntries($dbh, $str);
my $ver30str = "<a href='/${STR_LIST_VERSIONS}?days=30'>New releases, last month:</a>";

# Number of new versions, last 90 days.
$str = "select count(*) from version where adddate > date_add(curdate(), interval - 90 day)";
my $nqver = countEntries($dbh, $str);
my $ver90str = "<a href='/${STR_LIST_VERSIONS}?days=90'>New releases, last quarter:</a>";

# Number of screen capture images.
$str = "select count(*) from image where scale = 'full'";
my $nimg = countEntries($dbh, $str);

print "<table width='270' border='1' cellpadding='3' cellspacing='0'>\n";
print "<tr><th colspan='2' align='center'>Current Statistics</th></tr>\n";
print "<tr><th width='200' align='left'>Programs:</th><td width='70'>$nprog</td></tr>\n";
print "<tr><th width='200' align='left'>Authors:</th><td width='70'>$nauth</td></tr>\n";
print "<tr><th width='200' align='left'>$ver30str</th><td width='70'>$nver</td></tr>\n";
print "<tr><th width='200' align='left'>$ver90str</th><td width='70'>$nqver</td></tr>\n";
print "<tr><th width='200' align='left'>Screen capture images:</th><td width='70'>$nimg</td></tr>\n";
print "<tr><th width='200' align='left'>Subscribers:</th><td width='70'>$nsubs</td></tr>\n";
print "<tr><th width='200' align='left'>Visitors per day:</th><td width='70'>$nredir</td></tr>\n";
print "</table>\n";

$dbh->disconnect();

sub countEntries {
  my ($dbh, $str) = @_;

  my $sh = dbQuery($dbh, $str);
   my ($ret) = $sh->fetchrow_array();
#   my @ret = $sh->fetchrow_array();
#   my $ret = scalar @ret;
  return $ret;
}
