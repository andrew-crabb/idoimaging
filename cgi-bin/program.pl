#! /usr/bin/env perl
use warnings;

use strict;
no strict 'refs';

use CGI;
use DBI;
use FindBin qw($Bin);
use lib $Bin;
use Utility;
use radutils;
use bigint;

# ------------------------------------------------------------
# Constants.
# ------------------------------------------------------------


my $TIP_PROGURL_1  = "Visit website for this program";
my $TIP_PROGURL_0  = "Program's website is currently down (try anyway)";
my $TIP_PROGURL_NA = "No website available";
my $TIP_SRCURL_1   = "Visit website for this program's source code";
my $TIP_SRCURL_0   = "Program source code's website currently down (try anyway)";
my $TIP_SRCURL_NA  = "No source code available";

my $cgi = new CGI;
my $FULLWIDTH = $radutils::TABLEWIDTH;
my $HALFWIDTH = 460;
my $TH_WIDTH = 100;
my $HALF_TD_WIDTH = 360;
my $TH_STR = "<th width ='$TH_WIDTH' valign='top' align='left'>";

# ------------------------------------------------------------
# Globals
# ------------------------------------------------------------

my %g_tipstrs = ();

# my $ident = $cgi->param('ident');
print $cgi->header();
my ($ident) = getParams($cgi, (qw(ident)));
my $dbh = hostConnect();
my $verbose = 0;

# Get ident of logged-in user.
my $userid = undef;
if (defined($userid = $ENV{'logged_in_user'})) {
  delete $ENV{'logged_in_user'};
}

# ------------------------------------------------------------
# Handle relationships ISNOW and ISPARTOF
# ------------------------------------------------------------

# Get all relationships involving this program.
my ($oldprog, $subtitlestr) = ('', '', '');
my $str = "select * from relationship";
$str   .= " where ((prog1 = '$ident')";
$str   .= " or (prog2 = '$ident'))";

my %prognames = ();
my $sh = dbQuery($dbh, $str, $verbose);
while (my $recp = $sh->fetchrow_hashref) {
  my %recp = %$recp;
  my ($p1, $p2, $type) = @recp{qw(prog1 prog2 type)};

  # Get all program names (might need them later...)
  %prognames = allProgNames($dbh) unless (scalar(keys(%prognames)));

  # tt("Coming in with ident = $ident");
  # Case: prog1 isnow or ispartof, prog2.  
  if (($type == $radutils::REL_ISNOW) or ($type == $radutils::REL_ISPARTOF)) {
    # Print a subtitle, and redirect by changing ident if necessary.
    ($ident, $oldprog) = ($p2, $p1);
    tt("Now (ident, old) = ($ident, $oldprog)");
    my $qualifier = ($type == $radutils::REL_ISNOW) ? "was formerly known as" : "includes the program";
    $subtitlestr = "Note: This program $qualifier $prognames{$oldprog}";
  }
}

# ------------------------------------------------------------
# Get reviews and blog entries for this program.
# ------------------------------------------------------------

# CODE FOR BLOG AND REVIEW RESOURCES
$str  = "select * from resource";
$str .= " where program = $ident";
$str .= " and ((type = $RES_BLO)";
$str .= " or (type = $RES_REV)";
$str .= " or (type = $RES_DEM))";
$sh = dbQuery($dbh, $str, $verbose);
# Create hash by date of resource pointers.
my %prog_res = ();
while (my $resp = $sh->fetchrow_hashref) {
  $prog_res{$resp->{'program'}}{$resp->{'date'}} = $resp;
}

$sh = dbQuery($dbh, "select * from program where ident = '$ident'", $verbose);
my $prog = $sh->fetchrow_hashref();

my $title = "I Do Imaging - $prog->{'name'}";

# HTML string and tipstring for home URL
my %urlopts = (
  $KEY_CGI     => $cgi,
  $KEY_IDENT   => $ident,
  $KEY_URL     => $prog->{'homeurl'},
  $KEY_URLSTAT => $prog->{'urlstat'},
  $KEY_TABLE   => "program",
  $KEY_FIELD   => "homeurl",
  $KEY_TIP0    => $TIP_PROGURL_0,
  $KEY_TIP1    => $TIP_PROGURL_1,
  $KEY_TIPNA   => $TIP_PROGURL_NA,
    );

