#! /usr/bin/env perl
use warnings;

use CGI;
use CGI::Carp;
use DBI;
use FindBin qw($Bin);
use lib $Bin;
use Utility;
use radutils;
use Userbase;
use bigint;
use strict;
no strict 'refs';

my $cgi = new CGI;

# Redirect unless this has come from me, not a search engine.
my $referer = $cgi->referer();

print $cgi->header();
# My little javascript bit.
my $jscript =<<EOJS;
<script type="text/javascript">
function today(element) {
  var now = new Date();
  var month = now.getMonth() + 1;
  var year = now.getFullYear();
  var syear = new String(year);
  year = syear.substr(2,2);
  var today = month + "/" + now.getDate() + "/" + year;

  element.value = today;
}
</script>
EOJS

my ($ident, $addprog) = getParams($cgi, (qw(ident add)));
$addprog = (has_len($addprog)) ? $addprog : 0;

# If adding program, ensure logged-in user is admin.
my $det = get_user_details();
unless ($det and $det->{$Userbase::UB_IS_ADMIN}) {
  print "<tt>Edit a program?  I don't think so.</tt><br>\n";
  get_user_details(1);
  exit;
}

my $dbh = hostConnect();
my $title = "Edit Program";

dumpParams($cgi);

#------------------------------------------------------------
# Data prep: Authors table.
#------------------------------------------------------------
my $str = "select * from author order by ident";
my $sh = dbQuery($dbh, $str);

my (%names);
$names{'0'} = '--- Select ---';
my $cnt = 0;

while (my $ref = $sh->fetchrow_hashref()) {
  my $ident = $ref->{'ident'};
  my $formatname = fmtAuthorName($ident, $dbh);
  $names{$ref->{'ident'}} = $formatname;
}
my @skeys = sort {$names{$a} cmp $names{$b}} keys %names;

#------------------------------------------------------------
# Data prep: Program table.
#------------------------------------------------------------
$str = "select * from program where ident = '$ident'";
$sh = dbQuery($dbh, $str);
my $prog = $sh->fetchrow_hashref();

#------------------------------------------------------------
# Data prep: Prerequsites.
#------------------------------------------------------------
$str = "select ident, name from program where ident < 100 order by name";
$sh = dbQuery($dbh, $str);
# Prerequsites are encoded as binary value.
my (%prereqs, @prereqs);
while (my @list = $sh->fetchrow_array()) {
  push(@prereqs, \@list);
  my $preid = $list[0];
  $prereqs{$list[0]} = $list[1];
  my $prer = $prog->{'prer'};
  push(@prereqs, $list[0]) if (has_len($prer) and ((2 ** $preid) & $prer));

}
my @prekeys = sort {"\U$prereqs{$a}" cmp "\U$prereqs{$b}"} keys %prereqs;

#------------------------------------------------------------
# Data prep: Relationships.
#------------------------------------------------------------
$str = "select prog2, type, date from relationship where prog1 = '$ident'";
$sh = dbQuery($dbh, $str);
my @relationships = ();
while (my $hptr = $sh->fetchrow_hashref()) {
  my $prog2 = $hptr->{'prog2'};
  my $pstr = "select name from program where ident = '$prog2';";
  my $psh = dbQuery($dbh, $pstr);
  my $h2ptr = $psh->fetchrow_hashref();
  push(@relationships, [($hptr, $h2ptr)]);
}
our %relat = %radutils::relationship;
my @relkeys = ("", sort {$relat{$a} cmp $relat{$b}} keys %relat);

#------------------------------------------------------------
# Data prep: List of program names for 'relationship' and 'related'
#------------------------------------------------------------
# Build list of %allprogs for related programs.
$str = "select ident, name from program where ident >= 100 order by name";
$sh = dbQuery($dbh, $str);
  
