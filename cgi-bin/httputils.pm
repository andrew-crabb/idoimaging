#! /usr/local/bin/perl -w

# use LWP::Simple;
# use LWP::UserAgent;
use WWW::Mechanize;

package httputils;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(checkLinkStatus getURL);

sub checkLinkStatus {
  my ($href, $urlfld) = @_;
  my %hash = %$href;
  my ($ident, $name, $url) = @hash{('ident', 'name', $urlfld)};
  my $homestr = $hash{'homestr'};
  $url = "http://$url" unless ($url =~ /^http|^ftp/);

  my $mech = WWW::Mechanize->new('autocheck' => 0);
  my $response = $mech->get($url);

  my $status = 0;
  if ($response->is_success()) {
    # Page is present but test depends on whether homestr is defined.
    if (defined($homestr) and length($homestr)) {
      # homestr field is defined, test for it in page contents.
      my $content = $mech->content();
#       my $content = $response->content;
      if ($content =~ /$homestr/) {
	$status = 1;
# 	print("status = 1: '$homestr' contained in $url\n");
      } else {
 	print("\nstatus = 0: '$homestr' not contained in $url\n");
      }
    } else {
#       print("status = 1: no homestr defined for $url\n");      
      $status = 1;
    }
  } else {
    print("\nstatus = 0: No response to $name ($ident, $url)\n");
  }
  return $status;
}

sub getURL {
  my ($url) = @_;

  my $contents = "";
  my $ua = LWP::UserAgent->new(
    env_proxy => 1,
    keep_alive => 1,
    timeout => 10,
      );
  my $resp = $ua->get($url);
  $contents = $resp->content if ($resp->is_success());
  return($contents) ;
}

1;
