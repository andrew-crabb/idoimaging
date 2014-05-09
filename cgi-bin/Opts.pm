#! /usr/local/bin/perl -w

use strict;
no strict 'refs';

package Opts;
require Exporter;
our @ISA = qw(Exporter);

our        @EXPORT = qw($OPTS_CONF  $OPTS_CORQ  $OPTS_DFLT  $OPTS_MODE  $OPTS_NAME  $OPTS_OPTN  $OPTS_TEXT  $OPTS_TYPE);
@EXPORT = (@EXPORT,  qw($OPTS_BOOL $OPTS_FLOAT $OPTS_INT $OPTS_NOTE $OPTS_STRING));
@EXPORT = (@EXPORT,  qw($OPTS_MAJR  $OPTS_MINR));
@EXPORT = (@EXPORT,  qw($OPTS_BOOL $OPTS_FLOAT $OPTS_INT $OPTS_STRING));
@EXPORT = (@EXPORT,  qw($OPTS_ERR $OPTS_CNT));
@EXPORT = (@EXPORT,  qw($OPT_VERBOSE $OPT_DUMMY $OPT_HELP $OPT_FORCE $OPT_NOTE));

use Getopt::Long;
use File::Basename;

use Utility;

# ------------------------------------------------------------
# Boolean command line option
# ------------------------------------------------------------

# Categories (LHS of options defined in program)
Readonly::Scalar our $OPTS_CONF => 'opts_conf'; # Require confirmation.
Readonly::Scalar our $OPTS_CORQ => 'opts_corq'; # Co-requisite.
Readonly::Scalar our $OPTS_DFLT => 'opts_dflt'; # Default value.
Readonly::Scalar our $OPTS_MODE => 'opts_kind'; # OPTS_MAJR, OPTS_MINR
Readonly::Scalar our $OPTS_NAME => 'opts_name'; # Long name.
Readonly::Scalar our $OPTS_OPTN => 'opts_optn'; # Optional (default is required arg or default value)
Readonly::Scalar our $OPTS_TEXT => 'opts_text'; # Help text.
Readonly::Scalar our $OPTS_TYPE => 'opts_type'; # Type of option.

# Types of values.
Readonly::Scalar our $OPTS_BOOL   => 'opts_bool';   # Boolean option.
Readonly::Scalar our $OPTS_FLOAT  => 'opts_float';  # Value: Float.
Readonly::Scalar our $OPTS_INT    => 'opts_int';    # Value: Integer.
Readonly::Scalar our $OPTS_NOTE   => 'opts_note';   # Not value but usage note.
Readonly::Scalar our $OPTS_STRING => 'opts_string'; # Value: String, Optional.

# Values for $OPTS_MODE (RHS of options defined in program)
Readonly::Scalar our $OPTS_MAJR => 'opts_majr'; # Major mode.
Readonly::Scalar our $OPTS_MINR => 'opts_minr'; # Minor mode.

Readonly::Hash our %OPTS_TYPES => (
  $OPTS_BOOL   => '',
  $OPTS_FLOAT  => 'f',
  $OPTS_INT    => 'i',
  $OPTS_STRING => 's',
  );

Readonly::Scalar our $OPTS_ERR => 'opts_err'; # Number of errors.
Readonly::Scalar our $OPTS_CNT => 'opts_cnt'; # Number of options set.

Readonly::Scalar our $OPT_VERBOSE  => 'v';
Readonly::Scalar our $OPT_DUMMY    => 'd';
Readonly::Scalar our $OPT_HELP     => 'h';
Readonly::Scalar our $OPT_FORCE    => 'f';
Readonly::Scalar our $OPT_NOTE     => '@';

Readonly::Hash our %DEFAULT_OPTS => (
  $OPT_VERBOSE => {
    $OPTS_NAME => 'verbose',
    $OPTS_TYPE => $OPTS_BOOL,
    $OPTS_TEXT => 'Verbose (accumulates).',
  },
  $OPT_DUMMY => {
    $OPTS_NAME => 'dummy',
    $OPTS_TYPE => $OPTS_BOOL,
    $OPTS_TEXT => 'Dummy: Print commands, don\'t execute.',
  },
  $OPT_HELP => {
    $OPTS_NAME => 'help',
    $OPTS_TYPE => $OPTS_BOOL,
    $OPTS_TEXT => 'Help: Print help text.',
  },
  $OPT_FORCE => {
    $OPTS_NAME => 'force',
    $OPTS_TYPE => $OPTS_BOOL,
    $OPTS_TEXT => 'Force/clobber.',
  },
);

