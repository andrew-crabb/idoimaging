#! /usr/bin/php
<?php
error_reporting(E_ALL);
$curr_dir = realpath(dirname(__FILE__));
set_include_path(get_include_path() . PATH_SEPARATOR . "${curr_dir}/../lib");

$mc   = new MailChimp();
$ub   = new UserBase();
$mc_users = $mc->list_users(false, $page);
?>

