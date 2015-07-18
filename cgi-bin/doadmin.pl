#! /usr/bin/env perl
use warnings;

use DBI;
use CGI;
use CGI::Carp;
use FindBin qw($Bin);
use lib $Bin;
use Utility;
use radutils;

my $cgi = new CGI;

my $url = "";
my %acts = (
  'BAddProg'   => "edit_program?Add=1&Commit=1",
  'BEditProg'  => "programs?edit=1&Commit=1",
  'BEditRel'   => "edit_relationship",
  'BAddAuth'   => "edit_author?Add=1",
  'BEditAuth'  => "edit_author?edit=1",
  'BAddReso'   => "edit_resource?Add=1",
  'BEditReso'  => "edit_resource?edit=1",
  'BAddData'   => "edit_data?DBtable=data&Add=1",
  'BEditData'  => "edit_data?DBtable=data",
  'BListDead'  => "siteStatus?listdead=1",
  'BCheckMan'  => "checkVersions?X=1",
  'BSyncDB'    => "synchronize_DB",
  'BSyncDBR'   => "synchronize_DB?Reverse=1",
  'BRanking'   => "ranking",
  'BEmails'    => "sendemails",
  'BUpdates'   => "checklinkupdate?email=1",
    );
foreach my $param (keys %acts) {
  if (has_len($cgi->param($param))) {
    $url = $acts{$param};
    last;
  }
}

# Password.
my $pass = $cgi->param('pass');
$pass = ($pass eq 'asdf') ? 1 : 0;
my $loggedIn = ($pass) ? $pass : has_len($cgi->cookie('loggedin'));

my @params = $cgi->param();

if ($pass or $loggedIn) {
  my $mycookie = $cgi->cookie(
    -name => 'loggedin',
    -value => 1,
      );
  my $hdr = $cgi->header(
    -cookie => $mycookie,
    -location => $url,
      );
  print $hdr;
} else {
  print $cgi->header() . "\n";

  my $title = "I Do Imaging: Admin";
  printStartHTML($cgi, $title);

  print "<br>\n";
  dumpParams($cgi);
  print "You're Not logged in, your pass = '$pass'<br>\n";
}
exit;
