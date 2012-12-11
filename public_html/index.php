<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <?php
      error_reporting(E_ALL);
      set_include_path(get_include_path() . PATH_SEPARATOR . '/Users/ahc/idoimaging/php');
      require_once "Utility.php";
      require_once "Content.php";
      require_once 'Radutil.php';

      $util    = new Utility();
      $rad     = new Radutil($util);
      $content = new Content($util, $rad);

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

	// Login-related content, if any.
	print Utility::comment("Login related content begin");
	if ($is_admin = Utility::elem_of($ub_details, Radutil::UB_IS_ADMIN)) {
	  // Admins get the admin menu all the time. 
	  print "<tr>\n<td class='ub_edit_info'>\n";
	  virtual(Radutil::USERBASE . '?' . $_SERVER['QUERY_STRING']); 
	  print "</td>  <!-- ub_edit_info -->\n</tr>\n";
	} else {
	  $content->print_login_for_state(Radutil::UB_BODY, $ub_details);
	}
	print Utility::comment("Login related content end");

	// Do not print rest of page if login_for_state was an account-editing action.
        $is_editing = $rad->is_editing();
	// if (!($is_editing or $is_admin)) {
	if (!($is_editing )) {
	  // Use the following code if not a user-editing condition.
      ?>
      
      <!-- Row 1: Intro -->
      <tr>
	<td width='920' class='white' align='center'>
	  <table cellpadding='5' cellspacing='0'>
	    <tr>
	      <td id='frontpage_intro' width='558' class='white'  valign='top' >
		<?php
		  include("intro.html");
		?>
	      </td>  <!-- frontpage_intro -->
	      <td id='frontpage_status' width='300' class='white' valign='top'>
		<?php
		  $content->virtual_or_exec(Content::STATUS);
		?>
	      </td>  <!-- frontpage_status  -->
            </tr>
	  </table>
	</td>
      </tr>
      <!-- End of row 1: intro -->

      <!-- Row 2: Search functions. -->
      <tr>
	<td id='frontpage_search' width='920' class='white' align='center'>
	  <?php
		  if (!$content->print_static_file_for(Content::FINDER_NH)) {
		    $content->virtual_or_exec(Content::FINDER_NH);
		  }
	  ?>
	</td>  <!-- frontpage_search -->
      </tr>
      <!-- End of row 2: Search functions. -->
      
      <?php
		  /// Row for Quick Links
		  if (!$content->print_static_file_for(Content::QUICKLINKS)) {
		    $content->virtual_or_exec(Content::QUICKLINKS);
		  }
		  // Row for New Version Releases, Newly Added Programs
		  if (!$content->print_static_file_for(Content::NEWRELEASES)) {
		    $content->virtual_or_exec(Content::NEWRELEASES);
		  }
		  // Row for 'Highest Ranked', 'Most Visited', 'Most Tracked'
		  include(Content::NEWS);
        } else {
	  // Known state - user editing condition - don't print page contents.
	}
	$content->virtual_or_exec(Content::FOOTER);
      ?>
      
    </table>

    <?php
      $content->virtual_or_exec(Content::ANALYTICS);
    ?>

  </div>
</body>
</html>
