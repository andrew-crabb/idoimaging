#! /opt/local/bin/perl -w

# Current approach 1/29/11
# Enter the topmost date string under 'Modified' on the files/ url.
# This string is found as the content of the td with headers="files_date_h"

# Note: without Javascript, you get a different page.  Makes it tricky.
# The string in "Looking for the latest version is in 
# the title of the first <a> after the <div> with class downloadbar.
# Problem is that the non-javascript version of the page often has this info outdated.

# Note: For sourceforge, enter the package name under 'Newest Files'.
# I search for class = 'latest' as this is the tr containing the latest files.

use strict;

package MyParser;
use base qw(HTML::Parser);

# my $is_class_latest = 0;
our $revstr = '';
our $revstr_found = 0;
our $tbody_found = 0;
our $done = 0;

# Yet another version 1/2011.  Search for 'Looking for the latest version' string
# It's in <div class="download-bar">
sub start {
  my ($self, $tagname, $attr, $attrseq, $origtext) = @_;

  if ($tagname eq 'div') {
    if (defined(my $class = $attr->{'class'})) {
      if ($class eq 'download-bar') {
        main::printHash($attr, "attr");
      }
    }
  }
}

# Currently (12/10), the first <tr> after <tbody> holds the rev number in its <title>
sub start_not {
  my ($self, $tagname, $attr, $attrseq, $origtext) = @_;
    
  return if ($done);
  if ($tagname eq 'tbody') {
    $tbody_found = 1;
  } elsif ($tbody_found and ($tagname eq 'tr')) {
    if (defined(my $title = $attr->{title})) {
      if ($revstr_found = ($title =~ /$revstr/)) {
         print "*** title: $title does     contain revstr: $revstr\n";
      } else {
         print "*** title: $title does not contain revstr: $revstr\n";
      }
      $done = 1;
    }
  }
}

package main;

use WWW::Mechanize;
use DBI;
use FindBin qw($Bin);
use lib $Bin;
use radutils;
use Getopt::Std;

my $toaddr = "ahc\@andy.rad.jhmi.edu";
my $fromaddr = "ahc\@jhu.edu";
my $sourceforgestring = 'class="folder level2 open (hidden|)">\s+<td class="tree"><a href="#" class="icon folder">';

# Mech was killing program on 404 with autocheck on.
my $mech = WWW::Mechanize->new('autocheck' => 0);
my $timeout = $mech->timeout();
print "timeout $timeout\n";
$mech->timeout(5);
 $timeout = $mech->timeout();
print "timeout $timeout\n";


$| = 1;
my %opts;
getopts('hvr', \%opts);
my $dorem   = ($opts{'r'}) ? 1 : 0;
my $verbose = ($opts{'v'}) ? 1 : 0;
if ($opts{'h'}) {
  print "Usage: checklinkupdate [-mvr]\n";
  exit;
}


my $dbh = hostConnect("imaging");
my $notstr = ($dorem) ? " not " : "";
my $query = "select ident, name, revurl, revstr from program";
$query .= " where ident >= 100";
$query .= " and name like '\%$ARGV[0]\%'" if (scalar(@ARGV));
$query .= " and revurl is not null";
$query .= " and remdate $notstr like '0000%'";
# $query .= " order by visdate";

my $sh = dbQuery($dbh, $query);

my ($total, $same, $changed) = (0, 0, 0);
while (my ($ident, $name, $revurl, $revstr) = $sh->fetchrow_array()) {
  $total++;

#   print "$name\n";
  next unless (length($revurl));
  # This also allows URLs to be stored as https://
  $revurl = "http://${revurl}" unless ($revurl =~ /^http/);
#   $revurl .= "/files" if (($revurl =~ /sourceforge/) and ($revurl !~ /\/files/));
  my $response = $mech->get($revurl);
  unless ($response->is_success()) {
    my $msg = $response->{'_msg'};
    printMessage($name, "Can't find page ($msg)", $revurl);
    next;
  }
  my $contents = $mech->content();
  my $len = length($contents);
#   print $contents;
  # SourceForge is special.
  my $string_found = 0;
  if ($revurl =~ /sourceforge/) {
#  if (0) {
    $string_found = stringFoundSF($revstr, $contents);
  } else {
    # Escape special characters in revstr.
    $revstr =~ s/\ /\\s+/g;
    $contents =~ s/\&nbsp\;//g;
    $string_found = ($contents =~ /$revstr/) ? 1 : 0;
  }
  if ($string_found) {
    print ".";
    $same++;
  } else {
    printMessage($name, "Can't find string >$revstr< in $len byte $name", $revurl);
    $changed++;
  }
}
print "\nThere were $total total: $same same and $changed changed\n";

sub printMessage {
  my ($name, $str, $url) = @_;
  
  $url =~ s{http://}{};
  $name = substr($name, 0, 16);
  my $outstr = "\n";
  $outstr .= sprintf("Program: %s\n", $name);
  $outstr .= sprintf("URL:     %s\n", $url);
  $outstr .= sprintf("Reason:  %s\n", $str);
  print "$outstr";
}

sub stringFoundSF {
  my ($revstr, $contents) = @_;
  my $ret = 0;

  my @contents = split(/\n/, $contents);
#   print scalar(@contents) . " lines in results\n";
  my ($files_date_h_line) = grep(/headers="files_date_h"/, @contents);
#    print "revstr $revstr, files_date_h_line $files_date_h_line\n";
  if ($files_date_h_line =~ /.+>([^\<]+)<.+/) {
#     print "Date string = $1\n";
    if ($1 =~ /$revstr/) {
      $ret = 1;
    }
  }
#   print "stringFoundSF($revstr) returning $ret\n";
  return $ret;
}

sub stringFoundSF_not {
  my ($revstr, $contents) = @_;

  # Two types of SourceForge search, depending on where the project's versions are stored.
  # revstr is version number from <title> of first <tr> after <tbody>
  # 1: Each rev in its own subdir:
  #    - revurl ends in '/files'
  # 2: All revs in one subdir:
  #    - revurl ends in '/files/progname'

  my $parser = MyParser->new;
  $MyParser::done = 0;
  $MyParser::revstr = $revstr;
  $parser->parse($contents);
  my $revstr_found = ($MyParser::revstr_found) ? 1 : 0;

#   print "stringFoundSF($revstr) returning $revstr_found\n";
  return $revstr_found;
}
