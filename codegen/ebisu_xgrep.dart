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
      library('test_index'),
      library('test_mongo_index_persister')
      ..includeLogger = true,
      library('test_mlocate_index_updater')
      ..includeLogger = true,
      library('test_grep'),
    ]
    ..libraries = [
      library('xgrep')
      ..includeLogger = true
      ..imports = [
        '"package:path/path.dart" as path',
        "'package:ebisu/ebisu_utils.dart' as ebisu_utils",
        'package:id/id.dart',
        'package:quiver/iterables.dart',
        'package:mongo_dart/mongo_dart.dart',
        'io',
        'async',
        'convert',
      ]
      ..parts = [
        part('index')
        ..classes = [
          class_('prune_spec')
          ..immutable = true
          ..opEquals = true
          ..jsonSupport = true
          ..members = [
            member('names')..type = 'List<String>'..classInit = [],
            member('paths')..type = 'List<String>'..classInit = [],
          ],
          class_('find_args')
          ..immutable = true
          ..members = [
            member('includes')..type = 'List<RegExp>'..classInit = [],
            member('excludes')..type = 'List<RegExp>'..classInit = [],
          ],
          class_('index')
          ..members = [
            member('id')..type = 'Id'..access = RO,
            member('paths')
            ..doc = 'Paths to include in the index with corresponding prunes specific to the path'
            ..type = 'Map<String, PruneSpec>'..access = RO,
            member('prune_names')
            ..doc = 'Global set of names to prune on all paths'
            ..type = 'List<String>'
            ..access = RO
          ],
          class_('index_stats')
          ..immutable = true
          ..members = [
            member('index')..type = 'Index',
            member('last_update')..type = 'DateTime',
          ],
          class_('index_persister')
          ..isAbstract = true
          ..members = [
            member('connect_future')..type = 'Future'..access = IA
          ],
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
          ..extend =  'IndexPersister'
          ..members = [
            member('uri')..isFinal = true..access = RO,
            member('db')..access = IA..type = 'Db',
            member('indices')..access = IA..type = 'DbCollection',
          ]
        ],
        part('mlocate_index_updater')
        ..classes = [
          class_('mlocate_index_updater')
          ..extend = 'IndexUpdater'
        ],
        part('grep')
        ..classes = [
          class_('grep_args')
          ..immutable = true
          ..members = [
            member('args')..type = 'List<String>'..classInit = []
          ],
          class_('find_grep')
          ..immutable = true
          ..members = [
            member('indexer')..type = 'Indexer',
            member('index_id')..type = 'Id',
            member('grep_args')..type = 'GrepArgs',
          ]
        ],
      ],
    ];

  ebisu.generate();

}