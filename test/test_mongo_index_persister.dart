library xgrep.test.test_mongo_index_persister;

import 'package:logging/logging.dart';
import 'package:unittest/unittest.dart';
// custom <additional imports>

import 'dart:async';
import 'dart:io';
import 'package:id/id.dart';
import 'package:path/path.dart';
import 'package:xgrep/xgrep.dart';

// end <additional imports>

final _logger = new Logger('test_mongo_index_persister');

// custom <library test_mongo_index_persister>
// end <library test_mongo_index_persister>
main() {
// custom <main>

  defaultCollectionPrefix = 'test';

  final thisDir = dirname(Platform.script.path);
  final libDir = join(dirname(thisDir), 'lib');
  final indexId = idFromString('test_index');
  final indexName = indexId.snake;
  final srcIndex = new Index(indexId, [thisDir, libDir]);

  group('MongoIndexPersister', () {
    test('cleanup/removeAllIndices works', () async {
      await MongoIndexPersister.withIndexPersister(
          (IndexPersister persister) async {
        List<Index> indices =
            await persister.removeAllIndices().then((_) => persister.indices);
        expect(indices.length, 0);
      });
    });

    test('persist works', () async {
      await MongoIndexPersister.withIndexPersister(
          (IndexPersister persister) async {
        await persister.persistIndex(srcIndex);
        List<Index> indices = await persister.indices;
        expect(indices.length, 1);
        expect(indices.first.paths.containsKey(thisDir), true);
        expect(indices.first.paths.containsKey(libDir), true);
        expect(indices.first.paths.containsKey('/tmp/x'), false);
      });
    });

    test('lookup works', () async {
      await MongoIndexPersister.withIndexPersister(
          (IndexPersister persister) async {
        final index = await persister.lookupIndex(indexId);
        expect(index.paths.containsKey(thisDir), true);
      });
    });

    test('add path works', () async {
      await MongoIndexPersister.withIndexPersister(
          (IndexPersister persister) async {
        final index = await persister.addPaths(indexId, ['/tmp/x', '/tmp/y']);
        expect(index.paths['/tmp/x'], emptyPruneSpec);
        expect(index.paths['/tmp/y'], emptyPruneSpec);
      });
    });

    test('remove path works', () async {
      await MongoIndexPersister.withIndexPersister(
          (IndexPersister persister) async {
        final index =
            await persister.removePaths(indexId, ['/tmp/x', '/tmp/y']);
        expect(index.paths['/tmp/x'], null);
        expect(index.paths['/tmp/y'], null);
      });
    });

    test('remove index works', () async {
      await MongoIndexPersister.withIndexPersister(
          (IndexPersister persister) async {
        final removedIndexId = await persister.removeIndex(srcIndex.id);
        expect(indexId, indexId);
        final index = await persister.lookupIndex(indexId);
        expect(index, null);
      });
    });
  });

// end <main>

}
