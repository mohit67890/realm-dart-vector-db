import 'dart:convert';
import 'dart:io';

void main() async {
  final file = File('test/data/output.json');
  final jsonString = await file.readAsString();
  final jsonData = json.decode(jsonString);
  final row = jsonData['rows'][0]['row'];

  print('Keys: ${row.keys.toList()}');
  print('Type of emb: ${row["emb"].runtimeType}');

  if (row['emb'] is List) {
    final embList = row['emb'] as List;
    print('emb is List with ${embList.length} elements');
    print('First element type: ${embList[0].runtimeType}');
    print('First 5 elements: ${embList.take(5).toList()}');
  } else {
    print('emb value (first 100 chars): ${row["emb"].toString().substring(0, 100)}');
  }

  print('\nChecking _id: ${row["_id"]} (${row["_id"].runtimeType})');
  print('Checking text: ${row["text"]} (${row["text"].runtimeType})');
  print('Checking trec-year: ${row["trec-year"]} (${row["trec-year"].runtimeType})');
}
