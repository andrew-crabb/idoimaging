#! /usr/bin/php
<?php
// user_util.php
// Adds each email address given as a param to the MC email list
// as a confirmed user.  Assumes user has already responded to
// the opt-email from UserBase.
// Actions:
// - MC sends welcome email to user with unsubscribe link.
// - MC add-user calls idi webhook to add mc userid to user record.

error_reporting(E_ALL);

// ------------------------------------------------------------
// Constants
// ------------------------------------------------------------

// ------------------------------------------------------------
// Includes
// ------------------------------------------------------------

$curr_dir = realpath(dirname(__FILE__));
set_include_path(get_include_path() . PATH_SEPARATOR . "${curr_dir}/../lib");

require_once 'Utility.php';
require_once 'Library.php';
require_once 'MailChimp.php';
require_once 'UserBase.php';
require_once 'MailDB.php';
require_once 'Radutil.php';

$util = new Utility();
$rad  = new Radutil($util);
$lib  = new Library();
$mc   = new MailChimp();
$ub   = new UserBase();

// ------------------------------------------------------------
// Command line opts
// ------------------------------------------------------------

define('OPT_ADD'     , 'a');        # Add given address
define('OPT_DELETE'  , 'd');        # Delete given address
define('OPT_DEL_ALL' , 'D');        # Delete all addresses
define('OPT_EDIT'    , 'e');        # Edit given address to this value
define('OPT_HELP'    , 'h');        # Display help
define('OPT_INFO'    , 'i');        # Display given address
define('OPT_LIST'    , 'l');        # Display list of all users
define('OPT_MAIL'    , 'm');        # Mail address to use
define('OPT_TEST_MSG', 't');        # Send test message to given address
define('OPT_WELCOME' , 'w');        # Send welcome message when adding
define('OPT_VERBOSE' , 'v');        # 

$allopts = array(
  OPT_ADD => array(
    Utility::OPTS_NAME => 'add',
    Utility::OPTS_TYPE => Utility::OPTS_BOOL,
    Utility::OPTS_TEXT => 'Add given mail address',
    Utility::OPTS_CORQ => OPT_MAIL,
    Utility::OPTS_KIND => Utility::OPTS_MODE,
  ),
  OPT_DELETE => array(
    Utility::OPTS_NAME => 'delete',
    Utility::OPTS_TYPE => Utility::OPTS_BOOL,
    Utility::OPTS_TEXT => 'Delete given email address',
    Utility::OPTS_CORQ => OPT_MAIL,
    Utility::OPTS_KIND => Utility::OPTS_MODE,
  ),
  OPT_DEL_ALL => array(
    Utility::OPTS_NAME => 'delete_all',
    Utility::OPTS_TYPE => Utility::OPTS_BOOL,
    Utility::OPTS_TEXT => 'Delete all email addresses',
    Utility::OPTS_KIND => Utility::OPTS_MODE,
    Utility::OPTS_CONF => true,
  ),
  OPT_EDIT => array(
    Utility::OPTS_NAME => 'edit',
    Utility::OPTS_TYPE => Utility::OPTS_VALR,
    Utility::OPTS_TEXT => 'Edit given user to have this address',
    Utility::OPTS_CORQ => OPT_MAIL,
    Utility::OPTS_KIND => Utility::OPTS_MODE,
  ),
  OPT_HELP => array(
    Utility::OPTS_NAME => 'help',
    Utility::OPTS_TYPE => Utility::OPTS_BOOL,
    Utility::OPTS_TEXT => 'Print this help text',
  ),
  OPT_INFO => array(
    Utility::OPTS_NAME => 'info',
    Utility::OPTS_TYPE => Utility::OPTS_BOOL,
    Utility::OPTS_TEXT => 'Display information on user',
    Utility::OPTS_CORQ => OPT_MAIL,
    Utility::OPTS_KIND => Utility::OPTS_MODE,
  ),
  OPT_LIST => array(
    Utility::OPTS_NAME => 'list_users',
    Utility::OPTS_TYPE => Utility::OPTS_BOOL,
    Utility::OPTS_TEXT => 'Display list of all users',
    Utility::OPTS_KIND => Utility::OPTS_MODE,
  ),
  OPT_MAIL => array(
    Utility::OPTS_NAME => 'mail_address',
    Utility::OPTS_TYPE => Utility::OPTS_VALR,
    Utility::OPTS_TEXT => 'Email address to use',
    Utility::OPTS_KIND => Utility::OPTS_OPTN,
  ),
  OPT_TEST_MSG => array(
    Utility::OPTS_NAME => 'test_msg',
    Utility::OPTS_TYPE => Utility::OPTS_BOOL,
    Utility::OPTS_TEXT => 'Send test message to user',
    Utility::OPTS_KIND => Utility::OPTS_OPTN,
  ),
  OPT_VERBOSE => array(
    Utility::OPTS_NAME => 'verbose',
    Utility::OPTS_TYPE => Utility::OPTS_BOOL,
    Utility::OPTS_TEXT => 'Print messages',
    Utility::OPTS_KIND => Utility::OPTS_OPTN,
  ),
  OPT_WELCOME => array(
    Utility::OPTS_NAME => 'send_welcome',
    Utility::OPTS_TYPE => Utility::OPTS_BOOL,
    Utility::OPTS_TEXT => 'Send welcome email from MailChimp',
    Utility::OPTS_DFLT => false,
    Utility::OPTS_KIND => Utility::OPTS_OPTN,
  ),
);


