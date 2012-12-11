#! /usr/local/bin/perl -w

use strict;
use CGI;
use CGI::Carp;
use DBI;
use FindBin qw($Bin);
use lib $Bin;
use radutils;
use Utilities_new;
use bigint;

my $cgi = new CGI;
print $cgi->header();
my $dbh = hostConnect();
my $NPERPAGE = 35;

# table.field => [width, title, sort order, secondary key, sec sort order]
# sortable: 0 = not, 1 = ascending, 2 = descending.
my %hdg = (
  'name'    => [100, 'Name',        $radutils::AS, 'version', $radutils::DE],
  'summ'    => [250, 'Description', $radutils::NN, '',        $radutils::NN],
  'version' => [ 40, 'Version',     $radutils::NN, '',        $radutils::NN],
  'reldate' => [ 40, 'Released',    $radutils::DE, 'name',    $radutils::AS],
  'adddate' => [ 40, 'Added',       $radutils::DE, 'name',    $radutils::AS],
    );


my $order = $cgi->param('order');
my $ndays = $cgi->param('days') || '';
my $table = $cgi->param('table') || 'version';
$table = 'version' unless ($table =~ /program|version/);
$order = "adddate desc, name asc" unless (hasLen($order));

# Run this different ways depending on whether programs or versions being listed.
my @versions = ();

my $str = "select version.progid, version.version, version.reldate, ";
$str .= "program.name, program.summ, ${table}.adddate ";

if ($table eq 'program') {
  $str .= ", version.ident as version_ident " ;
  $str .= ", version.reldate as version_reldate " ;
}

$str .= "from version, program ";
$str .= "where version.progid = program.ident ";
$str .= "and ((length(version) > 0) ";
$str .= "or (reldate != '0000-00-00')) ";
$str .= "and ${table}.adddate > date_add(curdate(), interval - $ndays day) " if (hasLen($ndays));
$str .= "order by $order ";
$str .= "limit 500";
# tt($str);
my $sh = dbQuery($dbh, $str);

my %allprogs = ();
while (my $rptr = $sh->fetchrow_hashref()) {
  if ($table eq 'version') {
    push(@versions, $rptr);
  } else {
    push(@{$allprogs{$rptr->{'progid'}}}, $rptr);
  }
}

if ($table eq 'program') {
  foreach my $progid (sort {$a <=> $b} keys %allprogs) {
    my $progptr = $allprogs{$progid};
    my @progs = @$progptr;
    my @progs_sorted = sort {$b->{'version_ident'} <=> $a->{'version_ident'}} @progs;
    my $n = scalar(@progs);
    my $prog = $progs_sorted[0];
    tt("$prog->{'name'} has $n versions, most recent ident $prog->{'version_ident'} dated  $prog->{'version_reldate'}");
  }
}

# Display the contents.
my $nver = scalar(@versions);

my $page = $cgi->param('page');
$page = 0 unless (hasLen($page));
my $tmporder = $order;
$tmporder =~ s/\ /\&nbsp\;/g;
# my $optstr = "order=$tmporder";
my $optstr = (hasLen($ndays)) ? "days=$ndays" : "";

my $linkcode = "/${STR_LIST_VERSIONS}";
my ($low, $high, $navcode) = listParts($nver, $NPERPAGE, $page, $linkcode, $optstr);
my @subver = @versions[$low..$high];

print "<tr><td class='light_bg' align='center'><h2 class='title'>Version Release Archive</h2></td></tr>\n";


if (hasLen($ndays)) {
  my $dtxt = "Displaying versions added in the past $ndays days";
  print "<tr><td class='light_bg' align='center'>$dtxt</td></tr>\n";
}
print "<tr><td class='light_bg' align='center'>$navcode</td></tr>\n";

# ------------------------------------------------------------
# Print table.
# ------------------------------------------------------------

print "<tr><td class='light_bg' align='center'>\n";
print "<table cellspacing=0 cellpadding=3 border=1 width=$radutils::TABLEWIDTH>\n";

# Print heading row.

my @keyvals = (qw(name summ version reldate adddate));
my $listurl = "/${STR_LIST_VERSIONS}";

# ====== Come back to this one - it includes sort by column colde (which needs fixing for subsets) ======
# my $headingrow = sortedHeadingRow($cgi, $order, $listurl, \@keyvals, \%hdg);
# print $headingrow;

my $outstr = "";

$outstr .= "<tr>\n";
$outstr .= "<th width='130' >Name</th>";
$outstr .= "<th width='70' class='noborderright'>&nbsp;</th>";
$outstr .= "<th width='350' align='left'>Description</th>";
$outstr .= "<th width='40'>Version</th>";
$outstr .= "<th width='40'>Released</th>";
$outstr .= "<th width='40'>Added</th>";
$outstr .= "</tr>\n";


# Print one line per version release.

my %g_tipstrs = ();
foreach my $version (@subver) {
  my %version = %$version;
  my ($progid, $version, $reldate, $name, $summ, $adddate) = @version{qw(progid version reldate name summ adddate)};

  my %popts = (
    'ident'  => $progid,
    'dbh'    => $dbh,
    'maxlen' => '25',
  );
  my $proglink = makeProgramLink(\%popts);
  my %proglink = %$proglink;
  my ($progstr, $capstr, $platstr) = @proglink{qw(progstr capstr platstr)};
  # Add tooltip objects to global g_tipvars.
  addCvars($proglink, \%g_tipstrs);

  $reldate = convertDates($reldate)->{'MM/DD/YY'};
  $adddate = convertDates($adddate)->{'MM/DD/YY'};

  $outstr .= "<tr>\n";
  $outstr .= "<td width='130' align='left'>$progstr</td>\n";
  $outstr .= "<td width='70'  align='left' class='noborderright'>${capstr}&nbsp;${platstr}</td>\n";
  $outstr .= "<td width='350' align='left'>$summ</td>\n";
  $outstr .= "<td width='40'  align='left'>$version</td>\n";
  $outstr .= "<td width='40'  align='left'>$reldate</td>\n";
  $outstr .= "<td width='40'  align='left'>$adddate</td>\n";
  $outstr .= "</tr>\n";
}
  print $outstr;

print "</table>\n";
print "</td>\n</tr>\n";
printToolTips(\%g_tipstrs);
