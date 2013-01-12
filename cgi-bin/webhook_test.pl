#! /usr/local/bin/perl -w

use CGI;
use CGI::Carp 'fatalsToBrowser';

use FindBin qw($Bin);
use lib $Bin;
use radutils;
# use Utilities_new;
use constants;

# ==================== CONSTANTS ====================
my $outstem = "/usr/home/acrabb/open/webhook_test_";

# Webhook constants: Common
my $wh_type                = 'type';
my $wh_fired_at            = 'fired_at';
my $wh_profile             = 'profile';
my $wh_subscribe           = 'subscribe';
my $wh_unsubscribe         = 'unsubscribe';
my $wh_upemail             = 'upemail';
# Webhook constants: Update email
my $wh_update_new_id       = 'data[new_id]';
my $wh_update_new_email    = 'data[new_email]';
my $wh_update_old_email    = 'data[old_email]';
my $wh_update_list_id      = 'data[list_id]';
# Webhook constants: Subscribe
my $wh_subscribe_id        = 'data[id]';
my $wh_subscribe_email     = 'data[email]';
my $wh_subscribe_list_id   = 'data[list_id]';
# Webhook constants: Unsubscribe
my $wh_unsubscribe_action  = 'data[action]';
my $wh_unsubscribe_reason  = 'data[reason]';
my $wh_unsubscribe_id      = 'data[id]';
my $wh_unsubscribe_email   = 'data[email]';
my $wh_unsubscribe_list_id = 'data[list_id]';
# Webhook constants: Profile
my $wh_profile_id          = 'data[id]';
my $wh_profile_email       = 'data[email]';
my $wh_profile_list_id     = 'data[list_id]';
    

$cgi = new CGI;
print $cgi->header();

print $cgi->start_html(
   -title  => "Webhook Test", 
     ) . "\n";
print comment("webhook: Content only required for ping test.");

our @outlines = ();
print_all_params();
my $type = $cgi->param($wh_type);
if ($type eq $wh_subscribe) {
  do_subscribe();
} elsif ($type eq $wh_unsubscribe) {
  do_unsubscribe();
} elsif ($type eq $wh_upemail) {
  do_upemail();
} else {
  # Unknown action.
}

write_params_to_file();

sub do_subscribe {
  
}

sub do_unsubscribe {
  my $email = $cgi->param($wh_unsubscribe_email);
  my $id    = $cgi->param($wh_unsubscribe_id);
  my $str = "delete from subscribers";
  $str   .= " where Email like '$email'";
  $str   .= " or mc_ident = '$id'";
  push(@outlines, "$str\n");
  my $mstr = "delete from monitor";
  $mstr   .= " where userid = 'insert_user_id_here'";
#   print "$mstr\n";
  push(@outlines, "m$str\n");
}

sub do_upemail {
  
}
 
sub print_all_params {  
  my @param_names = $cgi->param();

  foreach my $param_name (@param_names) {
    my $param_value = $cgi->param($param_name);
    push(@outlines, "$param_name: $param_value\n");
  }
}

sub write_params_to_file {
  my $outfile = $outstem . time() . ".txt";
  write_file($outfile, \@outlines);
}
