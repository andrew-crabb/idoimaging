<?php
error_reporting(E_ALL | E_STRICT);
class Content {
  // ------------------------------------------------------------
  // Static content.
  // ------------------------------------------------------------

  const STR_RETRY_LOGIN  = 'Login not recognized, please try again';
  const ADVERTISING_FILE = 'advertising.html';
  // May delete these.
  const TITLE_HOLDER     = "title_450_70";
  
  // ------------------------------------------------------------
  // Constants.
  // ------------------------------------------------------------

  const TABLE_WIDTH = 920;
  const TABLE_NAME = 'main_table';
  
  // ------------------------------------------------------------
  // Rewrite targets, and their file equivalents.
  // Allow running virtual includes when testing from cmd line:
  // virtual(target) in Apache environment, else include(DOCUMENT_ROOT/file)
  // ------------------------------------------------------------

  const CGIBIN        = '/cgi-bin';
  // Defined in REWRITE, executed as CGI programs without page headers.
  const ABOUT         = 'about';
  const ADD_MONITOR   = 'add_monitor';
  const ADMIN         = 'admin';
  const ANALYTICS     = 'analytics';
  const BLOG          = 'blog';
  const FINDER_NH     = 'finder_nh';
  const FOOTER        = 'footer';
  const FORMATS       = 'formats';
  const HOME          = 'home';
  const LIST_VERSIONS = 'list_versions';
  const MOST_LINKED   = 'most_linked';
  const MOST_RANKED   = 'most_ranked';
  const MOST_WATCHED  = 'most_watched';
  const NEWRELEASES   = 'newreleases';
  const PEOPLE        = 'people';
  const PROGRAM       = 'program';
  const PROGRAMS      = 'programs';
  const QUICKLINKS    = 'quicklinks';
  const REDIRECT      = 'redirect';
  const RESOURCES     = 'resources';
  const SEARCH        = 'search';
  const STATUS        = 'status';
  const STATIC_CONT   = 'static_cont';
  const USER_HOME     = 'user_home';            # Must match definition in radutils.pm

  const EDIT_PROGRAM  = 'edit_program';
  const EDIT_AUTHOR   = 'edit_author';
  const EDIT_RESOURCE = 'edit_resource';
  const DO_EDIT_PROG  = 'do_edit_program';
  // Use this as a model.  I think I can eliminate the duplicated string constants.
  const SYNCH_DB      = 'synchronize_DB';
  const COMP_DB       = 'compare_db';

  // Defined in REWRITE, executed as CGI programs with page headers.
  const FINDER      = 'finder';
  // These ones are not defined in REWRITE and are included.
  const NEWS        = 'news.php';
  