my %allprogs;
while (my ($ident, $name) = $sh->fetchrow_array()) {
  $allprogs{$ident} = substr($name, 0, 15);
}
my @allprogs = sort {"\U$allprogs{$a}" cmp "\U$allprogs{$b}"} keys %allprogs;
my $relref = relatedPrograms($dbh, $ident);
my %related = %$relref;

# Get list of secondary screen captures for this program.
my @seccaps = getSecondaryScreenCaptures($dbh, $ident);

#------------------------------------------------------------
# HTML code.
#------------------------------------------------------------
my $name = $prog->{'name'};
$name = '' unless (has_len($name));
$title = '';

my $sstr = "select count(*) from monitor where progid = '$ident'";
$sh = dbQuery($dbh, $sstr);
my ($ntrk) = $sh->fetchrow_array();
$sh->finish();

my $istr = "select count(*) from image where rsrcid = '$ident' and scale = 'full'";
$sh = dbQuery($dbh, $istr);
my ($nimg) = $sh->fetchrow_array();
$sh->finish();

$ntrk = 0 unless (has_len($ntrk) and $ntrk);
$title = "Editing: $name ($ntrk monitors, $nimg images)";
printRowWhiteCtr($cgi->h1($title));

my $remdate = $prog->{'remdate'};
if (defined($remdate) and ($remdate !~ /^0000/)) {
  $remdate = convert_date($remdate, $DATE_MDY);
  printRowWhiteCtr "<h3>Note: This program was removed on $remdate and is not being tracked</h3>";
}

print $cgi->start_form(
  -name   => "editform",
  -action => "/${STR_DO_EDIT}",
    ) . "\n";
print "<input type='hidden' name='Add' value='1'>\n"    if ($addprog);

print comment("Begin td for lefthand column");
print "<td valign='top'>\n";

print comment("Table for left column holds all but related programs");
print "<table class='new'  border=0>\n";

#----------------------------------------------------------------------
# Fully editable text fields.
#----------------------------------------------------------------------

# First four fields all editable.
foreach my $varname (qw(ident name summ descr adddate visdate rev rdate homeurl srcurl revurl revstr homestr counturl revtrust)) {
  my $val = ($prog->{$varname} or '');
  # Find an available ident if editing.
  $val = nextIdent($dbh) if ($varname eq 'ident');

  my ($identline, $buttline) = ('', '');
  if ($varname =~ /adddate/) {
    # DateTime->today->format_cldr("YYYY-MM-dd")
    # $val = timeNow()->{'M/D/Y'} if ($addprog and not has_len($val));
    $val = DateTime->today->format_cldr("M/D/Y") if ($addprog and not has_len($val));
  }
  if ($varname =~ /rdate|visdate|adddate/) {
    $val = convert_date($val, $DATE_MDY);
  }

  # Special field for changing the ID field, if editing.
  if (($varname eq 'ident') and not $addprog) {
    $identline = 
	$cgi->td({-width => 300}, $ident . "\n" .
		 $cgi->hidden(
           -name    => 'ident',
           -default => $ident,
             ) . "\n" .
		 "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;" .
		 $cgi->textfield(
           -name    => 'newident',
           -default => $ident,
           -size    => 10,
             )) . "\n";
  } else {
    # Not the ident field.
    if ($varname =~ /summ|descr/) {
      # Summary and Description have text areas
      $identline = $cgi->td({-width => 400},
			    $cgi->textarea(
                  -name     => $varname,
                  -class    => 'blue',
                  -default  => $val,
                  -rows     => 5,
                  -columns  => 50,
                            )) . "\n";
    } else {
      # Shorter fields get textfields.
      my $vurl = "&nbsp;&nbsp;&nbsp;";
      # Add a 'today' button for date fields.
      $identline = $cgi->td(
        {-width     => 400, 
         -alignment => 'left'},
        $cgi->textfield(
          -name      => $varname,
          -default   => $val,
          -maxlength => 100,
          -size      => 50,
        )) . "\n";
      if ($varname =~ /date$/) {
 	my $sstr = substr($varname, 0, 3);
 	$buttline = "<td><input type=button value='$sstr today' onClick=\"today(document.editform.$varname)\"></td>";
      }
      if ($varname =~ /url$/) {
	$val = "http://${val}" unless ($val =~ /^http/);
	$buttline = "<td><a target='new' href='$val'>visit $varname</a></td>" ;
      }
    }
  }

  print $cgi->Tr($cgi->th({-width=>150,-align=>'left'}, 
			  $varname) . 
		 $identline . $buttline) . "\n";
}

