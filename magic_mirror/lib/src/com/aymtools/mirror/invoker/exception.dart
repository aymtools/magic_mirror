import '../tools.dart';

///当前框架中所有异常信息的父类
abstract class MagicMirrorException implements Exception {}

///类信息无法找到异常
class ClassNotFoundException implements MagicMirrorException {
  ///触发异常的uri
  final String uri;

  ///其他信息
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

///函数未找到异常
class NoSuchFunctionException implements MagicMirrorException {
  ///所发生异常时的类型
  final Type type;

  ///要查找的函数的名字
  final String functionName;

  ///其他信息
  final message;

  NoSuchFunctionException(this.type, this.functionName, {this.message});

  @override
  String toString() {
    final def = 'NoSuchFunctionException:\n${type} : $functionName not found !';
    if (message == null) return def;
    return '$def\n$message';
  }
}

///属性未找到异常
class NoSuchFieldException implements MagicMirrorException {
  ///所发生异常时的类型
  final Type type;

  ///要查找的属性的名字
  final String fieldName;

  ///其他信息
  final message;

  NoSuchFieldException(this.type, this.fieldName, {this.message});

  @override
  String toString() {
    final def = 'NoSuchFieldException:\n${type} : $fieldName not found !';
    if (message == null) return def;
    return '$def\n$message';
  }
}

///参数类型异常
class IllegalArgumentException implements MagicMirrorException {
  ///所发生异常时的类型
  final Type type;

  ///发生异常的函数。构造函数。属性的名字
  final String name;

  ///目标所需要的类型
  final List<Pair<String, Type>> paramsTypes;

  ///当前能提供的类型
  final List<Pair<String, Type>> valuesTypes;

  ///其他信息
  final message;

  IllegalArgumentException(
      this.type, this.name, this.paramsTypes, this.valuesTypes,
      {this.message});

  @override
  String toString() {
    final def =
        'IllegalArgumentException:\n${type} : $name illegal argument ! \n need params : ${paramsTypes.map((e) => '${e.key}:${e.value}')} \n values params ${valuesTypes.map((e) => '${e.key}:${e.value}')}';
    if (message == null) return def;
    return '$def\n$message';
  }
}
