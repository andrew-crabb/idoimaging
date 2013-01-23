#! /usr/local/bin/perl -w

use CGI;
use CGI::Carp 'fatalsToBrowser';
use DBI;
use DateTime::Format::MySQL;

use FindBin qw($Bin);
use lib $Bin;
use Utility;
use radutils;
use bigint;
use strict;
no strict 'refs';

my $cgi = new CGI;
print $cgi->header();

my $title = "I Do Imaging - Edit Program";

# printStartHTML($cgi, $title);
# printTitle($cgi);

# dumpParams($cgi);

print "<tr><td class='white'>\n";


# Retrieve existing record.
my $ident = $cgi->param('ident');
my $addprog = $cgi->param('Add Program');
$addprog = (has_len($addprog)) ? $addprog : 0;
unless (has_len($ident) or $addprog) {
  print "ERROR: No ident or addprog parameter<br>\n";
  exit;
} else {
  print "ident $ident, addprog $addprog<br>\n";
}

my $dbh = hostConnect('');

my $prog;	# Ptr to hash of program details.
if (not $addprog) {
  my $str = "select * from program where ident = '$ident'";
  my $sh = dbQuery($dbh, $str, 0);
  unless ($prog = $sh->fetchrow_hashref()) {
    print "<br><b>ERROR: doeditprogram: fetchrow_hashref failed</b><br>\n";
    exit 1;
  }
}

# Scalar variables.
my $update_str = "";
my $comma = "";
my $val;
# prog is only filled in if this is not an add.
my @pkeys = ($addprog) ? (keys %radutils::db_program) : (keys %$prog);
@pkeys = sort @pkeys;
foreach my $varname (@pkeys) {
  # Don't touch the URL stat fields or link count.
  next if ($varname =~ /urldate|linkcnt|stat|capture|percentile$/);
  # Allow for editing of key ident field.
  if (($varname eq "ident") and not $addprog) {
    $val = $cgi->param('newident');
  } else {
    # val is the new val to be compared against the db val.
    # It is set to the db val (null comparison) or to a new value
    # from cgi.  Binary-encoded values are decoded first.
    $val = decodeCGI($cgi, $varname) or $prog->{$varname};
  }
  # Convert date.
  $val = definedVal($val);
  if ($varname =~ /rdate|adddate|visdate/) {
    val = convert_date($val, DATE_SQL);
  }
  if ($addprog) {
    $update_str .= "$comma $varname = '$val'";
    $comma = ", ";
  } else {
    my $dbval = definedVal($prog->{$varname});	# Database val.
    my $cmpval = $dbval;
    if ($varname =~ /date$/) {
      $dbval = $cmpval = convert_date($dbval, $DATE_SQL);
    }

    warn("doeditprogram: val undefined, varname $varname") unless (defined($val));
    warn("doeditprogram: dbval undefined, varname $varname") unless (defined($dbval));

    my $valsdiffer = ($val ne $dbval) ? 1 : 0;
    my $valnonzero = (isNonZero($val) or isNonZero($dbval));
    if ($valsdiffer and $valnonzero) {
      $update_str .= "$comma $varname = '$val'";
      $comma = ", ";
      my ($vstr, $svstr) = ("", "");
      if ($varname =~ /fmt|plat|interface|lang|func|category|feature/) {
	$vstr  = format_string($varname, $val);
	$svstr = format_string($varname, $dbval);
      }
    }
  }
}

my $sh;
if ($addprog) {
  addVersionRecord($dbh, $ident, $cgi);
  $update_str = "insert into program set $update_str";
  tt($update_str);
  $sh = dbQuery($dbh, $update_str, 1);
} else {
  if (length($update_str)) {
    $update_str = "update program set $update_str where ident = '$ident'";
    tt($update_str);
    # Submit to database.
    addVersionRecord($dbh, $ident, $cgi);
    $sh = dbQuery($dbh, $update_str);
  }
}

# ------------------------------------------------------------
# Process related programs.
# ------------------------------------------------------------
# Related programs to this program.
my @related = $cgi->param('related');		# Array of prog ids from checkbox.
my $relref = relatedPrograms($dbh, $ident);	# Hash of prog id, name from SQL.
my %dbrelated = %$relref;
my @dbrelated = keys (%dbrelated);

my @adds;
foreach my $related (@related) {
  if (defined($dbrelated{$related})) {
    delete $dbrelated{$related};
  } else {
    push(@adds, $related);
  }
}
my @drops = keys %dbrelated;
foreach my $add (@adds) {
  my $str = "insert into related set prog1 = '$ident', prog2 = '$add'";
  print "<tt>$str</tt><br>\n";
  $sh = dbQuery($dbh, $str);
}

foreach my $drop (@drops) {
  my $str = "delete from related where (prog1 = '$ident' and prog2 = '$drop') or (prog1 = '$drop' and prog2 = '$ident')";
  tt($str);
  $sh = dbQuery($dbh, $str);
}

# ------------------------------------------------------------
# Process relationships between programs.
# ------------------------------------------------------------
# Definition.
# (progA ISNOW progB) == (progB FORMERLY progA)
# This relationship is equivalent and can be stored either or both ways.
# - A reference to progA is redirected to progB.
# - A reference to progB includes a note that was formerly progA.
# - Monitors of progA receive notices about progB.
#
# (progA ISPARTOF progB)
# - A reference to progA is redirected to progB
# - Details of progB include listing all programs which are part of it.

