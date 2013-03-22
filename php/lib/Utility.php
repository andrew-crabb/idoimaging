<?php
error_reporting(E_ALL | E_STRICT);

/**
 * Functions applicable to all programs
 *
 * Provides functions not restricted to application, such as date
 * conversion, file input/output, string checking and testing, MySQL
 * access (though these should probably go into another class), and so
 * on.  This package is stored outside of the document_root for the web
 * sites and may be accessed using set_include_path().
 * @package Utility
 */

class Utility {
  /**
   * Boolean command line option
   */
  const OPTS_BOOL = 'opt_bool';
  const OPTS_NAME = 'opt_name'; // Long name.
  const OPTS_TEXT = 'opt_text'; // Help text.
  const OPTS_VALO = 'opt_valo'; // Value: Optional.
  const OPTS_VALR = 'opt_valr'; // Value: Required.
  const OPTS_DFLT = 'opt_dflt'; // Default value.
  const OPTS_CORQ = 'opt_corq'; // Co-requisite.
  const OPTS_CONF = 'opt_conf'; // Require confirmation.
  const OPTS_TYPE = 'opt_type'; // OPTS_CHAR, OPTS_VALR, OPTS_VALO.
  const OPTS_MODE = 'opt_mode'; // Major mode.
  const OPTS_OPTN = 'opt_optn'; // Option to major mode)
  const OPTS_KIND = 'opt_kind'; // OPTS_MODE, OPTS_OPTN

  const OPTS_ERR = 'opt_err';
  const OPTS_CNT = 'opt_cnt'; // Number of options set.

  // ------------------------------------------------------------
  // Constants for date conversion.
  // ------------------------------------------------------------

  const DATES_YYYY         = 'YYYY';
  const DATES_YY           = 'YY';
  const DATES_MM           = 'MM';
  const DATES_DD           = 'DD';
  const DATES_Y            = 'Y';
  const DATES_M            = 'M';
  const DATES_D            = 'D';
  const DATES_YYYY_MM_DD   = 'YYYY-MM-DD';
  const DATES_SQL          = 'SQL';
  const DATES_YYMMDD       = 'YYMMDD';
  const DATES_YYYYMMDD     = 'YYYYMMDD';
  const DATES_MM_DD_YY     = 'MM/DD/YY';
  const DATES_M_D_YY       = 'M/D/YY';
  const DATES_MMMM_DD_YYYY = 'MMMM DD YYYY';
  const DATES_DD_MMMM      = 'DD MMMM';
  const DATES_HR           = 'HR';
  const DATES_MN           = 'MN';
  const DATES_SC           = 'SC';
  const DATES_HRMN         = 'HRMN';
  const DATES_HR_MN        = 'HR:MN';
  /**
   * <kbd>11:10:09</kbd>
   */
  const DATES_HR_MN_SC     = 'HR:MN:SC';
  const DATES_HRMNSC       = 'HRMNSC';
  const DATES_HRMNSCDD     = 'HRMNSCDD';
  const DATES_DATETIME     = 'datetime';
  const DATES_DATE         = 'date';
  const DATES_SECS         = 'secs';
  const DATES_HRRTDATE     = 'hrrtdate';
  const DATES_HRRTFILE     = 'hrrtfile';
  /**
   * <kbd>YYMMDD_HHMMSS</kbd>
   */
  const DATES_HRRTDIR      = 'hrrtdir';
  const DATETIME_SQL       = 'SQL_datetime';

  // ------------------------------------------------------------
  // Constants for string formatting
  // ------------------------------------------------------------

  const STR_FMT          = 'str_fmt';           // Class of formatting.
  const STR_LCASE        = 'str_lcase';         // Lower case
  const STR_UCASE        = 'str_ucase';         // Upper case
  const STR_ONLYANUM     = 'str_onlyanum';      // Alphanumeric only (no punct or whitespace)

  // ------------------------------------------------------------
  // Environment variables.                     http    cmd line   note
  // ------------------------------------------------------------

  const ENV_HOSTNAME      = 'HOSTNAME';         // no       yes
  const ENV_SERVER_NAME   = 'SERVER_NAME';      // yes      no
  const ENV_DOCUMENT_ROOT = 'DOCUMENT_ROOT';    // yes      yes       FQ dir path
  const ENV_HOST          = 'HOST';             // yes      yes
  const ENV_USER          = 'USER';             // no       yes
  const ENV_HOME          = 'HOME';             // no       yes
  const ENV_PWD           = 'PWD';
  const QUERY_STRING      = 'QUERY_STRING';
  const HTTP_REFERER      = 'HTTP_REFERER';
  const REDIRECT_URL      = 'REDIRECT_URL';

  public $ENV_VARS = array(self::ENV_HOSTNAME, self::ENV_SERVER_NAME, self::ENV_DOCUMENT_ROOT, self::ENV_HOST, self::ENV_USER, self::ENV_HOME, self::ENV_PWD);

  // For testing files and directories.
  const TYPE_TYPE    = 'type_type';
  const TYPE_FILE    = 'file';
  const TYPE_DIR     = 'dir';

  // Misc
  const UTIL_IS_CLI  = 'util_is_cli';

  // ------------------------------------------------------------
  // Database constants
  // ------------------------------------------------------------
  
  const HOST_ANDY = 'andy';
  const HOST_LOCALHOST_USERBASE = 'localhost_userbase';
  const HOST_LOCALHOST_IMAGING  = 'localhost_imaging';
  const HOST_IDI_USERBASE       = 'idoimaging.com_userbase';
  const HOST_IDI_IMAGING        = 'idoimaging.com_imaging';

  const DB_HOST     = 'db_host';
  const DB_USER     = 'db_user';
  const DB_PASS     = 'db_pass';
  const DB_DATABASE = 'db_database';

