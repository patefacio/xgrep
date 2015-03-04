part of xgrep.xgrep;

class GrepArgs {
  const GrepArgs(this.args);

  final List<String> args;
  // custom <class GrepArgs>
  // end <class GrepArgs>
}

class FindGrep {
  const FindGrep(this.id, this.grepArgs);

  final Id id;
  final GrepArgs grepArgs;
  // custom <class FindGrep>

  Future grep() {
    return new MongoIndexPersister()
        .lookupIndex(id)
        .then((List<Index> indices) {
      final index = indices.first;
      final updater = new MlocateIndexUpdater(index);
      print('Got index $index\nneed to look in ${updater.indexDbDir}');
      final dbDir = new Directory(updater.indexDbDir);
      var future = dbDir.existsSync()
          ? _grep(updater)
          : updater.updateIndex(index).then((_) => _grep(updater));
      return future;
    });
  }

  Future _grep(IndexUpdater updater) {
    final command = 'mlocate';
    final dbPaths = updater.dbPaths.values.toList();
    final args = dbPaths.map((p) => '-d $p').toList();
    print('Will search $command $args');
    return new Future.sync(() => 42);
  }

  // end <class FindGrep>
}
// custom <part grep>
// end <part grep>
