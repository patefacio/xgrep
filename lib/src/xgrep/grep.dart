part of xgrep.xgrep;

// custom <part grep>

grepWithIndexer(Id indexId, List<String> grepArgs, Indexer indexer) {
  final nullTerminator = new String.fromCharCode(0);
  return indexer.lookupIndex(indexId).then((Index index) {
    if (index == null) {
      _logger.warning('Skipping grep on *${indexId.snake}* - index not found');
      return;
    }

    final command = _xargsGrepCommand(grepArgs);
    _logger.info(() => 'Grep running $command');
    return Process.start(command.first, command.sublist(1)).then(
        (Process process) {
      final completer = new Completer<String>();

      stderr.addStream(process.stderr);

      int matches = 0;
      process.stdout
          .transform(new Utf8Decoder())
          .transform(new LineSplitter())
          .listen((line) {
        matches++;
        print(line);
      });

      indexer.findPaths(index).then((Stream stream) {
        return stream.map((path) => path + nullTerminator).listen((String s) {
          return process.stdin.write(s);
        }, onDone: () {
          process.stdin.close();
          completer.complete();
        });
      });

      return completer.future.then((var _) {
        _logger.info(() => 'Grep completed with $matches matches');
        return _;
      });
    });
  });
}

grep(Id indexId, List<String> grepArgs) => Indexer.withIndexer(
    (Indexer indexer) => grepWithIndexer(indexId, grepArgs, indexer));

_xargsGrepCommand(List<String> grepArgs) =>
    ['xargs', '-0', 'grep', '-s', '-n', '-E',]..addAll(grepArgs);

// end <part grep>
