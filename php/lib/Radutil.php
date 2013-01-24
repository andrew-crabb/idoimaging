<?php
error_reporting(E_ALL);
class Radutil {

  // ============================================================
  // Userbase
  // ============================================================
  const IDOIMAGING = '/Users/ahc/Dropbox/idoimaging';
  const USERBASE  = '/cgi-bin/userbase/userbase.cgi';

  // Fields returned by ubvars.
  const UB_USERNAME          = 'ub_username';
  const UB_USERID            = 'ub_userid';
  const UB_IS_MEMBER         = 'ub_is_member';
  const UB_IS_ADMIN          = 'ub_is_admin';
  const UB_REALNAME          = 'ub_realname';
  const UB_EMAIL             = 'ub_email';
  const UB_GROUP_MEMBERSHIPS = 'ub_group_memberships';
  const UB_GROUP_LIST        = 'ub_group_list';

  // Group names.
  const UB_GROUP_ADMIN       = 'admin';

  // State array indexes.
  const UB_STATE          = 'ub_state';         // Current state of the login.
  const UB_STRING         = 'ub_string';        // Identifying query_string
  const UB_HDR            = 'ub_hdr';           // Print full UB in page header?
  const UB_BODY           = 'ub_body';          // Print full UB in page body?
  const UB_CUST_MSG       = 'ub_cust_msg';      // Custom message to display in login box.
  const UB_CONT_NONE      = 'ub_none';          // Print no UB form.
  const UB_CONT_MINI      = 'ub_mini';          // Print mini UB form.
  const UB_CONT_FULL      = 'ub_full';          // Print full UB form.
  const UB_CONT_JUSTLINK  = 'ub_just_link';     // Just a login/logout link.

  // Userbase states.
  const UB_PENDING         = 'ub_pending';        // Account pending confirmation.
  const UB_PENDING_STR     = 'kmsg=';
  const UB_VERIFY          = 'ub_verify';         // 
  const UB_VERIFY_STR      = 'action=verify';
  const UB_EDIT_USER       = 'ub_edit_user';      // L/in.   Edit user details.
  const UB_EDIT_USER_STR   = 'action=edituser';
  const UB_EDIT_RSLT       = 'ub_edit_report';    // L/in.   Show status of editing user details.
  const UB_EDIT_RSLT_STR   = 'rslt=10';
  const UB_BAD_AUTH_MSG    = 'Invalid login, please try again';
  const UB_PW_RESET        = 'ub_pw_reset';       // L/out.  Password reset request
  const UB_PW_RESET_STR    = 'action=pwreset';    // Note: Will handle all 3 phases.
  const UB_SIGNUP          = 'ub_signup';         // L/out: Create account.
  const UB_SIGNUP_STR      = 'action=signup';
  const UB_UNKNOWN         = 'ub_unknown';
  const UB_UNKNOWN_STR     = 'ub_unknown_str';
  // Userbase phases.
  const UB_PHASE           = 'ub_phase';
  const UB_PHASE_STR       = 'phase=';  
  /*
  const UB_ERR_VER         = 'ub_err_ver';        // L/out.  Attempt log in, pending verify.
  const UB_ERR_VER_STR     = 'phase=eacctpndvrf';
  const UB_BAD_AUTH        = 'ub_bad_auth';       // L/out.  Bad authorization (failed login).
  const UB_BAD_AUTH_STR    = 'phase=ebadauth';
  const UB_ERR_PEND        = 'ub_err_pend';       // L/out: Error attempt login while pending.
  const UB_ERR_PEND_STR    = 'phase=eacctpndvrf';
  const UB_PW_SENT         = 'ub_pw_sent';        // L/out: PW reset email sent.
  const UB_PW_SENT_STR     = 'phase=spwrst';      // Note: Actually spwrst2
  */

