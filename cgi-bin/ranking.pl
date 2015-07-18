#! /usr/bin/env perl
use warnings;

use CGI;
use CGI::Carp;
use DBI;
use FindBin qw($Bin);
use radutils;

my $cgi = new CGI;
my $dbh = hostConnect();

print $cgi->header();
printStartHTML($cgi);
printTitle($cgi);

# Data for redirects.
my $str = "select redirect.count, program.name, program.ident from redirect, program where redirect.progid = program.ident and redirect.tabl = 'program' order by redirect.count desc limit 25";
my $sh = dbQuery($dbh, $str);
my $ref = $sh->fetchall_arrayref();
my @rankings = @$ref;

# Data for watchings.
$str = "select monitor.progid, program.name from monitor, program where monitor.progid = program.ident";
$sh = dbQuery($dbh, $str);
$ref = $sh->fetchall_arrayref();
my @monitors = @$ref;
my (%progids, %prognames);
foreach my $monitor (@monitors) {
  my ($progid, $progname) = @$monitor;
  $progids{$progid}++;
  $prognames{$progid} = $progname;
}

print comment("Outer table for two table columns");
print "<table cellspacing=4 cellpadding=2 border=0>\n";
print "<tr><td>\n";

print comment("Table 1 for most linked to");
print "<table cellspacing=0 cellpadding=2 border=1>\n";
print "<tr><th>Rank</th><th>Name</th><th>Count</th></tr>\n";
my $rank = 1;
foreach my $ranking (@rankings) {
  my ($count, $name, $ident) = @$ranking;
  print $cgi->Tr($cgi->td([$rank, $name, $count])) ."\n";
  $rank++;
}
print "</table>\n";

print comment("End of td for first table");
print "</td>\n<td>\n";

print comment("Table 2 for most watched");
print "<table cellspacing=0 cellpadding=2 border=1>\n";

print "<tr><th>Rank</th><th>Name</th><th>Monitor</th><th>ID</th></tr>\n";
my $rank = 1;
my @countids = sort {$progids{$b} <=> $progids{$a}} keys %progids;
foreach my $countid (@countids[0..24]) {
#   print "<tt>$prognames{$countid} = $progids{$countid}</tt><br>\n";
  my $name = $prognames{$countid};
  my $count = $progids{$countid};
  print "<tr><td>$rank</td><td>$name</td><td>$count</td><td>$countid</td></tr>\n";
  $rank++;
}

print "</table>\n";

print "</td>\n</tr>\n";
print "</table>\n";
