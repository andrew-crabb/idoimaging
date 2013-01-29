<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">

<head>
  <meta charset="<?php bloginfo( 'charset' ); ?>" />
  <meta name="viewport" content="width=device-width" />
  <link rel="profile" href="http://gmpg.org/xfn/11" />
  <link rel="stylesheet" type="text/css" media="all" href="<?php bloginfo( 'stylesheet_url' ); ?>" />
  <link rel="pingback" href="<?php bloginfo( 'pingback_url' ); ?>" />
  <!--[if lt IE 9]>
    <script src="<?php echo get_template_directory_uri(); ?>/js/html5.js" type="text/javascript"></script>
  <![endif]-->

  <!-- IDI header block begin -->
  <?php
   error_reporting(E_ALL);
   $include_path = get_include_path() ;
   set_include_path($include_path . PATH_SEPARATOR . '/Users/ahc/idoimaging/php');
   require_once "Utility.php";
   require_once "Content.php";
   require_once "Radutil.php";

   $util    = new Utility();         // General purpose utilities.
   $rad     = new Radutil($util);         // Utilities specific to the site.
   $content = new Content($util, $rad);         // Generates site-specific content.

   // print $util->tt_debug("before print_index_head()");
   // This does the Javascript and the CSS.
   $content->print_index_head();
   print Content::META_DATA;
  ?>
  <!-- IDI header block end -->

  <!-- WP header block begin -->
  <?php
    // WP header block.
    /* Always have wp_head() just before the closing </head> tag */
    wp_head();
  ?>
  <!-- WP header block end -->

</head>

<body <?php body_class(); ?>>

<?php
// Title image and login block
$ub_details = $rad->get_user_details();
$content->print_page_header($ub_details);
// Start table, navigation code, page-top advertising.
$content->print_page_intro(Content::BLOG);
// Non-standard ending my main table here to allow WordPress to do its thing.
print "</table><br>\n";
?>

<div id="page" class="hfeed">
  <header id="branding" role="banner">
    
    <?php
      // Check to see if the header image has been removed
      $header_image = get_header_image();
      if ( ! empty( $header_image ) ) :
    ?>
    <a href="<?php echo esc_url( home_url( '/' ) ); ?>">
    <?php
	// The header image
	// Check if this is a post or page, if it has a thumbnail, and if it's a big one
	if ( is_singular() &&
	     has_post_thumbnail( $post->ID ) &&
	     ( /* $src, $width, $height */ $image = wp_get_attachment_image_src( get_post_thumbnail_id( $post->ID ), array( HEADER_IMAGE_WIDTH, HEADER_IMAGE_WIDTH ) ) ) &&
	     $image[1] >= HEADER_IMAGE_WIDTH ) :
	  // Houston, we have a new header image!
	  echo get_the_post_thumbnail( $post->ID, 'post-thumbnail' );
    else : ?>
    <img src="<?php header_image(); ?>" width="<?php echo HEADER_IMAGE_WIDTH; ?>" height="<?php echo HEADER_IMAGE_HEIGHT; ?>" alt="" />
    <?php endif; // end check for featured image or standard header ?>
  </a>
  <?php endif; // end check for removed header image ?>

  <?php
      // Has the text been hidden?
      if ( 'blank' == get_header_textcolor() ) :
  ?>
  <div class="only-search<?php if ( ! empty( $header_image ) ) : ?> with-image<?php endif; ?>">
  <?php // get_search_form(); ?>
</div>
<?php
      else :
?>
<?php // get_search_form(); ?>
<?php endif; ?>

</header><!-- #branding -->


<div id="main">
