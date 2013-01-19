#! /usr/local/bin/perl -w

# newReleases.pl
# Write table with new programs and versions.

use CGI;
# use CGI::Carp 'fatalsToBrowser';
use CGI::Carp;
use DBI;
use Getopt::Std;

use FindBin qw($Bin);
use lib $Bin;
use radutils;
use Utility;

# Options: (V)erbose.
my %opts;
getopts('vn', \%opts);	
my $verbose = ($opts{'v'}) ? 1 : 0;
my $noheader = ($opts{'n'}) ? 1 : 0;

use strict;
no strict 'refs';

my $cgi = new CGI;
unless ($noheader) {
  print $cgi->header();
}
my $dbh = hostConnect();

our %col_width = (
  'name'        => 200,
  'icons'       => 80,
  'summ'        => 400,
  'version'     => 50,
  'reldate'     => 50,
  'version_add' => 50,
  'adddate'     => 50,
);

my $str = "select version.progid, version.version, version.reldate, ";
$str .= "program.name, program.summ, ";
$str .= "version.adddate as version_add, ";
$str .= "datediff(curdate(), program.adddate) as days_ago ";
$str .= "from version, program ";
$str .= "where version.progid = program.ident ";
$str .= "and ((length(version) > 0) ";
$str .= "or (reldate != '0000-00-00')) ";
$str .= "and program.remdate = '0000-00-00' ";
$str .= "order by version.adddate desc, version.reldate desc limit 15";
my $sh = dbQuery($dbh, $str);

# ------------------------------------------------------------
# New Version Releases
# ------------------------------------------------------------

# printRowWhiteCtr("<img class='title' src='img/title/NewVersionReleases.png' alt='NewVersionReleases' />", $radutils::TABLEWIDTH);
printRowWhiteCtr("<h2 class='title'>New Version Releases</h2>", $radutils::TABLEWIDTH);
my $url = "/${STR_LIST_VERSIONS}";
my $tstr = '';
$tstr .= "<table width='$radutils::TABLEWIDTH' border='1' cellspacing='0' cellpadding='2'>\n";
$tstr .= "<tr><th colspan='2'>Name</th><th width='320'>Summary</th><th width='50'>Version</th><th width='50'>Released</th><th width='50'>Added</th></tr>\n";
$tstr .= "<tr>\n";
$tstr .= "<td align='center' colspan='2'><a href='$url'>Show Archive</a></td>\n";
$tstr .= "<td align='center'><a href='$url'>Show archive of all releases</a></td>\n";
$tstr .= "<td align='center'>-</td><td align='center'>-</td><td align='center'>-</td>\n";
$tstr .= "</tr>\n";

# Store program links and tooltip strings to avoid repeating database queries.
my %proglinks = ();
our %g_tipstrs = ();

while (my $ver = $sh->fetchrow_hashref()) {
  $tstr .= "<tr>\n";
  my $ident = $ver->{'progid'};

  my %popts = (
    'ident'  => $ident,
    'dbh'    => $dbh,
    'maxlen' => '',
    'isnew'  => (has_len($ver->{'days_ago'}) and ($ver->{'days_ago'} < 90)) ? 1 : 0,
  );
  my $proglink = makeProgramLink(\%popts);

  $proglinks{$ident} = $proglink;
  my %proglink = %$proglink;
  my ($progstr, $capstr, $platstr) = @proglink{qw(progstr capstr platstr)};
  # Add tooltip objects to global g_tipvars.
  addCvars($proglink, \%g_tipstrs);

  foreach my $elem (qw(name icons summ version reldate version_add)) {
    my $value = '';
    my $classstr = "";
    # Add href to program name
    if ($elem =~ /name/) {
      $value = $progstr;
      $classstr = "class='noborderright'";
    } elsif ($elem =~ /date$|version_add/) {
      if (my $dt = parse_sql_date($ver->{$elem})) {
	$value = $dt->mdy('/');
      }
    } elsif ($elem =~ /icons/) {
      $value = "${capstr}&nbsp;${platstr}";
    } else {
      # Default: Value comes directly from DB record.
      $value = $ver->{$elem};
    }
    $value = "&nbsp;" unless (has_len($value));

    # Program summary gets icon for resource, if there are any.
    if ($elem =~ /summ/) {
      my $rsrcicon = makeRsrcIcon($dbh, $ident);
      if (has_len($rsrcicon)) {
        $value .= "&nbsp;&nbsp;$rsrcicon->{'iconstr'}";
        addCvars($rsrcicon, \%g_tipstrs);
      }
    }

    my $tdwidth = $col_width{$elem};
    $tstr .= "<td ${classstr} width='$tdwidth' align='left' valign='top'>$value</td>\n";
  }
  $tstr .= "</tr>\n";
}
$tstr .= "</table>\n";