my $rel_type  = $cgi->param('new_rel_type');
my $rel_prog2 = $cgi->param('new_rel_prog2');
if (defined($rel_type) && defined($rel_prog2) && ($rel_prog2 >= 100)) {
  # See if any relationship already exists between these two programs.
  my $str = "select * from relationship";
  $str   .= " where (((prog1 = '$ident') and (prog2 = '$rel_prog2'))";
  $str   .= " or ((prog1 = '$rel_prog2') and (prog2 = '$ident')))";
  my $sh = dbQuery($dbh, $str);
  my $rel_exists = 0;
  while (my $rref = $sh->fetchrow_hashref) {
    tt("Relationship: $ident $radutils::relationship{$rref->{'type'}} $rel_prog2");
    # Test to see if the new relationship already exists.
    $rel_exists++;
    # ------------------
  }
  unless ($rel_exists) {
    # Add this new relationship.
    my $today = today();
    $str = "insert into relationship set prog1 = '$ident', type = '$rel_type', prog2 = '$rel_prog2', date = '$today'";
    tt($str);
    my $sh = dbQuery($dbh, $str);
  }
}

# ------------------------------------------------------------
# Process secondary screen captures.
# ------------------------------------------------------------

# Get list of secondary screen captures for this program.
my $str  = "select * from resource";
$str .= " where program = '$ident'";
$str .= " and type = '$radutils::RES_IMG'";
$sh = dbQuery($dbh, $str, 0);
my @dbseccaps = ();
while (my $href = $sh->fetchrow_hashref()) {
  my $imgname = $href->{'url'};
  push(@dbseccaps, $imgname);
}

# Handle edits/deletes of existing secondary captures.
my @params = $cgi->param();
my @seccaps = grep (/seccap_/, @params);
foreach my $seccap (@seccaps) {
  my $selected_seccap_file = $cgi->param($seccap);
  if ($seccap =~ /seccap_add/) {
    if (has_len($selected_seccap_file))  {
      # Adding a new secondary screen capture.  All values are valid - no testing required.
      $str  = "insert into resource";
      $str .= " set program = '$ident'";
      $str .= ", url = '$selected_seccap_file'";
      $str .= ", type = '$radutils::RES_IMG'";
      dbQuery($dbh, $str, 1);
    }
  } else {
    # Editing an existing secondary screen capture.
    (my $existing_seccap_file = $seccap) =~ s/^seccap_//;
    tt("selected value of selector $seccap is $selected_seccap_file, previous value was $existing_seccap_file");
    # No edits if input named after sec cap file has self-named option selected.
    if ($selected_seccap_file ne $existing_seccap_file) {
      if ($selected_seccap_file =~ /Delete/) {
	# Remove this secondary screen cap file from Resources.
	$str  = "delete from resource";
	$str .= " where url = '$existing_seccap_file'";
	dbQuery($dbh, $str, 1);
      } else {
	# Only options in this selector are Delete, or another (different) file.
	$str  = "update resource";
	$str .= " set url = '$selected_seccap_file'";
	$str .= " where url = '$existing_seccap_file'";
	dbQuery($dbh, $str, 1);
      }
    }
  }
}


# ------------------------------------------------------------
# Perform the database update.
# ------------------------------------------------------------

my $url = "/${STR_PROGRAMS}?Edit=1";
print $cgi->p("$update_str<br>") . "\n";
print "<a href=$url>Return to editing programs</a>\n";
# dumpParams($cgi);

print "</td></tr>\n";

sub format_string {
  my ($varname, $val) = @_;

  my $hashname = ($varname =~ /fmt$/) ? "formats" : $varname;
  my %hash = %{"radutils::cat_${hashname}"};

  my $spc = "";
  my $ret;
  foreach my $fmt (keys %hash) {
    if (($val * 1) & ($fmt * 1)) {
      my $fname = $hash{$fmt}->[0];
      $ret .= "$spc$fname";
      $spc = "-";
    }
  }
  $ret = "($ret)" if (has_len($ret));
  return $ret;
}

# Encode scalar fields from arrays of checkboxes.
# Returns: Sum of array CGI values if a checkbox variable, else null.
sub decodeCGI {
  my ($cgi, $var) = @_;
  my $ret = '';
  if ($var =~ /plat|interface|category|lang|func|readfmt|writfmt|feature/) {
    $ret = 0;
    # Array of keys from selected checkboxes.
    my @vals = $cgi->param($var);
    foreach my $val (@vals) {
      $ret += $val;
    }
#tt("doeditprogram::decodeCGI($var): vals " . join(" ", @vals) . ", sum $ret");
  } elsif ($var =~ /prer/) {
    $ret = calcPrereq($cgi);
  } else {
    $ret = $cgi->param($var);
  }
  return $ret;
}

# Prerequsites are encoded by ordinal (not exponential) index values.
# Calculate sum of CGI prereq values.

sub calcPrereq {
  my ($cgi) = @_;

  my @prereqs = $cgi->param('prer');
  my $prer = 0;
  foreach my $pval (@prereqs) {
    $prer += 2 ** $pval;
  }
  return $prer;
}
