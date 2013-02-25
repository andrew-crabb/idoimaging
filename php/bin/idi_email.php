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

define('EMAIL_TEMPLATE', "2col-1-2.html");
define('DEFAULT_PERIOD', 30);	// Period for program updates in email.
define('MAX_EMAILS', 3);	// Number of most recent email addrs to receive newsletter only.



// set_error_handler("my_error_handler");
$util = new Utility();        // General purpose utilities.

// ------------------------------------------------------------
// Command line options
// ------------------------------------------------------------

define('OPT_HELP'    , 'h');     // h: Help   :
define('OPT_LOCAL'   , 'l');     // l: Local  : Don't connect to MailChimp
define('OPT_NOPROGS' , 'N');     // N: No Progs: Newsletter only, no program versions.
define('OPT_PERIOD'  , 'p');     // p: Period : Period in days
define('OPT_SEND'    , 's');     // s: Send   : Send emails through MailChimp
define('OPT_USER'    , 'u');     // u: User   : User ident to send to
define('OPT_VERBOSE' , 'v');     // v: Verbose:
define('OPT_CONTENT' , 'c');     // c: Content: File with news paragraph and column 0.
define('OPT_TEMPL'   , 't');     // t: Template: File to use as email template.

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
  OPT_NOPROGS => array(
    Utility::OPTS_NAME => 'noprogs',
    Utility::OPTS_TYPE => Utility::OPTS_BOOL,
    Utility::OPTS_TEXT => 'Newsletter only, no program versions',
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
  OPT_VERBOSE => array(
    Utility::OPTS_NAME => 'verbose',
    Utility::OPTS_TYPE => Utility::OPTS_BOOL,
    Utility::OPTS_TEXT => 'Verbose',
  ),
  OPT_CONTENT => array(
    Utility::OPTS_NAME => 'content',
    Utility::OPTS_TYPE => Utility::OPTS_VALO,
    Utility::OPTS_TEXT => 'File for news/sidebar content (FQ or will glob default dir)',
  ),
  OPT_TEMPL => array(
    Utility::OPTS_NAME => 'template',
    Utility::OPTS_TYPE => Utility::OPTS_VALO,
    Utility::OPTS_TEXT => 'File for email template (FQ or will glob default dir, or use default)',
    Utility::OPTS_DFLT => EMAIL_TEMPLATE,
  ),
);

$opts = $util->process_opts($allopts);
if ($opts[OPT_HELP]) {
  $util->usage($allopts);
  exit;
}
$util->printr($opts, 'opts', true);
// Check if option 's' selected.
if ($opts{OPT_SEND}) {
  $response = readline("Really send the emails? [y/N]: ");
  $opts{OPT_SEND} = (strtoupper(substr($response, 0, 1)) == 'Y') ? 1 : 0;
}

// ------------------------------------------------------------
// Mail objects (delay construction as need options)
// ------------------------------------------------------------

$mail   = new MailChimp($opts{OPT_VERBOSE});      // Functions specific to MailChimp
$maildb = new MailDB();         // Database-related mail content

// $mail->list_campaigns();
// $mail->list_templates();


// Initialize database.
$imaging_key  = $opts{OPT_LOCAL} ? Utility::HOST_LOCALHOST_IMAGING  : Utility::HOST_IDI_IMAGING;
$userbase_key = $opts{OPT_LOCAL} ? Utility::HOST_LOCALHOST_USERBASE : Utility::HOST_IDI_USERBASE;
$dbh_ub  = $util->host_connect_pdo($userbase_key);
$dbh_im  = $util->host_connect_pdo($imaging_key);

// For template and content, use defined file or glob pattern in default location.
$document_root = $util->server_details[Utility::ENV_DOCUMENT_ROOT];
$template_path = '/Users/ahc/idoimaging/' . MailChimp::TEMPL_PATH;
$content_path  = '/Users/ahc/idoimaging/' . MailChimp::CONTENT_PATH;

$template_file = $util->file_defined_or_glob($opts{OPT_TEMPL}, $template_path, $allopts{OPT_TEMPL}{Utility::OPTS_DFLT});
$content_file = $util->file_defined_or_glob($opts{OPT_CONTENT}, $content_path);
if (!strlen($content_file) || !strlen($template_file)) {
  print "ERROR: Missing content file ($content_file) or template file ($template_file)\n";
  exit(1);
}

print "template_file $template_file\n";
print "content_file  $content_file\n";


// ------------------------------------------------------------
// Main Program
// ------------------------------------------------------------

// Get all new versions over this period.
$versions_this_period = $maildb->make_versions_this_period_pdo($dbh_im, $opts{OPT_PERIOD});
print_r($versions_this_period);

// Analyze program versions in this period.
list($vers_for_users, $prog_ids) = make_vers_for_users($versions_this_period);
 print "vers_for_users: \n";
$util->printr($vers_for_users, 'vers_for_users', true);

 print "prog_ids: \n";
$util->printr($prog_ids, 'prog_ids', true);

// Make hash by program id of array of users for this program.
$users_for_progs = make_users_for_progs($vers_for_users);
$util->printr($users_for_progs, 'users_for_progs', true);

