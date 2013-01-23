#! /usr/local/bin/perl -w

use CGI;
use CGI::Carp;
use DBI;
use FindBin qw($Bin);
use lib $Bin;
use Utility;
use radutils;

use strict;
no strict 'refs';

my $cgi = new CGI;

print $cgi->header();
my $currpage = $cgi->param('currpage');
$currpage = '' unless (has_len($currpage));
printPageIntro('', '', '', $currpage);
