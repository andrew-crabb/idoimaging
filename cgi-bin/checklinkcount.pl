#! /usr/bin/env perl
use warnings;

use strict;
no strict 'refs';

use CGI;
use DBI;
use FindBin qw($Bin);
use lib $Bin;
use Utility;
use radutils;

use WWW::Google::PageRank;

$|++;
# Search object.
# my $key = '/rL/JfpQFHK7MAH5xYyJcYGSSR9mHqdz';
# my $google = Net::Google->new(key=>$key);

my @arr;
my $dbh = hostConnect();
my ($query, $sh, $ref);


if (scalar(@ARGV)) {
  # URLs from command line.
  foreach my $name (@ARGV) {
    $query = "select ident, homeurl, name, linkcnt, counturl from program where name like '\%$name\%' or homeurl like '\%$name\%'";
    $sh = dbQuery($dbh, $query);
    $ref = $sh->fetchall_arrayref;
    $sh->finish();
    @arr = @$ref;
    my $numprog = scalar(@arr);
    print "$numprog programs match $name\n";
    foreach my $elem (@arr) {
      my ($ident, $url, $name, $linkcnt, $counturl) = @$elem;
      printf "%-20s %6d %s\n", substr($name, 0, 20), $ident, $url;
    }
  }
} else {
  # URLs from database.
  my $query = "select ident, homeurl, name, linkcnt, counturl from program where ident >= 100 order by ident";
  my $sh = dbQuery($dbh, $query);
  my $ref = $sh->fetchall_arrayref;
  $sh->finish();
  @arr = @$ref;
}

my $pr = WWW::Google::PageRank->new;
foreach my $rslt (@arr) {
  my ($ident, $homeurl, $name, $oldcnt, $counturl) = @$rslt;
  $homeurl = $counturl if (has_len($counturl));
  $homeurl = "http://${homeurl}" unless ($homeurl =~ /http/);

  my $ret = $pr->get($homeurl);
  print "get($homeurl) = $ret\n";
  $ret = 0 unless (has_len($ret));
  my $sqlstr = "update program set linkcnt = $ret where ident = '$ident'";
  print "update program set linkcnt = $ret where ident = '$ident'\n";
#  my $sqlsh = dbQuery($dbh, $sqlstr);
#   $sqlsh->finish();
}
