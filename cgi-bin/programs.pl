#! /usr/local/bin/perl -w

use DBI;
use CGI;
use CGI::Carp;

use FindBin qw($Bin);
use lib $Bin;
use Utility;
use radutils;
# use FileUtilities;
use bigint;
use strict;
no strict 'refs';

my $cgi = new CGI;

# ------------------------------------------------------------
# Constants.
# ------------------------------------------------------------
my $NPERPAGE = 20;		# Text items per page.
my $NIMGPERPAGE = 12;		# Screen captures per page.
my $NCAPCOL = 3;		# Screen capture columns per page.
my $NCAPROW = 4;		# Screen capture rows per page.

my $TIP_HOMEURL_1 = "Visit the website for this project";
my $TIP_HOMEURL_0 = "Project website is currently down (try anyway)";

# ------------------------------------------------------------
# Globals.
# ------------------------------------------------------------

our %g_tipstrs = ();

# ------------------------------------------------------------
# Program code.
# ------------------------------------------------------------
print $cgi->header();


my $dbh = hostConnect('');

my ($progids, $included) = (undef, 0);
if (defined($progids = $ENV{'progids'})) {
  delete $ENV{'progids'};
  $included = 1;
}

# Get ident of logged-in user.
my ($userid, $is_logged_in) = (undef, 0);
if (defined($userid = $ENV{'logged_in_user'})) {
  delete $ENV{'logged_in_user'};
  $is_logged_in = 1;
  # print "<tt>you are user $userid</tt><br>\n";
} else {
  # print "<tt>you are not logged in.</tt><br>\n";
}

my @monitored = monitoredPrograms($dbh, $userid);

# print "<tr><td>\n";
# dumpParams($cgi);
# print "</tr></td>\n";

# Get search parameters.
our ($category, $func, $readfmt, $writfmt, $plat, $lang, $edit, $showcap) = getParams($cgi, qw(category func readfmt writfmt plat lang edit showcap));
my $cgiorder = $cgi->param('order');
our $order = (has_len($cgiorder)) ? $cgiorder : 'program.name';

# Number of items per page is different for image vs. text items.
my $numperpage = ($showcap) ? $NIMGPERPAGE : $NPERPAGE;

# ------------------------------------------------------------
# Get list of all relationships.
# ------------------------------------------------------------
my %relation1 = ();
my $relstr = "select * from relationship";
my $rel_sh = dbQuery($dbh, $relstr);
while (my $rel_rec = $rel_sh->fetchrow_hashref()) {
  $relation1{$rel_rec->{'prog1'}} = $rel_rec;
}
my %relation2 = reverse %relation1;

# ------------------------------------------------------------
# Get count of images for each program.
# ------------------------------------------------------------

my $str = "select rsrcid as progid, count(*) as numimg from image where rsrcfld = 'prog' and scale = 'full' group by rsrcid order by rsrcid";
my $sh = dbQuery($dbh, $str);
my %progimgs = ();
while (my $iptr = $sh->fetchrow_hashref()) {
  $progimgs{$iptr->{'progid'}} = $iptr->{'numimg'};
}

# Get list of all program names.
my %allprogs = allProgNames($dbh);

# If progids is supplied, it is a comma-delimited list of prog ids to display.
# All these progids are displayed, no other tests applied.
my $proglist = '';
if (has_len($progids)) {
  my @progids = split(/,/, $progids);
  my $sep = '';
  $proglist = "and (";
  foreach my $progid (@progids) {
    $proglist .= "${sep} program.ident = '$progid' ";
    $sep = " or";
  }
  $proglist .= ') ';
} else {
  $proglist = "and program.ident >= 100 ";
}