my $urlicon = urlIcon(\%urlopts);
our $homeurl = $urlicon->{'urlstr'};
addCvars($urlicon, \%g_tipstrs);

# HTML string and tipstring for source URL
$urlopts{'url'}     = $prog->{'srcurl'};
$urlopts{'urlstat'} = $prog->{'srcstat'};
$urlopts{'field'}   = 'srcurl';
$urlopts{'tip_0'}   = $TIP_SRCURL_0;
$urlopts{'tip_1'}   = $TIP_SRCURL_1;
$urlopts{'tip_na'}  = $TIP_SRCURL_NA;

$urlicon = urlIcon(\%urlopts);
our $srcurl = $urlicon->{'urlstr'};
addCvars($urlicon, \%g_tipstrs);

my @prer = listPrereq($dbh, $prog->{'prer'});

# ------------------------------------------------------------
# Row for title.
# ------------------------------------------------------------
print comment("Start row for 'List programs' graphic");
print "<tr>\n";
my $progstr = "Program:  $prog->{'name'}";
print "<td width='$radutils::TABLEWIDTH' class='white' align='center'><h2>$progstr</h2></td>\n";
print "</tr>\n";
if (has_len($subtitlestr)) {
print "<tr>\n";
  print "<td width='$radutils::TABLEWIDTH' class='white' align='center'><h3>$subtitlestr</h3></td>\n";
print "<tr>\n";
}


# ------------------------------------------------------------
# Row for ISNOW or FORMERLY program name.
# ------------------------------------------------------------
# if (has_len($newprog)) {
#   my $str = "select name from program where ident = '$newprog'";
#   my $sh = dbQuery($dbh, $str, $verbose);
#   my ($newname) = $sh->fetchrow_array();
#   my $urlstr = "<a href='${}/program.pl?ident=$newprog'>";

#   my $newstr = "(NOTE: This program has been replaced by ${urlstr}$newname</a>";
#   printRowWhiteCtr($newstr);
# }

# ------------------------------------------------------------
# Row for 'program removed' text.
# ------------------------------------------------------------
my $remdate = $prog->{'remdate'};
unless ($remdate =~ /^0000/) {
  $remdate = convert_date($remdate, $DATE_MDY);
  printRowWhiteCtr("<h3>Note: This program was removed on $remdate and is not being monitored</h3>");
}

# print "<tr valign='top'>\n";
# # This td contains the entire program listing.
# print "<td class='light_bg' width=525>\n";

# ============================================================
print comment("Table for program description (top table)");
print "<tr><td class='white'>\n";
print "<table width='$FULLWIDTH' border='1' cellspacing='0' cellpadding='2'>\n";
# ============================================================

# ------------------------------------------------------------
# Row for monitoring.
# ------------------------------------------------------------

my @monitored = monitoredPrograms($dbh, $userid);
my $is_monitored = grep(/$ident/, @monitored);
my $can_monitor = (has_len($prog->{'rev'}) or has_len($prog->{'rdate'}));
my $included = 0;

my $mon_det = make_monitor_details($userid, $ident, $is_monitored, $can_monitor, $included);
my $mon_url   = $mon_det->{$MON_URL};
my $mon_icon  = $mon_det->{$MON_ICON};
my $mon_cvars = $mon_det->{$MON_CVARS};
my $tip_class = $mon_det->{$MON_TIPCL};
my $mon_text  = $mon_det->{$MON_TEXT};

# Put links together differently depending on login, is_monitored, can_monitor.
# All states get the basic icon and message.
my $iconstr = "${mon_icon}&nbsp;${mon_text}";
my $loginstr = (has_len($mon_url)) ? "<a href='$mon_url'>${iconstr}</a>" : $iconstr;
$g_tipstrs{$tip_class} = $mon_cvars unless (defined($g_tipstrs{$tip_class}));

# All logged-in states get a link to user page (see all monitored programs).
if (has_len($userid)) {
  $loginstr .= "&nbsp;&mdash;&nbsp;";
  $loginstr .= "<a href='/${STR_USER_HOME}'>See all monitored programs</a>";

  # If monitored, add link to stop monitoring.
  if ($is_monitored) {
    my $rem_det = make_monitor_details($userid, $ident, $is_monitored, $can_monitor, 1);
    my $rem_url   = $rem_det->{$MON_URL};
    my $rem_icon  = $rem_det->{$MON_ICON};
    my $rem_cvars = $rem_det->{$MON_CVARS};
    my $rtip_class = $rem_det->{$MON_TIPCL};
    my $rem_text  = $rem_det->{$MON_TEXT};
    $loginstr .= "&nbsp;&mdash;&nbsp;";
    $loginstr .= "<a href='$rem_url'>${rem_icon}&nbsp;${rem_text}</a>";
  }
}

