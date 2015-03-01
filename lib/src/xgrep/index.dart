part of xgrep.xgrep;

class Index {
  Index(this._id, this._paths,
      [this._pruneNames = const ['.svn', '.gitignore', '.git', '.pub']]);

  Index._default();

  Id get id => _id;
  List<String> get paths => _paths;
  List<String> get pruneNames => _pruneNames;
  // custom <class Index>
  // end <class Index>

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
    print('Got map $jsonMap');
    _id = idFromString(jsonMap["_id"]);
    // paths is List<String>
    _paths =
        ebisu_utils.constructListFromJsonData(jsonMap["paths"], (data) => data);
    // pruneNames is List<String>
    _pruneNames = ebisu_utils.constructListFromJsonData(
        jsonMap["pruneNames"], (data) => data);
  }
  Id _id;
  List<String> _paths;
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

  Future get connectFuture =>
    (_connectFuture == null) ?
    _connectFuture =
    connect().whenComplete(() => print('Im done')) : _connectFuture;

  Future connect();
  Future close();

  Future<List<Index>> get indices;
  Future<Index> lookupIndex(Id id);
  Future persistIndex(Index index);
  Future addPaths(Id id, List<String> paths);
  Future removePaths(Id id, List<String> paths);

  // end <class IndexPersister>
  Future _connectFuture;
}

abstract class IndexUpdater {
  // custom <class IndexUpdater>

  updateIndex(Index indexId);
  DateTime lastUpdate(Index index);

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

  IndexStats stats(Id indexId) {
    final index = indexPersister.lookupIndex(indexId);
    return new IndexStats(index, indexUpdater.lastUpdate);
  }

  // end <class Indexer>
}
// custom <part index>
// end <part index>