  // Maps rewrite targets to (menu_index, program_to_run, description, db_table, db_field)
  // HTML files are included as such, others get cgi-bin and are executed.
  const REWRITE_NAV     = 0;
  const REWRITE_TO      = 1;
  const REWRITE_DESC    = 2;
  const REWRITE_DB_TBL  = 3;
  const REWRITE_DB_FLD  = 4;
  public $REWRITE = array(
    self::ABOUT         => array(Radutil::NAV_ABOUT     , 'about.php'      , 'About'    , ''       , ''    ),
    self::ADD_MONITOR   => array(Radutil::NAV_PROGRAMS  , 'addmonitor.pl'  , 'Monitor'  , ''       , ''    ),
    self::ANALYTICS     => array(''                     , 'analytics.html' , ''         , ''       , ''    ),
    'bloga'             => array(Radutil::NAV_BLOG      , 'bloga.php'       , 'Blog'     , ''       , ''    ),
    self::BLOG          => array(Radutil::NAV_BLOG      , 'blog.php'       , 'Blog'     , ''       , ''    ),
    self::FINDER        => array(Radutil::NAV_SEARCH    , 'finder.pl'      , 'Search'   , ''       , ''    ),
    self::FINDER_NH     => array(''                     , 'finder.pl'      , 'Search'   , ''       , ''    ),
    self::FOOTER        => array(''                     , 'footer.php'     , ''         , ''       , ''    ),
    self::FORMATS       => array(Radutil::NAV_FORMATS   , 'formats.pl'     , 'Formats'  , 'format' , 'name'),
    self::LIST_VERSIONS => array(Radutil::NAV_PROGRAMS  , 'listVersions.pl', 'Versions' , ''       , ''    ),
    self::MOST_LINKED   => array(''                     , 'mostLinked.pl'  , ''         , ''       , ''    ),
    self::MOST_RANKED   => array(''                     , 'mostRanked.pl'  , ''         , ''       , ''    ),
    self::MOST_WATCHED  => array(''                     , 'mostWatched.pl' , ''         , ''       , ''    ),
    self::NEWRELEASES   => array(''                     , 'newreleases.pl' , ''         , ''       , ''    ),
    self::PEOPLE        => array(''                     , 'people.pl'      , 'People'   , ''       , ''    ),
    self::PROGRAM       => array(Radutil::NAV_PROGRAMS  , 'program.pl'     , 'Program'  , 'program', 'name'),
    self::PROGRAMS      => array(Radutil::NAV_PROGRAMS  , 'programs.pl'    , 'Programs' , ''       , ''    ),
    self::QUICKLINKS    => array(''                     , 'quicklinks.pl'  , ''         , ''       , ''    ),
    self::REDIRECT      => array(''                     , 'redirect.pl'    , ''         , ''       , ''    ),
    self::RESOURCES     => array(Radutil::NAV_RESOURCES , 'resources.pl'   , 'Resources', ''       , ''    ),
    self::SEARCH        => array(Radutil::NAV_SEARCH    , 'search.pl'      , 'Search'   , ''       , ''    ),
    self::STATIC_CONT   => array(''                     , 'static_cont.php', 'Static'   , ''       , ''    ),
    self::STATUS        => array(''                     , 'status_new.pl'  , ''         , ''       , ''    ),
    self::USER_HOME     => array(''                     , 'users_home.php' , 'User Home', ''       , ''    ),
    self::EDIT_PROGRAM  => array(''                     , 'editprogram.pl'    , ''         , ''       , ''    ),
    self::EDIT_AUTHOR   => array(''                     , 'editauthor.pl'     , ''         , ''       , ''    ),
    self::EDIT_RESOURCE => array(''                     , 'editresource.pl'   , ''         , ''       , ''    ),
    self::DO_EDIT_PROG  => array(''                     , 'doeditprogram.pl'  , ''         , ''       , ''    ),
    self::SYNCH_DB      => array(''                     , 'synchronize_db.pl' , ''         , ''       , ''    ),
  );

  // Admin programs.  Must match with .htaccess file.
  // Should be able to replace these with the constants above.
  const ADDPROG  = 'addprog';
  const EDITPROG = 'editprog';
  const EDITREL  = 'editrel';
  const ADDAUTH  = 'addauth';
  const EDITAUTH = 'editauth';
  const ADDRESO  = 'addreso';
  const EDITRESO = 'editreso';
  const ADDREV   = 'addrev';
  const EDITREV  = 'editrev';
  const ADDDATA  = 'adddata';
  const EDITDATA = 'editdata';
  const LISTDEAD = 'listdead';
  const SYNCDB   = 'syncdb';
  const SYNCDBR  = 'syncdb_r';
  const RANKING  = 'ranking';
  const EMAILS   = 'emails';
  const UPDATES  = 'updates';

  // Indexes into ADMIN_PROGS
  const ADMIN_DESC = 0;
  const ADMIN_URL  = 1;

  public $ADMIN_PROGS = array(
    self::ADDPROG	=> array('Add Program'    , 'edit_program?add=1'),
    self::EDITPROG	=> array('Edit Program'   , 'programs?edit=1'),
    self::EDITREL	=> array('Relationships'  , ''),
    self::ADDAUTH	=> array('Add Author'     , 'edit_author?add=1'),
    self::EDITAUTH	=> array('Edit Author'    , 'edit_author'),
    self::ADDRESO	=> array('Add Resource'   , 'edit_resource?add=1'),
    self::EDITRESO	=> array('Edit Resource'  , 'edit_resource'),
    self::ADDREV	=> array('Add Review'     , ''),
    self::EDITREV	=> array('Edit Review'    , ''),
    self::ADDDATA	=> array('Add Test Data'  , ''),
    self::EDITDATA	=> array('Edit Test Data' , ''),
    self::LISTDEAD	=> array('List Dead Sites', ''),
    self::SYNCDB	=> array('Synch Databases' , 'synchronize_DB'),
    self::SYNCDBR	=> array('Synch DB Reverse', 'synchronize_DB?reverse=1&verbose=1'),
    self::COMP_DB       => array('Compare DB'      , 'synchronize_DB?compare=1'),
    self::RANKING	=> array('Rankings'       , ''),
    self::EMAILS	=> array('Emails'         , ''),
    self::UPDATES	=> array('Update Check'   , ''),
  );