print "<tr>\n";
print "<th align='left' valign='top'>Monitoring</th>\n";
print "<td colspan='3'>$loginstr</td>\n";
print "</tr>\n";

# ------------------------------------------------------------
# Rows for each item of program description.
# ------------------------------------------------------------

my $colno = 0;
foreach my $fld (qw(summ descr rev auth plat interface func category readfmt writfmt homeurl srcurl)) {
  my $val = (defined($$fld)) ? $$fld : $prog->{$fld};
  # Process the value according to the nature of the field.
 SWITCH: {
   # -------------------- readfmt writfmt --------------------
   if ($fld =~ /fmt$/) {
     $val = formatList($val) . "\n"; 
     last SWITCH;
   }
   # -------------------- auth --------------------
   if ($fld eq 'auth') {
     my %authopts = (
       'flag'    => 1,
         );
     my $aptr = authName($dbh, $val, \%authopts);
     addCvars($aptr, \%g_tipstrs);

     $val = $aptr->{'urlstr'};
     last SWITCH;
   }
   # -------------------- rev --------------------
   if ($fld eq 'rev' and validDate($prog->{'rdate'}))  {
     my $fdate = convert_date($prog->{'rdate'}, $DATE_MDY);
     $val = "$val (Released: $fdate)";  
     last SWITCH;
   }
   # -------------------- category, func, interface, plat, srcurl --------------------
   if ($fld =~ /category|func|interface|plat|srcurl/) {
     # Value may encode several values from hash.
     # Options: fld => [hashname, sumval, doicon, sortarray]
     my %opts = (
       'category'  => [$fld  , $val           , 0, 0],
       'func'      => [$fld  , $val           , 0, 0],
       'interface' => [$fld  , $val           , 1, 1],
       'plat'      => [$fld  , $prog->{'plat'}, 1, 1],
       'srcurl'    => ['lang', $prog->{'lang'}, 0, 0],
	 );

     my $opt = $opts{$fld};
     my $sortarr = $opt->[3] ? "radutils::cat_" . $opt->[0] : '';
     my %args = (
       'hashname' => "radutils::cat_" . $opt->[0],
       'sumval'   => $opt->[1],
       'sortarr'  => $sortarr,
       'field'    => $fld,
	 );

#      printHash(\%args, "args to selectedvals");

     my $selvals = selectedVals(\%args);
     my %selvals = %$selvals;

     # Only get tooltips for certain fields.
     my ($sortkeys, $vals, $iconstr, $tiptxt) = ("", "", "", "");
     if ($opt->[2]) {
       # Displaying icons and tiptext along with vals.
       ($sortkeys, $vals, $iconstr) = @selvals{qw(sortkeys vals narricons_t)};
       addCvars($selvals, \%g_tipstrs);
     } else {
       ($sortkeys, $vals) = @selvals{qw(sortkeys vals)};
     }

     my @sortedkeys = @$sortkeys;
     my %matchvals = %$vals;

     # Category/Speciality is a list of links to programs.pl for this category.
     my @dvals = ();
     if ($fld eq 'category') {
       foreach my $categ (@sortedkeys) {
	 push(@dvals, "<a href='/${STR_PROGRAMS}?category=${categ}'>$matchvals{$categ}</a>");
       }
     } else {
       @dvals = @matchvals{@sortedkeys};
     }
     if ($fld =~ /srcurl/) {
       # List of languages follows icon for source URL.
       $val .= "&nbsp;&nbsp;(" . join(",&nbsp;", @dvals) . ")\n" if (scalar(@dvals));
     } else {
       $val = join(",&nbsp;", @dvals);
       if (has_len($iconstr)) {
	 $val .= "&nbsp;&nbsp;${iconstr}"
       }
     }
     last SWITCH;
   }
  }
  # ------------------------------ End of the big switch ------------------------------

  # CODE FOR BLOG AND REVIEW RESOURCES
  $val = "&nbsp;" unless (has_len($val));
  if ($fld eq 'summ') {
    my $rsrcicon = makeRsrcIcon($dbh, $ident);
    if (has_len($rsrcicon)) {
      $val .= "&nbsp;&nbsp;$rsrcicon->{'iconstr'}";
       addCvars($rsrcicon, \%g_tipstrs);
    }
  }

  # Have processed value, now display in appropriately-sized field.
  my ($colspan, $startrow, $endrow, $colwidth);
  if ($fld =~ /summ|descr/) {
    # This is a full-width td.
    $colspan = 3;
    $colwidth = $FULLWIDTH - $TH_WIDTH;
    $startrow = $endrow = 1;
  } else {
    # This is a half-width td.
    $colspan = 1;
    $colwidth = $HALF_TD_WIDTH;
    $startrow = ($colno == 0);
    $endrow = ($colno == 1);
    $colno = ($colno) ? 0 : 1;
  }
   
  my $title = $radutils::db_program{$fld}->[0];
  print "<tr>\n" if ($startrow);
  print $cgi->th({-align  => 'left',
		  -valign => 'top',
		  -width  => $TH_WIDTH}, 
		 $title) . "\n";
  print $cgi->td({-colspan => "$colspan",
		  -width => $colwidth},
		 $val) . "\n";
  print "</tr>\n" if ($endrow);
}

