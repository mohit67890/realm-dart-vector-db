// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hnsw_benchmark_test.dart';

// **************************************************************************
// RealmObjectGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
class Query extends _Query with RealmEntity, RealmObjectBase, RealmObject {
  Query(
    String id,
    String text,
    int trecYear, {
    Iterable<double> embedding = const [],
  }) {
    RealmObjectBase.set(this, 'id', id);
    RealmObjectBase.set(this, 'text', text);
    RealmObjectBase.set(this, 'trecYear', trecYear);
    RealmObjectBase.set<RealmList<double>>(
        this, 'embedding', RealmList<double>(embedding));
  }

  Query._();

  @override
  String get id => RealmObjectBase.get<String>(this, 'id') as String;
  @override
  set id(String value) => RealmObjectBase.set(this, 'id', value);

  @override
  String get text => RealmObjectBase.get<String>(this, 'text') as String;
  @override
  set text(String value) => RealmObjectBase.set(this, 'text', value);

  @override
  int get trecYear => RealmObjectBase.get<int>(this, 'trecYear') as int;
  @override
  set trecYear(int value) => RealmObjectBase.set(this, 'trecYear', value);

  @override
  RealmList<double> get embedding =>
      RealmObjectBase.get<double>(this, 'embedding') as RealmList<double>;
  @override
  set embedding(covariant RealmList<double> value) =>
      throw RealmUnsupportedSetError();

  @override
  Stream<RealmObjectChanges<Query>> get changes =>
      RealmObjectBase.getChanges<Query>(this);

  @override
  Stream<RealmObjectChanges<Query>> changesFor([List<String>? keyPaths]) =>
      RealmObjectBase.getChangesFor<Query>(this, keyPaths);

  @override
  Query freeze() => RealmObjectBase.freezeObject<Query>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      'id': id.toEJson(),
      'text': text.toEJson(),
      'trecYear': trecYear.toEJson(),
      'embedding': embedding.toEJson(),
    };
  }

  static EJsonValue _toEJson(Query value) => value.toEJson();
  static Query _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {
        'id': EJsonValue id,
        'text': EJsonValue text,
        'trecYear': EJsonValue trecYear,
      } =>
        Query(
          fromEJson(id),
          fromEJson(text),
          fromEJson(trecYear),
          embedding: fromEJson(ejson['embedding']),
        ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(Query._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(ObjectType.realmObject, Query, 'Query', [
      SchemaProperty('id', RealmPropertyType.string, primaryKey: true),
      SchemaProperty('text', RealmPropertyType.string),
      SchemaProperty('trecYear', RealmPropertyType.int),
      SchemaProperty('embedding', RealmPropertyType.double,
          collectionType: RealmCollectionType.list),
    ]);
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}
