############################################################################
# Specify where ContactForm should store its datafiles.  The directory
# that you specify here must exist and must be both world-readable and
# world-writable (aka "chmod a+rwx" or 0777).  By default, we set its
# _in_docroot PREF to 'no' because by default the data directory gets placed
# at the same location as the contact.cgi script itself, so we don't
# need to prepend the value of DOCROOT onto it; we can access it directly
# since it's in the same dir we're running in.  The default settings are:
#
#	$PREF{datadir}			= 'encdata';
#	$PREF{datadir_is_in_docroot}	= 'no';
#
# Alternatively you can set it with an absolute path, like this:
#
#	$PREF{datadir}			= '/var/www/mysite.com/cgi-bin/encdata';
#	$PREF{datadir_is_in_docroot}	= 'no';
#
# Or this:
#
#	$PREF{datadir}			= 'c:\inetpub\wwwroot\cgi-bin\encdata';
#	$PREF{datadir_is_in_docroot}	= 'no';
#
$PREF{datadir}						= 'encdata';
$PREF{datadir_is_in_docroot}				= 'no';



############################################################################
# In order to send you an email, this script will first try to use the SMTP
# server that you specify, and if that fails it'll try to fallback to using
# sendmail.  So you should specify both here.  The SMTP server is usually
# just yourdomain.com, or else mail.yourdomain.com or smtp.yourdomain.com.
# It may also be one of those same subdomains on yourISP.com.  Or it could
# also just be localhost or 127.0.0.1.  The path to sendmail is usually
# /usr/bin/sendmail but if that doesn't work for you then you might need to 
# ask your server admin / hosting company for the correct path.  If you have
# shell access you can try running "which sendmail" to find the path.  Some
# servers require you to authenticate before they will send mail for you, in
# which case you must specify your SMTP authorization username and password
# (usually the same username & password you use to check your mail).
#
$PREF{smtp_server}					= 'localhost:25'; # port is usually 25 or 587.
$PREF{smtp_auth_username}				= '';
$PREF{smtp_auth_password}				= '';
$PREF{path_to_sendmail}					= '/usr/sbin/sendmail';



############################################################################
# Specify the text appearing on your contact page.  When a message is sent
# successfully, we'll display a brief message and then automatically
# redirect the visitor back to your homepage (or whatever page you specify)
# after a few seconds.
#
$PREF{contact_page_title}				= qq`<h1 class="pagetitle">Contact Us</h1>`;
$PREF{contact_page_intro}				= qq`<p>You can get in touch with us by typing a message below.<br />Your message will be sent to us in an email.</p>`;
$PREF{contact_page_outro}				= qq``;
#
$PREF{form_wrapper_start}				= qq`<table>`;
$PREF{submit_button}					= qq`<tr><td class="submit" colspan="2"><input type="button" value="Send email to $ENV{HTTP_HOST}" class="default button submit" id="contact-button" onclick="submitmessage()" /></td></tr>`;
$PREF{form_wrapper_end}					= qq`</table>`;
#
$PREF{name_of_name_field}				= 'Name';
$PREF{name_of_sender_field}				= 'Email';
$PREF{name_of_recipient_field}				= 'Recipient'; # used internally; visitors cannot enter recipient addresses, to prevent spamming.
$PREF{name_of_subject_field}				= 'Subject';
$PREF{name_of_message_field}				= 'Message';
#
$PREF{success_title}					= qq`Contact - Success - $ENV{HTTP_HOST}`;
$PREF{success_message}					= qq`<h1 class="pagetitle">Message Sent</h1>\n<p>Thanks for your message!&nbsp; We will get back to you as soon as possible.</p>\n<p>Sending you home...</p>`;
$PREF{success_message_display_time}			= 5; # in seconds; may be zero.
$PREF{redirection_url}					= '/'; # default is '/' which is your homepage.



