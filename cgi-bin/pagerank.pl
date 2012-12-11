#! /opt/local/bin/perl -w

use WWW::Google::PageRank;

my ($url) = $ARGV[0];
$url = "http://${url}" unless ($url =~ /http/);
my $pr = WWW::Google::PageRank->new;
my $ret = $pr->get($url);
print "$ret   $url\n";
