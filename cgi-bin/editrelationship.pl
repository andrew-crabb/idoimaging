#! /usr/local/bin/perl -w

use CGI;
use CGI::Carp qw(fatalsToBrowser warningsToBrowser);
use DBI;
use FindBin qw($Bin);
use lib $Bin;
use Utility;
use radutils;
use bigint;
use strict;
no strict 'refs';

# ------------------------------------------------------------
# Initialize.
# ------------------------------------------------------------

my $cgi = new CGI;
my $ishttp = (defined($ENV{'HTTP_HOST'})) ? 1 : 0;
print $cgi->header() if ($ishttp);
warningsToBrowser(1) if ($ishttp);


my $dbh = hostConnect();
my $title = "Edit Resources";

printStartHTML($cgi, $title) if ($ishttp);
printTitle($cgi, 1) if ($ishttp);

# ------------------------------------------------------------
# Process incoming changes.
# ------------------------------------------------------------

# Get list of relationships before processing incoming.
my %relates = ();
my $rstr = "select * from relationship";
my $rsh = dbQuery($dbh, $rstr);
while (my $ref = $rsh->fetchrow_hashref()) {
  $relates{$ref->{'ident'}} = $ref;
}
tt(scalar(keys(%relates)) . " relationships", $ishttp);

# dumpParams($cgi);
my @params = $cgi->param();
# Check existing values for change.
my @relparams = grep(/^sel_/, @params);
# Extract hash of old relationships indexed by sequential id.
my %relparams = ();
foreach my $relparam (@relparams) {
  my $oldval = $cgi->param($relparam);
  $relparam =~ /^sel_(\d+)_(.+)$/;
  my ($relid, $field) = ($1, $2);
#   tt("relationship $relid field $field value $oldval");
  $relparams{$relid}{$field} = $oldval;
}
# Check old relationships against database.
foreach my $relid (sort {$a <=> $b} keys %relparams) {
  my $relparam = $relparams{$relid};
  my %relparam = %$relparam;
  my $changestr = '';
  my $comma = '';
  my $del_relat = 0;
  foreach my $checkval (qw(prog1 prog2 type date)) {
    my $db_val = $relates{$relid}->{$checkval};
    my $param_val = $relparam->{$checkval};
    if ($db_val ne $param_val) {
      tt("Change in relationship $relid: Field $checkval: Param value $param_val differs from database value $db_val");
      $changestr .= "$comma $checkval = '$param_val'";
      $comma = ',';
      $del_relat = 1 if (($checkval eq 'type') and ($param_val eq $REL_DELREL));
    }
  }
  if ($del_relat) {
    # Delete this relationship.
    my $qstr = "delete from relationship";
    $qstr   .= " where ident = $relid";
    tt($qstr);
    $dbh->do($qstr);
  } elsif (has_len($changestr)) {
    my $qstr = "update relationship";
    $qstr   .= " set $changestr";
    $qstr   .= " where ident = '$relid'";
    tt($qstr);
    $dbh->do($qstr);
  }
}

# Check for new relationship.
my $add_prog1 = $cgi->param('add_prog1');
if (has_len($add_prog1)) {
  my $add_prog2 = $cgi->param('add_prog2');
  my $add_type  = $cgi->param('add_type');
  if (has_len($add_prog2) and has_len($add_type)) {
    my $astr = "insert into relationship";
    $astr   .= " set prog1 = '$add_prog1'";
    $astr   .= ", prog2 = '$add_prog2'";
    $astr   .= ", type = '$add_type'";
    tt($astr);
    $dbh->do($astr);
  }
  $cgi->param('add_prog1', '');
  $cgi->param('add_prog2', '');
  $cgi->param('add_type',  '');
}

# ------------------------------------------------------------
# Gather data for display.
# ------------------------------------------------------------

# Get list of all resources.
%relates = ();
my $str = "select * from relationship";
my $sh = dbQuery($dbh, $str);
while (my $ref = $sh->fetchrow_hashref()) {
  $relates{$ref->{'ident'}} = $ref;
}
tt(scalar(keys(%relates)) . " relationships", $ishttp);

