#!/usr/bin/env dart
/// A script for indexing directories and running find/grep operations on
/// those indices. All indices and filters are named and stored in a
/// database so they may be reused. Names of indices and filters must be
/// *snake_case*, eg (-i cpp_code) and (-f ignore_objs).
///
/// xargs.dart [OPTIONS] [PATTERN...]
///
/// If no arguments are provided, a list of existing indices and filters
/// with their descriptions will be displayed.
///
/// If one or more indices or filters is supplied without other arguments
/// those item descriptions will be displayed.
///
/// # Index Creation
///
/// To create an index, provide a single -i argument and one or more path
/// arguments, with optional prune arguments. See [--path],
/// [--prune-name] options. Note: When an index is created its definition is
/// persisted and the actual index is created - (e.g. updatedb will run
/// creating an index database)
///
/// # Filter Creation
///
/// Note: the same flag (-f) is used to create filters and to reference
/// filters for searching. The only difference is the format dictates the
/// intent. Any spaces in the argument indicate a desire to create a
/// filter. See [-f] description below.
///
/// # Updating
///
/// If one or more indices is supplied with the update flag set, the
/// databases for the index/indices will be updated (e.g. *updatedb*
/// will be called to re-index)
///
/// # Searching
///
/// If one or more indices is supplied with zero or more filter arguments
/// and one or more remaining positional arguments, the positional
/// arguments become grep patterns and the command performs a grep against
/// all files files matching the indices with any filters applied.
///
/// TODO:
/// If one positional argument is provided without indices or any other
/// arguments a the prior search is replacing the grep pattern with the
/// positional argument.
///

import 'dart:async';
import 'dart:io';
import 'package:args/args.dart';
import 'package:id/id.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart';
import 'package:xgrep/xgrep.dart';

//! The parser for this script
ArgParser _parser;

//! The comment and usage associated with this script
void _usage() {
  print(r'''
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

''');
  print(_parser.getUsage());
}

