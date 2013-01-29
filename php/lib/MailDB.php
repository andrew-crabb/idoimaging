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

  // Class variables
  public $util;
  public $all_programs;
  public $all_subscribers;
  public $image_path;

  // ------------------------------------------------------------
  // Constructor
  
  function MailDB() {
    require_once 'Utility.php';
    require_once 'simplehtmldom/simple_html_dom.php';
    $this->util = new Utility();
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

  function make_versions_this_period($dbh, $days) {
    $period = "$days day";
    $perstr = "date_add(curdate(), interval - $period)";

    $str  = "select version.* ";
    $str .= "from version, program ";
    $str .= "where ((version.reldate > $perstr) ";
    $str .= "or (version.adddate > $perstr)) ";
    $str .= "and (program.ident = version.progid) ";
    $str .= "order by program.name, version.adddate desc";
    print "$str\n";
    $versions_this_period = $this->util->query_as_hash($dbh, $str, 'ident');
    return $versions_this_period;
  }

  // ------------------------------------------------------------

  function add_content_to_template($template_str, $user_content, $program_content) {
    // Use simpleDOM to extract news and sidebar DIV contents
    $dom_doc = str_get_html($user_content);
    $news_content    = $dom_doc->find("div[id=" . self::NEWS_DIV    . "]");
    $sidebar_content = $dom_doc->find("div[id=" . self::SIDEBAR_DIV . "]");

    if (!(count($news_content) && count($sidebar_content))) {
      $this->util->printr("ERROR: missing " . self::NEWS_DIV . " or " . self::SIDEBAR_DIV);
      exit;
    }
    
    print "news_content has length " . strlen($news_content[0]) . "\n";
    print "sidebar_content has length " . strlen($sidebar_content[0]) . "\n";

    // Note replacing the marker string with an empty string is OK.
    $email_str = $template_str;
    $email_str = str_replace(self::TEMPLATE_NEWS , $news_content[0]   , $email_str);
    $email_str = str_replace(self::TEMPLATE_COL_0, $sidebar_content[0], $email_str);
    $email_str = str_replace(self::TEMPLATE_COL_1, $program_content   , $email_str);
    return $email_str;
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
    foreach ($prog_ids as $prog_id) {
      $version = $ver_for_prog[$prog_id];
      list($html_part, $text_part) = $this->content_for_program($prog_id, $prog_imgs, $version);
      $html_str .= $html_part;
      $text_str .= $text_part;
    }

    $html_str .= "</table>\n";
    return array($html_str, $text_str);
  }

  // ------------------------------------------------------------

  function content_for_program($prog_id, $prog_imgs, $version) {
    $prog_name = $this->all_programs[$prog_id]['name'];
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
    // Row 0, col 0
    $html_str .= "<tr>\n";
    $html_str .= "<td id='r0c0' style='background-color: #fafafe; border-bottom: 0px; border-right: 0px;'>\n";
    $html_str .= "${a_href}<strong>$prog_name</strong></a>\n";
    $html_str .= "</td>\n";
    // Row 0 and 1, col 1
    $html_str .= "<td id='r1c1' style='background-color: #ffffff; border-left: 0px;' rowspan='2' align='middle' valign='top'>\n";
    $html_str .= "${a_href}$img_code</a>\n";
    $html_str .= "</td>\n";
    $html_str .= "</tr>\n";
    // Row 1, col 0
    $html_str .= "<tr>\n";
    $html_str .= "<td id='r1c0' style='background-color: #fafafe;border-top: 0px;border-right: 0px;'>\n";
    $html_str .= "<strong>New version:</strong><br>${ver_version}<br><strong>Released:</strong><br>$ver_reldate\n";
    $html_str .= "</td>\n";
    $html_str .= "</tr>\n";
    $html_str .= "*|END:INTERESTED|*\n";

    // ------------------------------------------------------------
    // Text content
    // ------------------------------------------------------------
    $text_str  = "*|INTERESTED:programs:program_${prog_id}|*\n";
    $text_str .= "Program: $prog_name\n";
    $text_str .= "New version: $ver_version, Released: $ver_reldate\n";
    $text_str .= "Link to program page: $prog_url\n\n";
    $text_str .= "*|END:INTERESTED|*\n";

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
  // Create an entry in the mail_group DB table for this email campaign.
  // mail_group fields:
  // ident    : Ordinal id of this mail_group entry
  // mc_ident : MailChimp ident of the email campaign
  // datetime : Created by my program, part of campaign name
  // prog_str : All programs included in this campaign as csv: 'prog_200,prog_212,prog_300'
  
  function update_mail_group($campaign_id, $time_now, $group_names_str) {
    // datetime format is 'YYYY-MM-DD HH:MM:SS'
    $datetime = $time_now[Utility::DATETIME_SQL];
    
    $str  = "insert into mail_group ";
    $str .= "set mc_ident = '$campaign_id', ";
    $str .= "datetime = '$datetime', ";
    $str .= "prog_str = '$group_names_str'";
    print "$str\n";
    $result = mysql_query($str) or die("Query failed: " . mysql_error() . "\n");
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

