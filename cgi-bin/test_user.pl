#! /usr/local/bin/perl -w

use CGI;
use CGI::Carp;
use DBI;
use FindBin qw($Bin);
use lib $Bin;
use Utility;
use radutils;
use Userbase;
use bigint;
use strict;
no strict 'refs';

my $cgi = new CGI;

# Redirect unless this has come from me, not a search engine.
my $referer = $cgi->referer();

print $cgi->header();

# If adding program, ensure logged-in user is admin.
my $det = get_user_details();
unless ($det and $det->{$Userbase::UB_IS_ADMIN}) {
  print "<tt>UB_IS_ADMIN is false.</tt><br>\n";
  get_user_details(1);
  exit;
}
