#! /usr/local/bin/perl -w

use strict;
no strict 'refs';

use DBI;
use CGI;

use FindBin qw($Bin);
use lib $Bin;
use radutils;
use Utilities_new;
use bigint;

my $TIP_AUTHURL_1  = "Visit website for this author";
my $TIP_AUTHURL_0  = "Author's website is currently down (try anyway)";
my $TIP_AUTHURL_NA = "No website available";

my $cgi = new CGI;

# Constants.
my $NPERPAGE = 20;

my ($dbh) = hostConnect();

# Ident of specified author, and sort order.
our ($order, $page, $ident);
foreach my $var (qw(order ident page)) {
  $$var = (hasLen($cgi->param($var))) ? $cgi->param($var) : "";
}
$order = 'name_last' unless (hasLen($order));

if (hasLen($ident)) {
  # Gather data on programs written by this author.
  # Do this first as may print redirect header if exactly one program.
  my $austr  = "select ident, name, summ from program where auth = '$ident' and ident >= 100 order by name";
  my $aush = dbQuery($dbh, $austr);
  my $auref = $aush->fetchall_arrayref;
  $aush->finish();
  my @auths = @$auref;
  # if (scalar(@auths) == 1) {
  #   my ($pident, $pname, $psumm) = @{$auths[0]};
  #   my $progurl = "/${STR_PROGRAM}/$pident";
  #   print $cgi->redirect($progurl);
  #   exit;
  # }

  print $cgi->header();
  my $title = "I Do Imaging - Software Authors";

  # Long display of one author if ID specified.
  my $tablestr = '';

  my $str = "select name_last, name_first, email, home from author where ident = '$ident'";
  my $sh = dbQuery($dbh, $str);
  my ($alast, $afirst, $aemail, $ahome) = ('', '', '', '');
  if (($alast, $afirst, $aemail, $ahome) = $sh->fetchrow_array()) {

    $tablestr .= "<table cellpadding='3' cellspacing='0' width='700' border='1'>\n";
#     $tablestr .= $cgi->Tr($cgi->th(["Name", "Description"])) . "\n";
    $tablestr .= "<tr>\n";
    $tablestr .= "<th width='200'>Name</th>\n";
    $tablestr .= "<th width='500'>Description</th>\n";
    $tablestr .= "</tr>\n";

    foreach my $authref (@auths) {
      my ($pident, $pname, $psumm) = @$authref;

      my $url = "/${STR_PROGRAM}/$pident";
      $tablestr .= $cgi->Tr($cgi->td({-width => '200'}, "<a href='$url'>$pname</a>"),
			    $cgi->td({-width => '500'}, $psumm)) . "\n";
    }
    $tablestr .= "</table>\n";
  }
  

  printRowWhiteCtr("<h2>Author: $afirst $alast</h2>");

  print "<tr><td class='white' width='700'>\n";
  print $tablestr;
  print "</td></tr>\n";
  exit;
}

# No author ident supplied: Show list of all.
print $cgi->header();
my $title = "I Do Imaging - Software Authors";

# Prepare data.
my $sqlstr = "select distinct";
$sqlstr .= " author.ident, author.name_last, author.name_first, author.email, author.home, author.urlstat";
$sqlstr .= " from author, program"; 
$sqlstr .= " where author.ident = program.auth and program.ident > 100";
$sqlstr .= " order by $order";

my $sh = dbQuery($dbh, $sqlstr);
my $aref = $sh->fetchall_arrayref();
my @matches = @$aref;
my $nmatch = scalar(@matches);

# Display $NPERPAGE matches at a time.
$page = 0 unless (hasLen($page));
my $offset = $page * $NPERPAGE;
my $first = $offset + 1;
my $max = $offset + $NPERPAGE;
$max = $nmatch if ($max > $nmatch);
my @subrec = @matches[$offset..($max - 1)];
my $npage = int($nmatch/$NPERPAGE) + 1;

my $tdtext = '';
# Previous page.
my $cgilink = "/${STR_PEOPLE}";
my $prev = $page - 1;
my $prevurl = "<a class='grey' href='${cgilink}?page=$prev'>";
# my $prevurl = "<a class='grey' href='/${STR_PEOPLE}/page=$prev'>";
$prevurl = ($prev >= 0) ? "${prevurl}Previous</a>" : "Previous";

