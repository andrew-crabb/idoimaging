#! /opt/local/bin/php

<?php
error_reporting(E_ALL);

$curr_dir = realpath(dirname(__FILE__));
$include_path = get_include_path() 
  . PATH_SEPARATOR . realpath("${curr_dir}/../lib")
  . PATH_SEPARATOR . realpath("${curr_dir}/../contrib")
  . PATH_SEPARATOR . realpath("${curr_dir}/../contrib/mailchimp");
set_include_path($include_path);
require_once 'MailChimp.php';
require_once 'MailDB.php';
require_once 'MCAPI.class.php';
require_once 'Utility.php';

// ------------------------------------------------------------
// Constants
// ------------------------------------------------------------

define('MYDEBUG', 1);

define('DEFAULT_PERIOD', 30);	// Period for program updates in email.
define('MAX_EMAILS', 3);	// Number of most recent email addrs to receive newsletter only.



// set_error_handler("my_error_handler");
$util = new Utility();        // General purpose utilities.

// ------------------------------------------------------------
// Command line options
// ------------------------------------------------------------

define('OPT_HELP'    , 'h');     // h: Help   :
define('OPT_LOCAL'   , 'l');     // l: Local  : Don't connect to MailChimp
define('OPT_PERIOD'  , 'p');     // p: Period : Period in days
define('OPT_SEND'    , 's');     // s: Send   : Send emails through MailChimp
define('OPT_USER'    , 'u');     // u: User   : User ident to send to
define('OPT_YEAR'    , 'y');     // y: Year   : Year of account creation for user emails.
define('OPT_VERBOSE' , 'v');     // v: Verbose:

$allopts = array(
  OPT_HELP => array(
    Utility::OPTS_NAME => 'help',
    Utility::OPTS_TYPE => Utility::OPTS_BOOL,
    Utility::OPTS_TEXT => 'Print this help text',
  ),
  OPT_LOCAL => array(
    Utility::OPTS_NAME => 'local',
    Utility::OPTS_TYPE => Utility::OPTS_BOOL,
    Utility::OPTS_TEXT => 'Run locally',
  ),
  OPT_PERIOD => array(
    Utility::OPTS_NAME => 'period',
    Utility::OPTS_TYPE => Utility::OPTS_VALO,
    Utility::OPTS_TEXT => 'Period in days',
    Utility::OPTS_DFLT => DEFAULT_PERIOD,
  ),
  OPT_SEND => array(
    Utility::OPTS_NAME => 'send',
    Utility::OPTS_TYPE => Utility::OPTS_BOOL,
    Utility::OPTS_TEXT => 'Do send emails (not test)',
  ),
  OPT_USER => array(
    Utility::OPTS_NAME => 'user',
    Utility::OPTS_TYPE => Utility::OPTS_VALO,
    Utility::OPTS_TEXT => 'User ID to send to',
  ),
  OPT_YEAR => array(
    Utility::OPTS_NAME => 'year',
    Utility::OPTS_TYPE => Utility::OPTS_VALO,
    Utility::OPTS_TEXT => 'Year of account creation for user emails',
  ),
  OPT_VERBOSE => array(
    Utility::OPTS_NAME => 'verbose',
    Utility::OPTS_TYPE => Utility::OPTS_BOOL,
    Utility::OPTS_TEXT => 'Verbose',
  ),
);

$opts = $util->process_opts($allopts);
if ($opts[OPT_HELP]) {
  $util->usage($allopts);
  exit;
}
// $util->printr($opts, 'opts', true);
$util->print_opts($opts, $allopts);

// Check if option 's' selected.
if ($opts{OPT_SEND}) {
  $response = readline("Really send the emails? [y/N]: ");
  $opts{OPT_SEND} = (strtoupper(substr($response, 0, 1)) == 'Y') ? 1 : 0;
}

// ------------------------------------------------------------
// Mail objects (delay construction as need options)
// ------------------------------------------------------------

$mail   = new MailChimp($opts{OPT_VERBOSE});      // Functions specific to MailChimp
$maildb = new MailDB($opts{OPT_VERBOSE});         // Database-related mail content

// $mail->list_campaigns();
// $mail->list_templates();

// Initialize database.
$imaging_key  = $opts{OPT_LOCAL} ? Utility::HOST_LOCALHOST_IMAGING  : Utility::HOST_IDI_IMAGING;
$userbase_key = $opts{OPT_LOCAL} ? Utility::HOST_LOCALHOST_USERBASE : Utility::HOST_IDI_USERBASE;
$dbh_ub  = $util->host_connect_pdo($userbase_key);
$dbh_im  = $util->host_connect_pdo($imaging_key);

