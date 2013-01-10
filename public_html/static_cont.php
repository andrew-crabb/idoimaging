<?php
if (isset($_GET['ident'])) {
  $content = $_GET['ident'];
  if (file_exits($content)) {
    require("static/${content}.php");
  }
}
?>
