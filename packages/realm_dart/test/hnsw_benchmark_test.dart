// Copyright 2024 MongoDB, Inc.
// SPDX-License-Identifier: Apache-2.0

import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:realm_dart_vector_db/realm.dart';

part 'hnsw_benchmark_test.realm.dart';

@RealmModel()
class _Query {
  @PrimaryKey()
  late String id;
  late String text;
  late int trecYear;
  late List<double> embedding; // 1024-dimensional embedding
}

void main() {
  group('HNSW Performance Benchmark -', () {
    late Realm realm;
    late List<Map<String, dynamic>> dataset;

    setUpAll(() async {
      print('\n🔧 Loading dataset from output.json...');
      final file = File('test/data/output.json');
      if (!file.existsSync()) {
        throw Exception('Dataset file not found: ${file.path}. Please ensure output.json is in test/data/ directory');
      }

      final jsonString = await file.readAsString();
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;

      // Properly convert each row and its embedding
      dataset = [];
      for (final item in (jsonData['rows'] as List)) {
        final rowData = item['row'] as Map<String, dynamic>;
        final row = Map<String, dynamic>.from(rowData);

        // Convert embedding - it might be a List or a JSON string
        if (row['emb'] is String) {
          // Parse the string as JSON list
          final embString = row['emb'] as String;
          final embList = json.decode(embString) as List;
          row['emb'] = embList.map((e) => (e as num).toDouble()).toList();
        } else if (row['emb'] is List) {
          row['emb'] = (row['emb'] as List).map((e) => (e as num).toDouble()).toList();
        }

        dataset.add(row);
      }

      print('✅ Loaded ${dataset.length} queries with ${(dataset[0]['emb'] as List).length}D embeddings');
    });

    setUp(() {
      final config = Configuration.local(
        [Query.schema],
        path: 'benchmark_${DateTime.now().millisecondsSinceEpoch}.realm',
      );
      realm = Realm(config);
    });

    tearDown(() {
      final path = realm.config.path;
      realm.close();
      try {
        Realm.deleteRealm(path);
      } catch (e) {
        print('⚠️ Could not delete realm file: $e');
      }
    });

    test('BENCHMARK 1: Bulk Insert Performance', () {
      print('\n📊 BENCHMARK 1: Bulk Insert Performance');
      print('=' * 60);

      final stopwatch = Stopwatch()..start();

      realm.write(() {
        for (final row in dataset) {
          final query = Query(
            row['_id'] as String,
            row['text'] as String,
            row['trec-year'] as int,
            embedding: (row['emb'] as List<dynamic>).map((e) => (e as num).toDouble()).toList(),
          );
          realm.add(query);
        }
      });

      stopwatch.stop();
      final insertTime = stopwatch.elapsedMilliseconds;

      print('📝 Records inserted: ${dataset.length}');
      print('⏱️  Total time: ${insertTime}ms');
      print('📈 Average per record: ${(insertTime / dataset.length).toStringAsFixed(2)}ms');
      print('💾 Database size: ${File(realm.config.path).lengthSync() / 1024} KB');

      expect(realm.all<Query>().length, dataset.length);
    });

    test('BENCHMARK 2: Vector Index Creation Performance', () {
      print('\n📊 BENCHMARK 2: Vector Index Creation Performance');
      print('=' * 60);

      // First, insert data
      realm.write(() {
        for (final row in dataset) {
          realm.add(Query(
            row['_id'] as String,
            row['text'] as String,
            row['trec-year'] as int,
            embedding: (row['emb'] as List<dynamic>).map((e) => (e as num).toDouble()).toList(),
          ));
        }
      });

      print('📝 Inserted ${dataset.length} records');

      // Benchmark index creation
      final stopwatch = Stopwatch()..start();

      realm.write(() {
        realm.createVectorIndex<Query>(
          'embedding',
          metric: VectorDistanceMetric.cosine,
          m: 16,
          efConstruction: 200,
        );
      });

      stopwatch.stop();
      final indexTime = stopwatch.elapsedMilliseconds;

      print('🔍 Index created on 1024D vectors');
      print('⏱️  Index creation time: ${indexTime}ms');
      print('📊 Parameters: m=16, efConstruction=200');
      print('💾 Database size after index: ${File(realm.config.path).lengthSync() / 1024} KB');
    });

    test('BENCHMARK 3: KNN Search Performance (Cold Start)', () {
      print('\n📊 BENCHMARK 3: KNN Search Performance (Cold Start)');
      print('=' * 60);

      // Setup: Insert data and create index
      realm.write(() {
        for (final row in dataset) {
          realm.add(Query(
            row['_id'] as String,
            row['text'] as String,
            row['trec-year'] as int,
            embedding: (row['emb'] as List<dynamic>).map((e) => (e as num).toDouble()).toList(),
          ));
        }
        realm.createVectorIndex<Query>(
          'embedding',
          metric: VectorDistanceMetric.cosine,
          m: 16,
          efConstruction: 200,
        );
      });

      // Use first query as search vector
      final queryVector = (dataset[0]['emb'] as List<dynamic>).map((e) => (e as num).toDouble()).toList();

      // Cold start search
      final stopwatch = Stopwatch()..start();
      final results = realm.vectorSearchKnn<Query>(
        'embedding',
        queryVector: queryVector,
        k: 5,
      );
      final resultsList = results;
      stopwatch.stop();

      print('🔍 Query vector dimension: ${queryVector.length}D');
      print('📝 Results returned: ${resultsList.length}');
      print('⏱️  Cold start search time: ${stopwatch.elapsedMicroseconds}μs');
      print('🎯 Top result: "${resultsList.first.object.text}"');

      expect(resultsList.length, greaterThan(0));
      expect(resultsList.length, lessThanOrEqualTo(5));
    });

    test('BENCHMARK 4: KNN Search Performance (Warm Cache)', () {
      print('\n📊 BENCHMARK 4: KNN Search Performance (Warm Cache)');
      print('=' * 60);

      // Setup
      realm.write(() {
        for (final row in dataset) {
          realm.add(Query(
            row['_id'] as String,
            row['text'] as String,
            row['trec-year'] as int,
            embedding: (row['emb'] as List<dynamic>).map((e) => (e as num).toDouble()).toList(),
          ));
        }
        realm.createVectorIndex<Query>(
          'embedding',
          metric: VectorDistanceMetric.cosine,
          m: 16,
          efConstruction: 200,
        );
      });

      final queryVector = (dataset[0]['emb'] as List<dynamic>).map((e) => (e as num).toDouble()).toList();

      // Warm up cache
      realm.vectorSearchKnn<Query>('embedding', queryVector: queryVector, k: 5);

      // Benchmark warm searches
      final times = <int>[];
      const iterations = 10;

      for (int i = 0; i < iterations; i++) {
        final stopwatch = Stopwatch()..start();
        final results = realm.vectorSearchKnn<Query>(
          'embedding',
          queryVector: queryVector,
          k: 5,
        );
        stopwatch.stop();
        times.add(stopwatch.elapsedMicroseconds);

        if (i == 0) {
          print('🎯 Sample result: "${results.first.object.text}"');
        }
      }

      final avgTime = times.reduce((a, b) => a + b) / times.length;
      final minTime = times.reduce((a, b) => a < b ? a : b);
      final maxTime = times.reduce((a, b) => a > b ? a : b);

      print('🔄 Iterations: $iterations');
      print('⏱️  Average search time: ${avgTime.toStringAsFixed(2)}μs');
      print('⚡ Min search time: ${minTime}μs');
      print('🐢 Max search time: ${maxTime}μs');
      print('📊 Throughput: ${(1000000 / avgTime).toStringAsFixed(0)} searches/sec');
    });

    test('BENCHMARK 5: Radius Search Performance', () {
      print('\n📊 BENCHMARK 5: Radius Search Performance');
      print('=' * 60);

      // Setup
      realm.write(() {
        for (final row in dataset) {
          realm.add(Query(
            row['_id'] as String,
            row['text'] as String,
            row['trec-year'] as int,
            embedding: (row['emb'] as List<dynamic>).map((e) => (e as num).toDouble()).toList(),
          ));
        }
        realm.createVectorIndex<Query>(
          'embedding',
          metric: VectorDistanceMetric.cosine,
          m: 16,
          efConstruction: 200,
        );
      });

      final queryVector = (dataset[0]['emb'] as List<dynamic>).map((e) => (e as num).toDouble()).toList();
      final radiusThresholds = [0.1, 0.3, 0.5, 0.7, 0.9];

      for (final radius in radiusThresholds) {
        final stopwatch = Stopwatch()..start();
        final results = realm.vectorSearchRadius<Query>(
          'embedding',
          queryVector: queryVector,
          maxDistance: radius,
        );
        stopwatch.stop();

        print('🎯 Max distance: $radius => ${results.length} results in ${stopwatch.elapsedMicroseconds}μs');
      }
    });

    test('BENCHMARK 6: Filtered Vector Search Performance', () {
      print('\n📊 BENCHMARK 6: Filtered Vector Search Performance');
      print('=' * 60);

      // Setup
      realm.write(() {
        for (final row in dataset) {
          realm.add(Query(
            row['_id'] as String,
            row['text'] as String,
            row['trec-year'] as int,
            embedding: (row['emb'] as List<dynamic>).map((e) => (e as num).toDouble()).toList(),
          ));
        }
        realm.createVectorIndex<Query>(
          'embedding',
          metric: VectorDistanceMetric.cosine,
          m: 16,
          efConstruction: 200,
        );
      });

      final queryVector = (dataset[0]['emb'] as List<dynamic>).map((e) => (e as num).toDouble()).toList();

      // Test 1: No filter
      var stopwatch = Stopwatch()..start();
      var results = realm.vectorSearchKnn<Query>(
        'embedding',
        queryVector: queryVector,
        k: 5,
      );
      stopwatch.stop();
      print('⚡ No filter: ${results.length} results in ${stopwatch.elapsedMicroseconds}μs');

      // Test 2: With year filter
      stopwatch = Stopwatch()..start();
      final allResults2 = realm.vectorSearchKnn<Query>(
        'embedding',
        queryVector: queryVector,
        k: 10,
      );
      results = allResults2.where((r) => r.object.trecYear >= 2020).take(5).toList();
      stopwatch.stop();
      print('🔍 With filter (trecYear >= 2020): ${results.length} results in ${stopwatch.elapsedMicroseconds}μs');

      // Test 3: Text contains filter
      stopwatch = Stopwatch()..start();
      final allResults3 = realm.vectorSearchKnn<Query>(
        'embedding',
        queryVector: queryVector,
        k: 10,
      );
      results = allResults3.where((r) => r.object.text.toLowerCase().contains('what')).take(5).toList();
      stopwatch.stop();
      print('📝 With filter (text contains "what"): ${results.length} results in ${stopwatch.elapsedMicroseconds}μs');
    });

    test('BENCHMARK 7: Different Distance Metrics Comparison', () {
      print('\n📊 BENCHMARK 7: Different Distance Metrics Comparison');
      print('=' * 60);

      final queryVector = (dataset[0]['emb'] as List<dynamic>).map((e) => (e as num).toDouble()).toList();
      final metrics = [
        VectorDistanceMetric.cosine,
        VectorDistanceMetric.euclidean,
        VectorDistanceMetric.dotProduct,
      ];

      for (final metric in metrics) {
        // Create fresh realm for each metric
        final testPath = 'benchmark_metric_${metric.name}_${DateTime.now().millisecondsSinceEpoch}.realm';
        final testConfig = Configuration.local([Query.schema], path: testPath);
        final testRealm = Realm(testConfig);

        // Insert and index
        final setupWatch = Stopwatch()..start();
        testRealm.write(() {
          for (final row in dataset) {
            testRealm.add(Query(
              row['_id'] as String,
              row['text'] as String,
              row['trec-year'] as int,
              embedding: (row['emb'] as List<dynamic>).map((e) => (e as num).toDouble()).toList(),
            ));
          }
          testRealm.createVectorIndex<Query>(
            'embedding',
            metric: metric,
            m: 16,
            efConstruction: 200,
          );
        });
        setupWatch.stop();

        // Benchmark search
        final searchWatch = Stopwatch()..start();
        final results = testRealm.vectorSearchKnn<Query>(
          'embedding',
          queryVector: queryVector,
          k: 5,
        );
        searchWatch.stop();

        print('📐 ${metric.name.toUpperCase()}:');
        print('   Index creation: ${setupWatch.elapsedMilliseconds}ms');
        print('   Search time: ${searchWatch.elapsedMicroseconds}μs');
        print('   Results: ${results.length}');

        testRealm.close();
        try {
          Realm.deleteRealm(testPath);
        } catch (e) {
          // Ignore cleanup errors
        }
      }
    });

    test('BENCHMARK 8: Index Parameters Tuning (m and efConstruction)', () {
      print('\n📊 BENCHMARK 8: Index Parameters Tuning');
      print('=' * 60);

      final queryVector = (dataset[0]['emb'] as List<dynamic>).map((e) => (e as num).toDouble()).toList();
      final parameterSets = [
        {'m': 8, 'efConstruction': 100},
        {'m': 16, 'efConstruction': 200},
        {'m': 32, 'efConstruction': 400},
      ];

      for (final params in parameterSets) {
        final testPath = 'benchmark_params_m${params['m']}_ef${params['efConstruction']}_${DateTime.now().millisecondsSinceEpoch}.realm';
        final testConfig = Configuration.local([Query.schema], path: testPath);
        final testRealm = Realm(testConfig);

        // Insert data
        testRealm.write(() {
          for (final row in dataset) {
            testRealm.add(Query(
              row['_id'] as String,
              row['text'] as String,
              row['trec-year'] as int,
              embedding: (row['emb'] as List<dynamic>).map((e) => (e as num).toDouble()).toList(),
            ));
          }
        });

        // Benchmark index creation
        final indexWatch = Stopwatch()..start();
        testRealm.write(() {
          testRealm.createVectorIndex<Query>(
            'embedding',
            metric: VectorDistanceMetric.cosine,
            m: params['m'] as int,
            efConstruction: params['efConstruction'] as int,
          );
        });
        indexWatch.stop();

        // Benchmark search (average of 5 runs)
        final searchTimes = <int>[];
        for (int i = 0; i < 5; i++) {
          final searchWatch = Stopwatch()..start();
          testRealm.vectorSearchKnn<Query>(
            'embedding',
            queryVector: queryVector,
            k: 5,
          );
          searchWatch.stop();
          searchTimes.add(searchWatch.elapsedMicroseconds);
        }
        final avgSearchTime = searchTimes.reduce((a, b) => a + b) / searchTimes.length;

        final dbSize = File(testPath).lengthSync() / 1024;

        print('⚙️  m=${params['m']}, efConstruction=${params['efConstruction']}:');
        print('   Index creation: ${indexWatch.elapsedMilliseconds}ms');
        print('   Avg search time: ${avgSearchTime.toStringAsFixed(2)}μs');
        print('   DB size: ${dbSize.toStringAsFixed(2)} KB');

        testRealm.close();
        try {
          Realm.deleteRealm(testPath);
        } catch (e) {
          // Ignore cleanup errors
        }
      }
    });

    test('BENCHMARK 9: Concurrent Read Performance', () {
      print('\n📊 BENCHMARK 9: Concurrent Read Performance');
      print('=' * 60);

      // Setup
      realm.write(() {
        for (final row in dataset) {
          realm.add(Query(
            row['_id'] as String,
            row['text'] as String,
            row['trec-year'] as int,
            embedding: (row['emb'] as List<dynamic>).map((e) => (e as num).toDouble()).toList(),
          ));
        }
        realm.createVectorIndex<Query>(
          'embedding',
          metric: VectorDistanceMetric.cosine,
          m: 16,
          efConstruction: 200,
        );
      });

      final queryVector = (dataset[0]['emb'] as List<dynamic>).map((e) => (e as num).toDouble()).toList();

      // Sequential reads
      final seqWatch = Stopwatch()..start();
      for (int i = 0; i < 10; i++) {
        realm.vectorSearchKnn<Query>(
          'embedding',
          queryVector: queryVector,
          k: 5,
        );
      }
      seqWatch.stop();

      print('🔄 Sequential 10 searches: ${seqWatch.elapsedMilliseconds}ms');
      print('📊 Average per search: ${seqWatch.elapsedMilliseconds / 10}ms');

      // Note: True concurrent access would require multiple isolates
      // This test shows sequential performance baseline
    });

    test('BENCHMARK 10: Memory Usage and Database Size', () {
      print('\n📊 BENCHMARK 10: Memory Usage and Database Size');
      print('=' * 60);

      final initialSize = File(realm.config.path).lengthSync();
      print('💾 Initial DB size: ${initialSize / 1024} KB');

      // Insert data
      realm.write(() {
        for (final row in dataset) {
          realm.add(Query(
            row['_id'] as String,
            row['text'] as String,
            row['trec-year'] as int,
            embedding: (row['emb'] as List<dynamic>).map((e) => (e as num).toDouble()).toList(),
          ));
        }
      });

      final sizeAfterInsert = File(realm.config.path).lengthSync();
      print('💾 After insert: ${sizeAfterInsert / 1024} KB (+${(sizeAfterInsert - initialSize) / 1024} KB)');

      // Create index
      realm.write(() {
        realm.createVectorIndex<Query>(
          'embedding',
          metric: VectorDistanceMetric.cosine,
          m: 16,
          efConstruction: 200,
        );
      });

      final sizeAfterIndex = File(realm.config.path).lengthSync();
      print('💾 After index: ${sizeAfterIndex / 1024} KB (+${(sizeAfterIndex - sizeAfterInsert) / 1024} KB)');

      final recordCount = realm.all<Query>().length;
      print('📊 Records: $recordCount');
      print('📏 Avg size per record: ${(sizeAfterInsert - initialSize) / recordCount} bytes');
      print('📐 Index overhead: ${((sizeAfterIndex - sizeAfterInsert) / (sizeAfterInsert - initialSize) * 100).toStringAsFixed(2)}%');
    });
  });
}
