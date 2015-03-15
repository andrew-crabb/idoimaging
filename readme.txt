3/11/15

Updated some Userbase code.  This will require moving encdata to public_html/login/.
These changes are not yet committed.
Database access on server is granted to % with password.
Now: mysql extension is deprecated.  But is it worth rewriting this if I am rewriting the whole site?
Next: Commit these edits and pull to server.
Then: Continue with /demo/ page.

working on cgi_bin/checklinkupdate.pl
Adding Github specific parser
Think I should be using HTML::TreeBuilder rather than HTML::Parse which is low level.
Now I'm trying Ruby and NokoGiri.

Ansible to maintain site:
- Symlink to wiki