# ------------------------------------------------------------
# Given options structure, process command line options.
# cgi: If defined, get params from Apache envt.  Must use long options ('verbose' etc).
# Else, from cmd line.  Can use short keys ('v') but used internally as long name.
# Returns: Ptr to hash of short_key => value.
# Bools init to 0, strings to '' (defined, zero length).

sub process_opts {
  my ($allopts, $cgi) = @_;
  $cgi = undef unless (is_apache_environment() and (ref($cgi) eq 'CGI'));

  # Use default options, but allow incoming options to override.
  my $opts_to_use = merge_opts_arrays(\%DEFAULT_OPTS, $allopts);
  my $opt_arr = make_opt_array($opts_to_use);

  # Read in the options.
  Getopt::Long::Configure('bundling');
  my %set_opts;
  if ($cgi) {
    # Get from Apache envt.
    my $set_opts = get_apache_options($cgi, $opts_to_use);
    %set_opts = %$set_opts;
    # printHashAsTable(\%set_opts, 0, "process_opts()");
    } else {
    # Get from cmd line.  Note that keys are long names even if short key used.
    GetOptions(\%set_opts, @$opt_arr);
    # printHash(\%set_opts, 'Utilities_new::process_opts(): set_opts');
  }

  # Process each opt and fill into options array.
  my %options_set = ();
  my %coreqs = ();
  my $current_mode = '';
  $options_set{$Opts::OPTS_CNT} = scalar(keys(%set_opts));
  $options_set{$OPTS_ERR} = 0;

  foreach my $optkey (sort keys %$opts_to_use) {
    my $opt = $opts_to_use->{$optkey};
    if ($optkey eq $OPT_NOTE) {
      unless (defined($opt->{$OPTS_NAME})) {
        next;
      }
    }
    my ($opt_kind, $opt_type, $opt_name, $opt_conf, $opt_text, $opt_coreq, $opt_dflt) = @{$opt}{($OPTS_MODE, $OPTS_TYPE, $OPTS_NAME, $OPTS_CONF, $OPTS_TEXT, $OPTS_CORQ, $OPTS_DFLT)};

    # Post-process %set_opts since it sets only used options.
    # set_val is what options_set{$optkey} and options_set{$opt_name} are set to.
    my $set_val = undef;
    # 1. Defaults: false for bool, undef for string, int, float (not '': is a legal value).
    if ($opt_type eq $OPTS_BOOL) {
      $set_val = 0;
    }
    # 2. Set to default value if supplied.
    if (defined($opt_dflt)) {
      $set_val = $opt_dflt;
    }
    # 3. Set to options value from GetOptions.
    if (defined($set_opts{$opt_name})) {
      $set_val = $set_opts{$opt_name};
    }

    # Process all set options.
    if (defined($set_val)) {
      # Get confirmation if required.
      if (defined($opt_conf)) {
        if (!get_confirmation($opt_text)) {
          print "ERROR: confirmation required for option -$optkey ($opt_name)\n";
          $options_set{$OPTS_ERR} = 1;
        }
      }

      # Ensure multiple major modes are not defined
      if (defined($opt_kind)) {
        if (($opt_kind eq $OPTS_MAJR) and has_len($current_mode)) {
          print "ERROR: Options -$current_mode and -$opt_name may not be used together\n";
          $options_set{$OPTS_ERR} = 1;
          } else {
            $current_mode = $opt_name;
          }
        }

      # Gather co-requisites needed by this (set) option.
      if (defined($opt_coreq)) {
        push(@{$coreqs{$opt_coreq}}, ($optkey => $opt_name));
      }

      if ($opt_type eq $OPTS_STRING) {
  # If option set, check it has a value.
  if (!defined($set_val)) {
    print "process_opts(): ERROR: No value set for option $optkey ($opt_name: $opt_text)";
    $options_set{$OPTS_ERR} = 1;
  }
}
$options_set{$optkey} = $set_val;
      # $options_set{$opt_name} = $set_val;
    }
  }

  # Check co-requisites were satisfied.
  foreach my $needed_opt (sort keys %coreqs) {
    my $needed_by_arr = $coreqs{$needed_opt};
    my ($needed_key, $needed_name) = @{$needed_by_arr};
    if (!defined($set_opts{$needed_name})) {
      # Setting $OPTS_ERR will cause the program to exit.
      my $needed_opt_str = $opts_to_use->{$needed_key}{$OPTS_NAME};
      my $needed_by_str = '';
      my $sep = '';
      foreach my $needed_by_elem (@{$needed_by_arr}) {
        $needed_by_str .= "${sep}-$needed_by_elem ($needed_name)";
        $sep = ', ';
      }
      print "ERROR: -$needed_opt ($needed_opt_str) is needed by $needed_by_str\n";
      $options_set{$OPTS_ERR} = 1;
    }
  }

  foreach my $key (keys %options_set) {
    my $val = $options_set{$key};
    if ($val) {
      # print "Utilities_new::process_opts():: $key: $val\n";
    }
  }
  # printHash(\%options_set, 'Utilities_new::process_opts(): options_set');

  return \%options_set;
}