  public $DB_DATA = array(
    self::HOST_IDI_USERBASE => array(
      self::DB_HOST     => 'idoimaging.com',
      self::DB_USER     => '_www',
      self::DB_PASS     => 'PETimage',
      self::DB_DATABASE => 'userbase',
    ),
    self::HOST_IDI_IMAGING => array(
      self::DB_HOST     => 'idoimaging.com',
      self::DB_USER     => '_www',
      self::DB_PASS     => 'PETimage',
      self::DB_DATABASE => 'imaging',
    ),
    self::HOST_LOCALHOST_USERBASE => array(
      self::DB_HOST     => 'localhost',
      self::DB_USER     => '_www',
      self::DB_PASS     => 'PETimage',
      self::DB_DATABASE => 'userbase',
    ),
    self::HOST_LOCALHOST_IMAGING => array(
      self::DB_HOST     => 'localhost',
      self::DB_USER     => '_www',
      self::DB_PASS     => 'PETimage',
      self::DB_DATABASE => 'imaging',
    ),
  );

  # ================================================================================
  # Functions
  # ================================================================================

  /**
   *
   */
  
  function __construct() {
    $this->server_details = $this->server_details();
    $this->debug = (isset($_GET["dbg"])) ? true : false;
    $server_name = getenv(self::ENV_SERVER_NAME);
    $this->is_cmd_line = (self::has_len($server_name)) ? false : true;
    $this->start_time = microtime(true);
    $this->timing_str = '';
    // use Time::HiRes 'gettimeofday'; $PREF{script_start_time_highres} = gettimeofday();
    // print STDERR "UBruntime=" . (gettimeofday() - $PREF{script_start_time_highres}) . "\n";
  }

  public function add_timing($txt = '') {
    $load_time = sprintf("%4.1f", microtime(true) - $this->start_time);
    $comma = (strlen($this->timing_str)) ? ', ': '';
    $colon = (strlen($txt)) ? ':': '';
    $this->timing_str .= "${comma}${txt}${colon} $load_time";
  }

  /**
   * Return array of standard environment variables
   *
   * The environment variables returned are:<br>
   * <kbd>HOSTNAME SERVER_NAME DOCUMENT_ROOT HOST USER HOME PWD</kbd>
   *
   * @param bool $verbose Print extra information
   */
  
  public function server_details($verbose = 0) {
    $details = array();
    foreach ($this->ENV_VARS as $env_name) {
      $env_val = getenv($env_name);
      $env_val = (isset($env_val) && strlen($env_val)) ? $env_val : '';
      $details{$env_name} = $env_val;
    }
    // Modify if run interactively on command line.
    if (self::has_len($details[self::ENV_HOME])) {
      $details[self::ENV_DOCUMENT_ROOT] = $details[self::ENV_HOME] . "/public_html";
      $details[self::UTIL_IS_CLI] = true;
    } else {
      $details[self::UTIL_IS_CLI] = false;
    }
    
    return $details;
  }

  /**
   *
   */

  public function print_details() {
    $this->pre($this->server_details, "Utility::server_details");
  }

  /**
   *
   */
  
  public static function has_len($var) {
    $ret = (isset($var) && strlen($var) && !($var === 'NULL')) ? 1 : 0;
    return $ret;
  }

  /**
   *
   */
  
  public function file_contents($infile) {
    $filesize = 0;
    $thedata = '';
    $infile = self::expand_tilde_path($infile);
    if (file_exists($infile) && ($fh = fopen($infile, 'r'))) {
      $filesize = filesize($infile);
      $thedata = fread($fh, $filesize);
      fclose($fh);
    }
    // echo "file_contents($infile) returning $filesize bytes\n";
    return $thedata;
  }

  /**
   * Expand tilde ~ in file paths.
   * Only defined in command line environments.
   */
  
  public static function expand_tilde_path($path) {
    if (isset($_SERVER['HOME'])) {
      $homedir = $_SERVER['HOME'];
      $newpath = preg_replace('|~[^/]*|', $homedir, $path);
      if (is_file($newpath)) {
        $newpath = realpath($newpath);
      }
    } else {
      // Shouldn't really be called from a web application.
      $newpath = $path;
    }
    return $newpath;
  }

  /**
   * Return given path as absolute (starts with '/')
   */

  public static function make_absolute_path($path) {
    // Tildes get expanded.
    $do_make_real = true;
    if (strpos($path, '~') === 0) {
      $newpath = self::expand_tilde_path($path);
    } elseif (strpos($path, '/') === 0) {
      $newpath = $path;
      $do_make_real = false;
    } else {
      $newpath = getcwd() . '/' . $path;
    }
    if ($do_make_real) {
      $newpath = realpath($newpath);
    }
    return $newpath;
  }

  /**
   *
   */
  
  public function file_contents_optional($infile, $required = 0, $verbose = 0) {
    if (self::has_len($infile)) {
      $content = $this->file_contents($infile);
      if (!strlen($content)) {
        throw new Exception("ERROR: Utility::file_contents_optional(): Cannot read content file $infile");
      }
    } else {
      $content = '';
    }
    if ($required) {
      if (!strlen($content)) {
        throw new Exception("ERROR: Input file $infile not found.");
      }
    }
    if ($verbose) {
      $len = strlen($content);
      print "Utility::file_contents_optional($infile) has length $len\n";
    }

    return $content;
  }

  /**
   * Convert given date into many formats
   *
   * Long description for this function.
   * 
   * @link expand_tilde_path() an unrelated link, again
   * @link DATES_HRRTDIR stuff for dates_hrrtdir
   * @param string $datestr Date in various formats:
   * <ul>
   * <li> <kbd>2011-10-09 11:10:09</kbd> (SQL format with time)
   * <li> <kbd>1325311078</kbd> (Unix epoch dates)
   * <li> <kbd>2003-12-15</kbd> or <kbd>12-15-2003</kbd> (Slash-delimited)
   * <li> <kbd>12/15/03</kbd> or <kbd>12/15/2003</kbd> (Dash-delimited)
   * </ul>
   * @param bool $verbose Talk a lot
   * @return array $dates
   * <ul>
   * <li> <kbd>111009_111009</kbd> ({@link DATES_HRRTDIR})
   * <li> {@link DATES_HR_MN_SC}
   * </ul>
   */
  
