part of xgrep.xgrep;

class MlocateIndexUpdater implements IndexUpdater {
  const MlocateIndexUpdater(this.index);

  final Index index;
  // custom <class MlocateIndexUpdater>

  updateIndex() {
    createDbPath();
    final futures = [];
    dbPaths.forEach((String searchPath, String dbPath) {
      final command = 'updatedb';
      final args = ['-l', '0', '-U', searchPath, '-o', dbPath];
      print('Running: $command $args');
      futures.add(Process.run(command, args));
    });

    return Future.wait(futures).then((List<ProcessResult> results) {
      results.forEach((ProcessResult pr) {
        print(
            'Got result:\n====stdout======\n${pr.stdout}\n====stderr======\n${pr.stderr}');
      });
    });
  }

  DateTime lastUpdate();

  Map get dbPaths {
    final folderPath = path.join(dbPath, index.id.snake);
    final result = {};
    enumerate(index.paths).forEach((IndexedValue iv) => result[iv.value] =
        path.join(folderPath, '${iv.index}.${path.basename(iv.value)}'));
    return result;
  }

  String get indexDbDir => path.join(dbPath, index.id.snake);

  String get dbPath => path.join(Platform.environment['HOME'], 'xgrepdbs');

  createDbPath() => new Directory(indexDbDir)..createSync(recursive: true);

  // end <class MlocateIndexUpdater>
}
// custom <part mlocate_index_updater>
// end <part mlocate_index_updater>
