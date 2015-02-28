part of xgrep.xgrep;

class Index {
  const Index(this.name, this.paths, this.targetIndex);

  final Id name;
  final List<String> paths;
  final String targetIndex;
  // custom <class Index>
  // end <class Index>
}

class IndexStats {
  const IndexStats(this.index, this.lastUpdate);

  final Index index;
  final DateTime lastUpdate;
  // custom <class IndexStats>
  // end <class IndexStats>
}

abstract class IndexPersister {
  // custom <class IndexPersister>

  List<Index> get indices;
  void persistIndex(Index index);
  Index lookupIndex(Id id);
  void addPaths(Id id, List<String> paths);
  void removePaths(Id id, List<String> paths);

  // end <class IndexPersister>
}

abstract class IndexUpdater {
  // custom <class IndexUpdater>

  void updateIndex(Id indexId);
  DateTime lastUpdate(Index index);

  // end <class IndexUpdater>
}

class Indexer {
  const Indexer(this.indexPersister, this.indexUpdater);

  final IndexPersister indexPersister;
  final IndexUpdater indexUpdater;
  // custom <class Indexer>

  void updateIndex(Index index) {
    indexPersister.persistIndex(index);
    indexUpdater.updateIndex(index);
  }

  IndexStats stats(Id indexId) {
    final index = indexPersister.lookupIndex(indexId);
    return new IndexStats(index, indexUpdater.lastUpdate);
  }

  // end <class Indexer>
}
// custom <part index>
// end <part index>
