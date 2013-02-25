#! /usr/local/bin/perl -w

# Synchronize database between local and server.
# Note that Compare would work better if I added a timestamp field to each table.
# For now, just count table entries.
# See: bit.ly/onGSSy

use strict;
no strict 'refs';
use FindBin qw($Bin);
use lib $FindBin::Bin;
use lib Cwd::abs_path($FindBin::Bin . '/../lib');
use Utility;
use CGI;

# Including for just this one program.
use lib '/Users/ahc/BIN/perl/lib';
use Utilities_new;

use radutils;
use Percona;

my $DB_IMAGING = 'db_imaging';
my $DB_TEST = 'db_test';
my $DB_DATABASE = 'db_database';
my $DB_TABLES = 'db_tables';
my %dbs = (
  $DB_IMAGING => {
    $DB_DATABASE => 'imaging',
    # $DB_TABLES => [qw(author format image monitor program redirect related resource version)],
    # $DB_TABLES => [qw(author format image monitor program related resource version)],
    $DB_TABLES => [qw(author format image program related resource version)],
  },
  $DB_TEST => {
    $DB_DATABASE => 'test',
    $DB_TABLES => [qw(dfile imagefile recon scan)],
  }
);

# Get options if running from command line.
my $OPT_COMPARE   = 'c';
my $OPT_REVERSE   = 'r';
my $OPT_TABLE     = 't';
my $OPT_TEST      = 'e';
my %allopts = (
  $OPT_COMPARE => {
    $OPTS_NAME => 'compare',
    $OPTS_TYPE => $OPTS_BOOL,
    $OPTS_TEXT => 'Show comparison of DB between server and local.',
  },
  $OPT_REVERSE => {
    $OPTS_NAME => 'reverse',
    $OPTS_TYPE => $OPTS_BOOL,
    $OPTS_TEXT => 'Reverse sync (from server to local).',
  },
  $OPT_TEST => {
    $OPTS_NAME => 'test',
    $OPTS_TYPE => $OPTS_BOOL,
    $OPTS_TEXT => 'Use test database (default: imaging).',
  },
  $OPT_TABLE => {
    $OPTS_NAME => 'table',
    $OPTS_TYPE => $OPTS_STRING,
    $OPTS_TEXT => 'Table to sync.',
  },
);

our $cgi = undef;
my $opts = undef;
my $is_http = is_apache_environment();
if ($is_http) {
  # Running in browser.
  $cgi = CGI->new();
  print $cgi->header();
  $opts = process_opts(\%allopts, $cgi);
} else {
  # Running from command line.
  $opts = process_opts(\%allopts);
  if ($opts->{$OPT_HELP}) {
    usage(\%allopts);
    exit;
  }
}
exit unless (is_admin_or_cli(1));
my ($reverse, $test, $dummy, $verbose) = @{$opts}{($OPT_REVERSE, $OPT_TEST, $OPT_DUMMY, $OPT_VERBOSE)};

if ($is_http) {
  printHashAsTable($opts, 0, 'synchronize_db');
} else  {
  printHash($opts, "synchronize_db opts");
}

if ($is_http) {
  print "<tr><td class='white' id='container1'>\n";
} else {
  print "Table   Entries   Updates   Adds   Deletes   Changes\n";
}
tt("(dummy, verbose, test, reverse) = ($dummy, $verbose, $test, $reverse)", $is_http);

# Select database and tables list.
my $db_key = $test ? $DB_TEST : $DB_IMAGING;
my $db_rec = $dbs{$db_key};
my $db     = $db_rec->{$DB_DATABASE};
my $tables = $db_rec->{$DB_TABLES};
my @tables = @$tables;
print "<tt>db '$db', tables '" . join('*', @tables) . "'</tt><br>\n";

if ($opts->{$OPT_COMPARE}) {
  # print "Compare databases\n";
  my @lines = ();
  my %attr = (RaiseError => 1);
  my $dsn_local  = "DBI:mysql:$db";
  my $dsn_remote = "DBI:mysql:$db:idoimaging.com";
  my $dbh_local  = DBI->connect($dsn_local ,'_www','PETimage', \%attr);
  my $dbh_remote = DBI->connect($dsn_remote,'_www','PETimage', \%attr);
  die unless ($dbh_local and $dbh_remote);
  foreach my $table (@tables) {
    my $str = "select count(*) from $table";
    my $sh_local  = dbQuery($dbh_local , $str);
    my $sh_remote = dbQuery($dbh_remote, $str);
    if ($sh_local and $sh_remote) {
      my ($cloc) = $sh_local->fetchrow_array();
      my ($crem) = $sh_remote->fetchrow_array();
      # print "$table: local $cloc remote $crem\n";
      my $local  = sprintf("%6d %s", $cloc, ($cloc > $crem) ? '+' : '');
      my $remote = sprintf("%6d %s", $crem, ($crem > $cloc) ? '+' : '');
      my $remote_plus = ($cloc < $crem) ? '+' : '';
      push(@lines, [$table, $local, $remote]);
    } else {
      print "ERROR: dbQuery returned null\n";
    }
  }
  my @hdgs = qw/Table Local Remote/;
  my @keys = qw/s s s/;
  print_array(\@lines, \@keys, \@hdgs, $is_http);
  exit;
}

our @rslts = ();
foreach my $table (@tables) {
  # For tables monitor, and redirect, 'source' dbh is remote, and 'dest' is local.
  # All others are source local, dest remote (subscribers are updated at production site).
  unless ($opts->{$OPT_TABLE} and ($opts->{$OPT_TABLE} ne $table)) {
    my ($sourcesite, $destsite);
    if ($reverse or ($table =~ /monitor|redirect/)) {
      # Info source is remote (production) site.
      $sourcesite = 'idoimaging.com';
      $destsite   = 'localhost';
    } else {
      # Info source is local (development) site.
      $sourcesite = 'localhost';
      $destsite   = 'idoimaging.com';
    }
    my $perc = Percona->new();
    my %args = (
      $Percona::SOURCE_SITE => $sourcesite,
      $Percona::DEST_SITE   => $destsite,
      $Percona::DATABASE    => $db,
      $Percona::TABLE       => $table,
    );
    my $rslt = $perc->pt_table_sync(\%args, $opts);
    my @rslt_row = @{$rslt}{($DB_TBL, $DELETE, $REPLACE, $INSERT, $UPDATE, $ELAPSED)};
    push(@rslts, \@rslt_row);
  }
}

# UP TO HERE
# http://stackoverflow.com/questions/799968/whats-the-difference-between-perls-backticks-system-and-exec

print_results(\@rslts, $is_http);
if ($is_http) {
  print "</td> <!-- container1 -->\n";
  print "</tr>\n";
}

sub print_results {
  my ($rslts, $is_http) = @_;
  $is_http //= 0;

  my @hdgs = qw/Table Delete Replace Insert Update Elapsed/;
  my @keys = qw/s i i i i i/;

  if ($is_http) {
    print "<table>\n";
    print "<tr>\n";
    print $cgi->th({-class=>'andy'}, \@hdgs) . "\n";
    print "</tr>\n";
    foreach my $rslt_row (@rslts) {
      print "<tr>\n";
      print $cgi->td({-class=>'crabb'}, $rslt_row) . "\n";
      print "</tr>\n";
    }
    print "</table>\n";
  } else {
    my ($maxes, $fmtstr, $hdgstr) = max_cols_print(\@rslts, \@keys, \@hdgs);

    printf("$hdgstr\n", @hdgs);
    foreach my $rslt_row (@rslts) {
      printf("$fmtstr\n", @$rslt_row);
    }
  }
}
