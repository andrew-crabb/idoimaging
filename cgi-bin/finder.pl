#! /usr/local/bin/perl -w

use DBI;
use CGI;
use CGI::Carp qw(fatalsToBrowser warningsToBrowser);
use FindBin qw($Bin);
use lib $Bin;
use radutils;
use bigint;
use Getopt::Std;

# Options: (V)erbose.
my %opts;
getopts('vn', \%opts);	
my $verbose = ($opts{'v'}) ? 1 : 0;
my $noheader = ($opts{'n'}) ? 1 : 0;

# ============================================================
# Constants
# ============================================================

our $PROGRAM_FORM = 'program_form';

# ============================================================
# JavaScript
# ============================================================

my $jquery_code = <<EOD;
<script type="text/javascript">
    \$(document).ready(function(){
                       });
      function submitSearchForm(){
        quizSearchForm = jQuery("#${PROGRAM_FORM}");
        quizSearchForm.find(':input[value=""]').attr('disabled', true);
        quizSearchForm.submit();
      }
</script>
EOD
# There's an apostrophe here just to fix the Perl syntax highlighting...

# ============================================================
# Main
# ============================================================

my $cgi = new CGI;
unless ($noheader) {
  print $cgi->header();
}
 # dumpParams($cgi);

my $dbh = hostConnect();

# ============================================================
# Table 'Search'
# ============================================================

print "<tr id='finder_content_tr'>\n";
print "<td id='finder_content_td' class='white'>\n";

print "<table id='search' width='$radutils::TABLEWIDTH' cellpadding='0' cellspacing='0' border='1'>\n";

# ------------------------------------------------------------
# Table 'Search': Row 0: Software classification search.
# ------------------------------------------------------------

print comment("Search table: Row 0: Cols 0-1: 'Search Software Classifications' table", 1);
print "<tr id='search_r0' valign='top'>\n";
print "<td id='search_r0c0' width='$radutils::TABLEWIDTH' colspan='2' class='white' align='center'>\n";

# Begin form for software classifications search.
print $cgi->startform(
  -action => "/${STR_PROGRAMS}",
   -method => 'GET',
  -id     => $PROGRAM_FORM,
    );

# ============================================================
# Table 'Software Classification'
# ============================================================
print comment("Table for row 0: Software Classification.");
print "<table id='search_clas' width='$radutils::TABLEWIDTH' cellpadding='5' cellspacing='0' border='0'>\n";

# ------------------------------------------------------------
# Table 'Classification': Row 0: Selection category headings.
# ------------------------------------------------------------
print "<tr id='search_clas_r0' >\n";
print "<td align='center' class='white' colspan='6'>\n";
print "<h3 class='title'>Search Software Classifications</h3>\n";
print "</td>\n";
print "</tr>  <!-- search_clas_r0 -->\n";

# ------------------------------------------------------------
# Table 'Classification': Row 1: Selection category headings.
# ------------------------------------------------------------
my @slct = ('Function', 'Speciality', 'Input Format', 'Output Format', 'Platform', 'Language');
print comment("Search table: Row 1: Col 0-5: Classification titles", 1);
print $cgi->Tr(
  $cgi->th( {
    -width => '121',
    -align => 'left',
            }, 
           [@slct]),
    ) . "\n";

# ------------------------------------------------------------
# Table 'Classification': Row 2: Selection category lists.
# ------------------------------------------------------------
print comment("Search table: Row 2: Col 0-5: Classification popup inputs", 1);
print "<tr>\n";
foreach my $categ (qw(func category readfmt writfmt plat lang)) {
  my $hashname = ($categ =~ /fmt$/) ? "cat_formats" : "cat_${categ}";
  # If an array of radutils hash keys is available, use it.  Else sort values.
  my (@vals, %labels);
  my $keyarray = "radutils::cat_${categ}";
  if (defined(@{$keyarray})) {
    @vals = ('', @{$keyarray});
    my %category = %$keyarray;
    foreach my $val (@vals) {
      $labels{$val} = $category{$val}->[0];
    }
  } else {
    @vals = ("", sortHashVal($hashname, 0));
    %hash = %{"radutils::${hashname}"};
    foreach my $val (@vals) {
      $labels{$val} = $hash{$val}->[0];
    }
  }
  $labels{''} = "All/Any";
  print $cgi->td( { -width => '121' },
		  $cgi->popup_menu(
                    -name   => $categ,
                    -values => \@vals,
                    -labels => \%labels,
                  )) . "\n";
}
print "</tr>\n";

# ------------------------------------------------------------
# Table 'Classification': Row 3: Selection form buttons.
# ------------------------------------------------------------
print comment("Search table: Row 3: Col 0-5: Classification submit buttons", 1);
print "<tr>\n";
print "<td width='121'>&nbsp;</td><td width='121'>&nbsp;</td>\n";
print $cgi->td({-width => '121', -align => 'center'}, $cgi->submit(-name => 'Search Classifications', -onClick => 'submitSearchForm()')) . "\n";
print $cgi->td({-width => '121', -align => 'center'}, $cgi->reset()) . "\n";
print "<td width='121'>&nbsp;</td><td width='121'>&nbsp;</td>\n";
print "</tr>\n";

