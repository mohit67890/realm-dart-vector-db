// Copyright 2025 MongoDB, Inc.
// SPDX-License-Identifier: Apache-2.0

import 'dart:ffi';

import 'error_handling.dart';
import 'ffi.dart';
import '../object_handle.dart';
import 'realm_bindings.dart';
import 'realm_handle.dart';
import 'realm_library.dart';

/// Result of a vector search operation at the native level.
class NativeVectorSearchResult {
  final ObjectHandle objectHandle;
  final double distance;

  NativeVectorSearchResult(this.objectHandle, this.distance);
}

/// Extension on native RealmHandle to provide low-level vector search operations.
extension RealmHandleVectorSearch on RealmHandle {
  /// Performs KNN vector search at the native level.
  List<NativeVectorSearchResult> vectorSearchKnn({
    required int classKey,
    required int propertyKey,
    required List<double> queryVector,
    required int k,
    int efSearch = 50,
  }) {
    return using((arena) {
      final Pointer<Double> queryPtr = arena<Double>(queryVector.length);
      for (var i = 0; i < queryVector.length; i++) {
        queryPtr[i] = queryVector[i];
      }

      final Pointer<realm_hnsw_search_result_t> resultsPtr = arena<realm_hnsw_search_result_t>(k);
      final Pointer<Size> numResultsPtr = arena<Size>();

      realmLib
          .realm_hnsw_search_knn(pointer.cast<realm_t>(), classKey, propertyKey, queryPtr, queryVector.length, k, efSearch, resultsPtr, numResultsPtr)
          .raiseLastErrorIfFalse();

      final numResults = numResultsPtr.value;
      final results = <NativeVectorSearchResult>[];

      for (var i = 0; i < numResults; i++) {
        final result = resultsPtr[i];
        final objHandle = getObject(classKey, result.object_key);
        results.add(NativeVectorSearchResult(objHandle, result.distance));
      }

      return results;
    });
  }

  /// Performs radius-based vector search at the native level.
  List<NativeVectorSearchResult> vectorSearchRadius({
    required int classKey,
    required int propertyKey,
    required List<double> queryVector,
    required double maxDistance,
    int maxResults = 100,
  }) {
    return using((arena) {
      final Pointer<Double> queryPtr = arena<Double>(queryVector.length);
      for (var i = 0; i < queryVector.length; i++) {
        queryPtr[i] = queryVector[i];
      }

      final Pointer<realm_hnsw_search_result_t> resultsPtr = arena<realm_hnsw_search_result_t>(maxResults);
      final Pointer<Size> numResultsPtr = arena<Size>();

      realmLib
          .realm_hnsw_search_radius(
            pointer.cast<realm_t>(),
            classKey,
            propertyKey,
            queryPtr,
            queryVector.length,
            maxDistance,
            resultsPtr,
            maxResults,
            numResultsPtr,
          )
          .raiseLastErrorIfFalse();

      final numResults = numResultsPtr.value;
      final results = <NativeVectorSearchResult>[];

      for (var i = 0; i < numResults; i++) {
        final result = resultsPtr[i];
        final objHandle = getObject(classKey, result.object_key);
        results.add(NativeVectorSearchResult(objHandle, result.distance));
      }

      return results;
    });
  }

  /// Gets statistics about the vector index.
  ({int numVectors, int maxLayer})? getVectorIndexStats({required int classKey, required int propertyKey}) {
    return using((arena) {
      final Pointer<Size> numVectorsPtr = arena<Size>();
      final Pointer<Int> maxLayerPtr = arena<Int>();

      final success = realmLib.realm_hnsw_get_stats(pointer.cast<realm_t>(), classKey, propertyKey, numVectorsPtr, maxLayerPtr);

      if (!success) {
        return null;
      }

      return (numVectors: numVectorsPtr.value, maxLayer: maxLayerPtr.value);
    });
  }

  /// Checks if a vector index exists on the property.
  bool hasVectorIndex({required int classKey, required int propertyKey}) {
    return using((arena) {
      final Pointer<Bool> hasIndexPtr = arena<Bool>();

      final success = realmLib.realm_hnsw_has_index(pointer.cast<realm_t>(), classKey, propertyKey, hasIndexPtr);

      return success && hasIndexPtr.value;
    });
  }

  /// Creates an HNSW vector index on the property.
  void createVectorIndex({required int classKey, required int propertyKey, required realm_hnsw_distance_metric metric, int m = 16, int efConstruction = 200}) {
    realmLib.realm_hnsw_create_index(pointer.cast<realm_t>(), classKey, propertyKey, m, efConstruction, metric).raiseLastErrorIfFalse();
  }

  /// Removes an HNSW vector index from the property.
  void removeVectorIndex({required int classKey, required int propertyKey}) {
    realmLib.realm_hnsw_remove_index(pointer.cast<realm_t>(), classKey, propertyKey).raiseLastErrorIfFalse();
  }
}
