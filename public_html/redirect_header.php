<?php
require('print_page_top.php');
// ------------------------------------------------------------
// Now the actual content of the page.
// ------------------------------------------------------------
$content->virtual_or_exec($redirect_url, true, $ub_details);
// print "redirect_url = '$redirect_url'<br>\n";
require('print_page_bottom.php');
?>
