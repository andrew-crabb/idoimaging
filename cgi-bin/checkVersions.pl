#! /usr/local/bin/perl -w

use DBI;
use CGI;
use Getopt::Std;
use CGI::Carp qw(fatalsToBrowser warningsToBrowser);
use FindBin qw($Bin);
use lib $Bin;
use radutils;
use Utilities_new;
# use strict;

my $cgi = new CGI;
print $cgi->header();

my $dbh = hostConnect();
my $title = "Manual Check Software Versions";

warningsToBrowser(1);

printStartHTML($cgi, $title);
printTitle($cgi);
# dumpParams($cgi);

my %tables = ('name'     => [50, 0],
	      'homeurl'  => [50, 0],
	      'rev'      => [20, 5],
	      'revurl'   => [150, 40],
	      'revstr'   => [100, 25],
	      'revtrust' => [20, 1]
	      );

print "<center><h2>Edit Version String, URL and Flag</h2></center>\n";

my @params = $cgi->param();
if (my ($progid) = grep(/Go_/, @params)) {
  # Called by self: Process changes then resubmit.
  $progid =~ s/Go_//;
  tt("Called by self: $progid");
  my @cgivars = grep(/var_${progid}/, @params);
  # Get matching values from database.
  my $str = "select rev, revurl, revstr, revtrust from program where ident = $progid";
  my $sh = dbQuery($dbh, $str);
  my $pprog = $sh->fetchrow_hashref();
  my ($upstr, $comma) = ("", "");
  foreach my $cgivar (@cgivars) {
    my $varname = $cgivar;
    $varname =~ s/var_${progid}_//;
    my $cgival = $cgi->param($cgivar);
    my $dbval = $pprog->{"$varname"};
    my $diff = "    ";
    if (hasLen($cgival) and hasLen($dbval)) {
      if ($cgival ne $dbval) {
	$diff = "DIFF";
	$upstr = "$comma $varname = '$cgival'";
	$comma = ",";
      } else {
	$diff = "&nbsp;&nbsp;&nbsp;&nbsp;";
      }
    }
    tt("$diff | $cgivar | $varname | $cgival | $dbval");
  }
  if (length($upstr)) {
    $upstr = "update program set $upstr where ident = $progid";
    tt($upstr);
    dbQuery($dbh, $upstr);
  }
}

my $str = "select * from program where ident >= 100 order by revtrust, name";
my $sh = dbQuery($dbh, $str);

print $cgi->startform() . "\n";
print "<br><table cellpadding=0 cellspacing=2 border=0>\n";

my $lastflag = -1;
while (my $prog = $sh->fetchrow_hashref()) {
  my $trstr = "";
  if ($prog->{'revtrust'} != $lastflag) {
    # Print heading for this group by trust flag.
    $trstr = $cgi->th([qw(Name Ver VersionURL VerString Flag &nbsp;)]);
  } else {
    foreach my $var (qw(name rev revurl revstr revtrust)) {
      my ($width, $size) = @{$tables{$var}};
      my $fld;
      my $val = $prog->{$var};
      if ($var =~ /summ/) {
	# These fields are displayed, non editable.
	$fld = $val;
      } elsif ($var =~ /name/) {
	my $url = $prog->{'homeurl'};
	$url = "http://${url}" unless ($url =~ /^http/);
	$fld = "<a target='new' href='$url'>$val</a>";
# 	my $url = makeURL($prog, 'homeurl');
	$fld = "<a target='new' href='$url'>$val</a>";
	print "URL(homeurl) = $url\n";
      } elsif ($var =~ /homeurl/) {
	# Display link only for home.
      } else {
	$fld = $cgi->textfield(-name    => "var_$prog->{'ident'}_${var}",
			       -default => $val,
			       -size    => $size);
      }
      # Add 'visit' link after URL fields.
      if ($var =~ /revurl/) {
	my $url = $prog->{'revurl'};
	$url = "http://${url}" unless ($url =~ /^http/);
	$fld .= "&nbsp;<a target='new' href='$url'>&nbsp;Visit&nbsp;</a>";
      }
      $trstr .= "<td >$fld</td>";
    }
    # 'Submit' button in last column.
    $trstr .= $cgi->td($cgi->submit(-name => "Go_$prog->{'ident'}",
				    -value => "Go"));
  }
  $lastflag = $prog->{'revtrust'};
  print "<tr>$trstr</tr>\n";
}
print "</table>\n";
print $cgi->endform() . "\n";
