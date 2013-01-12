<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">

  <head>
    <?php
      error_reporting(E_ALL);
      require_once "BIN/Utility.php";
      require_once "Content.php";
      require_once 'Radutil.php';

      $util    = new Utility();         // General purpose utilities.
      $rad     = new Radutil($util);         // Utilities specific to the site.
      $content = new Content($util, $rad);         // Generates site-specific content.

      $content->print_index_head();
    ?>
  </head>

  <body>
    <div class='container'>
<?php
// idi_webhook.php
// This URL is called by MailChimp upon a list event.

error_reporting(E_ALL);

// ------------------------------------------------------------
// Constants
// ------------------------------------------------------------

define('DIR_BIN_DEVEL' , '/Users/ahc/BIN/php');
define('DIR_BIN_ONLINE', '');
define('DIR_PUB_DEVEL' , '/Users/ahc/public_html/php');
define('DIR_PUB_ONLINE', '');

// ------------------------------------------------------------
// Includes
// ------------------------------------------------------------

$g_include_dirs  = array(DIR_BIN_ONLINE, DIR_PUB_ONLINE, DIR_BIN_DEVEL, DIR_BIN_ONLINE);
$g_include_files = array('Utility', 'Radutil', 'Library', 'MailChimp', 'MailDB');

foreach ($g_include_files as $include_file) {
  $file_found = 0;
  foreach ($g_include_dirs as $inc_dir) {
    $full_include_file = "${inc_dir}/${include_file}.php";
    if (file_exists($full_include_file)) {
      require_once $full_include_file;
      $file_found = 1;
      break;
    }
  }
  if (!$file_found) {
    print "Error: Can't include required file $include_file<br />\n";
    exit;
  }
}

$util = new Utility();
$rad  = new Radutil($util);
$lib = new Library();
$mc = new MailChimp();

// ------------------------------------------------------------
// Main
// ------------------------------------------------------------

// $in_listid = $_GET['listid'];
// if (!isseet($in_listid) or ($in_listid != $mc->list_id)) {
//  die('Authorization Denied');
// }

$postvals = array();
foreach ($_POST as $key => $value) {
  $postvals[] = "$key = $value";
}

$logfile = MailChimp::LOGFILE_STEM . $util->timenow(Utility::DATES_DATETIME) . ".txt";
$util->write_file($logfile, $postvals, 'a+');

