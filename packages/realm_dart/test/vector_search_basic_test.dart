// Copyright 2025 MongoDB, Inc.
// SPDX-License-Identifier: Apache-2.0

import 'package:realm_dart_vector_db/realm.dart';
import 'test.dart';

part 'vector_search_basic_test.realm.dart';

@RealmModel()
class _VectorDoc {
  @PrimaryKey()
  late String id;

  late String title;
  late List<double> embedding;
}

void main() {
  setupTests();

  group('Vector Search - Basic Tests', () {
    test('KNN search without filters', () {
      final config = Configuration.local([VectorDoc.schema]);
      final realm = getRealm(config);

      realm.write(() {
        // Create vector index with default metric (Euclidean)
        realm.createVectorIndex<VectorDoc>('embedding');

        // Insert test documents with simple 3D vectors
        realm.add(VectorDoc('1', 'Auth Issue', embedding: [1.0, 0.0, 0.0]));
        realm.add(VectorDoc('2', 'Billing Issue', embedding: [0.0, 1.0, 0.0]));
        realm.add(VectorDoc('3', 'Performance Issue', embedding: [0.0, 0.0, 1.0]));
        realm.add(VectorDoc('4', 'Similar Auth', embedding: [0.9, 0.1, 0.0]));
        realm.add(VectorDoc('5', 'Similar Perf', embedding: [0.1, 0.0, 0.9]));
      });

      // Query for documents similar to [1.0, 0.0, 0.0] (Auth issues)
      final results = realm.vectorSearchKnn<VectorDoc>('embedding', queryVector: [1.0, 0.0, 0.0], k: 3);

      expect(results.length, equals(3));
      expect(results[0].object.id, equals('1')); // Exact match
      expect(results[0].distance, closeTo(0.0, 0.001));
      expect(results[1].object.id, equals('4')); // Very similar
    });

    test('Radius search', () {
      final config = Configuration.local([VectorDoc.schema]);
      final realm = getRealm(config);

      realm.write(() {
        realm.createVectorIndex<VectorDoc>('embedding');

        // Create documents at different distances from origin
        realm.add(VectorDoc('close1', 'Close 1', embedding: [0.1, 0.1]));
        realm.add(VectorDoc('close2', 'Close 2', embedding: [0.2, 0.1]));
        realm.add(VectorDoc('medium', 'Medium', embedding: [0.5, 0.5]));
        realm.add(VectorDoc('far', 'Far', embedding: [5.0, 5.0]));
      });

      // Search within radius 1.0 from origin
      final results = realm.vectorSearchRadius<VectorDoc>('embedding', queryVector: [0.0, 0.0], maxDistance: 1.0);

      expect(results.length, equals(3)); // close1, close2, medium
      expect(results.every((r) => r.distance <= 1.0), isTrue);

      // Verify far document is not included
      expect(results.any((r) => r.object.id == 'far'), isFalse);
    });

    test('Different distance metrics', () {
      final config = Configuration.local([VectorDoc.schema]);
      final realm = getRealm(config);

      realm.write(() {
        // Create index with cosine metric
        realm.createVectorIndex<VectorDoc>('embedding', metric: VectorDistanceMetric.cosine);

        // Same direction, different magnitudes
        realm.add(VectorDoc('short', 'Short Vector', embedding: [1.0, 1.0]));
        realm.add(VectorDoc('long', 'Long Vector', embedding: [10.0, 10.0]));
        // Different direction
        realm.add(VectorDoc('diff', 'Different Direction', embedding: [1.0, -1.0]));
      });

      final results = realm.vectorSearchKnn<VectorDoc>('embedding', queryVector: [1.0, 1.0], k: 3);

      // With cosine, magnitude doesn't matter - short and long should be equally similar
      expect(results[0].distance, closeTo(results[1].distance, 0.001));
      // Different direction should be furthest
      expect(results[2].distance, greaterThan(results[0].distance));
    });

    test('Index management', () {
      final config = Configuration.local([VectorDoc.schema]);
      final realm = getRealm(config);

      realm.write(() {
        // Create index
        realm.createVectorIndex<VectorDoc>('embedding');

        // Add some data
        realm.add(VectorDoc('1', 'Doc 1', embedding: [1.0, 0.0]));
      });

      // Verify index exists
      final hasIndex = realm.hasVectorIndex<VectorDoc>('embedding');
      expect(hasIndex, isTrue);

      // Get stats
      final stats = realm.getVectorIndexStats<VectorDoc>('embedding');
      expect(stats, isNotNull);
      expect(stats!.numVectors, equals(1));

      realm.write(() {
        // Remove index
        realm.removeVectorIndex<VectorDoc>('embedding');
      });

      // Verify index is removed
      final hasIndexAfter = realm.hasVectorIndex<VectorDoc>('embedding');
      expect(hasIndexAfter, isFalse);
    });

    test('Manual filtering after search', () {
      final config = Configuration.local([VectorDoc.schema]);
      final realm = getRealm(config);

      realm.write(() {
        realm.createVectorIndex<VectorDoc>('embedding');

        // Add various documents
        realm.add(VectorDoc('auth1', 'Auth Issue 1', embedding: [1.0, 0.0, 0.0]));
        realm.add(VectorDoc('bill1', 'Billing Issue', embedding: [0.9, 0.1, 0.0]));
        realm.add(VectorDoc('auth2', 'Auth Issue 2', embedding: [0.8, 0.2, 0.0]));
        realm.add(VectorDoc('perf1', 'Performance', embedding: [0.7, 0.3, 0.0]));
      });

      // Get KNN results
      final allResults = realm.vectorSearchKnn<VectorDoc>('embedding', queryVector: [1.0, 0.0, 0.0], k: 10);

      // Filter for auth documents only (those starting with 'auth')
      final authResults = allResults.where((r) => r.object.id.startsWith('auth')).toList();

      expect(authResults.length, equals(2));
      expect(authResults.every((r) => r.object.id.startsWith('auth')), isTrue);

      // Results should still be sorted by distance
      for (int i = 0; i < authResults.length - 1; i++) {
        expect(authResults[i].distance, lessThanOrEqualTo(authResults[i + 1].distance));
      }
    });
  });
}
