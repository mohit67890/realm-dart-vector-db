# Realm Vector Search Demo

This Flutter example demonstrates the HNSW (Hierarchical Navigable Small World) vector search capabilities in Realm.

## What's New

This example has been updated with:
- **iOS Framework with HNSW Support**: The `realm_dart.xcframework` now includes all HNSW C API functions
- **Vector Search Example**: Demonstrates semantic search using document embeddings
- **All Three Distance Metrics**: Shows usage of Euclidean, Cosine, and Dot Product metrics

## Features Demonstrated

### 1. Vector Index Creation
```dart
realm.createVectorIndex<Document>(
  'embedding',
  metric: VectorDistanceMetric.cosine,
  m: 16,
  efConstruction: 200,
);
```

### 2. K-Nearest Neighbors (KNN) Search
```dart
final results = realm.vectorSearchKnn<Document>(
  'embedding',
  queryVector: [0.9, 0.8, 0.1, 0.2],
  k: 3,
);
```

### 3. Radius-Based Search
```dart
final results = realm.vectorSearchRadius<Document>(
  'embedding',
  queryVector: [0.5, 0.5, 0.5, 0.5],
  maxDistance: 0.5,
);
```

### 4. Index Statistics
```dart
final stats = realm.getVectorIndexStats<Document>('embedding');
print('Vectors indexed: ${stats.numVectors}');
print('Max layer: ${stats.maxLayer}');
```

## Running the Example

### Prerequisites
- Flutter SDK ^3.27.0
- Dart SDK ^3.6.0
- Xcode (for iOS)

### Steps

1. Get dependencies:
```bash
cd packages/realm/example
flutter pub get
```

2. Run on iOS Simulator:
```bash
flutter run -d "iPhone 15 Pro"
```

3. Or run on a physical iOS device:
```bash
flutter run
```

## Example Output

The app will display:
- Basic CRUD operations with Car and Person models
- Vector search demonstration with Document model
- Semantic similarity search results
- Distance calculations for each result
- Index statistics

## Technical Details

### iOS Framework
- **Location**: `packages/realm/ios/realm_dart.xcframework`
- **Size**: 23 MB
- **Architectures**: 
  - iOS Device: arm64
  - iOS Simulator: arm64 + x86_64
- **HNSW Functions**: 6 C API functions exported

### Vector Search C API Functions
All exported and available:
- `realm_hnsw_create_index`
- `realm_hnsw_search_knn`
- `realm_hnsw_search_radius`
- `realm_hnsw_has_index`
- `realm_hnsw_get_stats`
- `realm_hnsw_remove_index`

### Distance Metrics Supported
1. **Euclidean (L2)**: Best for vectors where magnitude matters
2. **Cosine**: Best for normalized embeddings (measures angle)
3. **Dot Product**: Best for maximum inner product search (MIPS)

## Sample Data

The example creates documents with 4-dimensional embeddings:
- **Tech documents**: High values in first two dimensions
- **Nature documents**: High values in last two dimensions
- **Mixed document**: Balanced across all dimensions

This demonstrates how semantically similar documents cluster together in vector space.

## Configuration Options

### Index Parameters
- **m**: Number of bidirectional links (default: 16)
- **efConstruction**: Build-time quality parameter (default: 200)
- **metric**: Distance calculation method (default: Euclidean)

### Search Parameters
- **k**: Number of nearest neighbors to return
- **efSearch**: Search-time quality parameter (default: 50)
- **maxDistance**: Maximum distance for radius search
- **maxResults**: Maximum results for radius search (default: 100)

## Troubleshooting

If you encounter build issues:

1. Clean the build:
```bash
flutter clean
flutter pub get
```

2. For iOS, clean CocoaPods:
```bash
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
```

3. Verify the framework is present:
```bash
ls -lh ios/realm_dart.xcframework/
```

## Next Steps

- Experiment with different embedding dimensions
- Try different distance metrics
- Adjust HNSW parameters (m, efConstruction)
- Add more documents and compare results
- Implement real embeddings from ML models (e.g., sentence transformers)

## Additional Resources

- [Realm Documentation](https://docs.mongodb.com/realm/)
- [HNSW Algorithm Paper](https://arxiv.org/abs/1603.09320)
- [Vector Search Guide](https://www.mongodb.com/docs/atlas/atlas-vector-search/)