//! Method to parse command line options.
//! The result is a map containing all options, including positional options
Map _parseArgs(List<String> args) {
  ArgResults argResults;
  Map result = {};
  List remaining = [];

  _parser = new ArgParser();
  try {
    /// Fill in expectations of the parser
    _parser.addFlag('update', help: r'''
If set will update any specified indices
''', abbr: 'u', defaultsTo: false);
    _parser.addFlag('remove-item', help: r'''
If set will remove any specified indices (-i) or filters (-f)
''', abbr: 'r', defaultsTo: false);
    _parser.addFlag('remove-all', help: r'''
Remove all stored indices
''', abbr: 'R', defaultsTo: false);
    _parser.addFlag('list', help: r'''
For any indices or filters provided, list associated
items. For indices it lists all files, for filters
lists the details.  Effectively *find* on the index
and print on filter.
''', abbr: 'l', defaultsTo: false);
    _parser.addFlag('emacs-support', help: r'''
Writes emacs file $HOME/.xgrep.el which contains
functions for running various commands from emacs.
''', abbr: 'e', defaultsTo: false);
    _parser.addFlag('display-filters', help: r'''
Display all persisted filters
''', abbr: null, defaultsTo: false);
    _parser.addFlag('help', help: r'''
Display this help screen
''', abbr: 'h', defaultsTo: false);

    _parser.addOption('index', help: r'''
Id of index associated with command
''', defaultsTo: null, allowMultiple: true, abbr: 'i', allowed: null);
    _parser.addOption('path', help: r'''
Colon separated fields specifying path with
pruning. Fields are:

 1: The path to include

 2: One or more path names (i.e. unqualified folder
    names) to prune

 e.g. -p /home/gnome/ebisu:cache:.pub:.git

''', defaultsTo: null, allowMultiple: true, abbr: 'p', allowed: null);
    _parser.addOption('prune-name', help: r'''
Global prune names excluded from all paths
''', defaultsTo: null, allowMultiple: true, abbr: 'P', allowed: null);
    _parser.addOption('prune-path', help: r'''
Fully qualified path existing somewhere within a path
to be excluded

''', defaultsTo: null, allowMultiple: true, abbr: 'X', allowed: null);
    _parser.addOption('filter', help: r'''
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

''', defaultsTo: null, allowMultiple: true, abbr: 'f', allowed: null);
    _parser.addOption('immediate-filter', help: r'''
Use the filter specified to restrict files searched
The format is the same as (-f) except it is not named
and therefore will be used but not persisted.

 -F'- ~$ .gitignore /\.git\b /\.pub\b'

will filter out from the current search command tilda, .gitignore
files and .git and .pub folders.

''', defaultsTo: null, allowMultiple: true, abbr: 'F', allowed: null);
    _parser.addOption('grep-args', help: r'''
Arguments passed directly to grep
''', defaultsTo: null, allowMultiple: true, abbr: 'g', allowed: null);
    _parser.addOption('log-level', help: r'''
Select log level from:
[ all, config, fine, finer, finest, info, levels,
  off, severe, shout, warning ]

''', defaultsTo: null, allowMultiple: false, abbr: null, allowed: null);

    /// Parse the command line options (excluding the script)
    argResults = _parser.parse(args);
    if (argResults.wasParsed('help')) {
      _usage();
      exit(0);
    }
    result['index'] = argResults['index'];
    result['path'] = argResults['path'];
    result['prune-name'] = argResults['prune-name'];
    result['prune-path'] = argResults['prune-path'];
    result['update'] = argResults['update'];
    result['remove-item'] = argResults['remove-item'];
    result['remove-all'] = argResults['remove-all'];
    result['list'] = argResults['list'];
    result['emacs-support'] = argResults['emacs-support'];
    result['display-filters'] = argResults['display-filters'];
    result['filter'] = argResults['filter'];
    result['immediate-filter'] = argResults['immediate-filter'];
    result['grep-args'] = argResults['grep-args'];
    result['help'] = argResults['help'];
    result['log-level'] = argResults['log-level'];

    if (result['log-level'] != null) {
      const choices = const {
        'all': Level.ALL,
        'config': Level.CONFIG,
        'fine': Level.FINE,
        'finer': Level.FINER,
        'finest': Level.FINEST,
        'info': Level.INFO,
        'levels': Level.LEVELS,
        'off': Level.OFF,
        'severe': Level.SEVERE,
        'shout': Level.SHOUT,
        'warning': Level.WARNING
      };
      final selection = choices[result['log-level'].toLowerCase()];
      if (selection != null) Logger.root.level = selection;
    }

    return {'options': result, 'rest': argResults.rest};
  } catch (e) {
    _usage();
    throw e;
  }
}

final _logger = new Logger('xgrep');

/// All arguments for processing as a unit.
///
class ArgProcessor {
  List<String> args;
  Map options;
  List<String> positionals;
  List<String> indexArgs;
  List<String> pathArgs;
  List<String> pruneNameArgs;
  List<String> prunePathArgs;
  List<String> filterArgs;
  List<String> immediateFilterArgs;
  bool updateFlag;
  bool removeItemFlag;
  bool removeAllFlag;
  bool listFlag;
  bool displayFiltersFlag;
  bool emacsSupportFlag;
  List<String> grepArgs;
  Map<String, PruneSpec> pathMap = {};
  // custom <class ArgProcessor>

  ArgProcessor(List<String> this.args, Map options, List<String> positionals)
      : this.options = options,
        this.positionals = positionals,
        indexArgs = options['index'],
        pathArgs = options['path'],
        pruneNameArgs = options['prune-name'],
        prunePathArgs = options['prune-path'],
        filterArgs = options['filter'],
        immediateFilterArgs = options['immediate-filter'],
        grepArgs = options['grep-args'],
        updateFlag = options['update'],
        removeItemFlag = options['remove-item'],
        removeAllFlag = options['remove-all'],
        listFlag = options['list'],
        displayFiltersFlag = options['display-filters'],
        emacsSupportFlag = options['emacs-support'];

  toString() => """
indexArgs: $indexArgs
pathArgs: $pathArgs
pruneNameArgs: $pruneNameArgs
prunePathArgs: $prunePathArgs
filterArgs: $filterArgs
immediateFilterArgs: $immediateFilterArgs
update: $updateFlag
removeItem: $removeItemFlag
removeAll: $removeAllFlag
list: $listFlag
displayFilters: $displayFiltersFlag
emacsSupportFlag: $emacsSupportFlag
""";

