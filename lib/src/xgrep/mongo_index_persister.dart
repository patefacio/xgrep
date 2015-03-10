part of xgrep.xgrep;

/// Default implementation of an [IndexPersister] which stores index
/// information in *MongoDB*
class MongoIndexPersister extends IndexPersister {
  String get uri => _uri;
  // custom <class MongoIndexPersister>

  MongoIndexPersister([String uri]) : _uri = (uri==null)? _mongoUri : uri;

  static Future withIndexPersister(Future callback(IndexPersister),
      [String uri]) async {
    if(uri == null) uri = _mongoUri;
    final indexPersister = new MongoIndexPersister(uri);
    try {
      final persister = await indexPersister.connectFuture;
      await callback(persister);
    } finally {
      indexPersister.close();
    }
  }

  String get indexCollectionName => '${defaultCollectionPrefix}_indices';
  String get filtersCollectionName => '${defaultCollectionPrefix}_filters';

  Future connect() {
    _db = new Db(uri);
    return _db.open().then((c) {
      _indices = _db.collection(indexCollectionName);
      _filterSets = _db.collection(filtersCollectionName);
      return this;
    });
  }

  Future close() {
    _logger.info('Closing mongo connnection against $connectFuture on $_db');
    return connectFuture.then((c) => _db.close());
  }

  Future<List<Index>> get indices {
    _logger.info('Retrieving indices from mongo');
    return connectFuture.then((c) => _indices
        .find({})
        .toList()
        .then((List<Map> data) =>
            data.map((Map datum) => Index.fromJson(datum)).toList()));
  }

  Future lookupIndex(Id id) => connectFuture.then((c) => _indices
      .find({'_id': id.snake})
      .toList()
      .then((List<Map> data) {
    _logger.info('Looking up index *${id.snake}*');
    if (data.isEmpty) {
      return null;
    } else {
      return Index.fromJson(data.first);
    }
  }));

  Future persistIndex(Index index) {
    _logger.info('Persisting $index');
    return connectFuture.then((c) => _indices
        .save(index.toJson())
        .then((mongoResult) => _convertResult(
            mongoResult, () => 'Unable to persist index $index', index)));
  }

  _convertResult(mongoResult, String messageMaker(), [returnValue]) {
    if (mongoResult['ok'] !=
        1) throw new Exception('${messageMaker()}\n$mongoResult');
    return returnValue;
  }

  Future addPaths(Id id, dynamic paths) => lookupIndex(id).then((Index index) {
    if (index != null) {
      if (paths is List) {
        paths.forEach((p) => index.addPath(p));
      } else if (paths is Map) {
        index.addPaths(paths);
      } else {
        throw new Exception('''
When adding paths provide either:
* List<String> as paths with no pruning
* Map<String, PruneSpec> paths to include with some pruning
''');
      }
      return persistIndex(index);
    }
  });

  Future removePaths(Id id, List<String> paths) => lookupIndex(id).then(
      (Index index) {
    if (index != null) {
      paths.forEach((p) => index.paths.remove(p));
      return persistIndex(index);
    }
  });

  Future removeAllIndices() => connectFuture.then((c) => _indices.remove({}));

  Future removeIndex(Id indexId) => connectFuture.then((c) => _indices
      .remove({'_id': indexId.snake})
      .then((mongoResult) => _convertResult(mongoResult,
          () => 'Unable to remove index ${indexId.snake}', indexId)));

  Future<List<FilenameFilterSet>> get filenameFilterSets {
    _logger.info('Retrieving filename filter sets from mongo');
    return connectFuture.then((c) => _filterSets
        .find({})
        .toList()
        .then((List<Map> data) => data
            .map((Map datum) => FilenameFilterSet.fromJson(datum))
            .toList()));
  }

  Future persistFilenameFilterSet(FilenameFilterSet filterSet) {
    _logger.info('Persisting filename filter set $filterSet');
    return connectFuture.then((c) => _filterSets
        .save(filterSet.toJson())
        .then((mongoResult) => _convertResult(mongoResult,
            () => 'Unable to persist filename filter set $filterSet',
            filterSet)));
  }

  Future removeFilenameFilterSet(Id filterId) => connectFuture.then(
      (c) => _filterSets
          .remove({'_id': filterId.snake})
          .then((mongoResult) => _convertResult(mongoResult,
              () => 'Unable to remove filter set ${filterId.snake}',
              filterId)));

  Future removeAllFilenameFilterSets() {
    _logger.info('Removing all filters');
    return connectFuture.then((c) => _filterSets.remove({}));
  }

  // end <class MongoIndexPersister>
  final String _uri;
  Db _db;
  DbCollection _indices;
  DbCollection _filterSets;
}
// custom <part mongo_index_persister>

const defaultUri = "mongodb://127.0.0.1/xgreps";

final _mongoUri = Platform.environment['XGREP_MONGO_URI'] == null?
  defaultUri : Platform.environment['XGREP_MONGO_URI'];

String _defaultCollectionPrefix = Platform.environment['XGREP_COL_PREFIX'] ==
        null
    ? Platform.environment['USER']
    : Platform.environment['XGREP_COL_PREFIX'];
set defaultCollectionPrefix(String str) => _defaultCollectionPrefix = str;
get defaultCollectionPrefix => _defaultCollectionPrefix;

// end <part mongo_index_persister>
