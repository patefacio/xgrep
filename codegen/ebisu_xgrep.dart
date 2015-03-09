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
  formatPrunes = [ new RegExp(r'/bin/xgrep.dart\b') ];
  System ebisu = system('xgrep')
    ..includeHop = true
    ..license = 'boost'
    ..rootPath = topDir
    ..doc = 'Package providing support for advanced find/grep'
    ..scripts = [
      script('xgrep')
      ..isAsync = true
      ..doc = '''

xargs.dart [OPTIONS] [PATTERN...]

A script for indexing directories for the purpose of doing find/greps
on those indices.

If no arguments are provided, a list of existing indices will be
displayed.

If one or more indices is supplied without other arguments, a list of
files in the index (indices) will be output. Effectively a *find*
operation.

If a single index is supplied with any paths it will be considered an
index definition and first persist the index and then update it.

If one or more indices is supplied with the update flag set, the
databases for the index (indices) will be updated (e.g. *updatedb*
will be called to re-index)

If one or more indices is supplied with one additional argument, that
argument is the grep pattern and is grepped on all files in all
specified indices.

If one positional argument is provided without indices or any other
arguments a the prior search is replacing the grep pattern with the
positional argument.

'''
      ..imports = [
        'package:xgrep/xgrep.dart',
        'package:id/id.dart',
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
          member('grep_args')..type = 'List<String>',

          member('indices')..type = 'List<Index>'..access = IA,
          member('filters')..type = 'List<FilenameFilterSet>'..access = IA,
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
For any indices or filters provided, list associated items. For indices
it lists all files, for filters lists the details.
Effectively *find* on the index and print on filter.'''
        ..abbr = 'l'
        ..isFlag = true,
        scriptArg('display_filters')
        ..doc = 'Display all persisted filters'
        ..isFlag = true,
        scriptArg('filter')
        ..doc = r"""
Specifies a filter. If the argument is a single
identifier it must repsent a filter stored in the
database, to be used in the find/grep operation.

If the argument more than just an identifier it is
considered a filter definition and must be of the
form:

  filter_identifier;inclusions;exclusions

Both inclusions and exclusions are comma separated
fields representing patterns to include/exclude. If a
pattern has non-word characters (i.e. not [\w_.]) it
assumed to be a regex and the filtering is matched
case insensitively. Otherwise the field is a string
and is matched exactly.

Examples:

-f 'dart_filter;\.dart$,\.html$,\.yaml$;\.js$,.*~$'
-f 'cpp_filter;\.(?:hpp|cpp|c|h|inl|cxx)$;'

The first extablishes a filter named *dart_filter*
that includes dart, html and yaml files and excludes
js and tilda files.

-i my_oss -f dart_filter -f cpp_filter join split

These flags will search index *my_oss* filtering to
*dart_filter* and *cpp_filter* looking for the words
*join* and *split*
"""
        ..type = ArgType.STRING
        ..abbr = 'f'
        ..isMultiple = true,
        scriptArg('immediate_filter')
        ..doc = r"""
Use the filter specified to restrict files searched
The format must be two fields separated by a single
semicolon where each field represents a pattern:

-F'\.(?:hpp|cpp|c|h|inl|cxx)$;'
-F';\.(?:\.obj|\.a)'

The first says to *include* some c++ type files and leaves
the *exclude* field blank. The second says to exclude
.obj and .a files See [create_filter] option
for more on how the patterns are interpreted. Note:
the use of semicolon prevents collisions with group
regex expressions.
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
          class_('filename_filter_set')
          ..doc = r"""
List of regex filters for inclusion/exclusion of
files on find operation.

So the following:

    FilenameFilterSet([ '\.dart$', '\.yaml$' ], [ '\.js$' ])

would include *dart* and *yaml* files and exclude
javascript *files*
"""
          ..opEquals = true
          ..members = ([
            member('id')
            ..doc = 'Uniquely identifies the filter set'
            ..type = 'Id',
            member('include')
            ..doc = 'List of string patterns interpreted as RegExp to *include*'
            ..type = 'List<String>',
            member('exclude')
            ..doc = 'List of string patterns interpreted as RegExp to *exclude*'
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
            member('filter_sets')..access = IA..type = 'DbCollection',
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