# @allnames is used for page-bracketing tool tips for paging through long lists.
my ($sqlstr, $condstr, %condstr, @allrecs, @allnames, @remrec);
# Get details on software package.
$sqlstr  = "select program.ident, program.name, program.summ, ";
$sqlstr .= "author.ident as 'author.ident', program.homeurl, ";
$sqlstr .= "program.plat, program.lang, program.readfmt, program.writfmt, ";
$sqlstr .= "program.func, program.urlstat, program.revurl, program.linkcnt, ";
$sqlstr .= "program.rev, program.rdate, program.capture, program.interface, ";
$sqlstr .= "program.category, program.percentile, program.remdate, program.capture ";
$sqlstr .= "from program, author ";
$sqlstr .= "where program.name is not null and program.auth = author.ident ";
# $sqlstr .= "and program.ident >= 100 ";
$sqlstr .= $proglist;
$sqlstr .= "order by $order ";
$sqlstr .= "desc" if (has_len($cgiorder) and ($cgiorder =~ /percentile|rdate/));
$sqlstr .= ", program.name" if ($order =~ /urlstat/);
$sh = dbQuery($dbh, $sqlstr);

my ($somecond, $makescond);
while (my $sqlrec = $sh->fetchrow_hashref()) {
  my $ident = $sqlrec->{'ident'};
  $somecond = 0;
  $makescond = 0;

  # Check whether this program is now part of another.
  if (defined(my $relat = $relation1{$ident})) {
    my $type = $relat->{'type'};
    if (($type == $REL_ISNOW) or ($type == $REL_ISPARTOF)) {
      # This program is now another, or part of another.
      if ($edit) {
        # Still allow me to edit it.
        my $prog2 = $relat->{'prog2'};
        tt("*** prog $allprogs{$ident} ($ident) $relationships{$type} $allprogs{$prog2} ($prog2): Still allowing editing.");
      } else {
        # Silently skip it.
        next;
      }
    }
  }

  # Check conditions for four fields: Input/Output Format; Platform; Language.
  foreach my $cond (qw(plat lang category readfmt writfmt func urlstat)) {
    # Retrieve hash corresponding to this condition.
    my %hash = ($cond =~ /fmt$/) ? %{"radutils::cat_formats"} : %{"radutils::cat_${cond}"};
    # Retrieve index values from dropdown lists, and corresp SQL field.
    my $condval = $$cond;
    my $sqlval = $sqlrec->{$cond};
    if (has_len($condval) and ($condval > 0)) {
      $somecond++;
      # Bit match to extract key bit.
      if (($condval * 1) & ($sqlval * 1)) {
        $makescond++;
        my $hashval = $hash{$$cond}->[0];
        $hashval = '' unless (has_len($hashval));
        $condstr{$cond} = "$cond = $hashval\n";
      }
    }
  }

  if ($sqlrec->{'remdate'} =~ /^0000/) {
    # Keep this record if no conditions, or all conditions met.
    if (($somecond == 0) or ($somecond == $makescond)) {
      # Omit this prog if showing images, and prog has none.
      unless ($showcap and (not defined ($progimgs{$ident}))) {
        push(@allrecs, $sqlrec);
        push(@allnames, $sqlrec->{'name'});
      }
    }
  } else {
    push(@remrec, $sqlrec);    
  }
}
  
# Page Intro.
my $nummatch = scalar(@allrecs);
my $twidth = $edit ? 850 : $radutils::TABLEWIDTH;

# ------------------------------------------------------------
# Row for title image.
# ------------------------------------------------------------
unless ($included) {
  print comment("Row for 'List programs' graphic");
  print "<tr>\n";
  print "<td width='$radutils::TABLEWIDTH' class='white' align='center'><h2 class='title'>List Programs</h2></td>\n";
  print "</tr>\n";
}

# ------------------------------------------------------------
# Row for page intro text.
# ------------------------------------------------------------
if (scalar(keys %condstr)) {
  if ($nummatch == 1) {
    $condstr = "<ul>$nummatch program matches:\n";
  } else {
    $condstr  = "<ul>$nummatch programs match:\n";
  }
  foreach my $key (keys %condstr) {
    my ($ckey, $cval) = split(/[\s=]+/, $condstr{$key});
    my $condname = $radutils::db_program{$key}->[0];
    $condstr .= "<li>$condname = '$cval'\n";
  }
  $condstr .= "</ul>";
  print "<tr>\n<td width='350'>\n$condstr\n";
  if ($showcap) {
    print "Note: $showcap programs match these criteria. This shows only the $nummatch that have screen captures.\n";
  }
  print "</td></tr>\n";
} else {
  unless ($included) {
    print "<tr><td class='white'>\n";
    my $finderstr = "/${STR_FINDER}";
    print "Use <a class='green' href='/${STR_FINDER}'>Search</a> to narrow your search by specifying an image format, platform, or function.\n";
    print "</td></tr>\n";
  }
}

