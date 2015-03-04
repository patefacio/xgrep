library xgrep.test.test_mlocate_index_updater;

import 'package:unittest/unittest.dart';
// custom <additional imports>

import 'package:xgrep/xgrep.dart';
import 'package:id/id.dart';
import 'package:path/path.dart';
import 'package:logging/logging.dart';
import 'dart:io';

// end <additional imports>

// custom <library test_mlocate_index_updater>
// end <library test_mlocate_index_updater>
main() {
// custom <main>

  Logger.root.onRecord.listen(
      (LogRecord r) => print("${r.loggerName} [${r.level}]:\t${r.message}"));
  Logger.root.level = Level.INFO;

  final varDir = '/var';
  final bin = '/bin';
  final home = Platform.environment['HOME'];
  final thisDir = dirname(Platform.script.path);
  final thisDirDotted = split(thisDir).sublist(1).join('.');
  final indexId = idFromString('test_index');
  final index = new Index(indexId, [varDir, bin, thisDir]);
  final updater = new MlocateIndexUpdater();
  final indexDbDir = updater.indexDbDir(indexId);

  if (new Directory(indexDbDir).existsSync()) {
    throw new Exception('For this test to run, clean up $indexDbDir');
  }

  print(home);
  group('basics', () {
    test('index path matches', () {
      expect(indexDbDir, join(MlocateIndexUpdater.dbPath, indexId.snake));
    });

    test('commands make sense', () {
      final commands = updater.mlocateCommands(index);
      final indexName = indexId.snake;
      expect(commands, [
        [
          'updatedb',
          '-l',
          '0',
          '-U',
          '/var',
          '-o',
          '$home/xgrepdbs/$indexName/var'
        ],
        [
          'updatedb',
          '-l',
          '0',
          '-U',
          '/bin',
          '-o',
          '$home/xgrepdbs/$indexName/bin'
        ],
        [
          'updatedb',
          '-l',
          '0',
          '-U',
          '$thisDir',
          '-o',
          '$home/xgrepdbs/$indexName/$thisDirDotted'
        ]
      ]);
    });

    test('update creates files', () async {
      expect(new Directory(indexDbDir).existsSync(), false);
      await updater.updateIndex(index);
      expect(new Directory(indexDbDir).existsSync(), true);
    });

    test('remove index works', () async {
      expect(new Directory(indexDbDir).existsSync(), true);
      await updater.removeIndex(indexId);
      expect(new Directory(indexDbDir).existsSync(), false);
    });
  });

// end <main>

}
