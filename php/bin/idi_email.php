#! /opt/local/bin/php

<?php
error_reporting(E_ALL);

// ------------------------------------------------------------
// Constants
// ------------------------------------------------------------

define('MYDEBUG', 1);
define('DIR_DEVEL'     , '/Users/ahc/BIN/php');
define('DIR_ONLINE'    , '/usr/home/acrabb/BIN/php');

define('EMAIL_TEMPLATE', "2col-1-2.html");
// define('HTML_PATH'     , $_SERVER['HOME'] . "/public_html/idoimaging");
// define('TEMPL_PATH'    , "email/templ");
// define('CONTENT_PATH'  , "email/cont");
define('DEFAULT_PERIOD', 30);
define('AHC_ID', 5237);    // My email ID for I Do Imaging (HTML, email program)
define('AHC_JH', 5233);    // My email ID for JHU (text).
define('AHC_GM', 25152);   // My email id for Gmail (HTML, web browser).
define('AHC_MM', 2056);    // My email id for MobileMe

// $g_include_dirs  = array(DIR_DEVEL, DIR_ONLINE);
$g_include_dirs  = array($_SERVER['HOME'] . '/BIN/php');
$g_ahc_emails    = array(AHC_ID, AHC_JH, AHC_GM, AHC_MM);
$g_include_files = array('Utility', 'MailChimp', 'MailDB');

$files_tried = array();
foreach ($g_include_files as $include_file) {
  $file_found = 0;
  foreach ($g_include_dirs as $inc_dir) {
    $full_include_file = "${inc_dir}/${include_file}.php";
    if (file_exists($full_include_file)) {
      include_once $full_include_file;
      print "include $full_include_file\n";
      $file_found = 1;
      break;
    } else {
      array_push($files_tried, $full_include_file);
    }
  }
  if ($file_found == 0) {
    print "\nERROR: Cound not find include file $include_file, and I tried the following:\n";
    print_r($files_tried);
    // exit;
  }
}

set_error_handler("my_error_handler");
$util = new Utility();        // General purpose utilities.

// ------------------------------------------------------------
// Initialization
// ------------------------------------------------------------

$dbh_local  = $util->host_connect(Utility::HOST_IDI_USERBASE);

// ------------------------------------------------------------
// Command line options
// ------------------------------------------------------------

