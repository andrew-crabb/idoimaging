#! /usr/local/bin/perl

##  printenv -- demo CGI program which just prints its environment

my @keys = sort(keys(%ENV));
my $http = scalar(grep(/HTTP/, @keys)) ? 1 : 0;

if ($http) {
  print "Content-type: text/html\n\n";
  print "<html>\n<body>\n";
  print "<table cellpadding=2 cellspacing=0 border=0>\n";
  foreach $var (@keys) {
    $val = $ENV{$var};
    $val =~ s|\n|\\n|g;
    $val =~ s|"|\\"|g;
    print "<tr><td>$var</td><td>$val</td></tr>\n";
  }
  print "</table>\n";
} else {
  my $maxlen = 0;
  foreach my $key (@keys) {
    $maxlen = length($key) if (length($key) > $maxlen);
  }
  print "maxlen: $maxlen\n";
  my $fmtstr = "\%-${maxlen}s: \%s\n";
  foreach my $key (@keys) {
    my $val = $ENV{$key};
    printf($fmtstr, $key, $val );
  }
#   print "fmtstr: >${fmtstr}<\n";
}

# print "ps:<br>\n";
# my @ps = `ps -aux | grep pl`;
# #  my @ps = `mysqladmin version`;
# print join("<br>\n", @ps);
# print "<br>\n";
