#! /usr/local/bin/perl -w

use CGI;
use CGI::Carp qw(fatalsToBrowser warningsToBrowser);
use DBI;
use FindBin qw($Bin);
use lib $Bin;
use radutils;

use strict;
no strict 'refs';

my $cgi = new CGI;

print $cgi->header();
my $currpage = $cgi->param('currpage');
$currpage = '' unless (hasLen($currpage));
printPageIntro('', '', '', $currpage);
