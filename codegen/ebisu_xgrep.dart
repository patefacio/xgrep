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
      library('test_mongo_index_persister'),
      library('test_mlocate_index_updater'),
    ]
    ..libraries = [
      library('xgrep')
      ..imports = [
        '"package:path/path.dart" as path',
        'package:id/id.dart',
        'package:quiver/iterables.dart',
        'package:mongo_dart/mongo_dart.dart',
        'io',
        'async',
      ]
      ..parts = [
        part('index')
        ..classes = [
          class_('index')
          ..jsonToString = true
          ..members = [
            member('id')..type = 'Id'..isFinal = true..access = RO..ctors = [''],
            member('paths')..type = 'List<String>'..isFinal = true..access = RO..ctors = [''],
            member('prune_names')
            ..type = 'List<String>'
            ..access = RO
            ..ctorsOpt = ['']
            ..ctorInit = '''
const [
  '.svn', '.gitignore', '.git', '.pub'
]'''
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
          ..implement = [ 'IndexUpdater' ]
          ..immutable = true
          ..members = [
            member('index')..type = 'Index'
          ]
        ],
        part('grep'),
      ],
    ];

  ebisu.generate();

}