# Get given options from Apache environment.
# $opts_to_use: Ptr to has including %DEFAULT_OPTS.
# Returns: Ptr to hash of (long_name => value) only of set opts.

sub get_apache_options {
  my ($cgi, $opts_to_use) = @_;

  my %set_opts = ();

  my $params = $cgi->Vars;
  my @param_keys = keys(%$params);
  my @keys_to_use = keys(%$opts_to_use);
  # param_keys comes in as long names.  Check against names of opts_to_use.
  foreach my $param_key (@param_keys) {
    my $param_is_valid = 0;
    FORE:
    foreach my $opt_key (@keys_to_use) {
      # Skip notes: Not a true option.
      if ($opt_key eq $OPT_NOTE) {
       unless (defined($opts_to_use->{$opt_key}->{$OPTS_NAME})) {
         next;
       }
     }
     if ($param_key eq $opts_to_use->{$opt_key}->{$OPTS_NAME}) {
       $param_is_valid = 1;
       $set_opts{$param_key} = $params->{$param_key};
       last FORE;
     }
   }
   unless ($param_is_valid) {
    my $pval = $params->{$param_key};
    print STDERR "Utilities_new::get_apache_options(): Unknown option: '$param_key' => '$pval'\n";
  }
}
  # printHashAsTable(\%set_opts, 0, "get_apache_opts set_opts");

  return \%set_opts;
}


# Create array of arguments for GetOptions.
# Each element is a string of the form '<name>|<init><op><type>'.
# Name: Full length name of option, for use as '--opt_name optval'.
# Init: Initial letter of option, for use as '-init optval'.
# Op:   Operator: '=' == required, ':' == optional.
# Type: 's' == string, 'i' == integer, 'f' == float

sub make_opt_array {
  my ($allopts) = @_;

  my @opt_array = ();
  foreach my $letter (sort keys %$allopts) {
    my $opt = $allopts->{$letter};
    # Skip note unless its letter has been overridden.
    if ($letter eq $OPT_NOTE) {
      unless (defined($opt->{$OPTS_NAME})) {
        next;
      }
    }
    # Letter (required) and name.
    my $opt_name = $opt->{$OPTS_NAME};
    my $opt_str = (has_len($opt_name)) ? "${opt_name}|${letter}" : $letter;
    # Type.
    my $type_str = (has_len($opt->{$OPTS_TYPE})) ? $OPTS_TYPES{$opt->{$OPTS_TYPE}} : '';
    # Operator.  No type => 'incremental boolean'.
    my $op_str = (has_len($type_str)) ? (has_len($opt->{$OPTS_OPTN})) ? ':' : '=' : '+';
    # print "make_opt_string: Returning >${opt_string_short}<\n";
    my $opt_elem = "${opt_str}${op_str}${type_str}";
    push(@opt_array, $opt_elem);
    # print "Utilities_new::make_opt_array(): $opt_elem\n";
  }
  return \@opt_array;
}

