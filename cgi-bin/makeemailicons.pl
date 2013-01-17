#! /usr/local/bin/perl -w

use DBI;
use Getopt::Std;

use FindBin qw($Bin);
use lib $Bin;
use radutils;

my %opts;
getopts('fh', \%opts);
if (defined($opts{'h'})) {
  print "Usage: makeemailicons [-f]\n";
  print "   -f: Force recreate duplicate icon files\n";
  exit;
}
my $force = (defined($opts{'f'})) ? 1 : 0;

my $dbh = hostConnect();
my $emaildir = "/img/email";

my $who = (scalar(@ARGV)) ? "where name_last like '$ARGV[0]%'" : "";

my $str = "select ident, email from author $who order by ident";
my $sh = dbQuery($dbh, $str, 1);
my $ptr = $sh->fetchall_arrayref;
foreach my $pptr (@$ptr) {
  my ($ident, $email) = @$pptr;
  $email = '' unless (hasLen($email));
  print "Processing ($ident, $email)\n";
  next unless ($ident and $email);
  my $filename = sprintf("${emaildir}/email_%04d.gif", $ident);
  if ((-s $filename) and not $force) {
    print "Skipping duplicate $ident $email\n";
  } else {
    print "Creating $ident $email\n";
    makeemailicon($ident, $email);
  }
}
