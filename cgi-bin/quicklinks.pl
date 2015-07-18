#! /usr/bin/env perl
use warnings;

# Creates table of top N results for 3 platforms in categories:
# DICOM viewer (3), format converter (3), PACS client (2).

use CGI;
# use CGI::Carp;
use DBI;
use Getopt::Std;

use FindBin qw($Bin);
use lib $Bin;
use Utility;
use radutils;
use bignum;

use strict; 
no strict 'refs';

# Options: (V)erbose.
my %opts;
getopts('nv', \%opts);	
my $verbose = ($opts{'v'}) ? 1 : 0;
my $noheader = ($opts{'n'}) ? 1 : 0;

my $cgi = new CGI;
my $dbh = hostConnect();

# ------------------------------------------------------------
# Gather data.
# ------------------------------------------------------------

# Get list of all programs.

my $str = "select * from program";
$str .= " where ident >= 100 and remdate like '0000%'";
$str .= " order by percentile desc";
my $sh = dbQuery($dbh, $str);
my @progs = ();
while (my $aptr = $sh->fetchrow_hashref()) {
  push(@progs, $aptr);
}

# Get list of all images.
$str  = "select rsrcid from image";
$str .= " where rsrcfld = 'prog'";
$str .= " group by rsrcid";

$sh = dbQuery($dbh, $str);
my %progimgs = ();
while (my ($rsrcid) = $sh->fetchrow_array) {
  $progimgs{$rsrcid} = 1;
}

my %funcnames = (
  $radutils::FUNC_DISP => "Display DICOM", 
  $radutils::FUNC_CONV => "Convert Files", 
  $radutils::CATE_PACS => "PACS Client",
    );

# Iterate over programs by percentile, pulling out those matching combinations of conditions.
my %favs = ();
my %caps = ();
foreach my $prog (@progs) {
  my $progid = $prog->{'ident'};
  my ($ident, $name, $plat, $func, $categ, $readfmt) = @{$prog}{qw(ident name plat func category readfmt)};


  foreach my $plat (@radutils::cat_plat) {
    # Get top matches by function.
    foreach my $func ($radutils::FUNC_DISP, $radutils::FUNC_CONV) {
      if (isMatch($prog, $plat, $func, '')) {
	push(@{$favs{$plat}{$func}}, $prog);
	if (defined($progimgs{$progid}) and ($progimgs{$progid} > 0)) {
	  push(@{$caps{$plat}{$func}}, $prog);
	}
      }
    }

    # Get top matches by category
    if (isMatch($prog, $plat, '', $radutils::CATE_PACS)) {
      push(@{$favs{$plat}{$radutils::CATE_PACS}}, $prog);
      if (defined($progimgs{$progid}) and ($progimgs{$progid} > 0)) {
	push(@{$caps{$plat}{$radutils::CATE_PACS}}, $prog);
      }
    }
  }
}
# -------------------- Print output table. --------------------

my $col0width = 90;
my $col1width = 15;
my $progcolwidth0 = 80;
my $progcolwidth1 =115;
my $progcolwidth2 = 65;

unless ($noheader) {
  print $cgi->header();
}
# printRowWhiteCtr("<img class='title' src='img/title/quick_links.png' alt='quick_links.png' />");
printRowWhiteCtr("<h2 class='title'>Quick Links To Popular Programs</h2>");

print comment("Begin Quick Links table.");
print "<tr>\n";
print "<td class='white' align='center'>\n";
print "<table width='$radutils::TABLEWIDTH' border='1' cellspacing='0' cellpadding='2'>\n";
# -- Print header row --
print "<tr>\n";
print "<th class='noborderbottom borderright' width='$col0width'>&nbsp;</th>\n";
print "<th class='noborderright noborderbottom' width='$col1width'>&nbsp;</th>\n";
foreach my $platform (qw(Windows Macintosh Linux)) {
  print "<th class='noborderbottom borderright' colspan='2'>$platform</th>\n";
}
print "</tr>\n";

