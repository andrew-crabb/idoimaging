<!-- Row for 'Whats Popular' title image -->
<tr><td class='white' width='920' align='center'><h2 class='title'>What's Popular</h2></td></tr>

<!-- Row for 'Whats Popular' table -->
<tr><td class='white' width='920' align='center'>

<!-- Table for 3 columns of 'Most Popular' -->
<table width='920' border='0' cellspacing='0' cellpadding='5'>

<!-- 'Whats Popular' table row 0: Headings -->
<tr valign='top'>
<td width='300' class='white' valign='top' align='center'><h3 class='title'>Highest Ranked...</h3></td>
<td width='300' class='white' valign='top' align='center'><h3 class='title'>Most Visited...</h3></td>
<td width='300' class='white' valign='top' align='center'><h3 class='title'>Most Tracked.</h3></td>
</tr>

<!-- 'Whats Popular' table row 1: Text -->
<tr valign='top'>
<td width='300' class='white' valign='top' align='left'>
Based on number of monitors and visits to their site, and links to their web sites.
</td>
<td width='300' class='white' valign='top' align='left'>
Here are the most-followed links to external sites over the past week.
</td>
<td width='300' class='white' valign='top' align='left'>
Ranked by number of people receiving emails about program updates.
To track a program, <a class='green' href='/login?action=register'>create an Account</a>.
</td>
</tr>

<!-- 'Whats Popular' table row 2: Tables -->
<tr valign='top'>
<td width='300' class='white' valign='top' align='center'>
  <?php
    if (!$content->print_static_file_for(Content::MOST_RANKED)) {
      $content->virtual_or_exec(Content::MOST_RANKED);
    }
  ?>
</td>
<td width='300' class='white' valign='top' align='center'>
  <?php 
    if (!$content->print_static_file_for(Content::MOST_LINKED)) {
      $content->virtual_or_exec(Content::MOST_LINKED);
    }
  ?>
</td>
<td width='300' class='white' valign='top' align='center'>
 <?php 
    if (!$content->print_static_file_for(Content::MOST_WATCHED)) {
      $content->virtual_or_exec(Content::MOST_WATCHED);
    }
 ?>
</td>
</tr>

<!-- End of 'Whats Popular' table -->
</table>

<!-- End of row for 'Whats Popular' table -->
</td>
</tr>