  // ------------------------------------------------------------
  // JavaScript
  // ------------------------------------------------------------
  
  // JavaScript files to include.
  public $JS_FILES = array(
//    "http://fast.fonts.com/jsapi/8cd49632-3a6b-429c-9409-f21c6e9f686d.js",
    "/cgi-bin/userbase/userbase.cgi?js",
    "/js/dw_event.js",
    "/js/dw_viewport.js",
    "/js/dw_tooltip.js",
    "/js/dw_tooltip_aux.js",
    // "/js/dw_defaultprops.js",
    // "/js/google_analytics.js",
    "/js/local_settings.js",
  );
  
  // ------------------------------------------------------------
  // Heredocs for header.
  // ------------------------------------------------------------

  const PAGE_HEADER_TITLE = <<<EOD
  <span id="page_header_title">
  <a href="/index.php">
  <img src="/img/title/idoimaging_title.png" height="70" width="450" alt="I Do Imaging Title"/>
  </a>
  </span>  <!-- page_header_title -->
EOD;

  const CSS_IDI = <<<EOD
<meta http-equiv="Content-type" content="text/html; charset=utf-8" />
<link rel="stylesheet" href="/css/idoimaging_php.css" media="all" type="text/css" />
<link rel="stylesheet" href="/css/idoimaging1.css"    media="all" type="text/css" />
<link rel="stylesheet" href="/css/idoimaging_ub.css"    media="all" type="text/css" />
EOD;

const META_DATA = <<<EOD
    <link rel="SHORTCUT ICON" href="img/i_icon.ico" />
    <meta name="verify-v1" content="e3tPgqcrYKQATpByx2hX2RrsmNqr2HUeUgVCQCRmjdA=" />
    <meta name="description" content="Free DICOM and Medical Image Viewer/Converter Software" />
    <meta name="google-site-verification" content="lStnLppbZlby2aC0whjxLZlFI6h67oSA0gqzHGEvK8Y" />
    <meta http-equiv="Content-Type" content="text/html; charset=US-ASCII" />
    <meta name="keywords" content="DICOM, image, conversion, converter, viewer, medical imaging, radiology, free software, imaging, DICOM, MRI, CT, PET, freeware, programmer, open source" />
EOD;

// ------------------------------------------------------------

  function __construct($util, $rad) {
    $this->util = $util;
    $this->rad = $rad;
    $this->debug = isset($_GET["dbg"]) ? true : false;
    //    set_error_handler(array($this, "error_handler"));
  }

  public function error_handler($type, $msg, $file, $line, $context) {
    print "<tt>ERROR type $type: $msg in $file line $line</tt><br>\n";
  }

  // ------------------------------------------------------------

  public function print_index_head() {
    // Include Javascript files.
    $space = '';
    foreach ($this->JS_FILES as $jsfile) {
      print("$space<script type='text/javascript' src='$jsfile'></script>\n");
      $space = '    ';
    }

    print self::CSS_IDI . "\n";

    $title = $this->make_title_for_url();
    print "<title>$title</title>\n";
  }

  // ------------------------------------------------------------

  public function print_page_header($ub_details) {
    print "<div class='page_header'>\n";

    // Title image.
    print self::PAGE_HEADER_TITLE . "\n";

    // Login section.
    $this->print_login_box($ub_details);
    
    print "</div>  <!-- page_header -->\n";
}

  // ------------------------------------------------------------

