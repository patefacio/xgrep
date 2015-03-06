#!/usr/bin/env dart
///
/// A script for indexing directories for the purpose of doing find/greps
/// on those indices.
///
/// If an index is supplied without other arguments, a list of existing
/// indices will be displayed.
///
/// If index is supplied with any paths it will
/// update the index - as in persist it as well as update it.
///
/// If an index is supplied with update option , the databases for the
/// index will be updated.
///
/// If an index is supplied with grep args, a grep on the index will be
/// performed.

import 'dart:io';
import 'package:args/args.dart';
import 'package:logging/logging.dart';

//! The parser for this script
ArgParser _parser;

//! The comment and usage associated with this script
void _usage() {
  print('''

A script for indexing directories for the purpose of doing find/greps
on those indices.

If an index is supplied without other arguments, a list of existing
indices will be displayed.

If index is supplied with any paths it will
update the index - as in persist it as well as update it.

If an index is supplied with update option , the databases for the
index will be updated.

If an index is supplied with grep args, a grep on the index will be
performed.
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
    _parser.addFlag('help', help: '''
Display this help screen
''', abbr: 'h', defaultsTo: false);

    _parser.addOption('index', help: '''
Id of index associated with command
''', defaultsTo: null, allowMultiple: false, abbr: 'i', allowed: null);
    _parser.addOption('path', help: '''
Colon separated fields specifying path with pruning. Fields are:
 1: The path to include
 2: One or more path names (i.e. unqualified folder names)
    to prune
 e.g. -p /home/gnome/ebisu:cache:.pub:.git

''', defaultsTo: null, allowMultiple: true, abbr: 'p', allowed: null);
    _parser.addOption('prune-names', help: '''
Global prune names excluded from all paths
''', defaultsTo: null, allowMultiple: true, abbr: 'P', allowed: null);
    _parser.addOption('prune-paths', help: '''
Fully qualified path existing somewhere within a path to be excluded
''', defaultsTo: null, allowMultiple: true, abbr: 'X', allowed: null);
    _parser.addOption('remove-index', help: '''
Id of index to remove
''', defaultsTo: null, allowMultiple: true, abbr: 'r', allowed: null);

    /// Parse the command line options (excluding the script)
    argResults = _parser.parse(args);
    if (argResults.wasParsed('help')) {
      _usage();
      exit(0);
    }
    result['index'] = argResults['index'];
    result['path'] = argResults['path'];
    result['prune-names'] = argResults['prune-names'];
    result['prune-paths'] = argResults['prune-paths'];
    result['remove-index'] = argResults['remove-index'];
    result['help'] = argResults['help'];

    return {'options': result, 'rest': remaining};
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
  // end <xgrep main>

}

// custom <xgrep global>
// end <xgrep global>
