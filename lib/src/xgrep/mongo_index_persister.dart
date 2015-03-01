part of xgrep.xgrep;

class MongoIndexPersister extends IndexPersister {
  String get uri => _uri;
  // custom <class MongoIndexPersister>

  MongoIndexPersister([String uri = "mongodb://127.0.0.1/xgreps"]) : _uri = uri;

  Future connect() {
    _db = new Db(uri);
    print('Trying to connect $uri');
    return _db.open().then((c) {
      print('RT ${c.runtimeType}');
      _indices = _db.collection('indices');
      return this;
    });
  }

  Future close() => connectFuture.then((c) => _db.close());

  Future<List<Index>> get indices => connectFuture.then((c) => _indices
      .find()
      .toList()
      .then((List<Map> data) => data.map((Map datum) => Index.fromJson(datum)).toList()));

  Future<Index> lookupIndex(Id id) =>
      connectFuture.then((c) => new Future.sync(() => _sample()));

  Future persistIndex(Index index) =>
      connectFuture.then((c) => _indices.save(index.toJson()));

  Future addPaths(Id id, List<String> paths) =>
      connectFuture.then((c) => new Future.sync(() => null));

  Future removePaths(Id id, List<String> paths) =>
      connectFuture.then((c) => new Future.sync(() => null));

  _sample() => new Index(new Id('foo_bar'), ['/tmp/a', '/tmp/b']);

  // end <class MongoIndexPersister>
  final String _uri;
  Db _db;
  DbCollection _indices;
}
// custom <part mongo_index_persister>
// end <part mongo_index_persister>
