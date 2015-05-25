library xgrep.test_index;

import 'package:args/args.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

// custom <additional imports>
import 'dart:async';
import 'dart:io';
import 'package:id/id.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart';
import 'package:xgrep/xgrep.dart';
// end <additional imports>

final _logger = new Logger('test_index');

// custom <library test_index>
// end <library test_index>

main([List<String> args]) {
  Logger.root.onRecord.listen(
      (LogRecord r) => print("${r.loggerName} [${r.level}]:\t${r.message}"));
  Logger.root.level = Level.OFF;
// custom <main>

  if (false) {
    Logger.root.onRecord.listen(
        (LogRecord r) => print("${r.loggerName} [${r.level}]:\t${r.message}"));
    Logger.root.level = Level.INFO;
  }

  defaultCollectionPrefix = 'test';

  group('index', () {
    test('default ctor', () {
      final index = new Index(idFromString('foo_bar'), ['/x/a', '/x/b']);
      expect(index.paths, {'/x/a': emptyPruneSpec, '/x/b': emptyPruneSpec});
      expect(index.pruneNames, commonPruneNames);
    });
    test('default ctor with prune names', () {
      final pruneNames = ['.git', '.svn'];
      final index =
          new Index(idFromString('foo_bar'), ['/x/a', '/x/b'], pruneNames);
      expect(index.paths, {'/x/a': emptyPruneSpec, '/x/b': emptyPruneSpec});
      expect(index.pruneNames, pruneNames);
    });

    test('ctor with prunning', () {
      final pruneNames = ['.git', '.svn'];
      final aPruneSpec = new PruneSpec([], ['/x/a/ignore_1', '/x/a/ignore_2']);
      final bPruneSpec = new PruneSpec(commonPruneNames, ['/x/b/ignore_1']);
      final index = new Index.withPruning(idFromString('foo_bar'), {
        '/x/a': aPruneSpec,
        '/x/b': bPruneSpec,
      }, ['voldermort']);
      expect(index.paths['/x/a'], aPruneSpec);
      expect(index.paths['/x/b'], bPruneSpec);
      expect(index.pruneNames, ['voldermort']);
    });

    test('basic indexer', () async {
      final thisDir = dirname(Platform.script.toFilePath());
      final index = new Index(idFromString('test_indexer'), [thisDir]);

      await Indexer.withIndexer((Indexer indexer) async {
        expect(indexer.indexPersister is MongoIndexPersister, true);
        await indexer.removeAllIndices();
        var indices = await indexer.indices;
        expect(indices.length, 0);
        await indexer.saveAndUpdateIndex(index);
        indices = await indexer.indices;
        expect(indices.length, 1);
        final readIndex = await indexer.lookupIndex(index.id);
        expect(readIndex, index);
        await indexer.removeAllIndices();
        indices = await indexer.indices;
        expect(indices.length, 0);
      });
    });
  });

// end <main>

}