# Exit if nothing to show.
unless ($nummatch) {
  print "</table>\n";
  exit;
}

# ------------------------------------------------------------
# Row for page navigation links.
# ------------------------------------------------------------
my $add_col = ($included) ? 'Remove' : 'Add';
my %hdg = (
  'program.name'	=> [170, 'Name'       , 1],
  'bogus.capicon'       => [16,  'Capture',   , 0],
  'bogus.progicon'      => [85,  'Platform'   , 0],
  'bogus.ificon'        => [60,  'Interface'  , 0],
  'program.summ'	=> [280, 'Description', 0],
  'author.name_last'    => [110, 'Author'     , 1],
  'program.urlstat'     => [30,  'URL'        , 0],
  'program.percentile'  => [40,  'Rank'       , 1],
  'bogus.rev'		=> [45,  'Rev'        , 0],
  'program.rdate'	=> [45,  'Date'       , 1],
  'bogus.watch'         => [30,  $add_col     , 0],
);
  
# Display $numperpage matches at a time, unless it's me doing admin.
my $page = $cgi->param('page');
$page = 0 unless (has_len($page));

# finderstr used later for appending sort order to column URL.  
# finderstr_noorder is for column headings that will have order added to them.
my ($finderstr, $finderstr_noorder) = ("", "");
my ($ord_ampersand, $noord_ampersand) = ("", "");
# Make up condition string, if needed, for finder.
foreach my $var (qw(order func readfmt writfmt plat lang edit category showcap)) {
  if (has_len($cgi->param($var))) {
    $finderstr .= "${ord_ampersand}$var=$$var";
    $ord_ampersand = "\&";
    # finderstr_noorder does not include the 'order' CGI parameter.
    if ($var ne "order") {
      $finderstr_noorder .= "${noord_ampersand}$var=$$var";
      $noord_ampersand = "\&";
    }
  }
}

# Display list on multiple pages.
my ($tnum, $tpage) = ($edit) ? ($nummatch, 0) : ($numperpage, $page);
my $url = "/${STR_PROGRAMS}";
my ($low, $high, $navcode) = listParts($nummatch, $tnum, $tpage, $url, $finderstr, @allnames);

# listParts returns empty HTML if only one page to display.
my @subrecs = @allrecs[$low..$high];
my $numsubrecs = scalar(@subrecs);
if (has_len($navcode)) {
  print "<tr>\n<td class='white' align='center'>\n$navcode\n</td>\n</tr>\n";
}

# ------------------------------------------------------------
# Row for table listing programs.
# ------------------------------------------------------------
print comment("Row for table listing programs.", 1);
print "<tr>\n";
print "<td width='$radutils::TABLEWIDTH' class='white' valign='top'>\n";

