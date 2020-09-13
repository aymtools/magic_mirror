import '../core.dart';
import '../tools.dart';
import 'exception.dart';

// typedef IType<T> = void Function();
class TypeToken<T> {
  Type get typeValue => T;

  // bool check(dynamic value, bool Function<T>(dynamic value) checker) =>
  //     checker.call<T>(value);

  @override
  bool operator ==(Object other) {
    return super == other ||
        (other is TypeToken && other.typeValue == typeValue);
  }
}

class Void {
  static const Void _void = Void._();

  const Void._();

  factory Void() => _void;
}

class MirrorClass<T> {
  final String key;
  final MClass annotation;
  final TypeToken annotationType;

  final String name;
  final TypeToken<T> type;

  final List<MirrorConstructor<T>> constructors;

  final List<MirrorField<T, dynamic>> fields;

  final List<MirrorFunction<T, dynamic>> functions;

  const MirrorClass(this.key, this.annotation, this.annotationType, this.type,
      this.name, this.constructors, this.fields, this.functions);

  // dynamic newInstance(String constructorName, List<dynamic> positionalArguments,
  //     [Map<Symbol, dynamic> namedArguments = const <Symbol, dynamic>{}]) {
  //   var c = getConstructor(constructorName);
  //   if (c == null) {
  //     throw ClassNotFoundException('constructorName');
  //   }
  //   return c.newInstance(positionalArguments, namedArguments);
  // }

  T newInstanceForMap(String constructorName, Map<String, dynamic> params) {
    var c = getConstructor(constructorName);
    if (c == null) {
      throw ClassNotFoundException('$key.$constructorName');
    }
    return c.newInstanceForMap(params);
  }

  MirrorConstructor<T> getConstructor(String constructorName) =>
      findFistWhere(constructors, (e) => e.key == constructorName);

  MirrorFunction<T, dynamic> getFunction(String functionName) =>
      findFistWhere(functions, (e) => e.key == functionName);

  MirrorField<T, dynamic> getField(String fieldName) =>
      findFistWhere(fields, (e) => e.key == fieldName);
}

class MirrorConstructor<T> {
  final MConstructor annotation;
  final TypeToken annotationType;
  final String name;
  final List<MirrorParam> params;

  final MirrorConstructorInvoker<T> invoker;

  const MirrorConstructor(this.annotation, this.annotationType, this.name,
      this.params, this.invoker);

  // dynamic newInstance(List<dynamic> positionalArguments,
  //     [Map<Symbol, dynamic> namedArguments = const <Symbol, dynamic>{}]) {}

  T newInstanceForMap(Map<String, dynamic> params) => invoker.call(params);

  String get key => annotation.key.isEmpty ? name : annotation.key;
}

class MirrorFunction<T, R> {
  final MFunction annotation;
  final TypeToken annotationType;
  final String name;
  final List<MirrorParam> params;
  final TypeToken returnType;
  final MirrorFunctionInvoker<T, R> invoker;

  const MirrorFunction(this.annotation, this.annotationType, this.name,
      this.params, this.returnType, this.invoker);

  R invoke(T bean, Map<String, dynamic> params) => invoker.call(bean, params);

  String get key => annotation.key.isEmpty ? name : annotation.key;
}

class MirrorField<T, V> {
  final MField annotation;
  final TypeToken annotationType;
  final String name;
  final TypeToken fieldType;
  final MirrorFieldGetInvoker<T, V> getInvoker;
  final MirrorFieldSetInvoker<T, V> setInvoker;

  const MirrorField(
    this.annotation,
    this.annotationType,
    this.name,
    this.fieldType,
    this.getInvoker,
    this.setInvoker,
  );

  dynamic get(T bean) => getInvoker.call(bean);

  void set(T bean, dynamic value) => setInvoker.call(bean, value);

  bool get hasSetter => setInvoker != null;

  bool get hasGetter => getInvoker != null;

  String get key => annotation.key.isEmpty ? name : annotation.key;
}

class MirrorParam {
  final MParam annotation;
  final TypeToken annotationType;
  final String name;
  final TypeToken paramType;

  const MirrorParam(
      this.annotation, this.annotationType, this.name, this.paramType);

  String get key => annotation.key.isEmpty ? name : annotation.key;
}

typedef MirrorConstructorInvoker<T> = T Function(Map<String, dynamic> params);

typedef MirrorFieldGetInvoker<T, V> = V Function(T bean);
typedef MirrorFieldSetInvoker<T, V> = void Function(T bean, V value);

typedef MirrorFunctionInvoker<T, R> = R Function(
    T bean, Map<String, dynamic> params);

// abstract class MirrorConstructorInvoker<T> {
//   T newInstanceForMap(Map<String, dynamic> params);
// }

// abstract class MirrorFieldInvoker<T> {
//   dynamic getField(T bean) {}
//
//   void setField(T bean, dynamic value) {}
// }
//
// abstract class MirrorFunctionInvoker<T> {
//   dynamic invoke(T bean, Map<String, dynamic> params) {}
// }
