library xgrep.test.test_mlocate_index_updater;

import 'package:unittest/unittest.dart';
// custom <additional imports>

import 'package:xgrep/xgrep.dart';
import 'package:id/id.dart';
import 'package:path/path.dart' as path;
import 'dart:io';

// end <additional imports>

// custom <library test_mlocate_index_updater>
// end <library test_mlocate_index_updater>
main() {
// custom <main>

  final home = Platform.environment['HOME'];
  print(home);
  group('basics', () {
    final varDir = '/var';
    final usr = '/usr';
    final index = new Index(idFromString('my_search'), [varDir, usr]);
    final updator = new MlocateIndexUpdater(index);
    test('creates dbPath if DNE', () {
      updator.createDbPath();
      expect(new Directory(updator.indexDbDir).existsSync(), true);
    });

    test('index path matches', () {
      expect(updator.indexDbDir, path.join(updator.dbPath, index.id.snake));
    });

    test('dbPaths work', () {
      final dbPaths = updator.dbPaths;
      print(dbPaths);
      expect(path.basename(dbPaths[varDir]), '0.var');
      expect(path.basename(path.dirname(dbPaths[varDir])), index.id.snake);
      expect(path.basename(dbPaths[usr]), '1.usr');
      expect(path.basename(path.dirname(dbPaths[usr])), index.id.snake);
    });

    test('update creates files', () {
      updator.updateIndex();
    });
  });

// end <main>

}
