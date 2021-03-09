import '../tools.dart';

///当前库中所有异常的父类
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

///类信息无法找到异常
class ClassNotConfigException implements MagicMirrorException {
  ///触发异常的uri
  final Type type;

  ///其他信息
  final message;

  ClassNotConfigException(this.type, {this.message});

  @override
  String toString() {
    final def =
        'ClassNotConfigException:\n For ${type} can not found Class config!';
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

// ///参数自动转换类型时出现异常
// class ArgumentConvertException implements MagicMirrorException {
//   ///转换的原始类型
//   final Type from;
//
//   ///转换的目标类型
//   final Type to;
//
//   final source;
//
//   ///其他信息
//   final message;
//
//   ArgumentConvertException(this.from, this.to, this.source, {this.message});
//
//   @override
//   String toString() {
//     final def =
//         'ArgumentConvertException:\nThe source:${source} cannot from $from convert to $to';
//     if (message == null) return def;
//     return '$def\n$message';
//   }
// }
