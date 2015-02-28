import "dart:io";
import "package:path/path.dart" as path;
import "package:id/id.dart";
import "package:ebisu/ebisu.dart";
import "package:ebisu/ebisu_dart_meta.dart";
import "package:logging/logging.dart";

void main() {
  Logger.root.onRecord.listen((LogRecord r) =>
      print("${r.loggerName} [${r.level}]:\t${r.message}"));

  String here = path.absolute(Platform.script.path);
  final topDir = path.dirname(path.dirname(here));
  useDartFormatter = true;
  System ebisu = system('xgrep')
    ..includeHop = true
    ..license = 'boost'
    ..rootPath = topDir
    ..doc = 'Package providing support for advanced find/grep'
    ..testLibraries = [
      library('test_mongo_index_persister'),
      library('test_mlocate_index_updater'),
    ]
    ..libraries = [
      library('xgrep')
      ..imports = [
        'package:thrift/transport.dart'
      ]
      ..parts = [
        part('index')
        ..classes = [
          class_('index')
          ..immutable = true
          ..members = [
            member('name')..type = 'Id',
            member('paths')..type = 'List<String>',
            member('target_index'),
          ],
          class_('index_stats')
          ..immutable = true
          ..members = [
            member('index')..type = 'Index',
            member('last_update')..type = 'DateTime',
          ],
          class_('index_persister')
          ..isAbstract = true,
          class_('index_updater')
          ..isAbstract = true,
          class_('indexer')
          ..immutable = true
          ..members = [
            member('index_persister')..type = 'IndexPersister',
            member('index_updater')..type = 'IndexUpdater'
          ],
        ],
        part('mongo_index_persister')
        ..classes = [
          class_('mongo_index_persister')
          ..implement = [ 'IndexPersister' ]
        ],
        part('mlocate_index_updater')
        ..classes = [
          class_('mlocate_index_updater')
          ..implement = [ 'IndexerUpdater' ]
        ],
        part('grep'),
      ],
    ];

  ebisu.generate();

}