MOTD poem files
===============

index.ini has a [motd] count= giving how many poem files exist. The
server picks one at random (1.txt, 2.txt, ... up to count) each time a
client requests text 0 (clientSendGetSysInfo), and sends it after the
banner.

Format
------
Plain text, one poem line per file line. Public-domain poetry only -
up to 8 lines or a single verse, short enough not to overstay its
welcome on a C64.

Line width: keep every line to 38 characters or fewer. The client
renders each line behind a 2-character "* " prefix into a 40-column,
41-byte log line buffer (2 prefix + up to 38 text + 1 null terminator
- see strsAppendMessage/LOGLINE_MAX in test.s), so anything longer
gets silently truncated at 38 rather than wrapping.

If a poem's own line is longer than that, split it across two file
lines and prefix the continuation with "/ " (counts toward the
38-char budget too, so up to 36 characters of text on the
continuation line) - e.g.:

    Could frame thy fearful
    / symmetry?

Adding a new poem
------------------
1. Add the next file, e.g. 3.txt.
2. Bump count= in index.ini to match.