  public static function convert_dates($datestr, $verbose = 0) {

    $datestr = trim($datestr);
    if (strlen($datestr) == 0) {
      return '';
    }

    $months = array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec');

    // Take off time, if supplied in SQL format '2004-04-12 11:19:25'.
    // $datebits = explode(" ", $datestr);
    $datebits = preg_split('/[\ _]/', $datestr);
    $indate = $datebits[0];
    $intime = (count($datebits) > 1) ? $datebits[1] : '';

    // Special case: Allow time only, if in the form 9:30:00
    $timeonly = 0;
    if (preg_match("/^(\d{1,2}:)+(\d{1,2})$/", $indate) && !has_len($intime)) {
      $intime = $indate;
      $indate = "";
      $timeonly = 1;
      print "   time only: intime >${intime}<, indate >${indate}<\n";
    }

    $year = $month = $day = "";
    $hr = $mn = $sc = "";

    // ============================================================
    // Decode date field.
    // ============================================================

    date_default_timezone_set("America/New_York");
    if (preg_match('|^\d{9,10}$|', $indate)) {
      // Unix epoch-type times.
      $lt = localtime($indate, true);
      $sc = $lt['tm_sec'];
      $mn = $lt['tm_min'];
      $hr = $lt['tm_hour'];
      $day = $lt['tm_mday'];
      $month = $lt['tm_mon'];
      $year = $lt['tm_year'];
      $year += 1900;
      $month += 1;
    } elseif (preg_match('|^(\d{4})-(\d{1,2})-(\d{1,2})$|', $indate, $bits)) {
      // 2003-12-15
      $year  = $bits[1];
      $month = $bits[2];
      $day   = $bits[3];
    } elseif (preg_match('|^(\d{1,2})-(\d{1,2})-(\d{4})$|', $indate, $bits)) {
      // 12-15-2003
      $year  = $bits[3];
      $month = $bits[1];
      $day   = $bits[2];
    } elseif (preg_match('|^(\d{1,2})/(\d{1,2})/(\d{2,4})$|', $indate, $bits)) {
      // 12/15/03 or 12/15/2003
      $year  = $bits[3];
      $month = $bits[1];
      $day   = $bits[2];
    } elseif (preg_match('|^(\d{6})$|', $indate, $bits)) {
      // 031215
      $year  = substr($indate, 0, 2);
      $month = substr($indate, 2, 2);
      $day   = substr($indate, 4, 2);
    } elseif (preg_match('|^(\d{8})$|', $indate, $bits)) {
      // 20040812
      $year  = substr($indate, 0, 4);
      $month = substr($indate, 4, 2);
      $day   = substr($indate, 6, 2);
    } elseif (preg_match('|^(\d{1,2})-(\d{1,2})-(\d{1,2})$|', $indate, $bits)) {
      // 4-1-2 is 4/1/02 by idiots running Scanditronix.
      $year  = $bits[3];
      $month = $bits[1];
      $day   = $bits[2];
    } elseif (preg_match('|^(\d{4})\.(\d{1,2}).(\d{1,2}).(\d{1,2}).(\d{1,2}).(\d{1,2})|', $indate, $bits)) {
      // 2006.1.12.7.30.5 is Judd's brilliant way of encoding 2006-01-12 07:30:05
      $year  = $bits[1];
      $month = $bits[2];
      $day   = $bits[3];
      $hr    = $bits[4];
      $mn    = $bits[5];
      $sc    = $bits[6];
    } elseif (preg_match('|^(\d{2}):(\d{2}):(\d{4})|', $indate, $bits)) {
      // Interfile 26:04:2006
      $year  = $bits[3];
      $month = $bits[1];
      $day   = $bits[2];
    }
    if (!self::has_len($year) and !self::has_len($month) and !self::has_len($day)) {
      return '';
    }
    if (strlen($year) == 2) {
      $year += ($year < 50) ? 2000 : 1900;
    }

    // ============================================================
    // Decode time field.
    // ============================================================

    if (self::has_len($intime)) {
      if (preg_match('|(\d{6})\.(\d{2,3,6})|', $intime, $bits)) {
        $intime = $bits[1];
      } elseif (preg_match('|^(\d{1,2}):(\d{1,2}):(\d{1,2})$|', $intime, $bits)) {
        $hr = $bits[1];
        $mn = $bits[2];
        $sc = $bits[3];
      } elseif (preg_match('|^\d{6}$|', $intime)) {
        $hr = substr($intime, 0, 2);
        $mn = substr($intime, 2, 2);
        $sc = substr($intime, 4, 2);
      }
    }

    if (strlen($year) or $timeonly) {
      // my ($year2, $lmonth, $mo, $dy);
      $year  = sprintf("%04d", $year);
      $month = sprintf("%02d", $month);
      $day   = sprintf("%02d", $day);
      $year2 = sprintf("%02d", $year % 100);
      $lmonth = $months[$month - 1];
      $mo = sprintf("%d", $month);
      $dy = sprintf("%d", $day);
      $mdystr  = ($day == '00') ? '' : "${month}/${day}/${year2}";
      $mdysstr = ($day == '00') ? '' : "${mo}/${dy}/${year2}";
      $hr   = sprintf("%02d", $hr);
      $mn   = sprintf("%02d", $mn);
      $sc   = sprintf("%02d", $sc);

      $date_format = 'Y-m-d H:i:s';
      $date = DateTime::createFromFormat($date_format, "${year}-${month}-${day} ${hr}:${mn}:${sc}");
      $secs = $date->format('U');

      $dates = array(
        // Dates.
        self::DATES_YYYY          => $year,
        self::DATES_YY            => $year2,
        self::DATES_MM            => $month,
        self::DATES_DD            => $day,
        "date_array"               => array($year2, $month, $day),
        self::DATES_Y             => self::has_len($year2) ? sprintf("%d", $year2) : "",
        self::DATES_M             => self::has_len($month) ? sprintf("%d", $month) : "",
        self::DATES_D             => self::has_len($day)   ? sprintf("%d", $day) : "",
        self::DATES_YYYY_MM_DD    => "${year}-${month}-${day}",
        self::DATES_SQL           => "${year}-${month}-${day}",
        self::DATETIME_SQL        => "${year}-${month}-${day} ${hr}:${mn}:${sc}",
        self::DATES_YYMMDD        => "${year2}${month}${day}",
        self::DATES_YYYYMMDD      => "${year}${month}${day}",
        self::DATES_MM_DD_YY      => $mdystr,
        self::DATES_M_D_YY        => $mdysstr,
        self::DATES_MMMM_DD_YYYY  => "$lmonth $day, $year",
        self::DATES_DD_MMMM       => "$day $lmonth",
        // Times.
        self::DATES_HR            => self::has_len($hr) ? sprintf("%d", $hr) : "",
        self::DATES_MN            => self::has_len($mn) ? sprintf("%d", $mn) : "",
        self::DATES_SC            => self::has_len($sc) ? sprintf("%d", $sc) : "",
        self::DATES_HRMN          => "${hr}${mn}",
        self::DATES_HR_MN         => "${hr}:${mn}",
        self::DATES_HR_MN_SC      => "${hr}:${mn}:${sc}",
        self::DATES_HRMNSC        => "${hr}${mn}${sc}",
        self::DATES_HRMNSCDD      => "${hr}${mn}${sc}.00",
        // Miscellaneous.
        self::DATES_DATETIME      => "${month}/${day}/${year2} ${hr}:${mn}:${sc}",
        self::DATES_DATE          => "${month}/${day}/${year2}",
        self::DATES_SECS          => $secs,
        self::DATES_HRRTDATE      => sprintf("%4d.%d.%d", $year, $month, $day),
        self::DATES_HRRTFILE      => sprintf("%d.%d.%d.%d.%d.%d", $year, $month, $day, $hr, $mn, $sc),
        self::DATES_HRRTDIR       => "${year2}${month}${day}_${hr}${mn}${sc}",
      );
    }
    if ($verbose) {
      // print "Utility::convert_dates($datestr)\n";
      // print_r ($dates);
    }
    
    return $dates;
  }

