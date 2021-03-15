import 'dart:math';

import '../core.dart';
import '../tools.dart';
import 'exception.dart';

///用来获取具体类型
class TypeToken<T> {
  ///实际类型
  Type get typeValue => T;

  // bool check(dynamic value, bool Function<T>(dynamic value) checker) =>
  //     checker.call<T>(value);

  @override
  bool operator ==(Object other) {
    return this == other ||
        (other is TypeToken && other.typeValue == typeValue);
  }

  @override
  int get hashCode => typeValue.hashCode;
}

///标注函数的返回值为void
class Void {
  static const Void _void = Void._();

  const Void._();

  factory Void() => _void;
}

///扫描到的类信息
class MirrorClass<T, A extends MReflectionEnable> {
  ///依据的key uri类型
  final String key;

  ///扫描时的注解信息
  final A annotation;

  ///扫描时的注解类型
  TypeToken<A> get annotationType => TypeToken<A>();

  ///类名 不包含所在的lib路径
  final String name;

  ///类的具体type
  TypeToken<T> get type => TypeToken<T>();

  ///所有的扫描到的构造函数
  final List<MirrorConstructor<T, MAnnotation>> constructors;

  ///所有的扫描到的属性
  final List<MirrorField<T, MAnnotation, dynamic>> fields;

  ///所有的扫描到的函数 不包含构造函数 和 get set
  final List<MirrorFunction<T, MAnnotation, dynamic>> functions;

  const MirrorClass(this.key, this.annotation, this.name, this.constructors,
      this.fields, this.functions);

  ///根据map内的参数来生成一个类的实例
  T newInstance(String? constructorName, Map<String, dynamic> params) {
    var c = getConstructor(constructorName);
    return c.newInstance(params);
  }

  ///根据命名构造函数的key来查找可用的构造函数
  MirrorConstructor<T, MAnnotation> getConstructor(String? constructorName) {
    var constructorNameStr = constructorName ?? '';
    var constructor = findFistWhere<MirrorConstructor<T, MAnnotation>>(
        constructors, (e) => e.key == constructorNameStr);
    if (constructor == null) {
      throw NoSuchFunctionException(T, constructorNameStr);
    }
    return constructor;
  }

  ///根据函数的key 来查找可用的函数
  MirrorFunction<T, MAnnotation, dynamic> getFunction(String functionName) {
    var function = findFistWhere<MirrorFunction<T, MAnnotation, dynamic>>(
        functions, (e) => e.key == functionName);
    if (function == null) {
      throw NoSuchFunctionException(T, functionName);
    }
    return function;
  }

  ///根据属性的key 来查找可用的属性
  MirrorField<T, MAnnotation, dynamic> getField(String fieldName) {
    var field = findFistWhere<MirrorField<T, MAnnotation, dynamic>>(
        fields, (e) => e.key == fieldName);
    if (field == null) {
      throw NoSuchFunctionException(T, fieldName);
    }
    return field;
  }
}

///扫描到的类的构造函数信息
class MirrorConstructor<T, A extends MAnnotation> {
  ///扫描时的注解信息
  final A annotation;

  ///扫描时的注解类型
  TypeToken get annotationType => TypeToken<A>();

  ///扫描时的函数名
  final String name;

  ///函数所需要的参数信息
  final List<MirrorParam<MAnnotation, dynamic>> params;

  ///具体的执行器
  final MirrorConstructorInvoker<T> invoker;

  // static final _checkMapArgAnnotation = TypeToken<MConstructorMapArg>();
  // static final _checkMapType = TypeToken<Map<String, dynamic>>();

  const MirrorConstructor(
      this.annotation, this.name, this.params, this.invoker);

  ///根据map内的参数来生成一个类的实例
  T newInstance(Map<String, dynamic> params) => invoker.call(params);

  ///执行函数
  T newInstance2(List positional, Map<String, dynamic> named) {
    var params = <String, dynamic>{};
    params.addAll(named);

    for (int i = 0, j = min(positional.length, this.params.length);
        i < j;
        i++) {
      params[this.params[i].key] = positional[i];
    }
    return newInstance(params);
  }

  ///获取key信息 优先从注解中获取 当注解为空时返回扫描时的name
  String get key => annotation.key.isEmpty ? name : annotation.key;

// //判断构造函数的参数是map的 特殊的构造函数
// bool get isConstructorMapArg =>
//     params.length == 1 &&
//     !params[0].isNamed &&
//     params[0].annotation.key.isEmpty &&
//     annotationType == _checkMapArgAnnotation &&
//     params[0].paramType == _checkMapType;
}