// ------------------------------------------------------------
// Main Program
// ------------------------------------------------------------

// Get all new versions over this period.
$versions_this_period = $maildb->make_versions_this_period_pdo($dbh_im, $opts{OPT_PERIOD});

// Analyze program versions in this period.

// hang on a minute, vers_for_users isn't used??!

list($vers_for_users, $users_for_prog) = make_vers_for_users($versions_this_period);
$prog_ids = array_keys($users_for_prog);
sort($prog_ids, SORT_NUMERIC);

$util->printr($vers_for_users, 'vers_for_users', true);
$util->printr($users_for_prog, 'users_for_prog', true);

exit;
// Get one image per program to use in the email.
$prog_imgs = make_images_for_programs($prog_ids);

// ------------------------------------------------------------
// Create mail list and groups.  Related to users, not mail content.
// ------------------------------------------------------------

// Ensure all users for this email are on the MailChimp list, remove if not.
$users_this_email = array_keys($vers_for_users);
print count($users_this_email) . " users_this_email: " . join(" ", $users_this_email) . "\n";

list($group_names, $groupnames_for_users) = $mail->create_group_names($users_for_prog);
// $util->printr($group_names, 'group_names', true);
// $util->printr($groupnames_for_users, 'groupnames_for_users', true);

// Create text and HTML content for program updates, also add-monitor guide.
list($program_content, $text_str) = $maildb->content_for_programs($prog_ids, $prog_imgs, $versions_this_period);
exit;
// print "------------------------------\n";
// print "$program_content\n";
// print "------------------------------\n";
// print "$text_str\n";
// print "------------------------------\n";

// template_str is retrieved from MailChimp
$template_id = $mail->select_template();

$template_str = $mail->get_html_of_template($template_id);
$mail->list_templates();
$email_str = str_replace('__PROGRAMS_CONTENT__', $program_content, $template_str);

if ($handle = fopen('/tmp/ahc_email_' . date('Ymd_His') . '.html', 'w')) {
  fwrite($handle, $email_str);
}

// Delete all existing groups, re-create for users getting this email.
try {
  $mail->delete_existing_groups(); 
  $mail->create_groupings();
  $mail->create_groups($group_names, $groupnames_for_users);
} catch (Exception $e) {
  error_log("Error during group creation");
  print $e->getMessage() . "\n";
  echo $e->getTraceAsString() . "\n";
  exit(1);
}

  // ------------------------------------------------------------
  // Create email campaign.  Related to mail content, not users.
  // ------------------------------------------------------------

  $campaign_id = $mail->create_campaign($email_str, $text_str, $group_names);

  // ------------------------------------------------------------
  // Send campaign.
  // ------------------------------------------------------------

  if ($opts{OPT_SEND}) {
    $sent_ok = $mail->send_campaign($campaign_id);
    print "sent_ok = mail->send_campaign($campaign_id)\n";
    if (!$sent_ok) {
      print "ERROR: Campaign $campaign_id not sent.\n";
    }
  } else {
    print "Emails were not sent.\n";
  }
exit;
// ------------------------------------------------------------
// Update database with email compaign, recipients, and versions.
// ------------------------------------------------------------$
$maildb->update_mail_sent($campaign_id, $template_id, $users_this_email);

// ================================================================================
//                               FUNCTIONS
// ================================================================================

function my_error_handler($errno, $errstr) {
  global $util;
  
  print("MailChimp::my_error_handler(): Error[$errno]: $errstr\n");
  if (MYDEBUG && ($errno >= E_NOTICE)) {
    $util->print_trace();
    exit;
  }
}

// ------------------------------------------------------------
// Iterate over all new versions released within period.
//   vers_for_users: Hash by user ids of arrays of version objects.
//   prog_ids       : Array of unique program ids
// ------------------------------------------------------------