  // ------------------------------------------------------------
  
  public function today($verbose = 0) {
    $today = $this->convert_dates(time());
    $fmtstr = self::DATES_YYYY_MM_DD;
    $ret = $today[$fmtstr];
    if ($verbose) {
      print "utilities::today(): returning $ret\n";
    }
    return $ret;
  }

  // ------------------------------------------------------------
  
  public function timenow($verbose = 0) {
    $today = $this->convert_dates(time());
    $fmtstr = self::DATES_DATETIME;
    $ret = $today[$fmtstr];
    if ($verbose) {
      print "utilities::today(): returning $ret\n";
    }
    return $ret;
  }

  // ------------------------------------------------------------

  public static function print_box($text) {
    $maxlen = -1;
    $lines = explode("\n", $text);
    print count($lines) . " lines\n";
    
    foreach ($lines as $line) {
      print "line $line\n";
      $maxlen = (strlen($line) > $maxlen) ? strlen($line) : $maxlen;
      
    }
    print "maxlen $maxlen\n";
    $dashes = "+" . str_pad("", $maxlen + 2, "-") . "+";
    $printlines[] = $dashes;
    foreach ($lines as $line) {
      $printlines[] =  "| "  . str_pad($line, $maxlen, " ") . " |";
    }
    $printlines[] = $dashes;
    print(join("\n", $printlines)) . "\n";
  }

  // ------------------------------------------------------------

  public function path_of_this_script() {
    $self = $_SERVER['PHP_SELF'];
    $pathbits = explode("/", $self);
    $path = join("/", array_slice($pathbits, 0, sizeof($pathbits) - 1));
    $this->fprint($path);
    return $path;
  }

  // ------------------------------------------------------------

  public function fprint($text) {
    $backtrace = debug_backtrace();
    $funcname = $backtrace[1]['function'];
    $class = $backtrace[1]['class'];
    print "------------------------------------------------------------\n";
    print "${class}::${funcname}(): Returning:\n";
    print "$text\n";
    print "------------------------------------------------------------\n";
  }

  // ------------------------------------------------------------

  public static function printr($object, $comment = '', $print_r = false, $to_logfile = false) {
    if ($to_logfile) {
      ob_start();
    }
    $is_http = isset($_SERVER['HTTP_HOST']);
    $eol = ($is_http) ? "<br>\n" : "\n";
    print "------------------------------------------------------------$eol";
    $backtrace = debug_backtrace();
    if (count($backtrace) < 2) {
      print "***  $comment  ***\n";
    }
    $comment = (strlen($comment)) ? ": $comment" : $comment;
    foreach (array_slice($backtrace, 1) as $indx => $det) {
      $funcname = $det['function'];
      $class = (isset($det['class'])) ? $det['class'] : '';
      $line = $det['line'];
      print "$indx: ${class}::${funcname}()$comment\n";
    }
    if ($print_r) {
      if ($is_http) {
	self::print_r_html($object);
      } else {
	print_r($object);
      }
      if (is_scalar($object)) {
        print "\n";
      }
    }
    print "------------------------------------------------------------$eol";

    $outstr = ob_get_contents();
    if ($to_logfile) {
      ob_end_clean();
      $lines = explode("\n", $outstr);
      foreach ($lines as $line) {
	if (strlen($line) > 2) {
	  error_log($line);
	}
      }
    } else {
      print($outstr);
    }
  }

  public static function print_r_html($object) {
    $output = '';
    $newline = "<br>";
    foreach($object as $key => $value) {
      if (is_array($value) || is_object($value)) {
	$value = "Array()" . $newline . "(<ul>" . self::print_r_html($value) . "</ul>)" . $newline;
      }
      $output .= "[$key] => " . $value . $newline;
    }
    print "$output\n";
    return $output;
  }

  // ------------------------------------------------------------
  // Test given filename for FQ existence, return if so.
  // Else, glob for given filename in given path, return FQ file if one match.
  // Else, glob for default nmae in given path, return FQ file if one match.
  // Else, return empty string
  // ------------------------------------------------------------  
  public function file_defined_or_glob($infile, $default_path, $default_name = '') {
    $infile = self::expand_tilde_path($infile);
    $ret = '';
    if (file_exists($infile)) {
      // FQ name supplied and matches: done.
      $this->printr($infile, "Case 0");
      $ret = $infile;
    } else {
      // Search in given path for given infile as pattern, then default pattern.
      $patterns = array($infile, $default_name);
      foreach ($patterns as $pattern) {
	// print "file_defined_or_glob($infile, $default_path, $default_name) start '$pattern'\n";
        if (self::has_len($pattern)) {
          $files_in_dir = $this->files_in_directory($default_path, $pattern);
          $nfiles = count($files_in_dir);
          if ($nfiles == 1) {
            $ret = $default_path . "/" . $files_in_dir[0];
            break;
          }
        }
      }
    }
    // print "file_defined_or_glob($infile, $default_path, $default_name) returning $ret\n";
    return $ret;
  }

