<?php
error_reporting(E_ALL);

$dir_devel  = '/Users/ahc/BIN/php';
$dir_drop  = '/Users/ahc/Dropbox/BIN/php';
$dir_online = '/usr/home/acrabb/BIN/php';
$include_files = array("Utility");

$files_tried = array();
foreach ($include_files as $include_file) {
  $file_found = 0;
  foreach (array($dir_devel, $dir_online, $dir_drop) as $inc_dir) {
    $full_include_file = "${inc_dir}/${include_file}.php";
    if (file_exists($full_include_file)) {
      include $full_include_file;
      print "include $full_include_file\n";
      $file_found = 1;
    } else {
      array_push($files_tried, $full_include_file);
    }
  }
  if ($file_found == 0) {
    print "ERROR: Cound not find include file $include_file, and I tried the following:\n";
    print_r($files_tried);
    exit;
  }
}


$util = new Utility();

// ------------------------------------------------------------
// Initialization
// ------------------------------------------------------------

host_connect();
$host = host_details();

// ------------------------------------------------------------
// Main Program
// ------------------------------------------------------------

$opts = getopt("hmps::u::v");
print "opts: ";
var_dump($opts);
exit;

$today_dates = $util->convert_dates($util->today());
$g_datestr = $today_dates[$util->DATES_YYMMDD];
print "g_datestr is $g_datestr\n";

// Closing connection
mysql_close($link);


function not_yet_used() {
  // Performing SQL query
  $query = "SELECT count(*) FROM $t_program";
  $result = mysql_query($query) or die("Query failed: " . mysql_error() . "\n");

  // Printing results in HTML
  echo "<table>\n";
  while ($line = mysql_fetch_array($result, MYSQL_ASSOC)) {
    echo "\t<tr>\n";
    foreach ($line as $col_value) {
      echo "\t\t<td>$col_value</td>\n";
    }
    echo "\t</tr>\n";
  }
  echo "</table>\n";

  // Free resultset
  mysql_free_result($result);
}

?>
