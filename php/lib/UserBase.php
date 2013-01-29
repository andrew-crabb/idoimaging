<?php
error_reporting(E_ALL|E_STRICT);

$curr_dir = realpath(dirname(__FILE__));
set_include_path(get_include_path() . PATH_SEPARATOR . "${curr_dir}/../lib");
require_once 'Utility.php';

require_once 'Radutil.php';

/**
 * @package UserBase
 * Accesses and modifies the 'userbase' database.
 */

class UserBase {
  const USERS    = 'userbase_users';
  // Fields within userbase_users
  const ID       = 'id';
  const USERNAME = 'username';
  const NAME     = 'name';
  const EMAIL    = 'email';
  const CDATE    = 'cdate';
  const MC_IDENT = 'mc_ident';

  public $UB_FIELDS = array(self::ID, self::USERNAME, self::NAME, self::EMAIL, self::CDATE, self::MC_IDENT);
  
  function __construct() {
    $this->util = new Utility();
    $this->rad  = new Radutil($this->util);
    // Changed this 10/30/12 to always use the server UB database.
    // $db_det = ($this->rad->which_host() == Radutil::SITE_DEVEL) ? Radutil::DB_MMC_UB : Radutil::DB_LOCAL_UB;
    $db_det = Radutil::DB_MMC_UB;
    $this->dbh = $this->rad->host_connect($db_det);
  }

  function get_user_info($email) {
    $ret = array();
    $str  = "select * from " . self::USERS;
    $str .= " where " . self::USERNAME . " = '$email'";
    print "$str\n";
    $user_info = $this->util->query_as_hash($this->dbh, $str, self::ID);
    $keys = array_keys($user_info);
    if (isset($keys[0])) {
      $key0 = $keys[0];
      $ret = $user_info[$key0];
    } else {
      $ret = '';
    }
    return $ret;
  }

  function list_users() {
    $ret = array();
    $str  = "select * from " . self::USERS;
    $user_info = $this->util->query_as_hash($this->dbh, $str, self::ID);
    return $user_info;
  }

  function delete_user($email) {
    $str  = "delete from " . self::USERS;
    $str .= " where " . self::USERNAME . " = '$email'";
    print "$str\n";
    $rslt = $this->util->query_issue($this->dbh, $str);
    return($rslt);
  }

  /**
   * Add mailchimp id user to UserBase field MC_IDENT
   *
   */

  function add_mc_to_user($email, $mc_ident = '') {
    $sql_str  = "update " . self::USERS;
    $sql_str .= " set " . self::MC_IDENT . " = '$mc_ident'";
    // $sql_str .= " where " . self::EMAIL . " = '$email'";
    $sql_str .= " where " . self::USERNAME . " = '$email'";
    // print "UserBase::add_mc_to_user(): $sql_str\n";
    $this->util->query_issue($this->dbh, $sql_str);
    
  }
}
  
?>
