#! /usr/local/bin/perl -w

# Apply the same attributes to a number of programs.

use CGI;
use CGI::Carp qw(fatalsToBrowser warningsToBrowser);
use DBI;
use FindBin qw($Bin);
use lib $Bin;
use Utility;
use radutils;
use bigint;
use strict;
no strict 'refs';

my $cgi = new CGI;

# Redirect unless this has come from me, not a search engine.
my $referer = $cgi->referer();
my $doredirect = 1;
if (has_len($referer)) {
    $doredirect = 0 if (substr($referer, 0, 25) =~ /idoimaging|andy|localhost|127.0.0.1/);
}

print $cgi->header();
# warningsToBrowser(1);

my ($step0, $step1, $step2) = getParams($cgi, (qw(step0 step1 step2)));
$step0 = 1 unless(has_len($step0) or has_len($step1) or has_len($step2));

my $dbh = hostConnect('');
my $title = "Edit Attributes";
$title .= "\n<br />Note: Local Database" if ($localdb);

printStartHTML($cgi, $title);
printTitle($cgi, 1);

dumpParams($cgi);
my @params = $cgi->param();
my @opt_params = grep(/opt_/, @params);

# ------------------------------------------------------------
#                     Prepare data.
# ------------------------------------------------------------

my $numcols = 4;
my %hiddens = ();
my %programs = ();
my %prog_names_by_ident = ();
my @prog_idents_by_name = ();
if (has_len($step1) or has_len($step2)) {
  my $str = "select * from program";
  $str   .= " where ident >= 100";
  $str   .= " and remdate like '0000%'";
  my $sh = dbQuery($dbh, $str);
  while (my $href = $sh->fetchrow_hashref()) {
    $programs{$href->{'ident'}} = $href;
    $prog_names_by_ident{$href->{'ident'}} = $href->{'name'};
  }
  @prog_idents_by_name = sort {lc($programs{$a}->{'name'}) cmp lc($programs{$b}->{'name'})} keys %programs;
}

# ------------------------------------------------------------
#                     Print page.
# ------------------------------------------------------------

printRowWhiteCtr($cgi->h1($title));
print $cgi->startform() . "\n";

print comment("Begin tr for table");
print "<tr>\n";

print comment("Begin td for table");
print "<td valign='top'>\n";

print comment("Table for editing fields");
print "<table border='1' cellspacing='0' class='new'  border=0>\n";