# ============================================================
# End of main table (top part).
# ============================================================
print comment(": End of program description table (top)");
print "</table>\n";
print "</td></tr>\n";

# ============================================================
# Table for screen caps and advertising
# ============================================================
print comment("Table for screen caps and advertising");

# ------------------------------------------------------------
# Row for screen caps.
# ------------------------------------------------------------
if (my $caprecs = getCaptureImages($dbh, $ident)) {
  # Get all sizes for all ordinals, select random subset of two ordainals.
  my %caprecs = %$caprecs;
  my @capords = keys %caprecs;
  my @randords = randomSubset(\@capords, 2);
  my @subrecs = @caprecs{@randords};
  my $rowwidth = (scalar(@randords) > 1) ? $HALFWIDTH : $FULLWIDTH;

  my $rowstr = "<tr><td class='white'>\n";
  $rowstr .= "<table width='$FULLWIDTH' border='0' cellspacing='0' cellpadding='2'>\n";

  $rowstr .= "<tr>\n";
  # Each caprec is a ptr to a hash of (scale -> file details).
  foreach my $caprec (@subrecs) {
    my %caprec = %$caprec;
    my ($det320, $detfull) = @caprec{qw(320 full)};

    # String for full scale image.
    my $fullimgstr = "/img/cap/prog/" . $detfull->{'filename'};

    # String for 320 pixel image.
    my %smdet = %$det320;
    my ($smpath, $smname, $smwidth, $smheight, $smfilename) = @smdet{qw(path filename width height filename)};
    my $smimgstr = "/img/cap/prog/${smpath}/${smfilename}";

    my $capstr  = "<a href='$fullimgstr' onclick=\"return popup(this, 'Screen Capture')\">";
    $capstr .= "<img border='0' src='$smimgstr' width='$smwidth' height='$smheight' alt='img' /></a>";    
    $rowstr .= "<td class='white' align='center' width='$rowwidth'>$capstr</td>\n";
  }
  $rowstr .= "</tr>\n";
  
  $rowstr .= comment("End of screen captures table");
  $rowstr .= "</table>\n";
  $rowstr .= "</td></tr>\n";
  print $rowstr;
}

# ============================================================
# Table for revision history, related programs, related specialities (bottom table).
# ============================================================
print comment("Table for rev hist, related programs, related specs (bottom table)");
print "<tr><td class='white' align='center'>\n";
print "<table width='$FULLWIDTH' border='1' cellspacing='0' cellpadding='2'>\n";