  // Define which UserBase info to display on page header and body, for given state.
  public $ub_states = array (
    self::UB_UNKNOWN     => array (
      self::UB_STATE     => self::UB_UNKNOWN,
      self::UB_STRING    => self::UB_UNKNOWN_STR,
      self::UB_HDR       => self::UB_CONT_MINI,
      self::UB_BODY      => self::UB_CONT_NONE,
    ),
    self::UB_PENDING     => array (
      self::UB_STATE     => self::UB_PENDING,
      self::UB_STRING    => self::UB_PENDING_STR,
      // self::UB_HDR       => self::UB_CONT_MINI,
      self::UB_HDR       => self::UB_CONT_NONE,
      self::UB_BODY      => self::UB_CONT_FULL,
    ),
    self::UB_VERIFY      => array (
      self::UB_STATE     => self::UB_VERIFY,
      self::UB_STRING    => self::UB_VERIFY_STR,
      self::UB_HDR       => self::UB_CONT_MINI,
      self::UB_BODY      => self::UB_CONT_FULL,
    ),
    self::UB_EDIT_USER   => array (
      self::UB_STATE     => self::UB_EDIT_USER,
      self::UB_STRING    => self::UB_EDIT_USER_STR,
      // self::UB_HDR       => self::UB_CONT_MINI,
      self::UB_HDR       => self::UB_CONT_NONE,   // P/W reset (&id=99) mini edit user puts all fields
      self::UB_BODY      => self::UB_CONT_FULL,
    ),
    self::UB_EDIT_RSLT => array (
      self::UB_STATE     => self::UB_EDIT_RSLT,
      self::UB_STRING    => self::UB_EDIT_RSLT_STR,
      // self::UB_HDR       => self::UB_CONT_MINI,
      self::UB_HDR       => self::UB_CONT_NONE,
      self::UB_BODY      => self::UB_CONT_FULL,
    ),
    self::UB_PW_RESET    => array (
      self::UB_STATE     => self::UB_PW_RESET,
      self::UB_STRING    => self::UB_PW_RESET_STR,
      self::UB_HDR       => self::UB_CONT_MINI,
      self::UB_BODY      => self::UB_CONT_FULL,
    ),
    self::UB_SIGNUP      => array (
      self::UB_STATE     => self::UB_SIGNUP,
      self::UB_STRING    => self::UB_SIGNUP_STR,
      self::UB_HDR       => self::UB_CONT_MINI,
      self::UB_BODY      => self::UB_CONT_FULL,
    ),
    // ---- Phases ----
    self::UB_PHASE      => array (
      self::UB_STATE     => self::UB_PHASE,
      self::UB_STRING    => self::UB_PHASE_STR,
      self::UB_HDR       => self::UB_CONT_MINI,
      self::UB_BODY      => self::UB_CONT_FULL,
    ),
    // self::UB_ERR_VER     => array (
    // self::UB_STATE     => self::UB_ERR_VER,
    // self::UB_STRING    => self::UB_ERR_VER_STR,
    // self::UB_HDR       => self::UB_CONT_FULL,
    // self::UB_BODY      => self::UB_CONT_NONE,
    // ),
    /*
    self::UB_BAD_AUTH    => array (
      self::UB_STATE     => self::UB_BAD_AUTH,
      self::UB_STRING    => self::UB_BAD_AUTH_STR,
      self::UB_HDR       => self::UB_CONT_MINI,
      self::UB_BODY      => self::UB_CONT_NONE,
      self::UB_CUST_MSG  => self::UB_BAD_AUTH_MSG,
    ),
    self::UB_ERR_PEND     => array (
      self::UB_STATE     => self::UB_ERR_PEND,
      self::UB_STRING    => self::UB_ERR_PEND_STR,
      self::UB_HDR       => self::UB_CONT_NONE,
      self::UB_BODY      => self::UB_CONT_FULL,
    ),
    self::UB_PW_SENT     => array (
      self::UB_STATE     => self::UB_PW_SENT,
      self::UB_STRING    => self::UB_PW_SENT_STR,
      self::UB_HDR       => self::UB_CONT_MINI,
      self::UB_BODY      => self::UB_CONT_FULL,
    ),
    */
  );