# ============================================================
# End of table 'Classification'
# ============================================================
print comment("End of table 'Software Classification'.");
print "</table>\n";
print $cgi->endform() . "\n";

# ------------------------------------------------------------
# End of Table 'Search': Row 0: Software Classification
# ------------------------------------------------------------
print "</td>  <!-- search_r0c0 -->\n";
print "</tr>  <!-- search_r0 -->\n";

# ------------------------------------------------------------
# Table 'Search': Row 1: Two td's, each with a table (need the dividing line between them).
# ------------------------------------------------------------
print "<tr id='search_r1'>\n";

# -------------------- Col 0: Site description search --------------------
print comment("Row 1 Col 0: Search site descriptions");
print "<td id='search_r1c0' valign='top' class='white'>\n";

# ============================================================
# Table 'Software Description'
# ============================================================
print "<table id='search_desc' width='$radutils::HALFWIDTH' cellpadding='5' cellspacing='0' border='0'>\n";

# ------------------------------------------------------------
# Table 'Software Description': Row 0: Title image.
# ------------------------------------------------------------
print comment("Table 'Software Description': Row 0: Title image.", 1);
print "<tr>\n";
print "<td class='light_bg' width='$radutils::HALFWIDTH' align='center'>\n";
print "<h3 class='title'>Search Software Descriptions</h3>\n";
print "</td>\n";
print "</tr>\n";

# ------------------------------------------------------------
# Table 'Software Description': Row 0: Title image.
# ------------------------------------------------------------
print comment("Table 'Software Description': Row 1: Text.", 1);
print "<tr>\n";
print "<td height='30' valign='top' class='light_bg'>\n";
print "Search the program names and descriptions stored in the database.\n";
print "</td>\n";
print "</tr>\n";

# ------------------------------------------------------------
# Table 'Software Description': Row 0: Title image.
# ------------------------------------------------------------
print comment("Table 'Software Description': Row 2: Search box.", 1);
print "<tr>\n";
print "<td height='30' valign='top' align='center' >";
print $cgi->startform(
    -action => "/${STR_SEARCH}",
    -method => 'GET',
    );
print "<input class='blue' type='text' name='search' size='22' maxlength='100' />\n";
print "&nbsp;&nbsp;";
print $cgi->submit(-name => 'Search') . "\n";
print $cgi->endform() . "\n";
print "</td>\n";
print "</tr>\n";

# ============================================================
# End of Table 'Software Description'
# ============================================================
print "</table>  <!-- search_desc -->\n";
print "</td>  <!-- search_r1c0 -->\n";

# -------------------- Col 1: Google search --------------------
print comment("Row 4 Col 1: Google search");
print "<td id='search_r1c1' valign='top' class='white'>\n";

# ============================================================
# Table 'Google Search'
# ============================================================
print comment("Table to contain Google search components");
print "<table id='search_sites' width='$radutils::HALFWIDTH' cellpadding='5' cellspacing='0' border='0'>\n";

# ------------------------------------------------------------
# Table 'Google Search': Row 0: Title image.
# ------------------------------------------------------------
print comment("Table 'Google Search': Row 0: Title image.", 1);
print "<tr>\n";
print "<td class='light_bg' align='center' width='$radutils::HALFWIDTH'>\n";
print "<h3 class='title'>Search Project Web Sites</h3>\n";
print "</td>\n";
print "</tr>\n";

# ------------------------------------------------------------
# Table 'Google Search': Row 0: Description.
# ------------------------------------------------------------
print comment("Table 'Google Search': Row 0: Description.", 1);
print "\n<tr>\n";
print "<td height='30' valign='top' class='light_bg'>\n";
print <<ENDOFTEXT;
Search the contents of all web sites indexed by I Do Imaging.  
Searching for common terms may produce many unsorted results. 
ENDOFTEXT
print "</td>\n";
print "</tr>\n";

# ------------------------------------------------------------
# Table 'Google Search': Row 2: Search box.
# ------------------------------------------------------------
print comment("Table 'Google Search': Row 2: Search box", 1);
print "<tr>\n";
print "<td height='30' valign='middle' align='center'>\n";
print <<EOGOOGLE;
<form action="http://www.idoimaging.com/search_results.php" id="cse-search-box">
  <div>
    <input type="hidden" name="cx" value="015375320376295324229:-syh5thp9gc" />
    <input type="hidden" name="cof" value="FORID:9" />
    <input type="hidden" name="ie" value="UTF-8" />
    <input type="text" name="q" size="22" />
    <input type="submit" name="sa" value="Search" />
  </div>
</form>
<script type="text/javascript" src="http://www.google.com/coop/cse/brand?form=cse-search-box&amp;lang=en"></script>
EOGOOGLE
print "</td>\n";
print "</tr>\n";

# ============================================================
# End of Table 'Google Search'
# ============================================================
print "</table>  <!-- search_sites -->\n";
print "</td>  <!-- search_r1c1 -->\n";
print "</tr>  <!-- search_r1 -->\n";

# ============================================================
# End of Table 'Search'
# ============================================================
print "</table>  <!-- search -->\n";

print "</td>  <!-- finder_content_td -->\n";
print "</tr>  <!-- finder_content_tr -->\n";
