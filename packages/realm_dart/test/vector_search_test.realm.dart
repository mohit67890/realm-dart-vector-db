// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vector_search_test.dart';

// **************************************************************************
// RealmObjectGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
class Document extends _Document
    with RealmEntity, RealmObjectBase, RealmObject {
  Document(
    String id,
    String title, {
    String? category,
    String? priority,
    Iterable<double> embedding = const [],
  }) {
    RealmObjectBase.set(this, 'id', id);
    RealmObjectBase.set(this, 'title', title);
    RealmObjectBase.set(this, 'category', category);
    RealmObjectBase.set(this, 'priority', priority);
    RealmObjectBase.set<RealmList<double>>(
        this, 'embedding', RealmList<double>(embedding));
  }

  Document._();

  @override
  String get id => RealmObjectBase.get<String>(this, 'id') as String;
  @override
  set id(String value) => RealmObjectBase.set(this, 'id', value);

  @override
  String get title => RealmObjectBase.get<String>(this, 'title') as String;
  @override
  set title(String value) => RealmObjectBase.set(this, 'title', value);

  @override
  String? get category =>
      RealmObjectBase.get<String>(this, 'category') as String?;
  @override
  set category(String? value) => RealmObjectBase.set(this, 'category', value);

  @override
  String? get priority =>
      RealmObjectBase.get<String>(this, 'priority') as String?;
  @override
  set priority(String? value) => RealmObjectBase.set(this, 'priority', value);

  @override
  RealmList<double> get embedding =>
      RealmObjectBase.get<double>(this, 'embedding') as RealmList<double>;
  @override
  set embedding(covariant RealmList<double> value) =>
      throw RealmUnsupportedSetError();

  @override
  Stream<RealmObjectChanges<Document>> get changes =>
      RealmObjectBase.getChanges<Document>(this);

  @override
  Stream<RealmObjectChanges<Document>> changesFor([List<String>? keyPaths]) =>
      RealmObjectBase.getChangesFor<Document>(this, keyPaths);

  @override
  Document freeze() => RealmObjectBase.freezeObject<Document>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      'id': id.toEJson(),
      'title': title.toEJson(),
      'category': category.toEJson(),
      'priority': priority.toEJson(),
      'embedding': embedding.toEJson(),
    };
  }

  static EJsonValue _toEJson(Document value) => value.toEJson();
  static Document _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {
        'id': EJsonValue id,
        'title': EJsonValue title,
      } =>
        Document(
          fromEJson(id),
          fromEJson(title),
          category: fromEJson(ejson['category']),
          priority: fromEJson(ejson['priority']),
          embedding: fromEJson(ejson['embedding']),
        ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(Document._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(ObjectType.realmObject, Document, 'Document', [
      SchemaProperty('id', RealmPropertyType.string, primaryKey: true),
      SchemaProperty('title', RealmPropertyType.string),
      SchemaProperty('category', RealmPropertyType.string, optional: true),
      SchemaProperty('priority', RealmPropertyType.string, optional: true),
      SchemaProperty('embedding', RealmPropertyType.double,
          collectionType: RealmCollectionType.list),
    ]);
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}
