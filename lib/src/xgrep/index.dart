part of xgrep.xgrep;

/// Comparable to *prune* flags on *updatedb* linux command.
///
class PruneSpec {
  const PruneSpec(this.names, this.paths);

  bool operator ==(PruneSpec other) => identical(this, other) ||
      const ListEquality().equals(names, other.names) &&
          const ListEquality().equals(paths, other.paths);

  int get hashCode => hash2(const ListEquality<String>().hash(names),
      const ListEquality<String>().hash(paths));

  /// Directory names (without paths) which should not be included in a path database.
  final List<String> names;
  /// Fully qualified paths which should not be included in a path database.
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

class FindArgs {
  const FindArgs(this.includes, this.excludes);

  final List<RegExp> includes;
  final List<RegExp> excludes;
  // custom <class FindArgs>
  // end <class FindArgs>
}

/// Defines a name index which establishes a set of filesystem paths that can be
/// indexed and later searched.
///
class Index {
  bool operator ==(Index other) => identical(this, other) ||
      _id == other._id &&
          const MapEquality().equals(_paths, other._paths) &&
          const ListEquality().equals(_pruneNames, other._pruneNames);

  int get hashCode => hash3(_id, const MapEquality().hash(_paths),
      const ListEquality<String>().hash(_pruneNames));

  Id get id => _id;
  /// Paths to include in the index mapped with any corresponding pruning specific to
  /// that path
  Map<String, PruneSpec> get paths => _paths;
  /// Global set of names to prune on all paths in this index
  List<String> get pruneNames => _pruneNames;
  // custom <class Index>

  Index._default();

  Index(Id id, List<String> paths, [pruneNames = commonPruneNames])
      : this.withPruning(id,
          paths.fold({}, (prev, elm) => prev..[elm] = emptyPruneSpec),
          pruneNames);

  Index.withPruning(this._id, this._paths,
      [this._pruneNames = commonPruneNames]);

  toString() => '(${runtimeType}) => ${ebisu_utils.prettyJsonMap(toJson())}';

  addPath(String path, [PruneSpec pruneSpec = emptyPruneSpec]) =>
      paths[path] = pruneSpec;

  addPaths(Map<String, Prunespec> additions) => paths.addall(additions);

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
    _paths = ebisu_utils.constructMapFromJsonData(
        jsonMap["paths"], (data) => PruneSpec.fromJson(data));
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

/// Establishes an interface that persists *Indices* as well as other
/// meta-data associated with the creation, update, and usage those
/// *Indices*.
///
abstract class IndexPersister {
  // custom <class IndexPersister>

  Future get connectFuture => (_connectFuture == null)
      ? _connectFuture = connect().whenComplete(
          () => _logger.info('Opened an IndexPersister connection'))
      : _connectFuture;

  Future connect();
  Future close();

  Future<List<Index>> get indices;
  Future persistIndex(Index index);
  Future<Index> lookupIndex(Id id);
  Future addPaths(Id id, List<String> paths);
  Future removePaths(Id id, List<String> paths);
  Future removeAllIndices();
  Future removeIndex(Id id);

  // end <class IndexPersister>
  Future _connectFuture;
}

/// Establishes an interface that is used to update indices on the
/// filesystem using some for of indexer like the Linux *updatedb*
/// command. Also provides support for finding matching files associated
/// with an index.
abstract class IndexUpdater {
  // custom <class IndexUpdater>

  /// Trigger an update of the index - for example run a linux *updatedb* on all
  /// the paths with the appropriate settings
  Future updateIndex(Index index);

  /// Remove the index identified by [id]
  Future removeIndex(Id id);

  /// Use the supplied [index] to perform a query on databases associated with
  /// the [paths] in the index. The result is a stream of filenames
  Future<Stream<String>> findPaths(Index index,
      [FindArgs findArgs = emptyFindArgs]);

  Future history(Id id);

  // end <class IndexUpdater>
}

class Indexer {
  const Indexer(this.indexPersister, this.indexUpdater);

  final IndexPersister indexPersister;
  final IndexUpdater indexUpdater;
  // custom <class Indexer>

  static Future withIndexer(Future callback(Indexer indexer)) {
    return MongoIndexPersister.withIndexPersister((IndexPersister persister) {
      return callback(new Indexer(persister, new MlocateIndexUpdater()));
    });
  }

  updateIndex(Index index) => indexUpdater.updateIndex(index);

  updateIndexById(Id indexId) async {
    final index = await lookupIndex(indexId);
    if (index != null) {
      return updateIndex(index);
    }
    _logger.warning('Requested update of unkown index: ${indexId.snake}');
  }

  saveAndUpdateIndex(Index index) => indexPersister
      .persistIndex(index)
      .then((_) => indexUpdater.updateIndex(index));

  IndexStats stats(Id indexId) async {
    final index = await lookupIndex(indexId);
    return new IndexStats(index, indexUpdater.lastUpdate(index));
  }

  removeIndex(Id id) {
    _logger.info('Indexer removing index ${id.snake}');
    return indexPersister
        .removeIndex(id)
        .then((_) => indexUpdater.removeIndex(id));
  }

  removeAllIndices() => indexPersister.indices.then((List<Index> indices) {
    _logger.info('Indexer removeAllIndices begin removing ${indices.length}');
    final futures = [];
    for (final index in indices) {
      _logger.info('removeAllIndices removing index ${index.id}');
      futures.add(indexUpdater.removeIndex(index.id));
    }
    _logger.info('Indexer removeAllIndices completed');
    return Future.wait(futures).then((_) => indexPersister.removeAllIndices());
  });

  Future<List<Index>> get indices => indexPersister.indices;

  Future processPaths(Index index, processor(String)) async {
    final completer = new Completer<String>();
    indexUpdater.findPaths(index).then((Stream stream) {
      stream.listen((String path) => processor(path),
          onDone: () => completer.complete());
    });
    await completer.future;
  }

  Future<Stream<String>> findPaths(Index index,
          [FindArgs findArgs = emptyFindArgs]) =>
      indexUpdater.findPaths(index, findArgs);

  Future<Index> lookupIndex(Id id) => indexPersister.lookupIndex(id);

  // end <class Indexer>
}
// custom <part index>

const commonPruneNames = const ['.svn', '.gitignore', '.git', '.pub'];
const emptyPruneSpec = const PruneSpec(const [], const []);
const emptyFindArgs = const FindArgs(const [], const []);

// end <part index>
