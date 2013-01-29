<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">

  <head>
    <?php
      error_reporting(E_ALL);
      $curr_dir = realpath(dirname(__FILE__));
      set_include_path(get_include_path() . PATH_SEPARATOR . "${curr_dir}/../lib");

      require_once 'Utility.php';
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

	// ------------------------------------------------------------
	// Includes
	// ------------------------------------------------------------

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

	$util->write_file($logfile, $postvals, 'a+');
