import 'dart:convert';
import 'dart:io';
import 'dart:math';

void main() {
  final random = Random(42); // Fixed seed for reproducibility
  final dataset = <Map<String, dynamic>>[];
  
  // Generate 100 synthetic queries with 1024-dimensional embeddings
  for (int i = 0; i < 100; i++) {
    // Generate random unit vector
    final embedding = List.generate(1024, (_) => (random.nextDouble() * 2 - 1));
    
    // Normalize to unit vector
    final norm = sqrt(embedding.fold<double>(0, (sum, val) => sum + val * val));
    final normalizedEmbedding = embedding.map((v) => v / norm).toList();
    
    dataset.add({
      '_id': '${100000 + i}',
      'text': 'Sample query text number $i for benchmarking purposes',
      'trec-year': 2020 + (i % 5),
      'emb': normalizedEmbedding,
    });
  }
  
  final output = {
    'dataset': 'synthetic-benchmark',
    'rows': dataset.map((row) => {'row': row}).toList(),
  };
  
  final file = File('test/data/output.json');
  file.writeAsStringSync(jsonEncode(output));
  
  print('✅ Generated ${dataset.length} synthetic queries with 1024D embeddings');
  print('💾 Saved to ${file.path}');
}
