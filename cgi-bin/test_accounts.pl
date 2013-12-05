#! /usr/local/bin/perl -w

use strict;
no strict 'refs';

use DBI;
use Readonly;

use FindBin qw($Bin);
use lib $Bin;
use Utility;
use radutils;
use FileUtilities;
use bigint;

Readonly::Scalar our $P_SYNEDRA => 326;
Readonly::Scalar our $P_OSIRIX  => 251;
Readonly::Scalar our $P_KPACS   => 287;
Readonly::Scalar our $P_DCM4CHE => 176;
Readonly::Scalar our $P_MANGO   => 352;

# Don't modify my 'andy@idoimaging.com' account.
# All the others can be deleted and recreated at will.

my %my_accounts = (
  'ahc@jhu.edu'         => [$P_SYNEDRA, $P_OSIRIX],
  'ahc@me.com'          => [$P_OSIRIX, $P_KPACS, $P_DCM4CHE, $P_MANGO],
  'andycrabb@gmail.com' => [$P_SYNEDRA, $P_MANGO],
  'quux11@gmail.com'    => [$P_KPACS, $P_DCM4CHE],
);

foreach my $email (sort keys %my_accounts) {
  my $pptr = $my_accounts{$email};
  printf("%-20s: %s\n", $email, join(' ', @$pptr));
}
