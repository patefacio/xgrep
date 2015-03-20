# XGrep

A script for indexing directories and running find/grep operations on
those indices. All indices and filters are named and stored in a
database so they may be reused. Names of indices and filters must be
*snake_case*, eg (-i cpp_code) and (-f ignore_objs).

    xargs.dart [OPTIONS] [PATTERN...]

If no arguments are provided, a list of existing indices and filters
with their descriptions will be displayed.

If one or more indices or filters is supplied without other arguments
those item descriptions will be displayed.

## Index Creation

To create an index, provide a single -i argument and one or more path
arguments, with optional prune arguments. See [--path],
[--prune-name] options. Note: When an index is created its definition is
persisted and the actual index is created - (e.g. updatedb will run
creating an index database)

## Filter Creation

Note: the same flag (-f) is used to create filters and to reference
filters for searching. The only difference is the format dictates the
intent. Any spaces in the argument indicate a desire to create a
filter. See [-f] description below.

## Updating

If one or more indices is supplied with the update flag set, the
databases for the index/indices will be updated (e.g. *updatedb*
will be called to re-index)

## Searching

If one or more indices is supplied with zero or more filter arguments
and one or more remaining positional arguments, the positional
arguments become grep patterns and the command performs a grep against
all files files matching the indices with any filters applied.

    TODO:
    If one positional argument is provided without indices or any other
    arguments a the prior search is replacing the grep pattern with the
    positional argument.


    -u, --[no-]update             If set will update any specified indices
    -r, --[no-]remove-item        If set will remove any specified indices (-i) or filters (-f)
    -R, --[no-]remove-all         Remove all stored indices
    -l, --[no-]list               For any indices or filters provided, list associated
                                  items. For indices it lists all files, for filters
                                  lists the details.  Effectively *find* on the index
                                  and print on filter.

    -e, --[no-]emacs-support      Writes emacs file $HOME/.xgrep.el which contains
                                  functions for running various commands from emacs.

        --[no-]display-filters    Display all persisted filters
    -h, --[no-]help               Display this help screen
    -i, --index                   Id of index associated with command
    -p, --path                    Colon separated fields specifying path with
                                  pruning. Fields are:

                                   1: The path to include

                                   2: One or more path names (i.e. unqualified folder
                                      names) to prune

                                   e.g. -p /home/gnome/ebisu:cache:.pub:.git

    -P, --prune-name              Global prune names excluded from all paths
    -X, --prune-path              Fully qualified path existing somewhere within a path
                                  to be excluded

    -f, --filter                  Used to create a filter or reference one or more filters.
                                  If the argument has any white space it is attempting to
                                  create a single filter (with space delimited patterns).
                                  Otherwise it is referencing one or more filters. If there
                                  are only [\w_] characters, it is naming a single filter.
                                  Otherwise it is a deemed a pattern and finds all matching
                                  filters. This way you can do -f'c.*' and pull in all
                                  filters that start with 'c'.

                                  For filter creation, the argument must be of the form:

                                   -f'filter_id [+-] PATTERN... '

                                  Where the first word names the filter (e.g. filter_id), the '+'
                                  indicates desire to include, the '-' a desire to exclude. The
                                  following patterns are space delimited and can be either plain string
                                  or regex. If it contains only [\w_.] characters it is a string,
                                  otherwise it is considered a regex and must parse correctly.
                                  For example:

                                   -f'dart + \.dart$ \.html$ \.yaml$'

                                  persists a new filter named *dart* that includes *.dart*,
                                  *.html* and *.yaml* files. The following

                                   -f'ignore - ~$ .gitignore /\.git\b /\.pub\b'

                                  persists a new filter named *ignore* that excludes tilda files,
                                  *.gitignore* and any .git or .pub subfolders.

    -F, --anonymous-filter        Use the filter specified to restrict files searched
                                  The format is the same as (-f) except it is not named
                                  and therefore will be used but not persisted.

                                   -F'- ~$ .gitignore /\.git\b /\.pub\b'

                                  will filter out from the current search command tilda, .gitignore
                                  files and .git and .pub folders.

    -g, --grep-args               Arguments passed directly to grep
        --log-level               Select log level from:
                                  [ all, config, fine, finer, finest, info, levels,
                                    off, severe, shout, warning ]
----------------------------------------------------------------------
