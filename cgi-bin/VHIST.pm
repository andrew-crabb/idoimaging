#! /usr/local/bin/perl -w

# VHIST.pm
# VHIST functions

package VHIST;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(initialize_vhist print_vhist_summary add_vhist_step add_vhist_line print_vhist_tell);
@EXPORT = (@EXPORT, qw($VHIST_DIR $VHIST_RECON_START));

use strict;
use Cwd;
use Cwd qw(abs_path);
use Carp;

use lib 'C:/BIN/perl';
use lib '/home/ahc/BIN/perl';
use FileUtilities;
use Utilities_new;
use HRRTUtilities;
use MySQL;

no strict 'refs';

# ============================================================
# Constants.
# ============================================================

our $VERBOSE           = 'verbose';
our $VHIST_RECON       = 'vhist_recon';
our $VHIST_DIR         = 'vhist_dir';
our $VHIST_RECON_START  = 'vhist_recon_start';
our $VHIST_VCMD_FILE   = 'vhist_vcmd_file';
our $VHIST_VHIST_FILE  = 'vhist_vhist_file';
our $VHIST_VCMD_FULL   = 'vhist_vcmd_full';
our $VHIST_VHIST_FULL  = 'vhist_vhist_full';
our $VHIST_VCMD_HANDLE   = 'vhist_vcmd_handle';

our $STEP_NAME     = 'step_name';
our $STEP_DESC     = 'step_desc';
our $STEP_CMD      = 'step_cmd';
our $STEP_INFILE   = 'step_infile';
our $STEP_OUTFILE  = 'step_outfile';
our $STEP_TOOLPATH = 'step_toolpath';
our $STEP_PROGNAME = 'step_progname';

# ============================================================
# Definitions
# ============================================================

my %defs = (
  $STEP_NAME => [('-s')],
  $STEP_DESC => [('-s')],
    );

# Create a new VHIST object.
# Options hash keys must be VHIST constants from this file.

sub new {
  my ($that, $self, $recon) = @_;
  my $class = ref($that) || $that;
  my %self = %$self;

  my $vhist_stem = "vhist_" . $self->{$VHIST_RECON_START};

  $self{$VHIST_VCMD_FILE} =  "${vhist_stem}.vcmd";
  $self{$VHIST_VHIST_FILE} = "${vhist_stem}.vhist";
  $self{$VHIST_VCMD_FULL} =  $self{$VHIST_DIR} . "/${vhist_stem}.vcmd";
  $self{$VHIST_VHIST_FULL} = $self{$VHIST_DIR} . "/${vhist_stem}.vhist";
  $self{$VHIST_RECON} = $recon;

  printHash(\%self, "VHIST::new");
  my $this = \%self;
  bless($this, $class);
  return($this);
}

# Open a new VHIST file.  Returns 0 on success, else 1.

sub initialize_vhist {
  my ($this, $recon) = @_;

  my $vcmd_file = $this->{$VHIST_VCMD_FULL};
  (my $vhist_file = $vcmd_file) =~ s/\.vcmd/\.vhist/;
  unlink($vcmd_file);
  my $VCMD_HANDLE;
  unless (open($VCMD_HANDLE, ">>", $vcmd_file)) {
    return 1;
  }
  $this->{$VHIST_VCMD_HANDLE} = $VCMD_HANDLE;

  my $timenow = (timeNow())[0];
  my $start_time = $this->{$VHIST_RECON_START};

  print $VCMD_HANDLE "# VHIST command file $vcmd_file\n";
  print $VCMD_HANDLE "# Created $timenow\n";
  print $VCMD_HANDLE "# Reconstruction start time $start_time\n";
  print $VCMD_HANDLE "-O '$vhist_file'\n";
  return 0;
}

sub print_vhist_tell {
  my ($this, $txt) = @_;
  
  my $vcmd_handle = $this->{$VHIST_VCMD_HANDLE};
  print "tell $txt: " . tell($vcmd_handle) . "\n";
}

sub print_vhist_summary {
  my ($this, $summary) = @_;

  if (defined($summary) and ref($summary)) {
    my $vcmd_handle = $this->{$VHIST_VCMD_HANDLE};
    my $summ_str = $summary->{'Name'} . "(" . $summary->{'Scan_Date'} . ")";
    print {$vcmd_handle} "\n# VHIST summary: $summ_str\n";
    print $vcmd_handle "-d title 'Reconstruction $summ_str'\n";
  }
}

sub add_vhist_step {
  my ($this, $v_summ) = @_;
  my @v_summ = @$v_summ;

  my $vcmd_handle = $this->{$VHIST_VCMD_HANDLE};
  foreach my $elem (@v_summ) {
    print $vcmd_handle "$elem\n";
  }

#   print $vcmd_handle "\n# VHIST step: " . $v_summ->{$STEP_NAME} . "\n";
#   print $vcmd_handle "-d title 'VHIST::add_vhist_step'\n";
#   $this->add_vhist_line($v_summ, $STEP_NAME   , '-s title');
#   $this->add_vhist_line($v_summ, $STEP_DESC   , '-s description');
#   $this->add_vhist_line($v_summ, $STEP_TOOLPATH , '-s toolpath');
#   $this->add_vhist_line($v_summ, $STEP_PROGNAME , '-s tool');
#   $this->add_vhist_line($v_summ, $STEP_INFILE , '-i');
#   $this->add_vhist_line($v_summ, $STEP_OUTFILE, '-o');

}

# sub add_vhist_line {
#   my ($this, $elem) = @_;

#   my $vcmd_handle = $this->{$VHIST_VCMD_HANDLE};
#   my ($key, $val) = @$elem;
#   $val = 'EMPTY' unless (hasLen($elem));
#   print "VHIST::add_vhist_line($key = $val)\n" if ($this->{$VERBOSE});
#   print $vcmd_handle "$intro $val\n";

#   # HACK
#   if ($v_key =~ /file$/) {
#     print $vcmd_handle "-f no-embed\n";    
#   }
      
#   print  "$intro $val\n";
# }

1;