# Table display is different if displaying screen captures.
my ($wwidth, @keyvals);
# Accumulate divs for tool tip text.
if ($showcap) {
  $wwidth = $edit ? "" : "width='$radutils::TABLEWIDTH'";
  my $nrows = int(($numsubrecs + $NCAPCOL - 1)/ $NCAPCOL);
  print "<table cellspacing='0' cellpadding='10' border='1' $wwidth>\n";
  foreach my $row (0..($nrows - 1)) {
    print comment("Programs table: Screen captures: row $row", 1);
    print "<tr>\n";
    foreach my $col (0..($NCAPCOL - 1)) {
      my $tdtxt = '';
      my $subrecindex = $row * $NCAPCOL + $col;
      if ($subrecindex >= $numsubrecs) {
        $tdtxt = "&nbsp;";
      } else {
        my $subrec = $subrecs[$subrecindex];
        my %subrec = %$subrec;
        my ($progid, $progname, $summ) = @subrec{(qw(ident name summ))};

        my $caprecs = getCaptureImages($dbh, $progid);
        my %caprecs = %$caprecs;
        my @capords = keys %caprecs;
        my ($randord) = randomSubset(\@capords, 1);
        my $caprec = $caprecs{$randord};
        my $smimgdet = $caprec->{'320'};
        my %smimgdet = %$smimgdet;
        my ($smpath, $smfilename, $smwidth, $smheight) = @smimgdet{qw(path filename width height)};
        my $href  = "href='/${STR_PROGRAM}/$progid'>";
        my $imgsrc = "/img/cap/prog/${smpath}/${smfilename}";
        $tdtxt .= "<h3><a ${href}${progname}</a></h3>\n";
        $tdtxt .= "<br />$summ<br />\n";
        $tdtxt .= "<br /><a ${href}<img width='$smwidth' height='$smheight' border='0' src='$imgsrc' alt='$smfilename' /></a>\n";
      }
      print "<td valign='top'>$tdtxt</td>\n";
    }
    print "</tr>\n";
  }
  print "</table>\n";
} else {
  # Not showing screen captures.
  # Sort index -> Field width, name, sortable.
  @keyvals = qw(program.name bogus.capicon bogus.progicon program.summ author.name_last program.urlstat program.percentile bogus.rev program.rdate bogus.watch);
  if ($edit) {
    $hdg{'bogus.track'}       = ([30, 'nTrk',  0]);
    $hdg{'bogus.updates'}     = ([30, 'nUpd',  0]);
    $hdg{'bogus.revurl'}      = ([30, 'rURL',  0]);
    $hdg{'program.visdate'}   = ([30, 'visit', 1]);
    $hdg{'bogus.delete'}      = ([30, 'Del',   0]);
    @keyvals = (@keyvals, 'bogus.track', 'bogus.updates', 'bogus.revurl', 'program.visdate', 'bogus.delete');
  }

  $wwidth = $edit ? "" : "width='$radutils::TABLEWIDTH'";
  print "<table cellspacing='0' cellpadding='3' border='1' $wwidth>\n";
  printColumnHeadings(\@keyvals, 1);
  my $rowno = 0;
  foreach my $sqlrec (@subrecs) {
    printTableLine($sqlrec, 1, $rowno++);
  }
  print "</table>\n";
}
print comment("End of row holding table of program descriptions");
print "</td>\n</tr>\n";

# List removed programs, if it's me.
if ($edit) {
  printRowWhiteCtr "<h2>Removed Programs</h2>";
  my $tstr = "<table cellspacing='0' cellpadding='2' border='1' $wwidth>\n";
  $tstr .= printColumnHeadings(\@keyvals, 0);
  my $rowno = 0;
  foreach my $remrec (@remrec) {
    $tstr .= printTableLine($remrec, 0, $rowno++);
  }
  $tstr .= "</table>\n";
  printRowWhite($tstr);
}

# Print Javascript content_vars for tip strings.
# Define doAdd = 1 since apending to content_vars object literal in scope of HTML page.
printToolTips(\%g_tipstrs, 0);

$dbh->disconnect();

sub printColumnHeadings {
  my ($aref, $doprint) = @_;
  my @keys = @$aref;

  $doprint = 1 unless (has_len($doprint) and ($doprint ==0));
  # Print column headings to sort by.
  my $str = "<tr>\n";
  my $url;
  foreach my $key (@keys) {
    my ($width, $title, $sortable) = @{$hdg{$key}};
    # Special case: Platforms icon does not get its own heading.
    next if ($key =~ /bogus.progicon|bogus.capicon/);
    # Special case: Sortable by URL status if I am editing.
    if ($edit and $key =~ /urlstat/) {
      $sortable = 1;
    }
    $url = "/${STR_PROGRAMS}";
    my $a_str;
    my $star = ($key eq $order) ? " *" : "";
    if ($sortable) {
      $a_str = "class='orange_u' href='${url}?order=$key&amp;$finderstr_noorder'";
    } else {
      $a_str = "class='orange'";
    }
    my %thopts = ('width' => $width);
    if ($key =~ /program.name/) {
      # Calculate width for column spanning 3 cells.
      my $namewidth = $hdg{'program.name'}->[0] + $hdg{'bogus.capicon'}->[0] + $hdg{'bogus.progicon'}->[0] + $hdg{'bogus.ificon'}->[0];
      %thopts = (
	'colspan' => '4',
	'width'   => $namewidth,
      );
    }
    $str .= $cgi->th(\%thopts,
		     "<a $a_str>$title</a>&nbsp;$star") . "\n";
  }
  $str .= "</tr>\n";
  print($str) if ($doprint);
  return $str;
}