#----------------------------------------------------------------------
# Dropdown lists (author, screen cap file).
#----------------------------------------------------------------------

# Author field is dropdown list.
print $cgi->Tr($cgi->th({-align=>'left'}, 
			"Select an Author") .
	       $cgi->td({-width => 300},
			$cgi->popup_menu(
                          -name    => 'auth',
                          -values  => \@skeys,
                          -labels  => \%names,
                          -default => $prog->{'auth'},
                        ))) . "\n";

print comment("End of 1st table (holding freeform fields) in r0c0 ");
print "</table>\n";

#----------------------------------------------------------------------
# Checkboxes for combined limited options.
#----------------------------------------------------------------------

# New table for vertically-oriented check boxes.

print comment("Begin 2nd table (holding structured fields) in r0c0");

# Row 0: Short-answer numerical options.
my @scategs = (qw(installer obtain audience rank_activity rank_appear rank_doc rank_scope rank_overall));
# Row 1: Long-answer numerical options.
my @lcategs = (qw(plat interface category readfmt writfmt func lang feature prer));

foreach my $categ_type(\@scategs, \@lcategs) {
  my @categs = @$categ_type;
  print "<table class='new' border='1'>\n";

  # Row 0: Title.
  my @titles = ();
  foreach my $categ (@categs) {
    push(@titles, $radutils::db_program{$categ}->[0]);
  }
  print $cgi->Tr({-align => 'left'}, $cgi->th([@titles])). "\n";

  # Row 1: Content.
  print "<tr valign='top'>\n";
  foreach my $categ (@categs) {
    my $cname = $radutils::db_program{$categ}->[0];
    my $cval = $prog->{$categ};
    my $tdtxt = '';

    if ($categ =~ /^rank/) {
      # 'rank_' fields are radio groups.
      $tdtxt = $cgi->radio_group(
        -name      => $categ,
        -values    => [(1..5)],
        -default   => $cval,
        -linebreak => 'true',
          );
    } else {
      # All other fields are checkbox groups.
      my ($values, $default, $labels);
      if ($categ =~ /prer/) {
	($values, $default, $labels) = (\@prekeys, \@prereqs, \%prereqs);
      } else {
	my $hashname = ($categ =~ /fmt$/) ? "formats" : $categ;
 	my %hash = %{"radutils::cat_${hashname}"};
	my $hptr = \%hash;
	my @values = sortHashVal($hptr, 0);
	
	my $sref = selectedVals(
      {'hashname' => "radutils::cat_" . $hashname, 
       'sumval'   => $cval,
       'field'    => $categ,
      });
	my $sortkeys = $sref->{'sortkeys'};
	my $allvals = $sref->{'allvals'};
 	my $trunchash = truncateHashVals($allvals, 12);
	($values, $default, $labels) = (\@values, $sortkeys, $trunchash);
      }
      $tdtxt = $cgi->checkbox_group(
        -values    => $values,
        -default   => $default,
        -labels    => $labels,
        -linebreak => 'true',
        -name      => $categ,
          );
    }
    $tdtxt = formatInput($tdtxt);
    print $cgi->td({-valign => "top"}, $tdtxt);
  }
  print "</tr>\n";
  print "</table>\n";
}

