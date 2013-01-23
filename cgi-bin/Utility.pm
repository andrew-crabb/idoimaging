#! /usr/local/bin/perl -w

package Utility;
require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw(platform has_len parse_sql_date convert_date);

@EXPORT = (@EXPORT, qw($PLAT_LNX $PLAT_WIN $PLAT_MAC $DATE_MDY $DATE_SQL));

use strict;

use DateTime::Format::MySQL;
use Carp qw(cluck confess);

# ------------------------------------------------------------
# Constants
# ------------------------------------------------------------

# Platform strings and constants
our $PLAT_LNX    = "plat_lnx";
our $PLAT_WIN    = "plat_win";
our $PLAT_MAC    = "plat_mac";

# Date formats
our $DATE_MDY    = 'date_mdy';
our $DATE_SQL    = 'date_sql';

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

# Given a date in SQL format yyyy-mm-dd, return date in the format mm/dd/yyyy

sub convert_date {
  my ($indate, $format) = @_;

  # Hack to avoid bad dates (and keep long cluck out of server error log).
  my $outdate = ($indate or '');
  if (has_len($indate)) {
    $indate =~ /(....)-(..)-(..)/;
    if (!has_len($2) or ($2 < 1) or ($2 > 12)) {
      # print STDERR "ERROR: Utility::convert_date($indate): bad indate\n";
      $outdate = '';
    } else {
      my $dt = undef;
      eval { $dt = parse_sql_date($indate); };
      if ($@) {
	print STDERR "ERROR: Utility::convert_date()\n";
	cluck($@);
      }
      if ($dt) {
	if ($format eq $DATE_MDY) {
	  $outdate = $dt->mdy('/');
	} elsif ($format eq $DATE_SQL) {
	  $outdate = DateTime::Format::MySQL->format_date($dt);
	}
      }
    }
  }

  return $outdate;
}

1;
