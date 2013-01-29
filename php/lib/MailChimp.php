<?php

class MailChimp {

  // ============================================================
  // MailChimp field constants
  // ============================================================

  const EMAIL    = 'email';
  const ID       = 'id';
  const WEB_ID   = 'web_id';
  public $FIELDS = array(self::EMAIL, self::ID, self::WEB_ID);

  const DASHES = "----------------------------------------\n";
  const GROUPING_PROGRAMS = 'programs';
  const WEB_ID_PATTERN = "/[0-9a-f]{8,12}/";
  const TEST_HTML_EMAIL   = 'test_html_email.html';

  const TEMPL_PATH        = 'email/templ';
  const CONTENT_PATH      = 'email/cont';
  
  public $api_key; // MailChimp API key
  public $list_id; // MailChimp id of my mailing list

  public $util;                    // Utility class object.
  public $programs_grouping_id;    // MailChimp ID of the 'programs' grouping.
  public $time_now;                // Time the MailChimp object was created.
  
  // ------------------------------------------------------------
  // Constructor.

  function __construct($verbose = 0) {
    $curr_dir = realpath(dirname(__FILE__));

    set_include_path(get_include_path() . PATH_SEPARATOR . "${curr_dir}/../lib");
    require_once 'Utility.php';
    
    set_include_path(get_include_path() . PATH_SEPARATOR . "${curr_dir}/../contrib/mailchimp");
    require_once 'MCAPI.class.php';
    require_once 'config.inc.php'; //contains apikey
    
    $this->api_key = $apikey;
    $this->list_id = $listId;
    $this->api = new MCAPI($this->api_key);
    // print "MailChimp::__construct(): api_key = "  . $this->api_key . "\n";
    $this->util = new Utility();
    $this->time_now = $this->util->convert_dates(time());
    $this->verbose = $verbose;
  }

  // ------------------------------------------------------------
  // Given array of user ids, ensure they are on the MailChimp mailing list.
  // Conditions for inclusion: same email, code, ident.
  //   all_users: Dump of IDI email DB.
  // Fields of all_users{user_id} needed: Email, mc_ident
  
  public function check_users_on_list(&$user_ids, $all_users) {
    $list_id = $this->list_id;
    foreach ($user_ids as $user_id) {
      print "check_users_on_list(user $user_id)\n";
      $user = $all_users[$user_id];
      $user_email = $user['Email'];
      $user_mc_ident = $user['mc_ident'];
      $list_member = $this->run_api_query('listMemberInfo', array($list_id, array($user_email)));
      if (isset($list_member)) {
        if ($list_member['success']) {
          // Ensure local db record is in sync with mc record.
          print "************ $user_email exists ************\n";
          print_r($list_member);
          // Updates Subscribers: No longer used.
          // $this->update_user_local($user, $list_member);
        } else {
          print "************ $user_email does not exist ************\n";
          $added_ok = $this->add_user($user_email);
          if ($added_ok) {
            print "Added $user_email OK\n";
            // Now add mc_ident to local record.
            $new_member = $this->run_api_query('listMemberInfo', array($list_id, array($user_email)));
            if (isset($new_member) && $new_member['success']) {
              $mc_id_new = $new_member['data'][0]['id'];
              $str  = "update subscribers";
              $str .= " set mc_ident = '$mc_id_new'";
              $str .= " where Email = '$user_email'";
              $result = mysql_query($str) or die("Query failed: " . mysql_error() . "\n");              
            } else {
              print "ERROR query new email: $user_email\n";
            }
          }
        }
      }
    }
  }

  // ------------------------------------------------------------

  public function add_user($user_email, $send_confirm = false, $send_welcome = false) {
    $add_user_opts = array($this->list_id, $user_email, NULL, 'html', $send_confirm, false, true ,$send_welcome);
    if ($this->verbose) {
      print "MailChimp::add_user($user_email): send_welcome = $send_welcome\n";
      print_r($add_user_opts);
    }
    $added_ok = $this->run_api_query('listSubscribe', $add_user_opts);
    if (!$added_ok) {
      print "ERROR: MailChimp::add_user($user_email)\n";
    }
    return $added_ok;
  }

  // ------------------------------------------------------------

