part of xgrep.xgrep;

class GrepArgs {
  const GrepArgs(this.args);

  final List<String> args;
  // custom <class GrepArgs>
  // end <class GrepArgs>
}

class FindGrep {
  const FindGrep(this.indexer, this.indexId, this.grepArgs);

  final Indexer indexer;
  final Id indexId;
  final GrepArgs grepArgs;
  // custom <class FindGrep>

  Future grep() {
    print('Grepping $indexId');
  }

  // end <class FindGrep>
}
// custom <part grep>

grepWithIndexer(Id indexId, GrepArgs grepArgs, Indexer indexer) async {
  //  indexer.ProcessPaths(
}

grep(GrepArgs grepArgs, Id indexId, [Indexer indexer]) async {
  if (indexer == null) {
    indexer = new Indexer(new MongoIndexPersister(), new MlocateIndexUpdater());
  }
  final findGrep = new FindGrep(indexer, indexId, grepArgs);
  findGrep.grep();
}

// end <part grep>
