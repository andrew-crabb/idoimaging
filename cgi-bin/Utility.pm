#! /usr/local/bin/perl -w

package Utility;
require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw(platform has_len parse_sql_date convert_date is_apache_environment today);

@EXPORT = (@EXPORT, qw($PLAT_LNX $PLAT_WIN $PLAT_MAC));
@EXPORT = (@EXPORT, qw($DATE_MDY $DATE_MM_DD_YYYY_0 $DATE_MM_DD_YYYY_1 $DATE_YYMMDD $DATE_YYYYMMDD $DATE_YYYY_MM_DD $DATE_SQL_DATE $DATE_SQL_DATETIME));

use strict;

use DateTime::Format::MySQL;
use DateTime::Format::Strptime;
use Carp qw(cluck confess);
use Readonly;
use IO::Handle;

# ------------------------------------------------------------
# Constants
# ------------------------------------------------------------

# Platform strings and constants
our $PLAT_LNX    = "plat_lnx";
our $PLAT_WIN    = "plat_win";
our $PLAT_MAC    = "plat_mac";

# ------------------------------------------------------------
# Date Conversion Constants
# ------------------------------------------------------------

# Need named conversion strings for converting both to and from a datetime object.
Readonly::Scalar our $DATE_MM_DD_YYYY_0 => 'date_mm_dd_yyyy_0';	# 12/15/2003
Readonly::Scalar our $DATE_MM_DD_YYYY_1 => 'date_mm_dd_yyyy_1';	# 12-15-2003
Readonly::Scalar our $DATE_YYMMDD       => 'date_yymmdd';	# 031215
Readonly::Scalar our $DATE_YYYYMMDD     => 'date_yyyymmdd';	# 20031215
Readonly::Scalar our $DATE_YYYY_MM_DD   => 'date_yyyy_mm_dd';	# 2003-12-15
Readonly::Scalar our $DATE_SQL_DATE     => 'date_sql_date';	# 2003-12-15
Readonly::Scalar our $DATE_SQL_DATETIME => 'date_sql_datetime';	# 2003-12-15 09:10:11
Readonly::Scalar our $DATE_MDY          => 'date_mdy';		# 12/15/03

# Date parsing strings (POSIX compliant) see Date::Format::Strptime and DateTime::strftime
# Note I think CLDR patterns are more modern.
# %Y : Year with century
# %y : Year without century
# %m : Month (01-12), 1 or 2 digits
# %d : Day of month (01-31), 1 or 2 digits
# %T : Time hr:mn:sc, 1 or 2 digits

Readonly::Hash my %date_patterns => (
  $DATE_MM_DD_YYYY_0 => '%m/%d/%Y',	# 12/15/2003
  $DATE_MDY          => '%m/%d/%y',	# 12/15/03
  $DATE_MM_DD_YYYY_1 => '%m-%d-%Y',	# 12-15-2003
  $DATE_YYMMDD       => '%y%m%d',	# 031215
  $DATE_YYYYMMDD     => '%Y%m%d',	# 20031215
  $DATE_YYYY_MM_DD   => '%Y-%m-%d',	# 2003-12-15
  $DATE_SQL_DATE     => '%Y-%m-%d',	# 2003-12-15
  $DATE_SQL_DATETIME => '%Y-%m-%d %T',	# 2003-12-15 09:10:11
);

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

# Convert date in various formats.
#   Returns: Formatted date string if outformat supplied, else DateTime object.

sub convert_date {
  my ($indate, $outformat_key) = @_;

  # error_log("Indate '$indate'", 1);
  my $ret = undef;
  if (!has_len($indate)) {
    # print STDERR "Utility::convert_date(): No date specified\n";
  } else {
    eval {
      my $dp = new MyDateParser;
      if (my $dt = $dp->parse_datetime($indate)) {
	$ret = (has_len($outformat_key)) ? $dt->strftime($date_patterns{$outformat_key}) : $dt;
      } else {
	print STDERR "Utility::convert_date(): dp->parse_datetime() failed\n";
      }
    };
    if ($@) {
      # print STDERR "Utility::convert_date(): XXXXXXX\n";
    }
  }
  if (defined($ret)) {
    return $ret;
  } else {
    return;
  }
}

sub today {
  return DateTime->today->format_cldr("YYYY-MM-dd");
}

sub is_apache_environment {
  my $gw = $ENV{'GATEWAY_INTERFACE'};
  my $ret = (has_len($gw) and ($gw =~ /^CGI/)) ? 1 : 0;
  return $ret;
}



# Print given message to STDERR with stack trace (like PHP's error_log)
# Returns 1 on non-zero message length (allows "return(error_log($err_msg));")

sub error_log {
  my ($msg, $is_err, $start_level) = @_;
  $is_err //= 0;
  $start_level //= 2;

  STDERR->autoflush(1);
  my @lines = ($is_err) ? stackContents($msg, $start_level) : ($msg);
  foreach my $line (@lines) {
    print STDERR "$line\n";
  }
  return has_len($msg);
}

# Provide array of lines of stack trace for later printing.