  bool get hasIndices => !indexArgs.isEmpty;
  bool get hasFilters => !filterArgs.isEmpty;
  bool get impliesIndexCreation => !pathArgs.isEmpty;
  bool get impliesGrep => hasIndices && !positionals.isEmpty;
  bool get impliesUpdate => updateFlag;
  bool get impliesRemoval => removeItemFlag || removeAllFlag;
  bool get impliesListFiles => hasIndices && listFlag;

  final snakeCharsRe = new RegExp(r'^[\w_]+$');
  isSnake(s) => snakeCharsRe.hasMatch(s);
  isMatch(String s, Id id) =>
      isSnake(s) ? (s == id.snake) : id.snake.contains(new RegExp(s));

  process() => Indexer.withIndexer((Indexer indexer) async {
    _logger.info('${new DateTime.now()}: Processing $args');

    if (emacsSupportFlag) {
      await updateEmacsFile(indexer);
    }

    if (impliesRemoval) {
      if (!positionals.isEmpty) {
        exitWith('When removing filters or indices, '
            'positionals args must be empty');
      }
      return removeItems(indexer);
    } else if (!hasIndices && !hasFilters && positionals.isEmpty) {
      await printIndices(indexer);
      await printFilters(indexer);
    } else {
      createNewFilters(indexer);

      /// Deterimine if this is
      /// - index creation
      /// - grep operation (with optional filter creation)
      /// - removal operation
      /// - find operation (with optional filter creation)
      if (impliesIndexCreation) {
        if (indexArgs.length == 1) {
          await createIndex(indexer);
        } else {
          reportCreateIndexError();
        }
      } else if (impliesUpdate) {
        if (hasIndices) {
          if (hasFilters) _logger
              .warning('When doing update filters $fliterArgs are not used');
          final targetIndices = (await matchingIndices(indexer));
          targetIndices.forEach((Index index) async => await indexer
              .updateIndex(index)
              .then((_) => announceIndexOpComplete('Updated', index)));
        }
      } else if (impliesGrep) {
        final targetIndices = (await matchingIndices(indexer));
        final filters = (await matchingFilters(indexer));
        positionals.forEach(
            (String positional) => grepArgs.addAll(['-e', positional]));
        return grepWithIndexer(targetIndices, grepArgs, indexer, filters);
      } else if (impliesListFiles) {
        return listFiles(indexer);
      } else if (hasIndices || hasFilters) {
        return listItems(indexer);
      }
    }
  });

  /// Scans filter options (-f...) for filter creates. For each persists the
  /// filter, then pushes the argument on the list of filterArgs for later
  /// processing. This approach allows new filters to be created/modified
  /// in the grep/locate itself
  /// e.g.
  /// xgrep -i dart -f'dart_filter \.dart$ \.html$ \.yaml$ @ \.js$ .*~$' switch
  ///
  /// This will persist the *dart_filer* then grep for swithc in index *dart*
  /// using that filter
  createNewFilters(indexer) async {
    final creationFilters = [];
    filterArgs.removeWhere((String arg) {
      final match = arg.contains(' ');
      if (match) creationFilters.add(arg);
      return match;
    });

    if (!creationFilters.isEmpty) {
      creationFilters.forEach((String filterArg) async {
        final filter = new Filter.fromArg(filterArg);
        await indexer.persistFilter(filter);
        announceFilterOpComplete('Saved', filter);
        filterArgs.addAll(['-f', filter.id.snake]);
      });
    }
  }

  createIndex(indexer) async {
    _logger.info('Creating index ${indexArgs.first}');
    final map = {};
    for (final path in pathArgs) {
      final parts = path.split(':');
      assert(!parts.isEmpty);
      map[parts.first] = (parts.length == 1)
          ? emptyPruneSpec
          : new PruneSpec(parts.sublist(1), []);
    }
    final index = new Index.withPruning(idFromString(indexArgs.first), map);
    await indexer.saveAndUpdateIndex(index);
    announceIndexOpComplete('Created/updated', index);
  }

  announceFilterOpComplete(String op, Filter filter) {
    print('$op filter *${nameItem(filter)}*');
    printFilenameFilter(filter);
  }