  public function print_login_box($ub_details) {
    $query_string = $this->util->get_server_var(Utility::QUERY_STRING);
    
    // Line 0: Query string.
    print $this->util->tt_debug("query_string '$query_string'", $this->debug);
    
    // $this->debug = true;
    // Line 1 : User details.
    $logged_in = false;
    if ($ub_details[Radutil::USER_LOGGED_IN]) {
      // User is logged in.
      $ub_userid     = $ub_details[Radutil::UB_USERID];
      $ub_username   = $ub_details[Radutil::UB_USERNAME];
      print $this->util->tt_debug("'${ub_username}' Logged in", $this->debug);
      $logged_in = true;
    } else {
      // Not logged in.
      print $this->util->tt_debug("Logged out", $this->debug);
    }

    // HTML.
    // Message about leaving password blank.
    // print "<div class='page_header_message'>\n";
    // $this->print_temp_login_message();
    // print "</div>  <!-- page_header_message -->\n";

    
    // Login box.
    print "<!-- Login section -->\n";
    print "<div id='page_header_login'>\n";
    if (!$ub_details[Radutil::USER_LOGGED_IN]) {
      $readme = "<a href='/static/login_message' class='showTip readme_login'>Logging In?  Read Me</a>";
      print "<div id='login_message'>$readme</div>\n";
    }
    $this->print_login_for_state(Radutil::UB_HDR, $ub_details);
    print "</div>  <!-- page_header_login -->\n";

    return;
  }

  public function print_temp_login_message() {
    print "The login system has changed (<a href='http://idoimaging.com/blog/#new_login_system'>Why?</a>).  If you created an account before March 2012, log in with your email and leave the password blank.  You will be asked to provide a password.\n";

  }

  // ------------------------------------------------------------

  public function print_login_for_state($page_part, $ub_details) {
    $logged_in = $ub_details[Radutil::USER_LOGGED_IN];
    $query_string = $this->util->get_server_var(Utility::QUERY_STRING);
    $state_det = $this->rad->current_state();
    $state   = $state_det[Radutil::UB_STATE];
    $ub_cont = $state_det[$page_part];

    // Exceptions: Use shortest 'Login'/'Logout' link in page header under two conditions:
    // 1. When not logged in, except on the front page.
    // 2. When the state is not Unknown, ie a user account action is happening.
    $script_name = getenv('SCRIPT_NAME');
    $is_page_head = ($page_part == Radutil::UB_HDR);
    $not_front_page = (strpos($script_name, 'index.php') === false);
    $is_known_state = ($state != Radutil::UB_UNKNOWN);
    if ($is_page_head and ($not_front_page or $is_known_state)) {
      // $ub_cont = Radutil::UB_CONT_JUSTLINK;
    }

    // Admin gets none on header and full in body every time, override previous.
    if ($logged_in and $ub_details[Radutil::UB_IS_ADMIN]) {
      // $ub_cont = $is_page_head ? Radutil::UB_CONT_MINI : Radutil::UB_CONT_FULL;
      $ub_cont = $is_page_head ? Radutil::UB_CONT_MINI : Radutil::UB_CONT_NONE;
    } 

    // -------------------- Prepare content 
    // Login box, passing on any envt vars.
    $userbase_opts = "";
    $sep = "&";
    if ($ub_cont == Radutil::UB_CONT_FULL) {
      $sep = "?";
    } elseif ($ub_cont == Radutil::UB_CONT_MINI) {
       $userbase_opts = "?format=mini";
      # TEMP
      #$sep = "?";
    } elseif ($ub_cont == Radutil::UB_CONT_JUSTLINK) {
      $userbase_opts = "?format=justlink";
      # TEMP
      # $sep = "?";
    }
    $userbase_opts .= (strlen($query_string)) ? $sep . $query_string : "";
    // $this->debug = 1;
    // -------------------- Debug content 
    print Utility::comment("Login for state begin");
    print Utility::tt_debug("State '$state', Page '$page_part', Cont '$ub_cont', qs '$query_string'", $this->debug);
    print Utility::tt_debug("Opts: '$userbase_opts'", $this->debug);
    
    // -------------------- UserBase content
    // Print custom header message, if any, for this user and state.
    $cust_msg = isset($state_det[Radutil::UB_CUST_MSG]) ? $state_det[Radutil::UB_CUST_MSG] : '';
    if (!$logged_in and $is_page_head and (strlen($cust_msg))) {
      print "<div class='ub_cust_msg'>$cust_msg</div>\n";
    }
    
    // Print UserBase form.
    if ($ub_cont == Radutil::UB_CONT_NONE) {
      print Utility::comment("No Userbase code for this section");
    } else {
      $document_root = $this->util->server_details[Utility::ENV_DOCUMENT_ROOT];
      $userbase_url = Radutil::USERBASE . $userbase_opts;
      // putenv('QUERY_STRING=action=chklogin&code=' . $_COOKIE['site_session']);
      if ($this->util->is_cmd_line) {
        print Utility::tt("Not calling userbase: Run from command line");
      } else {
        print ($is_page_head) ? "" : "<tr>\n<td class='ub_edit_info'>\n";
        virtual($userbase_url);
	// print "virtual($userbase_url)\n";
        print ($is_page_head) ? "" : "</td>  <!-- ub_edit_info -->\n</tr>\n";
      }
    }

    print Utility::comment("Login for state end");
  }

