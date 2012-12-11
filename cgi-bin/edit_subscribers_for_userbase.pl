#! /usr/local/bin/perl -w

use DBI;
use FindBin qw($Bin);
use lib $Bin;
use radutils;
use Utilities_new;
use bigint;
use strict;
no strict 'refs';

my $dbh   = hostConnect('imaging');
my $dbh_u = hostConnect('userbase');

# Build a list of UserBase users by email.
my $str = "select * from userbase_users";
my $sh = dbQuery($dbh_u, $str);
my %ub_users = ();
while (my $ref = $sh->fetchrow_hashref()) {
  my $ub_id = $ref->{'id'};
  my $ub_email = $ref->{'username'};
  if (hasLen($ub_email)) {
    $ub_users{$ub_email} = $ub_id;
  }
}
print scalar(keys %ub_users) . " users in userbase\n";

# Build list of subscribers id by email.
$str = "select * from subscribers";
$sh = dbQuery($dbh, $str);
my %subscribers = ();
while (my $ref = $sh->fetchrow_hashref()) {
  # my $sub_id = $ref->{'ident'};
  my $sub_email = $ref->{'Email'};
  $subscribers{$sub_email} = $ref;
}

# Build list of programs monitored by subscribers.
my %monitors = ();
$str = "select * from monitor";
# $str .= " where userid < 20";
$sh = dbQuery($dbh, $str);
while (my $ref = $sh->fetchrow_hashref()) {
  my $monid = $ref->{'ident'};
  my $userid = $ref->{'userid'};
  push(@{$monitors{$userid}}, $monid);
}

my $i = 0;
foreach my $ub_email (sort keys %ub_users) {
  # printf "%-30s: ", $ub_email;
  # Update monitor records with userbase user id's.
  my $ub_id = $ub_users{$ub_email};
  if (defined(my $sub_rec = $subscribers{$ub_email})) {
    my $sub_id = $sub_rec->{'ident'};

    # Update userbase record with account creation time from subscribers.
    my $sub_date = $sub_rec->{'Date_Applied'};
    my $epoch_time = convertDates($sub_date)->{$DATES_SECS};
    $str = "update userbase_users set cdate = '$epoch_time' where id = '$ub_id'";
     $sh = dbQuery($dbh_u, $str);
    # print "$epoch_time  ";

    my $mon_ref = $monitors{$sub_id};
    my @mon = (defined($mon_ref)) ? sort {$a <=> $b} @$mon_ref : ();
    my $mon_str = join(" ", @mon);
    my $n_mon = scalar(@mon);
    # printf(" UB id %5d, sub id %5d, %3d monitors: %s\n", $ub_id, $sub_id, $n_mon, $mon_str);
    foreach my $mon_id (@mon) {
      $str = "update monitor set userid = '$ub_id' where ident = '$mon_id'";
       $sh = dbQuery($dbh, $str);
      # print "$str\n";
    }
  } else {
    print "Not defined: subscribers{$ub_email}\n";
  }
  # last if ($i++ > 100);
}

exit;
