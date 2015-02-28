part of xgrep.xgrep;

class MlocateIndexer implements Indexer {
  // custom <class MlocateIndexer>

  List<Index> get indices;
  void updateIndex(Index index);
  void addPaths(Id id, List<String> paths);
  void removePaths(Id id, List<String> paths);
  IndexStats stats(Id id);

  // end <class MlocateIndexer>
}
// custom <part mlocate_indexer>
// end <part mlocate_indexer>
