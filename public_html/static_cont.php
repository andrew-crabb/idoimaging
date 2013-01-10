<?php
if (isset($_GET['ident'])) {
  $content = $_GET['ident'];
  if (file_exists($content)) {
    require("static/${content}.php");
  }
}
?>