############################################################################
# Specify the fields that will appear on the form.  For all fields, the
# following options will take these default values unless you specify them
# differently for a given field:
#
#	$PREF{formfield_NN_label_classname}	= 'label'; # for CSS.
#	$PREF{formfield_NN_field_classname}	= 'field'; # for CSS.
#	$PREF{formfield_NN_label_colspan}	= 1;
#	$PREF{formfield_NN_separator}		= '</td><td class="field">';
#	$PREF{formfield_NN_type}		= 'singleline';
#	$PREF{formfield_NN_size}		= '200x200'; # only for multiline fields.
#	$PREF{formfield_NN_maxlength}		= 150;
#	$PREF{formfield_NN_required}		= 'yes';
#	$PREF{formfield_NN_emailformat}		= 'no'; # whether to verify input is a valid email address.
#
# (But note that the "subject" and "sender" fields have some different
#  defaults and some special rules.)
#
# The 'type' can be singleline, multiline, dropdown, or none.  Specifying
# 'none' means that no field field will be displayed; this is useful when
# you want to just use the label for this item to insert some custom text
# or HTML.  (You probably want to set colspan to 2 and separator to '' in
# this case.)
#
# You can create as many input fields as you'd like.  The only restriction
# is that you must not change the names of the 5 basic fields (name, sender,
# subject, message, recipient), and you must not use these names for any 
# other fields, though it is fine to disable any of the 5 if you wish.
#
$PREF{formfield_01_name}				= $PREF{name_of_name_field}; # don't change this.
$PREF{formfield_01_label}				= qq`Name:`;
$PREF{formfield_01_separator}				= '<br />';

$PREF{formfield_02_name}				= $PREF{name_of_sender_field}; # don't change this.
$PREF{formfield_02_label}				= qq`Email Address:`;
$PREF{formfield_02_separator}				= '<br />';

$PREF{formfield_03_name}				= $PREF{name_of_subject_field}; # don't change this.
$PREF{formfield_03_label}				= qq`Subject:`;
$PREF{formfield_03_separator}				= '<br />';

$PREF{formfield_04_name}				= $PREF{name_of_message_field}; # don't change this.
$PREF{formfield_04_label}				= qq`Message:`;
$PREF{formfield_04_maxlength}				= 10000;
$PREF{formfield_04_type}				= 'multiline';
$PREF{formfield_04_separator}				= '<br />';

# Example of how to create a dropdown so your visitors can select from a list of recipients.
#$PREF{formfield_05_name}				= $PREF{name_of_recipient_field}; # don't change this.
#$PREF{formfield_05_label}				= qq`Recipient:`;
#$PREF{formfield_05_type}				= 'dropdown';
#$PREF{formfield_05_displayed_values}			= '|||Sales|||Support|||Other';
#$PREF{formfield_05_submitted_values}			= '|||sales@mysite.com|||help@mysite.com|||misc@mysite.com';
#$PREF{formfield_05_separator}				= '<br />';



############################################################################
# If you want to use your own custom HTML for your formfields, then you can
# set $PREF{custom_form_fields_code}.  This will prevent ContactForm from
# generating form fields internally using the $PREF{formfield_NN} settings
# above; instead, it will display your custom HTML code.
#
# For each custom form field in your code here, you must add the field's name
# to the $PREF{custom_form_fields_namelist} setting (comma-separated), so that
# ContactForm knows it should process that field.  (Note: for any given form
# field, instead of adding it to the $PREF{custom_form_fields_namelist}
# setting, you can optionally create a $PREF{formfield_NN} setting [above],
# in case you want to use any of the extra functionality provided by the other
# $PREF{formfield_NN_*} settings.)
#
$PREF{custom_form_fields_code}				= qq``;
$PREF{custom_form_fields_namelist}			= qq``;
$PREF{custom_form_fields_messagefield_maxlength}	= 10000;
$PREF{custom_form_fields_maxlength}			= 150;



############################################################################
# Specify the recipient for your contact page.  This can include multiple
# addresses separated by commas.  If you are using a field named
# "recipient" then that will override this.
#
$PREF{contact_page_recipient}				= 'andy@idoimaging.com';



############################################################################
# If we have a name for the sender, then we'll set the From: field on the
# email to "Name <email@address.com>".  But some servers get confused by
# this, reporting errors like "can't extract address" or similar; in that
# case you can disable this here.
#
$PREF{include_name_within_address_field}		= 'yes';



############################################################################
# Specify your subject template and optionally a fixed sender address.
# The subject template includes any user-entered subject by default, and
# can also include the variable %serial_number% (see the option for
# $PREF{enable_serial_number} below).  The fixed sender address should 
# only be used if you're not displaying a "From:" field on your form.
#
$PREF{subject_template}					= '%user_entered_subject%';
$PREF{fixed_sender_address}				= '';



