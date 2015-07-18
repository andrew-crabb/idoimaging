#! /usr/bin/env perl
use warnings;

# Percona.pm
# Percona functions

package Percona;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(analyze_pt_table_sync);
@EXPORT = (@EXPORT, qw($DELETE $REPLACE $INSERT $UPDATE $ALGORITHM $START $END $EXIT $DB_TBL $ELAPSED));


use strict;
use Cwd;
use Cwd qw(abs_path);
use Carp;
use Readonly;
use IO::CaptureOutput qw/capture_exec/;
use FindBin;

use lib $FindBin::Bin;
use FileUtilities;
# use Utilities_new;
# use HRRTUtilities;
# use MySQL;

# Including for just this one program.
use lib '/Users/ahc/BIN/perl/lib';
use Utilities_new;

no strict 'refs';

# ============================================================
# Constants.
# ============================================================

# Global constants.
Readonly::Scalar my $SITEPERL => '/opt/local/siteperl/bin';
Readonly::Scalar my $PT_TABLE_SYNC => 'pt-table-sync';

Readonly::Scalar our $SOURCE_SITE => 'source_site';
Readonly::Scalar our $DEST_SITE   => 'dest_site';
Readonly::Scalar our $DATABASE    => 'database';
Readonly::Scalar our $TABLE       => 'table';

# pt_table_sync output:
# DELETE REPLACE INSERT UPDATE ALGORITHM START    END      EXIT DATABASE.TABLE
#      0       0      0      1 Chunk     19:05:33 19:05:36 2    test.imagefile
Readonly::Scalar our $PT_TABLE_SYNC_PATT => q/#\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\d+)\s+(\S+)/;

Readonly::Scalar our $DELETE    => 'delete';
Readonly::Scalar our $REPLACE   => 'replace';
Readonly::Scalar our $INSERT    => 'insert';
Readonly::Scalar our $UPDATE    => 'update';
Readonly::Scalar our $ALGORITHM => 'algorithm';
Readonly::Scalar our $START     => 'start';
Readonly::Scalar our $END       => 'end';
Readonly::Scalar our $EXIT      => 'exit';
Readonly::Scalar our $DB_TBL    => 'db_tbl';
Readonly::Scalar our $ELAPSED   => 'elapsed';

# ============================================================
# Definitions
# ============================================================

my %defs = (
);

# Create a new Percona object.
# Options hash keys must be Percona constants from this file.

sub new {
  my $that = shift;
  my $class = ref($that) || $that;
  my $self = {@_};
  bless($self, $class);
  return($self);
}

sub pt_table_sync {
  my ($this, $args, $prog_opts) = @_;
  # printHash($args, "Percona::pt_table_sync(): args");
  # printHash($prog_opts, "Percona::pt_table_sync(): prog_opts $OPT_VERBOSE");

  my $str = "${SITEPERL}/${PT_TABLE_SYNC} --verbose --execute";

  $str   .= " h=$args->{$SOURCE_SITE},D=$args->{$DATABASE},t=$args->{$TABLE},u=_www,p=PETimage";
  $str   .= " h=$args->{$DEST_SITE}";
  print STDERR "Percona::pt_table_sync(): $str\n" if ($prog_opts->{$OPT_VERBOSE});
  chomp(my ($stdout, $stderr, $succ, $exit) = capture_exec($str));
  print STDERR "Percona::pt_table_sync(): $stderr\n" if (hasLen($stderr));
  my $rslts = $this->analyze_pt_table_sync($stdout);
  return $rslts
}

# Syncing D=test,h=localhost,p=...,t=imagefile,u=_www

sub analyze_pt_table_sync {
  my ($this, $ret) = @_;

  my @lines = split(/\n/, $ret);
  my %ret = ();
  if ($lines[2] =~ $PT_TABLE_SYNC_PATT) {
    # error_log("6='$6', 7='$7'");
    my $startsecs = convert_times($6)->{$TIMES_SECS};
    my $endsecs   = convert_times($7)->{$TIMES_SECS};
    my $elapsed = $endsecs - $startsecs;
    $ret{$DELETE}  = $1;
    $ret{$REPLACE} = $2;
    $ret{$INSERT}  = $3;
    $ret{$UPDATE}  = $4;
    $ret{$EXIT}    = $8;
    $ret{$DB_TBL}  = $9;
    $ret{$ELAPSED} = $elapsed;
  }
  return \%ret;
}

1;