  announceIndexOpComplete(String op, Index index) {
    print('$op index *${nameItem(index)}*');
    printIndex(index);
  }

  listItems(indexer) async {
    (await matchingIndices(indexer)).forEach(printIndex);
    (await matchingFilters(indexer)).forEach(printFilenameFilter);
  }

  removeItems(indexer) async {
    if (removeAllFlag) {
      print('Are you sure you want to remove all indices: [N/Y]?');
      final ans = stdin.readLineSync();
      const doIt = const ['Y', 'y', 'yes', 'Yes'];
      if (doIt.contains(ans)) {
        print('Deleting all items');
        await indexer.removeAllItems();
      } else {
        print('Nothing removed: Dodged a bullet there');
      }
    } else {
      if (indexArgs.isEmpty && filterArgs.isEmpty) {
        assert(removeItemFlag);
        exitWith('''
remove-item requires -i and/or -f specifying named items to remove''');
      } else {
        await removeSpecifiedIndices(indexer);
        await removeSpecifiedFilters(indexer);
        _logger.info('Completed item removal');
      }
    }
  }

  listFiles(indexer) async {
    final indices = await matchingIndices(indexer);
    final filters = (await matchingFilters(indexer));
    for (final index in indices) {
      _logger.info('Listing files for ${nameItem(index)}');
      await indexer.processPaths(index, (path) => print(path), filters);
    }
  }

  matchingIndices(Indexer indexer) async {
    if (_indices != null) return _indices;
    final indicesAvailable = (await indexer.indices);
    _indices = indicesAvailable
        .where(
            (Index index) => indexArgs.any((String s) => isMatch(s, index.id)))
        .toList();
    _logger.info('Matching indices ${nameItems(_indices).toList()}');
    if (_indices.isEmpty) {
      print('Could find no matching indexes on $indexArgs');
    }
    return _indices;
  }

  matchingFilters(Indexer indexer) async {
    if (_filters != null) return _filters;
    _filters = (await indexer.filters)
        .where((Filter filter) =>
            filterArgs.any((String s) => isMatch(s, filter.id)))
        .toList();
    _logger.info('Matching filters ${nameItems(_filters).toList()}');
    return _filters;
  }

  removeSpecifiedIndices(Indexer indexer) => matchingIndices(indexer).then(
      (List<Index> indices) async {
    _logger.info('Removing indices $indexArgs matching '
        '${nameItems(indices).toList()}');
    indices.forEach((Index index) async {
      await indexer.removeIndex(index.id);
      announceIndexOpComplete('Removed', index);
    });
  });

  removeSpecifiedFilters(Indexer indexer) => matchingFilters(indexer).then(
      (List<Filter> filters) {
    _logger.info('Removing filters $filterArgs matching '
        '${nameItems(filters).toList()}');
  });

  updateEmacsFile(Indexer indexer) async {
    final theIndices = (await indexer.indices);
    List parts = [
      '''
(defun xg (args)
  "Run xgrep with all args supplied"
  (interactive "sEnter args:")
  (grep (concat "xgrep " args))
  (set-buffer "*grep*")
  (rename-buffer (concat "*xg " args "*") t))

(defun xgi (args)
  "Run xgrep ignoring case with all args supplied"
  (interactive "sEnter args:")
  (grep (concat "xgrep -g-i " args))
  (set-buffer "*grep*")
  (rename-buffer (concat "*xg " args "*") t))

(defun xgu-* ()
  "Update all xgrep indices"
  (interactive)
  (shell-command "xgrep -i.* -u" "update all xgrep indices"))
''',
    ];
    for (final index in theIndices) {
      final snakeId = index.id.snake;
      final eid = index.id.emacs;
      parts.add('''
(defun xg-$eid (args)
  "Do an xgrep -i $snakeId with additional args. Look for things in the index"
  (interactive "sEnter args:")
  (grep (concat "xgrep -i $snakeId " args))
  (set-buffer "*grep*")
  (rename-buffer (concat "*xg-$eid " args "*") t))

(defun xgi-$eid (args)
  "Do an xgrep -i $snakeId with additional args ignoring case. Look for things in the index"
  (interactive "sEnter args:")
  (grep (concat "xgrep -i $snakeId -g-i " args))
  (set-buffer "*grep*")
  (rename-buffer (concat "*xg-$eid " args "*") t))

(defun xgl-$eid ()
  "List all files in the index $snakeId"
  (interactive)
  (compile "xgrep -i $snakeId -l")
  (set-buffer "*compilation*")
  (rename-buffer "*list of $snakeId*" t))

(defun xgu-$eid ()
  "Update the index $snakeId"
  (interactive)
  (grep "xgrep -i $snakeId -u"))

''');
    }
    final efile = join(Platform.environment['HOME'], '.xgrep.el');
    new File(efile).writeAsStringSync(parts.join('\n'));
    print('Wrote $efile');
  }