  /*
   * Return array of files in given dir.
   *
   * @param string $pattern Pattern to match with preg
   * @param array $opts
   */

  public static function files_in_directory($dir, $pattern = '', $opts = '') {
    $test_for_dirs = false;
    if (is_array($opts)) {
      $opt_type = isset($opts[self::TYPE_TYPE]) ? $opts[self::TYPE_TYPE] : '';
      $test_for_dirs = ($opt_type == self::TYPE_DIR) ? true : false;
    }
    self::tt("dir = $dir");
    $dir = self::expand_tilde_path($dir);
    self::tt("dir = $dir");
    $matched_files = array();
    if ($handle = opendir($dir)) {
      $oldwd = getcwd();
      chdir($dir);
      while (($file = readdir($handle)) !== false) {
        // if (is_file($file)) {
        $right_type = ($test_for_dirs) ? is_dir($file) : is_file($file);
        if ($right_type) {
          // Include all files unless there is a pattern and it doesn't match.
          $pattern_has_len = self::has_len($pattern);
          $preg_matches = preg_match("/$pattern/i", $file);
          if (!($pattern_has_len && !$preg_matches)) {
            // Omit Emacs edits
            if (preg_match('/[A-Za-z0-9_]$/', $file)) {
              array_push($matched_files, $file);
            }
          }
        }
      }
      chdir($oldwd);
    } else {
      print "ERROR: Could not open directory $dir\n";
    }
    return $matched_files;
  }

  // ------------------------------------------------------------

  public static function comment($text) {
    $ret = "<!-- $text -->\n";
    return $ret;
  }

  // ------------------------------------------------------------
  
  public static function print_trace($max_depth = 0) {
    $backtrace = debug_backtrace();
    $det = array();
    $i = 0;
    $max_line = $max_file = $max_class = $max_fn = 0;
    foreach ($backtrace as $level => $vals) {
      if ($max_depth and ($i >= $max_depth)) {
	break;
      }
      // File and line come from the previous call
      $file     = array_key_exists('file', $vals) ? $vals['file'] : '';
      $line     = array_key_exists('line', $vals) ? $vals['line'] : '';
      if ($level < 1) {
        $lastfile = $file;
        $lastline = $line;
        continue;
      }
      $function = array_key_exists('function', $vals) ? $vals['function'] : '';
      $class    = array_key_exists('class', $vals) ? $vals['class'] : '';
      $classstr = strlen($class) ? "${class}::" : '';
      $path_parts = pathinfo($lastfile);
      $filename = $path_parts['basename'];
      $det[$i]['line'] = $lastline;
      $det[$i]['file'] = $filename;
      $det[$i]['class'] = $classstr;
      $det[$i]['function'] = $function;
      $max_line  = ($max_line  > strlen($lastline)) ? $max_line  : strlen($lastline);
      $max_file  = ($max_file  > strlen($filename)) ? $max_file  : strlen($filename);
      $max_class = ($max_class > strlen($classstr)) ? $max_class : strlen($classstr);
      $max_fn    = ($max_fn    > strlen($function)) ? $max_fn    : strlen($function);

      $lastfile = $file;
      $lastline = $line;
      $i++;
    }
    // error_log("Error in ${classstr}$function() in $filename line $lastline");
    $classlen = $max_class + $max_fn;
    $fmtstr = "%d: %-${classlen}s in %-${max_file}s line %${max_line}d";
    for ($j = 0; $j < $i; $j++) {
      $rec = $det[$j];
      $outstr = sprintf($fmtstr, $j, $rec['class'] . $rec['function'], $rec['file'], $rec['line']);
      error_log($outstr);
    }
  }

  // ------------------------------------------------------------
  // Given options structure, process command line options.

  function process_opts($allopts) {
    list($opt_string_short, $opt_array_long) = $this->make_opt_strings($allopts);

    // Read in the options.
    $opts = getopt($opt_string_short, $opt_array_long);
    // print "opts($opt_string_short): ";
    // var_dump($opts);

    // Process each opt and fill into options array.
    $options = array();
    $coreqs = array();
    $current_mode = '';
    $options[self::OPTS_CNT] = count($opts);
    $options[self::OPTS_ERR] = false;
    foreach ($allopts as $optkey => $optarr) {
      // Default values are handled first.
      if (isset($optarr[self::OPTS_DFLT])) {
        $options[$optkey] = $optarr[self::OPTS_DFLT];
      }

      if (isset($opts[$optkey])) {
        $optval = $opts[$optkey];
        $opttype = $optarr[self::OPTS_TYPE];
        $optname = $optarr[self::OPTS_NAME];

        // Get confirmation if required.
        if (isset($optarr[self::OPTS_CONF])) {
          if (!$this->get_confirmation($optarr[self::OPTS_TEXT])) {
            print "ERROR: confirmation required for option -$optkey ($optname)\n";
            $options[self::OPTS_ERR] = 1;
          }
        }

        // Ensure multiple major modes are not defined
        if (isset($optarr[self::OPTS_KIND])) {
          if (($optarr[self::OPTS_KIND] == self::OPTS_MODE) and strlen($current_mode)) {
            print "ERROR: Options -$current_mode and -$optkey may not be used together\n";
            $options[self::OPTS_ERR] = 1;
          } else {
            $current_mode = $optkey;
          }
        }

        // Gather co-requisites needed by this (set) option.
        if (isset($optarr[self::OPTS_CORQ])) {
          $coreqs[$optarr[self::OPTS_CORQ]][] = array($optkey => $optarr[self::OPTS_NAME]);
        }
	
        // If a boolean, being set evaluates to true.
        if ($opttype == self::OPTS_BOOL) {
          $optval = 1;
        } elseif (($opttype == self::OPTS_VALO) || ($opttype == self::OPTS_VALR)) {
          // If option set, check it has a value.
          if (!strlen($optval)) {
            $errstr = "Foo Bar\nERROR: No value set for option $optkey (" . $optarr[self::OPTS_TEXT] . ")";
            $this->print_box($errstr);
            $options[self::OPTS_ERR] = 1;
            return $options;
          }
        }
        $options[$optkey] = $optval;
      } else {
        // Set, but evaluates to false.
        $optval = isset($options[$optkey]) ? $options[$optkey] : '';
        $options[$optkey] =  self::has_len($optval) ? $optval : '';
      }
    }

    // Check co-requisites were satisfied.
    foreach ($coreqs as $needed_opt => $needed_by_arr) {
      if (!isset($opts[$needed_opt])) {
        // Setting self::OPTS_ERR will cause the program to exit.
        $needed_opt_str = $allopts[$needed_opt][self::OPTS_NAME];
        $needed_by_str = '';
        $sep = '';
        foreach ($needed_by_arr as $needed_by_elem) {
          foreach ($needed_by_elem as $needed_by_key => $needed_by_name) {
            $needed_by_str .= "${sep}-$needed_by_key ($needed_by_name)";
            $sep = ', ';
          }
        }
        print "ERROR: -$needed_opt ($needed_opt_str) is needed by $needed_by_str\n";
        $options[self::OPTS_ERR] = 1;
      }
    }

    // print $this->print_in_lines("Summary of set options");
    foreach ($options as $key => $val) {
      if ($val) {
        //        print "$key: $val\n";
      }
    }
    return $options;
  }

