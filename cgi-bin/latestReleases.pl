#! /usr/local/bin/perl -w

use CGI;
use CGI::Carp 'fatalsToBrowser';
use DBI;
use FindBin qw($Bin);
use lib $Bin;
use Utility;
use radutils;

$cgi = new CGI;
print $cgi->header();
my $dbh = hostConnect();

my $str = "select version.progid, version.version, version.reldate, ";
$str .= "program.name, program.summ, ";
$str .= "version.adddate as version_add, program.adddate as prog_add ";
$str .= "datediff(curdate(), program.adddate) as days_ago ";
$str .= "from version, program ";
$str .= "where version.progid = program.ident ";
$str .= "order by version.adddate desc, version.reldate desc limit 10";
$sh = dbQuery($dbh, $str);

print "<table border=1 cellspacing=0 cellpadding=2>\n";
print "<tr><th>Name</th><th>Summary</th><th>Version</th><th>Released</th><th>Added</th></tr>\n";
while (my $ver = $sh->fetchrow_hashref()) {
  print "<tr>\n";
  my $ident = $ver->{'progid'};
  foreach my $elem (qw(name summ version reldate version_add)) {
    my $value = $ver->{$elem};
    # Add href to program name
    if ($elem =~ /name/) {
      my $padd = $ver->{'prog_add'};
      if (has_len($padd) and ($padd !~ /0000/)) {
	# New program is one added within the last month.
	my $new = ($ver->{'days_ago'} < 30) ? " <font color=#22CC22>(New!)</font>" : "";
	$value .= $new;
      }
#       $value = "<a href=${CGI}/program.pl?ident=$ident>$value</a>";
      $value = "<a href='/${STR_PROGRAM}/$ident'>$value</a>";
    }
    if ($elem =~ /date$|version_add/) {
      $value = convert_date($value, $DATE_MDY);
    }
    $value = "&nbsp;" unless (has_len($value));
    print "<td>$value</td>";
  }
  print "</tr>\n";
}
print "</table>\n";