  public function delete_user($user_email) {
    if ($this->verbose) {
      print "MailChimp::delete_user($user_email)\n";
    }
    $del_user_opts = array($this->list_id, $user_email, true, false, false);
    $del_ok = $this->run_api_query('listUnsubscribe', $del_user_opts);
    if (!$del_ok) {
      print "ERROR: MailChimp::delete_user($user_email)\n";
    }
    return $del_ok;
  }

  // ------------------------------------------------------------

  public function edit_user($user_email, $new_email) {
    if ($this->verbose) {
      print "MailChimp::edit_user($user_email, $new_email)\n";
    }
    $merge_vars = array('EMAIL' => $new_email);
    $edit_user_opts = array($this->list_id, $user_email, $merge_vars);
    $edit_ok = $this->run_api_query('listUpdateMember', $edit_user_opts);
    if (!$edit_ok) {
      print "ERROR: MailChimp::edit_user($user_email, $new_email)\n";
    }
    return $edit_ok;
  }

  // ------------------------------------------------------------

  public function update_user_local($local_user, $mc_user) {
    $mc_user_ident = $mc_user['data'][0]['id'];
    $local_mc_ident = $local_user['mc_ident'];
    $local_user_email = $local_user['Email'];
    $local_ident = $local_user{'ident'};
    print "$local_user_email exists with id $mc_user_ident\n";

    // mc_user_ident comes from MC, so overwrite local field value for this user.
    if ($local_mc_ident != $mc_user_ident) {
      $update_str  = "update subscribers";
      $update_str .= " set mc_ident = '$mc_user_ident'";
      $update_str .= " where ident = '$local_ident'";
      // No longer use this table.
      // $n_updates = $this->util->query_issue($update_str);
    } else {
      print "Local user ident $local_ident has same MC ident: $mc_user_ident\n";
    }
  }

  // ------------------------------------------------------------

  function delete_existing_groups() {
    $list_id = $this->list_id;
    print "MailChimp::delete_existing_groups()\n";
    $interest_groupings = $this->run_api_query('listInterestGroupings', array($list_id));
    // print_r($interest_groupings);
    if ($this->verbose) {
      $this->util->printr($interest_groupings, 'interest_groupings');
    }
    if (isset($interest_groupings)) {
      // Iterate through groupings to find 'programs'
      $grouping = NULL;
      foreach ($interest_groupings as $interest_grouping) {
        if ($interest_grouping['name'] == self::GROUPING_PROGRAMS) {
          $grouping = $interest_grouping;
        }
      }

      if (isset($grouping)) {
        $this->programs_grouping_id = $grouping['id'];
        $groups      = $grouping['groups'];
        foreach ($groups as $group) {
          $group_name = $group['name'];
          $list_params = array($list_id, $group_name, $this->programs_grouping_id);
          $this->run_api_query('listInterestGroupDel', $list_params);
          print "listInterestGroupDel($group_name, " . $this->programs_grouping_id . ")\n";
        }
      } else {
        print "ERROR: MailChimp::delete_existing_groups(): Could not find grouping " . self::GROUPING_PROGRAMS . "\n";
      }
    }
  }

  // ------------------------------------------------------------
  // Creates interest groups and returns array of group names.

  function create_group_names($users_for_progs) {
    // Create an interest group on MC for each program.  Need to create all groups first as
    // the next loop adds each user to the interest group of each of their programs.
    $group_names = array();
    $groupnames_for_users = array();
    foreach ($users_for_progs as $progid => $users) {
      $group_name = "program_${progid}";
      array_push($group_names, $group_name);

      // Add this group name to array of such for this user.
      foreach ($users as $user) {
        $groupnames_for_users[$user][] = $group_name;
      }
    }
    return array($group_names, $groupnames_for_users);
  }

  // ------------------------------------------------------------
  // Given array of group names, creates interest groups on MC