  exitWith(String err) {
    print(err);
    exit(-1);
  }

  reportCreateIndexError() {
    exitWith((indexArgs.isEmpty)
        ? '''
You have paths specified ($pathArgs),
indicating a desire to create an index but no named index.
Please name the index - e.g.:

xgrep -i my_dart \\
   -p \$HOME/dev/open_source/xgrep:.pub:.git \\
   -p \$HOME/dev/open_source/ebisu:.pub:.git
'''
        : '''
You have specified path arguments:($pathArgs)
with multiple indices: ($indexArgs)

Path arguments imply desire to create an index of paths and
you can only create one index at a time. Use a single -i in
conjunction with one or more paths (-p) and optionally some
pruning.

xgrep -i my_dart \\
   -p \$HOME/dev/open_source/xgrep:.pub:.git \\
   -p \$HOME/dev/open_source/ebisu:.pub:.git
''');
  }

  // end <class ArgProcessor>
  List<Index> _indices;
  List<Filter> _filters;
}

main(List<String> args) async {
  Logger.root.onRecord.listen(
      (LogRecord r) => print("${r.loggerName} [${r.level}]:\t${r.message}"));
  Logger.root.level = Level.OFF;
  Map argResults = _parseArgs(args);
  Map options = argResults['options'];
  List positionals = argResults['rest'];

  // custom <xgrep main>

  final argProcessor = new ArgProcessor(args, options, positionals);
  await argProcessor.process();
  // end <xgrep main>

}

// custom <xgrep global>

positionalsCheck(List<String> positionals, String tag) {
  if (!positionals.isEmpty) {
    print('''
Will not $tag indices if additional positional args provided.
The following args remain $positionals.''');
    exit(-1);
  }
}

printIndex(Index index) {
  print('---------- ${nameItem(index)} ----------');
  final paths = index.paths;
  paths.keys.forEach((String path) {
    print('  $path');
    final pruneSpec = index.paths[path];
    pruneSpec.names.forEach((String pruneName) {
      print('    prune_name:$pruneName');
    });
    pruneSpec.paths.forEach((String prunePath) {
      print('    prune_path:$prunePath');
    });
  });
  index.pruneNames.forEach((String pruneName) {
    print('  index prune:$pruneName');
  });
}

printFilenameFilter(Filter filter) {
  print(filter.toJson());
  final type = filter.isInclusion ? '+' : '-';
  print('.......... $type${nameItem(filter)} ..........');
  display(String s) => Filter.interpret(s);
  filter.patterns.forEach((String s) {
    print('  pattern: ${display(s)}');
  });
}

printIndices(indexer) async {
  print('**** Current Indices ****');
  final indices = await indexer.indices;
  if (indices.isEmpty) {
    print('''
You have no indices created yet. Consider creating some.
For example:

xgrep -i my_dart \\
   -p \$HOME/dev/open_source/xgrep:.pub:.git \\
   -p \$HOME/dev/open_source/ebisu:.pub:.git
''');
  } else {
    indices.forEach(printIndex);
  }
}

printFilters(indexer) async {
  print('**** Current Filters ****');
  final filters = await indexer.filters;
  if (filters.isEmpty) {
    print(r"""
You have no filters. Consider creating some.
For example:

xgrep -f 'dart_filter + \.dart$ \.html$ \.yaml$'

""");
  } else {
    filters.forEach(printFilenameFilter);
  }
}

nameItem(item) => item.id.snake;
nameItems(items) => items.map((item) => nameItem(item));

// end <xgrep global>
