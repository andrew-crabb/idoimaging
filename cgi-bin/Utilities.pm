#! /usr/local/bin/perl -w

package Utilities;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(hasLen);

# Return 1 if var is defined and has a value, else 0.

sub hasLen {
  my ($var) = @_;

  my $ret = (defined($var) and length($var) and ($var ne 'NULL')) ? 1 : 0;
  return $ret;
}



1;