  // ------------------------------------------------------------

  function make_opt_strings($allopts) {
    $opt_string_short = '';
    $opt_array_long = array();
    foreach ($allopts as $letter => $opt) {
      $opt_name = $opt[self::OPTS_NAME];
      $opt_string_short .= $letter;
      if ($opt[self::OPTS_TYPE] == self::OPTS_VALO) {
        $opt_string_short .= '::';
        $opt_name .= '::';
      } elseif ($opt[self::OPTS_TYPE] == self::OPTS_VALR) {
        $opt_string_short .= ':';
        $opt_name .= ':';
      }
      array_push($opt_array_long, $opt_name);
    }
    // print "make_opt_string: Returning >${opt_string_short}<\n";
    return array($opt_string_short, $opt_array_long);
  }

  // ------------------------------------------------------------
  function usage($allopts) {
    $script_name = $_SERVER["SCRIPT_NAME"];
    $path_bits = explode("/", $script_name);
    $prog_name = end($path_bits);
    print "Usage: $prog_name\n";
    ksort($allopts);

    $maxlen = 0;
    $has_val = 0;

    foreach ($allopts as $letter => $opt) {
      // Max name length, for printf format string.
      $len = strlen($opt[self::OPTS_NAME]);
      $maxlen = ($len > $maxlen) ? $len : $maxlen;
      // Whether any opt has a value.
      $opt_type = $opt[self::OPTS_TYPE];
      $has_val += (($opt_type == self::OPTS_VALO) || ($opt_type == self::OPTS_VALR)) ? 1 : 0;
    }
    $val_space = ($has_val) ? '%5s' : '';
    $fmtstr = "%s -%s ${val_space} --%-${maxlen}s:  %s\n";
    // print "fmtstr($fmtstr)\n";
    
    foreach ($allopts as $letter => $opt) {
      $opt_name = $opt[self::OPTS_NAME];
      $opt_type = $opt[self::OPTS_TYPE];
      $requires_val = ($opt_type == self::OPTS_VALR) ? '*' : ' ';
      if (isset($opt[self::OPTS_DFLT])) {
        $val = $opt[self::OPTS_DFLT];
        $default_str = ($val === true) ? 'true' : ($val === false) ? 'false' : $val;
        $default_text = " (default: $default_str)";
      } else {
        $default_text = '';
      }
      $coreq_text = (isset($opt[self::OPTS_CORQ])) ? ' (requires: -' . $opt[self::OPTS_CORQ] . ')' : '';
      $opt_text = $opt[self::OPTS_TEXT] . $default_text . $coreq_text;
      if ($has_val) {
        if (($opt_type == self::OPTS_VALO) || ($opt_type == self::OPTS_VALR)) {
          printf($fmtstr, $requires_val, $letter, '<val>', $opt_name, $opt_text);
        } else {
          printf($fmtstr, $requires_val, $letter, '     ', $opt_name, $opt_text);
        }
      } else {
        printf($fmtstr, $requires_val, $letter, $opt_name, $opt_text);
      }
    }
  }

  // ------------------------------------------------------------

  /**
   * Print summary of options.
   */

  public function print_opts($opts, $allopts) {
    $all_lines = array();
    foreach ($opts as $key => $val) {
      if (strlen($val)) {
	$desc = (isset($allopts[$key][self::OPTS_TEXT])) ? $allopts[$key][self::OPTS_TEXT] : '';
	array_push($all_lines, array($key, $val, $desc));
      }
    }
    if (count($all_lines)) {
      print "Non zero-length options:\n";
    }
    $this->print_array_formatted($all_lines, true);
  }

  public static function print_array_formatted($arr, $bars = false, $title = null, $headings = null) {
    $lengths = array();
    $i = 0;
    $test_arr = $arr;
    if (isset($headings)) {
      array_push($test_arr, $headings);
    }
    foreach ($test_arr as $entry) {
      $i = 0;
      foreach ($entry as $elem) {
	$len = strlen($elem);
	if (isset($lengths[$i])) {
	  $lengths[$i] = max($lengths[$i], $len);
	} else {
	  $lengths[$i] = $len;
	}
	$i++;
      }
    }

    $fmtstr = ($bars and $i) ? '| ' : '';
    $space = '';
    foreach ($lengths as $length) {
      $fmtstr .= "${space}%-${length}s";
      $space = ($bars) ? ' | ' : ' ';
    }
    $fmtstr .= ($bars and strlen($fmtstr)) ? " | \n" : "\n";

    $lines = '';
    if ($bars and strlen($fmtstr)) {
      $lines = '+';
      foreach ($lengths as $length) {
	for ($j = 0; $j < ($length + 2); $j++) {
	  $lines .= '-';
	}
	$lines .= '+';
      }
      $lines .= "\n";
    }

    if (isset($title)) {
      $totlen = strlen($lines) ? strlen($lines) : array_sum($lengths) + count($lengths);
	$totlen;
      $titlen = strlen($title);
      // print "totlen $totlen titlen $titlen\n";
      $spc_before = intval(($totlen - $titlen) / 2);
      $spc_after = $totlen - $titlen - $spc_before - 1;
      $titfmt = "%-${spc_before}s%s%${spc_after}s";
      // print "titfmt '$titfmt'\n";
      print $lines;
      printf("$titfmt\n", '|', $title, '|');
    }

    if (isset($headings) and count($headings)) {
      print $lines;
      vprintf($fmtstr, $headings);
    }

    print $lines;
    foreach ($arr as $entry) {
      vprintf($fmtstr, $entry);
    }
    print $lines;

  }

