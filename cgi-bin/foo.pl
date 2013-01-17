#! /usr/local/bin/perl -w

print "******************************\n";
print scalar(@INC) . " items in INC:\n";
print join("\n", @INC) . "\n";
print "******************************\n";

use CGI;
use CGI::Carp 'fatalsToBrowser';
use DBI;
use FindBin qw($Bin);
use lib $Bin;
use radutils;

print "findbin: $FindBin::Bin - Bin is $Bin\n";
print "******************************\n";
print scalar(@INC) . " items in INC:\n";
print join("\n", @INC) . "\n";
print "******************************\n";

use radutils;

exit;

