library xgrep.test.test_mongo_index_persister;

import 'package:unittest/unittest.dart';
// custom <additional imports>

import 'package:xgrep/xgrep.dart';
import 'package:id/id.dart';
import 'dart:async';

// end <additional imports>

// custom <library test_mongo_index_persister>
// end <library test_mongo_index_persister>
main() {
// custom <main>

  group('mongo persister', () {
    final persister = new MongoIndexPersister();
    final id = idFromString('test_index');
    final index = new Index(id, ['/tmp/a', '/tmp/b']);

    Future.wait([
      persister.connect().then((var o) {
        print('Got ${o.runtimeType}');

        test('indices', () {
          persister.indices
              .then((List<Index> l) => print(l.map((i) => i.toJson())));
        });

        test('lookupIndex', () {
          persister.lookupIndex(id).then((Index i) => print(i));
        });

        test('persistIndex', () {
          persister.persistIndex(index).then((_) => print(_));
        });

        test('addPaths', () {
          persister.addPaths(id, ['/tmp/c']).then((_) => print(_));
        });
      })
    ]).then((_) => print('done'));

    // test('addPaths', () {
    //   persister.removePaths(id, ['/tmp/c']).then((_) => print(_));

    //   persister.connect().then((IndexPersister ip) => ip.goo());
    // });

  });

// end <main>

}
