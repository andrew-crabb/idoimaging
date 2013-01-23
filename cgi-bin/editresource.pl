#! /usr/local/bin/perl -w

use strict;
use CGI;
use CGI::Carp qw(fatalsToBrowser warningsToBrowser);
use DBI;
use FindBin qw($Bin);
use lib $Bin;
use Utility;
use radutils;
use Userbase;

$| = 1;
my $cgi = new CGI;
print $cgi->header();


my $dbh = hostConnect('');
my $title = "I Do Imaging - Edit Resource";

# If adding program, ensure logged-in user is admin.
my $det = get_user_details();
unless ($det and $det->{$Userbase::UB_IS_ADMIN}) {
  print "<tt>Edit a program?  I don't think so.</tt><br>\n";
  exit;
}

print "<br>\n";
dumpParams($cgi);
my ($ident, $doAdd, $doDelete) = getParams($cgi, (qw(ident add delete)));

if (has_len($ident)) {
  if (has_len($doAdd)) {
    # Given ident and add: from CGI params, add new or edit existing record.
    doEditAdd($ident);
  } elsif(has_len($doDelete) and $doDelete) {
    my $str = "delete from resource where ident = '$ident'";
    printRowWhite($str);
    dbQuery($dbh, $str);
  } else {
    # Ident given, not add: edit this existing record.
    editAddForm($ident);
  }
} else {
  if (has_len($doAdd)) {
    # Adding, no ident given: fill in blank form, call self with add and ident.
    editAddForm();
  } else {
    # Editing, no ident: display list, each elem has ident but not add.
    showList();
  }
}
exit;

# Display edit/add form.  If ident set, it's an edit, else it's an add.

