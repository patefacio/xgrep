library xgrep.test.test_index;

import 'package:unittest/unittest.dart';
// custom <additional imports>
import 'package:xgrep/xgrep.dart';
import 'package:id/id.dart';
// end <additional imports>

// custom <library test_index>
// end <library test_index>
main() {
// custom <main>

  group('index', () {
    test('default ctor', () {
      final index = new Index(idFromString('foo_bar'), ['/x/a', '/x/b']);
      expect(index.paths, { '/x/a' : emptyPruneSpec, '/x/b' : emptyPruneSpec });
      expect(index.pruneNames, commonPruneNames);
    });
    test('default ctor with prune names', () {
      final pruneNames = ['.git', '.svn'];
      final index = new Index(idFromString('foo_bar'), ['/x/a', '/x/b'], pruneNames);
      expect(index.paths, { '/x/a' : emptyPruneSpec, '/x/b' : emptyPruneSpec });
      expect(index.pruneNames, pruneNames);
    });

    test('ctor with prunning', () {
      final pruneNames = ['.git', '.svn'];
      final aPruneSpec = new PruneSpec([], ['/x/a/ignore_1', '/x/a/ignore_2']);
      final bPruneSpec = new PruneSpec(commonPruneNames, ['/x/b/ignore_1']);
      final index = new Index.withPruning(idFromString('foo_bar'),
          {
            '/x/a' : aPruneSpec,
            '/x/b' : bPruneSpec,
          },
          []);
      //expect(index.paths['/x/a'], aPruneSpec);
    });
  });

// end <main>

}
