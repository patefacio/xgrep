part of xgrep.xgrep;

class PruneSpec {
  const PruneSpec(this.names, this.paths);

  final List<String> names;
  final List<String> paths;
  // custom <class PruneSpec>
  // end <class PruneSpec>

  Map toJson() =>
      {"names": ebisu_utils.toJson(names), "paths": ebisu_utils.toJson(paths),};

  static PruneSpec fromJson(Object json) {
    if (json == null) return null;
    if (json is String) {
      json = convert.JSON.decode(json);
    }
    assert(json is Map);
    return new PruneSpec._fromJsonMapImpl(json);
  }

  PruneSpec._fromJsonMapImpl(Map jsonMap)
      :
      // names is List<String>
      names = ebisu_utils.constructListFromJsonData(
          jsonMap["names"], (data) => data),
        // paths is List<String>
        paths = ebisu_utils.constructListFromJsonData(
            jsonMap["paths"], (data) => data);

  PruneSpec._copy(PruneSpec other)
      : names = other.names == null ? null : new List.from(other.names),
        paths = other.paths == null ? null : new List.from(other.paths);
}

class Index {
  Id get id => _id;
  /// Paths to include in the index with corresponding prunes specific to the path
  Map<String, PruneSpec> get paths => _paths;
  /// Global set of names to prune on all paths
  List<String> get pruneNames => _pruneNames;
  // custom <class Index>

  Index._default();

  Index(Id id, List<String> paths, [pruneNames = commonPruneNames])
      : this.withPruning(id,
          paths.fold({}, (prev, elm) => prev..[elm] = emptyPruneSpec),
          pruneNames);

  Index.withPruning(this._id, this._paths, [pruneNames = commonPruneNames]);

  toString() => '(${runtimeType}) => ${ebisu_utils.prettyJsonMap(toJson())}';

  Map toJson() => {
    "_id": _id.snake,
    "paths": ebisu_utils.toJson(paths),
    "pruneNames": ebisu_utils.toJson(pruneNames),
  };

  static Index fromJson(Object json) {
    if (json == null) return null;
    if (json is String) {
      json = convert.JSON.decode(json);
    }
    assert(json is Map);
    return new Index._default().._fromJsonMapImpl(json);
  }

  void _fromJsonMapImpl(Map jsonMap) {
    _id = idFromString(jsonMap["_id"]);
    // paths is List<String>
    _paths =
        ebisu_utils.constructMapFromJsonData(jsonMap["paths"], (data) => data);
    // pruneNames is List<String>
    _pruneNames = ebisu_utils.constructListFromJsonData(
        jsonMap["pruneNames"], (data) => data);
  }

  // end <class Index>
  Id _id;
  Map<String, PruneSpec> _paths;
  List<String> _pruneNames;
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

  Future get connectFuture => (_connectFuture == null)
      ? _connectFuture = connect().whenComplete(() => print('Im done'))
      : _connectFuture;

  Future connect();
  Future close();

  Future<List<Index>> get indices;
  Future<Index> lookupIndex(Id id);
  Future persistIndex(Index index);
  Future addPaths(Id id, List<String> paths);
  Future removePaths(Id id, List<String> paths);
  Future removeAllIndices();

  // end <class IndexPersister>
  Future _connectFuture;
}

abstract class IndexUpdater {
  // custom <class IndexUpdater>

  updateIndex(Index indexId);
  DateTime lastUpdate(Index index);
  Map get dbPaths;
  Index get index;

  // end <class IndexUpdater>
}

class Indexer {
  const Indexer(this.indexPersister, this.indexUpdater);

  final IndexPersister indexPersister;
  final IndexUpdater indexUpdater;
  // custom <class Indexer>

  updateIndex(Index index) => indexPersister
      .persistIndex(index)
      .then((_) => indexUpdater.updateIndex(index));

  IndexStats stats(Id indexId) async {
    final index = await indexPersister.lookupIndex(indexId);
    return new IndexStats(index, indexUpdater.lastUpdate(index));
  }

  // end <class Indexer>
}
// custom <part index>

const commonPruneNames = const ['.svn', '.gitignore', '.git', '.pub'];
const emptyPruneSpec = const PruneSpec(const [], const []);

// end <part index>
