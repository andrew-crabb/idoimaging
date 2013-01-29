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
      <!-- Top of page content.  Contains logo and login section -->
      <?php
	$ub_details = $rad->get_user_details();
	// Title image and login block
	$content->print_page_header($ub_details);

	// Start table, navigation code, page-top advertising.
	$content->print_page_intro(Radutil::NAV_HOME);

        // Print goodbye message if just logged out.
        if ($rad->do_print_goodbye()) {
          // Avoids re-login from 'bye' page going back to 'bye' page.
          $rad->print_row_white_ctr("Thank you for visiting I Do Imaging.  You are logged out.");
        } else {
          // Login-related content, if any.
          print Utility::comment("Login related content begin");
          if ($is_admin = Utility::elem_of($ub_details, Radutil::UB_IS_ADMIN)) {
            // Admins get the admin menu all the time. 
            $content->print_ub_content_in_tr();
          } else {
            $content->print_login_for_state(Radutil::UB_BODY, $ub_details);
          }
          print Utility::comment("Login related content end");
          
          // Do not print rest of page if login_for_state was an account-editing action.
          $is_editing = $rad->is_editing();
          if (!($is_editing or $is_admin)) {
            // Use the following code if not a user-editing condition.
            include('front_page_contents.html');
            // $util->tt_debug("include('front_page_contents.html')");
          }
        }
	$content->virtual_or_exec(Content::FOOTER);
      ?>
      
    </table>

    <?php
      $content->virtual_or_exec(Content::ANALYTICS);
    ?>

  </div>  <!-- container -->
</body>
</html>