  // ============================================================
  // Navigation Menus
  // ============================================================
  const NAV_HOME      = 0;
  const NAV_SEARCH    = 1;
  const NAV_PROGRAMS  = 2;
  const NAV_FORMATS   = 3;
  const NAV_RESOURCES = 4;
  const NAV_BLOG      = 5;
  const NAV_ABOUT     = 6;

  public $nav_menu_det = array (
    self::NAV_HOME      => array('Home'      , 'home'      ),
    self::NAV_SEARCH    => array('Search'    , 'finder'    ),
    self::NAV_PROGRAMS  => array('Programs'  , 'programs'  ),
    self::NAV_FORMATS   => array('Formats'   , 'formats'   ),
    self::NAV_RESOURCES => array('Resources' , 'resources' ),
    self::NAV_BLOG      => array('Blog'      , 'blog'      ),
    self::NAV_ABOUT     => array('About'     , 'about'     ),
				);

  // ------------------------------------------------------------
  // Site-specific details
  // ------------------------------------------------------------
  const LOCAL_SERVER    = '/^idoimaging$/';
  const REMOTE_SERVER   = 'idoimaging.com';
    
  const SITE_DEVEL      = 'site_devel';
  const SITE_ONLINE     = 'site_online';
  const SITE_UNKNOWN    = 'site_unknown';
  const SITE_WHICHHOST  = 'site_whichhost';

  // ------------------------------------------------------------
  // Database-specific details
  // ------------------------------------------------------------
  const DB_LOCAL    = 'db_local';
  const DB_LOCAL_UB = 'db_local_ub';
  const DB_MMC_UB   = 'db_mmc_ub';
  const DB_MMC      = 'db_mmc';
  const DB_SERVER   = 'db_server';
  const DB_HOST     = 'db_host';
  const DB_USER     = 'db_user';
  const DB_PASS     = 'db_pass';
  const DB_DATABASE = 'db_database';

  public $DB_DATA = array(
    self::DB_LOCAL => array(
      self::DB_HOST     => 'localhost',
      self::DB_USER     => '_www',
      self::DB_PASS     => 'PETimage',
      self::DB_DATABASE => 'imaging',
    ),
    self::DB_LOCAL_UB => array(
      self::DB_HOST     => 'localhost',
      self::DB_USER     => '_www',
      self::DB_PASS     => 'PETimage',
      self::DB_DATABASE => 'userbase',
    ),
    self::DB_MMC => array(
      self::DB_HOST     => 'idoimaging.macminicolo.net',
      self::DB_USER     => '_www',
      self::DB_PASS     => 'PETimage',
      self::DB_DATABASE => 'imaging',
    ),
    self::DB_MMC_UB => array(
      self::DB_HOST     => 'idoimaging.macminicolo.net',
      self::DB_USER     => '_www',
      self::DB_PASS     => 'PETimage',
      self::DB_DATABASE => 'userbase',
    ),
    self::DB_SERVER => array(
      self::DB_HOST     => 'db95a.pair.com',
      self::DB_USER     => 'acrabb',
      self::DB_PASS     => 'NEW2this',
      self::DB_DATABASE => 'acrabb_imaging',
    ),
  );

  // ------------------------------------------------------------
  // User details
  // ------------------------------------------------------------
  const USER_LOGGED_IN = 'user_logged_in';
  const LOGGED_OUT_STR = 'bye';

  // ------------------------------------------------------------
  // File details
  // ------------------------------------------------------------
  // const TEMPL_PATH        = 'email/templ';
  // const CONTENT_PATH      = 'email/cont';
  const CLI_DOCUMENT_ROOT = '/Users/ahc/public_html/idoimaging';
  const MY_CNF            = '/Users/ahc/.my.cnf';

