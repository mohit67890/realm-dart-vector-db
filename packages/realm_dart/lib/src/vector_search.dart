// Copyright 2025 MongoDB, Inc.
// SPDX-License-Identifier: Apache-2.0

// Import native implementation to get vector search methods
import 'handles/native/realm_bindings.dart' show realm_hnsw_distance_metric;
import 'handles/native/realm_handle.dart' as native_handle show RealmHandle, NativeVectorSearchResult;
import 'realm_class.dart';
import 'realm_object.dart';

/// Distance metric for vector similarity search.
///
/// {@category Realm}
enum VectorDistanceMetric {
  /// Euclidean distance (L2 norm). Measures the straight-line distance between vectors.
  /// Lower values indicate higher similarity. Best for vectors where magnitude matters.
  euclidean,

  /// Cosine similarity. Measures the angle between vectors, independent of magnitude.
  /// Values range from 0 (identical) to 2 (opposite). Best for normalized embeddings.
  cosine,

  /// Dot product. Measures both angle and magnitude. Negative values optimized for
  /// maximum inner product search (MIPS). Best for recommendation systems.
  dotProduct;

  /// @nodoc
  int get _nativeValue {
    switch (this) {
      case VectorDistanceMetric.euclidean:
        return 0; // RLM_HNSW_METRIC_EUCLIDEAN
      case VectorDistanceMetric.cosine:
        return 1; // RLM_HNSW_METRIC_COSINE
      case VectorDistanceMetric.dotProduct:
        return 2; // RLM_HNSW_METRIC_DOT_PRODUCT
    }
  }
}

/// Result of a vector similarity search operation.
///
/// Contains a reference to the found object and its distance from the query vector.
///
/// {@category Realm}
class VectorSearchResult<T extends RealmObject> {
  /// The object found by the search.
  final T object;

  /// The distance between the query vector and this object's vector.
  /// Interpretation depends on the distance metric:
  /// - Euclidean: Lower is more similar (0 = identical)
  /// - Cosine: Lower is more similar (0 = identical, 2 = opposite)
  /// - Dot Product: More negative is more similar
  final double distance;

  const VectorSearchResult(this.object, this.distance);

  @override
  String toString() => 'VectorSearchResult(object: $object, distance: $distance)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is VectorSearchResult && runtimeType == other.runtimeType && object == other.object && distance == other.distance;

  @override
  int get hashCode => Object.hash(object, distance);
}

/// Statistics about an HNSW vector index.
///
/// {@category Realm}
class VectorIndexStats {
  /// The number of vectors currently indexed.
  final int numVectors;

  /// The maximum layer in the HNSW graph structure.
  /// Higher values indicate a more complex graph, typically built from more insertions.
  final int maxLayer;

  const VectorIndexStats({required this.numVectors, required this.maxLayer});

  @override
  String toString() => 'VectorIndexStats(numVectors: $numVectors, maxLayer: $maxLayer)';
}