// Get one image per program to use in the email.
$prog_imgs = make_images_for_programs($prog_ids);
// $util->printr($prog_imgs, 'prog_imgs', true);

// ------------------------------------------------------------
// Create mail list and groups.  Related to users, not mail content.
// ------------------------------------------------------------

// Ensure all users for this email are on the MailChimp list, remove if not.
$users_this_email = array_keys($vers_for_users);
print "users_this_email: " . join(" ", $users_this_email) . "\n";

// Send non-program related emails and exit, if option selected.
if ($opts{OPT_NOPROGS}) {
  $mail->send_newsletter_only($users_this_email);
  print "Exiting after sending email to non program subscribers\n";
  exit;
}

list($group_names, $groupnames_for_users) = $mail->create_group_names($users_for_progs);
$util->printr($group_names, 'group_names', true);
$util->printr($groupnames_for_users, 'groupnames_for_users', true);

// Create text and HTML content from template files.
list($program_content, $text_str) = $maildb->content_for_programs($prog_ids, $prog_imgs, $versions_this_period);
// print "\n\n$program_content\n\n";
// print "\n\n$text_str\n\n";

// Template, news paragraph, and sidebar (column 0) content.
// $content_file = $opts{OPT_CONTENT};
try {
  //  $template_str = $util->file_contents_optional($template_file, 1, 1);  // Email template.
  $user_content = $util->file_contents_optional($content_file , 0, 1);  // News and col 0.
}
catch (Exception $e) {
  print $e->getMessage() . "\n";
  exit;
}

// template_str is retrieved from MailChimp
$template_id = $mail->select_template();
$template_str = $mail->get_html_of_template($template_id);

$html_str = $maildb->add_content_to_template($template_str, $user_content, $program_content);
if ($handle = fopen('/tmp/ahc_email.html', 'w')) {
  fwrite($handle, $html_str);
}

// Don't know why I had this.  If they weren't on the list why add them now?
// $mail->check_users_on_list($users_this_email, $all_users);
// print "users_this_email now: " . join(" ", $users_this_email) . "\n";

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

  $campaign_id = $mail->create_campaign($html_str, $text_str, $group_names);

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
// ------------------------------------------------------------
$group_names_str = join(",", $group_names);
$maildb->update_mail_group($campaign_id, $mail->time_now, $group_names_str);
$maildb->update_mail_sent($campaign_id, $users_this_email);

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
  $summaries = array();
  foreach ($versions_this_period as $version_id => $ver) {
    $progid = $ver['progid'];
    $version = $ver['version'];
    // Newest of duplicate versions is seen first.
    if (in_array($progid, $prog_ids)) {
      print "Already seen progid $progid, omit old version " . $ver['version'] . "\n";
      continue;
    }
    array_push($prog_ids, $progid);
    // Build array of userids to notify for this version.
    $monstr = "select distinct userid from monitor where progid = '$progid'";
    $result = $util->query_issue_pdo($dbh_im, $monstr);
    $users_this_progid = array();
    // while ($row = mysql_fetch_assoc($result)) {
    foreach ($result as $row) {
      // Get the user email from the UB database.
      $ubstr = "select username from userbase_users where id = '" . $row['userid'] . "'";
      $ubresult = $util->query_issue_pdo($dbh_ub, $ubstr);
      foreach ($ubresult as $ubrow) {
	$users_this_progid[] = $ubrow['username'];
      }
    }
    $n_users = count($users_this_progid);
    $summaries[] = sprintf("%3d userids are monitoring program %s: %s", $n_users, $progid, join(", ", $users_this_progid));

    // Create array of version records for each user (may include duplicates).
    foreach ($users_this_progid as $user_email) {
      $vers_for_users[$user_email][] = $ver;
    }
  }

  // Print a summary.
  print "-------------------- make_vers_for_users begin --------------------\n";
  print join("\n", $summaries) . "\n";
  foreach ($vers_for_users as $user => $versions) {
    $progstr = '';
    foreach ($versions as $version) {
      $progid = $version['progid'];
      $version = $version['version'];
      $progstr .= "$progid ($version) ";
    }
    printf("user %-20s gets these programs: %s\n", $user, $progstr);
  }
  print "-------------------- make_vers_for_users end   --------------------\n";

  ksort($vers_for_users, SORT_NUMERIC);
  sort($prog_ids, SORT_NUMERIC);
  return array($vers_for_users, $prog_ids);
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
      $summaries[] = "*** $nimg_prog prog, $nimg_title title images for program $progid";
      // Use title image if available, else prog image.
      if ($nimg_title > 0) {
        $prog_imgs[$progid] = $images_title[0];
      } else {
        $img_indx = rand(1, $nimg_prog) - 1;
        $prog_imgs[$progid] = ($nimg_prog) ? $images_prog[$img_indx] : '';
      }
    } else {
      // No images for this program.  Not an error condition?  Just don't define element.
    }
  }

  print "-------------------- make_images_for_programs begin --------------------\n";
  print join("\n", $summaries) . "\n";
  print "-------------------- make_images_for_programs end   --------------------\n";
  
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