my %tipstrs = ();
foreach my $func ($radutils::FUNC_DISP, $radutils::FUNC_CONV, $radutils::CATE_PACS) {
  # Section heading: 'Full List' row.
  my $fld = ($func == $radutils::CATE_PACS) ? "category" : "func";
  print "<tr>\n";
  print "<th class='noborderbottom borderright' width='$col0width'>$funcnames{$func}</th>\n";
  print "<th class='noborderright noborderbottom' width='$col1width'>&nbsp;</th>\n";
  my %nperplat = ();
  foreach my $plat (@radutils::cat_plat) {
    my @all = @{$favs{$plat}{$func}};
    my $numprogs = scalar(@all);
    $nperplat{$plat} = $numprogs;
    
    my $urlstr = "/${STR_PROGRAMS}?${fld}=${func}&amp;plat=${plat}";
    $urlstr .= "&amp;readfmt=2" if ($func == 4);
    $urlstr .= "&amp;order=program.percentile";
    $urlstr = "<a class='orange'  href='${urlstr}'>Full List of $numprogs</a>";
    print "<th class='borderright noborderbottom' colspan='2'>$urlstr</th>\n";
  }
  print "</tr>\n";

  # Section heading: 'Screen Captures' row.
  print "<tr>\n";
  print "<th class='noborderbottom borderright' width='$col0width'>&nbsp;</th>\n";
  print "<th class='noborderright borderbottom' width='$col1width'>&nbsp;</th>\n";
  foreach my $plat (@radutils::cat_plat) {
    my @all = @{$caps{$plat}{$func}};
    my $numcaps = scalar(@all);
    my $urlstr = "/${STR_PROGRAMS}?${fld}=${func}&amp;plat=${plat}";
    $urlstr .= "&amp;readfmt=2" if ($func == 4);
    $urlstr .= "&amp;order=program.percentile";
    $urlstr .= "&amp;showcap=$nperplat{$plat}";
    $urlstr = "<a class='orange'  href='${urlstr}'>$numcaps Screen Captures</a>";
    print "<th class='borderright borderbottom' colspan='2'>$urlstr</th>\n";
  }  
  print "</tr>\n";

  # One row per top 3 in each category.
  foreach my $n (1..3) {
    print "<tr>\n";
    my $fn = "&nbsp;";
    my $borderbottom = ($n == 3) ? "borderbottom" : "noborderbottom";
    print "<th class='borderright $borderbottom' width='$col0width'>$fn</th>\n";
    print "<td class='noborderright $borderbottom' width='$col1width' align='left'>$n</td>\n";
    foreach my $plat (@radutils::cat_plat) {
      my $prog = $favs{$plat}{$func}[$n - 1];
      my %prog = %$prog;
      my ($name, $ident, $capture, $interface) = @prog{qw(name ident capture interface)};
      $name = substr($name, 0, 18) . "..." if (length($name) > 18);
      my %popts = (
	'ident'  => $prog,
	'dbh'    => $dbh,
	'maxlen' => 15,
	'isnew'  => 0,
	  );
      my $proglink = makeProgramLink(\%popts);
      my %proglink = %$proglink;

      my ($progstr , $prog_cvars)  = @proglink{qw(progstr  prog_cvars)};
      my ($capstr  , $cap_cvars)   = @proglink{qw(capstr   cap_cvars)};
      my ($platstr , $plat_cvars)  = @proglink{qw(platstr  plat_cvars)};
      my ($ifacestr, $iface_cvars) = @proglink{qw(ifacestr iface_cvars)};

      print "<td class='noborderright borderleft $borderbottom' width='$progcolwidth0' align='left'>$progstr</td>\n";
      print "<td class='borderright $borderbottom' width='$progcolwidth1' align='left'>$capstr&nbsp;$platstr$ifacestr</td>\n";
      
      # Accumulate tooltip objects if they are new.
      foreach my $cvar ($prog_cvars, $cap_cvars, $plat_cvars, $iface_cvars) {
	addToCvars($cvar, \%tipstrs);
      }
    }
    print "</tr>\n";
  }
}

print comment("End Quick Links table.");
print "</table>\n";

# Print Javascript content_vars for tip strings.
printToolTips(\%tipstrs);

print comment("============================================================");

print comment("End row for Quick Links table.");
print "</td></tr>\n";

sub isMatch {
  my ($prog, $platform, $function, $category) = @_;
  my %prog = %{$prog};

  my ($ident, $name, $plat, $func, $categ, $readfmt) = @prog{qw(ident name plat func category readfmt)};
  my $ret = 0;

  if (($plat * 1) & ($platform * 1)) {
    if (has_len($function)) {
      # HACK: select Dicom (val = 2) programs if function is Display.
      if ($function == $radutils::FUNC_DISP) {
	$ret = (($readfmt * 1) & 2) ? 1 : 0;
      } else {
	$ret = 1;
      }
      if ($ret) {
	$ret = (($func * 1) & ($function * 1)) ? 1 : 0;
      }
    } else {
      $ret = (($categ * 1) & ($category * 1)) ? 1 : 0;
    }
  }
  return $ret;
}

sub addToCvars {
  my ($cvar, $tipstrs) = @_;

  if (has_len($cvar)) {
    my $cclass = $cvar->{'class'};
    unless (exists($tipstrs->{$cclass})) {
      $tipstrs->{$cclass} = $cvar ;
#       tt("Processing class: $cclass");
    }
  }
}
