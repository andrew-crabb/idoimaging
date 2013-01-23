#! /usr/local/bin/perl -w

use CGI;
use CGI::Carp;
use DBI;
use Getopt::Std;

use FindBin qw($Bin);
use radutils;

# Global constants.
my $SITEPERL = '/opt/local/siteperl/bin';
my $PT_TABLE_SYNC = 'pt-table-sync';

# Get options if running from command line.
my $OPT_REVERSE   = 'r';
my %allopts = (
  $OPT_REVERSE => {
    $OPTS_NAME => 'reverse',
    $OPTS_TYPE => $OPTS_BOOL,
    $OPTS_TEXT => 'Reverse sync (from server to local).',
  },
);

our ($dummy, $reverse, $verbose) = (0, 0, 0);

if (is_apache_environment()) {
  # Running in browser.
  ($dummy, $reverse) = getParams($cgi, (qw(Dummy Reverse)));
} else {
  # Running from command line.
  my $opts = process_opts(\%allopts);
  if ($opts->{$OPT_HELP}) {
    usage(\%allopts);
    exit;
  }
  $reverse = $opts->{$OPT_HELP};
  $dummy = $opts->{$OPT_DUMMY};
  $verbose = $opts->{$OPT_VERBOSE};
}

$cgi = new CGI;
print $cgi->header();

# printStartHTML($cgi);
# printTitle($cgi);

dumpParams($cgi);
our ($dummy, $reverse) = getParams($cgi, (qw(Dummy Reverse)));
tt("(dummy, reverse) = ($dummy, $reverse)");

print "<tr><td class='white'>\n";
print "<table cellspacing=0 cellpadding=2 border=0>\n";
print "<th>Table</th><th>Entries</th><th>Updates</th><th>Adds</th><th>Deletes</th><th>Changes</th>\n";

# Local and remote dbh's.
my $ldbh = hostConnect();
my $rdbh = DBI->connect("DBI:mysql:imaging:idoimaging.macminicolo.net","_www","PETimage");
die("No local DB:  $DBI::errstr") unless ($ldbh);
die("No remote DB: $DBI::errstr") unless ($rdbh);

foreach my $table (qw(author format image monitor program redirect related resource version)) {
# foreach my $table (qw(resource)) {
  # For tables monitor, and redirect, 'source' dbh is remote, and 
  # 'dest' is local.  All others are source local, dest remote.  This is because 
  # subscribers update themseleves at the remote (production) site.
  my ($sourcedbh, $destdbh);
  my ($sourcesite, $destsite);
  if ($reverse or ($table =~ /monitor|redirect/)) {
    # Info source is remote (production) site.
    $sourcedbh = $rdbh;
    $destdbh = $ldbh;
    $sourcesite = "Remote";
    $destsite = "Local";
  } else {
    # Info source is local (development) site.
    $sourcedbh = $ldbh;
    $destdbh = $rdbh;
    $sourcesite = "Local";
    $destsite = "Remote";
  }

  my $str = "select * from $table order by ident";
#   tt("Processing table $table: Source $sourcesite, Dest $destsite: $str");
  my $sourcesh = dbQuery($sourcedbh, $str);
  my $destsh   = dbQuery($destdbh, $str);
  die unless ($sourcesh and $destsh);

  # Build hash of ident to element arrays for source and dest.
  # Assumption: table elements indexed by 'ident'.
  # NOTE: Global variables.
  local (%srcvals, %dstvals);
  while (my $srcref = $sourcesh->fetchrow_hashref()) {
    $srcvals{$srcref->{'ident'}} = $srcref;
  }
  while (my $dstref = $destsh->fetchrow_hashref()) {
    $dstvals{$dstref->{'ident'}} = $dstref;
  }
  tt("table $table: srcvals ($sourcesite) has " . scalar(keys(%srcvals)) . " elements, dstvals ($destsite) has " . scalar(keys(%dstvals)) . " elements");

  # User id's changed 

  # Iterate through source values.  Three cases:
  # 1. Source, Dest present: Element-wise update of Dest from Source.
  # 2. Dest missing: Insert Source element into Dest.
  # 3. Source missing: Delete element from Dest.

  my ($count, $updates, $adds, $deletes) = (0, 0, 0, 0);
  foreach my $ident (sort {$a <=> $b} keys %srcvals) {
    $count++;
    if (defined ($dstvals{$ident})) {
      # Case 1: Present in source and dest.  Check for updates to dest.
      $updates += updateRecord($destdbh, $table, $ident, $destsite);
    } else {
      # Case 2: Present in source, not dest.  Add to dest.
      $adds += addRecord($destdbh, $table, $ident, $destsite);
    }
  }

  # Remaining members of dest are those missing from source.
  foreach my $dstident (sort {$a <=> $b} keys %dstvals ) {
    # Case 3: Present in dest but not source.  Delete from dest.
    my $str = "delete from $table where ident = '$dstident'";
    if ($dummy) {
      tt("$destsite: destdbh->do($str)");
    } else {
      tt("$destsite: destdbh->do($str)");
    }
    $deletes++;
  }
  my $changes = $updates + $adds + $deletes;
  my $linestr = "<tr>\n";
  $linestr .= "<td>$table</td><td>$count</td><td>$updates</td><td>$adds</td><td>$deletes</td><td>$changes</td>\n";
  $linestr .= "</tr>\n";
  print $linestr;
}
print "</table>\n";
print "</td></tr>\n";

sub updateRecord {
  my ($dbh, $table, $ident, $destsite) = @_;
  my %srchash = %{$srcvals{$ident}};
  my %dsthash = %{$dstvals{$ident}};

  my $updates = 0;
  my ($updatestr, $comma) = ("", "");
  foreach my $key (sort keys %srchash) {
    my $srcval = defined($srchash{$key}) ? $srchash{$key} : "";
    my $dstval = defined($dsthash{$key}) ? $dsthash{$key} : "";
    $srcval =~ s/'/\\'/g;
    $dstval =~ s/'/\\'/g;
    if ($dstval ne $srcval) {
      $updatestr .= "$comma $key = '$srcval'";
      $comma = ",";
      $updates = 1;
    }
  }
  if ($updates) {
    my $astr = "update $table set $updatestr where ident = '$ident'";
    if ($dummy) {
      tt("$destsite: dbh->do($astr)");
    } else {
      $dbh->do($astr);
    }
  }
  # Delete dest val so remainders are those missing from source.
  delete $dstvals{$ident};
  return $updates;
}

sub addRecord {
  my ($dbh, $table, $ident, $destsite) = @_;
  my %srchash = %{$srcvals{$ident}};

  my $deletes = 0;
  my ($astr, $comma) = ("", "");
  foreach my $key (sort keys %srchash) {
    my $srcval = $srchash{$key};
    if (defined($srcval)) {
      $srcval =~ s/'/\\'/g;
      $astr .= "$comma $key = '$srcval'";
      $comma = ",";
      $deletes = 1;
    }
  }
  if ($deletes) {
    my $astr = "insert into $table set $astr";
    if ($dummy) {
      tt("$destsite: dbh->do($astr)");
    } else {
      $dbh->do($astr);
    }
#      tt("$astr");
  }
  return $deletes;
}
