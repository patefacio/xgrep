part of xgrep.xgrep;

class MongoIndexPersister extends IndexPersister {
  String get uri => _uri;
  // custom <class MongoIndexPersister>

  MongoIndexPersister([String uri = defaultUri]) : _uri = uri;

  static Future withIndexPersister(Future callback(IndexPersister),
      [String uri = defaultUri]) async {
    final indexPersister = new MongoIndexPersister(uri);
    try {
      final persister = await indexPersister.connectFuture;
      await callback(persister);
    } finally {
      indexPersister.close();
    }
  }

  String get collectionName => '${defaultCollectionPrefix}_indices';

  Future connect() {
    _db = new Db(uri);
    print('Trying to connect $uri');
    return _db.open().then((c) {
      print('RT ${c.runtimeType} $c');
      _indices = _db.collection(collectionName);
      return this;
    });
  }

  Future close() {
    print('Closing mongo connnection against $connectFuture on $_db');
    final result = connectFuture.then((c) => _db.close());
    print('Completed $result');
    return result;
  }

  Future<List<Index>> get indices => connectFuture.then((c) => _indices
      .find({})
      .toList()
      .then((List<Map> data) =>
          data.map((Map datum) => Index.fromJson(datum)).toList()));

  Future lookupIndex(Id id) => connectFuture.then((c) => _indices
      .find({'_id': id.snake})
      .toList()
      .then((List<Map> data) =>
          data.map((Map datum) => Index.fromJson(datum)).toList()));

  Future persistIndex(Index index) {
    print('Persisting $index');
    return connectFuture.then((c) => _indices.save(index.toJson()));
  }

  Future addPaths(Id id, List<String> paths) =>
      connectFuture.then((c) => new Future.sync(() => null));

  Future removePaths(Id id, List<String> paths) =>
      connectFuture.then((c) => new Future.sync(() => null));

  Future removeAllIndices() =>
    connectFuture.then((c) => _indices.remove({}));

  _sample() => new Index(new Id('foo_bar'), ['/tmp/a', '/tmp/b']);

  // end <class MongoIndexPersister>
  final String _uri;
  Db _db;
  DbCollection _indices;
}
// custom <part mongo_index_persister>

const defaultUri = "mongodb://127.0.0.1/xgreps";


String _defaultCollectionPrefix = Platform.environment['USER'];
set defaultCollectionPrefix(String str) => _defaultCollectionPrefix = str;
get defaultCollectionPrefix => _defaultCollectionPrefix;

// end <part mongo_index_persister>