define('OPT_HELP'    , 'h');     // h: Help   :
define('OPT_LOCAL'   , 'l');     // l: Local  : Don't connect to MailChimp
define('OPT_PERIOD'  , 'p');     // p: Period : Period in days
define('OPT_SEND'    , 's');     // s: Send   : Send emails through MailChimp
define('OPT_TOME'    , 'm');     // m: To Me  : Send to my email addresses only.
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
  OPT_TOME => array(
    Utility::OPTS_NAME => 'me',
    Utility::OPTS_TYPE => Utility::OPTS_BOOL,
    Utility::OPTS_TEXT => 'Send to me',
    Utility::OPTS_DFLT => true,
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

// For template and content, use defined file or glob pattern in default location.
// $template_path = HTML_PATH . "/" . TEMPL_PATH;
// $content_path  = HTML_PATH . "/" . CONTENT_PATH;
$document_root = $util->server_details[Utility::ENV_DOCUMENT_ROOT];
$template_path = $document_root . '/idoimaging/' . MailChimp::TEMPL_PATH;
$content_path  = $document_root . '/idoimaging/' . MailChimp::CONTENT_PATH;

$template_file = $util->file_defined_or_glob($opts{OPT_TEMPL}, $template_path, $allopts{OPT_TEMPL}{Utility::OPTS_DFLT});
$content_file = $util->file_defined_or_glob($opts{OPT_CONTENT}, $content_path);
if (!strlen($content_file) || !strlen($template_file)) {
  print "ERROR: Missing content file ($content_file) or template file ($template_file)\n";
  exit(1);
}

print "template_file $template_file\n";
print "content_file  $content_file\n";


// ------------------------------------------------------------
// Mail objects (delay construction as need options)
// ------------------------------------------------------------

$mail   = new MailChimp($opts{OPT_VERBOSE});      // Functions specific to MailChimp
$maildb = new MailDB();         // Database-related mail content

// ------------------------------------------------------------
// Main Program
// ------------------------------------------------------------

list($all_users) = $maildb->get_db_data($dbh_local);
list($nprog, $nver, $nqver) = $maildb->get_db_counts($dbh_local);

// Get all new versions over this period.
$versions_this_period = $maildb->make_versions_this_period($dbh_local, $opts{OPT_PERIOD});

// Analyze program versions in this period.
list($vers_for_users, $prog_ids) = make_vers_for_users($versions_this_period);
print "vers_for_users: \n";
$util->printr($vers_for_users, 'vers_for_users');
print "prog_ids: \n";
$util->printr($prog_ids, 'prog_ids');

// Make hash by program id of array of users for this program.
$users_for_progs = make_users_for_progs($vers_for_users);
$util->printr($users_for_progs, 'users_for_progs');

// Get one image per program to use in the email.
$prog_imgs = make_images_for_programs($prog_ids);

// ------------------------------------------------------------
// Create mail list and groups.  Related to users, not mail content.
// ------------------------------------------------------------

// Ensure all users for this email are on the MailChimp list, remove if not.
$users_this_email = array_keys($vers_for_users);
print "users_this_email: " . join(" ", $users_this_email) . "\n";

list($group_names, $groupnames_for_users) = $mail->create_group_names($users_for_progs);

// Create text and HTML content from template files.
list($program_content, $text_str) = $maildb->content_for_programs($prog_ids, $prog_imgs, $versions_this_period);

// Template, news paragraph, and sidebar (column 0) content.
// $content_file = $opts{OPT_CONTENT};
try {
  $template_str = $util->file_contents_optional($template_file, 1, 1);  // Email template.
  $user_content = $util->file_contents_optional($content_file , 0, 1);  // News and col 0.
}
catch (Exception $e) {
  print $e->getMessage() . "\n";
  exit;
}

$html_str = $maildb->add_content_to_template($template_str, $user_content, $program_content);
if ($handle = fopen('/tmp/ahc_email.html', 'w')) {
  fwrite($handle, $html_str);
}

if (!$opts{OPT_LOCAL}) {
  $mail->check_users_on_list($users_this_email, $all_users);
  print "users_this_email now: " . join(" ", $users_this_email) . "\n";

  // Delete all existing groups, re-create for users getting this email.
  $mail->delete_existing_groups();
  $mail->create_groups($group_names, $groupnames_for_users, $all_users);

  // ------------------------------------------------------------
  // Create email campaign.  Related to mail content, not users.
  // ------------------------------------------------------------

  $campaign_id = $mail->create_campaign($html_str, $text_str, $group_names);

  // ------------------------------------------------------------
  // Send campaign.
  // ------------------------------------------------------------

  if ($opts{OPT_SEND}) {
    // $sent_ok = $mail->send_campaign($campaign_id);
    print "DUMMY: sent_ok = mail->send_campaign($campaign_id)\n";
    if (!$sent_ok) {
      print "ERROR: Campaign $campaign_id not sent.\n";
    }
  } else {
    print "Emails were not sent.\n";
  }
} else {
  $now = $util->convert_dates(time());
  $util->printr($now, 'now');
  $campaign_id = "1111" . $now{Utility::DATES_HRMNSC};
  print "campaign id = $campaign_id\n";
}

// ------------------------------------------------------------
// Update database with email compaign, recipients, and versions.
// ------------------------------------------------------------
$group_names_str = join(",", $group_names);
$maildb->update_mail_group($campaign_id, $mail->time_now, $group_names_str);
$maildb->update_mail_sent($campaign_id, $users_this_email);

// Closing connection
mysql_close($dbh_local);

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
  global $util, $opts, $g_ahc_emails, $dbh_local;
  
  $prog_ids = array();
  $vers_for_users = array();
  $summaries = array();
  foreach ($versions_this_period as $version_id => $ver) {
    $progid = $ver['progid'];
    $version = $ver['version'];
    // Newest of duplicate versions is seen first.
    if (in_array($progid, $prog_ids)) {
      print "Skipping progid $progid, version " . $ver['version'] . "\n";
      continue;
    }
    array_push($prog_ids, $progid);
    // Build array of userids to notify for this version.
    $ids_for_ver = array();
    // Iterate over each monitor record having the program for this version record.
    $monstr = "select * from monitor where progid = '$progid'";
    $users_this_progid = $util->query_as_hash($dbh_local, $monstr, 'userid');
    $n_users = count($users_this_progid);
    foreach ($users_this_progid as $monitor) {
      $userid = $monitor['userid'];
      array_push($ids_for_ver, $userid);
    }
    $summaries[] = sprintf("%3d userids are monitoring program %s", $n_users, $progid);
    
    // Create array of version records for each user (may include duplicates).
    foreach ($ids_for_ver as $userid) {
      $do_add = 1;
      if ($opts{OPT_TOME} && !in_array($userid, $g_ahc_emails)) {
        $do_add = 0;
      }
      if ($do_add) {
        $vers_for_users[$userid][] = $ver;
      }
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
    printf("user %5d gets these programs: %s\n", $user, $progstr);
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
  $util->printr($users_for_progs, 'users_for_progs');
  print "-------------------- make_users_for_progs end   --------------------\n";
  return $users_for_progs;
}

// ------------------------------------------------------------
// Create hash by program id of images to use for all programs.
// ------------------------------------------------------------

function make_images_for_programs($prog_ids) {
  global $util, $dbh_local;
  
  $prog_imgs = array();
  $summaries = array();
  foreach ($prog_ids as $progid) {
    $istr  = "select * from image where";
    $istr .= " (   rsrcfld = 'prog'";
    $istr .= " or  rsrcfld = 'title')";
    $istr .= " and path    = 'sm'";
    $istr .= " and scale   = '200'";
    $istr .= " and rsrcid  = '$progid'";
    $images = $util->query_as_hash($dbh_local, $istr, 'ident');
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