/// Extension on [Realm] providing vector similarity search capabilities.
///
/// Enables HNSW (Hierarchical Navigable Small World) based approximate nearest
/// neighbor search for List<double> properties.
///
/// Example:
/// ```dart
/// class Document extends RealmObject {
///   @PrimaryKey()
///   late String id;
///
///   @Indexed(RealmIndexType.vector)
///   late List<double> embedding;
/// }
///
/// final results = realm.vectorSearchKnn<Document>(
///   'embedding',
///   queryVector: [0.1, 0.2, 0.3],
///   k: 10,
/// );
///
/// for (final result in results) {
///   print('${result.object.id}: distance=${result.distance}');
/// }
/// ```
///
/// {@category Realm}
extension VectorSearchExtension on Realm {
  /// Performs k-nearest neighbor (KNN) vector similarity search.
  ///
  /// Finds the [k] most similar vectors to [queryVector] using an HNSW index
  /// on the specified [propertyName].
  ///
  /// * [propertyName]: The name of the List<double> property to search.
  /// * [queryVector]: The query vector to search for. Must have the same
  ///   dimensions as the indexed vectors.
  /// * [k]: The number of nearest neighbors to return.
  /// * [efSearch]: The size of the dynamic candidate list during search.
  ///   Higher values improve accuracy but slow down search. Default is 50.
  ///
  /// Returns a list of [VectorSearchResult] sorted by distance (closest first).
  ///
  /// Throws [RealmError] if:
  /// - No vector index exists on the property
  /// - Query vector dimensions don't match indexed vectors
  /// - The property is not of type List<double>
  List<VectorSearchResult<T>> vectorSearchKnn<T extends RealmObject>(
    String propertyName, {
    required List<double> queryVector,
    required int k,
    int efSearch = 50,
  }) {
    if (k <= 0) {
      throw ArgumentError.value(k, 'k', 'Must be greater than 0');
    }
    if (efSearch <= 0) {
      throw ArgumentError.value(efSearch, 'efSearch', 'Must be greater than 0');
    }
    if (queryVector.isEmpty) {
      throw ArgumentError.value(queryVector, 'queryVector', 'Cannot be empty');
    }

    final metadata = _getMetadata<T>();
    final propertyMeta = _getPropertyMetadata(metadata, propertyName);

    // Cast to native handle to access vector search extension methods
    final nativeHandle = handle as native_handle.RealmHandle;
    final nativeResults = nativeHandle.vectorSearchKnn(
      classKey: metadata.classKey,
      propertyKey: propertyMeta.key,
      queryVector: queryVector,
      k: k,
      efSearch: efSearch,
    );

    final results = <VectorSearchResult<T>>[];
    for (final nativeResult in nativeResults) {
      final obj = createObject(T, nativeResult.objectHandle, metadata) as T;
      results.add(VectorSearchResult(obj, nativeResult.distance));
    }

    return results;
  }

  /// Performs radius-based vector similarity search.
  ///
  /// Finds all vectors within [maxDistance] from [queryVector] using an HNSW
  /// index on the specified [propertyName].
  ///
  /// * [propertyName]: The name of the List<double> property to search.
  /// * [queryVector]: The query vector to search for. Must have the same
  ///   dimensions as the indexed vectors.
  /// * [maxDistance]: The maximum distance threshold. Only vectors within this
  ///   distance will be returned.
  /// * [maxResults]: The maximum number of results to return. Defaults to 100.
  ///
  /// Returns a list of [VectorSearchResult] sorted by distance (closest first).
  ///
  /// Throws [RealmError] if:
  /// - No vector index exists on the property
  /// - Query vector dimensions don't match indexed vectors
  /// - The property is not of type List<double>
  List<VectorSearchResult<T>> vectorSearchRadius<T extends RealmObject>(
    String propertyName, {
    required List<double> queryVector,
    required double maxDistance,
    int maxResults = 100,
  }) {
    if (maxDistance < 0) {
      throw ArgumentError.value(maxDistance, 'maxDistance', 'Cannot be negative');
    }
    if (maxResults <= 0) {
      throw ArgumentError.value(maxResults, 'maxResults', 'Must be greater than 0');
    }
    if (queryVector.isEmpty) {
      throw ArgumentError.value(queryVector, 'queryVector', 'Cannot be empty');
    }

    final metadata = _getMetadata<T>();
    final propertyMeta = _getPropertyMetadata(metadata, propertyName);

    // Cast to native handle to access vector search extension methods
    final nativeHandle = handle as native_handle.RealmHandle;
    final nativeResults = nativeHandle.vectorSearchRadius(
      classKey: metadata.classKey,
      propertyKey: propertyMeta.key,
      queryVector: queryVector,
      maxDistance: maxDistance,
      maxResults: maxResults,
    );

    final results = <VectorSearchResult<T>>[];
    for (final nativeResult in nativeResults) {
      final obj = createObject(T, nativeResult.objectHandle, metadata) as T;
      results.add(VectorSearchResult(obj, nativeResult.distance));
    }

    return results;
  }

  /// Gets statistics about the vector index on the specified property.
  ///
  /// Returns [VectorIndexStats] containing information about the index size
  /// and structure, or `null` if no index exists on the property.
  ///
  /// * [propertyName]: The name of the List<double> property to check.
  VectorIndexStats? getVectorIndexStats<T extends RealmObject>(String propertyName) {
    final metadata = _getMetadata<T>();
    final propertyMeta = _getPropertyMetadata(metadata, propertyName);

    // Cast to native handle to access vector search extension methods
    final nativeHandle = handle as native_handle.RealmHandle;
    final stats = nativeHandle.getVectorIndexStats(classKey: metadata.classKey, propertyKey: propertyMeta.key);

    if (stats == null) {
      return null;
    }

    return VectorIndexStats(numVectors: stats.numVectors, maxLayer: stats.maxLayer);
  }