sub merge_opts_arrays {
  my ($default_opts, $prog_opts) = @_;

  my %opts_to_use = %$default_opts;
  my @seen_keys = ();
  if (defined($prog_opts) and ref($prog_opts)) {
    # Use default, allowing prog to overwrite.
    foreach my $key (sort keys %opts_to_use) {
      if (defined($prog_opts->{$key})) {
        $opts_to_use{$key} = $prog_opts->{$key};
        push(@seen_keys, $key);
      }
    }
    # Add any remaining prog options.
    foreach my $key (sort keys %$prog_opts) {
      unless (grep(/^$key$/, @seen_keys)) {
        $opts_to_use{$key} = $prog_opts->{$key};
      }
    }
  }

  my $opts_to_use = \%opts_to_use;
  return $opts_to_use;
}

# ------------------------------------------------------------

sub usage {
  my ($prog_opts) = @_;
  # printHash($prog_opts, 'usage');

  # Use default options, but allow incoming options to override.
  my $opts_to_use = merge_opts_arrays(\%DEFAULT_OPTS, $prog_opts);

  my ($name, $path, $suffix) = fileparse($0);
  print "Usage: $name\n";

  my $maxlen = 0;
  my $has_val = 0;
  foreach my $letter (sort keys %$opts_to_use) {
    next if ($letter eq $OPT_NOTE);
    my $opt = $opts_to_use->{$letter};
    my ($opt_name, $opt_type) = @{$opt}{($OPTS_NAME, $OPTS_TYPE)};
    # Max name length, for printf format string.
    my $len = has_len($opt_name) ? length($opt_name) : 0;
    $maxlen = ($len > $maxlen) ? $len : $maxlen;
    # Whether any opt has a value.
    $has_val += ($opt_type eq $OPTS_STRING) ? 1 : 0;
  }

  my $val_space = ($has_val) ? '%5s' : '';
  my $fmtstr = "%s -%s ${val_space} --%-${maxlen}s :  %s\n";

  # Put prog_opts first.
  my @opt_keys = (ref($prog_opts)) ? (keys(%$prog_opts), 'dummy') : ();
  # print "opt_keys: " . join(' ', @opt_keys) . "\n";
  foreach my $default_key (sort keys %DEFAULT_OPTS) {
    # print "default_key was $default_key, opt_keys " . join(' ', @opt_keys) . "\n";
    push(@opt_keys, $default_key) unless (grep(/^${default_key}$/, @opt_keys));
    # print "default_key now $default_key, opt_keys " . join(' ', @opt_keys) . "\n";

  }
  # print "opt_keys: " . join(' ', @opt_keys) . "\n";

  my $comment_line = (ref($prog_opts)) ? 'Program Options:' : '';
  foreach my $letter (@opt_keys) {
    next if ($letter eq $OPT_NOTE);
    # Comment_line optionally introduces the program and default sections.
    if (has_len($comment_line)) {
      print "$comment_line\n";
      $comment_line = '';
      # next;
    }
    # 'dummy' is placed after program opts, introduces default opts.
    if ($letter eq 'dummy') {
      print "Default Options:\n";
      next;
    }

    my $opt = $opts_to_use->{$letter};
    my ($opt_name, $opt_type, $opt_text, $opt_dflt, $opt_corq) = @{$opt}{($OPTS_NAME, $OPTS_TYPE, $OPTS_TEXT, $OPTS_DFLT, $OPTS_CORQ)};
    my $requires_val = ($opt_type eq $OPTS_STRING) ? '*' : ' ';
    my $default_text = '';
    if (defined($opt_dflt)) {
      my $default_str = ($opt_dflt eq '1') ? 'true' : ($opt_dflt eq '0') ? 'false' : $opt_dflt;
      $default_text = " (default: '$default_str')";
    }
    my $coreq_text = (defined($opt_corq)) ? ' (requires: -${opt_corq})' : '';
    my $opt_str = $opt_text . $default_text . $coreq_text;
    if ($has_val) {
      if ($opt_type eq $OPTS_STRING) {
        printf($fmtstr, $requires_val, $letter, '<val>', $opt_name, $opt_str);
      } else {
        printf($fmtstr, $requires_val, $letter, '     ', $opt_name, $opt_str);
      }
    } else {
      printf($fmtstr, $requires_val, $letter, $opt_name, $opt_str);
    }
  }
  if (defined(my $note_text = $opts_to_use->{$OPT_NOTE}->{$OPTS_TEXT})) {
    print $note_text;
  }
}

1;
