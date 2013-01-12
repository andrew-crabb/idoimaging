<?php
        // Following two calls need to be told not to follow REDIRECT_URL.
        $content->virtual_or_exec(Content::FOOTER   , false);
        $content->virtual_or_exec(Content::ANALYTICS, false);
      ?>
    </div>
  </body>
</html>
