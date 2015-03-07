library xgrep.test.test_grep;

import 'package:unittest/unittest.dart';
// custom <additional imports>

import 'dart:io';
import 'package:id/id.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart';
import 'package:xgrep/xgrep.dart';

// end <additional imports>

// custom <library test_grep>
// end <library test_grep>
main() {
// custom <main>

  if (false) {
    Logger.root.onRecord.listen(
        (LogRecord r) => print("${r.loggerName} [${r.level}]:\t${r.message}"));
    Logger.root.level = Level.INFO;
  }

  group('grep', () {
    test('grep', () async {
      final indexId = idFromString('test_index');
      final thisDir = dirname(Platform.script.path);
      final srcIndex = new Index(indexId, [thisDir]);

      await Indexer.withIndexer(
          (Indexer indexer) => indexer.saveAndUpdateIndex(srcIndex));

      await grep(srcIndex.id, ['-e', 'updateIndex']);

      await Indexer
          .withIndexer((Indexer indexer) => indexer.removeAllIndices());
    });
  });

// end <main>

}
