part of xgrep.xgrep;

// custom <part grep>

final _nullTerminator = new String.fromCharCode(0);

grepWithIndexer(List<Index> indices, List<String> grepArgs, Indexer indexer,
    [List filters = const []]) {
  final command = _xargsGrepCommand(grepArgs);
  int filesConsidered = 0;
  int filesFiltered = 0;
  int linesMatched = 0;
  _logger.info(() => 'Grep running $command');

  return Process
      .start(command.first, command.sublist(1))
      .then((Process process) {
    stderr.addStream(process.stderr);

    process.stdout
        .transform(new Utf8Decoder())
        .transform(new LineSplitter())
        .listen((String line) {
      linesMatched++;
      print(line);
    });

    final futures = [];
    indices.forEach((Index index) {
      final completer = new Completer<Id>();

      futures.add(indexer.findPaths(index).then((Stream stream) => stream
          .where((String path) {
        if (FileSystemEntity.isDirectorySync(path)) return false;
        filesConsidered++;
        final skipped = filters.any((filter) => filter.excludePath(path));
        if (skipped) filesFiltered++;
        return !skipped;
      }).map((path) => path + _nullTerminator).listen(
          (String s) => process.stdin.write(s), onDone: () {
        _logger.fine('Finished find on ${index.id}');
        completer.complete(index.id);
      })));

      futures.add(completer.future);
    });

    return Future.wait(futures).then((var _) {
      _logger.info('Finished all locates, closing down grep');
      process.stdin.close();
    }).then((_) => process.exitCode);
  }).then((int exitCode) {
    _logger.info(() => 'Grep completed ($exitCode): '
        '$filesConsidered files considered, $filesFiltered filtered, '
        '$linesMatched linesMatched');
    return exitCode;
  });
}

_xargsGrepCommand(List<String> grepArgs) =>
    ['xargs', '-0', 'grep', '-s', '-n', '-E',]..addAll(grepArgs);

// end <part grep>
