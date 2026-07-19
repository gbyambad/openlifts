import 'dart:convert';

import 'package:drift/drift.dart';

/// Stores a `List<String>` as a JSON text column, for display-only data
/// (instructions, image paths) that is never queried.
class StringListConverter extends TypeConverter<List<String>, String> {
  const StringListConverter();

  @override
  List<String> fromSql(String fromDb) =>
      (jsonDecode(fromDb) as List).cast<String>();

  @override
  String toSql(List<String> value) => jsonEncode(value);
}

/// Stores a `List<int>` as a JSON text column (e.g. chosen weekdays).
class IntListConverter extends TypeConverter<List<int>, String> {
  const IntListConverter();

  @override
  List<int> fromSql(String fromDb) => (jsonDecode(fromDb) as List).cast<int>();

  @override
  String toSql(List<int> value) => jsonEncode(value);
}
