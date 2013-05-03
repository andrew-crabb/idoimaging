#! /usr/local/bin/perl -w

use strict;
use Test::More;

use lib '../';
use Utility;

my %test_data = (
  '0000-00-00' => '',
  '2008-09-11' => '2008-09-11',
  '09/11/2008' => '2008-09-11',
  '9/11/2008'  => '2008-09-11',
  '09-11-2008' => '2008-09-11',
  '080911'     => '2008-09-11',
  '20080911'   => '2008-09-11',
  '9/11/08'    => '2008-09-11',
  '09/11/08'   => '2008-09-11',
);

my $n_tests = scalar(keys %test_data);
plan tests => $n_tests;
foreach my $indate (keys %test_data) {
  # print "testing convert_date($indate, $DATE_YYYY_MM_DD)\n";
  my $outdate = convert_date($indate, $DATE_YYYY_MM_DD);
  my $answer = $test_data{$indate};
  $outdate //= '';
  my $cmt = sprintf("convert_date(%-10s) gives '$outdate', want '$answer'", $indate);
  my $is_ok = is($outdate, $answer, $cmt);
  unless ($is_ok) {
    print "convert_date($indate) gives '$outdate', want '$answer'\n";
  }
  # ok(has_len($outdate) and ($outdate eq $test_data{$indate}));
}