  /// Checks if a vector index exists on the specified property.
  ///
  /// Returns `true` if an HNSW vector index exists on the property,
  /// `false` otherwise.
  ///
  /// * [propertyName]: The name of the List<double> property to check.
  bool hasVectorIndex<T extends RealmObject>(String propertyName) {
    final metadata = _getMetadata<T>();
    final propertyMeta = _getPropertyMetadata(metadata, propertyName);

    // Cast to native handle to access vector search extension methods
    final nativeHandle = handle as native_handle.RealmHandle;
    return nativeHandle.hasVectorIndex(classKey: metadata.classKey, propertyKey: propertyMeta.key);
  }

  /// Creates an HNSW vector index on the specified property.
  ///
  /// This must be called within a write transaction. The index enables fast
  /// approximate nearest neighbor search on the property's vectors.
  ///
  /// * [propertyName]: The name of the `List<double>` property to index.
  /// * [metric]: The distance metric to use for similarity calculations.
  ///   This cannot be changed after index creation.
  /// * [m]: Number of bidirectional links per node (except layer 0). Higher values
  ///   improve recall but increase memory usage. Default: 16.
  /// * [efConstruction]: Size of dynamic candidate list during construction. Higher
  ///   values improve index quality but slow down construction. Default: 200.
  ///
  /// Example:
  /// ```dart
  /// realm.write(() {
  ///   realm.createVectorIndex<Document>(
  ///     'embedding',
  ///     metric: VectorDistanceMetric.cosine,
  ///   );
  /// });
  /// ```
  ///
  /// Throws [RealmError] if:
  /// - Not in a write transaction
  /// - Index already exists on the property
  /// - Property is not of type `List<double>`
  void createVectorIndex<T extends RealmObject>(
    String propertyName, {
    VectorDistanceMetric metric = VectorDistanceMetric.euclidean,
    int m = 16,
    int efConstruction = 200,
  }) {
    if (m <= 0) {
      throw ArgumentError.value(m, 'm', 'Must be greater than 0');
    }
    if (efConstruction <= 0) {
      throw ArgumentError.value(efConstruction, 'efConstruction', 'Must be greater than 0');
    }

    final metadata = _getMetadata<T>();
    final propertyMeta = _getPropertyMetadata(metadata, propertyName);

    // Cast to native handle to access vector search extension methods
    final nativeHandle = handle as native_handle.RealmHandle;
    nativeHandle.createVectorIndex(
      classKey: metadata.classKey,
      propertyKey: propertyMeta.key,
      metric: realm_hnsw_distance_metric.values[metric._nativeValue],
      m: m,
      efConstruction: efConstruction,
    );
  }

  /// Removes an HNSW vector index from the specified property.
  ///
  /// This must be called within a write transaction.
  ///
  /// * [propertyName]: The name of the `List<double>` property.
  ///
  /// Example:
  /// ```dart
  /// realm.write(() {
  ///   realm.removeVectorIndex<Document>('embedding');
  /// });
  /// ```
  ///
  /// Throws [RealmError] if:
  /// - Not in a write transaction
  /// - No index exists on the property
  void removeVectorIndex<T extends RealmObject>(String propertyName) {
    final metadata = _getMetadata<T>();
    final propertyMeta = _getPropertyMetadata(metadata, propertyName);

    // Cast to native handle to access vector search extension methods
    final nativeHandle = handle as native_handle.RealmHandle;
    nativeHandle.removeVectorIndex(classKey: metadata.classKey, propertyKey: propertyMeta.key);
  }

  RealmObjectMetadata _getMetadata<T extends RealmObject>() {
    return metadata.getByType(T);
  }

  RealmPropertyMetadata _getPropertyMetadata(RealmObjectMetadata metadata, String propertyName) {
    return metadata[propertyName];
  }
}