# Next page.
my $next = $page + 1;
my $nexturl = "<a class='grey' href='${cgilink}?page=$next'>";
# my $nexturl = "<a class='grey' href='/${STR_PEOPLE}/page=$next'>";
$nexturl = ($next < $npage) ? "${nexturl}Next</a>" : "Next";

$tdtext .=  "$prevurl\n";
foreach my $pind (0..($npage - 1)) {
  $tdtext .=  "&nbsp;&nbsp;";
  my $nextpage = $pind + 1;
  my $url = "${cgilink}?page=$pind";

  if ($pind == $page) {
    $tdtext .=  "<tt class='big'><b>$nextpage</b></tt>\n";
  } else {
    $tdtext .=  "<a class='grey' href='$url'>$nextpage</a>\n";
  }
}
$tdtext .=  "&nbsp;&nbsp;";
$tdtext .=  "$nexturl\n";

# Outer table of 1 column * 3 rows: Page title, selectors, content.
print "<tr><td class='light_bg' align='center'><h2 class='title'>Software Authors</h2></td></tr>\n";

print "<tr><td class='light_bg' align='center'>Displaying $first..$max of $nmatch authors</td></tr>\n";
print "<tr><td class='light_bg' align='center'>$tdtext</td></tr>\n";

my %headings = (
  'name_last' => 'Name',
  'email'     => 'Email',
  'home'      => 'Home URL',
    );

print "<tr><td class='white' align='center'>\n";
print "<table cellpadding='2' cellspacing='0' width='600' bgcolor='#CCCCFF' border='1'>\n";
# Print column headings to sort by.
print "<tr>\n";

foreach $title qw(name_last email home) {
  my $a_str;
  if ($title =~ /name_last/) {
    my $url = "/${STR_PEOPLE}?order=$title";
    $a_str = "class='orange_u' href='${url}'";
  } else {
    $a_str = "class='orange'";
  }
  print $cgi->th("<a $a_str>" . $headings{$title} . "</a>\n");
}
print "</tr>\n";

my %tipstrs = ();
foreach my $bptr (@subrec) {
  my @bits = @$bptr;
  my ($id, $last, $first, $email, $aurl, $urlstat) = @bits;
  # Author name and flag, with tool tip.
  my %authopts = (
    'flag'    => 1,
      );
  my $aptr = authName($dbh, $id, \%authopts);
  my $aulink = $aptr->{'urlstr'};
  addCvars($aptr, \%tipstrs);

  $first = "" unless (hasLen($first));
  $last = "" unless (hasLen($last));
  # 'email' field is icon of email addr, or blank space if no email addr.
  my $email_txt = "&nbsp;";
  if (hasLen($email)) {
    $email_txt = sprintf("/img/email/email_%04d.gif", $id);
    $email_txt = "<img border='0' src='${email_txt}' alt='email.gif' />";
  }
  my %urlopts = (
    'cgi'     => $cgi,
    'ident'   => $id,
    'url'     => $aurl,
    'urlstat' => $urlstat,
    'table'   => "author",
    'field'   => "home",
    'tip_0'   => $TIP_AUTHURL_0,
    'tip_1'   => $TIP_AUTHURL_1,
    'tip_na'   => $TIP_AUTHURL_NA,
      );
    my $urlicon = urlIcon(\%urlopts);
    my %urlicon = %$urlicon;
    my ($urlstr, $url_cvars) = @urlicon{qw(urlstr url_cvars)};
#     push(@tipstrs, $tipstr) unless (grep(/^$tipstr$/, @tipstrs));
  if (hasLen($url_cvars)) {
    $tipstrs{$url_cvars->{'class'}} = $url_cvars unless (exists($tipstrs{$url_cvars->{'class'}}));
  }


  print $cgi->Tr($cgi->td({-align => 'left'},
			  [$aulink, $email_txt, $urlstr])) . "\n";
}
print "</table>\n";
printToolTips(\%tipstrs);

print "</td></tr>\n";
