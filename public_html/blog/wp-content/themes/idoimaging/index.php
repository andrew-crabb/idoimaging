<?php
/**
 * I Do Imaging Blog
 *
 * @package WordPress
 * @subpackage Twenty_Eleven
 */

get_header(); 
?>


<div id="primary">
  <div id="content" role="main">

    <?php 
      if ( have_posts() ) {
	// print $_GET['SERVER_NAME'] . "<br>\n"; 
	twentyeleven_content_nav( 'nav-above' );
	/* Start the Loop */ 
	/* 
	   while ( have_posts() ) {
	   the_post(); 
	   get_template_part( 'content', get_post_format() ); 
	   }
	*/
	$args = array('numberposts' => 3,);

	$myposts = get_posts($args);
	foreach ($myposts as $post) {
	  setup_postdata($post);
	  the_post();
	  get_template_part( 'content', get_post_format() ); 
	}
	twentyeleven_content_nav( 'nav-below' );
      } else {
    ?>
    <article id="post-0" class="post no-results not-found">
      <header class="entry-header">
	<h1 class="entry-title">
	  <?php 
	    _e( 'Nothing Found', 'twentyeleven' ); 
	  ?>
	</h1>
      </header><!-- .entry-header -->

      <div class="entry-content">
	<p>
	  <?php 
	    _e( 'No results were found for the requested archive. Try searching?', 'twentyeleven' ); 
	  ?>
	</p>
	<?php 
	    get_search_form(); 
	?>
      </div><!-- .entry-content -->
    </article><!-- #post-0 -->

    <?php 
	  }
    ?>

  </div><!-- #content -->
</div><!-- #primary -->

<?php 
  get_sidebar();
get_footer(); 
?>