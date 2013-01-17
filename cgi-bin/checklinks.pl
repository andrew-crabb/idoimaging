#! /usr/local/bin/perl -w
# checklinks.pl
# Check each URL listed in program table; update urlstat for this entry.

use strict;
no strict 'refs';
use CGI;
use CGI::Carp 'fatalsToBrowser';
use DBI;
use Getopt::Std;

use FindBin qw($Bin);
use lib $Bin;
use radutils;
use httputils;

$| = 1;
my %opts;
getopts('adlprsSuw', \%opts);

our $do_all      = ($opts{'a'}) ? 1 : 0;
our $dummy       = ($opts{'d'}) ? 1 : 0;
our $local       = ($opts{'l'}) ? 1 : 0;
our $do_program  = ($opts{'p'}) ? 1 : 0;
our $do_resource = ($opts{'r'}) ? 1 : 0;
our $do_author   = ($opts{'u'}) ? 1 : 0;
our $do_status   = ($opts{'s'}) ? 1 : 0;
our $do_down     = ($opts{'w'}) ? 1 : 0;
$do_status       = ($opts{'S'}) ? 0 : 1;

if ($do_all) {
  $do_program = $do_resource = $do_author = 1;
}
print "Options: program $do_program resource $do_resource author $do_author \n";
unless ($do_program or $do_resource or $do_author) {
  usage();
  exit 1;
}

$local = 0 unless (hasLen($local) and $local);
my $dbh = hostConnect('', $local);

# Digit suffixes appended to table name to allow duplicates.
our %tables = (
  'author'   => ['home',    'urlstat'],
  'program'  => [['homeurl', 'srcurl'], ['urlstat', 'srcstat']],
  'resource' => ['url',     'urlstat'],
    );

foreach my $table (sort keys %tables) {
  next if (scalar(@ARGV) and ($table !~ "program"));
  my $checkvar = "do_${table}";
  next unless ($$checkvar);
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
    if (hasLen($id)) {
      $condstr   .= " $junction name like '$id\%'";
      $junction = "and";
    }
    if ($table =~ /program/i) {
      $condstr .= " $junction ident >= 100";
      $junction = "and";
      if ($do_down) {
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
    if ($do_down) {
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
#   my ($pname, $ident, $currstat) = @element{qw(name ident urlstat)};
  my ($pname, $ident, $currstat) = @element{qw(name ident $statfld)};
  $currstat = 0 unless (hasLen($currstat) and $currstat);
  my $url = $element{$urlfld};

  my $date_today = today();
  return 0 unless (hasLen($url));
  my $link_is_up = checkLinkStatus($href, $urlfld);

  # Record this date in 'program.urldate' field if link is up.
  if ($link_is_up) {
    my $str = "update program";
    $str .= " set urldate = '$date_today'";
    $str .= " where ident = '$ident'";
    if ($dummy) {
      print "$str\n";
    } else {
      my $sh = dbQuery($dbh, $str);
    }
  } else {
    print "link_is_up is false\n";
  }

  print "*** checklink(pname $pname, statfld $statfld, table $table, urlfld $urlfld): link_up $link_is_up, currstat $currstat\n";

#   # Update status field in 'status' table.
#   # Only insert a record if the status has changed.
#   my $str = "select * from status";
#   $str   .= " where progid = '$ident'";
#   $str   .= " order by date desc";
#   my $sh = dbQuery($dbh, $str);
#   my $db_status = undef;
#   if (my $statptr = $sh->fetchrow_hashref()) {
#     $db_status = $statptr->{'status'};
#   }
#   # Insert a new status record if there wasn't one before, or if the status has changed.
#   if (!defined($db_status) or ($db_status != $link_is_up)) {
#     print "\nchecklink($statfld, $table, $urlfld): $pname ($ident) old status $currstat new status $link_is_up\n";
#     $str = "insert into status set";
#     $str .= " progid = '$ident',";
#     $str .= " date = '$date_today',";
#     $str .= " status = '$link_is_up'";
# #     print "\n$str\n";
#     unless ($dummy) {
#       $dbh->do($str);
#     }
#   } else {
#     if ($dummy) {
#       print "Program $ident status remains $link_is_up\n";
#     }
#   }

  # Update status field in relevant table (program, author, resource).
  my $str;
  if ($currstat != $link_is_up) {
    $str = "update $table set $statfld = '$link_is_up' where ident = '$ident'";
    if ($dummy) {
      print "\n$str\n";
    } else {
      $dbh->do($str);
    }
  } else {
    print ".";
  }
}

sub usage {
  print "Usage: checklinks [-adDpru] <progname>\n";
  print "-a: All\n";
  print "-d: Dummy\n";
#   print "-s: Status: Update 'status' table in database\n";
#   print "-S: No database update\n";
  print "-p: Program\n";
  print "-r: Resources\n";
  print "-u: Author\n";
  print "-w: Down links only\n";
}
