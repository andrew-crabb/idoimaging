<?php 
$groups_allowed = "admin"; 
# $users_allowed = 'ahc';
require($_SERVER['DOCUMENT_ROOT'] . "/login/ublock.php"); 
?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <?php
      error_reporting(E_ALL);
      $curr_dir = realpath(dirname(__FILE__));
      set_include_path(get_include_path() . PATH_SEPARATOR . "${curr_dir}/../php/lib");
      require_once "Utility.php";
      require_once "Content.php";
      require_once 'Radutil.php';

      $util    = new Utility();         // General purpose utilities.
      $rad     = new Radutil($util);         // Utilities specific to the site.
      $content = new Content($util, $rad);         // Generates site-specific content.

      // This does the Javascript and the CSS.
      $content->print_index_head();
      print Content::META_DATA;
    ?>
  </head>

  <body>
    <div class='container'>
      <?php
	// Note the online DB connection is for Userbase, for not for content.
	$dbh_im = $rad->host_connect(Radutil::DB_IDI);
	$dbh_ub = $rad->host_connect(Radutil::DB_IDI_UB);
	$ub_details = $rad->get_user_details();

	// Title image and login block
	$content->print_page_header($ub_details);
	// Start table, navigation code, page-top advertising.
	$content->print_page_intro(Radutil::NAV_HOME);
      ?>
      <div>
	<tr>
	  <td>
	    <a href='/admin?action=edits'>Edit Content</a><br>
	    <a href='/admin?action=activity'>View User Activity</a><br>
	    <a href='/admin?action=userbase'>Administer Userbase</a><br>
	  </td>
	</tr>
	<tr>
	  <td>
      <?php

	if (isset($_GET['action'])) {
	  // Called from self: Perform actions.
	  $action = $_GET['action'];
	  if ($action == 'edits') {
	    // ********** Section 1: Admin programs. **********
	    $content->print_admin_options();
	  } elseif ($action == 'activity') {
	    // ********** Section 2: User activity. **********
	    print_user_activity();
	  } elseif ($action == 'userbase') {
	    virtual(Radutil::USERBASE . '?' . $_SERVER['QUERY_STRING']); 
	  }
	}
	?>
	  </td>
	</tr>
      </div>
    </div>
  </body>

  <?php
    function print_user_activity() {
      global $a_week_ago;

      $timenow = time();
      $a_week_ago = $timenow - (3600 * 24 * 7);
      $events = array();
      
      add_events_for_accounts($events);
      add_events_for_logins($events);
      add_events_for_passwords($events);
      add_events_for_monitors($events);
  ?>
  <!-- Show all activity for the last week. -->
  <div class='space5pix'>
    <table cellpadding='2' cellspacing='0'>
      <tr><th colspan='5' align='center'>Last 60 events</th></tr>
      <tr><th>Date</th><th>Event</th><th>UserID</th><th>User</th><th>Age</th></tr>
      <?php
	print_event_table_rows($events);
      ?>
    </table>
  </div>
  <?php
    }
    
    function calc_age ($thetime, $userid, $comment) {
      $timenow = time();
      $elapsed = $timenow - $thetime;
      $age_days = round($elapsed / 86400);  
      // print "<tt>calc_age($userid, $comment): time $thetime elap $elapsed age $age_days</tt><br>\n";
      return $age_days;
    }

    function print_event_table_rows($events) {
      krsort($events);
      $lastdate = '';
      $days_ago = 0;
      foreach ($events as $datetime => $details) {
	list($ddate, $dtime) = explode(' ', $datetime);
	if ($ddate != $lastdate) {
	  print "<tr><th colspan='5'>$ddate</th></tr>\n";
	  $lastdate = $ddate;
	  $days_ago++;
	}
	$days_before = $details['acct_age'] - $days_ago + 1;
	print "<tr>\n";
	print "<td>" . $datetime            . "</td>\n";
	print "<td>" . $details['type']     . "</td>\n";
	print "<td>" . $details['userid']   . "</td>\n";
	print "<td>" . $details['user']     . "</td>\n";
	print "<td>" . $days_before         . "</td>\n";
	print "</tr>\n";
      }
    }

    function add_events_for_accounts(&$events) {
      global $a_week_ago, $dbh_ub;

      // Data for new accounts.
      $str  = "select id, username, cdate, loggedin, pending_email_verification";
      $str .= " from userbase_users";
      $str .= " where cdate > $a_week_ago";
      $str .= " order by cdate desc";

      if ($ub_users = Utility::query_as_array($dbh_ub, $str)) {
	foreach ($ub_users as $user) {
	  $dates = Utility::convert_dates($user['cdate']);
	  $f_cdate = $dates[Utility::DATES_DATETIME];
	  $events[$f_cdate] = array (
	    'type'   => 'New User',
	    'user'   => $user['username'],
	    'userid' => $user['id'],
	    'acct_age' => calc_age($user['cdate'], $user['id'], 'create'),
	  );
	}
      }

    }

    function add_events_for_logins(&$events) {
      global $a_week_ago, $dbh_ub;

      // Data for logins.
      $lstr =  "select userbase_logins.id as login_id,";
      $lstr .= " user_id, timestamp, username, userbase_users.cdate as cdate";
      $lstr .= " from userbase_logins, userbase_users";
      $lstr .= " where userbase_logins.user_id = userbase_users.id";
      $lstr .= " and cdate > $a_week_ago";
      $lstr .= " order by timestamp desc";

      if ($ub_logins = Utility::query_as_array($dbh_ub, $lstr)) {
	foreach ($ub_logins as $login) {
	  $dates = Utility::convert_dates($login['timestamp']);
	  $f_cdate = $dates[Utility::DATES_DATETIME];
	  $events[$f_cdate] = array (
	    'type'     => 'Login',
	    'user'     => $login['username'],
	    'userid'   => $login['user_id'],
	    'acct_age' => calc_age($login['cdate'], $login['user_id'], 'login'),
	  );
	}
      }
    }

    function add_events_for_passwords(&$events) {
      global $a_week_ago, $dbh_ub;

      // Data for password changes.
      $pstr  = "select user_id, timestamp, username, cdate";
      $pstr .= " from userbase_password_activity, userbase_users";
      $pstr .= " where userbase_password_activity.user_id = userbase_users.id";	
      $pstr .= " and timestamp > $a_week_ago";
      $pstr .= " order by timestamp desc";

      if ($ub_updates = Utility::query_as_array($dbh_ub, $pstr)) {
	foreach ($ub_updates as $update) {
	  $dates = Utility::convert_dates($update['timestamp']);
	  $f_cdate = $dates[Utility::DATES_DATETIME];
	  $events[$f_cdate] = array (
	    'type'     => 'Password',
	    'user'     => $update['username'],
	    'userid'   => $update['user_id'],
	    'acct_age' => calc_age($update['cdate'], $update['user_id'], 'update'),
	  );
	}
      }
    }

    function add_events_for_monitors(&$events) {
      global $dbh_im, $dbh_ub;

      // Data for monitors.
      $mstr  = "select * from imaging.monitor";
      $mstr .= " where datetime not like '0000%'";
      $mstr .= " and datetime > (curdate() - 7)";
      $mstr .= " order by datetime desc";

      if ($monitors = Utility::query_as_array($dbh_im, $mstr)) {
	foreach ($monitors as $monitor) {
	  $userid = $monitor['userid'];
	  $ustr  = "select username, cdate";
	  $ustr .= " from userbase_users";
	  $ustr .= " where id = $userid";
	  if ($ub_users = Utility::query_as_array($dbh_ub, $ustr)) {
	    $ub_user = $ub_users[0];
	    $user_email = $ub_user['username'];
	    $dates = Utility::convert_dates($monitor['datetime']);
	    $f_date = $dates[Utility::DATES_DATETIME];
	    
	    $events[$f_date] = array (
	      'type'     => 'Monitor',
	      'user'     => $user_email,
	      'userid'   => $userid,
	      'acct_age' => calc_age($ub_user['cdate'], $userid, 'monitor'),
	    );
	  }
	}
      }
    }

    ?>