sub printTableLine {
  my ($sqlrec, $doprint, $rowno) = @_;
  $rowno = 0 unless (defined($rowno) and $rowno);

  $doprint = 1 unless (has_len($doprint) and ($doprint ==0));
  my %sqlrec = %$sqlrec;
  my ($progid, $progname, $progsumm, $authid, $progurl, $urlstat, $revurl, $linkcount, $rev, $rdate, $interface, $percentile) = @sqlrec{(qw(ident name summ author.ident progurl urlstat revurl linkcount rev rdate interface percentile))};

  # Get program link and platform and interface icons.
  my %popts = (
    'ident'  => $progid,
    'dbh'    => $dbh,
    'maxlen' => '',
    'isnew'  => 0,
    'showimg' => $edit,
  );
  my $proglink = makeProgramLink(\%popts);
  my %proglink = %$proglink;
  my ($progstr, $capstr, $platstr, $ifacestr) = @proglink{qw(progstr capstr platstr ifacestr)};
  # Add tooltip objects to global g_tipvars.
  addCvars($proglink, \%g_tipstrs);

  # ---------- 'Name' column ----------
  # Change progstr if editing.
  if ($edit) {
    my $prog_url = "/${STR_EDIT_PROGRAM}?ident=$progid";
    $progstr  = "<a href='$prog_url'>$progname</a>";
  }

  # ---------- 'Description' column ----------
  # Program summary gets icon for resource, if there are any.
  $progsumm = "&nbsp;" unless has_len($progsumm);
  my $rsrcicon = makeRsrcIcon($dbh, $progid);
  if (has_len($rsrcicon)) {
    $progsumm .= "&nbsp;&nbsp;$rsrcicon->{'iconstr'}";
    addCvars($rsrcicon, \%g_tipstrs);
  }

  # ---------- 'Author' column ----------
  my %authopts = (
    'maxlen'  => 20,
    'flag'    => 1,
  );
  my $authptr = authName($dbh, $authid, \%authopts);
  addCvars($authptr, \%g_tipstrs);
  my $aname = $authptr->{'urlstr'};
  $aname = "&nbsp;" unless has_len($aname);

  # ---------- 'URL' column ----------
  my %urlopts = (
    'cgi'     => $cgi,
    'ident'   => $progid,
    'urlstat' => $urlstat,
    'field'   => "homeurl",
    'table'   => "program",
    'tip_0'   => $TIP_HOMEURL_0,
    'tip_1'   => $TIP_HOMEURL_1,
  );

  my $urlicon = urlIcon(\%urlopts);
  my %urlicon = %$urlicon;
  my ($urlstr, $url_cvars) = @urlicon{qw(urlstr url_cvars)};
  my $tipclass = $url_cvars->{'class'};
  $g_tipstrs{$tipclass} = $url_cvars unless (defined($g_tipstrs{$tipclass}));

  # ---------- 'Rank' column ----------
  # Link count and monitor checkbox.
  my $linkicon = ($edit) ? $percentile : linkCountIcon($percentile);

  # ---------- 'Rev' column ----------
  $rev = "&nbsp;" unless (has_len($rev));

  # ---------- 'Date' column ----------
  my $rdatestr = "&nbsp;";
  $rdatestr = convert_date($rdate, $DATE_MDY);

  # ---------- 'Add/Remove' column ----------
  # Data for monitor icon.
  my $is_monitored = grep(/$progid/, @monitored);
  my $can_monitor = (has_len($rev) or validDate($rdate));

  # Returns hash of (urlstr, iconstr, tipstr, tipclass).
  my $mon_det = make_monitor_details($userid, $progid, $is_monitored, $can_monitor, $included);
  my $mon_url   = $mon_det->{$MON_URL};
  my $mon_icon  = $mon_det->{$MON_ICON};
  my $mon_cvars = $mon_det->{$MON_CVARS};
  my $tip_class = $mon_det->{$MON_TIPCL};

  my $monitored = (has_len($mon_url)) ? "<a href='$mon_url'>$mon_icon</a>" : $mon_icon;

  # Add the cvars objects for add/monitor icon to global variable g_tipstrs for later printing.
  $g_tipstrs{$tip_class} = $mon_cvars unless (defined($g_tipstrs{$tip_class}));

  my $outstr = '';
  my $vtop = "-valign => 'top'";

  $outstr .= comment("Programs table row for program '$progname'", 1);
  my $oddrowclass = ($rowno % 2) ? " class='oddrow'" : "";
  $outstr .= "<tr${oddrowclass}>\n";
  # 'Name' column: Program name and link.
  $outstr .= $cgi->td({-class  => 'noborderright',
		       -valign => 'top'}, 
		      $progstr) . "\n";
  # 'Name' column: Image capture.
  $outstr .= $cgi->td({-class => 'noborderright',
		       -valign => 'top'}, 
		      $capstr) . "\n";
  # 'Name' column: Platform.
  $outstr .= $cgi->td({-class => 'noborderright',
		       -valign => 'top'}, 
		      $platstr) . "\n";
  # 'Name' column: Interface.
  $outstr .= $cgi->td({-valign => 'top'}, 
		      $ifacestr) . "\n";
  # 'Description' column.
  $outstr .= $cgi->td({-valign => 'top'}, 
		      $progsumm) . "\n";
  # 'Author' column.
  $outstr .= $cgi->td({-valign => 'top'}, 
		      $aname) . "\n";
  # 'URL' column.
  $outstr .= $cgi->td({-align => 'center',
		       -valign => 'top'}, 
		      $urlstr)    . "\n";
  # 'Rank' column.
  $outstr .= $cgi->td({-align => 'left',
		       -valign => 'top'},   
		      $linkicon)  . "\n";
  # 'Rev' column.
  $outstr .= $cgi->td({-align => 'left',
		       -valign => 'top'},   
		      $rev)       . "\n";
  # 'Date' column.
  $outstr .= $cgi->td({-align => 'left',
		       -valign => 'top'},   
		      $rdatestr)  . "\n";
  # 'Add' column.
  $outstr .= $cgi->td({-align => 'center',
		       -valign => 'top'}, 
		      $monitored) . "\n";

  if ($edit) {
    # Extra info displayed if I am editing.
    # 1. Number of people tracking.
    my $str = "select count(*) from monitor where progid = '$progid'";
    my $sh = dbQuery($dbh, $str);
    my ($ntrk) = $sh->fetchrow_array();
    $ntrk = "&nbsp;" if ($ntrk == 0);
    $outstr .= $cgi->td({-align => 'left'}, $ntrk) . "\n";
    # 2. Number of updates.
    $str = "select count(*) from version where progid = '$progid'";
    $sh = dbQuery($dbh, $str);
    my ($nupd) = $sh->fetchrow_array();
    $nupd = "&nbsp;" if ($nupd == 0);
    $outstr .= $cgi->td({-align => 'center'}, $nupd) . "\n";
    # 3. Rev URL present.
    $str = "select revurl, visdate from program where ident = '$progid'";
    $sh = dbQuery($dbh, $str);
    my ($rurl, $vdate) = $sh->fetchrow_array();
    $rurl = (has_len($rurl)) ? "Y" : "&nbsp;";
    $outstr .= $cgi->td({-align => 'center'}, $rurl) . "\n";
    # 4. Date host site last visited.
    if (has_len($vdate)) {
      $vdate = convert_date($vdate);
    } else {
      $vdate = "&nbsp;";
    }

    $outstr .= $cgi->td({-align => 'center'}, $vdate) . "\n";
    # 5. 'Delete' button.
    my $delstr = "<a href='/${STR_RM_PROGRAM}?ident=$progid'>DEL</a>";
    $outstr .= $cgi->td({-align => 'center'}, $delstr) . "\n";
  }

  $outstr .= "</tr>\n";  
  print $outstr if ($doprint);
  return $outstr;
}

  sub countEntries {
    my ($dbh, $str) = @_;

    my $sh = dbQuery($dbh, $str);
    my ($ret) = $sh->fetchrow_array();
    return $ret;
  }

