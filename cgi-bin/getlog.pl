#! /usr/local/bin/perl -w

use Compress::Zlib;
use Net::Nslookup;
use Socket;
use Mail::Mailer qw(mail);
use Getopt::Std;
use FindBin qw($Bin);
use lib $Bin;
use radutils;
use Utilities_new;

my %opts;
getopts('th', \%opts);

my $help  = (defined($opts{'h'})) ? 1 : 0;
my $today = (defined($opts{'t'})) ? 1 : 0;

if ($help) {
  print "Usage: getlog [-t]\n";
  print "       -t: Today's log (default is yesterday's)\n";
  exit;
}

my @months = (qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec));
my @days = (qw(Sun Mon Tue Wed Thu Fri Sat));
local ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time());

# Calcualte yesterday's date for grepping through log file.
unless ($today) {
  my $yesterday = time() - (24 * 60 * 60);
  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($yesterday);
}
$mon += 1;
$year += 1900;
my $date = "${mon}-${mday}-${year}";
my $outfile = sprintf("/home/ahc/data/database/log%4d-%02d-%02d", ${year}, ${mon}, ${mday});

my $month = $months[$mon - 1];
my $ydate = "${mday}/$month";
my $dow = $days[$wday];

use LWP::UserAgent;
# my $ua = LWP::UserAgent->new;
my $ua = LWP::UserAgent->new(env_proxy => 1,
			     keep_alive => 1,
			     timeout => 10,
			     );
$ua->credentials('www.idoimaging.com:2082',
		 'Cpanel 6.0',
		 'acrabb' => 'new2this'
		 );

my $url = "http://www.idoimaging.com:2082/getaccesslog/accesslog-idoimaging.com-${date}.gz";
print "Getting >$url<\n";

my $response = $ua->get($url);

# my $request = HTTP::Request->new('GET', $url);
# my $response = $ua->request($request);

# die "Error: ", $response->header('Cpanel 6.0') || 
#     'Error accessing',
#     "\n ", $response->status_line, "\n at $url\n Aborting"
#     unless $response->is_success;

my %ips;
if (defined($response)) {
  my $buff = $response->content;
  print length($buff) . " bytes retrieved: $buff\n";
  my $unzip = Compress::Zlib::memGunzip($buff);
  foreach my $line (split(/\n/, $unzip)) {
    my ($ip, @rest) = split(/\s+/, $line);
    next unless ($rest[2] =~ /$ydate/);
#     print "date field $rest[2]\n";
    $ips{$ip} = 1 unless (defined($ips{$ip}));
  }
  open(OUT, ">${outfile}") or die;
  print OUT $unzip;
  close(OUT);
} else {
  print "No response\n";
  die "Not a success\n" unless ($response->is_success);
}

my (@reshosts, @unreshosts);
my $bots = 0;
foreach my $ip (sort keys %ips) {
  my $ip_struct = inet_aton($ip);
  $host = gethostbyaddr($ip_struct, AF_INET);
  if (defined($host)) {
    if ($host =~ /googlebot|crawl|sv\.av\.com|proxy\.aol\.com/) {
      $bots++;
    } else {
      push(@reshosts, $host);
    }
  } else {
    push(@unreshosts, $ip);
  }
}

my $nres = scalar(@reshosts);
my $nunres = scalar(@unreshosts);
my $numip = $nres + $nunres;

if ($today) {
  print "Summary for $dow $ydate\n\n";
  print "$numip unique IPs; $nres resolved, $bots bots\n\n";
  print join("\n", sort(@reshosts)) . "\n\n";
  print join("\n", sort(@unreshosts)) . "\n";
} else {
  %headers = ( 'To'      => "ahc\@jhu.edu",
	       'From'    => "ahc\@jhu.edu",
	       'Subject' => "idoimaging summary for $dow $ydate" );
  $mailprog = Mail::Mailer->new();
  $mailprog->open(\%headers);
  
  print $mailprog "Summary for $dow $ydate\n\n";
  print $mailprog "$numip unique IPs; $nres resolved, $bots bots\n\n";
  print $mailprog join("\n", sort(@reshosts)) . "\n\n";
  print $mailprog join("\n", sort(@unreshosts)) . "\n";
  $mailprog->close();
}