  // ------------------------------------------------------------

  /**
   * Get yes or no response to given prompt, return boolean.
   */

  public function get_confirmation($text) {
    $ans = readline("Confirm: ${text} (y/N) : ");
    $go = (preg_match('/^[Yy]/', $ans) == 1);
    return $go;
  }

  // ------------------------------------------------------------

  public static function tt($str) {
    return "<tt>${str}</tt><br />\n";
  }

  // ------------------------------------------------------------

  public static function tt_debug($str, $doprint = true) {
    return ($doprint) ? "<tt class='red'>${str}</tt><br />\n" : "";
  }

  // ------------------------------------------------------------
  
  public function pre($str, $comment = '') {
    $str = (is_array($str)) ? print_r($str, true) : $str;
    print "<pre>\n$comment\n$str</pre>\n<br />\n";
  }

  // ------------------------------------------------------------

  public function write_file($filename, $lines, $mode = 'w') {
    if (is_array($lines)) {
      $nlines = count($lines);
      $outstr = implode("", $lines);
    } else {
      $outstr = $lines;
    }
    if ($handle = fopen($filename, $mode)) {
      fwrite($handle, $outstr);
    } else {
      self::tt("ERROR: Utility::write_file($filename)");
    }
  }
  
  // ------------------------------------------------------------
  // Writes file with given content and names, and a PHP file with a HTTP header
  // redirecting to that file.  Returns URL of the PHP file.

  public function write_file_download($file_url, $full_filename, $lines) {
    $this->write_file($full_filename, $lines);
    // Get just the name of the file, since it will be in the same directory.
    $filename_parts = pathinfo($full_filename);
    $filename = $filename_parts['basename'];
    $php_contents = "<?php\n";
    $php_contents .= "header('Content-disposition: attachment; filename=$filename');\n";
    // This file type is recommended but it adds a '.txt' to the .php file.
    // $php_contents .= "header('Content-type: text/plain');\n";
    $php_contents .= "header('Content-type: application/octet-stream');\n";
    $php_contents .= "readfile('$filename');\n";
    $php_contents .= "?>\n";

    $php_file = preg_replace('/\..+$/', '.php', $full_filename);
    $php_url  = preg_replace('/\..+$/', '.php', $file_url);
    // self::tt("Utility::write_file_download()");
    // self::tt("> full_filename: $full_filename");
    // self::tt("> php_file: $php_file");
    // self::tt("> file_url: $file_url");
    // self::tt("> php_url: $php_url");
    // self::tt("> filename: $filename");
    $this->write_file($php_file, $php_contents);
    return $php_url;
  }
  
  // ------------------------------------------------------------

  public function print_in_lines($str = '') {
    $line = "------------------------------------------------------------";
    $linelen = strlen($line);
    $strlen = strlen($str);
    $outline = $line;
    if ($strlen) {
      $halflen = (strlen($line) - $strlen - 4) / 2;
      $halfline1 = $halfline2 = substr($line, 0, $halflen);
      if ($strlen % 2) {
        $halfline2 .= '-';
      }
      $outline = "$halfline1  $str  $halfline2";
    }
    $outline .= $this->is_cmd_line ? "\n" : "<br />\n";
    
    return $outline;
  }

  // ------------------------------------------------------------
  // Test for and return the given _SERVER var.
  // Returns the _SERVER var if set, else '' (which tests false).

  public static function get_server_var($var = '') {
    $ret = '';
    if (isset($_SERVER[$var])) {
      $ret = $_SERVER[$var];
    }
    return $ret;
  }

  public static function elem_of($arr, $index) {
    $ret = (isset($arr[$index])) ? $arr[$index] : '';
    return $ret;
  }

  public static function format_string($str, $fmt) {
    $oldstr = $str;
    $all_formats = (is_array($fmt)) ? $fmt : array($fmt);
    // Apply each format in turn to input string.
    foreach ($all_formats as $format) {
      if ($format == self::STR_LCASE) {
        $str = strtolower($str);
      }
      if ($format == self::STR_UCASE) {
        $str = strtoupper($str);
      }
      if ($format == self::STR_ONLYANUM) {
        $str = preg_replace('/[^A-Za-z0-9]/', '', $str);
      }
    }
    return $str;
  }

  /**
   * Test if variable has a value.
   *
   * @return true if var is nonzero-length strong, or nonempty array.
   */

  public static function has_value($var) {
    return (isset($var) and ((is_string($var) and strlen($var)) or (is_array($var) and count($var))));
  }

  /**
   * Read a certain number of bytes from start of file.
   *
   */

  public static function read_bytes($filename, $num) {
    $handle = fopen($filename, 'r');
    $buff = fread($handle, $num);
    fclose($handle);
    return $buff;
  }

  public static function parse_lines_by_sep($lines, $separator) {
    $hash = array();
    $all_lines = (is_array($lines)) ? $lines : explode("\n", $lines);
    foreach ($all_lines as $line) {
      $bits = self::parse_line_by_sep($line, $separator);
      if (count($bits) == 2) {
        if (strlen($bits[0])) {
          $hash[$bits[0]] = $bits[1];
        }
      }
    }
    // print "Utility::parse_lines_sep:\n";
    // print_r($hash);
    return $hash;
  }

  /*
   * Parse a line by given separator.
   * 
   * @return Array of [key => value].
   * Note either key or value may be zero length.
   */

  public static function parse_line_by_sep($line, $separator) {
    $parts = explode($separator, $line);
    $ret = array();
    if (count($parts) == 2) {
      $val = trim($parts[1]);
      $val = (strlen($val)) ? $val : '';
      $key = trim($parts[0]);
      $key = (strlen($key)) ? $key : '';
      $ret = array($key, $val);
    }
    return $ret;
  }

