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
        $msg_404 = "Page not found.  Try the <a href='/index.php'>front page</a> or use <a href='/finder'>Search</a> to find the page you're looking for.";

        $ub_details = $rad->get_user_details();
        // Title image and login block
        $content->print_page_header($ub_details);
        $content->print_page_intro(Radutil::NAV_HOME);

        $msg = '';
        $HttpStatus = $_SERVER["REDIRECT_STATUS"] ;
        if($HttpStatus==200) {$msg = "Document has been processed and sent to you.";}
        if($HttpStatus==400) {$msg = "Bad HTTP request ";}
        if($HttpStatus==401) {$msg = "Unauthorized - Iinvalid password";}
        if($HttpStatus==403) {$msg = "Forbidden";}
        if($HttpStatus==404) {$msg = $msg_404;}
        if($HttpStatus==500) {$msg = "Internal Server Error";}
        if($HttpStatus==418) {$msg = "I'm a teapot! - This is a real value, defined in 1998";}

        print "<tr><td class='white'><span class='white-box'>$msg\n</span></td></tr>\n";
        print "<tr><td class='white'>&nbsp;</td></tr>\n";

        $content->virtual_or_exec(Content::FOOTER   , false);
        $content->virtual_or_exec(Content::ANALYTICS, false);

      ?>
    </div>
  </body>
</html>
  