############################################################################
# You can choose to have each message sent by ContactForm contain a unique
# serial number that can be used as an order number, confirmation number,
# tracking number, etc.  This number will be stored on your server in the
# file $PREF{datadir}/_cf_counter_value.txt.  To start your serial number
# at some specific value, just edit the number in that file.
#
$PREF{enable_serial_number}				= 'yes';
$PREF{pad_with_zeros_to_this_length}			= 5;



############################################################################
# If you specify required=yes for any of your fields, and the user does not
# fill them in, we'll display an error message and change their colors.
#
$PREF{bgcolor_for_unfilled_required_fields}		= '#ffdd00';
$PREF{textcolor_for_unfilled_required_fields}		= '#000';
$PREF{default_bgcolor_for_required_fields}		= '#efefef'; # or try null ('').
$PREF{default_textcolor_for_required_fields}		= '#000';



############################################################################
# You can specify a time offset in case your server is in a different time
# zone than you are.
#
$PREF{time_offset}					= -0; # in hours; can include negative sign.



############################################################################
# If you're embedding ContactForm into an existing layout, then you probably
# don't want FC to print out full HTML tags.  So you can disable that here.
# In that case you must also put the following lines into the <head> section 
# of your website's header/template file:
#
#	<script type="text/javascript" src="/cgi-bin/contact.cgi?js"></script>
#	<link rel="stylesheet" type="text/css" media="all" href="/cgi-bin/contact.cgi?css" />
#
# Note that the CSS output may have conditional comments at the bottom that
# you'll need to copy directly into the <head> section of your site.
#
# If you are not going to use print_full_html_tags, then ideally you'll be
# calling ContactForm from a file like /upload/index.shtml that contains
# something pretty similar to this:
#
#	<!--#include virtual="/header.shtml" -->
#	<!--#include virtual="/cgi-bin/contact.cgi?$QUERY_STRING" -->
#	<!--#include virtual="/footer.shtml" -->
#
# ...where header.shtml and footer.shtml contain your site-wide standard
# HTML code that each page is wrapped in.  Or, if your header/footer are
# in PHP, then your /upload/index.php might look like this:
#
#	<? virtual("/header.php"); ?>
#	<? virtual("/cgi-bin/contact.cgi?" . $_SERVER['QUERY_STRING']); ?>
#	<? virtual("/footer.php"); ?>
#
# However, if you are on a brain-dead server (for example, IIS6+) which
# does not support any decent way to call a CGI script that includes the
# proper server environment variables, and your server does not have PHP
# installed, and you still want to include a standard header/footer with
# ContactForm, then you can set encodable_app_template_file.  Set this to
# the full path (probably starting with "%PREF{DOCROOT}/") to an HTML page
# on your site which should be used as the template for ContactForm's
# output.  You can create this HTML file in whatever way you normally
# create web pages; the only requirements are that it contain the string
# %%encodable_app_output%% wherever you'd like ContactForm's output to
# appear, and that you put the strings %%css%% and %%js%% within the
# <head> section of the file.  No server-side processing (PHP, SSI, etc)
# will be done on the contents of this file; however you can specify a 
# title within it by inserting the string %%title%% (for example, as in
# <title>%%title%%</title>) and we'll replace that with your value for
# the title_for_template_file variable (or in some cases, with an
# internally-set title).
#
$PREF{print_full_html_tags}				= 'yes'; # overridable by the more specific ones next.
$PREF{encodable_app_template_file}			= '';
$PREF{title_for_template_file}				= '';



############################################################################
# Here you can customize the styling of ContactForm.
#
# If you want to use this to call an external stylesheet, use the standard
# CSS @import command.  Because this setting gets wrapped in style tags,
# you'll also need to close and re-open them, like this:
#
#	$PREF{css} = qq`</style><style type="text/css">@import url(/path/to/stylesheet.css);</style><style type="text/css">`;
#
# You can also specify your own custom Javascript code.  Leave off the
# <script> tags.  And you can use schedule_onload_action(myfunction); to
# hook into the onload logic.
#
$PREF{custom_js_code}					= qq``;
$PREF{custom_js_code__onsubmit}				= qq``;
$PREF{main_container_css_id}				= qq`enccontact`;
#
$PREF{css} = qq`
#enccontact { font-family: sans-serif; }
input.default, textarea.default, select.default { border: 1px inset #888; background: #efefef; padding: 2px; }
input.default:hover, textarea.default:hover, input.default:focus, textarea.default:focus { background: #fff; }
input.text, #enccontact textarea { width: 400px; }
#enccontact td.label, #enccontact td.field { padding-bottom: 20px; }
#contact-Message { height: 300px; }
#contact-button { border: 1px outset #000; background: #efefef; color: #000; }
#enccontact form { margin: 0; padding: 0; }
#enccontact table { border: 0; border-collapse: collapse; }
#enccontact a:link, #enccontact a:visited { color: #5773ff; }
#enccontact .pb { font-size: 8pt; margin-top: 20px; }
`;