$opts = $util->process_opts($allopts);
$numopts = $opts[Utility::OPTS_CNT];
if ($opts[OPT_HELP] or $opts[Utility::OPTS_ERR] or ($numopts == 0)) {
  $util->usage($allopts);
  exit;
}

// ------------------------------------------------------------
// Main
// ------------------------------------------------------------
// This should already be handled by process_opts().
if ($opts[OPT_ADD] or $opts[OPT_DELETE] or $opts[OPT_EDIT] or $opts[OPT_INFO]) {
  $email = $opts[OPT_MAIL];
  if (!($lib->validEmail($email) or $mc->valid_web_id($email))) {
    error_log("ERROR in email address: $email");
    error_log("Pattern expected: " . MailChimp::WEB_ID_PATTERN);
    exit;
  }
}

if ($opts[OPT_INFO]) {
  print_user_info($email);
} elseif ($opts[OPT_DELETE]) {
  delete_user($email);
} elseif ($opts[OPT_DEL_ALL]) {
  delete_all_users();
} elseif ($opts[OPT_EDIT]) {
  $new_email = $opts[OPT_EDIT];
  if ($lib->validEmail($new_email)) {
    $edited_ok = $mc->edit_user($email, $new_email);
    if ($edited_ok) {
      error_log("Edited $email to $new_email OK");
    }
  } else {
    error_log("ERROR in new email address: $email");
    exit;
  }
} elseif ($opts[OPT_ADD]) {
  add_user($email, $opts[OPT_WELCOME]);
} elseif ($opts[OPT_LIST]) {
  list_users();
}

function print_user_info($email) {
  global $mc, $ub, $util;

  $mc_info = $mc->get_user_info($email);
  $ub_info = $ub->get_user_info($email);
  print "MC info:\n";
  print_r($mc_info);
  print "----------\n";
  print "UB info:\n";
  print_r($ub_info);
  print "----------\n";

  $mc_email    = $util->elem_of($mc_info, MailChimp::EMAIL);
  $mc_id       = $util->elem_of($mc_info, MailChimp::ID);
  $mc_web_id   = $util->elem_of($mc_info, MailChimp::WEB_ID);
  $ub_id       = $util->elem_of($ub_info, UserBase::ID);
  $ub_username = $util->elem_of($ub_info, UserBase::USERNAME);
  $ub_email    = $util->elem_of($ub_info, UserBase::EMAIL);
  $ub_cdate    = $util->elem_of($ub_info, UserBase::CDATE);
  $fmtstr = "%-10s %-10s %-30s %-5s %-10s %-30s %-10s\n";
  printf($fmtstr, 'MC_ID', 'MC_WEB_ID', 'MC_EMAIL', 'UB_ID', 'UB_USERNAME', 'UB_EMAIL', 'UB_CDATE');
  printf($fmtstr, $mc_id, $mc_web_id, $mc_email, $ub_id, $ub_username, $ub_email, $ub_cdate);
}

function add_mc_to_db() {
  global $mc, $ub, $util;

  for ($page = 218; $page <= 230; $page++) {
    print "page $page\n";
    $mc_users = $mc->list_users(false, $page);
    $i = 0;
    foreach ($mc_users as $mc_user) {
      $mc_email = $mc_user[MailChimp::EMAIL];
      $mc_webid = $mc_user[MailChimp::WEB_ID];
      
      // print "add_user(): email $mc_email, mc_id $mc_webid\n";
      $ret = $ub->add_mc_to_user($mc_email, $mc_webid);
    }
  }
}