  function create_groups($group_names, $groupnames_for_users, $all_users) {
    $list_id = $this->list_id;
    print "MailChimp::create_groups()\n";

    // Create group_names and groupnames_for_users
    foreach ($group_names as $group_name) {
      $group_params = array($list_id, $group_name, $this->programs_grouping_id);
      $add_ok = $this->run_api_query('listInterestGroupAdd', $group_params);
      print "listInterestGroupAdd($group_name) returned $add_ok\n";
    }
    
    // Update each user on MC server with appropriate interest groups.
    foreach ($groupnames_for_users as $userid => $group_names_for_user) {
      $group_names_string = join(",", $group_names_for_user);
      print "MailChimp::create_groups(): User $userid, group_string $group_names_string\n";
      print "MailChimp::create_groups(): Adding user $userid\n";
      $merge_vars = array(
        'GROUPINGS' => array(
          array(
            'groups' => $group_names_string,
            'id'     => $this->programs_grouping_id,
          ),
        ),
      );
      // print_r($merge_vars);
      if ($this->verbose) {
        $this->util->printr($merge_vars, 'merge_vars');
      }
      $user_email = $all_users[$userid]['Email'];
      $member_params = array(
        $list_id,
        $user_email,
        $merge_vars,
      );
      $update_ok = $this->run_api_query('listUpdateMember', $member_params);
      if ($update_ok) {
        print "User $userid ($user_email) updated OK with groups $group_names_string\n";
      } else {
        print "ERROR: User $userid ($user_email) not updated\n";
      }
    }
  }

  // ------------------------------------------------------------

  function create_campaign($html_code, $text_code, $group_names = NULL) {
    $datetime = $this->time_now[Utility::DATES_HRRTDIR];
    $campaign_opts = array(
      'list_id'    => $this->list_id,
      'subject'    => "IDI email $datetime",
      'from_email' => 'news@idoimaging.com',
      'from_name'  => 'I Do Imaging',
      'to_name'    => 'Test To-Name',
    );
    $content = array(
      'html' => $html_code,
      'text' => $text_code,
    );
    $segment_opts = (isset($group_names)) ? $this->make_segment_opts($group_names) : NULL;
    $campaign_params = array('regular', $campaign_opts, $content, $segment_opts);
    $campaign_id = $this->run_api_query('campaignCreate', $campaign_params);
    print "MailChimp::create_campaign(): Campaign ID = $campaign_id\n";
    return $campaign_id;
  }

  // ------------------------------------------------------------

  function make_segment_opts($group_names) {
    // Create the options.
    $group_key = 'interests-' . $this->programs_grouping_id;
    $group_value = join(",", $group_names);
    $group_conditions[] = array(
      'field' => $group_key,
      'op'    => 'one',
      'value' => $group_value,
    );
    $group_opts = array(
      'match'      => 'all',
      'conditions' => $group_conditions,
    );
    $opts = array($this->list_id, $group_opts);

    // Test how many users are selected by the options.
    $ret = $this->run_api_query('campaignSegmentTest', $opts, $this->verbose);
    print "MailChimp::make_segment_opts(): $ret users selected\n";
    return $group_opts;
  }

  // ------------------------------------------------------------

  function send_campaign($campaign_id) {
    // $test_emails = array("andy@idoimaging.com");
    // $campaign_params = array($campaign_id, $test_emails);
    // $sent_ok = $this->run_api_query('campaignSendTest', $campaign_params);
    $campaign_params = array($campaign_id);
    $sent_ok = $this->run_api_query('campaignSendNow', $campaign_params, $this->verbose);
    print "MailChimp::send_campaign($campaign_id) returning $sent_ok\n";
    return $sent_ok;
  }

  // ------------------------------------------------------------
  // Run a function in the MailChimp API.
  // Returns undef on error, else return value of API function execution.

