#! /usr/local/bin/perl -w

use CGI;
use CGI::Carp qw(fatalsToBrowser warningsToBrowser);
use DBI;
use FindBin qw($Bin);
use lib $Bin;
use Utility;
use radutils;
use radutils qw($DB_INT $DB_CHR $DB_BEN $DB_DAT $DB_FLT);
use strict;
no strict 'refs';

# Get params early: may redirect in header if ident & Add set.
my $cgi = new CGI;
my $ident   = $cgi->param('ident');	# If set, we are editing this resource.
my $doAdd   = $cgi->param('Add');	# If set, we are adding a new resource.
my $dbtable = $cgi->param('DBtable');	# This program handles any table.

my $dbh = hostConnect();
my $title = "idoimaging - edit data";

# ========== TEMP NOT PRINTING REDIRECT HEADER ==========
# unless (has_len($ident) and has_len($doAdd)) {
  print $cgi->header();
  dumpParams($cgi);
  
  printStartHTML($cgi, $title);
  warningsToBrowser(1);
  printTitle($cgi);
  print("<br>\n");
# }

if (has_len($ident)) {
  # Called from self.
  if (has_len($doAdd)) {
    # Given ident and add: from CGI params, add new or edit existing record.
    # This uses Add in a different sense to mean 'process changes'.
    doEditAdd($cgi, $dbh, $dbtable, $ident);
  } else {
    # Ident given, not add: edit this existing record (selected from list).
    editAddForm($cgi, $dbh, $dbtable, $ident);
  }
} else {
  # Called from Admin screen.
  if (has_len($doAdd)) {
    # Adding, no ident given: create blank form, call self with add and ident.
    editAddForm($cgi, $dbh, $dbtable);
  } else {
    # Editing, no ident: display list, each elem has ident but not add.
    showList($cgi, $dbh, $dbtable);
  }
}
exit;

# Display edit/add form.  If ident set, it's an edit, else it's an add.

sub editAddForm {
  my ($cgi, $dbh, $dbtable, $ident) = @_;
  
  print $cgi->startform(-action => $STR_EDIT_DATA) . "\n";
  print "<table>\n";
  print "<tr><th>Field</th><th>Value</th></tr>\n";

  my $href = '';
  if (has_len($ident)) {
    # Given a particular ident: we're editing.
    my $str = "select * from $dbtable where ident = '$ident'";
    my $sh = dbQuery($dbh, $str);
    $href = $sh->fetchrow_hashref();
  }

  # Now display a table for one record.  
  # If href filled in, editing, else add a new review.
  my $tablename = "radutils::db_${dbtable}";
  my %table = %{$tablename};
  my @sortkeys = sort {$table{$a}->[0] <=> $table{$b}->[0]} keys %table;
  foreach my $field (@sortkeys) {
    my $dbval = (has_len($href)) ? $href->{$field} : "";
    # Create the next free ID unless we have one.
    if (($field eq "ident") and (not has_len($ident))) {
      $dbval = nextIdent($dbh, "data");
      # Need to have hidden 'ident' set later on.
      $ident = $dbval;
    }
    my $tr = makeEditField($cgi, $dbh, $dbval, $table{$field}, $dbtable);
    print "$tr\n";
  }
  # Use the Add field to indicate 'process these changes'.
  print $cgi->hidden(-name => 'ident', -value => "$ident") . "\n";
  print $cgi->hidden(-name => 'Add', -value => '1') . "\n";
  print $cgi->hidden(-name => 'DBtable', -value => $dbtable) . "\n";
  print "</table>\n";
  print "<br>\n";
  print $cgi->submit() . "\n";
  print $cgi->endform() . "\n";
}

# Create <tr> with title and appropriate edit field for this value.
# Default value if any is prefilled, after formatting (eg date).
#   field  : Ptr to array of field values.
#   dbval  : Default value from database entry.

sub makeEditField {
  my ($cgi, $dbh, $val, $field, $table) = @_;

  # thdata is <th> heading (left column).
  my $thdata = $field->[2];
  my $tddata = valToTDedit($cgi, $dbh, $val, $field, $table);
  my $ret = $cgi->Tr($cgi->th({-align=>'left'}, $thdata), 
		     $cgi->td($tddata));
  return $ret;
}

# Perform add of new, or edit of existing database record.
# Note: can't print anything in here, since header has not been printed.

sub doEditAdd {
  my ($cgi, $dbh, $dbtable, $ident) = @_;

  my $str = "select * from $dbtable where ident = $ident";
  my $sh = dbQuery($dbh, $str, 0);
  my $dbrec = $sh->fetchrow_hashref;
  my $doEdit = (has_len($dbrec)) ? 1 : 0;
  my ($updatestr, $comma) = ("", "");

  my $tablename = "radutils::db_${dbtable}";
  my %table = %{$tablename};
  my @sortkeys = sort {$table{$a}->[0] <=> $table{$b}->[0]} keys %table;
  foreach my $field (@sortkeys) {
    my $newval = $cgi->param("fld_${field}");
    $newval = valToSQL($newval, $table{$field});
#   tt("editdata::doEditAdd(): field $field, oldval $dbrec->{$field}, newval $newval");
    if (has_len($newval)) {
      unless ($doEdit and ($newval eq $dbrec->{$field})) {
	# Include this string only if it's different.
	$updatestr .= "$comma $field = '$newval'";
	$comma = ",";
      }
    }
  }
  if (length($updatestr)) {
    if ($doEdit) {
      $updatestr = "update $dbtable set $updatestr where ident = '$ident'";
    } else {
      $updatestr = "insert into $dbtable set $updatestr";
    }
    tt($updatestr);
    dbQuery($dbh, $updatestr, 0);
  }

# ========== TEMP NOT PRINTING REDIRECT HEADER ==========
#   # Print redirection header to display summary of this record.

#   print $hdr;
}

sub showList {
  my ($cgi, $dbh, $dbtable) = @_;

  print "<table cellspacing=0 cellpadding=2 border=1>\n";
  # Column headings come from db_ hash.
  my $tablename = "radutils::db_${dbtable}";
  my %table = %{$tablename};
  my @sortkeys = sort {$table{$a}->[0] <=> $table{$b}->[0]} keys %table;
  my $throw = '';
  my @headings = ();
  my @fields = ();
  foreach my $key (@sortkeys) {
    my ($f_index, $f_key, $f_name, $f_type, $f_size, $f_ssize) = @{$table{$key}};
    if ($f_ssize > 0) {
      push(@headings, $f_name) unless ($key =~ /ident/);
      push(@fields, $f_key);
    }
  }
  push(@headings, "&nbsp;");	# Blank heading for 'Edit' column.
  print $cgi->Tr($cgi->th([@headings])) . "\n";

  my $selfields = join(", ", @fields);
  my $str = "select $selfields from $dbtable";
  my $sh = dbQuery($dbh, $str, 0);

  while (my $row = $sh->fetchrow_hashref()) {
    my @linetds = ();
    my $ident = '';
    foreach my $field (@fields) {
      my $val = $row->{$field};
      if ($field =~ /ident/) {
	# Store ident, don't display it.
	$ident = $val;
      } else {
	push(@linetds, valToTDsumm($cgi, $dbh, $val, $table{$field}));
      }
    }
    # Add 'Edit' link at the end. 'Add' flag not set (not finalizing).
    my $eurl = "<a href='${STR_EDIT_DATA}?ident=$ident&DBtable=$dbtable'>Edit</a>";
    push(@linetds, $eurl);
    print $cgi->Tr($cgi->td([@linetds])) . "\n";
  }
  print "</table>\n";
}
