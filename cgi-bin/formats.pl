#! /usr/local/bin/perl -w
# formats.pl

use strict;
no strict 'refs';

use DBI;
use CGI;

use FindBin qw($Bin);
use lib $Bin;
use radutils;
use Utilities_new;

# ------------------------------------------------------------
# Constants
# ------------------------------------------------------------
my $TIP_RSRCURL_1 = "Visit website for this resource";
my $TIP_RSRCURL_0 = "Project website is currently down (try anyway)";

my $cgi = new CGI;
print $cgi->header();

my $dbh = hostConnect();

# Ident of specified format, and sort order.
our ($ident, $name);
($ident, $name) = ('', '');
foreach my $var (qw(ident name)) {
  $$var = (hasLen($cgi->param($var))) ? $cgi->param($var) : "";
}

# Show one format in detail if specified.
if (hasLen($ident)) {
  # Get resources related to this format.
  my $str = "select ident, type, url, urlstat, summ from resource ";
  $str .= "where format = '$ident'";
  my $sh = dbQuery($dbh, $str);

  my $rstr = comment("========== Table for related resources ==========", 1);
  $rstr .= "<table cellpadding='2' cellspacing='0' border='1'>\n";
  my $firstline = 1;
  my %tipstrs = ();
  while (my ($rident, $rtype, $rurl, $rstat, $rsumm) = $sh->fetchrow_array()) {
    if ($firstline) {
      $rstr .= $cgi->Tr($cgi->th([qw(Type Summary URL)])) . "\n";
      $firstline = 0;
    }
    $rtype = $resourcetype{$rtype};

    my %urlopts = (
      'cgi'     => $cgi,
      'ident'   => $rident,
      'urlstat' => $rstat,
      'table'   => "resource",
      'field'   => "url",
      'tip_0'   => $TIP_RSRCURL_0,
      'tip_1'   => $TIP_RSRCURL_1,
	);
    my $urlicon = urlIcon(\%urlopts);
    my %urlicon = %$urlicon;
    my ($urlstr, $url_cvars) = @urlicon{qw(urlstr url_cvars)};
  if (hasLen($url_cvars)) {
    $tipstrs{$url_cvars->{'class'}} = $url_cvars unless (exists($tipstrs{$url_cvars->{'class'}}));
  }


    $rsumm = truncateString($rsumm, 40);
    $rstr .= $cgi->Tr($cgi->td([$rtype, $rsumm, $urlstr])) . "\n";
  }
  $rstr .= "</table>\n";

  $str = "select name, summ, descr from format where ident = '$ident'";
  $sh = dbQuery($dbh, $str);
  if (my ($fname, $fsumm, $fdescr) = $sh->fetchrow_array()) {
    my $title = "I Do Imaging - Format: $fname";
    
    print "<tr><td class='white' align='center'>\n";
    print "<h2>Format: $fname</h2>\n";
    print "</td></tr>\n";

    my $searchstr = "/${STR_PROGRAMS}?readfmt=$ident";
    $searchstr .= "&amp;order=program.percentile";
    $searchstr = "<a href='${searchstr}'>Click for list of software using this file format</a>";

    print comment("========== Row for table holding contents ==========", 1);
    print "<tr><td class='white'>\n";
    print "<table cellpadding='4' cellspacing='0' width='600' border='1'>\n";
    print $cgi->Tr($cgi->th({-width => '100'}, "Name"),
		   $cgi->td($fname)) . "\n";
    print $cgi->Tr($cgi->th("Summary"),
		   $cgi->td($fsumm)) . "\n";
    print $cgi->Tr($cgi->th("Description"),
		   $cgi->td($fdescr)) . "\n";
    print $cgi->Tr($cgi->th({-valign => 'top'}, "Resources"),
		   $cgi->td($rstr)) . "\n";
    print $cgi->Tr($cgi->th({-valign => 'top'}, "Software"),
		   $cgi->td($searchstr)) . "\n";
    print "</table>\n";
    print "</td></tr>\n";
    print comment("========== End row for table holding contents ==========");
  }
  # Print divs holding tool tip text.
printToolTips(\%tipstrs);
  
  exit;
}

# ------------------------------------------------------------
# No ident given: Show all formats.
# ------------------------------------------------------------

my $title = "I Do Imaging - File Formats";

# Prepare data.
my $sqlstr = "select ident, name, summ from format order by name";
my $sh = dbQuery($dbh, $sqlstr);

my %headings = ('name'	=> ['Name', 130],
		'summ'	=> ['Summary', 470]);
# Outer enclosing table just for aligning title with table.

print "<tr><td class='white' align='center'><h2 class='title'>File Formats</h2></td></tr>\n";

print comment("========== Row for table holding contents ==========");
print "<tr><td class='white' align='center'>\n";
print "<table border='1' cellpadding='2' cellspacing='0' width='600'>\n";

print comment("========== Row for table row titles ==========");
print "<tr>\n";
foreach $title qw(name summ) {
  my $url = "/${STR_FORMATS}?order=$title";
  my ($fname, $fwidth) = @{$headings{$title}};
  print $cgi->th({-width => $fwidth}, "<a class='orange' href='$url'>$fname</a>\n");
}
print "</tr>\n";

print comment("========== Table row contents ==========");
while (my (@bits) = $sh->fetchrow_array()) {
  my ($id, $name, $summ) = @bits;
  my $url = "/${STR_FORMATS}?ident=$id";
  $name = "<a href='$url'>$name</a>";
  $summ = (hasLen($summ)) ? $summ : "&nbsp;";
  print $cgi->Tr($cgi->td([$name, $summ])) . "\n";
}


print "</table>\n";
print "</td></tr>\n";
print comment("========== End of row for table holding contents ==========");

