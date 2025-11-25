// Copyright 2025 MongoDB, Inc.
// SPDX-License-Identifier: Apache-2.0

import 'package:realm_dart/realm.dart';
import 'test.dart';

part 'vector_search_test.realm.dart';

void main() {
  setupTests();

  test('Debug cosine distances', () {
    final config = Configuration.local([Document.schema]);
    final realm = getRealm(config);

    realm.write(() {
      realm.createVectorIndex<Document>('embedding', metric: VectorDistanceMetric.cosine);

      // Same direction, different magnitudes
      realm.add(Document('1', 'Short', embedding: [1.0, 1.0]));
      realm.add(Document('2', 'Long', embedding: [10.0, 10.0]));
      // Different direction
      realm.add(Document('3', 'Different', embedding: [1.0, -1.0]));
    });

    final results = realm.vectorSearchKnn<Document>('embedding', queryVector: [1.0, 1.0], k: 3);

    print('Cosine distance results:');
    for (var i = 0; i < results.length; i++) {
      print('  ${i + 1}. ${results[i].object.title}: distance=${results[i].distance}');
    }

    realm.close();
    Realm.deleteRealm(config.path);
  });
}
