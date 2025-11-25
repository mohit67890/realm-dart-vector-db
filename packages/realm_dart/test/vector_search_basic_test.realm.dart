// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vector_search_basic_test.dart';

// **************************************************************************
// RealmObjectGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
class VectorDoc extends _VectorDoc
    with RealmEntity, RealmObjectBase, RealmObject {
  VectorDoc(
    String id,
    String title, {
    Iterable<double> embedding = const [],
  }) {
    RealmObjectBase.set(this, 'id', id);
    RealmObjectBase.set(this, 'title', title);
    RealmObjectBase.set<RealmList<double>>(
        this, 'embedding', RealmList<double>(embedding));
  }

  VectorDoc._();

  @override
  String get id => RealmObjectBase.get<String>(this, 'id') as String;
  @override
  set id(String value) => RealmObjectBase.set(this, 'id', value);

  @override
  String get title => RealmObjectBase.get<String>(this, 'title') as String;
  @override
  set title(String value) => RealmObjectBase.set(this, 'title', value);

  @override
  RealmList<double> get embedding =>
      RealmObjectBase.get<double>(this, 'embedding') as RealmList<double>;
  @override
  set embedding(covariant RealmList<double> value) =>
      throw RealmUnsupportedSetError();

  @override
  Stream<RealmObjectChanges<VectorDoc>> get changes =>
      RealmObjectBase.getChanges<VectorDoc>(this);

  @override
  Stream<RealmObjectChanges<VectorDoc>> changesFor([List<String>? keyPaths]) =>
      RealmObjectBase.getChangesFor<VectorDoc>(this, keyPaths);

  @override
  VectorDoc freeze() => RealmObjectBase.freezeObject<VectorDoc>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      'id': id.toEJson(),
      'title': title.toEJson(),
      'embedding': embedding.toEJson(),
    };
  }

  static EJsonValue _toEJson(VectorDoc value) => value.toEJson();
  static VectorDoc _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {
        'id': EJsonValue id,
        'title': EJsonValue title,
      } =>
        VectorDoc(
          fromEJson(id),
          fromEJson(title),
          embedding: fromEJson(ejson['embedding']),
        ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(VectorDoc._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(ObjectType.realmObject, VectorDoc, 'VectorDoc', [
      SchemaProperty('id', RealmPropertyType.string, primaryKey: true),
      SchemaProperty('title', RealmPropertyType.string),
      SchemaProperty('embedding', RealmPropertyType.double,
          collectionType: RealmCollectionType.list),
    ]);
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}