  // ================================================================================
  // Functions
  // ================================================================================

  function __construct($util) {
    $this->util = $util;
    $this->debug = isset($_GET["dbg"]) ? true : false;
  }

  // ------------------------------------------------------------

  public function print_details() {
    //
  }

  // ------------------------------------------------------------

  public function host_connect( $host = self::DB_LOCAL, $verbose = 0 ) {
    $db_data = $this->DB_DATA[$host];
    $which_host = $this->which_host();

    $caller = Utility::my_caller();
    //error_log("Radutil::host_connect($host): $which_host: Caller $caller");

    // If on development machine, get DB details from my.cnf.
    if ($which_host == self::SITE_DEVEL) {
      $my_det = parse_ini_file(self::MY_CNF);
      $db_user = $my_det['user'];
      $db_pass = $my_det['password'];
    } else {
      $db_user = $db_data[self::DB_USER];
      $db_pass = $db_data[self::DB_PASS];
    }

    $dbh = mysql_pconnect($db_data[self::DB_HOST], $db_user, $db_pass)
	  or die('Could not connect: ' . mysql_error()); 
    mysql_select_db($db_data[self::DB_DATABASE]) or die('Could not select database $imaging');
    return $dbh;
  }

  // ------------------------------------------------------------

  public function make_nav_code($currpage = '') {
    $nav_code = $this->util->comment("========== Navigation code ==========");
    $nav_code .= "<div class='navcontainer'>\n";
    $nav_code .= "<ul class='step1 step2 step3 step4'>\n";
    
    foreach ($this->nav_menu_det as $page => $pagevals) {
      list($nav_text, $nav_action) = $pagevals;
      $id_str = $nav_text;
      str_replace("\s+", "_", $id_str);
      $id_spaces = substr("          ", 0, 10 - strlen($id_str));
      $classstr = '';
      if ($this->util->has_len($currpage)) {
        $classstr = ($page == $currpage) ? " class='active'" : "";
      }
      $spaces = substr("                       ", 0, 40 - strlen($nav_action));
      $astr = "<a href='/$nav_action'${spaces}>$nav_text</a>";
      $nav_code .= "<li id='$id_str'${classstr}${id_spaces}>$astr</li>\n";
    }
    
    $nav_code .= "</ul>\n";
    $nav_code .= "</div>   <!-- navcontainer -->\n";
    $nav_code .= $this->util->comment("========== End navigation code ==========");
    return $nav_code;
  }

  // ------------------------------------------------------------
  // Return hash of user details if logged in.
  // If run from command line, has only USER_LOGGED_IN => false, 

  public function get_user_details() {
    $document_root = $_SERVER['DOCUMENT_ROOT'];
    $ubvars = "${document_root}/login/ubvars.php";
    if ($this->util->is_cmd_line) {
      // For testing from command line, return dummy details.
      $user_details = array (
        self::UB_USERNAME          => '',
        self::UB_USERID            => '',
        self::UB_IS_ADMIN          => '',
        self::UB_IS_MEMBER         => '',
        self::UB_REALNAME          => '',
        self::UB_EMAIL             => '',
        self::UB_GROUP_MEMBERSHIPS => '',
        self::UB_GROUP_LIST        => '',
        self::USER_LOGGED_IN       => false,
			     );
    } else {
      // Run in Apache server environment
      require($ubvars);
      
      // Details directly from UserBase
      $user_details = array (
        self::UB_USERNAME          => isset($ub_username)          ? $ub_username          : '',
        self::UB_USERID            => isset($ub_userid)            ? $ub_userid            : '',
        self::UB_IS_ADMIN          => isset($ub_is_admin)          ? $ub_is_admin          : '',
        self::UB_IS_MEMBER         => isset($ub_is_member)         ? $ub_is_member         : '',
        self::UB_REALNAME          => isset($ub_realname)          ? $ub_realname          : '',
        self::UB_EMAIL             => isset($ub_email)             ? $ub_email             : '',
        self::UB_GROUP_MEMBERSHIPS => isset($ub_group_memberships) ? $ub_group_memberships : '',
        self::UB_GROUP_LIST        => isset($ub_group_list)        ? $ub_group_list        : '',
      );

      /*
      print Utility::tt_debug("Radutil::get_user_details(): $ubvars");
      print "<pre>\n";
      print_r($user_details);
      print "</pre>\n";
      */
      
      // Details derived from UserBase
      $user_details[self::USER_LOGGED_IN] = (isset($ub_userid) and strlen($ub_userid)) ? true : false;
    }

    // Return user details if logged in, else null.
    return $user_details;
  }

