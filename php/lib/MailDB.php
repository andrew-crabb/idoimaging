<?php
class MailDB {

  // Class constants
  const IDI_URL = 'http://www.idoimaging.com';
  const PROG    = 'program';
  // Maps rsrcfld to image path.
  const RSRC_TITLE      = "title";
  const RSRC_PROG       = "prog";
  const IMG_PROG_PATH   = "img/cap/prog";
  const IMG_TITLE_PATH  = "img/prog_title";
  // Email template
  const TEMPLATE_FIRSTLINE = "<!-- AHC_FIRSTLINE_CONTENT -->";
  const TEMPLATE_NEWS      = "<!-- AHC_NEWS_CONTENT -->";
  const TEMPLATE_COL_0     = "<!-- AHC_COL_0_CONTENT -->";
  const TEMPLATE_COL_1     = "<!-- AHC_COL_1_CONTENT -->";
  const SIDEBAR            = "SIDEBAR";
  const FIRSTLINE_DIV      = "first_line";
  const NEWS_DIV           = "news_content";
  const SIDEBAR_DIV        = "sidebar_content";
  // Section for generic add-monitor guide in place of program updates.
  const PROGRAM_NULL       = 'null';
  const MAX_IMAGE_HEIGHT   = 100;
  
  // Class variables
  public $util;
  public $all_subscribers;
  public $image_path;

  // ------------------------------------------------------------
  // Constructor
  
  function MailDB($verbose = false) {
    require_once 'simplehtmldom/simple_html_dom.php';
    $this->util = new Utility();
    $this->verbose = $verbose;
    $this->image_path = array(
      self::RSRC_TITLE => self::IMG_TITLE_PATH,
      self::RSRC_PROG  => self::IMG_PROG_PATH,
    );
  }

  // ------------------------------------------------------------

  function get_db_data($dbh_local) {
    $str = "select * from subscribers";
    $this->all_subscribers = $this->util->query_as_hash($dbh_local, $str, 'ident');
    
    return array($this->all_programs, $this->all_subscribers);
  }

  // ------------------------------------------------------------

  function get_db_counts($dbh) {
    $str = "select * from program where ident >= 100 and remdate like '0000%'";
    $nprog = $this->util->query_as_count($str);

    $str = "select * from version where adddate > date_add(curdate(), interval - 30 day)";
    $nver = $this->util->query_as_count($str);

    $str = "select * from version where adddate > date_add(curdate(), interval - 90 day)";
    $nqver = $this->util->query_as_count($str);

    print "$nprog programs, $nver versions last 30 days, $nqver versions last 90 days.\n";
    return array($nprog, $nver, $nqver);
  }

  // ------------------------------------------------------------
  // Create hash by version id of all versions in this period (may have duplicate programs).

  function make_versions_this_period_pdo($dbh, $days) {
    $period = "$days day";
    $perstr = "date_add(curdate(), interval - $period)";

    $str  = "select version.*";
    $str .= ", program.name as `program.name`";
    $str .= " from version, program";
    $str .= " where ((version.reldate > $perstr)";
    $str .= " or (version.adddate > $perstr))";
    $str .= " and (program.ident = version.progid)";
    $str .= " order by program.name, version.adddate desc";
    print "$str\n";
    $versions_this_period = $this->util->query_as_hash_pdo($dbh, $str, 'ident');

    if ($this->verbose) {
      print "MailDB::make_versions_this_period\n";
      $lines = array();
      foreach ($versions_this_period as $ident => $vals) {
	$lines[] = $vals;
      }
      $headings = array('ident', 'progid', 'version', 'reldate', 'adddate', 'name');
      $this->util->print_array_formatted($lines, true, "Versions this period", $headings);
    }

    return $versions_this_period;
  }

  // ------------------------------------------------------------

  function content_for_programs($prog_ids, $prog_imgs, $versions_this_period) {
    $html_str = "<table cellpadding='6' cellspacing='0' border='1' style='border-collapse:collapse;'>\n";
    $text_str = "";

    // Get first version for each program
    $ver_for_prog = array();
    foreach ($versions_this_period as $ver_id => $version) {
      $progid = $version['progid'];
      if (!isset($ver_for_prog[$progid])) {
        $ver_for_prog[$progid] = $version;
      }
    }

    // Row 0: Heading.
    $html_str .= "<tr>\n";
    $html_str .= "<td style='border:0px' colspan='2' align='middle'>\n";
    $html_str .= "<h4 id='new_progs_hdg'>New Version Releases</h4>\n";
    $html_str .= "</td>\n";
    $html_str .= "</tr>\n";

    // Rows 1-n: Program content.
    $summ = array();
    foreach (array_merge(array(null), $prog_ids) as $prog_id) {
      if (isset($prog_id)) {
	// Section for program.
	array_push($summ, array("program_${prog_id}"));
	$version = $ver_for_prog[$prog_id];
	list($html_part, $text_part) = $this->content_for_program($prog_id, $prog_imgs, $version);
      } else {
	// Section for add-monitor guide.
	array_push($summ, array('program_null'));
	list($html_part, $text_part) = $this->content_for_program();
      }
      $html_str .= $html_part;
      $text_str .= $text_part;
    }
    $this->util->print_array_formatted($summ, true, "content_for_programs");
    $html_str .= "</table>\n";
    return array($html_str, $text_str);
  }

