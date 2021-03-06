import 'package:test/test.dart';
import 'package:logging/logging.dart';
import 'test_index.dart' as test_index;
import 'test_filter.dart' as test_filter;
import 'test_mongo_index_persister.dart' as test_mongo_index_persister;
import 'test_mlocate_index_updater.dart' as test_mlocate_index_updater;
import 'test_xgrep_script.dart' as test_xgrep_script;

void testCore(Configuration config) {
  unittestConfiguration = config;
  main();
}

main() {
  Logger.root.level = Level.OFF;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}: ${rec.time}: ${rec.message}');
  });

  test_index.main();
  test_filter.main();
  test_mongo_index_persister.main();
  test_mlocate_index_updater.main();
  test_xgrep_script.main();
}
