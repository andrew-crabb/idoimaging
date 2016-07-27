<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
	<meta http-equiv="content-type" content="text/html; charset=UTF-8">
	<title> Software Demonstrations </title>
</head>
<body>
	<?php
	$urls = array(
		424 => array(
			'demo' => 'http://chafey.github.io/cornerstoneDemo',
			'home' => 'https://github.com/chafey/cornerstone',
			),
		);

	function idi_prog($progid) {
		echo "target='_blank' href='http://idoimaging.com/program/" . $progid . "'";
	}
	function idi_wiki($progid) {
		echo "target='_blank' href='http://idoimaging.com/wiki/tiki-index.php?page=program_" . $progid . "'";
	}
	function idi_redr($progid) {
		echo "target='_blank' href='http://idoimaging.com/redirect?field=homeurl&amp;table=program&amp;ident=" . $progid . "'";
	}
	function idi_demo($progid) {
		echo "target='_blank' href='http://idoimaging.com/demo/program/" . $progid . "'";
	}
	function idi_blog($blogid) {
		echo "target='_blank' href='http://idoimaging.com/blog/?p=" . $blogid . "'";
	}
	function icon($icn) {
		echo "<img class='img16' alt='' title='" . ucfirst($icn) . "' src='img/icn_" . $icn . "_0.png'>";
	}
	?>
	<table class="demo_prog center border1" width="650">
		<tbody>
			<!-- Introduction -->
			<tr><td colspan="3">
				Below are links to live demonstrations of free and open source medical imaging applications.  Some are DICOM viewers hosted on the 
				<a target="_blank" href="http://idoimaging.com/wiki/tiki-index.php?page=I+Do+Imaging+PACS">I Do Imaging PACS</a>,
				some are hosted on the project's home page.  Data in DICOM and other formats is available on the 
				<a target="_blank" href="http://idoimaging.com/wiki/tiki-index.php?page=Sample+Data">I Do Imaging Sample Data</a> page.
				<br />
				<br />
			</td></tr>
			<!-- Headings -->
			<tr>
				<th class="pad5" width="33%"> Program </th>
				<th class="pad5" width="34%"> Launch Demo </th>
				<th class="pad5" width="33%"> More Information </th>
			</tr>
			<!-- Orthanc Server -->
			<tr>
				<th class="pad5 demo_prog" colspan="3">Orthanc Server</th>
			</tr>
			<tr>
				<td class="pad10" width="33%">
					Runs on: <br />
					<?php icon('computer'); ?>&nbsp;&nbsp;<?php icon('mobile'); ?><br />
					HTML5/Browser<br />
					Launches into image server<br />
					Host: I Do Imaging<br />
					Version: 1.1.0 (6/27/16)<br />
				</td>
				<td class="pad10" width="34%">
					<a href='http://idoimaging.com:8042' target='blank' >
						<img alt="" src="img/orthanc_1_400.jpg" border="0" width="250">
					</a>
				</td>
				<td class="pad10" width="33%">
					<p><a <?php idi_redr(409);              ?> > Orthanc Home </a> </p>
					<p>I Do Imaging <a <?php idi_prog(409); ?> > Listing </a> </p>
					<p>I Do Imaging <a <?php idi_wiki(409); ?> > Wiki notes </a> </p>
				</td>
			</tr>
			<tr>
				<td class="pad10" colspan="3">
					Click on the above image to browse through the sample datasets on Orthanc server.  Two in-browser viewers are available 
					at the Series level: <a <?php idi_prog(451); ?> >Orthanc Web Viewer v. 2.2 (06/2016)</a> and <a <?php idi_prog(417); ?> >DWV Orthanc Plugin v. 0.13.0 (07/2016)</a>
				</td>
			</tr>
			<!-- Papaya -->
			<tr>
				<th class="pad5 demo_prog" colspan="3">Papaya Viewer</th>
			</tr>
			<tr>
				<td class="pad10" width="33%">
					Runs on: <br />
					<?php icon('computer'); ?>&nbsp;&nbsp;<?php icon('mobile'); ?><br />
					Javascript/Browser<br />
					Viewer launches directly<br />
					Host: I Do Imaging<br />
					Version: 0.6.5 (07/03/14)<br />
				</td>
				<td class="pad10" width="34%">
					<a <?php idi_demo(423); ?> >
						<img alt="" src="img/Papaya_Viewer_1_250.jpg" border="0" height="194" width="250">
					</a>
				</td>
				<td class="pad10" width="33%">
					<p><a <?php idi_redr(423); ?> > Papaya Home </a> </p>
					<p>I Do Imaging <a <?php idi_prog(423); ?> > Listing </a> </p>
					<p>I Do Imaging <a <?php idi_wiki(423); ?> > Wiki notes </a> </p>
				</td>
			</tr>
			<!-- DWV -->
			<tr>
				<th class="pad5 demo_prog" colspan="3">DWV: DICOM Web Viewer</th>
			</tr>
			<tr>
				<td class="pad10" width="33%">
					Runs on: <br />
					<?php icon('computer'); ?>&nbsp;&nbsp;<?php icon('mobile'); ?><br />
					HTML5/Browser<br />
					Viewer launches directly<br />
					Host: I Do Imaging PACS
					Version: 0.8.0 (11/20/14)<br />
				</td>
				<td class="pad10" align="center">
					<a target="_blank"
					href="http://idoimaging.com:8080/dwv/viewers/mobile/index.html?type=manifest&amp;input=http%3A%2F%2Fidoimaging.com%3A8080%2Fweasis-pacs-connector%2Fmanifest%3FseriesUID%3D1.3.6.1.4.1.5962.99.1.1647423216.1757746261.1397511827184.203.0">
					<img alt="DWV" src="img/dwv_0.jpg" border="0" height="177" width="150">
				</a> <br />
			</td>
			<td class="pad10" width="33%">
				<p><a <?php idi_redr(417); ?> > DWV Home </a></p>
				<p><a <?php idi_prog(417); ?> > I Do Imaging listing </a></p>
				<p><a <?php idi_blog(401); ?> > I Do Imaging blog entry </a></p>
				<p><a <?php idi_wiki(417); ?> > I Do Imaging wiki notes </a></p>
			</td>
		</tr>
		<!-- Cornerstone -->
		<tr>
			<th class="pad5 demo_prog" colspan="3">Cornerstone web imaging</th>
		</tr>
		<tr>
			<td class="pad10" width="33%">
				Runs on: <br />
				<?php icon('computer'); ?>&nbsp;&nbsp;
				<?php icon('mobile'); ?><br />
				HTML5/Browser<br />
				Viewer launches directly<br />
				Host: Cornerstone
			</td>
			<td class="pad10" align="center">
				<a target="_blank" href="http://chafey.github.io/cornerstoneDemo/">
					<img alt="" src="img/cornerstone_0_250.jpg" border="0"height="220" width="226">
				</a>
				<br />
			</td>
			<td class="pad10" width="33%">
				<a href="https://github.com/chafey/cornerstone">Cornerstone Home</a>
				<p><a <?php idi_prog(424); ?> > I Do Imaging listing </a></p>

				<br />
			</tr>
			<!-- iOviyam2 -->
			<tr>
				<th class="pad5 demo_prog" colspan="3">iOviyam2</th>
			</tr>
			<tr>
				<td class="pad10" width="33%">
					Runs on:<br />
					<?php icon('computer'); ?>&nbsp;&nbsp;
					<?php icon('mobile'); ?><br />
					HTML5/Browser<br />
					Links to PACS<br />
					Log in as 'guest' / 'guest'<br />
					Host: I Do Imaging PACS
				</td>
				<td class="pad10" align="center">
					<a target="_blank" href="http://idoimaging.com:8080/oviyam2/"> 
						<img alt="" src="img/iOviyam0.jpg" border="0" height="300"width="169">
					</a>
				</td>
				<td class="pad10" width="33%">
					<p><a <?php idi_redr(412); ?> > iOviyam2 Home </a></p>
					<p><a <?php idi_prog(412); ?> > I Do Imaging listing </a></p>
					<p><a <?php idi_blog(401); ?> > I Do Imaging blog entry </a></p>            
					<p><a <?php idi_wiki(412); ?> > I Do Imaging wiki notes </a></p>
				</td>
			</tr>
			<!-- Weasis -->
			<tr>
				<th class="pad5 demo_prog" colspan="3">Weasis</th>
			</tr>
			<tr>
				<td class="pad10" width="33%">
					Runs on: <br />
					<?php icon('computer'); ?><br />
					Java downloaded app<br />
					Links to PACS<br />
					Host: I Do Imaging PACS
				</td>
				<td class="pad10" align="center">
					<a target="_blank"
					href="http://idoimaging.com:8080/weasis-pacs-connector/viewer.jnlp?seriesUID=1.3.6.1.4.1.5962.99.1.1647423216.1757746261.1397511827184.7.0">
					<img alt="" src="img/weasis_brain_mr_0.jpg" border="0" height="229" width="250">
				</a><br />
			</td>
			<td class="pad10" width="33%">
				<p><a <?php idi_redr(403); ?> > Weasis Home </a></p>
				<p><a <?php idi_prog(403); ?> > I Do Imaging listing </a></p>
				<p><a <?php idi_blog(348); ?> > I Do Imaging blog entry </a></p>            
				<p><a <?php idi_wiki(403); ?> > I Do Imaging wiki notes </a></p>
			</td>
		</tr>
		<!-- SliceDrop -->
		<tr>
			<th class="pad5 demo_prog" colspan="3">Slice::Drop</th>
		</tr>
		<tr>
			<td class="pad10" width="33%">
				Runs on: <br />
				<?php icon('computer'); ?> (your data)
				<?php icon('mobile'); ?> (their data)<br />
				WebGL/HTML5<br />
				Drop local files on browser window<br />
				<br />
				<a href="http://idoimaging.com/data/dicom/1010_brain_mr/1010_brain_mr_04_lee.zip">
					Sample MRI DICOM files in zip format</a><br />
					(Download, unzip, drag and drop files onto SliceDrop window)<br />
					Host: SliceDrop site
				</td>
				<td class="pad10" align="center">
					<a target="_blank" href="http://slicedrop.com">
						<img alt="" src="img/slice_drop_0_250.jpg" border="0" height="220" width="250">
					</a>
					<br />
				</td>
				<td class="pad10" width="33%">
					<p><a <?php idi_redr(426); ?> > Slice:Drop Home </a></p>
					<p><a <?php idi_prog(426); ?> > I Do Imaging listing </a></p>
				</a><br />
			</td>
		</tr>
		<!-- BrainBrowser -->
		<tr>
			<th class="pad5 demo_prog" colspan="3">BrainBrowser</th>
		</tr>
		<tr>
			<td class="pad10" width="33%">
				Runs on: <br />
				<?php icon('computer'); ?><br />
				Host: BrainBrowser site
			</td>
			<td class="pad10" align="center">
				<a href="https://brainbrowser.cbrain.mcgill.ca">
					<img alt="" src="img/brainbrowser_0_250.jpg" border="0" height="250" width="233">
				</a><br />
			</td>
			<td class="pad10" width="33%">
				<p><a <?php idi_redr(427); ?> > BrainBrowser Home </a></p>
				<p><a <?php idi_prog(427); ?> > I Do Imaging listing </a></p>
			</td>
		</tr>
	</tbody>
</table>
</font>
</body>
</html>