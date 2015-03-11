import "dart:io";
import "package:path/path.dart" as path;
import "package:id/id.dart";
import "package:ebisu/ebisu.dart";
import "package:ebisu/ebisu_dart_meta.dart";
import "package:logging/logging.dart";

void main() {
  Logger.root.onRecord.listen((LogRecord r) =>
      print("${r.loggerName} [${r.level}]:\t${r.message}"));

  String here = path.absolute(Platform.script.path);
  final topDir = path.dirname(path.dirname(here));
  useDartFormatter = true;
  System ebisu = system('xgrep')
    ..includeHop = true
    ..license = 'boost'
    ..rootPath = topDir
    ..pubSpec = (pubspec('xgrep')
        ..version = '0.0.2'
        ..doc = 'A library/script for locating/grepping things on linux'
        ..homepage = 'https://github.com/patefacio/xgrep'
                 )
    ..doc = 'Package providing support for advanced find/grep'
    ..scripts = [
      script('xgrep')
      ..isAsync = true
      ..doc = r"""
A script for indexing directories and running find/grep operations on
those indices. All indices and filters are named and stored in a
database so they may be reused. Names of indices and filters must be
*snake_case*, eg (-i cpp_code) and (-f ignore_objs).

xargs.dart [OPTIONS] [PATTERN...]

If no arguments are provided, a list of existing indices and filters
with their descriptions will be displayed.

If one or more indices or filters is supplied without other arguments
those item descriptions will be displayed.

# Index Creation

To create an index, provide a single -i argument and one or more path
arguments, with optional prune arguments. See [--path],
[--prune-name] options. Note: When an index is created its definition is
persisted and the actual index is created - (e.g. updatedb will run
creating an index database)

# Filter Creation

Note: the same flag (-f) is used to create filters and to reference
filters for searching. The only difference is the format dictates the
intent. Any spaces in the argument indicate a desire to create a
filter. See [-f] description below.

# Updating

If one or more indices is supplied with the update flag set, the
databases for the index/indices will be updated (e.g. *updatedb*
will be called to re-index)

# Searching

If one or more indices is supplied with zero or more filter arguments
and one or more remaining positional arguments, the positional
arguments become grep patterns and the command performs a grep against
all files files matching the indices with any filters applied.

TODO:
If one positional argument is provided without indices or any other
arguments a the prior search is replacing the grep pattern with the
positional argument.
"""
      ..imports = [
        'package:xgrep/xgrep.dart',
        'package:id/id.dart',
        'package:path/path.dart',
        'async',
      ]
      ..classes = [
        class_('arg_processor')
        ..doc = '''
All arguments for processing as a unit.
'''
        ..members = [
          member('args')..type = 'List<String>',
          member('options')..type = 'Map',
          member('positionals')..type = 'List<String>',
          member('index_args')..type = 'List<String>',
          member('path_args')..type = 'List<String>',
          member('prune_name_args')..type = 'List<String>',
          member('prune_path_args')..type = 'List<String>',
          member('filter_args')..type = 'List<String>',
          member('immediate_filter_args')..type = 'List<String>',

          // Flags/commands ars
          member('update_flag')..type = 'bool',
          member('remove_item_flag')..type = 'bool',
          member('remove_all_flag')..type = 'bool',
          member('list_flag')..type = 'bool',
          member('display_filters_flag')..type = 'bool',
          member('emacs_support_flag')..type = 'bool',

          member('grep_args')..type = 'List<String>',

          member('indices')..type = 'List<Index>'..access = IA,
          member('filters')..type = 'List<Filter>'..access = IA,
          member('path_map')..type = 'Map<String,PruneSpec>'..classInit = {},
        ]

      ]
      ..args = [
        scriptArg('index')
        ..doc = 'Id of index associated with command'
        ..type = ArgType.STRING
        ..isMultiple = true
        ..abbr = 'i',
        scriptArg('path')
        ..doc = '''
Colon separated fields specifying path with
pruning. Fields are:

 1: The path to include

 2: One or more path names (i.e. unqualified folder
    names) to prune

 e.g. -p /home/gnome/ebisu:cache:.pub:.git
'''
        ..type = ArgType.STRING
        ..isMultiple = true
        ..abbr = 'p',
        scriptArg('prune_name')
        ..doc = 'Global prune names excluded from all paths'
        ..type = ArgType.STRING
        ..abbr = 'P'
        ..isMultiple = true,
        scriptArg('prune_path')
        ..doc = '''
Fully qualified path existing somewhere within a path
to be excluded
'''
        ..type = ArgType.STRING
        ..abbr = 'X'
        ..isMultiple = true,
        scriptArg('update')
        ..doc = 'If set will update any specified indices'
        ..type = ArgType.STRING
        ..abbr = 'u'
        ..isFlag = true,
        scriptArg('remove_item')
        ..doc = 'If set will remove any specified indices (-i) or filters (-f)'
        ..type = ArgType.STRING
        ..abbr = 'r'
        ..isFlag = true,
        scriptArg('remove_all')
        ..doc = 'Remove all stored indices'
        ..type = ArgType.STRING
        ..isFlag = true
        ..abbr = 'R',
        scriptArg('list')
        ..doc = '''
For any indices or filters provided, list associated
items. For indices it lists all files, for filters
lists the details.  Effectively *find* on the index
and print on filter.'''
        ..abbr = 'l'
        ..isFlag = true,
        scriptArg('emacs_support')
        ..doc = r'''
Writes emacs file $HOME/.xgrep.el which contains
functions for running various commands from emacs.'''
        ..abbr = 'e'
        ..isFlag = true,
        scriptArg('display_filters')
        ..doc = 'Display all persisted filters'
        ..isFlag = true,
        scriptArg('filter')
        ..doc = r"""
Used to create a filter or reference one or more filters.
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

"""
        ..type = ArgType.STRING
        ..abbr = 'f'
        ..isMultiple = true,
        scriptArg('immediate_filter')
        ..doc = r"""
Use the filter specified to restrict files searched
The format is the same as (-f) except it is not named
and therefore will be used but not persisted.

 -F'- ~$ .gitignore /\.git\b /\.pub\b'

will filter out from the current search command tilda, .gitignore
files and .git and .pub folders.
"""
        ..type = ArgType.STRING
        ..isMultiple = true
        ..abbr = 'F',
        scriptArg('grep_args')
        ..doc = 'Arguments passed directly to grep'
        ..abbr = 'g'
        ..isMultiple = true,
      ]
    ]
    ..testLibraries = [
      library('test_index'),
      library('test_filter'),
      library('test_mongo_index_persister')
      ..includeLogger = true,
      library('test_mlocate_index_updater')
      ..includeLogger = true,
      library('test_xgrep_script'),
    ]
    ..libraries = [
      library('xgrep')
      ..includeLogger = true
      ..imports = [
        '"package:path/path.dart" as path',
        "'package:ebisu/ebisu_utils.dart' as ebisu_utils",
        'package:id/id.dart',
        'package:quiver/iterables.dart',
        'package:mongo_dart/mongo_dart.dart',
        'io',
        'async',
        'convert',
      ]
      ..parts = [
        part('index')
        ..classes = [
          class_('filter')
          ..immutable = true
          ..doc = r"""
A list of patterns and a flag indicating whether this is an inclusion
filter.
"""
          ..opEquals = true
          ..members = ([
            member('id')
            ..doc = 'Uniquely identifies the filter set'
            ..type = 'Id',
            member('is_inclusion')
            ..classInit = false,
            member('patterns')
            ..doc = 'List of string patterns comprising the filter'
            ..type = 'List<String>',
          ].map((m) => m..access = RO)).toList(),
          class_('prune_spec')
          ..doc = '''
Comparable to *prune* flags on *updatedb* linux command.
'''
          ..immutable = true
          ..opEquals = true
          ..jsonSupport = true
          ..members = [
            member('names')
            ..doc = '''
Directory names (without paths) which should not be included in a path database.'''
            ..type = 'List<String>'..classInit = [],
            member('paths')
            .. doc = '''
Fully qualified paths which should not be included in a path database.'''
            ..type = 'List<String>'..classInit = [],
          ],
          class_('find_args')
          ..immutable = true
          ..members = [
            member('includes')..type = 'List<RegExp>'..classInit = [],
            member('excludes')..type = 'List<RegExp>'..classInit = [],
          ],
          class_('index')
          ..doc = '''
Defines a name index which establishes a set of filesystem paths that can be
indexed and later searched.
'''
          ..opEquals = true
          ..members = [
            member('id')..type = 'Id'..access = RO,
            member('paths')
            ..doc = '''
Paths to include in the index mapped with any corresponding pruning specific to
that path'''
            ..type = 'Map<String, PruneSpec>'..access = RO,
            member('prune_names')
            ..doc = 'Global set of names to prune on all paths in this index'
            ..type = 'List<String>'
            ..access = RO
          ],
          class_('index_stats')
          ..immutable = true
          ..members = [
            member('index')..type = 'Index',
            member('last_update')..type = 'DateTime',
          ],
          class_('index_persister')
          ..doc = '''
Establishes an interface that persists *Indices* as well as other
meta-data associated with the creation, update, and usage those
*Indices*.
'''
          ..isAbstract = true
          ..members = [
            member('connect_future')..type = 'Future'..access = IA
          ],
          class_('index_updater')
          ..doc = '''
Establishes an interface that is used to update indices on the
filesystem using some for of indexer like the Linux *updatedb*
command. Also provides support for finding matching files associated
with an index.'''
          ..isAbstract = true,
          class_('indexer')
          ..immutable = true
          ..members = [
            member('index_persister')..type = 'IndexPersister',
            member('index_updater')..type = 'IndexUpdater'
          ],
        ],
        part('mongo_index_persister')
        ..classes = [
          class_('mongo_index_persister')
          ..doc = '''
Default implementation of an [IndexPersister] which stores index
information in *MongoDB*'''
          ..extend =  'IndexPersister'
          ..members = [
            member('uri')..isFinal = true..access = RO,
            member('db')..access = IA..type = 'Db',
            member('indices')..access = IA..type = 'DbCollection',
            member('filters')..access = IA..type = 'DbCollection',
          ]
        ],
        part('mlocate_index_updater')
        ..classes = [
          class_('mlocate_index_updater')
          ..doc = '''
Default implementation of an [IndexUpdater] which manages indices with
Linux *updatedb* and *mlocate*'''
          ..extend = 'IndexUpdater'
        ],
        part('grep'),
      ],
    ];

  ebisu.generate();
}