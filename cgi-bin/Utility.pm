#! /usr/local/bin/perl -w

package Utility;
require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw(platform has_len parse_sql_date);

@EXPORT = (@EXPORT, qw($PLAT_LNX $PLAT_WIN $PLAT_MAC));

use strict;

use DateTime::Format::MySQL;

# ------------------------------------------------------------
# Constants
# ------------------------------------------------------------

# Platform strings and constants
our $PLAT_LNX    = "plat_lnx";
our $PLAT_WIN    = "plat_win";
our $PLAT_MAC    = "plat_mac";

# ------------------------------------------------------------
# Functions
# ------------------------------------------------------------

sub platform {
  my $ostype = ($^O or '');
  my $platform = undef;
  if ($ostype =~ /linux/i) {
    $platform = $PLAT_LNX;
  } elsif ($ostype =~ /darwin/i) {
    $platform = $PLAT_MAC;
  } elsif ($ostype =~ /cygwin/i) {
    $platform = $PLAT_WIN;
  }
  unless (has_len($platform)) {
    print "ERROR: Platform cannot be determined, ostype = '$ostype'\n";
  }
  print "Utility::platform(): returning '$platform'\n";
  return $platform;
}

# Return 1 if var is defined and has a value, else 0.

sub has_len {
  my ($var) = @_;

  my $ret = (defined($var) and length($var) and ($var ne 'NULL')) ? 1 : 0;
  return $ret;
}

sub parse_sql_date {
  my ($datestr) = @_;

  my $dt = undef;
  if ($datestr !~ /^0000/) {
    eval { $dt = DateTime::Format::MySQL->parse_date($datestr) };
    if ($@) {
      warn $@;
    }
  }
  return $dt;
}

1;