printRowWhiteCtr($tstr, $radutils::TABLEWIDTH);

# ------------------------------------------------------------
# Newly Added Programs
# ------------------------------------------------------------

$str  = "select ident, name, summ, adddate from program ";
$str .= "order by adddate desc limit 15";
$sh = dbQuery($dbh, $str);

# printRowWhiteCtr("<img class='title' src='img/title/NewlyAddedPrograms.png' alt='NewlyAddedPrograms.png' />", $radutils::TABLEWIDTH);
printRowWhiteCtr("<h2 class='title'>Newly Added Programs</h2>", $radutils::TABLEWIDTH);
$tstr = '';
$tstr .= "<table width='$radutils::TABLEWIDTH'  border='1' cellspacing='0' cellpadding='2'>\n";
$tstr .= "<tr><th colspan='2'>Name</th><th width='320'>Summary</th><th width='50'>Version</th><th width='50'>Released</th><th width='50'>Added</th></tr>\n";
while (my $ver = $sh->fetchrow_hashref()) {
  my %det = %$ver;
  our ($ident, $name, $summ, $adddate) = @det{qw(ident name summ adddate)};

  # Get program link from cached values, or database query.
  my $proglink = '';
  if (exists($proglinks{$ident})) {
    $proglink = $proglinks{$ident};
  } else {
    my %popts = (
      'ident'  => $ident,
      'dbh'    => $dbh,
      'maxlen' => '',
      'isnew'  => 0,
	);
    $proglink = makeProgramLink(\%popts);
  }
  $proglinks{$ident} = $proglink;
  my %proglink = %$proglink;
  my ($progstr, $capstr, $platstr) = @proglink{qw(progstr capstr platstr)};

  # Add tooltip objects to global g_tipvars.
  addCvars($proglink, \%g_tipstrs);

  # Find latest version for this program.
  $str = "select version, reldate from version where progid = $ident";
  my $vsh = dbQuery($dbh, $str);
  our ($version, $reldate) = ("", "");
  if (my (@ans) = $vsh->fetchrow_array()) {
    ($version, $reldate) = @ans;
  }

  $tstr .= "<tr>\n";
  foreach my $elem (qw(name icons summ version reldate adddate)) {
    my $value = '';
    my $classstr = '';
    # Add href to program name
    if ($elem =~ /name/) {
      $value = $progstr;
      $classstr = "class='noborderright'";
    } elsif ($elem =~ /date$|version_add/) {
      if (my $dt = parse_sql_date($$elem)) {
	$value = $dt->mdy('/');
      }
    } elsif ($elem =~ /icons/) {
      $value = "${capstr}&nbsp;${platstr}";
    } else {
      $value = $$elem;
    }
    $value = "&nbsp;" unless (has_len($value));

    # Program summary gets icon for resource, if there are any.
    if ($elem =~ /summ/) {
      my $rsrcicon = makeRsrcIcon($dbh, $ident);
      if (has_len($rsrcicon)) {
        $value .= "&nbsp;&nbsp;$rsrcicon->{'iconstr'}";
        addCvars($rsrcicon, \%g_tipstrs);
      }
    }

    my $tdwidth = $col_width{$elem};
    $tstr .= "<td ${classstr} width='$tdwidth' align='left' valign='top'>$value</td>\n";
  }
  $tstr .= "</tr>\n";
}
$tstr .= "</table>\n";

printRowWhiteCtr($tstr, $radutils::TABLEWIDTH);

# Print Javascript content_vars for tip strings.
# Define doAdd = 1 since apending to content_vars object literal in scope of HTML page.
printToolTips(\%g_tipstrs, 1);

