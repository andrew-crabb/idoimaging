<h2 align=center> 
<?php 
// mod_rewrite Test Page 
// Copyright 2006 Webune.com 
   if($_GET['link']==1){echo"You are not using mod_rewrite";} 
   elseif($_GET['link']==2){echo"Congratulations!! You are using Apache mod_rewrite";} 
   else{echo"Linux Apache mod_rewrte Test Tutorial";} 
?> 
</h2> 

<hr> 

<head> 
<title>How To Test mod_rewrite in Apache Linux Server</title> 
</head> 

<body> 
<p align="center">by <a href="http://www.webune.com">Webune</a></p> 
<p><a href="rewrite.php?link=1">LINK1</a> = rewrite.php?link=1</p>
<p><a href="link2.html">LINK2</a> = link2.html</p> 
<p>How this works: both links are for this same page, except they both are different. link one is without the mod_rewrite and link2 is using mod_rewrite. Link1 show the php file, with with mod_rewrite we are mascarading the php file into a html file. you can use whatever type of extension you want, you can change it to .htm or .shtml etc... all you have to do is to make sure you also chang it in the .htaccess file</p> 
<p>&lt;&lt; <a href="http://www.webune.com/forums/viewtopic-p-62.html">Go back to webune forums.</a></p> 
</body> 
</html> 