# Get list of all program names.
my %progs = ("" => "--- Select A Program ---");
my $pstr = "select ident, name from program";
$pstr   .= " where ident >= 100";
my $psh = dbQuery($dbh, $pstr);
while (my $pref = $psh->fetchrow_hashref()) {
  $progs{$pref->{'ident'}} = $pref->{'name'};
}
tt(scalar(keys(%progs)) . " progs", $ishttp);
# Sorted list of program keys.
# my @progkeys = sort {definedVal($progs{$a}->{'name'}) cmp definedVal($progs{$b}->{'name'})} keys %progs;
my @progkeys = sort {definedVal($progs{$a}) cmp definedVal($progs{$b})} keys %progs;
@progkeys = ("", @progkeys);
# Add the program idents (have to do this now else wouldn't sort alphabetically).
foreach my $progkey (keys %progs) {
  my $parenval = (has_len($progkey)) ? "($progkey)" : "";
  $progs{$progkey} = "$parenval $progs{$progkey}";
}

# List all relationships.
my $i = 0;
# Sorted list of relationship keys.
my @relatekeys = (sort {$progs{$relates{$a}->{'prog1'}} cmp $progs{$relates{$b}->{'prog1'}}} keys %relates);
foreach my $rkey (@relatekeys) {
  my $relat = $relates{$rkey};
  my %relat = %$relat;
  my ($ident, $prog1, $prog2, $type, $date) = @relat{(qw(ident prog1 prog2 type date))};
  my $p1name = "$progs{$prog1}";
  my $p2name = "$progs{$prog2}";
  my $relname = $radutils::relationships{$type};
  my $outstr = sprintf("%4d: %-30s %-10s %-30s\n", $ident, $p1name, $relname, $p2name);
  tt($outstr, $ishttp);
  # Append to hash.
  $relates{$rkey}->{'prog1name'} = $p1name;
  $relates{$rkey}->{'prog2name'} = $p2name;
  $relates{$rkey}->{'relname'} = $relname;

  $i++;
}

# Sorted keys of relationship types (text).
my @relate_keys = ("", $REL_ISNOW, $REL_ISPARTOF, $REL_DELREL);

print $cgi->startform(-action => $STR_EDIT_RELAT) . "\n";
print "<table>\n";
print "<tr>\n<td colspan = '5' align = 'center'>Existing Relationships</td>\n</tr>\n";

foreach my $relatekey (@relatekeys) {
  my $relat = $relates{$relatekey};
  my $relat_id = $relat->{'ident'};

  # Selectors for existing relationshipes.
  
  my $p1sel = $cgi->popup_menu(
    -name    => "sel_${relat_id}_prog1",
    -values  => \@progkeys,
    -labels  => \%progs,
    -default => $relat->{'prog1'},
      );

  my $p2sel = $cgi->popup_menu(
    -name    => "sel_${relat_id}_prog2",
    -values  => \@progkeys,
    -labels  => \%progs,
    -default => $relat->{'prog2'},
      );

  my $relsel = $cgi->popup_menu(
    -name    => "sel_${relat_id}_type",
    -values  => \@relate_keys,
    -labels  => \%radutils::relationships,
    -default => $relat->{'type'},
      );

  my $datesel = $cgi->textfield(
    -name    => "sel_${relat_id}_date",
    -default => $relat->{'date'},
    -size    => 11,
      );

  print "<tr>\n";
  print "<td>$relat->{'ident'}</td>\n";
  print "<td>$p1sel</td>\n";
  print "<td>$relsel</td>\n";
  print "<td>$p2sel</td>\n";
  print "<td>$datesel</td>\n";
  print "</tr>\n";
}

# Selectors for new relationship.
my $p1sel = $cgi->popup_menu(
  -name    => "add_prog1",
  -values  => \@progkeys,
  -labels  => \%progs,
  -default => "",
    );

my $p2sel = $cgi->popup_menu(
  -name    => "add_prog2",
  -values  => \@progkeys,
  -labels  => \%progs,
  -default => "",
    );

my $relsel = $cgi->popup_menu(
  -name    => "add_type",
  -values  => \@relate_keys,
  -labels  => \%radutils::relationships,
  -default => "",
    );

my $datesel = $cgi->textfield(
  -name    => 'add_date',
  -default => today(),
  -size    => 11,
    );

print "<tr>\n<td colspan = '5' align = 'center'>Add New Relationship</td>\n</tr>\n";
print "<tr>\n";
print "<td>&nbsp;</td>\n";
print "<td>$p1sel</td>\n";
print "<td>$relsel</td>\n";
print "<td>$p2sel</td>\n";
print "<td>$datesel</td>\n";
print "</tr>\n";

print "<tr><td colspan = '5' align = 'center'>" . $cgi->submit() . "</td></tr>\n";
print $cgi->endform() . "\n";


print "</table>\n";

