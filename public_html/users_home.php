<tr>
  <td id='user_home_td' class='white'>
    <table id='user_home_table' width='800' border='0' cellpadding='10' cellspacing='10'>
      
      <tr id='user_home_header'>
        <td class='white' align='center' valign=top colspan=3>
          <h2 class='heading'>My Programs</h2>
        </td>
      </tr>  <!-- user_home_header -->


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
	  $ub_details = $rad->get_user_details();
	  $userid = $ub_details[Radutil::UB_USERID];
          $userstr = (isset($userid) and strlen($userid)) ? $userid : "not set";


	  $dbh = $rad->host_connect();
	  $str  = "select monitor.progid";
	  $str .= " from program, monitor";
	  $str .= " where program.ident = monitor.progid";
	  $str .= " and program.remdate like '0000%'";
	  $str .= " and userid = '$userid'";
	  $str .= " order by progid";

          if ($rslt = Utility::query_as_array($dbh, $str)) {
	    $n = count($rslt);
	    print "<tr id='user_home_content'>\n";
	    print "<td class='white' align='center' valign=top colspan=3>\n";
            if ($n > 0) {
              print "Hello (userid $userstr), you are monitoring $n programs.  We'll send you occasional emails when there is a new version released.\n";
            }
	    print "</td>\n";
	    print "</tr>\n";

	    $proglist = '';
	    $sep = '';
	    foreach ($rslt as $elems) {
	      $progid = $elems['progid'];
	      $proglist .= "${sep}${progid}";
	      $sep = ',';
	    }
	    
	    $redirect_str = "/programs";
	    // I cannot for the LIFE of me get this variable to programs.pl otherwise.
	    // The key is to set 'query_string' so programs.pl can see it.
	    apache_setenv('progids', $proglist);

            $content->virtual_or_exec($redirect_str, true, $ub_details);
	  } else {
	    print "<tr id='user_home_content'>\n";
	    print "<td class='white' align='center' valign=top colspan=3>\n";
	    print "Hello.  You are not currently monitoring any programs for new version releases.  You can start monitoring a program by clicking on this icon <img src='/img/icon/add.png' /> when you see a program displayed.\n";
	    print "</td>\n";
	    print "</tr>\n";
	  }
      ?>
      
      
    </table>  <!-- user_home_table -->
  </td>  <!-- user_home_td -->
  </tr>