sub stackContents {
  my ($comment, $start_level) = @_;
  $start_level //= 1;

  my $i = $start_level;
  my @lines = ();
  while (my ($pack, $file, $line, $subr, @rest) = caller($i++)) {
    $file =~ /([^\/]+)$/;
    push(@lines, [$1, $line, $subr]);
  }
  # Get max col widths and sprintf fmtstr for vals.
  my @fmts = qw/s d s/;
  my ($maxcols, $fmtstr) = max_cols_print(\@lines, \@fmts);
  my $totwidth = 0;
  foreach my $colwidth (@$maxcols) {
    $totwidth += 2 if ($totwidth);
    $totwidth += $colwidth;
  }

  my $stars = '';
  for my $j (1..$totwidth) {
    $stars .= '*';
  }

  # Array of formatted lines of output.
  my @ret = ();
  # push(@ret, $stars);
  push(@ret, sprintf("%-${totwidth}s", $comment)) if (has_len($comment));
  foreach my $line (@lines) {
    push(@ret, sprintf "$fmtstr", @$line);
  }
  # push(@ret, $stars);

  return(@ret);
}

# Return string of formatted output of (1d or 2d) vals array.
# If keys provided and array return expected, create sprintf format string.
# If hdgs provided and array return expected, create appropriate heading string.

sub max_cols_print {
  my ($vals, $keys, $hdgs) = @_;

  my @allvals = (defined($hdgs)) ? (@$vals, $hdgs) : (@$vals);
  my $maxes = max_cols(\@allvals);
  my ($fmtstr, $hfmtstr, $sep) = ('', '', '');
  if (defined($keys)) {
    my @keys = @$keys;
    my $i = 0;
    foreach my $max (@$maxes) {
      my $maxval = $maxes->[$i];
      my $keyval = $keys->[$i];
      my $minus = ($keyval eq 's') ? '-' : '';
      $fmtstr .= "${sep}\%${minus}${maxval}${keyval}";
      $hfmtstr .= "${sep}\%-${maxval}s";
      $sep = '  ';
      $i++;
    }
  }
  # print "fmtstr '$fmtstr'\n";

  my $hdgstr = '';
  if (defined($hdgs)) {
    $hdgstr .= sprintf($hfmtstr, @$hdgs);
  }

  return wantarray() ? ($maxes, $fmtstr, $hdgstr) : $maxes;
}

# Return ptr to array of max col widths of given array.

sub max_cols {
  my ($vals) = @_;

  my @maxes = ();
  foreach my $entry (@$vals) {
    my @elems = @$entry;
    # print "Utility::max_cols(): elems '" . join("*", @elems) . "'\n";
    my $i = 0;
    foreach my $elem (@elems) {
      if (defined($maxes[$i])) {
	$maxes[$i] = length($elem) if (length($elem) > $maxes[$i]);
      } else {
	$maxes[$i] = length($elem);
      }
      $i++;
    }
  }
  return \@maxes;
}

################################################################################


package MyDateParser;

use DateTime::Format::Builder
  (
    parsers => {
      parse_datetime => [
	{
	  label => '12/15/2003',
	  regex => qr/^(\d{1,2})\/(\d{1,2})\/(\d{4})$/,
	  params => [qw( month day year )],
	},
	{
	  label => '12/15/03',
	  regex => qr!^(\d{1,2})/(\d{1,2})/(\d{2})$!,
	  params => [qw( month day year )],
	  postprocess => \&fix_year,
	},
	{
	  label => '12-15-2003',
	  regex => qr/^(\d{1,2})-(\d{1,2})-(\d{4})$/,
	  params => [qw( month day year )],
	},
	{
	  label => '2003-12-15',
	  preprocess => \&pre_process,
	  postprocess => \&post_process,
	  regex => qr/^(\d{4})-(\d{1,2})-(\d{1,2})$/,
	  params => [qw( year month day )],
	},

	{
	  label => '031215',
	  regex => qr/^(\d{2})(\d{2})(\d{2})$/,
	  params => [qw( year month day )],
	  postprocess => \&fix_year,
	},
	{
	  label => '20031215',
	  regex => qr/^(\d{4})(\d{2})(\d{2})$/,
	  params => [qw( year month day )],
	},
	{
	  label => '20031215093045',
	  regex => qr/^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})$/,
	  params => [qw( year month day hour minute second )],
	},
	{
	  label => '2003-12-15 09:30:45',
	  regex => qr/^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})$/,
	  params => [qw( year month day hour minute second )],
	},
      ],
    }
  );

sub fix_year {
  my %args = @_;

  my ($date, $p) = @args{qw( input parsed )};
  $p->{year} += $p->{year} > 69 ? 1900 : 2000;
  return 1;
}

sub post_process {
  my %args = @_;

  my ($date, $p) = @args{qw( input parsed )};
  if (($p->{year} == 0) or ($p->{month} == 0) or ($p->{day} == 0)) {
    # print STDERR "Utility::MyDateParser::post_process($date): Bad date\n";
    return 0;
  }

  if ($p->{'year'} < 1000) {
    $p->{year} += $p->{year} > 69 ? 1900 : 2000;
  }
  return 1;
}

sub pre_process {
  my %args = @_;

  my ($date, $p) = @args{qw( input parsed )};
  if ($date =~ /0000/) {
    # print STDERR "Utility::MyDateParser::pre_process($date): Bad date\n";
    return '';
  }
  return $date;
}


1;
