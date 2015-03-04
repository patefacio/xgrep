library xgrep.test.test_mongo_index_persister;

import 'package:unittest/unittest.dart';
// custom <additional imports>

import 'dart:async';
import 'dart:io';
import 'package:id/id.dart';
import 'package:path/path.dart';
import 'package:xgrep/xgrep.dart';

// end <additional imports>

// custom <library test_mongo_index_persister>
// end <library test_mongo_index_persister>
main() async {
// custom <main>

  defaultCollectionPrefix = 'test';

  final thisDir = dirname(Platform.script.path);

  int _i = 1;
  makeIndex() => new Index(idFromString('test_index_i$_i'),
      [ thisDir, join(dirname(thisDir), 'lib') ]);

  group('MongoIndexPersister', () {

    test('cleanup/removeAllIndices works', () async {
      await MongoIndexPersister.withIndexPersister(
          (IndexPersister persister) async {
            List<Index> indices = await persister
            .removeAllIndices()
            .then((_) => persister.indices);
            expect(indices.length, 0);
          });
    });

    test('persist works', () async {
      await MongoIndexPersister.withIndexPersister(
          (IndexPersister persister) async {
            await persister.persistIndex(makeIndex());
            List<Index> indices = await persister.indices;
            expect(indices.length, 1);
            print('foo');
          });
    });

    test('lookup works', () async {
      await MongoIndexPersister.withIndexPersister(
          (IndexPersister persister) async {
            final index = await persister
            .lookupIndex(idFromString('test_index_i1'));
            print('Found $index');
          });
    });

    test('add path works', () async {
      await MongoIndexPersister.withIndexPersister(
          (IndexPersister persister) async {
            final index = await persister
            .addPaths(idFromString('test_index_i1'), [ '/tmp/x', '/tmp/y' ]);
            print('Found $index');
            expect(index.paths['/tmp/x'], emptyPruneSpec);
            expect(index.paths['/tmp/y'], emptyPruneSpec);
          });
    });

    test('remove path works', () async {
      await MongoIndexPersister.withIndexPersister(
          (IndexPersister persister) async {
            final index = await persister
            .removePaths(idFromString('test_index_i1'), [ '/tmp/x', '/tmp/y' ]);
            print('Found $index');
            expect(index.paths['/tmp/x'], null);
            expect(index.paths['/tmp/y'], null);
          });
    });
  });

// end <main>

}
