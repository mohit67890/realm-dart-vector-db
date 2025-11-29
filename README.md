> [!NOTE]
> **🚀 Atlas Device Sync Replacement Available!**
> 
> MongoDB deprecated Atlas Device Sync in September 2024, but we've got you covered! 
> 
> Introducing **[Flutter Realm Sync](https://pub.dev/packages/flutter_realm_sync)** - the open-source, production-ready successor that provides:
> - ✅ **Real-time bidirectional sync** with MongoDB Atlas
> - ✅ **Offline-first architecture** with automatic conflict resolution
> - ✅ **Self-hosted control** - no vendor lock-in
> - ✅ **Production-ready server** included (Node.js + TypeScript)
> - ✅ **Battle-tested** with 1000s of documents in real apps
> 
> 👉 **[Get Started with Flutter Realm Sync →](https://pub.dev/packages/flutter_realm_sync)**  
> 📦 **[GitHub Repository →](https://github.com/mohit67890/flutter_realm_sync)**

<picture>
    <source srcset="./media/logo-dark.svg" media="(prefers-color-scheme: dark)" alt="realm by MongoDB">
    <img src="./media/logo.svg" alt="realm by MongoDB">
</picture>

[![License](https://img.shields.io/badge/License-Apache-blue.svg)](LICENSE)
[![Realm Dart CI](https://github.com/realm/realm-dart/actions/workflows/ci.yml/badge.svg)](https://github.com/realm/realm-dart/actions/workflows/ci.yml)
[![Coverage Status](https://coveralls.io/repos/github/realm/realm-dart/badge.svg?branch=main)](https://coveralls.io/github/realm/realm-dart?branch=main)

Realm is a mobile database that runs directly inside phones, tablets or wearables.
This repository holds the source code for the Realm SDK for Flutter™ and Dart™.

## Features

- **Mobile-first:** Realm is the first database built from the ground up to run directly inside phones, tablets, and wearables.
- **Simple:** Realm's object-oriented data model is simple to learn, doesn't need an ORM, and the [API](https://pub.dev/documentation/realm/latest/) lets you write less code to get apps up & running in minutes.
- **Modern:** Realm supports latest Dart and Flutter versions and is built with sound null-safety.
- **Fast:** Realm is faster than even raw SQLite on common operations while maintaining an extremely rich feature set.
- **Vector Search (HNSW):** Built-in support for high-performance vector similarity search using Hierarchical Navigable Small World (HNSW) algorithm. Perfect for AI/ML applications, semantic search, recommendation systems, and RAG (Retrieval-Augmented Generation) patterns.
- **🚀 [Flutter Realm Sync](https://pub.dev/packages/flutter_realm_sync)**: Open-source, production-ready replacement for deprecated Atlas Device Sync. Real-time bidirectional sync with MongoDB Atlas, offline-first architecture, automatic conflict resolution, and self-hosted control. Includes a complete Node.js server and is battle-tested in production apps. **[Get Started →](https://pub.dev/packages/flutter_realm_sync)**

## Getting Started

- Import Realm in a dart file `app.dart`

  ```dart
  import 'package:realm/realm.dart';  // import realm package

  part 'app.realm.dart'; // declare a part file.

  @RealmModel() // define a data model class named `_Car`.
  class _Car {
    late String make;

    late String model;

    int? kilometers = 500;
  }
  ```

- Generate RealmObject class `Car` from data model class `_Car`.

  ```
  dart run realm_flutter_vector_db generate
  ```

- Open a Realm and add some objects.

  ```dart
  var config = Configuration.local([Car.schema]);
  var realm = Realm(config);

  var car = Car("Tesla", "Model Y", kilometers: 5);
  realm.write(() {
    realm.add(car);
  });
  ```

- Query objects in Realm.

  ```dart
  var cars = realm.all<Car>();
  Car myCar = cars[0];
  print("My car is ${myCar.make} model ${myCar.model}");

  cars = realm.all<Car>().query("make == 'Tesla'");
  ```

- Get stream of result changes for a query.

  ```dart
  final cars = realm.all<Car>().query(r'make == $0', ['Tesla']);
  cars.changes.listen((changes) {
    print('Inserted indexes: ${changes.inserted}');
    print('Deleted indexes: ${changes.deleted}');
    print('Modified indexes: ${changes.modified}');
  });
  realm.write(() => realm.add(Car('VW', 'Polo', kilometers: 22000)));
  ```

## Vector Search with HNSW

Realm now supports high-performance vector similarity search using the Hierarchical Navigable Small World (HNSW) algorithm. This enables AI/ML applications including semantic search, recommendation systems, image similarity, and RAG (Retrieval-Augmented Generation) patterns.

### Quick Start with Vector Search

- Define a model with vector embeddings:

  ```dart
  import 'package:realm/realm.dart';

  part 'app.realm.dart';

  @RealmModel()
  class _Document {
    @PrimaryKey()
    late String id;

    late String title;
    late String content;
    late List<double> embedding;  // Vector embeddings
  }
  ```

- Generate the RealmObject class:

  ```
  dart run realm_flutter_vector_db generate
  ```

- Create a vector index and perform similarity search:

  ```dart
  var config = Configuration.local([Document.schema]);
  var realm = Realm(config);

  // Create HNSW vector index
  realm.write(() {
    realm.createVectorIndex<Document>(
      'embedding',
      metric: VectorDistanceMetric.cosine,  // or euclidean, dotProduct
      m: 16,                                // connections per layer (default: 16)
      efConstruction: 200,                  // build quality (default: 200)
    );
  });

  // Add documents with embeddings
  realm.write(() {
    realm.add(Document(
      '1',
      'AI Technology',
      'Machine learning and neural networks',
      embedding: [0.95, 0.85, 0.05, 0.10, 0.02, 0.08],
    ));
    realm.add(Document(
      '2',
      'Nature Guide',
      'Forest ecosystems and wildlife',
      embedding: [0.08, 0.12, 0.95, 0.88, 0.02, 0.05],
    ));
  });

  // K-Nearest Neighbors (KNN) search
  final queryVector = [0.9, 0.8, 0.1, 0.1, 0.05, 0.05];
  final results = realm.vectorSearchKnn<Document>(
    'embedding',
    queryVector: queryVector,
    k: 5,  // Return top 5 similar documents
  );

  for (var result in results) {
    print('${result.object.title}: distance=${result.distance}');
  }

  // Radius search (all documents within distance threshold)
  final radiusResults = realm.vectorSearchRadius<Document>(
    'embedding',
    queryVector: queryVector,
    maxDistance: 0.5,
  );
  ```

### Vector Search Features

- **Distance Metrics**:

  - `VectorDistanceMetric.cosine` - Cosine similarity (recommended for normalized vectors)
  - `VectorDistanceMetric.euclidean` - Euclidean distance
  - `VectorDistanceMetric.dotProduct` - Dot product similarity

- **Search Types**:

  - **KNN Search**: Find K nearest neighbors (`vectorSearchKnn`)
  - **Radius Search**: Find all vectors within distance threshold (`vectorSearchRadius`)

- **Index Management**:

  - `createVectorIndex()` - Create HNSW index on vector property
  - `removeVectorIndex()` - Remove index (preserves data)
  - `hasVectorIndex()` - Check if index exists
  - `getVectorIndexStats()` - Get index statistics (numVectors, maxLayer)

- **Tuning Parameters**:
  - `m` (default: 16) - Number of bi-directional links per node. Higher values = better recall, more memory
  - `efConstruction` (default: 200) - Build-time quality parameter. Higher values = better index quality, slower indexing

### Production Migration Pattern

When changing vector dimensions (e.g., 4D → 6D), use this safe migration pattern:

```dart
realm.write(() {
  // 1. Remove existing index (data is preserved!)
  if (realm.hasVectorIndex<Document>('embedding')) {
    realm.removeVectorIndex<Document>('embedding');
  }

  // 2. Transform embeddings
  for (final doc in realm.all<Document>()) {
    final oldValues = List<double>.from(doc.embedding);  // Create defensive copy
    final newValues = [...oldValues, 0.0, 0.0];          // Add new dimensions
    doc.embedding.clear();
    doc.embedding.addAll(newValues);
  }

  // 3. Create new index with updated dimensions
  realm.createVectorIndex<Document>(
    'embedding',
    metric: VectorDistanceMetric.cosine,
    m: 16,
    efConstruction: 200,
  );
});
```

**Key points:**

- `removeVectorIndex()` does NOT delete your data
- Always create a defensive copy with `List<double>.from()` before modifying
- This pattern avoids data loss unlike `shouldDeleteIfMigrationNeeded: true`

### Performance Benchmarks

Benchmark results with 100 queries (1024-dimensional embeddings):

| Metric                      | Performance                      |
| --------------------------- | -------------------------------- |
| **Bulk Insert**             | 0.90ms per record                |
| **Index Creation**          | 125ms (m=16, efConstruction=200) |
| **KNN Search (Cold Start)** | 2,016μs                          |
| **KNN Search (Warm)**       | ~102μs (**9,766 searches/sec**)  |
| **Radius Search**           | 104-959μs                        |
| **Filtered Search**         | 162-629μs                        |
| **Memory Overhead**         | ~100% (index size ≈ data size)   |

**Distance Metrics Comparison** (all perform similarly):

- Cosine: 190ms index creation, 155μs search
- Euclidean: 183ms index creation, 152μs search
- Dot Product: 178ms index creation, 157μs search

**Parameter Tuning Impact**:

- m=8, efConstruction=100: 118μs search
- m=16, efConstruction=200: 112μs search
- m=32, efConstruction=400: 104μs search (fastest)

_Higher HNSW parameters yield better search performance at the cost of slightly larger index size and longer index creation time._

### Use Cases

- **Semantic Search**: Find documents by meaning, not just keywords
- **Recommendation Systems**: Suggest similar items based on embeddings
- **Image Similarity**: Find visually similar images using vision model embeddings
- **RAG Applications**: Retrieve relevant context for AI chatbots and assistants
- **Duplicate Detection**: Find near-duplicate content
- **Clustering & Classification**: Group similar items together

For a complete example with 26 comprehensive tests, see [example/lib/main.dart](./example/lib/main.dart). Performance benchmarks are available in the test suite.

## Samples

For complete samples check the [Realm Flutter and Dart Samples](https://github.com/realm/realm-dart-samples).

## Documentation

For API documentation go to

- [Realm Flutter API Docs](https://pub.dev/documentation/realm/latest/)

- [Realm Dart API Docs](https://pub.dev/documentation/realm_dart/latest/)

Use [realm](https://pub.dev/packages/realm) package for Flutter and [realm_dart](https://pub.dev/packages/realm_dart) package for Dart applications.

For complete documentation of the SDKs, go to the [Realm SDK documentation](https://www.mongodb.com/docs/atlas/device-sdks/sdk/flutter/).

If you are using the Realm SDK for the first time, refer to the [Quick Start documentation](https://www.mongodb.com/docs/realm/sdk/flutter/quick-start/).

To learn more about using Realm with Atlas App Services and Device Sync, refer to the following Realm SDK documentation:

- [App Services Overview](https://www.mongodb.com/docs/realm/sdk/flutter/app-services/)
- [Device Sync Overview](https://www.mongodb.com/docs/realm/sdk/flutter/sync/)

# Realm Flutter SDK

Realm Flutter package is published to [realm](https://pub.dev/packages/realm).

## Environment setup for Realm Flutter

- Realm Flutter supports the platforms iOS, Android, Windows, MacOS and Linux.
- Flutter 3.10.2 or newer.
- For Flutter Desktop environment setup, see [Desktop support for Flutter](https://docs.flutter.dev/desktop).
- Cocoapods v1.11 or newer.
- CMake 3.21 or newer.

## Usage

**The full contents of `catalog.dart` is listed [after the usage](https://github.com/realm/realm-dart#full-contents-of-catalogdart)**

- Add `realm` package to a Flutter application.

  ```
  flutter pub add realm_flutter_vector_db
  ```

- For running Flutter widget and unit tests run the following command to install the required native binaries.

  ```
  dart run realm_flutter_vector_db install
  ```

- Import Realm in a dart file (ex. `catalog.dart`).

  ```dart
  import 'package:realm/realm.dart';
  ```

- Declare a part file `catalog.realm.dart` in the begining of the `catalog.dart` dart file after all imports.

  ```dart
  import 'dart:io';

  part 'catalog.realm.dart';
  ```

- Create a data model class.

  It should start with an underscore `_Item` and be annotated with `@RealmModel()`

  ```dart
  @RealmModel()
  class _Item {
      @PrimaryKey()
      late int id;

      late String name;

      int price = 42;
  }
  ```

- Generate RealmObject class `Item` from data model class `_Item`.

  _*On Flutter use `dart run realm_flutter_vector_db` to run `realm_flutter_vector_db` package commands*_

  ```
  dart run realm_flutter_vector_db generate
  ```

  A new file `catalog.realm.dart` will be created next to the `catalog.dart`.

  _\*The generated file should be committed to source control_

- Use the RealmObject class `Item` with Realm.

  ```dart
  // Create a Configuration object
  var config = Configuration.local([Item.schema]);

  // Opean a Realm
  var realm = Realm(config);

  var myItem = Item(0, 'Pen', price: 4);

  // Open a write transaction
  realm.write(() {
      realm.add(myItem);
      var item = realm.add(Item(1, 'Pencil')..price = 20);
  });

  // Objects `myItem` and `item` are now managed and persisted in the realm

  // Read object properties from realm
  print(myItem.name);
  print(myItem.price);

  // Update object properties
  realm.write(() {
      myItem.price = 20;
      myItem.name = "Special Pencil";
  });

  // Get objects from the realm

  // Get all objects of type
  var items = realm.all<Item>();

  // Get object by index
  var item = items[1];

  // Get object by primary key
  var itemByKey = realm.find<Item>(0);

  // Filter and sort object
  var objects = realm.query<Item>("name == 'Special Pencil'");
  var name = 'Pen';
  objects = realm.query<Item>(r'name == $0', [name]);

  // Close the realm
  realm.close();
  ```

## Full contents of `catalog.dart`

```dart
import 'package:realm/realm.dart';

part 'catalog.realm.dart';

@RealmModel()
class _Item {
    @PrimaryKey()
    late int id;

    late String name;

    int price = 42;
}

// Create a Configuration object
var config = Configuration.local([Item.schema]);

// Open a Realm
var realm = Realm(config);

var myItem = Item(0, 'Pen', price: 4);

// Open a write transaction
realm.write(() {
    realm.add(myItem);
    var item = realm.add(Item(1, 'Pencil')..price = 20);
});

// Objects `myItem` and `item` are now managed and persisted in the realm

// Read object properties from realm
print(myItem.name);
print(myItem.price);

// Update object properties
realm.write(() {
    myItem.price = 20;
    myItem.name = "Special Pencil";
});

// Get objects from the realm

// Get all objects of type
var items = realm.all<Item>();

// Get object by index
var item = items[1];

// Get object by primary key
var itemByKey = realm.find<Item>(0);

// Filter and sort object
var objects = realm.query<Item>("name == 'Special Pencil'");
var name = 'Pen';
objects = realm.query<Item>(r'name == $0', [name]);

// Close the realm
realm.close();
```

# Realm Dart Standalone SDK

Realm Dart package is published to [realm_dart](https://pub.dev/packages/realm_dart).

## Environment setup for Realm Dart

- Realm Dart supports the platforms Windows, Mac and Linux.
- Dart SDK 3.0.2 or newer.

## Usage

- Add `realm_dart` package to a Dart application.

  ```
  dart pub add realm_dart
  ```

- Install the `realm_dart` package into the application. This downloads and copies the required native binaries to the app directory.

  ```
  dart run realm_dart install
  ```

- Import realm_dart in a dart file (ex. `catalog.dart`).

  ```dart
  import 'package:realm_dart/realm.dart';
  ```

- To generate RealmObject classes with realm_dart use this command.

  _*On Dart use `dart run realm_dart` to run `realm_dart` package commands*_

  ```
  dart run realm_dart generate
  ```

  A new file `catalog.realm.dart` will be created next to the `catalog.dart`.

  _\*The generated file should be committed to source control_

- The usage of the Realm Dart SDK is the same like the Realm Flutter above.

# Sync Realm Data with MongoDB Atlas using Flutter Realm Sync

**The Open-Source Replacement for Atlas Device Sync**

With Atlas Device Sync deprecated, **[Flutter Realm Sync](https://pub.dev/packages/flutter_realm_sync)** is the community-driven, production-ready solution for real-time bidirectional sync between Realm databases and MongoDB Atlas.

## Why Flutter Realm Sync?

| Feature | Atlas Device Sync<br/>*(Deprecated)* | **Flutter Realm Sync**<br/>*(Active & Open Source)* |
|---------|--------------------------------------|------------------------------------------------------|
| Real-time Sync | ✔️ | ✔️ **Socket.IO powered** |
| Offline-First | ✔️ | ✔️ **Native Realm integration** |
| Open Source | ❌ Closed | ✔️ **MIT License** |
| Self-Hosted | ❌ | ✔️ **Full control** |
| Production Ready | ❌ Deprecated | ✔️ **Battle-tested** |
| Active Development | ❌ | ✔️ **Community-driven** |

## Quick Start Guide

### Step 1: Add Flutter Realm Sync

```yaml
dependencies:
  realm_flutter_vector_db: ^1.0.11
  flutter_realm_sync: ^0.0.1
  socket_io_client: ^3.1.2
```

```bash
flutter pub get
```

### Step 2: Define Your Realm Model

Add required sync fields to your Realm models:

```dart
import 'package:realm_flutter_vector_db/realm_vector_db.dart';
part 'models.realm.dart';

@RealmModel()
@MapTo('tasks')
class _Task {
  @PrimaryKey()
  @MapTo('_id')
  late String id;

  late String title;
  late String status;
  late int progressMinutes;

  // Required for sync functionality
  @MapTo('sync_updated_at')
  int? syncUpdatedAt;

  @MapTo('sync_update_db')
  bool syncUpdateDb = false;
}
```

Generate the Realm schema:

```bash
dart run realm_flutter_vector_db generate
```

### Step 3: Initialize Realm with Sync Models

```dart
import 'package:realm_flutter_vector_db/realm_vector_db.dart';
import 'package:flutter_realm_sync/services/Models/sync_metadata.dart';
import 'package:flutter_realm_sync/services/Models/sync_db_cache.dart';
import 'package:flutter_realm_sync/services/Models/sync_outbox_patch.dart';

// Configure Realm with your models + sync models
final config = Configuration.local([
  Task.schema,
  SyncMetadata.schema,    // Required for sync state
  SyncDBCache.schema,     // Required for sync caching
  SyncOutboxPatch.schema, // Required for sync operations
], schemaVersion: 1);

final realm = Realm(config);
```

### Step 4: Set Up the Sync Server

**Complete backend included!** Get the production-ready Node.js server:

```bash
git clone https://github.com/mohit67890/realm-sync-server.git
cd realm-sync-server
npm install

# Add your MongoDB Atlas URI to .env
echo "MONGODB_URI=your_mongodb_connection_string" > .env

# Start the sync server
npm run dev  # Development mode
npm start    # Production mode
```

The server provides:
- ✅ Socket.IO with room-based isolation
- ✅ MongoDB Atlas integration
- ✅ Automatic change broadcasting
- ✅ Historic sync for offline catch-up
- ✅ Deploy to AWS/GCP/Heroku/DigitalOcean

**Server Repository:** https://github.com/mohit67890/realm-sync-server

### Step 5: Connect to Sync Server

```dart
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_realm_sync/services/RealmSync.dart';

// Connect to your sync server
final socket = IO.io(
  'http://your-server-url:3000',
  IO.OptionBuilder()
    .setTransports(['websocket'])
    .disableAutoConnect()
    .build(),
);

socket.onConnect((_) {
  print('✅ Connected to sync server');
  
  // Join sync room
  socket.emitWithAck('sync:join', {'userId': 'user-123'}, ack: (data) {
    if (data['success'] == true) {
      print('Joined sync room successfully');
    }
  });
});

socket.connect();
```

### Step 6: Initialize RealmSync

```dart
final realmSync = RealmSync(
  realm: realm,
  socket: socket,
  userId: 'user-123',
  configs: [
    SyncCollectionConfig<Task>(
      collectionName: 'tasks',
      results: realm.all<Task>(),
      idSelector: (obj) => obj.id,
      needsSync: (obj) => obj.syncUpdateDb,
      fromServerMap: (map) {
        return Task(
          map['_id'] as String,
          map['title'] as String,
          map['status'] as String,
          map['progressMinutes'] as int,
          syncUpdatedAt: map['sync_updated_at'] as int?,
        );
      },
    ),
  ],
);

// Start real-time sync
realmSync.start();

// Fetch historic changes (data while offline)
realmSync.fetchAllHistoricChanges(applyLocally: true);
```

### Step 7: Write and Sync Data

```dart
import 'package:flutter_realm_sync/services/RealmHelpers/realm_sync_extensions.dart';

// Create and sync a task in one call
final task = Task(
  ObjectId().toString(),
  'Complete project',
  'in_progress',
  100,
);

realm.writeWithSync(task, () {
  task.syncUpdateDb = true;
  realm.add(task);
});

// Sync to MongoDB Atlas and all connected devices
realmSync.syncObject('tasks', task.id);

// Update existing task
realm.writeWithSync(task, () {
  task.status = 'completed';
  task.progressMinutes = 120;
});

realmSync.syncObject('tasks', task.id);
```

**That's it!** Your app now has:
- ✅ Real-time bidirectional sync with MongoDB Atlas
- ✅ Offline-first architecture with automatic conflict resolution
- ✅ Multi-device sync across iOS, Android, macOS, Windows, Linux
- ✅ Automatic reconnection and historic sync

## Key Features

### 🔄 Bidirectional Real-Time Sync
Changes flow seamlessly: Device ↔️ MongoDB Atlas ↔️ All Devices

### 💾 Offline-First Architecture
Write locally, sync automatically when online. Zero data loss.

### ⚡ Intelligent Batching
Bulk operations with smart debouncing for optimal performance.

### 🎯 Automatic Conflict Resolution
Last-write-wins with millisecond-precision timestamps.

### 🔌 Production-Ready Server
Complete Node.js + TypeScript backend included. Deploy anywhere.

### 🎨 Fully Customizable
Pre-processors, custom serializers, your business logic.

### 📊 Battle-Tested
Powers production apps with 10,000+ documents, <100ms sync latency.

## Advanced Features

### Listen to Sync Events

```dart
final subscription = realmSync.objectChanges.listen((event) {
  print('Synced ${event.collectionName}: ${event.id}');
  // Access the synced object
  print('Object: ${event.object}');
});

// Cancel when done
subscription.cancel();
```

### Custom Pre-Processing

Modify data before sending to server:

```dart
SyncCollectionConfig<Task>(
  // ... other config ...
  emitPreProcessor: (rawJson) {
    // Add metadata
    rawJson['clientVersion'] = '2.1.0';
    rawJson['deviceId'] = DeviceInfo.id;
    rawJson['timestamp'] = DateTime.now().toIso8601String();
    return rawJson;
  },
)
```

### Historic Sync for Offline Catch-Up

```dart
// Fetch all changes since last sync
realmSync.fetchAllHistoricChanges(applyLocally: true);

// Manual fetch for specific collection
socket.emitWithAck(
  'sync:get_changes',
  {
    'userId': 'user-123',
    'collectionName': 'tasks',
    'since': lastSyncTimestamp,
  },
  ack: (response) {
    // Process historic changes
  },
);
```

## Resources

- **📦 Flutter Realm Sync Package:** https://pub.dev/packages/flutter_realm_sync
- **💻 GitHub Repository:** https://github.com/mohit67890/flutter_realm_sync
- **🔧 Sync Server Repository:** https://github.com/mohit67890/realm-sync-server
- **📚 Full Documentation:** See package README for comprehensive guides
- **💬 Example Chat App:** Production-ready demo with offline support

## Migration from Atlas Device Sync

Migrating from deprecated Atlas Device Sync? Flutter Realm Sync provides:

1. **Drop-in replacement** - Similar API, familiar concepts
2. **Self-hosted control** - Your infrastructure, your rules
3. **Cost savings** - No vendor lock-in or surprise bills
4. **Active development** - Community-driven with rapid updates
5. **Production support** - Battle-tested with real apps

**Get started today:** https://pub.dev/packages/flutter_realm_sync

# Building the source

See [CONTRIBUTING.md](https://github.com/realm/realm-dart/blob/main/CONTRIBUTING.md#building-the-source) for instructions about building the source.

# Code of Conduct

This project adheres to the [MongoDB Code of Conduct](https://www.mongodb.com/community-code-of-conduct).
By participating, you are expected to uphold this code. Please report
unacceptable behavior to [community-conduct@mongodb.com](mailto:community-conduct@mongodb.com).

# License

Realm Flutter and Dart SDKs and [Realm Core](https://github.com/realm/realm-core) are published under the Apache License 2.0.

##### The "Dart" name and logo and the "Flutter" name and logo are trademarks owned by Google.

<img style="width: 0px; height: 0px;" src="https://3eaz4mshcd.execute-api.us-east-1.amazonaws.com/prod?s=https://github.com/realm/realm-dart#README.md">