  // ------------------------------------------------------------
  // Return HTML section for given program.
  // Return generic 'how to add monitor' section of prog_id is null.

  function content_for_program($prog_id = null, $prog_imgs = null, $version = null) {
    $html_str = '';
    $text_str = '';
    if (!isset($prog_id)) {
      $html_str = "*|INTERESTED:programs:program_" . self::PROGRAM_NULL . "null|*\n";
      $html_str .= "<!-- Content for program monitor guide -->\n";
      $html_str .= "<tr>\n";
      $html_str .= "<td colspan='2' style='background-color: #ffffff; border-left: 0px;' align='middle' valign='top'>\n";
      $html_str .= "This is the guide for adding a monitor to a program\n";
      $html_str .= "</td>\n";
      $html_str .= "</tr>\n";
      // Row 1, col 0
      $html_str .= "*|END:INTERESTED|*\n";
    } else {
      $prog_name = $version['program.name'];
      extract($version, EXTR_PREFIX_ALL, 'ver');
      $img_code = $this->code_for_image($prog_id, $prog_imgs);
      $prog_url = self::IDI_URL . "/" . self::PROG . "/$prog_id";
      $a_href = "<a href='${prog_url}'>";

      // ------------------------------------------------------------
      // HTML content
      // ------------------------------------------------------------
      // Program content in email is two tr's with text and image, enclosed by conditional includes.
      $html_str = "*|INTERESTED:programs:program_${prog_id}|*\n";
      $html_str .= "<!-- Content for program $prog_id ($prog_name) -->\n";
      $html_str .= "<tr>\n";

      // Col 0: image
      $html_str .= "<td style='background-color: #ffffff; border-left: 0px;' align='middle' valign='top'>\n";
      $html_str .= "${a_href}$img_code</a>\n";
      $html_str .= "</td>\n";

      // Col 1: text
      $html_str .= "<td style='background-color: #ffffff; border-left: 0px;' align='left' valign='top'>\n";
      $html_str .= "<strong>${a_href}$prog_name</a></strong><br>\n";
      $html_str .= "New version: $ver_version<br>\n";
      $html_str .= "Released: $ver_reldate<br>\n";
      $html_str .= "</td>\n";
      
      $html_str .= "</tr>\n";
      $html_str .= "*|END:INTERESTED|*\n";

      // ------------------------------------------------------------
      // Text content
      // ------------------------------------------------------------
      $text_str  = "*|INTERESTED:programs:program_${prog_id}|*\n";
      $text_str .= "Program: $prog_name\n";
      $text_str .= "New version: $ver_version, Released: $ver_reldate\n";
      $text_str .= "Link to program page: $prog_url\n";
      $text_str .= "*|END:INTERESTED|*\n";

    }
    // print "MailDB::content_for_program($prog_id): Returning $text_str\n";
    // $this->util->fprint($text_str);
      
    return array($html_str, $text_str);
  }

  // ------------------------------------------------------------

  function code_for_image($prog_id, $prog_imgs) {
    $imgstr = '';
    if (isset($prog_imgs[$prog_id]) && is_array($prog_imgs[$prog_id])) {
      $prog_img = $prog_imgs[$prog_id];
      // Fields: filename path rsrcfld rsrcname width height
      extract($prog_img, EXTR_PREFIX_ALL, 'img');
      if ($img_height > 100) {
        $factor = 100 / $img_height;
        print "*** scaling $img_filename by $factor from height of ($img_height, $img_width)";
        $img_height = intval($img_height * $factor);
        $img_width  = intval($img_width * $factor);
        print " to ($img_height, $img_width)\n";
      }
      if ($img_width > 150) {
        $factor = 150 / $img_width;
        print "*** scaling $img_filename by $factor from width of ($img_height, $img_width)";
        $img_height = intval($img_height * $factor);
        $img_width  = intval($img_width * $factor);
        print " to ($img_height, $img_width)\n";
      }
      $image_path = $this->image_path[$img_rsrcfld];
      $imgstr = "<img src='" . self::IDI_URL . "/${image_path}/${img_path}/${img_filename}'";
      $imgstr   .= " border='0' title='' alt='$img_rsrcname image'";
      $imgstr   .= " width='$img_width' height='$img_height' />";
    } else {
      $imgstr = '&nbsp;';
    }
    return $imgstr;
  }

  // ------------------------------------------------------------
  // Create an entry in the mail_sent DB table for each user receiving this email campaign.

  function update_mail_sent($campaign_id, $users_this_email) {
    foreach ($users_this_email as $userid) {
      $str  = "insert into mail_sent ";
      $str .= "set mc_ident = '$campaign_id', ";
      $str .= "user_id = '$userid'";
      print "$str\n";
      $result = mysql_query($str) or die("Query failed: " . mysql_error() . "\n");
    }
  }

}