  public static function print_hash($arr, $to_err = false, $comment = '') {
    $keys = array_keys($arr);
    $klengths = array_map('strlen', $keys);
    $key_len_max = max($klengths);

    $vals = array_values($arr);
    $vlengths = array_map('strlen', $vals);
    $val_len_max = max($vlengths);

    $linelen = $key_len_max + $val_len_max + 4;
    $lines = str_repeat('-', $linelen);
    $caller = self::my_caller();
    if ($to_err) {
      error_log($lines);
      error_log("Utility::print_hash(): $caller");
    } else {
      print "$lines\n";
      print "Utility::print_hash(): $caller\n";
    }
    
    foreach ($arr as $key => $val) {
      $str = sprintf("%-${key_len_max}s : %s", $key, $val);
      if ($to_err) {
	error_log($str);
      } else {
	print "$str\n";
      }
    }
  }

  /**
   * Perform MySQL query and return all rows in hash indexed by given field.
   */

  public function host_connect( $host, $verbose = 0 ) {
    $db_data = $this->DB_DATA[$host];

    // print "Utility::host_connect(" . $db_data[self::DB_HOST] . ", " . $db_data[self::DB_USER] . ", " . $db_data[self::DB_PASS] . ", " . $db_data[self::DB_DATABASE] . ")\n";
    $dbh = mysql_connect($db_data[self::DB_HOST], $db_data[self::DB_USER], $db_data[self::DB_PASS], true) or die('Could not connect: ' . mysql_error());
    mysql_select_db($db_data[self::DB_DATABASE], $dbh) or die('Could not select database $imaging');
    return $dbh;
  }

  public function host_connect_pdo( $host, $verbose = 0 ) {
    $db_data = $this->DB_DATA[$host];

    try {
      $dbname = "mysql:dbname=" . $db_data[self::DB_DATABASE] . "; host=localhost";
      $dbh = new PDO($dbname, $db_data[self::DB_USER], $db_data[self::DB_PASS]);
    } catch (PDOException $ex) {
      echo "Connection failed: " . $ex->getMessage();
    }
    return $dbh;
  }

  // ------------------------------------------------------------
  // Database functions.
  // ------------------------------------------------------------

  /**
   * Perform MySQL query and return all rows in hash indexed by given field.
   */
  
  public function query_as_hash( $dbh, $str, $keyfield ) {
    $ret = array();
    $result = mysql_query($str) or die("Query failed: " . mysql_error() . "\n");
    while ($row = mysql_fetch_array($result, MYSQL_ASSOC)) {
      $ret[$row[$keyfield]] = $row;
    }
    mysql_free_result($result);
    return $ret;
  }

  public function query_as_hash_pdo( $dbh, $str, $keyfield ) {
    $ret = array();
    // print "query_as_hash_pdo():\n$str\n";
    try {
      $result = $dbh->query($str);
    } catch (PDOException $ex) {
      echo ("Query failed: " . $ex->getMessage() . "\n");
    }
    while ($row = $result->fetch(PDO::FETCH_ASSOC)) {
      $ret[$row[$keyfield]] = $row;
    }
    return $ret;
  }

  /**
   * Perform MySQL query and return all rows in array.
   */

  public static function query_as_array( $dbh, $str ) {
    $ret = array();
    $result = mysql_query($str) or die("Query failed: " . mysql_error() . "\n");
    while ($row = mysql_fetch_array($result, MYSQL_ASSOC)) {
      array_push($ret, $row);
    }
    mysql_free_result($result);
    return $ret;
  }

  public function query_as_count( $str ) {
    $result = mysql_query($str) or die("Query failed: " . mysql_error() . "\n");
    return mysql_num_rows($result);
  }

  public static function query_issue_pdo($dbh, $str ) {
    try {
      $result = $dbh->query($str);
    } catch (PDOException $ex) {
      echo ("Query failed: " . $ex->getMessage() . "\n");
    }
    return $result;
  }

  public static function query_issue($dbh, $str ) {
    $result = mysql_query($str, $dbh) or die("Query failed: " . mysql_error() . "\n");
    return $result;
  }

  public static function make_db_condition_string($details, $sep = ', ', $keys = '', $skip = false, $oper = '=') {
    $str = "";
    $separator = "";
    $indices = (is_array($keys)) ? $keys : array_keys($details);
    foreach ($indices as $index) {
      $val = Utility::elem_of($details, $index);
      // Omit empty values if required.
      if (!$skip or strlen($val)) {
	$str .= " ${separator} $index $oper '$val'";
	$separator = $sep;
      }
    }
    $str = preg_replace('/\s+/', ' ', $str);
    return $str;
  }

  public static function find_in_db($dbh, $table, $details, $skip_empty = true, $use_like = false) {
    $oper = ($use_like) ? 'like' : '=';
    $cond_str = self::make_db_condition_string($details, "and", '', $skip_empty, $oper);
    $str =  "select * from $table";
    $str .= " where $cond_str";
    //  error_log("Utility::find_in_db(): $str");
    $recs = self::query_as_array($dbh, $str);
    return $recs;
  }

  public static function add_to_db($dbh, $table, $details) {
    $cond_str = self::make_db_condition_string($details, ",", '', true);
    $str  = "insert into $table";
    $str .= " set $cond_str";
    error_log( "$str");
    error_log(self::my_caller());
    $ret = self::query_issue($dbh, $str);
    return $ret;
  }

  public static function update_db_rec($dbh, $table, $details) {
    $cond_str = self::make_db_condition_string($details, ",");
    $str  = "insert into $table";
    $str .= " set $cond_str";
    error_log( "$str");
    error_log(self::my_caller());
    $ret = self::query_issue($dbh, $str);
    return $ret;
  }

  public static function db_insert_id() {
    $id = mysql_insert_id();
    return $id;
  }

  public static function showvar($var) {
    $val = (isset($_REQUEST[$var])) ? $_REQUEST[$var] : '';
    echo $val;
  }
  
  public static function my_caller() {
    $trace = debug_backtrace();
    if (isset($trace[2])) {
      $fn = $trace[2];
      $fn_fn    = (isset($fn['function'])) ? $fn['function'] : '';
      $fn_line  = (isset($fn['line']))     ? $fn['line']     : '';
      $fn_class = (isset($fn['class']))    ? $fn['class']    : '';
      $str = "Called from $fn_class:$fn_fn() (line $fn_line)";
    } else {
      $str = "Utility::my_caller(): trace[2] not set";
    }
    return $str;
  }

}
?>