  function run_api_query($progname, $params, $do_print = 0) {
    $ret = '';
    //    $paramstrs = array();
    //    foreach ($params as $param) {
    //      if (is_array($param)) {
    //        $param = '(' . join(', ', $param) . ')';
    //      } 
    //      $paramstrs[] = $param;
    //    }
    //    $paramstr = join(', ', $paramstrs);
    // print "MailChimp::run_api_query($progname, $paramstr)\n";
    if ($do_print) {
      $this->util->printr($params, 'params');
    }
    if (count($params) === 1) {
      $ret = $this->api->$progname($params[0]);
    } elseif (count($params) === 2) {
      $ret = $this->api->$progname($params[0], $params[1]);
    } elseif (count($params) === 3) {
      $ret = $this->api->$progname($params[0], $params[1], $params[2]);
    } elseif (count($params) === 4) {
      $ret = $this->api->$progname($params[0], $params[1], $params[2], $params[3]);
    } elseif (count($params) === 5) {
      $ret = $this->api->$progname($params[0], $params[1], $params[2], $params[3], $params[4]);
    } elseif (count($params) === 6) {
      $ret = $this->api->$progname($params[0], $params[1], $params[2], $params[3], $params[4], $params[5]);
    } elseif (count($params) === 7) {
      $ret = $this->api->$progname($params[0], $params[1], $params[2], $params[3], $params[4], $params[5], $params[6]);
    } elseif (count($params) === 8) {
      $ret = $this->api->$progname($params[0], $params[1], $params[2], $params[3], $params[4], $params[5], $params[6], $params[7]);
    } else {
      $n = count($params);
      print "ERROR: Too many parameters ($n)\n";
      return 0;
    }
    if ($this->api->errorCode) {
      echo "Unable to load $progname()!\n";
      echo "\tCode = " . $this->api->errorCode    . "\n";
      echo "\tMsg  = " . $this->api->errorMessage . "\n";
      $ret = '';
    }
    return $ret;
  }

  // ------------------------------------------------------------

  public function list_users($do_print = true, $page) {
    $list_id = $this->list_id;
    $opts = array($list_id, 'subscribed', NULL, $page, 100);

    $list_members = $this->run_api_query('listMembers', $opts, $this->verbose);
    print_r($list_members);
    exit;
    $list_total = $list_members['total'];
    // print "list_total $list_total\n";
    $list_data = $list_members['data'];
    $all_users = array();
    foreach ($list_data as $index => $element) {
      $email = $element['email'];
      $member_opts = array($list_id, array($email));
      $list_member = $this->run_api_query('listMemberInfo', $member_opts);
      // print_r($list_member['data'][0]);
      $member_data = $list_member['data'][0];
      $member_email = $member_data['email'];
      $member_id = $member_data['id'];
      $member_web_id = $member_data['web_id'];
      $groups = $member_data['merges']['GROUPINGS'][0]['groups'];
      if ($do_print) {
        printf("%2d %-10s %-10s %-40s %s\n", $index, $member_id, $member_web_id, $member_email, $groups);
      }
      $user_info = array();
      foreach ($this->FIELDS as $field) {
        $user_info[$field] = $member_data[$field];
      }
      $all_users[] = $user_info;
    }
    return $all_users;
  }

  // ------------------------------------------------------------
  // Return standard MC fields on given email address
  // Returns:  Array of values on success; NULL on failure
  // Elements: EMAIL, ID, WEB_ID

  public function get_user_info($email_addr) {
    $opts = array($this->list_id, $email_addr);
    $info = $this->run_api_query('listMemberInfo', $opts);
    $user_info = NULL;
    if ($info['success']) {
      $det = $info['data'][0];
      if (is_array($det) and !isset($det['error'])) {
        foreach ($this->FIELDS as $field) {
          $user_info[$field] = $det[$field];
        }
      }
    }
    return $user_info;
  }

  // ------------------------------------------------------------
  // Print standard MC fields on given email address

  public function print_user_info($email_addr) {
    $user_info = $this->get_user_info($email_addr);
    print $this->util->print_in_lines("MailChimp::print_user_info($email_addr)");
    if (isset($user_info)) {
      foreach ($this->FIELDS as $field) {
        printf("%-10s = %s\n", $field, $user_info[$field]);
      }
    } else {
      print "User $email_addr not found\n";
    }
  }

  // ------------------------------------------------------------
  // Check if given web ID (for MC database) is valid.
  // Returns: boolean

  public function valid_web_id($web_id) {
    $ret = preg_match(self::WEB_ID_PATTERN, $web_id) ? true : false;
    return $ret;
  }

  // ------------------------------------------------------------
  // Send a simple email to given user.

  public function send_test_email($email) {
    $document_root = $this->util->server_details[Utility::ENV_DOCUMENT_ROOT];
    $template_path = $document_root . '/' . self::TEMPL_PATH;
    $html_file = $template_path . '/' . self::TEST_HTML_EMAIL;
    $html_str = $this->util->file_contents($html_file);
    
    $campaign_id = $mail->create_campaign($html_str, $text_str, $group_names);
  }

}
?>
