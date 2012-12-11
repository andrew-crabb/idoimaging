#! /usr/local/bin/perl -w

use CGI;
use CGI::Carp 'fatalsToBrowser';

my $cstr = $cgi->cookie(-name  => "versionarchive",
			-value => 1);

my $cgi = new CGI;
print $cgi->header(-cookie=>$cstr);
