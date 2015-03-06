#!/usr/bin/env dart
///
/// A script for indexing directories for the purpose of doing find/greps
/// on those indices.
///
/// If no arguments are provided, a list of existing indices will be
/// displayed.
///
/// If one or more indices is supplied without other arguments, a list of
/// files in the index (indices) will be output. Effectively a *find*
/// operation.
///
/// If a single index is supplied with any paths it will be considered an
/// index definition and first persist the index and then update it.
///
/// If one or more indices is supplied with the update option, the
/// databases for the index (indices) will be updated (e.g. *updatedb*
/// will be called to re-index)
///
/// If one or more indices is supplied with one additional argument, that
/// argument is the grep pattern and is grepped on all files in all
/// specified indices.
///
/// If one positional argument is provided without indices or any other
/// arguments a the prior search is replacing the grep pattern with the
/// positional argument.
///
///

import 'dart:async';
import 'dart:io';
import 'package:args/args.dart';
import 'package:id/id.dart';
import 'package:logging/logging.dart';
import 'package:xgrep/xgrep.dart';

//! The parser for this script
ArgParser _parser;

//! The comment and usage associated with this script
void _usage() {
  print('''

A script for indexing directories for the purpose of doing find/greps
on those indices.

If no arguments are provided, a list of existing indices will be
displayed.

If one or more indices is supplied without other arguments, a list of
files in the index (indices) will be output. Effectively a *find*
operation.

If a single index is supplied with any paths it will be considered an
index definition and first persist the index and then update it.

If one or more indices is supplied with the update option, the
databases for the index (indices) will be updated (e.g. *updatedb*
will be called to re-index)

If one or more indices is supplied with one additional argument, that
argument is the grep pattern and is grepped on all files in all
specified indices.

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
    _parser.addFlag('remove-index', help: '''
If set will remove any specified indices
''', abbr: 'r', defaultsTo: false);
    _parser.addFlag('remove-all', help: '''
Remove all stored indices
''', abbr: 'R', defaultsTo: false);
    _parser.addFlag('list', help: '''
For any indices provided, list all files. Effectively *find* on the index.
''', abbr: 'l', defaultsTo: false);
    _parser.addFlag('help', help: '''
Display this help screen
''', abbr: 'h', defaultsTo: false);

    _parser.addOption('index', help: '''
Id of index associated with command
''', defaultsTo: null, allowMultiple: true, abbr: 'i', allowed: null);
    _parser.addOption('path', help: '''
Colon separated fields specifying path with pruning. Fields are:
 1: The path to include
 2: One or more path names (i.e. unqualified folder names)
    to prune
 e.g. -p /home/gnome/ebisu:cache:.pub:.git

''', defaultsTo: null, allowMultiple: true, abbr: 'p', allowed: null);
    _parser.addOption('prune-name', help: '''
Global prune names excluded from all paths
''', defaultsTo: null, allowMultiple: true, abbr: 'P', allowed: null);
    _parser.addOption('prune-path', help: '''
Fully qualified path existing somewhere within a path to be excluded
''', defaultsTo: null, allowMultiple: true, abbr: 'X', allowed: null);

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
    result['remove-index'] = argResults['remove-index'];
    result['remove-all'] = argResults['remove-all'];
    result['list'] = argResults['list'];
    result['help'] = argResults['help'];

    return {'options': result, 'rest': argResults.rest};
  } catch (e) {
    _usage();
    throw e;
  }
}

final _logger = new Logger('xgrep');

main(List<String> args) {
  Logger.root.onRecord.listen(
      (LogRecord r) => print("${r.loggerName} [${r.level}]:\t${r.message}"));
  Logger.root.level = Level.INFO;
  Map argResults = _parseArgs(args);
  Map options = argResults['options'];
  List positionals = argResults['rest'];

  // custom <xgrep main>
  //Logger.root.level = Level.OFF;
  if (args.isEmpty) {
    print('**** Current Indices ****');
    Indexer.withIndexer((Indexer indexer) async {
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
        for (final index in indices) {
          print(index.id.snake);
          final paths = index.paths;
          paths.keys.forEach((String path) {
            print('  $path');
            final pruneSpec = index.paths[path];
            pruneSpec.names.forEach((String pruneName) {
              print('    prune:$pruneName');
            });
            pruneSpec.paths.forEach((String prunePath) {
              print('    prune:$prunePath');
            });
          });
          index.pruneNames.forEach((String pruneName) {
            print('  prune:$pruneName');
          });
        }
      }
    });
  } else {
    final indices = options['index'];
    final paths = options['path'];
    final prunePaths = options['prune-path'];
    final pruneNames = options['prune-name'];
    final removeIndex = options['remove-index'];
    final removeAll = options['remove-all'];
    print(options);

    _logger.info('${indices.length} indices ${indices}');
    _logger.info('${paths.length} paths ${paths}');
    _logger.info('${prunePaths.length} prunePaths ${prunePaths}');
    _logger.info('${pruneNames.length} pruneNames ${pruneNames}');

    if (!indices.isEmpty) {
      if (indices.length == 1 && !paths.isEmpty) {
        // Define the index
        final map = {};
        for (final path in paths) {
          final parts = path.split(':');
          assert(!parts.isEmpty);
          map[parts.first] = (parts.length == 1)
              ? emptyPruneSpec
              : new PruneSpec([parts.sublist(1)], []);
        }
        final index = new Index.withPruning(idFromString(indices.first), paths);
        print('Index to create is $index');
      } else {
        if (removeIndex) {
          if (!positionals.isEmpty) {
            print('''
Will not remove indices if additional positional args provided.
The following args remain $positionals.''');
            exit(-1);
          }
          print('Removing indices $indices');
          Indexer.withIndexer((Indexer indexer) {
            indices.forEach((String idStr) {
              final id = idFromString(idStr);
              indexer.removeIndex(id);
            });
          });
        } else {
          // Not removing specified indices. Either it is a request to update
          // indices or do a grep. If there is one positional arg that is the
          // grep arg, otherwise, it is an update
          if (positionals.length > 1) {
            print('''
You have multiple remaining arguments. If you are trying to grep one or more
indices for more than one text pattern, use an egrep style pattern''');
            exit(-1);
          } else if (positionals.length == 1) {
            print('Doing grep of ${positionals.first} on $indices');
          } else {
            print('Doing an update on $indices');
            Indexer.withIndexer((Indexer indexer) {
              final futures = [];
              indices.forEach((String idStr) {
                final id = idFromString(idStr);
                futures.add(indexer
                    .lookupIndex(id)
                    .then((Index index) {
                      if(index == null) {
                        print('Could not find index <$id> - will not update!');
                      } else {
                        return indexer.updateIndex(index);
                      }
                    }));
              });
              return Future.wait(futures);
            });
          }
        }
      }
    } else {
      if (removeAll) {
        print('Are you sure you want to remove all indices: [N/Y]?');
        final ans = stdin.readLineSync();
        const doIt = const ['Y', 'y', 'yes', 'Yes'];
        if (doIt.contains(ans)) {
          print('Deleting all indices');
          Indexer
              .withIndexer((Indexer indexer) => indexer.removeAllIndices())
              .then((_) => print('Completed'));
        } else {
          print('Nothing removed: Dodged a bullet there');
        }
      }
    }

    if (options['list']) {
      print('List them!');
    }

    print('Positionals => $positionals');
  }

  // end <xgrep main>

}

// custom <xgrep global>
// end <xgrep global>
