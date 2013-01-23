#! /usr/local/bin/perl -w
# resources.pl

use DBI;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use FindBin qw($Bin);
use strict;
no strict 'refs';
use lib $Bin;
use Utility;
use radutils;
use bigint;

my $TIP_RSRCURL_1 = "Visit website for this resource";
my $TIP_RSRCURL_0 = "Project website is currently down (try anyway)";

my $cgi = new CGI;
print $cgi->header();

my $dbh = hostConnect();

# dumpParams($cgi);

# Ident of specified resource, and sort order.
our ($ident, $order);
foreach my $var (qw(ident order)) {
  $$var = (has_len($cgi->param($var))) ? $cgi->param($var) : "";
}
print comment("resources: ident = '$ident', order = '$order'");
$order = 'format' unless (has_len($order));

# Show one resource in detail if specified.
if (has_len($ident)) {
  print comment("Show one resource in detail: $ident");
  my $str = "select format, type, url, summ, descr, reviewer";
  $str   .= " from resource";
  $str   .= " where ident = '$ident'";
  my $sh = dbQuery($dbh, $str);
  if (my ($rfmt, $rtype, $rurl, $rsumm, $rdesc, $rrev) = $sh->fetchrow_array()) {
    $rfmt = '' unless (has_len($rfmt));
    $rtype = '' unless (has_len($rtype));
    $rurl = '' unless (has_len($rurl));
    $rsumm = '' unless (has_len($rsumm));
    $rdesc = '' unless (has_len($rdesc));
    $rrev = '' unless (has_len($rrev));
    if ($rtype == 6) {
      # This is a review of a program.
      $str = "select program.name from program, resource where program.ident = resource.program";
      my $ssh = dbQuery($dbh, $str);
      if (my ($pname) = $ssh->fetchrow_array()) {
	print $cgi->h2("Review of: $pname") . "\n";
	print "<table cellpadding='2' cellspacing='0' width='500'>\n";
	print $cgi->Tr($cgi->th({-width => '100', -align => 'left'}, "Program"),
		       $cgi->td($pname)) . "\n";
	print $cgi->Tr($cgi->th({-align => 'left'}, "Reviewer"),
		       $cgi->td($rrev)) . "\n";
	print $cgi->Tr($cgi->th({-align => 'left'}, "Summary"),
		       $cgi->td($rdesc)) . "\n";
	print "</table>\n";
      }
    } else {
      # This is an online resource.
      print $cgi->h2("Format: $rfmt") . "\n";
      
      print "<table cellpadding='2' cellspacing='0' width='500'>\n";
      print $cgi->Tr($cgi->th({-width => '100'}, "Type"),
		     $cgi->td($rtype)) . "\n";
      print $cgi->Tr($cgi->th("URL"),
		     $cgi->td($rurl)) . "\n";
      print $cgi->Tr($cgi->th("Summary"),
		     $cgi->td($rsumm)) . "\n";
      print $cgi->Tr($cgi->th("Description"),
		     $cgi->td($rdesc)) . "\n";
      print "</table>\n";
    }
  }
  exit;
}

# Prepare data for online and review resources.
my $str  = "select ident, format, program, type, url, urlstat, summ, descr";
$str .= " from resource";
$str .= " where ((type != $RES_BLO) and (type != $RES_REV))";
$str .= " order by $order";
my $sh = dbQuery($dbh, $str);
my $refs = $sh->fetchall_arrayref();
my @refs = @$refs;

my %headings = (
  'category'=>['Category',50],
  'format' => ['Format',  50],
  'type'   => ['Type',    50],
  'summ'   => ['Summary', 370],
  'url'    => ['URL',     30],
    );
print comment("Begin online resources");

# Outer enclosing table just for aligning title with table.
print comment("Begin of alignment table");

printRowWhiteCtr("<h2 class='title'>Online Resources</h2>");


print comment("========== Row for online resources table ==========");
print "<tr><td class='light_bg' align='center'>\n";
print comment("Begin online resources table");
print "<table border='1' cellpadding='2' cellspacing='0' width='600'>\n";
# print "<table border='1' cellpadding='2' cellspacing='0' width='$radutils::TABLEWIDTH'>\n";

# Print column headings to sort by.
print "<tr>\n";
foreach my $title qw(category format type summ url) {
  my $sortorder = ($title =~ /category/) ? "format" : $title;
  my $url = "/${STR_RESOURCES}?order=$sortorder";
  my ($fname, $fwidth) = @{$headings{$title}};
  print $cgi->th({-width => $fwidth}, "<a class='orange' href='$url'>$fname</a>\n");
}
print "</tr>\n";

my %tipstrs = ();
foreach my $ref (@refs) {
  my ($ident, $format, $program, $type, $url, $urlstat, $summ, $desc) = @$ref;
  # Skip reviews.
  next if ($type == 5);
  $summ = cleanString($summ);
  $desc = cleanString($desc);

    my %urlopts = (
      'cgi'     => $cgi,
      'ident'   => $ident,
      'urlstat' => $urlstat,
      'table'   => "resource",
      'field'   => "url",
      'tip_0'   => $TIP_RSRCURL_0,
      'tip_1'   => $TIP_RSRCURL_1,
	);
    my $urlicon = urlIcon(\%urlopts);
    my %urlicon = %$urlicon;
    my ($urlstr, $url_cvars) = @urlicon{qw(urlstr url_cvars)};
  if (has_len($url_cvars)) {
    $tipstrs{$url_cvars->{'class'}} = $url_cvars unless (exists($tipstrs{$url_cvars->{'class'}}));
  }


  $summ = (has_len($summ)) ? $summ : "&nbsp;";
  if (length($summ) > 50) {
    $summ = substr($summ, 0, 50);
    $summ .= "...";
  }
  # ftype is file format name, or program name.
  my $ftype = "";
  my $category;
  if (has_len($program) and ($program != 0)) {
    # Get the name of this program.
    $str = "select name from program where ident = '$program'";
    $sh = dbQuery($dbh, $str);
    if (my ($progname) = $sh->fetchrow_array()) {
      $ftype = $progname;
    }
    $category = "Program";
  } else {
    $ftype = $radutils::cat_formats{$format}->[0];
    $category = "Format";
  }
  my $rtype = $resourcetype{$type};
  $rtype = "-" unless (has_len($rtype));
  my $width = $headings{$format}->[1];
  print $cgi->Tr($cgi->td({-align => 'left',
			  -width => $width},
			  [$category, $ftype, $rtype, $summ, $urlstr])) . "\n";
}
print "</table>\n";
print "</td></tr>\n";
print comment("========== End row for online resources table ==========");

printToolTips(\%tipstrs);

sub cleanString {
  my ($instr) = @_;

  $instr =~ s/[^a-zA-Z0-9\ \.\,\n]//g;
  return($instr);
}
