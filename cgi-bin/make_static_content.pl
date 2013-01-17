#! /usr/local/bin/perl -w

# Run cgi programs and store their output in 'static' directory to be read by Content::print_static_file_for()

use strict;
no strict 'refs';

use CGI;
use CGI::Carp;
use DBI;
use FindBin qw($Bin);
use lib $Bin;
use radutils;

my @cgi_progs = qw(finder newreleases quicklinks mostWatched mostLinked mostRanked);
foreach my $progname (@cgi_progs) {
  my $fullprog = "~/idoimaging/cgi-bin/${progname}.pl";
  my $outfile = "/Users/ahc/idoimaging/public_html/static/${progname}.html";
print "$fullprog $outfile\n";
  my $outlines = `$fullprog -n`;
  fileWrite($outfile, $outlines);
}