function list_users() {
  global $mc, $ub, $util;

  $mc_users = $mc->list_users(true, 0);
  $ub_users = $ub->list_users();

  // Build a hash by MailChimp web id of UserBase users
  $allusers = array();
  foreach ($ub_users as $ident => $ub_user) {
    // print "Process ub_users[$ident] (" . $ub_user[UserBase::EMAIL] . ")";
    if ($util->has_len($ub_user[UserBase::MC_IDENT])) {
      // This UB record has an MC ident: add to allusers, remove from ub_users.
      $mc_ident = $ub_user[UserBase::MC_IDENT];
      // print ", it has mc_ident $mc_ident\n";
      $allusers[$mc_ident]['UB'] = $ub_user;
      unset($ub_users[$ident]);
    } else {
      // UB record has no MC ident: leave it in ub_users.
      // print "\n";
   }
  }
  foreach ($mc_users as $mc_user) {
    $mc_webid = $mc_user[MailChimp::WEB_ID];
    $allusers[$mc_webid]['MC'] = $mc_user;
  }
  
  // Now, any users in ub_users are not on MC
  // And an allusers record with no UB field is not on UB.
  $allusers_keys = array_keys($allusers);
  foreach ($allusers_keys as $mc_ident) {
    if (isset($allusers[$mc_ident]['MC']) and isset($allusers[$mc_ident]['UB'])) {
      $email = $allusers[$mc_ident]['MC'][MailChimp::EMAIL];
      print "ident $mc_ident is good: $email\n";
    } elseif (isset($allusers[$mc_ident]['MC'])) {
      print "ident $mc_ident is on MC but not UB\n";
    } elseif (isset($allusers[$mc_ident]['UB'])) {
      print "ident $mc_ident is on UB but not MC\n";
    }
  }
  foreach ($ub_users as $ident => $ub_user) {
    // $email = $ub_user[UserBase::EMAIL];
    $email = $ub_user[UserBase::USERNAME];
    print "UB user $ident ($email) is not on MC\n";
  }
}

/**
 * Delete given user
 *
 * Delete from UserBase and MailChimp the user with given email address.
 */

function delete_user ($email) {
  global $mc, $ub;

  $mc_deleted_ok = $mc->delete_user($email);
  $ub_deleted_ok = $ub->delete_user($email);
  // $mc_deleted_ok = 'DUMMY';
  // $ub_deleted_ok = 'DUMMY';
  print "delete_user($email): mc_deleted_ok $mc_deleted_ok, ub_deleted_ok $ub_deleted_ok\n";
}

/**
 * Delete all users
 * 
 * Delete all MailChimp users, and all on UserBase who are on MailChimp.
 * This is to allow keeping admin and test accounts on UserBase.
 */

function delete_all_users() {
  global $mc, $ub, $util;

  // Get emails of all MailChimp account.
  $emails_to_delete = array();
  $mc_users = $mc->list_users(false);
  foreach ($mc_users as $mc_user) {
    // Keep my admin accounts (not formatted as email addresses).
    $email = $mc_user[MailChimp::EMAIL];
    if (strpos($email, '@') !== false) {
      $emails_to_delete[] = $email;
    }
  }
  print count($emails_to_delete) . " emails to delete after MC\n";

  // Add any UB users who have MC accounts, and were not already on list.
  $ub_users = $ub->list_users();
  foreach ($ub_users as $ident => $ub_user) {
    if ($util->has_len($ub_user[UserBase::MC_IDENT])) {
      // $ub_email = $ub_user[UserBase::EMAIL];
      $ub_email = $ub_user[UserBase::USERNAME];
      if (array_search($ub_email, $emails_to_delete) === false) {
        array_push($emails_to_delete, $ub_email);
      }
    }
  }
  print count($emails_to_delete) . " emails to delete after UB\n";

  foreach ($emails_to_delete as $email) {
    // delete_user($email);
    print "delete($email)\n";
  }

}

function add_user($email, $send_welcome) {
  global $mc, $ub, $util;

  // Adding a user.
  error_log("add_user($email)");
  $added_ok = $mc->add_user($email, false, $send_welcome);
  if ($added_ok) {
    error_log("add_user(): Added $email OK");
    // Now update userbase with MC user id.
    $opts = array($mc->list_id, $email);
    $new_member = $mc->run_api_query('listMemberInfo', $opts);
    if (isset($new_member) && $new_member['success']) {
      $mc_id_new = $new_member['data'][0]['web_id'];
      error_log("add_user(): email $email, mc_id $mc_id_new");
      $ret = $ub->add_mc_to_user($email, $mc_id_new);
    } else {
      error_log("ERROR query new email: $email");
    }
  } else {
    error_log("ERROR: mc->add_user($email)");
  }
}

?>
