<?php
if (isset($_GET['ident'])) {
  $content = $_GET['ident'];
  require("static/${content}.php");
}
?>
