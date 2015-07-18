#! /usr/bin/env perl
use warnings;

# Run cgi programs and store their output in 'static' directory to be read by Content::print_static_file_for()

use strict;
no strict 'refs';

use CGI;
use CGI::Carp;
use DBI;
use FindBin qw($Bin);
use lib $Bin;
use Utility;
use radutils;
use FileUtilities;

my @cgi_progs = qw(finder newreleases quicklinks mostWatched mostLinked mostRanked);
foreach my $progname (@cgi_progs) {
  my $fullprog = "~/idoimaging/cgi-bin/${progname}.pl";
  my $outfile = "${Bin}/../public_html/static/${progname}.html";
  print "$fullprog $outfile\n";
  my $outlines = `$fullprog -n`;
  writeFile($outfile, $outlines);
}
