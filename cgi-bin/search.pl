#! /usr/local/bin/perl -w

use CGI;
use CGI::Carp 'fatalsToBrowser';
use DBI;
use FindBin qw($Bin);
use lib $Bin;
use Utility;
use radutils;
use bigint;

$cgi = new CGI;
print $cgi->header();

my $dbh = hostConnect();
my $search = $cgi->param('search');

# Log this search term to a file.
my $logfile = "/search.log";
if (open(LOG, ">>$logfile")) {
  my $time = timeNow()->{'MM/DD/YY'};
  print LOG "$time  $search\n";
  close(LOG);
}

my $LEFTCOLWIDTH = 200;
my $RIGHTCOLWIDTH = 450;

# printStartHTML($cgi);
# printTitle($cgi);
printRowWhiteCtr("<h2 class='title'>Search Results</h2>");

    
unless (has_len($search)) {
  printRowWhite("There were no matches for your search.");
  if (defined(my $referer = $cgi->referer())) {
    printRowWhite("Click <a class='green' href='$referer'>here</a> to return to the previous screen.");
  }
  exit;
}

# First search author.
my $str = "select ident, name_last, name_first from author where ";
my ($searchstr, $searchtext) = buildsearch('name_last', $search);
$str .= $searchstr;
($searchstr, $searchtext) = buildsearch('name_first', $search);
$str .= " or $searchstr";
$str .= " order by name_last";

my $sh = dbQuery($dbh, $str);
my $ref = $sh->fetchall_arrayref;
$sh->finish();
my @autharr = @$ref;
my $nummatch = scalar(@autharr);
if (scalar(@autharr)) {
  print "<tr><td class='white'>\n";
  print "<table cellspacing=0 cellpadding=2 border=1>\n";
  print "<tr><th>$nummatch Author names matching '$searchtext'</th></tr>\n";
  foreach my $entry (@autharr) {
    my ($ident, $name) = @$entry;
    my $fname = fmtAuthorName($ident, $dbh);
    my $url = "<a href=/${STR_PEOPLE}?ident=$ident>$fname</a>";
    print "<tr><td>$url</td></tr>\n";
  }
  print "</table>\n";
  print "</td></tr>\n";
}

# Now search program names.
my ($numname, @foundprogs);
($searchstr, $searchtext) = buildsearch('name', $search);
$str = "select ident, name, summ from program where $searchstr and ident >= 100 order by name";
# print "$str<br>\n";
$sh = dbQuery($dbh, $str);
$ref = $sh->fetchall_arrayref;
$sh->finish();
my @namearr = @$ref;
my %tipstrs = ();
$nummatch = scalar(@namearr);
if (scalar(@namearr)) {
  print "<tr><td class='white'>\n";
  print "<table cellspacing='0' cellpadding='2' border='1'>\n";
  print "<tr><th colspan='5'>$nummatch Program names matching '$searchtext'</th></tr>\n";
  foreach my $entry (@namearr) {
    my ($ident, $name, $summ) = @$entry;
    push(@foundprogs, $ident);

  my %popts = (
    'ident'  => $ident,
    'dbh'    => $dbh,
    'maxlen' => 25,
    'isnew'  => 0,
  );
  my $proglink = makeProgramLink(\%popts);
      my %proglink = %$proglink;

      my ($progstr , $prog_cvars)  = @proglink{qw(progstr  prog_cvars)};
      my ($capstr  , $cap_cvars)   = @proglink{qw(capstr   cap_cvars)};
      my ($platstr , $plat_cvars)  = @proglink{qw(platstr  plat_cvars)};
      my ($ifacestr, $iface_cvars) = @proglink{qw(ifacestr iface_cvars)};

      # Accumulate tooltip objects if they are new.
      if (has_len($prog_cvars)) {
	$tipstrs{$prog_cvars->{'class'}} = $prog_cvars unless (exists($tipstrs{$prog_cvars->{'class'}}));
      }
      if (has_len($cap_cvars)) {
	$tipstrs{$cap_cvars->{'class'}} = $cap_cvars unless (exists($tipstrs{$cap_cvars->{'class'}}));
      }
      if (has_len($plat_cvars)) {
	$tipstrs{$plat_cvars->{'class'}} = $plat_cvars unless (exists($tipstrs{$plat_cvars->{'class'}}));
      }
      if (has_len($iface_cvars)) {
	$tipstrs{$iface_cvars->{'class'}} = $iface_cvars unless (exists($tipstrs{$iface_cvars->{'class'}}));
      }

    print "<tr>\n";
    print "<td class='noborderright' width=$LEFTCOLWIDTH valign='top'>$progstr</td>\n";
    print "<td class='noborderright'>$capstr</td>\n";
    print "<td class='noborderright'>$platstr</td>\n";
    print "<td class='noborderright'>$ifacestr</td>\n";
    print "<td width=$RIGHTCOLWIDTH>&nbsp;&nbsp;$summ</td>\n";
    print "</tr>\n";
    $numname++;
  }
  print "</table>\n";
  print "</td></tr>\n";
}