  // ------------------------------------------------------------

  public function print_nav_menu($rad) {
    print "<div class='nav_menu'>\n";
    print $this->rad->make_nav_code();
    print "</div>  <!-- nav_menu -->\n";
  }

  // ------------------------------------------------------------
  // Prints start of overall table, then nav menu.
  
  public function print_page_intro($currpage) {
    $query_string = $this->util->get_server_var(Utility::QUERY_STRING);
    print Utility::comment("Page Intro begin");
    // Table containing everything in page body.
    $table_width = self::TABLE_WIDTH;
    $table_name  = self::TABLE_NAME;
    print "<table id = '$table_name' width='$table_width' border='0' cellpadding='5' cellspacing='0'>\n";

    //  Row 0: Navigation code.
    $nav_str = $this->rad->make_nav_code($currpage);
    
    print "<div ident='nav_table'>\n";
    $this->rad->print_row_white_ctr($nav_str);
    print "</div>  <!-- nav_table -->\n";

    // Row 1: Advertising.
    $have_logged_out = (strpos($query_string, Radutil::LOGGED_OUT_STR) !== false);
    $is_dev_machine = (strpos($_SERVER['HTTP_HOST'], Radutil::REMOTE_SERVER) === false);

    if ($have_logged_out or $is_dev_machine) {
      $ad_cont = "&nbsp;";
    } else {
      // Temp SIIM advert gets shown 1 page out of 8.
              $ad_file = getenv('DOCUMENT_ROOT') . '/' . self::ADVERTISING_FILE;
      $ad_cont = $this->util->file_contents($ad_file);
    }
    print "<div ident='advertising_top'>\n";
    $this->rad->print_row_white_ctr($ad_cont);
    print "</div> <!-- advertising_top -->\n";
    print Utility::comment("Page Intro end");
  }

  // ------------------------------------------------------------
  // virtual() or exec() the given rewrite target or its file equivalent,
  // depending on whether run from Apache environment or command line.

  public function virtual_or_exec($target, $do_redirect = true, $ub_details = '') {
    // Determine userid of logged in user
    $userid = '';
    if (isset($ub_details[Radutil::USER_LOGGED_IN]) and $ub_details[Radutil::USER_LOGGED_IN]) {
      $userid = $ub_details[Radutil::UB_USERID];
    }

    $query_string  = $this->util->get_server_var(Utility::QUERY_STRING);
    // ahc ***** NOTE RECENT CHANGE *****
    // unset($_SERVER['QUERY_STRING']);
    $server_name   = getenv('SERVER_NAME');

    $targ_str = preg_replace('/[\/]*(\w+)[\/\?]*.*/', '$1', $target);
    $new_target = $this->REWRITE[$targ_str][self::REWRITE_TO];
    $do_exec = (strpos($new_target, '.pl') !== false);
    $path = ($do_exec) ? '' : self::CGIBIN;
    // print Utility::tt_debug("virt_or_exec(): query_string '$query_string', target '$target'");
    // print Utility::tt_debug("virt_or_exec(): targ_str '$targ_str', new_targ '$new_target'");

    if ($this->util->is_cmd_line) {
      if ($do_exec) {
        // Case 0: Running an executable from command line.
        $cl_query_string = str_replace('&', ' ', $query_string);
        $cmd_str = "SERVER_NAME=$server_name; export SERVER_NAME;";
        $cmd_str .= Radutil::CLI_DOCUMENT_ROOT . "/.." . self::CGIBIN . "/${new_target} $cl_query_string";
	// print Utility::tt_debug("Content::virtual_or_exec(): Case 0 (CL, run): $cmd_str");
	$ret = `$cmd_str`;
      } else {
	// Case 1: Include a file from command line.
	$inc_file = Radutil::CLI_DOCUMENT_ROOT . '/' . $new_target;
	// print Utility::tt_debug("Content::virtual_or_exec(): Case 1 (CL, inc): $inc_file");
	$contents = $this->util->file_contents($inc_file);
	$ret = $contents;
      }
      print $ret;
    } else {
      // Apache environment.
      if ($do_exec) {
	// print Utility::tt_debug("Content::virtual_or_exec(): Case 2 (HTTP, virtual): $new_target");
        if (strlen($userid)) {
          apache_setenv('logged_in_user', $userid);
        }
	virtual(self::CGIBIN . "/${new_target}");
      } else {
	// print Utility::tt_debug("Content::virtual_or_exec(): Case 3 (HTTP, include): $new_target");
	include($new_target);
      }
    }
  }

