#! /usr/local/bin/perl -w

use strict;
use CGI;
use CGI::Carp;
use DBI;
use FindBin qw($Bin);
use lib $Bin;
use Utility;
use radutils;
use Userbase;
use constants;

# ------------------------------------------------------------
# Constants.
# ------------------------------------------------------------

my @author_fields = (qw(ident name_last name_first email home country));

my $cgi = new CGI;
print $cgi->header();
dumpParams($cgi);

my ($ident, $add, $process) = getParams($cgi, (qw(ident add process)));
my $dbh = hostConnect();

# If adding program, ensure logged-in user is admin.
my $det = get_user_details();
unless ($det and $det->{$Userbase::UB_IS_ADMIN}) {
  print "<tt>Edit?  I don't think so.</tt><br>\n";
  exit;
}

my $title = "I Do Imaging - Edit Author";
printRowWhiteCtr($cgi->h1($title));

# Fetch existing record if performing edit, or table to edit one record.
my $href = (has_len($ident)) ? dbRecord($dbh, "author", $ident) : undef;


# Perform editing and exit, if called from self.  Handles add and self-edit.
if (has_len($process)) {
  my ($updatestr, $comma) = ('', '');
  foreach my $vname (@author_fields) {
    my $newval = ($cgi->param("au_${vname}") or '');
    my $oldval = ($href) ? $href->{$vname} : '';
    print "<tt>newval '$newval' oldval '$oldval'</tt></br>\n";
    if ($newval ne $oldval) {
      $updatestr .= "$comma$vname = '$newval'";
      $comma = ',';
    }
  }
  if (length($updatestr)) {
    if (has_len($add)) {
      # Case 7.
      $updatestr = "insert into author set $updatestr";
    } else {
      # Case 5.
      $updatestr = "update author set $updatestr where ident = '$ident'";
    }
    print "$updatestr<br>\n";
    $dbh->do($updatestr);
  }
}
exit;
