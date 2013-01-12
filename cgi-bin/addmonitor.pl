#! /usr/local/bin/perl -w

use strict;
no strict 'refs';

use CGI;
use CGI::Carp 'fatalsToBrowser';
use DBI;
use FindBin qw($Bin);
use lib $Bin;
use radutils;
use Utilities_new;

my $cgi = new CGI;
my $dbh = hostConnect();

my ($addedIdent, $action, $obf_userid) = getParams($cgi, ('progid', 'action', $OBF_USERID));
$action = '' unless (defined($action));
my $action_add = ($action eq "add");
my $action_remove = ($action eq "remove");
# my $loggedIn =  loggedInIdent($dbh, $cgi);
my $userid = (hasLen($obf_userid)) ? $obf_userid / $OBFUSCATOR : '';

if (hasLen($addedIdent) and hasLen($userid)) {
  # Add a monitor for this program to this user, unless present.
  my $str = "select ident, progid from monitor where progid = '$addedIdent' and userid = '$userid'";
  my $sh = dbQuery($dbh, $str);
  my @vals = $sh->fetchrow_array();
  if ($action_add and (scalar(@vals) == 0)) {
    # Adding a new monitor.
    my $time_now = convertDates(timeNow());
    my $sqltime = $time_now->{$DATETIME_SQL};
    # Get current details of added program.
    $str = "select rev from program where ident = '$addedIdent'";
    $sh = dbQuery($dbh, $str);
    if (my ($curr_rev) = $sh->fetchrow_array()) {
      $str  = "insert into monitor";
      $str .= " set progid = '$addedIdent', lastrev = '$curr_rev', userid = '$userid', datetime = '$sqltime'";
      $sh = dbQuery($dbh, $str);
    }
  } elsif ($action_remove and scalar(@vals)) {
    $str = "delete from monitor where progid = '$addedIdent' and userid = '$userid'";
    $sh = dbQuery($dbh, $str);
  }
  print $cgi->redirect($cgi->referer());
} else {
  # Missing ident, or not logged in.
  print $cgi->header();
  printRowWhiteCtr($cgi->h1("Not Logged In"), $radutils::TABLEWIDTH);
  printRowWhite "You must be logged in to add a program to the list of programs that you are tracking";
  print "<tt>obf_userid $obf_userid  OBF_USERID $OBF_USERID</tt>\n";
  printRowWhite "Log in (at top of page) to track programs.";
  if (hasLen(my $referer = $cgi->referer())) {
    printRowWhite "Or click <a class='green' href='$referer'>here</a> to return to the previous screen";
  }
  print $cgi->endform() . "\n";
}