# ------------------------------------------------------------
# Half-row for revision history.
# ------------------------------------------------------------
my $rstr = "select * from version where progid = '$ident' order by reldate desc limit 5";
my $rsh = dbQuery($dbh, $rstr, $verbose);
my $rtxt = "";
while (my $revp = $rsh->fetchrow_hashref()) {
  # First rev entry: Create table and headings.
  unless (length($rtxt)) {
    print comment("'Revision History' subtable begin");
    $rtxt  = "<table border='0' cellpadding='2' cellspacing='0'>\n";
    $rtxt .= "<tr><th>Version</th><th>Release Date</th></tr>\n";
  }
  # Each revision entry creates a line in this subtable.
  $rtxt .= "<tr><td>$revp->{'version'}</td>";
  my $mdydate = (convert_date($revp->{'reldate'}, $DATE_MDY) or '&nbsp;');
  $rtxt .= "<td>$mdydate</td>";
  $rtxt .= "</tr>\n";
}
if (length($rtxt)) {
  # Have found at least one revision: end the subtable.
  $rtxt .= "</table>\n";
  $rtxt .= comment("'Revision History' subtable end");
  # Add a row to the main table containing the subtable.
} else {
  $rtxt = "&nbsp;";
}
print comment("Row for revision history and prerequsites");
print "<tr>\n";
print "<th width='$TH_WIDTH' valign='top' align='left'><b>Revision History:</b></th>\n";
print "<td width='$HALF_TD_WIDTH' align='left'>$rtxt</td>\n";

# ------------------------------------------------------------
# Half-row for prerequisites.
# ------------------------------------------------------------
print "<th width='$TH_WIDTH' valign='top' align='left'><b>Prerequisites:</b></th>\n";
my $tdtxt = '';
# if ($prer[0] == 0) {
if (defined($prer[0]) and ($prer[0] == 0)) {
  print "<td width='$HALF_TD_WIDTH' valign='top'>None</td>\n";
} else {
  # Each prerequisite is on its own line, indented by columns.
  print "<td width='$HALF_TD_WIDTH' align='left' valign='top'>\n";
  print comment("Prerequsites table");
  print "<table border='0' cellpadding='0' cellspacing='0'>\n";
  print "<tr><td>$prog->{'name'}</td><td>&nbsp;</td></tr>\n";
  my $initmask = (defined($prer[1]) and ($prer[1] != 0)) ? 1 : 0;
  print_prereq($dbh, 1, $initmask, @prer);
  print "</table>\n";
  print comment("End of prerequsites table");
  print "</td>\n";
}
print "</tr>\n";


# ------------------------------------------------------------
# Data for related specialities.
# ------------------------------------------------------------
my $related_spec_table = '';
my $related_spec_offs = 0;
if (my $category = $prog->{'category'}) {
  # Need two hashes for makeTableBinary: Headings and content.
  my $chash = selectedVals({'hashname' => "radutils::cat_category", 
			    'sumval'   => $category,
			    'field'    => 'category',
			   });
  my $selvals = $chash->{'vals'};
  my ($matching, $matched) = matchingProgramsTable($selvals, $ident);
  my $specialities = makeTableBinary($dbh, $selvals, $matching, $matched, \%g_tipstrs);
  my $related_spec_str = $specialities->{'tablestr'};
  $related_spec_offs = $specialities->{'offset'};
  $related_spec_table = comment("Related specialities row.");
  $related_spec_table .= "<tr>\n";
  $related_spec_table .= "${TH_STR}Programs With Related Specialities:</th>\n";
  $related_spec_table .= "<td colspan='3' align='left' valign='top'>\n";
  $related_spec_table .= "${related_spec_str}\n</td>\n";
  $related_spec_table .= "</tr>\n";
}

# ------------------------------------------------------------
# Row for related programs.
# ------------------------------------------------------------
my $href = relatedPrograms($dbh, $ident);
# tt("related_spec_offs = $related_spec_offs");
my $related_prog_str = relatedProgramsTable($href, $dbh, \%g_tipstrs, $related_spec_offs);
if (length($related_prog_str)) {
  print comment("'Related Programs' subtable begin");
  print comment("Related programs found: Begin related program row");
  print "<tr>\n";
  print "<th width='$TH_WIDTH' valign='top' align='left'><b>Related Programs:</b></th>\n";
  print "<td colspan='3' align='left' valign='top' >$related_prog_str</td>\n";
  print "</tr>\n";
}

# ------------------------------------------------------------
# Row for related specialities.
# ------------------------------------------------------------
print "$related_spec_table\n";

# End of main table.
print comment(": End of program description table");
print "</table>\n";
print "</td></tr>\n";

# Print Javascript content_vars for tip strings.
printToolTips(\%g_tipstrs);


############################################################
print comment(": End of overall page table");


exit;

