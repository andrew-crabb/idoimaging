<?PHP

# You can specify $users_allowed and/or $groups_allowed.
# A user only needs to match one in order to be allowed.
#
$users_allowed = "yournamehere,somebodyelse";
$groups_allowed = "member,other_groupname";

require($_SERVER['DOCUMENT_ROOT'] . "/login/ublock.php");

?>

Access granted!