  // ------------------------------------------------------------

  public function current_state($verbose = false) {
    $query_string = $this->util->get_server_var(Utility::QUERY_STRING);
    $current_state = self::UB_UNKNOWN;
    foreach ($this->ub_states as $state => $state_det) {
      $search_str = $state_det[self::UB_STRING];
      if (strpos($query_string, $search_str) !== false) {
        // This is the state.
        $current_state = $state;
        break;
      }
    }
    $current_det = $this->ub_states[$current_state];
    return $current_det;
  }

  // ------------------------------------------------------------

  public function print_row_white_ctr($text) {
    print "<tr>\n<td class='white' width='100%' align='center'>\n";
    print "$text\n";
    print "</td>\n</tr>\n";
  }

  // ------------------------------------------------------------

  public function which_host($verbose = 0) {
    $server_details = $this->util->server_details;
    
    $which_host = '';
    if (isset($_SERVER['HTTP_HOST']) and Utility::has_len($_SERVER['HTTP_HOST'])) {
      // Apache environment.  LOCAL_SERVER here is the site name.
      $is_devel = preg_match(self::LOCAL_SERVER, $_SERVER['SERVER_NAME']);
      $which_host = ($is_devel) ? self::SITE_DEVEL : self::SITE_ONLINE;
    } else {
      // Command line environment.  LOCAL_SERVER here is the machine name.
      $is_online = false;
      if (isset($_SERVER['hostname'])) {
	$is_online = preg_match(self::LOCAL_SERVER, $_SERVER['hostname']);
	$which_host = ($is_online) ? self::SITE_ONLINE : self::SITE_DEVEL;
      }
    }

    if ($verbose) {
      error_log("Radutil::which_host(): returns $which_host");
    }
    return($which_host);
  }

  public function is_editing() {
    $curr_state_det = $this->current_state();
    $curr_state = $curr_state_det[self::UB_STATE];
    // $is_editing = (($curr_state != self::UB_UNKNOWN) and ($curr_state != self::UB_BAD_AUTH));
    $is_editing = ($curr_state != self::UB_UNKNOWN);
    return $is_editing;
  }

  /*
   * Test whether to print 'goodbye' message on front page.
   *
   * True if URL ends with LOGGED_OUT_STR, but did not come from 'goodbye' page.
   */

  public function do_print_goodbye() {
    $query_string = Utility::get_server_var(Utility::QUERY_STRING);
    $http_referer = Utility::get_server_var(Utility::HTTP_REFERER);
    $have_logged_out      = strpos($query_string, Radutil::LOGGED_OUT_STR) !== false;
    $came_from_logged_out = strpos($http_referer, Radutil::LOGGED_OUT_STR) !== false;
    $ret = ($have_logged_out and !$came_from_logged_out);
    // $str = "Radutil::do_print_goodbye(): qs $query_string, referer $http_referer,<br>have_logged_out $have_logged_out, came_from_logged_out $came_from_logged_out, returning $ret";
    // print Utility::tt_debug($str);
    return $ret;
  }

}
