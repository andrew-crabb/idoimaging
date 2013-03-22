<?PHP

# ahc
# This one is not functionally modified, just check for unset vars etc.

# ubvars.php: this file/page is not visited directly; instead you
# require() it from within another page where you want to access
# UserBase variables (logged-in username, etc).  See the ubinfo.php
# file for an example.


$IDOIMAGING = '/Users/ahc/Dropbox/idoimaging';

$DOCROOT = isset($DOCUMENT_ROOT) ? $DOCUMENT_ROOT : $_SERVER['DOCUMENT_ROOT'];
$site_session = isset($_COOKIE['site_session']) ? $_COOKIE['site_session'] : '';
#
# On Windows servers, you may need to set $DOCROOT manually.  Check the
# PATH_TRANSLATED environment variable to see what the path should be.
# You can run the  phpinfo()  function to see that variable's value.

// Method 1:
// ahc note: This doesn't work since output buffering can't be used with virtual (it starts another process).
// ob_start();
// $login_check = $DOCROOT . '/../cgi-bin/imaging/userbase/userbase.cgi?action=chklogin';
// $login_check = '/cgi-bin/imaging/userbase/userbase.cgi?action=chklogin';
// $login_check = '/cgi-bin/test/penv.pl';
// virtual($login_check);
// $login_status = ob_get_contents();
// $len = ob_get_length();
// ob_end_clean();
// echo "<br>length = $len, login_status = $login_status<br>\n";



/*
# Method 2:
# Note that with this method, the IP received by the CGI script will be the server's
# IP, not the end-user's IP, so any features that rely on that (for example UserBase's
# "restrict this session to my IP" feature) must be disabled because they won't work.
#
// ahc note: This requires allow_url_include to be On in php.ini which is a security risk.
ob_start();
$login_check = "http://" . $_SERVER['HTTP_HOST'] . "/cgi-bin/userbase/userbase.cgi?action=chklogin&ubsessioncode=$site_session";
include($login_check);
$login_status = ob_get_contents();
ob_end_clean();
*/


  # Method 3:
  # Change only these first 2 lines, to match the path & name of your CGI script:
  $cgi_script_full  = "$IDOIMAGING/cgi-bin/userbase/userbase.cgi";
  $cgi_script_local = "/cgi-bin/userbase/userbase.cgi";

  if(!(file_exists($cgi_script_full)))
  {
    error_log( "Error: the file specified by \$cgi_script_full does not exist ('$cgi_script_full').  You may need to edit your ubvars.php file and manually set the \$DOCROOT and/or \$cgi_script_full variables.");
    exit;
  }

  reset($_SERVER);
  $qs_set = 0;
  while (list ($header, $value) = each ($_SERVER))
  {
  if($header == "SCRIPT_NAME" || $header == "SCRIPT_URL")
  {
  putenv("$header=$cgi_script_local");
  }
  elseif($header == "SCRIPT_FILENAME")
  {
  putenv("$header=$cgi_script_full");
  }
  elseif($header == "SCRIPT_URI")
  {
  $value = str_replace($_SERVER['SCRIPT_URL'], $cgi_script_local, $value);
  putenv("$header=$value");
  }
  elseif($header == "QUERY_STRING")
  {
  // putenv("$header=action=chklogin&code=" . $_COOKIE['site_session']);
  putenv("$header=action=chklogin&code=$site_session");
  $qs_set = 1;
  }
  else
  {
  putenv("$header=$value");
  }
  }
  if(!$qs_set)
  {
  // putenv("QUERY_STRING=action=chklogin&code=" . $_COOKIE['site_session']);
  putenv("QUERY_STRING=action=chklogin&code=$site_session");
  }

  unset($output);
  unset($output_body);
  exec($cgi_script_full, $output, $return_val);
  if(!$output)  {
    exec("perl $cgi_script_full", $output, $return_val);
  }
// print "ubvars.php: cgi_script_full $cgi_script_full<br>\n";
// print_r($output);

$html_headers_finished = 0;
$output_body = '';
foreach ($output as $line)  {
  if($html_headers_finished)  {
    if (preg_grep('/sql/', array($line))) {
      error_log("*** $line");
    }
    $output_body .= "$line\n";
  }  else  {
    if($line == '')  {
      $html_headers_finished = 1;
    }
  }
}
$login_status = $output_body;


  # Now unset these so as not to confuse any CGI scripts that we call after this one:
  reset($_SERVER);
  while (list ($header, $value) = each ($_SERVER))
  {
  $status = putenv($header) ? 'succeeded' : 'failed';
  #print "<!-- $status unsetting var $header -->\n";
  }



$ub_username = '';
$ub_userid = '';
$ub_is_member = 0;
$ub_is_admin = 0;
$ub_realname = '';
$ub_email = '';
$ub_group_memberships = '';
$ub_group_list = array();
$ub_vars = array();

if(preg_match("/^admin=(0|1):::::member=(0|1):::::username=(.*?):::::userid=(\d*?):::::group_memberships=(.*?):::::realname=(.*?):::::email=(.*?):::::(.*)/", $login_status, $matches))
  {
    $ub_username = $matches[3];
    $ub_userid = $matches[4];
    $ub_is_member = $matches[2];
    $ub_is_admin = $matches[1];
    $ub_realname = $matches[6];
    $ub_email = $matches[7];
    $ub_group_memberships = $matches[5];
    $ub_group_list = explode(",", $ub_group_memberships);

    $ub_custom_vars = explode(":::::", $matches[8]);
    foreach($ub_custom_vars as $pair)
      {
        // list($var,$val) = explode("=", $pair);
        $bits = explode("=", $pair);
        $var = (isset($bits[0])) ? $bits[0] : '';
        $val = (isset($bits[1])) ? $bits[1] : '';
        if($var)
          {
            $ub_vars[$var] = $val;
          }
      }
  }
?>
