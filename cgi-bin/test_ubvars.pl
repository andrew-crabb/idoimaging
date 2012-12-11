#! /opt/local/bin/perl -w

use CGI;
use CGI::Cookie;
use Utilities_new;

my $cgi = CGI->new();

$| = 1;
print $cgi->header();
print $cgi->start_html('test_ubvars');
print "<pre>\n";

my %cookies = CGI::Cookie->fetch;
my $site_session = defined($cookies{'site_session'}) ? $cookies{'site_session'}->value : '';
unless (hasLen($site_session)) {
  print "You my friend are not logged in.\n";
  exit;
}

# foreach my $envkey(keys %ENV) {
#   print "$envkey: $ENV{$envkey}<br />\n";
# }

my %env_orig = %ENV;
my $DOCUMENT_ROOT = $ENV{'DOCUMENT_ROOT'};
my $DOCROOT = $ENV{'DOCUMENT_ROOT'} . "/idoimaging";
print "docroot $DOCROOT <br />\n";

my $cgi_script_full  = "$DOCUMENT_ROOT/cgi-bin/imaging/userbase/userbase.cgi";
my $cgi_script_local = "/cgi-bin/imaging/userbase/userbase.cgi";

my $qs_set = 0;
foreach my $header(keys %ENV) {
  my $value = $ENV{$header};
#   my $hlen = length($header);
#   my $vlen = length($value);
#   print "($hlen)${header} = ($vlen)${value}\n";
  if ($header eq "SCRIPT_NAME" or $header eq "SCRIPT_URL") {
    $ENV{$header} = $cgi_script_local;
    print "0: ENV{$header} = $cgi_script_local;\n";
  } elsif ($header eq "SCRIPT_FILENAME") {
    $ENV{$header} = $cgi_script_full;
    print "1: ENV{$header} = $cgi_script_full;\n";
  } elsif ($header eq "SCRIPT_URI") {
    my $script_url = $ENV{'SCRIPT_URL'};
    $value =~ s/$script_url/$cgi_script_local/;
    $ENV{$header} = $value;
    print "2: ENV{$header} = $value;\n";
  } elsif ($header eq "QUERY_STRING") {
    $ENV{$header} = "action=chklogin&code=$site_session";
    print "3: ENV{$header} = \"action=chklogin&code=$site_session\";\n";
    $qs_set = 1;
  } else {
    $ENV{$header} = $value;
    print "4: ENV{$header} = $value;\n";
  }
}

if (!$qs_set) {
  my $envheader = "QUERY_STRING=action=chklogin&code=$site_session";
  $ENV{$header} = $envheader;
  print "ENV{$header} = $envheader;\n";
}

print "cgi_script_full: $cgi_script_full\n";

my @out = `$cgi_script_full`;
print scalar(@out) . " lines in the result:\n";
print "@out\n";

# print "Looking for changes in ENV\n";
foreach my $key (sort keys %env_orig) {
  my $origval = $env_orig{$key};
  my $newval = $ENV{$key};
#   my $note = ($origval eq $newval) ? "    " : "Diff";
#   printf("%s %-20s %-40s %-40s\n", $note, $key, $origval, $newval);
  if ($origval ne $newval) {
    $ENV{$key} = $origval;
    print "Reset: ENV{$key} = $origval\n";
  }
}

my ($ub_line) = grep(/::::/, @out);
print "$ub_line\n";
my $ub_bits = process_userbase_output($ub_line);
printHash($ub_bits);

print "</pre>\n";

sub process_userbase_output {
  my ($ub_line) = @_;

  my @ub_bits = split(/:::::/, $ub_line);
  my %ub_bits = ();
  foreach my $ub_bit (@ub_bits) {
    my ($ub_key, $ub_val) = split(/=/, $ub_bit);
    if (hasLen($ub_key) and hasLen($ub_val)) {
      $ub_bits{$ub_key} = $ub_val;
    }
  }
  return \%ub_bits;
}
