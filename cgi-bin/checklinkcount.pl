#! /opt/local/bin/perl -w
use DBI;
use FindBin qw($Bin);
use lib $Bin;
use radutils;
use WWW::Google::PageRank;
# use LWP::Simple;
# use Net::Google;

$|++;
# Search object.
# my $key = '/rL/JfpQFHK7MAH5xYyJcYGSSR9mHqdz';
# my $google = Net::Google->new(key=>$key);

my @arr;
my $dbh = hostConnect('');
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
  $homeurl = $counturl if (hasLen($counturl));

  $homeurl = "http://${homeurl}" unless ($homeurl =~ /http/);

  my $ret = $pr->get($homeurl);
  $ret = 0 unless (hasLen($ret));
  my $sqlstr = "update program set linkcnt = $ret where ident = '$ident'";
  print "update program set linkcnt = $ret where ident = '$ident'\n";
  my $sqlsh = dbQuery($dbh, $sqlstr);
  $sqlsh->finish();
}
