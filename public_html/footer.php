<!-- Begin footer -->
<tr><td class='white'></td></tr>

<tr id='footer_tr'>
	<td class='footer'>

		<!-- Facebook like -->


		<!-- Facebook page -->

		<a class='toleft' href="http://www.facebook.com/pages/I-Do-Imaging/170395076320501">
			<img src="/img/icon/links/facebook_16.png" style="vertical-align:middle" border="0" alt="Be a Facebook friend of I Do Imaging" />
			<img src="/img/icon/link_16/facebook_idi.png" style="vertical-align:middle" border="0" />
		</a>

		<!-- Twitter -->

		<a class='toleft' href="http://www.twitter.com/idoimaging">
			<img style="vertical-align:middle" border='0' src="/img/icon/links/twitter_16.png" alt="Follow idoimaging on Twitter" />
			<img style="vertical-align:middle" border='0' src="/img/icon/link_16/twitter_idi.png" alt="Follow idoimaging on Twitter" />
		</a>

		<!-- Email -->

		<a class='toleft'>
			<img src="/img/icon/link_16/email_icon.gif" style="vertical-align:middle" border="0" />
			<img src="/img/icon/link_16/email_idi.png" style="vertical-align:middle" border="0" />
		</a>

		<!-- LinkedIn -->

		<a class='toleft' href="http://www.linkedin.com/in/andrewcrabb" style="text-decoration:none;">
			<span style="font: 80% Arial,sans-serif; color:#0783B6;">
				<img src="/img/icon/links/linkedin_16.png"  alt="View Andrew Crabb's LinkedIn profile" style="vertical-align:middle" border="0" />&nbsp;
			</span>
		</a>

		<!-- Google Plus -->

		<a href="https://plus.google.com/103043218867576995891" rel="publisher">
			<img src="/img/icon/link_16/googleplus.gif" style="vertical-align:middle" border="0" />
		</a>


		<span class='toright'>Original content Copyright &#169; 2002-2013<br />Medical Imageworks LLC</span>

		<?php
		if (isset($this)) {
			$load_time = sprintf("%4.1f", microtime(true) - $this->util->start_time);
			print("<span class='toright space_right'>Loaded: $load_time s</span>\n");
		}
		?>

	</td>
</tr>  <!-- footer_tr -->
<!-- End footer -->
