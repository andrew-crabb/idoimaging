<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">

  <head>
    <?php
      error_reporting(E_ALL);
      $include_path = get_include_path() ;
      set_include_path($include_path . PATH_SEPARATOR . '/Users/ahc/BIN/php'. PATH_SEPARATOR .  '/Users/ahc/public_html/idoimaging');
      require_once "Utility.php";
      require_once "php/Content.php";
      require_once 'php/Radutil.php';

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
      <!-- Top of page content.  Contains logo and login section -->
      <?php
        // Title image and login block
	$ub_details = $rad->get_user_details();
        $content->print_page_header($ub_details);

        // Which menu item to highlight.  My env MY_REDIRECT overrides Apache REDIRECT_URL
	if (isset($_SERVER['MY_REDIRECT'])) {
	  $redirect_url = $_SERVER['MY_REDIRECT'];
	} else {
	  $redirect_url = getenv('REDIRECT_URL');
	}
	
        $menu_item = $content->menu_item_for_redirect($redirect_url);

        // Start table, navigation code, page-top advertising.
        $content->print_page_intro($menu_item);

	?>

