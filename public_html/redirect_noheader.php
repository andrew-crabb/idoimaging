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

$redirect_url = getenv('REDIRECT_URL');
// print $util->tt_debug("redirect_noheader(): rad->virtual_or_exec($redirect_url)");
$content->virtual_or_exec($redirect_url);
?>
</body>