# ------------------------------------------------------------
# 'Relationships' table.
# ------------------------------------------------------------

print comment("Begin 3rd table (for defining relationships) in r0c0");
print "<table width=500 class='new' border='0'>\n";

# First, list/edit all existing relationships for this program.
if (scalar(@relationships)) {
  print "<tr>\n";
  foreach my $aptr (@relationships) {
    my ($rptr, $r2ptr) = @{$aptr};
    my $relstr = $radutils::relationship{$rptr->{'type'}};
    print "<th>Relationship:</th>\n";
    print "<td>$relstr</td>\n";
    print "<td>$r2ptr->{'name'}</td>\n";
    print "<td>$rptr->{'date'}</td>\n";
  }
  print "</tr>\n";
}

# Now, allow definition of a new relationship.

print "<tr><td>&nbsp;</td></tr>\n";
print "<tr align='left'>\n";
print $cgi->th("New Relationship:") . "\n";
print $cgi->td($cgi->popup_menu(
                 -name    => 'new_rel_type',
                 -values  => \@relkeys,
                 -labels  => \%relat,
               )) . "\n";
my @proglist = ("", @allprogs);
print $cgi->td($cgi->popup_menu(
                 -name    => 'new_rel_prog2',
                 -values  => \@proglist,
                 -labels  => \%allprogs,
               )) . "\n";

print "</tr>\n";

print "<tr><td>&nbsp;</td></tr>\n";

# 'Submit' and 'Cancel' buttons.

if ($addprog) {
  print $cgi->Tr($cgi->td({-colspan => 2},
 			  $cgi->submit({-name =>'Add Program'}),
		 $cgi->td({-colspan => 2},
			  $cgi->reset())));
} else {
  print $cgi->Tr($cgi->td({-colspan => 2},
 			  $cgi->submit({-name =>'Edit Program'})),
		 $cgi->td({-colspan => 2},$cgi->reset()));
}


print comment("End table for defining relationships");
print "</table>\n";

print comment("End of left hand column of outer table");
print "</td>\n";

# ------------------------------------------------------------
# Right hand column holds checkboxes for related programs.
# ------------------------------------------------------------

# Right hand column (one td) holds 'related' checkboxes.
print comment("Right hand column in <td> holds related checkboxes");
print "<td width='200'>\n";
print comment("Table to hold related checkboxes");
print "<table class='new' border='0'>\n";

my @pkeys = ();
if (scalar(keys(%related))) {
  print $cgi->Tr($cgi->th("Related Programs")) . "\n";
  @pkeys = sort {"\U$related{$a}->{'name'}" cmp "\U$related{$b}->{'name'}"} keys %related;
  foreach my $pkey(@pkeys) {
    my $relprog = truncateString($related{$pkey}->{'name'}, 10);
    print $cgi->Tr($cgi->td($relprog)) . "\n";
  }
}
# Make a hash of allprogs with truncated names.
my %truncprogs = ();
foreach my $prog (sort keys %allprogs) {
  my $truncname = truncateString($allprogs{$prog}, 8);
  $truncprogs{$prog} = $truncname;
}

my $relatedstr = $cgi->checkbox_group(
  -name	 => 'related',
  -values	 => \@allprogs,
  -labels	 => \%truncprogs,
#  -labels	 => \%allprogs,
  -default   => \@pkeys,
  -linebreak => 'true',
    );
$relatedstr = ($cgi->td(formatInput($relatedstr)));
print "<tr valign='top'>\n$relatedstr</tr>\n";

print comment("End of table to hold related checkboxes");
print "</tr>\n</table>\n";
print comment("End of right hand column");
print "</td>\n";

print comment("End of outer table");
print "</tr>\n";
print "</table>\n";

print $cgi->end_form() . "\n";

# print "</td></tr>\n";

sub formatInput {
  my ($instr) = @_;
  $instr =~ s/<input/\n<input/g;
  return("$instr\n");
}
