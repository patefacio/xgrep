library xgrep.test.test_xgrep_script;

import 'package:unittest/unittest.dart';
// custom <additional imports>

import 'package:xgrep/xgrep.dart';
import 'package:path/path.dart';
import 'dart:io';

// end <additional imports>

// custom <library test_xgrep_script>

final testFolder = dirname(Platform.script.path);
final rootFolder = dirname(testFolder);
final binFolder = join(dirname(testFolder), 'bin');
final xgrep = join(binFolder, 'xgrep.dart');
final env = new Map.from(Platform.environment)..['XGREP_COL_PREFIX'] = 'test';

runScriptWithArgs(List<String> args) async => await Process
    .run(xgrep, args, environment: env)
    .then((ProcessResult result) => result.stdout);

runScriptWithArgsInteractive(List<String> args, [interaction(Process)]) async =>
    await Process.start(xgrep, args, environment: env).then((Process process) {
  if (interaction != null) interaction(process);
  return process.exitCode.then((int exitCode) => expect(exitCode, 0));
});

addTest(testName, scriptArgs, required) => test(testName,
    () async => await runScriptWithArgs(scriptArgs).then((String output) {
  if (false) {
    print('--------COMPLETED $testName------');
    print(output);
  }
  required.forEach((var s) {
    final match = output.contains(s);
    if (!match) print('Bogus ====\n$output\n====\nhas no $s');
    expect(match, true);
  });
}));

// end <library test_xgrep_script>
main() {
// custom <main>

  defaultCollectionPrefix = 'test';

  group('test_xgrep_script', () {
    test('remove_all', () async {
      await runScriptWithArgsInteractive(
          ['-R'], (process) => process.stdin.writeln('Y')).then((var _) async {
        await Indexer.withIndexer((Indexer indexer) async {
          final indices = await indexer.indices;
          expect(indices.length, 0);
        });
      });
    });

    test('index test folder', () async {
      await runScriptWithArgs(['-i', 'test_index', '-p', '$testFolder']).then(
          (String output) async {
        await Indexer.withIndexer((Indexer indexer) async {
          final indices = await indexer.indices;
          expect(indices.length, 1);
        });
      });
    });

    addTest('-i with -p creates index', [
      '-i',
      'test_index',
      '-p',
      '$testFolder'
    ], ['Creating/updating test_index']);

    addTest('without args displays index', [], ['--------- test_index']);

    addTest('without -h does help', ['-h'], ['-l, --[no-]list']);

    addTest('named -i does update', [
      '-i',
      'test_index'
    ], ['Doing an update on [test_index]']);

    addTest('named -i with -l lists files', [
      '-i',
      'test_index',
      '-l'
    ], ['test_xgrep_script.dart']);

    addTest('named -i bad name', ['-i', 'doesnotexist'], [
      'Could find no matching indexes on [doesnotexist]'
    ]);

    addTest('named -i with pattern works', [
      '-i',
      't.*',
      '-l'
    ], ['test_xgrep_script.dart']);

    addTest('named -i with -r removes', ['-i', 't.*', '-r'], [
      'Removing index test_index'
    ]);

    addTest('creation honors prune', [
      '-i',
      'test_index',
      '-p',
      '$rootFolder:prune_test'
    ], ['Creating/updating test_index', 'prune:prune_test',]);

    addTest('grep works', ['-i', 'test_index', 'funky_monkey', 'spinal_tap'], [
      new RegExp(r'test_xgrep_script.dart:\d+.*funky_monkey'),
      new RegExp(r'test_xgrep_script.dart:\d+.*spinal_tap'),
    ]);

    addTest('create a second index', [
      '-i',
      'test_index2',
      '-p',
      binFolder
    ], ['Creating/updating test_index2']);

    addTest('grep looks in multiple indices', [
      '-i',
      'test_index',
      '-i',
      'test_index2',
      'funky_monkey',
      'Are you sure'
    ], [
      // From test_index
      new RegExp(r'test_xgrep_script.dart:\d+.*funky_monkey'),
      // From test_index2
      new RegExp(r'xgrep.dart:\d+.*print\(.Are you sure'),
    ]);

    addTest('removal by pattern hits multiple indices', [
      '-i',
      'test_index.*',
      '-r'
    ], ['Removing index test_index', 'Removing index test_index2']);
  });

// end <main>

}