///扫描到的函数信息
class MirrorFunction<T, A extends MAnnotation, R> {
  ///扫描时的注解信息
  final A annotation;

  ///扫描时的注解类型
  TypeToken<A> get annotationType => TypeToken<A>();

  ///扫描时的函数名
  final String name;

  ///函数所需要的参数信息
  final List<MirrorParam<MAnnotation, dynamic>> params;

  ///函数的返回类型
  TypeToken<R> get returnType => TypeToken<R>();

  ///返回类型是否为非空类型
  final bool returnTypeIsNonNullable;

  ///函数的代理执行器
  final MirrorFunctionInvoker<T, R> invoker;

  ///函数对象的获取器
  final MirrorFunctionInstance<T> function;

  const MirrorFunction(this.annotation, this.name, this.params, this.invoker,
      this.function, this.returnTypeIsNonNullable);

  ///执行函数
  R? invoke(T bean, Map<String, dynamic> params) => invoker.call(bean, params);

  ///执行函数
  R? invoke2(T bean, List positional, Map<String, dynamic> named) {
    var params = <String, dynamic>{};
    params.addAll(named);

    for (int i = 0, j = min(positional.length, this.params.length);
        i < j;
        i++) {
      params[this.params[i].key] = positional[i];
    }
    return invoke(bean, params);
  }

  ///获取具体函数
  Function getFunction(T bean) => function.call(bean);

  ///获取key信息 优先从注解中获取 当注解为空时返回扫描时的name
  String get key => annotation.key.isEmpty ? name : annotation.key;
}

///扫描到的属性信息
class MirrorField<T, A extends MAnnotation, V> {
  ///扫描时的注解信息
  final A annotation;

  ///扫描时的注解类型
  TypeToken<A> get annotationType => TypeToken<A>();

  ///扫描时的属性名
  final String name;

  ///属性的类型
  TypeToken<V> get fieldType => TypeToken<V>();

  ///是否可以使用null赋值
  final bool isNonNullable;

  ///属性get代理执行器
  final MirrorFieldGetInvoker<T, V>? getInvoker;

  ///属性set代理执行器
  final MirrorFieldSetInvoker<T, dynamic>? setInvoker;

  const MirrorField(
    this.annotation,
    this.name,
    this.isNonNullable,
    this.getInvoker,
    this.setInvoker,
  );

  ///获取对象中的具体属性值
  V? get(T bean) => getInvoker?.call(bean);

  ///对象中的属性赋值
  void set(T bean, dynamic value) => setInvoker?.call(bean, value);

  ///是否可以set
  bool get hasSetter => setInvoker != null;

  ///是否可以get
  bool get hasGetter => getInvoker != null;

  ///获取key信息 优先从注解中获取 当注解为空时返回扫描时的name
  String get key => annotation.key.isEmpty ? name : annotation.key;
}

///扫描到的参数信息
class MirrorParam<A extends MAnnotation, PT> {
  ///扫描时的注解信息
  final A annotation;

  ///扫描时的注解类型
  TypeToken<A> get annotationType => TypeToken<A>();

  ///扫描时的参数名
  final String name;

  ///参数的type
  TypeToken<PT> get paramType => TypeToken<PT>();

  ///是否为可选参数
  final bool isOptional;

  ///是否为必选参数
  bool get isNeed => !isOptional;

  ///参数是否是命名参数
  final bool isNamed;

  ///是否是位置参数
  bool get isPositional => !isNamed;

  ///是否可以使用null赋值
  final bool isNonNullable;

  const MirrorParam(this.annotation, this.name, this.isOptional, this.isNamed,
      this.isNonNullable);

  ///获取key信息 优先从注解中获取 当注解为空时返回扫描时的name
  String get key => annotation.key.isEmpty ? name : annotation.key;
}

///构造函数的代理执行器
typedef MirrorConstructorInvoker<T> = T Function(Map<String, dynamic> params);

///属性的get代理执行器
typedef MirrorFieldGetInvoker<T, V> = V? Function(T bean);

///属性的set代理执行器
typedef MirrorFieldSetInvoker<T, V> = void Function(T bean, V value);

// ///获取函数对象的代理执行器
typedef MirrorFunctionInstance<T> = Function Function(T bean);

///执行函数调用的代理执行器
typedef MirrorFunctionInvoker<T, R> = R? Function(
    T bean, Map<String, dynamic> params);
