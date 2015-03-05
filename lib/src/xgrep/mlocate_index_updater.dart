part of xgrep.xgrep;

class MlocateIndexUpdater extends IndexUpdater {
  // custom <class MlocateIndexUpdater>

  Future updateIndex(Index index) {
    _logger.info('Updating index ${index.id}');
    _createDbPath(index.id);
    final futures = [];
    for (var command in updatedbCommands(index)) {
      futures.add(_runCommand(command));
    }
    return Future.wait(futures);
  }

  String indexDbDir(Id indexId) => path.join(dbPath, indexId.snake);

  static String get dbPath =>
      path.join(Platform.environment['HOME'], 'xgrepdbs');

  updatedbCommands(Index index) {
    final folderPath = path.join(dbPath, index.id.snake);
    final result = [];
    index.paths.forEach((String key, PruneSpec pruneSpec) {
      final mlocateDbPath =
          path.join(folderPath, path.split(key).sublist(1).join('.'));
      result.add(_updatedbCommand(key, mlocateDbPath, pruneSpec));
    });
    return result;
  }

  mlocateCommand(Index index) {
    final folderPath = path.join(dbPath, index.id.snake);
    final result = ['mlocate'];
    index.paths.keys.forEach((String key) {
      final mlocateDbPath =
          path.join(folderPath, path.split(key).sublist(1).join('.'));
      result..addAll(['-d', mlocateDbPath]);
    });
    result.add('.');
    return result;
  }

  Future<Stream<String>> findPaths(Index index,
      [FindArgs findArgs = emptyFindArgs]) async {
    final command = mlocateCommand(index);
    _logger.info('Running $command');
    final process = await Process.start(command.first, command.sublist(1));
    final result = process.stdout
        .transform(new Utf8Decoder())
        .transform(new LineSplitter());

    return result;
  }

  List<String> _pruneArgs(PruneSpec pruneSpec) {
    final result = [];
    if (!pruneSpec.names.isEmpty) {
      result
        ..add('-n')
        ..add(pruneSpec.names.join(' '));
    }
    if (!pruneSpec.paths.isEmpty) {
      result
        ..add('-n')
        ..add(pruneSpec.paths.join(' '));
    }
    return result;
  }

  List<String> _updatedbCommand(
      String searchPath, String dbPath, PruneSpec pruneSpec) => [
    'updatedb',
    '-l',
    '0',
    '-U',
    searchPath,
    '-o',
    dbPath
  ]..addAll(_pruneArgs(pruneSpec));

  _runCommand(List<String> command) {
    _logger.info('Running $command');
    final args = command.sublist(1);
    final path = command.skipWhile((p) => p != '-U').skip(1).first;
    return Process.run(command.first, args).then((ProcessResult result) {
      if (result.stdout.length > 0) _logger
          .info('mlocate <$path> stdout: ${result.stdout}');
      if (result.stderr.length > 0) _logger
          .info('mlocate <$path> stderr: ${result.stderr}');
    });
  }

  removeIndex(Id indexId) {
    _logger.info('Removing directory ${indexDbDir(indexId)}');
    return new Directory(indexDbDir(indexId)).delete(recursive: true);
  }

  _createDbPath(Id indexId) {
    _logger.info('Creating directory ${indexDbDir(indexId)}');
    return new Directory(indexDbDir(indexId))..createSync(recursive: true);
  }

  // end <class MlocateIndexUpdater>
}
// custom <part mlocate_index_updater>
// end <part mlocate_index_updater>
