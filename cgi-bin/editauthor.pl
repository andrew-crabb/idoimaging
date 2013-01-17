#! /usr/local/bin/perl -w
# Process an add/edit, or show table to edit one record, or list all records for editing.
# case ident  add  process
# 0    0      0    0       Show list, set ident for each element.
# 1    0      0    1       Error
# 2    0      1    0       Show empty table, set process, ident, add (-> 7).
# 3    0      1    1       Error
# 4    1      0    0       Show filled table, set process, ident (-> 5).
# 5    1      0    1       Process an edit of existing record.
# 6    1      1    0       Error
# 7    1      1    1       Process an add of a new record.

use strict;
use CGI;
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);
use DBI;
use FindBin qw($Bin);
use lib $Bin;
use radutils;
use Userbase;
use constants;

# ------------------------------------------------------------
# Constants.
# ------------------------------------------------------------

my @author_fields = (qw(ident name_last name_first email home country));

my $cgi = new CGI;
print $cgi->header();
warningsToBrowser(1);
exit unless (is_admin_or_cli());

dumpParams($cgi);
my ($ident, $add, $process) = getParams($cgi, (qw(ident add process)));
my $dbh = hostConnect('');

my $title = "I Do Imaging - Edit Author";
printRowWhiteCtr($cgi->h1($title));

# Fetch existing record if performing edit, or table to edit one record.
my $href = (hasLen($ident)) ? dbRecord($dbh, "author", $ident) : undef;

if (($ident and not $add) or ($add and not $ident)) {
  # add set: case 2, show empty table, set process, ident, add (goes to case 7).
  # ident set: case 5, show filled table, set process and ident (goes to case 5).
  my @lines = ();
  foreach my $vname (@author_fields) {
    my $val = (hasLen($ident)) ? $href->{$vname} : '';

    if ($vname eq 'ident') {
      $val = ($val or nextIdent($dbh, "author"));
    }
    if (($vname eq 'home') and hasLen($ident)) {
      $val =~ s{/http://}{};
      $val =~ s/\/$//;
    }

    my $fldstr;
    if ($vname eq 'country') {
      # Select country codes from drop-down list.
      my %revcountries = reverse(%countries);
      my @countries = sort {$countries{$a} cmp $countries{$b}} keys (%countries);
      $fldstr = $cgi->popup_menu(
	-name    => "au_${vname}",
	-values  => \@countries,
	-labels  => \%countries,
	-default => $val,
      );
    } else {
      $fldstr = $cgi->textfield(
	-name    => "au_${vname}",
	-default => $val,
      );
    }

    push(@lines, [$vname, $fldstr]);
  }

  print $cgi->startform(-action => ${STR_DO_EDIT_AUTH}) . "\n";
  print $cgi->hidden(-name => 'process', -value => 1) . "\n";
  print $cgi->hidden(-name => 'ident', -value => $ident) . "\n";
  print $cgi->hidden(-name => 'add', -value => 1) . "\n" if ($add);

  print "<table>\n";
  foreach my $line (@lines) {
    print "<tr>\n";
    print "<th>$line->[0]</th>\n";
    print "<td>$line->[1]</td>\n";
    print "</tr>\n";
  }
  print "</table>\n";
  print $cgi->submit() . "\n";
  print $cgi->endform() . "\n";

  exit;
} else {
  # No author ident specified: Display list.
  my $str = "select * from author order by name_last, name_first";
  my $sh = dbQuery($dbh, $str);
  print "<table>\n";
  my @titles = (qw(Ident Name Email URL));
  print $cgi->Tr({-align => 'left'}, $cgi->th([@titles])) . "\n";

  while (my $href = $sh->fetchrow_hashref()) {
    my $id = $href->{'ident'};
    my $lstr = '';
    foreach my $vname (qw(ident name email home)) {
      my $val;
      if ($vname =~ /name/) {
	my $fmtname = fmtAuthorName($id, $dbh);
	$val = "<a href=${STR_EDIT_AUTHOR}?ident=$id>$fmtname</a>" ;
      } elsif ($vname =~ /home/) {
	my $url = $href->{$vname};
	$url = "&nbsp;" unless (hasLen($url));
	$val = "<a target='new' href='http://$url'>$url</a>";
      } else {
	$val = $href->{$vname};
      }
      $val = definedVal($val);
      my $dispval = $val;
      $lstr .= $cgi->td($dispval);
    }
    print $cgi->Tr($lstr) . "\n";
  }
  print "</table>\n";
}