function make_vers_for_users($versions_this_period) {
  global $util, $opts, $dbh_ub, $dbh_im;
  
  $prog_ids = array();
  $vers_for_users = array();
  $users_for_prog = array();
  // $summaries = array();
  $prog_summ = array();
  foreach ($versions_this_period as $version_id => $ver) {
    $progid = $ver['progid'];
    $version = $ver['version'];
    // Newest of duplicate versions is seen first.
    if (in_array($progid, $prog_ids)) {
      print "Already seen progid $progid, omit old version " . $ver['version'] . "\n";
      continue;
    }
    array_push($prog_ids, $progid);

    // Build array of user emails to notify for this version.
    $monstr  = "select distinct userbase.userbase_users.username";
    $monstr .= " from imaging.monitor";
    $monstr .= " join userbase.userbase_users";
    $monstr .= " on imaging.monitor.userid = userbase.userbase_users.id";
    $monstr .= " where imaging.monitor.progid = '$progid'";

    $result = $util->query_issue_pdo($dbh_im, $monstr);
    foreach ($result as $row) {
      $user = $row['username'];
      $users_for_prog[$progid][] = $user;
      $vers_for_users[$user][] = $ver;
    }

    if (isset($users_for_prog[$progid])) {
      $n_users = count($users_for_prog[$progid]);
      $user_str = ($n_users > 1) ? "$n_users users" : join(", ", $users_for_prog[$progid]);
    } else {
      $n_users = 0;
      $user_str = '';
    }
    array_push($prog_summ, array($progid, $n_users, $user_str));
  }

  $user_summ = array();
  foreach ($vers_for_users as $user => $versions) {
    $nvers = count($vers_for_users[$user]);
    $vers = array();
    foreach ($vers_for_users[$user] as $ver) {
      array_push($vers, $ver['progid']);
    }
    $verstr = (count($vers) > 2) ? count($vers) . " programs" : join(', ', $vers);
    array_push($user_summ, array($user, $nvers, $verstr));
  }

  $util->print_array_formatted($prog_summ, true, "make_vers_for_users(): programs", array('prog', 'num', 'users'));
  $util->print_array_formatted($user_summ, true, "make_vers_for_users(): users", array('user', 'num', 'progs'));

  ksort($vers_for_users, SORT_NUMERIC);
  return array($vers_for_users, $users_for_prog);
}

// ------------------------------------------------------------
// For mail list groups, create array of users for each version (== each program)
// ------------------------------------------------------------

function make_users_for_progs( $vers_for_users ) {
  global $util;
  
  $users_for_progs = array();
  foreach ($vers_for_users as $user => $versions) {
    foreach ($versions as $version) {
      $progid = $version['progid'];
      $users_for_progs[$progid][] = $user;
    }
  }

  print "-------------------- make_users_for_progs begin --------------------\n";
  foreach ($users_for_progs as $version => $users) {
    $progid = $version['progid'];
    print "Program $version goes to " . count($users) . " users\n";
  }
  ksort($users_for_progs, SORT_NUMERIC);
  print "-------------------- make_users_for_progs end   --------------------\n";
  return $users_for_progs;
}

// ------------------------------------------------------------
// Create hash by program id of images to use for all programs.
// ------------------------------------------------------------

function make_images_for_programs($prog_ids) {
  global $util, $dbh_im;
  
  $prog_imgs = array();
  $summaries = array();
  $summ_lines = array();
  foreach ($prog_ids as $progid) {
    $istr  = "select * from image where";
    $istr .= " (   rsrcfld = 'prog'";
    $istr .= " or  rsrcfld = 'title')";
    $istr .= " and path    = 'sm'";
    $istr .= " and scale   = '200'";
    $istr .= " and rsrcid  = '$progid'";
    $images = $util->query_as_hash_pdo($dbh_im, $istr, 'ident');
    if (count($images)) {
      $images_prog = array();
      $images_title = array();
      foreach ($images as $ident => $image) {
        $fldname = 'images_' . $image['rsrcfld'];
        ${$fldname}[] = $image;
      }
      $nimg_prog  = count($images_prog);
      $nimg_title = count($images_title);
      // Use title image if available, else prog image.
      $image_used = '';
      if ($nimg_title > 0) {
        $image_used = $images_title[0];
      } else {
        $img_indx = rand(1, $nimg_prog) - 1;
        $image_used = ($nimg_prog) ? $images_prog[$img_indx] : '';
      }
      $prog_imgs[$progid] = $image_used;
      $summaries[] = "*** $nimg_prog prog, $nimg_title title images for program $progid, using " . $image_used['filename'];
      $summ_lines[] = array($nimg_prog, $nimg_title, $progid, $image_used['filename']);
    } else {
      // No images for this program.  Not an error condition?  Just don't define element.
    }
  }

  $headings = array('n_prog', 'n_title', 'Prog', 'File');
  $util->print_array_formatted($summ_lines, true, "Image Files for Programs", $headings);

  return $prog_imgs;
}

function not_yet_used() {
  // Performing SQL query
  $query = "SELECT count(*) FROM $t_program";
  $result = mysql_query($query) or die("Query failed: " . mysql_error() . "\n");

  // Printing results in HTML
  echo "<table>\n";
  while ($line = mysql_fetch_array($result, MYSQL_ASSOC)) {
    echo "\t<tr>\n";
    foreach ($line as $col_value) {
      echo "\t\t<td>$col_value</td>\n";
    }
    echo "\t</tr>\n";
  }
  echo "</table>\n";

  // Free resultset
  mysql_free_result($result);
}

?>