# Now search program text.
($searchstr, $searchtext) = buildsearch('summ', $search);
my ($dsearchstr, $dsearchtext) = buildsearch('descr', $search);

my $summstr = "select ident, name, summ from program where ident >= 100 and ($searchstr or $dsearchstr) order by name";
my $summsh = dbQuery($dbh, $summstr);
$summref = $summsh->fetchall_arrayref;
$summsh->finish();
my @summarr = @$summref;
$nummatch = scalar(@summarr);

# Filter out programs already seen.
my @newsummarr;
foreach my $entry (@summarr) {
  my ($ident, $name, $summ) = @$entry;
  push(@newsummarr, $entry) unless (grep(/$ident/, @foundprogs));
}

my $newsumm = scalar(@newsummarr);
if ($newsumm) {
  print "<tr><td class='white'>\n";
  print "<table cellspacing='0' cellpadding='2' border='1'>\n";
  print "<tr><th colspan='5'>An additional $newsumm program descriptions contain '$searchtext'</th></tr>\n";
  foreach my $entry (@summarr) {
    my ($ident, $name, $summ) = @$entry;
    # Skip previously listed programs.
    next if (grep(/$ident/, @foundprogs));
  my %popts = (
    'ident'  => $ident,
    'dbh'    => $dbh,
    'maxlen' => 25,
    'isnew'  => 0,
  );
  my $proglink = makeProgramLink(\%popts);
      my %proglink = %$proglink;

      my ($progstr , $prog_cvars)  = @proglink{qw(progstr  prog_cvars)};
      my ($capstr  , $cap_cvars)   = @proglink{qw(capstr   cap_cvars)};
      my ($platstr , $plat_cvars)  = @proglink{qw(platstr  plat_cvars)};
      my ($ifacestr, $iface_cvars) = @proglink{qw(ifacestr iface_cvars)};

      # Accumulate tooltip objects if they are new.
      if (has_len($prog_cvars)) {
	$tipstrs{$prog_cvars->{'class'}} = $prog_cvars unless (exists($tipstrs{$prog_cvars->{'class'}}));
      }
      if (has_len($cap_cvars)) {
	$tipstrs{$cap_cvars->{'class'}} = $cap_cvars unless (exists($tipstrs{$cap_cvars->{'class'}}));
      }
      if (has_len($plat_cvars)) {
	$tipstrs{$plat_cvars->{'class'}} = $plat_cvars unless (exists($tipstrs{$plat_cvars->{'class'}}));
      }
      if (has_len($iface_cvars)) {
	$tipstrs{$iface_cvars->{'class'}} = $iface_cvars unless (exists($tipstrs{$iface_cvars->{'class'}}));
      }

    print "<tr>\n";
    print "<td class='noborderright' width=$LEFTCOLWIDTH valign='top'>$progstr</td>\n";
    print "<td class='noborderright'>$capstr</td>\n";
    print "<td class='noborderright'>$platstr</td>\n";
    print "<td class='noborderright'>$ifacestr</td>\n";
    print "<td width=$RIGHTCOLWIDTH>&nbsp;&nbsp;$summ</td>\n";
    print "</tr>\n";
#     print "<tr><td width=$LEFTCOLWIDTH valign='top'>$url</td><td width=$RIGHTCOLWIDTH>$summ</td></tr>\n";
  }
  print "</table>\n";
  print "</td></tr>\n";
}

printToolTips(\%tipstrs);

print "</table>\n";

sub buildsearch {
  my ($var, $search) = @_;

  # Split the search term up into atoms.
  $search =~ s/^\s+//;	# Leading spaces.
  $search =~ s/\s+$//;	# Trailing spaces.
  $search =~ s/\W/ /g;	# Non-chars become space (delimiters).
  my @bits = split(/\s+/, $search);
  my $searchtext = join(" AND ", @bits);

  my $searchstr = "";
  my $and = "";
  foreach my $bit (@bits) {
    $searchstr .= "$and $var like '%$bit%'";
    $and = "and";
  }
  $searchstr = "($searchstr)" if (scalar(@bits) > 1);
  return($searchstr, $searchtext);
}
