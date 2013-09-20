#! /usr/bin/perl -w

package Userbase;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(get_user_details);
@EXPORT = (@EXPORT, qw($VAR_NAME));

use strict;
no strict 'refs';

use CGI::Cookie;
use LWP::Simple;

# Constants.
our $UB_IS_ADMIN          = 'ub_is_admin';
our $UB_IS_MEMBER         = 'ub_is_member';
our $UB_USERNAME          = 'ub_username';
our $UB_USERID            = 'ub_userid';
our $UB_GROUP_MEMBERSHIPS = 'ub_group_memberships';
our $UB_REALNAME          = 'ub_realname';
our $UB_EMAIL             = 'ub_email';

# our $USERBASE_URL = "/cgi-bin/userbase/userbase.cgi";
our $USERBASE_URL = "/userbase";
our $USERBASE_PATT = 'admin=(0|1):::::member=(0|1):::::username=(.*?):::::userid=(\d*?):::::group_memberships=(.*?):::::realname=(.*?):::::email=(.*?):::::(.*)';
# admin=1:::::member=1:::::username=ahc@me.com:::::userid=2056:::::group_memberships=admin,member,public:::::realname=:::::email=ahc@me.com:::::
sub get_user_details {
  my ($verbose) = @_;

  my %cookies = CGI::Cookie->fetch;
  my %user = ();
  my $login_check = '';
  my $content = '';
  if (defined(my $site_session = $cookies{'site_session'})) {
    my $ss_val = $site_session->value;
    $login_check = "http://" . $ENV{'HTTP_HOST'} . "${USERBASE_URL}?action=chklogin&ubsessioncode=$ss_val";
#    $login_check = "http://localhost/${USERBASE_URL}?action=chklogin&ubsessioncode=$ss_val";
    $content = get($login_check);
    if ($content =~ /^$USERBASE_PATT/) {
      print STDERR "Userbase.pm::get_user_details(): Pattern match<br>\n";
      $user{$UB_IS_ADMIN} = $1;
      $user{$UB_IS_MEMBER} = $2;
      $user{$UB_USERNAME} = $3;
      $user{$UB_USERID} = $4;
      $user{$UB_GROUP_MEMBERSHIPS} = $5;
      $user{$UB_REALNAME} = $6;
      $user{$UB_EMAIL} = $7;

    }
  }
  if ($verbose) {
    print "Userbase::get_user_details()<br>\n";
    print "ub_is_admin = $user{$UB_IS_ADMIN}<br>\n";
    print "ub_is_member = $user{$UB_IS_MEMBER}<br>\n";
    print "ub_username = $user{$UB_USERNAME}<br>\n";
    print "ub_userid = $user{$UB_USERID}<br>\n";
    print "ub_group_memberships = $user{$UB_GROUP_MEMBERSHIPS}<br>\n";
    print "ub_realname = $user{$UB_REALNAME}<br>\n";
    print "ub_email = $user{$UB_EMAIL}<br>\n";
    print STDERR "Userbase.pm::get_user_details(): url = $login_check<br>\n";
    my $clen = length($content);
    print STDERR "Userbase.pm::get_user_details(): content length = $clen<br>\n";
    if ($clen < 1000) {
      print STDERR "Userbase.pm::get_user_details(): content = $content<br>\n";
    }
#    print "<pre>$content</pre><br>\n"
  }
  return (scalar(keys(%user))) ? \%user : undef;
}
