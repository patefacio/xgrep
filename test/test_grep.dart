library xgrep.test.test_grep;

import 'package:unittest/unittest.dart';
// custom <additional imports>

import 'dart:io';
import 'package:id/id.dart';
import 'package:path/path.dart';
import 'package:xgrep/xgrep.dart';

// end <additional imports>

// custom <library test_grep>
// end <library test_grep>
main() {
// custom <main>

  group('grep', () {
    test('grep', () {
      final indexId = idFromString('test_index');
      final thisDir = dirname(Platform.script.path);
      final srcIndex = new Index(indexId, [thisDir]);
      final grepArgs = new GrepArgs(['foo']);
      grep(grepArgs, indexId);
    });
  });

// end <main>

}
