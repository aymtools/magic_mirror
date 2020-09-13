

import '../tools.dart';

class ClassNotFoundException implements Exception {
  final String uri;
  final message;

  ClassNotFoundException(this.uri, {this.message});

  @override
  String toString() {
    final def =
        'ClassNotFoundException:\n For ${uri} can not found Class config!';
    if (message == null) return def;
    return '$def\n$message';
  }
}

class NoSuchMethodException implements Exception {
  final Type type;
  final String methodName;
  final message;

  NoSuchMethodException(this.type, this.methodName, {this.message});

  @override
  String toString() {
    final def = 'NoSuchMethodException:\n${type} : $methodName not found !';
    if (message == null) return def;
    return '$def\n$message';
  }
}

class NoSuchFieldException implements Exception {
  final Type type;
  final String fieldName;
  final message;

  NoSuchFieldException(this.type, this.fieldName, {this.message});

  @override
  String toString() {
    final def = 'NoSuchFieldException:\n${type} : $fieldName not found !';
    if (message == null) return def;
    return '$def\n$message';
  }
}

class IllegalArgumentException implements Exception {
  final Type type;
  final String name;
  final List<Pair<String, Type>> paramsTypes;
  final List<Pair<String, Type>> valuesTypes;
  final message;

  IllegalArgumentException(
      this.type, this.name, this.paramsTypes, this.valuesTypes,
      {this.message});

  @override
  String toString() {
    final def =
        'IllegalArgumentException:\n${type} : $name illegal argument ! \n need params : ${paramsTypes} \n values params ${valuesTypes}';
    if (message == null) return def;
    return '$def\n$message';
  }
}
