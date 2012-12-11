<?php
/**
 *
 */

/**
 * Sample function.
 */
function favicon_link() {
  echo '<link rel="shortcut icon" type="image/x-icon" href="/favicon.ico" />' . "\n";
}

function not_used() {
  // get_stylesheet_directory() gets theme dir, since style.css overrides parent.
  // require_once( get_stylesheet_directory(). '/my_included_file.php' );
}

/**
 * Overrides twentyeleven_setup() in parent theme.
 * Parent theme tests for existence of this function before loading.
 */

function twentyeleven_setup() {
  // load_theme_textdomain( 'twentyeleven', get_template_directory() . '/languages' );

  $locale = get_locale();
  $locale_file = get_template_directory() . "/languages/$locale.php";
  if ( is_readable( $locale_file ) )
    require_once( $locale_file );

  // This theme styles the visual editor with editor-style.css to match the theme style.
  add_editor_style();

  // Load up our theme options page and related code.
  require( get_template_directory() . '/inc/theme-options.php' );

  // Grab Twenty Eleven's Ephemera widget.
  require( get_template_directory() . '/inc/widgets.php' );

  // Add default posts and comments RSS feed links to <head>.
  add_theme_support( 'automatic-feed-links' );

  // This theme uses wp_nav_menu() in one location.
  register_nav_menu( 'primary', __( 'Primary Menu', 'twentyeleven' ) );

  // Add support for a variety of post formats
  add_theme_support( 'post-formats', array( 'aside', 'link', 'gallery', 'status', 'quote', 'image' ) );

  // Add support for custom backgrounds
  add_custom_background();

  // add_theme_support( 'post-thumbnails' );

  define( 'HEADER_TEXTCOLOR', '000' );

  // By leaving empty, we allow for random image rotation.
  define( 'HEADER_IMAGE', '' );
  define( 'HEADER_IMAGE_WIDTH', apply_filters( 'twentyeleven_header_image_width', 1000 ) );
  define( 'HEADER_IMAGE_HEIGHT', apply_filters( 'twentyeleven_header_image_height', 288 ) );

  // We'll be using post thumbnails for custom header images on posts and pages.
  // We want them to be the size of the header image that we just defined
  // Larger images will be auto-cropped to fit, smaller ones will be ignored. See header.php.
  set_post_thumbnail_size( HEADER_IMAGE_WIDTH, HEADER_IMAGE_HEIGHT, true );

  // Add Twenty Eleven's custom image sizes
  add_image_size( 'large-feature', HEADER_IMAGE_WIDTH, HEADER_IMAGE_HEIGHT, true );
  add_image_size( 'small-feature', 500, 300 );
  // add_theme_support( 'custom-header', array( 'random-default' => true ) );
  // add_custom_image_header( 't_header_style', 't_admin_header_style', 't_admin_header_image' );

  // Default custom headers packaged with the theme. %s is a placeholder for the theme template directory URI.
  register_default_headers( array(
			    ) );
}


/**
 * Main.
 */

add_action('wp_head', 'favicon_link');

?>
