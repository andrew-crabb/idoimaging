#! /usr/local/bin/perl -w
# checklinks.pl
# Check each URL listed in program table; update urlstat for this entry.

use strict;
no strict 'refs';
use CGI;
use CGI::Carp;
use DBI;
use Getopt::Std;
use Opts;

use FindBin qw($Bin);
use lib $Bin;
use Utility;
use radutils;
use httputils;

$| = 1;

# our $do_program  = ($opts{'p'}) ? 1 : 0;
# our $do_resource = ($opts{'r'}) ? 1 : 0;
# our $do_down     = ($opts{'w'}) ? 1 : 0;

# Options.
my $OPT_ALL      = 'a';
my $OPT_PROGRAM  = 'p';
my $OPT_RESOURCE = 'r';
my $OPT_DOWN     = 'w';

my $usage_note = <<END_USAGE;
This is a note.
END_USAGE

my %allopts = (
  $OPT_ALL => {
    $OPTS_NAME => 'do_all',
    $OPTS_TYPE => $OPTS_BOOL,
    $OPTS_TEXT => 'Do all.',
  },
  $OPT_PROGRAM => {
    $OPTS_NAME => 'do_program',
    $OPTS_TYPE => $OPTS_BOOL,
    $OPTS_TEXT => 'Do program.',
  },
  $OPT_RESOURCE => {
    $OPTS_NAME => 'do_resource',
    $OPTS_TYPE => $OPTS_BOOL,
    $OPTS_TEXT => 'Do resource.',
  },
  $OPT_DOWN => {
    $OPTS_NAME => 'do_down',
    $OPTS_TYPE => $OPTS_BOOL,
    $OPTS_TEXT => 'Do down-links.',
  },
  $Opts::OPT_NOTE => {
    $OPTS_TEXT => $usage_note,
  },
);

my $opts = Opts::process_opts(\%allopts);
if ($opts->{$OPT_ALL}) {
  $opts->{$OPT_PROGRAM} = $opts->{$OPT_RESOURCE} = 1;
}

if ($opts->{$Opts::OPT_HELP} or not ($opts->{$OPT_PROGRAM} or $opts->{$OPT_RESOURCE})) {
  Opts::usage(\%allopts);
  exit;
}

my $dbh = hostConnect('');

our %tables = (
  'program'  => [['homeurl', 'srcurl'], ['urlstat', 'srcstat']],
  'resource' => ['url',     'urlstat'],
    );
foreach my $table (sort keys %tables) {
  next if (scalar(@ARGV) and ($table !~ "program"));
  my $checkvar = "do_${table}";
#  next unless ($$checkvar);
  my $program_name = $ARGV[0];
  checkTable($dbh, $table, $program_name);
}
$dbh->disconnect();

sub checkTable {
  my ($dbh, $table, $id) = @_;

  my ($urlflds, $statflds) = @{$tables{$table}};
  $table =~ s/_\d+$//;

  my (@urlflds, @statflds) = ((), ());
  if (ref($urlflds)) {
    @urlflds = @$urlflds;
    @statflds = @$statflds;
  } else {
    @urlflds = ($urlflds);
    @statflds = ($statflds);
  }

  my $numflds = scalar(@urlflds);
  for (my $i = 0; $i <= ($numflds - 1); $i++) {
    my $urlfld = $urlflds[$i];
    my $statfld = $statflds[$i];

    print "** numflds $numflds, i $i, urlfld $urlfld, statfld $statfld\n";

    my ($condstr, $junction) = ("", "where");
    if (has_len($id)) {
      $condstr   .= " $junction name like '$id\%'";
      $junction = "and";
    }
    if ($table =~ /program/i) {
      $condstr .= " $junction ident >= 100";
      $junction = "and";
      if ($opts->{$OPT_DOWN}) {
        $condstr .= " $junction urlstat = 0";
      }
    }

    print "*** Checking table $table (field $urlfld) ***\n";
    my $str = "select * from $table";
    $str   .= " $condstr" if (length($condstr));
    $str   .= " order by ident";
    print "$str\n";

    # Build array of DB elements matching conditions.
    my $sh = dbQuery($dbh, $str);
    my @hrefs = ();
    while (my $href = $sh->fetchrow_hashref()) {
      push(@hrefs, $href);
    }
    print scalar(@hrefs) . " matching records\n";

    # Print summary before checking, if checking program links that are down.
    if ($opts->{$OPT_DOWN}) {
      print "Checking following down links:\n";
      foreach my $href (sort {$a->{'name'} cmp $b->{'name'}} @hrefs) {
        printf("%03d %s\n", $href->{'ident'},  $href->{'name'});
      }
    }

    # Perform check on each matching program.
    foreach my $href (sort {$a->{'name'} cmp $b->{'name'}} @hrefs) {
      checklink($href, $statfld, $table, $urlfld);
    }
    print "\n";
  }
}

sub checklink {
  my ($href, $statfld, $table, $urlfld) = @_;
  my %element = %$href;
  my ($pname, $ident, $currstat) = @element{qw(name ident $statfld)};
  $currstat = 0 unless (has_len($currstat) and $currstat);
  my $url = $element{$urlfld};

  my $date_today = today();
  return 0 unless (has_len($url));
  my $link_is_up = checkLinkStatus($href, $urlfld);

  # Record this date in 'program.urldate' field if link is up.
  if ($link_is_up) {
    my $str = "update program";
    $str .= " set urldate = '$date_today'";
    $str .= " where ident = '$ident'";
    if ($opts->{$Opts::OPT_DUMMY}) {
      print "$str\n";
    } else {
      my $sh = dbQuery($dbh, $str);
    }
  } else {
    print "link_is_up is false\n";
  }

  print "*** checklink(pname $pname, statfld $statfld, table $table, urlfld $urlfld): link_up $link_is_up, currstat $currstat\n";

  # Update status field in relevant table (program, resource).
  my $str;
  if ($currstat != $link_is_up) {
    $str = "update $table set $statfld = '$link_is_up' where ident = '$ident'";
    if ($opts->{$Opts::OPT_DUMMY}) {
      print "\n$str\n";
    } else {
      $dbh->do($str);
    }
  } else {
    print ".";
  }
}
