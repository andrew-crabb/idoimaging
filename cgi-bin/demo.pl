#! /usr/bin/env perl
use warnings;
# demo.pl

use strict;
no strict 'refs';

use CGI;
use DBI;
use FindBin qw($Bin);
use lib $Bin;
use Utility;
use radutils;
use bigint;

my $cgi = new CGI;
print $cgi->header();
my ($prog_id) = getParams($cgi, (qw(prog_id)));
my $dbh = hostConnect();
my $verbose = 0;

my $str = "select * from demo";
$str   .= " where ident_prog = '$prog_id'";

my $sh = dbQuery($dbh, $str, $verbose);
while (my $recp = $sh->fetchrow_hashref) {
}

print "hello I am demo.pl, prog_id = $prog_id<br>\n";
