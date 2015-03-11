library xgrep.test.test_filter;

import 'package:unittest/unittest.dart';
// custom <additional imports>
import 'package:xgrep/xgrep.dart';
import 'package:id/id.dart';
// end <additional imports>

// custom <library test_filter>
// end <library test_filter>
main() {
// custom <main>

  group('filter basics', () {
    test('json', () {
      var filter =
          new Filter(idFromString('f'), true, [r'\.dart$', r'\.html$']);
      expect(Filter.fromJson(filter.toJson()), filter);
    });

    test('parsing exclusion filter', () {
      var filter = new Filter.fromArg(r'no_dart - \.dart$ \.html$ \.js');
      expect(filter.isInclusion, false);
      expect(filter.id, idFromString('no_dart'));
    });

    test('parsing inclusion filter', () {
      var filter = new Filter.fromArg(r'some_dart + \.dart$ \.html$ \.js');
      expect(filter.isInclusion, true);
      expect(filter.id, idFromString('some_dart'));
      expect(filter.patterns.length, 3);
    });

    test('parsing bogus filters', () {
      try {
        var filter = new Filter.fromArg(r'some_dart + \.d(art$ \.html$ \.js');
        assert('expected throw');
      } on Exception catch (e) {
        expect(e is FormatException, true);
      }
      try {
        var filter = new Filter.fromArg(r'?some_dart + \.dart$');
        assert('expected throw');
      } on Exception catch (e) {
        expect(e.message.contains('arg is not valid'), true);
      }
    });
  });

// end <main>

}
