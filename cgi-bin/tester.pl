#! /usr/local/bin/perl -w

use CGI;
use CGI::Carp;

use FindBin qw($Bin);
use lib $Bin;
use radutils;
use Utilities_new;
use bigint;
use strict;
no strict 'refs';

my $cgi = new CGI;
print $cgi->header() . "\n";
printStartHTML($cgi);
printTitle($cgi, '', $radutils::NAV_PROGRAMS);
print "<tr><td>\n";
dumpParams($cgi);
print "</td></tr>\n";
