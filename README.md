# Xgrep

A library and script for linux users that combines indexing
directories, specifying filter sets, and grepping of
files. Essentially it helps the user not have to remember the details
of and path inputs for *find | xargs grep...*

Are you a graybeard whose memory is not what it used to be?

Are you a die-hard emacs user getting somewhat envious of some of the
nice find capabilities of sublime?

Do you want to reduce the time it takes to do a find in all files you
are interested in from a simple command so you can use it from
terminal, emacs, or whatever?

# Purpose

The following is the intent:

* Allow persistence of index definitions - i.e. named collections of
  paths you frequently visit/search using *find/grep* or
  *updatedb/mlocate/grep*.

* Allow creation of file filter sets that can be incorporated into a
  search to weed out unwanted hits.

* Easily update your persisted indices. 

* Provide the *find|grep* equivalent combo in single script with less
  to remember

* Provide generation of $HOME/.xgrep.el for easy access to your
  grepping commands from emacs

# Prereqs/Notes

This uses MongoDB for the persistence of indices and filters.  It uses
updatedb/mlocate for the creation/search of directories. The databases
are stored in **$HOME/xgreps/...**

The default MongoDB uri is "mongodb://127.0.0.1/xgreps". You can
override this by setting the XGREP_MONGO_URI environment
variable.

If the -e option is used the file **$HOME/.xgreps.el** is written


# Examples

* Create an index of several project directories, in this case with
  some prune names:

        xgrep -i my_dart \\
        -p \$HOME/dev/open_source/id:.pub:.git \\           
        -p \$HOME/dev/open_source/xgrep:.pub:.git \\
        -p \$HOME/dev/open_source/ebisu:.pub:.git \\
        -p \$HOME/dev/open_source/ebisu_cpp:.pub:.git \\       

* Use that index to list all files:

        xgrep -i my_dart -l

* If you added/removed files, easily update the index

        xgrep -i my_dart -u

* Use the index to grep for stuff, like usage of *split* or *join* in all files

        xgrep -i my_dart split join

* Create many indices then grep over all files in all indices, since
  the named indices can be queried with pattern

        xgrep -i.* split join

  giving:

        .../ebisu_utils.dart:152:    result.add(guts.join(',\n'));
        .../ebisu_utils.dart:163:    result.add(guts.join(',\n'));
        ...
        .../ebisu_cpp.dart:448:template< ${decls.join(',\n          ')} >''';
        .../ebisu_cpp.dart:672:  return result.join('');
        .../ebisu_cpp.dart:676:    original.split('\n').map((l) => '"$l\\n"').join('\n');


* Similarly update all indices

        xgrep -i.* -u

* Generate emacs file with handy emacs functions for all your indices

        xgrep -e

  which will create functions like:

        (defun xgu-* ()
          "Update all xgrep indices"
          (interactive)
          (shell-command "xgrep -i.* -u" "update all xgrep indices"))

        (defun xg-my-dart (args)
          "Do an xgrep -i my_dart with additional args. Look for things in the index"
          (interactive "sEnter args:")
          (grep (concat "xgrep -i my_dart " args))
          (set-buffer "*grep*")
          (rename-buffer (concat "*xg-my-dart " args "*") t))

        (defun xgl-my-dart ()
          "List all files in the index my_dart"
          (interactive)
          (compile "xgrep -i my_dart -l")
          (set-buffer "*compilation*")
          (rename-buffer "*list of my_dart*" t))

        (defun xgu-my-dart ()
          "Update the index my_dart"
          (interactive)
          (grep "xgrep -i my_dart -u"))


