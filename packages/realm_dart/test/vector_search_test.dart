// Copyright 2025 MongoDB, Inc.
// SPDX-License-Identifier: Apache-2.0

import 'dart:math';
import 'package:realm_dart_vector_db/realm_dart_vector_db.dart';
import 'test.dart';

part 'vector_search_test.realm.dart';

@RealmModel()
class _Document {
  @PrimaryKey()
  late String id;

  late String title;
  late String? category;
  late String? priority;
  late List<double> embedding;
}

void main() {
  setupTests();

  group('Vector Search - Basic', () {
    test('KNN search without filters', () {
      final config = Configuration.local([Document.schema]);
      final realm = getRealm(config);

      realm.write(() {
        // Create vector index with default metric (Euclidean)
        realm.createVectorIndex<Document>('embedding');

        // Insert test documents
        realm.add(Document('1', 'Login issue', category: 'Auth', priority: 'High', embedding: [1.0, 0.0, 0.0]));
        realm.add(Document('2', 'Payment failed', category: 'Billing', priority: 'Medium', embedding: [0.0, 1.0, 0.0]));
        realm.add(Document('3', 'Slow loading', category: 'Performance', priority: 'Low', embedding: [0.0, 0.0, 1.0]));
        realm.add(Document('4', 'Cannot authenticate', category: 'Auth', priority: 'High', embedding: [0.9, 0.1, 0.0]));
        realm.add(Document('5', 'API timeout', category: 'Performance', priority: 'Medium', embedding: [0.1, 0.0, 0.9]));
      });

      // Query for documents similar to [1.0, 0.0, 0.0] (Auth issues)
      final results = realm.vectorSearchKnn<Document>('embedding', queryVector: [1.0, 0.0, 0.0], k: 3);

      expect(results.length, equals(3));
      expect(results[0].object.id, equals('1')); // Exact match
      expect(results[0].distance, closeTo(0.0, 0.001));
      expect(results[1].object.id, equals('4')); // Very similar
      expect(results[1].object.category, equals('Auth'));
    });

    test('KNN search with different k values', () {
      final config = Configuration.local([Document.schema]);
      final realm = getRealm(config);

      realm.write(() {
        realm.createVectorIndex<Document>('embedding');

        for (var i = 0; i < 10; i++) {
          final vec = [i.toDouble(), (10 - i).toDouble()];
          realm.add(Document('doc$i', 'Document $i', embedding: vec));
        }
      });

      final queryVector = [5.0, 5.0];

      // Test k=1
      final results1 = realm.vectorSearchKnn<Document>('embedding', queryVector: queryVector, k: 1);
      expect(results1.length, equals(1));

      // Test k=5
      final results5 = realm.vectorSearchKnn<Document>('embedding', queryVector: queryVector, k: 5);
      expect(results5.length, equals(5));

      // Results should be sorted by distance
      for (int i = 0; i < results5.length - 1; i++) {
        expect(results5[i].distance, lessThanOrEqualTo(results5[i + 1].distance));
      }
    });

    test('Radius search', () {
      final config = Configuration.local([Document.schema]);
      final realm = getRealm(config);

      realm.write(() {
        realm.createVectorIndex<Document>('embedding');

        // Create documents at different distances
        realm.add(Document('close1', 'Close 1', embedding: [0.1, 0.1]));
        realm.add(Document('close2', 'Close 2', embedding: [0.2, 0.1]));
        realm.add(Document('medium', 'Medium', embedding: [0.5, 0.5]));
        realm.add(Document('far', 'Far', embedding: [5.0, 5.0]));
      });

      // Search within radius 1.0 from origin
      final results = realm.vectorSearchRadius<Document>('embedding', queryVector: [0.0, 0.0], maxDistance: 1.0);

      expect(results.length, equals(3)); // close1, close2, medium
      expect(results.every((r) => r.distance <= 1.0), isTrue);

      // Verify far document is not included
      expect(results.any((r) => r.object.id == 'far'), isFalse);
    });
  });

  group('Vector Search - Distance Metrics', () {
    test('Euclidean distance metric', () {
      final config = Configuration.local([Document.schema]);
      final realm = getRealm(config);

      realm.write(() {
        realm.createVectorIndex<Document>('embedding', metric: VectorDistanceMetric.euclidean);

        realm.add(Document('1', 'Doc 1', embedding: [1.0, 0.0, 0.0]));
        realm.add(Document('2', 'Doc 2', embedding: [0.0, 1.0, 0.0]));
        realm.add(Document('3', 'Doc 3', embedding: [0.9, 0.1, 0.0]));
      });

      final results = realm.vectorSearchKnn<Document>('embedding', queryVector: [1.0, 0.0, 0.0], k: 2);

      // Document 3 should be closer than document 2 (Euclidean)
      expect(results[0].object.id, equals('1'));
      expect(results[1].object.id, equals('3'));
    });

    // TODO(HNSW): Known issue - cosine metric currently uses Euclidean distance
    // realm-core bug: the metric parameter is not being applied correctly
    test('Cosine distance metric', () {
      final config = Configuration.local([Document.schema]);
      final realm = getRealm(config);

      realm.write(() {
        realm.createVectorIndex<Document>('embedding', metric: VectorDistanceMetric.cosine);

        // Test vectors for cosine similarity
        realm.add(Document('1', 'Identical', embedding: [1.0, 0.0]));
        realm.add(Document('2', 'Same direction', embedding: [2.0, 0.0])); // Same direction, different magnitude
        realm.add(Document('3', 'Perpendicular', embedding: [0.0, 1.0])); // 90 degrees
        realm.add(Document('4', 'Opposite', embedding: [-1.0, 0.0])); // 180 degrees
      });

      final results = realm.vectorSearchKnn<Document>('embedding', queryVector: [1.0, 0.0], k: 4);

      // Debug output
      print('Cosine metric test results:');
      for (var r in results) {
        print('  ID=${r.object.id}, Title=${r.object.title}, Distance=${r.distance}');
      }

      // With cosine distance = 1 - cosine_similarity:
      // - [1,0] vs [1,0]: cos_sim=1 → distance=0
      // - [1,0] vs [2,0]: cos_sim=1 → distance=0
      // - [1,0] vs [0,1]: cos_sim=0 → distance=1
      // - [1,0] vs [-1,0]: cos_sim=-1 → distance=2
      expect(results[0].object.id, equals('1')); // Identical
      expect(results[0].distance, closeTo(0.0, 0.01));
      expect(results[1].object.id, equals('2')); // Same direction
      expect(results[1].distance, closeTo(0.0, 0.01));
      expect(results[2].object.id, equals('3')); // Perpendicular
      expect(results[2].distance, closeTo(1.0, 0.1));
      expect(results[3].object.id, equals('4')); // Opposite
      expect(results[3].distance, closeTo(2.0, 0.1));
    });

    test('Dot product distance metric', () {
      final config = Configuration.local([Document.schema]);
      final realm = getRealm(config);

      realm.write(() {
        realm.createVectorIndex<Document>('embedding', metric: VectorDistanceMetric.dotProduct);

        realm.add(Document('1', 'Aligned Large', embedding: [10.0, 10.0]));
        realm.add(Document('2', 'Aligned Small', embedding: [1.0, 1.0]));
        realm.add(Document('3', 'Orthogonal', embedding: [0.0, 1.0]));
      });

      final results = realm.vectorSearchKnn<Document>('embedding', queryVector: [1.0, 0.0], k: 3);

      // Dot product distance = -dot_product (negative for MIPS)
      // Query [1,0] · vectors:
      // - [10,10] = 10 → distance = -10
      // - [1,1] = 1 → distance = -1
      // - [0,1] = 0 → distance = 0
      // Results ordered by ascending distance (most negative first = largest dot product)
      expect(results[0].object.id, equals('1')); // [10,10]: largest dot product (10)
      expect(results[1].object.id, equals('2')); // [1,1]: smaller dot product (1)
      expect(results[2].object.id, equals('3')); // [0,1]: zero dot product (0)
    });
  });

  group('Vector Search - Filters', () {
    test('Manual filtering after KNN search', () {
      final config = Configuration.local([Document.schema]);
      final realm = getRealm(config);

      realm.write(() {
        realm.createVectorIndex<Document>('embedding');

        realm.add(Document('1', 'Auth Issue 1', category: 'Auth', priority: 'High', embedding: [1.0, 0.0, 0.0]));
        realm.add(Document('2', 'Billing Issue', category: 'Billing', priority: 'Medium', embedding: [0.9, 0.1, 0.0]));
        realm.add(Document('3', 'Auth Issue 2', category: 'Auth', priority: 'Low', embedding: [0.8, 0.2, 0.0]));
        realm.add(Document('4', 'Performance', category: 'Performance', priority: 'High', embedding: [0.7, 0.3, 0.0]));
        realm.add(Document('5', 'Auth Issue 3', category: 'Auth', priority: 'Medium', embedding: [0.85, 0.15, 0.0]));
      });

      // Get KNN results
      final allResults = realm.vectorSearchKnn<Document>('embedding', queryVector: [1.0, 0.0, 0.0], k: 5);

      // Filter for Auth category only
      final authResults = allResults.where((r) => r.object.category == 'Auth').toList();

      expect(authResults.length, equals(3));
      expect(authResults.every((r) => r.object.category == 'Auth'), isTrue);

      // Results should still be sorted by distance
      for (int i = 0; i < authResults.length - 1; i++) {
        expect(authResults[i].distance, lessThanOrEqualTo(authResults[i + 1].distance));
      }
    });

    test('Combined filter - category AND priority', () {
      final config = Configuration.local([Document.schema]);
      final realm = getRealm(config);

      realm.write(() {
        realm.createVectorIndex<Document>('embedding');

        realm.add(Document('1', 'Auth High 1', category: 'Auth', priority: 'High', embedding: [1.0, 0.0]));
        realm.add(Document('2', 'Auth Medium', category: 'Auth', priority: 'Medium', embedding: [0.9, 0.1]));
        realm.add(Document('3', 'Auth High 2', category: 'Auth', priority: 'High', embedding: [0.85, 0.15]));
        realm.add(Document('4', 'Billing High', category: 'Billing', priority: 'High', embedding: [0.8, 0.2]));
        realm.add(Document('5', 'Auth Low', category: 'Auth', priority: 'Low', embedding: [0.75, 0.25]));
      });

      final results = realm.vectorSearchKnn<Document>('embedding', queryVector: [1.0, 0.0], k: 10);

      // Filter for Auth + High priority
      final filtered = results.where((r) => r.object.category == 'Auth' && r.object.priority == 'High').toList();

      expect(filtered.length, equals(2));
      expect(filtered[0].object.id, equals('1'));
      expect(filtered[1].object.id, equals('3'));
    });

    test('Realm query + vector search combination', () {
      final config = Configuration.local([Document.schema]);
      final realm = getRealm(config);

      realm.write(() {
        realm.createVectorIndex<Document>('embedding');

        for (int i = 0; i < 20; i++) {
          final category = i % 2 == 0 ? 'Auth' : 'Billing';
          final vec = [1.0 - (i * 0.05), i * 0.05];
          realm.add(Document('doc$i', 'Document $i', category: category, priority: 'High', embedding: vec));
        }
      });

      // First, use Realm query to filter by category
      final authDocs = realm.all<Document>().query('category == "Auth"');

      // Then perform vector search on filtered results
      final results = realm.vectorSearchKnn<Document>('embedding', queryVector: [1.0, 0.0], k: 5);

      // Manually filter to only include Auth documents
      final authResults = results.where((r) => authDocs.contains(r.object)).toList();

      expect(authResults.every((r) => r.object.category == 'Auth'), isTrue);
    });
  });

  group('Vector Search - Index Management', () {
    test('Create and remove index', () {
      final config = Configuration.local([Document.schema]);
      final realm = getRealm(config);

      realm.write(() {
        // Create index
        realm.createVectorIndex<Document>('embedding');

        // Add some data
        realm.add(Document('1', 'Doc 1', embedding: [1.0, 0.0]));
      });

      // Verify index exists
      final hasIndex = realm.hasVectorIndex<Document>('embedding');
      expect(hasIndex, isTrue);

      // Get stats
      final stats = realm.getVectorIndexStats<Document>('embedding');
      expect(stats!.numVectors, equals(1));

      realm.write(() {
        // Remove index
        realm.removeVectorIndex<Document>('embedding');
      });

      // Verify index is removed
      final hasIndexAfter = realm.hasVectorIndex<Document>('embedding');
      expect(hasIndexAfter, isFalse);
    });

    test('Index with custom parameters', () {
      final config = Configuration.local([Document.schema]);
      final realm = getRealm(config);

      realm.write(() {
        realm.createVectorIndex<Document>('embedding', metric: VectorDistanceMetric.cosine, m: 32, efConstruction: 400);

        // Add multiple documents
        for (int i = 0; i < 100; i++) {
          final angle = i * 2 * pi / 100;
          final vec = [cos(angle), sin(angle)];
          realm.add(Document('doc$i', 'Document $i', embedding: vec));
        }
      });

      final stats = realm.getVectorIndexStats<Document>('embedding');
      expect(stats!.numVectors, equals(100));
      expect(stats!.maxLayer, greaterThan(0));
    });
  });

  group('Vector Search - Edge Cases', () {
    test('Empty index', () {
      final config = Configuration.local([Document.schema]);
      final realm = getRealm(config);

      realm.write(() {
        realm.createVectorIndex<Document>('embedding');
      });

      final results = realm.vectorSearchKnn<Document>('embedding', queryVector: [1.0, 0.0], k: 5);

      expect(results.isEmpty, isTrue);
    });

    test('K greater than number of documents', () {
      final config = Configuration.local([Document.schema]);
      final realm = getRealm(config);

      realm.write(() {
        realm.createVectorIndex<Document>('embedding');
        realm.add(Document('1', 'Doc 1', embedding: [1.0, 0.0]));
        realm.add(Document('2', 'Doc 2', embedding: [0.0, 1.0]));
      });

      final results = realm.vectorSearchKnn<Document>('embedding', queryVector: [1.0, 1.0], k: 10);

      expect(results.length, equals(2)); // Only returns available documents
    });

    test('Zero radius search', () {
      final config = Configuration.local([Document.schema]);
      final realm = getRealm(config);

      realm.write(() {
        realm.createVectorIndex<Document>('embedding');
        realm.add(Document('1', 'Exact match', embedding: [1.0, 1.0]));
        realm.add(Document('2', 'Close', embedding: [1.01, 1.0]));
      });

      final results = realm.vectorSearchRadius<Document>('embedding', queryVector: [1.0, 1.0], maxDistance: 0.0);

      // Should only return exact match
      expect(results.length, equals(1));
      expect(results[0].object.id, equals('1'));
      expect(results[0].distance, closeTo(0.0, 0.001));
    });

    test('High dimensional vectors', () {
      final config = Configuration.local([Document.schema]);
      final realm = getRealm(config);

      realm.write(() {
        realm.createVectorIndex<Document>('embedding');

        // Create 768-dimensional vectors (typical for embeddings)
        final vec1 = List.generate(768, (i) => i.toDouble() / 768);
        final vec2 = List.generate(768, (i) => (768 - i).toDouble() / 768);

        realm.add(Document('1', 'High dim 1', embedding: vec1));
        realm.add(Document('2', 'High dim 2', embedding: vec2));
      });

      final queryVector = List.generate(768, (i) => 0.5);
      final results = realm.vectorSearchKnn<Document>('embedding', queryVector: queryVector, k: 2);

      expect(results.length, equals(2));
      expect(results[0].distance, isPositive);
    });
  });

  group('Vector Search - Real-world Scenarios', () {
    test('Semantic search with embeddings', () {
      final config = Configuration.local([Document.schema]);
      final realm = getRealm(config);

      // Simulated embeddings for different topics
      final authEmbedding = [0.9, 0.1, 0.0, 0.0];
      final billingEmbedding = [0.1, 0.9, 0.0, 0.0];
      final performanceEmbedding = [0.0, 0.1, 0.9, 0.1];

      realm.write(() {
        realm.createVectorIndex<Document>('embedding', metric: VectorDistanceMetric.cosine);

        realm.add(Document('1', 'Cannot login to account', category: 'Auth', priority: 'High', embedding: authEmbedding));
        realm.add(Document('2', 'Password reset not working', category: 'Auth', priority: 'Medium', embedding: [0.85, 0.15, 0.0, 0.0]));
        realm.add(Document('3', 'Charge appeared twice', category: 'Billing', priority: 'High', embedding: billingEmbedding));
        realm.add(Document('4', 'Refund request', category: 'Billing', priority: 'Low', embedding: [0.15, 0.85, 0.0, 0.0]));
        realm.add(Document('5', 'Page loads slowly', category: 'Performance', priority: 'Medium', embedding: performanceEmbedding));
        realm.add(Document('6', 'API timeout error', category: 'Performance', priority: 'High', embedding: [0.0, 0.0, 0.85, 0.15]));
      });

      // Search for authentication-related issues
      final authQuery = [0.9, 0.1, 0.0, 0.0];
      final authResults = realm.vectorSearchKnn<Document>('embedding', queryVector: authQuery, k: 3);

      expect(authResults[0].object.category, equals('Auth'));
      expect(authResults[1].object.category, equals('Auth'));

      // Search for billing issues
      final billingQuery = [0.1, 0.9, 0.0, 0.0];
      final billingResults = realm.vectorSearchKnn<Document>('embedding', queryVector: billingQuery, k: 2);

      expect(billingResults[0].object.category, equals('Billing'));
      expect(billingResults[1].object.category, equals('Billing'));
    });

    test('Incremental index updates', () {
      final config = Configuration.local([Document.schema]);
      final realm = getRealm(config);

      realm.write(() {
        realm.createVectorIndex<Document>('embedding');
        realm.add(Document('1', 'Initial doc', embedding: [1.0, 0.0]));
      });

      var stats = realm.getVectorIndexStats<Document>('embedding');
      expect(stats!.numVectors, equals(1));

      // Add more documents
      realm.write(() {
        for (int i = 2; i <= 10; i++) {
          realm.add(Document('$i', 'Doc $i', embedding: [i.toDouble(), 0.0]));
        }
      });

      stats = realm.getVectorIndexStats<Document>('embedding');
      expect(stats!.numVectors, equals(10));

      // Delete some documents
      realm.write(() {
        final doc = realm.find<Document>('5');
        realm.delete(doc!);
      });

      stats = realm.getVectorIndexStats<Document>('embedding');
      expect(stats!.numVectors, equals(9));
    });
  });
}