# Recursively print each prerequisite on a line, indented by dependency level.
sub print_prereq {
  my ($dbh, $indent, $mask, @pre) = @_;
  my ($pre) = $pre[0];
  # ahc New change 7/29/12.
  return $mask unless (length($pre) and ($pre != 0));

  # See if this program has dependencies.
  my $str = "select name, prer from program where ident = '$pre'";
  my $sh = dbQuery($dbh, $str, $verbose);
  my ($name, $prer) = $sh->fetchrow_array();
  my @deps = listPrereq($dbh, $prer);

  print "<tr>";
  # Indent by level of dependency.
  # Graphic before this name depends on if this is the last in list.
  for (0..($indent - 2)) {
    # Tmpmask measures if this col has a vertical guide.
    my $tmpmask = 1 << $_;
     my $char = ($mask & $tmpmask) ? "+" : "&nbsp;";
    print "<td width=100 align='center'>$char</td>";
  }
  # Print this program and finish the line.
  my $mygr = "+";
  print "<td width=100 align='center'>$mygr</td>";
  print "<td width=100 cellspacing=2>";
  print "<a href='/${STR_PROGRAM}/$pre'>$name</a></td></tr>\n";
  
  # If this program has dependencies, print them.
  my $thismask = 1 << ($indent);
  if (defined($deps[0]) and $deps[0] != 0) {
    if ($deps[1] != 0) {
      # Encode mask with this indent level for vertical guidelines.
      # This prog has dependencies; encode this position in mask.
      $mask |= $thismask;
    } else {
      if (($indent != 1) or ($pre[1] == 0)) {
	$mask &= ~(1 << ($indent - 1));
      }
    }
    $mask = print_prereq($dbh, $indent + 1, $mask, @deps);
  } else {
    # This prog has no dependencies; clear mask at this pos.
    $mask &= ~(1 << ($indent + 1));
  }

  # Now call for the remaining dependencies to be printed.
  if (scalar(@pre) > 1) {
    $mask = print_prereq($dbh, $indent, $mask, @pre[1..scalar(@pre) - 1]);
  }
  return $mask;
}

sub matchingProgramsTable {
  my ($chash, $progid) = @_;
  my %cats = %$chash;

  # Build hash of (category => [name, summary]) for programs to be displayed.
  # name string has HTML to link to program.
  my (@cats) = sort {$a <=> $b} keys %cats;
  # Array of ptr to (categ, name, summ) - need to preserve order.
  my @matching = ();
  # Add programs matching categories, starting with best match.
  my $combs = sortedcomb(@cats);
  my %combs = %$combs;
  # Keep a track of which subconditions are used by >= 1 program.
  my %matchedsubconds = ();

 OUTER:
  foreach my $len (sort {$b <=> $a} keys %combs) {

    my $aptr = $combs{$len};
    my $nlen = scalar(@$aptr);
    # Include programs from most to least matches until limit reached.
    for (my $i = 0; $i < $nlen; $i++) {
      my @subcats = @{$combs{$len}[$i]};
      my $catsum = 0;
      # Sum of this partial list of matching categories.
      foreach my $subcat (@subcats) {
	$catsum += $subcat;
      }
      my $str = "select * from program where (category & $catsum) = $catsum";
      $sh = dbQuery($dbh, $str, $verbose);
      while (my $href = $sh->fetchrow_hashref()) {
	my %hash = %$href;
	my ($ident, $name, $summ) = @hash{qw(ident name summ)};
	next if ($ident == $progid);
	# Can't use hash + tests to store unique entries since order important.
	my $found = 0;
      FORE:
	foreach my $elem (@matching) {
	  if ($elem->[1] == $ident) {
	    $found = 1;
 	    my $nm = scalar @matching;
	    last FORE;
	  }
	}
	# Add ptr to array of this prog details if not found.
	unless ($found) {

	  my %popts = (
	    'ident'  => $href,
	    'dbh'    => $dbh,
	    'maxlen' => 20,
	    'isnew'  => 0,
	      );
	  my $plink = makeProgramLink(\%popts)->{'progstr'};
	  my $psumm = truncateString($summ, 80);
	  my @arr = ($catsum, $ident, $plink, $psumm);
	  push(@matching, [@arr]);
	  # Every member of subcats is satisfied at this point.  Record.
	  foreach my $subcat (@subcats) {
	    $matchedsubconds{$subcat} = 1;
	  }
	  last OUTER if (scalar(@matching) == 10);
	}
      }
    }
  }

  my @matched = keys %matchedsubconds;
  return (\@matching, \@matched);
}


