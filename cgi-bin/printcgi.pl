#!/usr/local/bin/perl

use CGI;

$cgi = new CGI;
my @params = $cgi->param();
my $nparams = scalar(@params);

print $cgi->header;
print $cgi->start_html("Simple CGI.pm Program");
print "<H1>Simple CGI.pm Program</H1>\n";
print "<HR >";
print "Here is a list of the $nparams values you passed: ";
print $cgi->Dump;
print "\n";

exit (0);
