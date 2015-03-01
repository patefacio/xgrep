import 'package:unittest/unittest.dart';
import 'package:logging/logging.dart';
import 'test_index.dart' as test_index;
import 'test_mongo_index_persister.dart' as test_mongo_index_persister;
import 'test_mlocate_index_updater.dart' as test_mlocate_index_updater;

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
  test_mongo_index_persister.main();
  test_mlocate_index_updater.main();
}