  public function menu_item_for_redirect($redirect_url) {
    $menu_item = '';
    if (strlen($redirect_url)) {
    $redirect_target = preg_replace('/[\/]*(\w+)[\/\?]*.*/', '$1', $redirect_url);
    foreach ($this->REWRITE as $key => $val) {
      if ($key == $redirect_target) {
        $menu_item = $val[self::REWRITE_NAV];
        break;
      }
    }
    }
    // print Utility::tt_debug("Content::menu_item_for_redirect($redirect_url, $redirect_target) returning $menu_item");
    return $menu_item;
  }

  public function print_ub_content_in_tr() {
    print "<tr>\n<td class='ub_edit_info'>\n";
    virtual(Radutil::USERBASE . '?' . $_SERVER['QUERY_STRING']); 
    print "</td>  <!-- ub_edit_info -->\n</tr>\n";
  }

  // Page title.
  // Requires database access to get full program etc name.
  // This is done before any CGI so it has its own decode and DB access.
  // UGLY HACK!

  public function make_title_for_url() {
    $redirect_url = getenv(Utility::REDIRECT_URL);
    $redirect_target = preg_replace('/[\/]*(\w+)[\/\?]*.*/', '$1', $redirect_url);
    foreach ($this->REWRITE as $key => $val) {
      if ($key == $redirect_target) {
        $desc  = $val[self::REWRITE_DESC];
        $table = $val[self::REWRITE_DB_TBL];
        $field = $val[self::REWRITE_DB_FLD];
        break;
      }
    }

    // Page title depends on whether page is related to a database table
    $outstr = '';
    if (isset($table) and strlen($table)) {
      // redirect_url is '/program/328'
      if (preg_match("/(\d+)$/", $redirect_url, $match)) {
        $str = "select $field from $table where ident = '$match[1]'";
        $dbh = $this->rad->host_connect();
        if ($rslt = Utility::query_issue($dbh, $str)) {
          $row = mysql_fetch_array($rslt);
          $outstr = $row[0];
        }
      }
    }

    if (!strlen($outstr)) {
      $outstr = (isset($desc) and strlen($desc)) ? $desc : '';
    }
    $sep = (strlen($outstr)) ? ' - ' : '';
    return "I Do Imaging${sep}${outstr}";
  }


  /*
   * Return a <tr> filled in with summary of given program.
   * @param arr Hash of program details from 'programs' table
   */
  
  public static function make_tr_of_prog($arr) {
    $name  = $arr['name'];
    $ident = $arr['ident'];
    $summ  = $arr['summ'];
    $prog_url = "/program/$ident";
    $str = "<tr class='prog_summ'>\n";
    $str .= "<td><a href='$prog_url'>$name</a></td>\n";
    $str .= "<td></td>\n";    
    $str .= "</tr>  <!-- prog_summ -->\n";
    return $str;
  }

  public function print_admin_options() {
    foreach ($this->ADMIN_PROGS as $key => $vals) {
      $admin_desc = $vals[self::ADMIN_DESC];
      $admin_url  = $vals[self::ADMIN_URL];
      print "<a href=$admin_url>$admin_desc</a><br>\n";
    }
  }

  /*
   * Look for a static file 'foo.html' matching the program 'foo.pl' 
   * that would otherwise be called for this virtual_or_exec() target.
   * If found, print it and return true, otherwise return false.
   */
  
  public function print_static_file_for($target) {
    $targ_str = preg_replace('/[\/]*(\w+)[\/\?]*.*/', '$1', $target);
    $new_target = $this->REWRITE[$targ_str][self::REWRITE_TO];
    $html_file = preg_replace('/(.+).pl/', 'static/$1.html', $new_target);
    $ret = false;
    if (file_exists($html_file) and (filesize($html_file) > 1000)) {
      include($html_file);
      $ret = true;
    } 
    return $ret;
  }

}
?>