if (has_len($step0)) {
  # First time round, choose params to set.
  # Row 0: Title.
  my @titles = ();
  my @lcategs = (qw(plat interface category readfmt writfmt func lang feature));
  foreach my $categ (@lcategs) {
    push(@titles, $radutils::db_program{$categ}->[0]);
  }
  print $cgi->Tr({-align => 'left'}, $cgi->th([@titles])). "\n";

  # Setting params: Choose which params to set for selected programs.
  print "<tr>\n";
  foreach my $categ (@lcategs) {
    my $cname = $radutils::db_program{$categ}->[0];
    
    # All other fields are checkbox groups.
    my ($values, $default, $labels);
    my $hashname = ($categ =~ /fmt$/) ? "formats" : $categ;
    my %hash = %{"radutils::cat_${hashname}"};
    my $hptr = \%hash;
    my @values = sortHashVal($hptr, 0);
    
    my $sref = selectedVals({
      'hashname' => "radutils::cat_" . $hashname, 
      'sumval'   => 0,
#      'field'    => $categ,
                            });
    my $sortkeys = $sref->{'sortkeys'};
    my $allvals = $sref->{'allvals'};
    my $trunchash = truncateHashVals($allvals, 12);
    
    my $tdtxt = $cgi->checkbox_group(
      -values    => \@values,
      -default   => $sortkeys,
      -labels    => $trunchash,
      -linebreak => 'true',
      -name      => "opt_${categ}",
        );
    $tdtxt = formatInput($tdtxt);
    print $cgi->td({-valign => "top"}, $tdtxt);
  }
  print "</tr>\n";

  %hiddens = (
    'step1'   => 1,
    'localdb' => $localdb,
      );

} elsif (has_len($step1)) {
  my $ncols = $numcols - 1;
  %hiddens = (
    'step2'   => 1,
    'localdb' => "$localdb",
      );
  # List the incoming params that will be applied to selected programs.
  foreach my $opt_param (@opt_params) {
    my @vals_this_categ = $cgi->param($opt_param);
    $hiddens{$opt_param} = @vals_this_categ;
#     tt("hiddens{$opt_param} = @vals_this_categ");
    (my $categ = $opt_param) =~ s/opt_//;
    $categ = "formats" if ($categ =~ /fmt/);
    my @names_this_categ = ();
    foreach my $val_this_categ (@vals_this_categ) {
      my %cat_hash = %{"radutils::cat_$categ"};
      push(@names_this_categ, $cat_hash{$val_this_categ}->[0]);
    }
#     tt("vals_this_categ ($categ) = @vals_this_categ, names_this_categ @names_this_categ");
    my $namestr = join(" ", @names_this_categ);
    print "<tr>\n";
    print "<th>\u$categ</td>\n";
    print "<th colspan=$ncols>$namestr</td>\n";
    print "</tr>\n";
  }
  

  # Second time round, choose the programs to apply the params to.
  print "<tr>\n";
  my $nprog = scalar(@prog_idents_by_name);
  my $npercol = $nprog / $numcols;
  # tt("$nprog programs, $npercol per column");

  foreach my $i (0..($numcols - 1)) {
    my $startindx = $i * $npercol;
    my $endindx = $startindx + $npercol - 1;
    $endindx = ($nprog - 1) if ($endindx >= $nprog);
    my @prog_idents_this_col = @prog_idents_by_name[${startindx}..${endindx}];
    my $npercol = scalar(@prog_idents_this_col);
    # tt("col $i: start $startindx end $endindx, npercol $npercol: @prog_idents_this_col");
    
    my $tdtxt = $cgi->checkbox_group(
      -values    => \@prog_idents_this_col,
      -default   => 0,
      -labels    => \%prog_names_by_ident,
      -linebreak => 'true',
      -name      => 'programs',
        );
    print "<td>\n$tdtxt\n</td>\n";
  }
  print "</tr>\n";
} elsif (has_len($step2)) {
  my @progs_to_do = $cgi->param('programs');
  foreach my $prog (@progs_to_do) {
    my $program = $programs{$prog};
    foreach my $opt_param (@opt_params) {
      (my $categ = $opt_param) =~ s/opt_//;
      my $prog_categ_val = $program->{$categ};
      my @vals_this_categ = $cgi->param($opt_param);
      my $totval = 0;
      foreach my $val (@vals_this_categ) {
        $totval += $val;
      }
      my $newval = $prog_categ_val | $totval;
      my $hashname = ($categ =~ /fmt/) ? "formats" : $categ;
      my %cat_hash = %{"radutils::cat_$categ"};
      my @oldvals = listHashMembers(\%cat_hash, $prog_categ_val);
      my @changes = listHashMembers(\%cat_hash, $totval);
      my @newvals = listHashMembers(\%cat_hash, $newval);
      tt("prog $prog field $opt_param oldval $prog_categ_val (@oldvals) changes $totval (@changes) newval (@newvals) $newval vals @vals_this_categ");
      my $sqlstr = "update program";
      $sqlstr   .= " set $categ = $newval";
      $sqlstr   .= " where ident = '$prog'";
      tt($sqlstr);
      dbQuery($dbh, $sqlstr, 1);
    }
  }
}

print "<tr><td colspan='$numcols'>" . $cgi->submit() . "</td></tr>\n";
print "</table>\n";
printHiddens($cgi, \%hiddens);
print $cgi->endform() . "\n";

print comment("End of td for content");
print "</td>\n";
print comment("End of tr for content");
print "</tr>\n";

sub formatInput {
  my ($instr) = @_;
  $instr =~ s/<input/\n<input/g;
  return("$instr\n");
}

sub printHiddens {
  my ($cgi, $hptr) = @_;
  my %hash = %$hptr;

  foreach my $key (sort keys %hash) {
    my $val = $hash{$key};
    tt("printHiddens($key = $val)");
    print $cgi->hidden (
      -name    => "$key",
      -default => [$val],
        ) . "\n";
  }
}  