############################################################################
# Various options.
#
# The subject, sender, and name values are already present in the email
# header, so you may not want them in the email body too.
#
# Also, you may not want to have "Message:" printed before the message text,
# because in many cases that is obvious/redundant.
#
$PREF{show_subject_field_in_message_body}		= 'no';
$PREF{show_sender_field_in_message_body}		= 'no';
$PREF{show_name_field_in_message_body}			= 'no';
$PREF{show_message_field_label_in_message_body}		= 'no';
$PREF{use_short_labels_in_email}			= 'no';
$PREF{hide_recipient_email_address_in_error_messages}	= 'yes';



############################################################################
# These should virtually always be 777; on a small number of servers you may
# be able to get away with using the less-permissive 755 instead.
#
$PREF{writable_dir_perms_as_string}			= '0777';	# quotes required. default is '0777'.
$PREF{writable_dir_perms_as_octal}			= 0777;		# no quotes. default is 0777.
$PREF{writable_dir_perms_mask_as_octal}			= 07777;	# no quotes. default is 07777.



############################################################################
# You probably don't need to do this.
#
$PREF{generate_message_id_internally}			= 'no';



############################################################################
# ContactForm will always look for a file named contact_prefs.cgi to read
# preference settings from.  But you can also create other prefs files in case
# you want to run ContactForm with different settings depending on how it's 
# called.  There are 2 methods for this:
#
# The first and recommended method is the shortcut method.  This requires you to
# specify (within contact.cgi or contact_prefs.cgi) shortcut names and
# shortcut targets.  Then you pass the shortcut_name on the URL with ?prefs=foo
# and that will cause ContactForm to use the filename specified in shortcut_target
# for shortcut_name = foo.  For example, given these settings:
#
#	$PREF{other_prefs_files}{01}{shortcut_name}	= qq`foo`;
#	$PREF{other_prefs_files}{01}{shortcut_target}	= qq`bar_prefs.txt`;
#
# ...then this URL:
#
#	http://mysite.com/cgi-bin/contact.cgi?prefs=foo
#
# ...will cause ContactForm to load prefs from the bar_prefs.txt file.
#
# The second method allows you to specify the full prefs filename including
# path on the URL with ?prefsfile=/cgi-bin/foo/bar/baz.txt.  The advantage of
# this method is that you don't have to specify the allowable prefs files 
# beforehand; the disadvantage is that, although we do our best to untaint
# filenames coming from the URL, accepting filenames to execute from the URL
# which any user can specify is always something of a security risk.  So
# using the shortcut method instead is more secure because ContactForm will
# only use filenames that you have hard-coded into either contact.cgi or
# contact_prefs.cgi beforehand.
#
# For either method, the _in_docroot PREF controls whether we'll automatically
# prepend your $DOCROOT value onto the filenames that you specify.  On most
# servers, if you put your prefs files in the same folder as contact.cgi,
# and you specify the filenames here with no path information, then the script
# will find them OK with _in_docroot set to 'no'.  Using in_docroot = 'no' also
# allows you to specify the full path with the filenames, all the way from the
# root of your server.  Using _in_docroot = 'yes' allows you to specify the
# filenames with just the website portion of the path, for example you could
# say {shortcut_target} = qq`/cgi-bin/client_prefs.txt`.
#
$PREF{other_prefs_files}{01}{shortcut_name}		= 'clients';
$PREF{other_prefs_files}{01}{shortcut_target}		= 'clients_prefs.txt';
$PREF{other_prefs_files}{02}{shortcut_name}		= 'vendors';
$PREF{other_prefs_files}{02}{shortcut_target}		= 'vendors_prefs.txt';
#
$PREF{enable_other_prefs_files_with_filename_on_URL}	= 'no';
$PREF{other_prefs_filenames_from_URL_can_contain_paths}	= 'no';
#
$PREF{other_prefs_files_are_in_docroot}			= 'no';

