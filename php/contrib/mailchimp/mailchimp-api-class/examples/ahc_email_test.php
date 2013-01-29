<?php
/**
This Example shows how to create a basic campaign via the MCAPI class.
**/
require_once 'inc/MCAPI.class.php';
require_once 'inc/config.inc.php'; //contains apikey
require_once 'ahc/utilities.php';

// Constants
$mail_html_file = '/Users/ahc/Dropbox/public_html/idoimaging/email/archive/110819/email_110819_1_0000.html';

$api = new MCAPI($apikey);

$type = 'regular';

$opts['list_id']    = '8742aa4b68';
$opts['subject']    = 'Test Newsletter Subject';
$opts['from_email'] = 'news@idoimaging.com'; 
$opts['from_name']  = 'I Do Imaging';

$opts['tracking'] = array(
  'opens'       => true,
  'html_clicks' => true,
  'text_clicks' => false,
);

$opts['authenticate'] = true;
$opts['analytics']    = array('google'=>'UA-2402704-1');
$opts['title']        = 'I Do Imaging - Test';

$content_html = file_contents($mail_html_file);
$content_text = 'This is the text content for file $mail_html_file';

$content = array(
  'html' => $content_html,
  'text' => $content_text,
);

/** OR we could use this:
$content = array('html_main'=>'some pretty html content',
		 'html_sidecolumn' => 'this goes in a side column',
		 'html_header' => 'this gets placed in the header',
		 'html_footer' => 'the footer with an *|UNSUB|* message', 
		 'text' => 'text content text content *|UNSUB|*'
		);
$opts['template_id'] = "1";
**/

$retval = $api->campaignCreate($type, $opts, $content);

if ($api->errorCode){
  echo "Unable to Create New Campaign!";
  echo "\n\tCode=" . $api->errorCode;
  echo "\n\tMsg="  . $api->errorMessage . "\n";
} else {
  echo "New Campaign ID:" . $retval . "\n";
}

?>
