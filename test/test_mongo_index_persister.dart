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

  try {
    MongoIndexPersister.withIndexPersister((IndexPersister persister) async {
      List<Index> indices = await persister
      .removeAllIndices()
      .then((_) => persister.indices);
      //throw 'Foobar';
      print('Got indices (1) $indices');

      test('true is true', () => expect(true, true));
      //      test('indices empty (1)', () => expect(indices.isEmpty, true));
      //      test('indices empty (2)', () => expect(indices.isEmpty, true));

      if(true) {
        await persister.persistIndex(makeIndex());
        List<Index> indicesAgain = await persister.indices;
        print('Indices again $indicesAgain');
        // assert(indicesAgain is List);
        // assert(indicesAgain.first is Index);
      }

      if(true) {
        print('is true true?');
        test('true is still true', () => expect(true, true));
      }

      print('Got indices (2) $indices');
    })
      .catchError((e) => print('Caugnt $e'));
  } on Exception catch(e) {
    print('YCaught $e');
  }

    // group('mongo persister', () {
    //   test('indices', () {
    //     persister.indices
    //       .then((List<Index> l) => print(l.map((i) => i.toJson())));
    //   });
    // });

    // Future.wait([
    //   persister.connect().then((var o) {
    //     print('Got ${o.runtimeType}');

    //     test('indices', () {
    //       persister.indices
    //           .then((List<Index> l) => print(l.map((i) => i.toJson())));
    //     });

    //     test('lookupIndex', () {
    //       persister.lookupIndex(id).then((Index i) => print(i));
    //     });

    //     test('persistIndex', () {
    //       persister.persistIndex(index).then((_) => print(_));
    //     });

    //     test('addPaths', () {
    //       persister.addPaths(id, ['/tmp/c']).then((_) => print(_));
    //     });
    //   })
    // ]).then((_) => print('done'));

    // test('addPaths', () {
    //   persister.removePaths(id, ['/tmp/c']).then((_) => print(_));

    //   persister.connect().then((IndexPersister ip) => ip.goo());
    // });

// end <main>

}
