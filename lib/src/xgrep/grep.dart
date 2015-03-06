part of xgrep.xgrep;

class GrepArgs {
  const GrepArgs(this.args);

  final List<String> args;
  // custom <class GrepArgs>
  // end <class GrepArgs>
}

/// Takes a stream of paths and passes them to *xargs grep*
///
class FindGrep {
  const FindGrep(this.indexId, this.found, this.grepArgs);

  /// [Id] of index producing the stream of filenames this class consumes
  final Id indexId;
  /// [Stream] of file paths produced by the query on index to which *grep*
  /// will be applied
  final Stream<String> found;
  final GrepArgs grepArgs;
  // custom <class FindGrep>

  Future grep() {
    print('Grepping $indexId');
  }

  // end <class FindGrep>
}
// custom <part grep>

grepWithIndexer(Id indexId, GrepArgs grepArgs, Indexer indexer) {
  final nullTerminator = new String.fromCharCode(0);
  return indexer.lookupIndex(indexId).then((Index index) {
    final command = _xargsGrepCommand(grepArgs);
    _logger.info(() => 'Grep running $command');
    return Process.start(command.first, command.sublist(1)).then(
        (Process process) {
      final completer = new Completer<String>();

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

      _logger.info(() => 'Grep completed with $matches matches');

      return completer.future;
    });
  });
}

grep(Id indexId, GrepArgs grepArgs) => Indexer.withIndexer(
    (Indexer indexer) => grepWithIndexer(indexId, grepArgs, indexer));

_xargsGrepCommand(GrepArgs grepArgs) =>
    ['xargs', '-0', 'grep', '-n', '-E', 'test'];

// end <part grep>