sub editAddForm {
  my ($ident) = @_;
  
  print $cgi->start_form(
    -action => "/${STR_DO_EDIT_RES}",
  ) . "\n";
  print "<table>\n";

  my $href = '';
  if (has_len($ident)) {
    # Given a particular ident: we're editing a resource.
    my $str = "select * from resource where ident = '$ident'";

    my $sh = dbQuery($dbh, $str);
    $href = $sh->fetchrow_hashref();
  }

  # Now display a table for one resource.  Fill in default vals if applicable.
  my @fields = (qw(ident format program type url date reviewer summ descr urlstat));
  foreach my $field (@fields) {
    my $val = (has_len($href)) ? $href->{$field} : "";
    $val = ($val or "");
    # Create the next free ID unless we have one.
    if (($field eq "ident") and (not has_len($ident))) {
      $val = nextIdent($dbh, "resource");
      # Need to have hiddent 'ident' set later on.
      $ident = $val;
    }
    if ($field =~ /url/) {
      $val =~ s{http://}{};
      $val =~ s/\/$//;
    }
    # entrydata is selector for selection-type fields, else freeform text.
    my $entrydata;
    if ($field =~ /type/) {
      $entrydata = make_type_select($val);
    } elsif ($field =~ /format/) {
      $entrydata = make_format_select($val);
    } elsif ($field =~ /program/) {
      $entrydata = make_prog_select($val);
    } else {
      $entrydata = $cgi->textfield(-name => "re_${field}",
				   -default => $val);
    }
    my @cont = ($cgi->th({-align=>'left'}, $field), $cgi->td($entrydata));
    print $cgi->Tr(@cont) . "\n";
  }
   print $cgi->hidden(-name => 'ident', -value => "$ident") . "\n";
   print $cgi->hidden(-name => 'add', -value => '1') . "\n";
  print "</table>\n";
  print $cgi->submit() . "\n";
  print $cgi->endform(-name => 'Add Resource') . "\n";
}

sub make_type_select {
  my ($val) = @_;

  my %res = %radutils::resourcetype;
  $res{''} = "- Select -";
  my @rkeys = sort {$res{$a} cmp $res{$b}} keys %res;
  my $type_select;
  if (has_len($val)) {
    $type_select = $cgi->popup_menu(-name => 're_type',
				    -values => \@rkeys,
				    -default => $val,
				    -labels => \%res) . "\n";
  } else {
    $type_select = $cgi->popup_menu(-name => 're_type',
				    -values => \@rkeys,
				    -labels => \%res) . "\n";
  }
  return $type_select;
}

sub make_format_select {
  my ($val) = @_;

  my %fmt = %radutils::cat_formats;
  $fmt{''} = ["- Select -"];
  my @fkeys = sort {$fmt{$a}->[0] cmp $fmt{$b}->[0]} keys %fmt;
  my %vals = ();
  foreach my $fkey (@fkeys) {
    $vals{$fkey} = $fmt{$fkey}->[0];
  }
  my $format_select;
  if (has_len($val)) {
    $format_select = $cgi->popup_menu(-name => 're_format',
				      -values => \@fkeys,
				      -default => $val,
				      -labels => \%vals) . "\n";
  } else {
    $format_select = $cgi->popup_menu(-name => 're_format',
				      -values => \@fkeys,
				      -labels => \%vals) . "\n";
  }
  return $format_select;
}

sub make_prog_select {
  my ($ident) = @_;

  my $str = "select ident, name from program where ident >= 100 order by name";
  my $sh = dbQuery($dbh, $str);
  my $ref = $sh->fetchall_arrayref;
  my @allprogs = @$ref;
  my %progs;
  foreach my $prog (@allprogs) {
    my ($pident, $pname) = @$prog;
    $progs{$pident} = $pname;
  }
  $progs{''} = "- Select -";
  my @pkeys = sort {$progs{$a} cmp $progs{$b}} keys %progs;
  my $prog_select;
  if (has_len($ident)) {
    $prog_select = $cgi->popup_menu(-name => 're_program',
				    -values => \@pkeys,
				    -default => $ident,
				    -labels => \%progs) . "\n";
  } else {
    $prog_select = $cgi->popup_menu(-name => 're_program',
				    -values => \@pkeys,
				    -labels => \%progs) . "\n";
  }
  return $prog_select;
}

sub doEditAdd {
  my ($ident) = @_;

  my $str = "select * from resource where ident = $ident";
  my $sh = dbQuery($dbh, $str);
  tt($str);
  my $ref = $sh->fetchrow_hashref;
  my $doEdit = (ref($ref)) ? 1 : 0;
#   tt("doEdit = $doEdit, ref = $ref\n");
  printHashAsTable($ref) if (ref($ref));
  my ($updatestr, $comma) = ("", "");
  my @fields = qw(ident format program type url date reviewer summ descr urlstat);
  foreach my $field (@fields) {
    my $newval = $cgi->param("re_${field}");
    $newval = '' unless (has_len($newval));

    if ($field =~ /date/) {
      $newval = convert_date($newval, $DATE_SQL);
    }

    if (has_len($newval)) {
      unless ($doEdit and $newval eq $ref->{$field}) {
	# Include this string only if it's different.
	$updatestr .= "$comma $field = '$newval'";
	$comma = ",";
      }
    }
  }
  if (length($updatestr)) {
    if ($doEdit) {
      $updatestr = "update resource set $updatestr where ident = '$ident'";
    } else {
      $updatestr = "insert into resource set $updatestr";
    }
    tt($updatestr);
    $dbh->do($updatestr);
  }
}

sub showList {
  my $str = "select ident, format, program, summ, type, url, urlstat from resource order by format, type";
  my $sh = dbQuery($dbh, $str);
  my $ref = $sh->fetchall_arrayref();
  my @resources = @$ref;
  print "<table cellspacing=0 cellpadding=2 border=1>\n";
  foreach my $resource (@resources) {
    my ($ident, $format, $program, $summ, $type, $url, $urlstat) = @$resource;
    my ($object, $class, $text) = ('', '', '');
    if (has_len($format) and ($format != 0)) {
      $object = $radutils::cat_formats{$format}->[0];
      $class = "Y";
      $text = "Format";
    } elsif (has_len($program) and ($program != 0)) {
      $str = "select name from program where ident = '$program'";
      $sh = dbQuery($dbh, $str);
      my ($pname) = $sh->fetchrow_array();
      $object = $pname;
      $class = "C";
      $text = "Program";
    } elsif ($type == 5) {
      $class = "R";
      $text = "Link";
    }
    $urlstat = $urlstat ? "Up" : "Down";
    my $urlstr = "<a target='new' href='http://$url'>$urlstat</a>";
    my $edit_url = "<a href='/${STR_EDIT_RESOURCE}?ident=$ident'>Edit</a>";
    my $del_url = "<a href='/${STR_EDIT_RESOURCE}?ident=$ident&delete=1'>Delete</a>";
    $summ = substr($summ, 0, 30) . "..." if (length($summ) > 30);
    $type = $radutils::resourcetype{$type};
    print $cgi->Tr($cgi->td({-class => $class}, $text),
		   $cgi->td([$type, $object, $summ, $urlstr, $edit_url, $del_url])) . "\n";
  }
  print "</table>\n";
}
