import 'package:magic_mirror/mirror.dart';

import 'type_adapter.dart';

abstract class IMirrorRegister {
  List<MirrorClass> classInfos();

// List<String> loadInitializer();
//
// List<String> loadTypeAdapter();
}

class MagicMirror implements IMirrorRegister {
  MagicMirror._();

  static final MagicMirror _instance = MagicMirror._();

  factory MagicMirror() => _instance;

  static MagicMirror get instance => _instance;

  IMirrorRegister _register;

  _MirrorRegister _registers;

  final Map<Type, Map<Type, TypeConvert>> _typeAdapter = {};

  final Map<String, MirrorClass> mirrorClassesK = {};

  final Map<Type, MirrorClass> mirrorClassesT = {};

  void bindRegister(IMirrorRegister register) {
    if (_register == null) {
      _register = _registers == null
          ? register
          : (_MirrorRegister(register)..bindSecRegister(_registers));
      _register.classInfos().forEach((element) {
        mirrorClassesK[element.key] = element;
        mirrorClassesT[element.type.typeValue] = element;
      });
      loadInitializer()
          .map((e) => newSingleInstance(e))
          .whereType<MirrorInitializer>()
          .forEach((element) => element.onInit(instance));
      // _register
      //     .loadInitializer()
      //     .map((e) => parseUriInfoByUriStr(e))
      //     .map((e) => newInstance(e.key, e.namedConstructorInUri, e.uriParams))
      //     .whereType<MirrorInitializer>()
      //     .forEach((element) => element.onInit(this));
    } else {
      throw Exception('Mirror is inited');
    }
  }

  static void register(IMirrorRegister register) {
    instance.bindRegister(register);
  }

  static void registers(IMirrorRegister register) {
    if (instance._register == null) {
      instance._registers = instance._registers == null
          ? _MirrorRegister(register)
          : (_MirrorRegister(register)..bindSecRegister(instance._registers));
    } else {
      throw Exception(
          'registerInvokers is close ! must register before registerInvoker');
    }
  }

  void registerTypeAdapter2(String typeAdapterClassUri) {
    registerTypeAdapter(newSingleInstance(typeAdapterClassUri));
  }

  void registerTypeAdapter(TypeConvert convert) {
    if (convert != null) {
      if (_typeAdapter[convert.from] == null) {
        _typeAdapter[convert.from] = <Type, TypeConvert>{};
      }
      _typeAdapter[convert.from][convert.to] = convert;
    }
  }

  static ClassUriInfo parseClassUriInfoByUriStr(String uri) =>
      parseClassUriInfo(Uri.parse(uri));

  static ClassUriInfo parseClassUriInfo(Uri u) => instance.parseUriInfo(u);

  static String getClassKey(Uri u) {
    return instance.parseUriInfo(u).key;
  }

  static String getNamedConstructorInUri(Uri u) {
    return instance.parseUriInfo(u).namedConstructorInUri;
  }

  static final Map<String, dynamic> _singleInstances = {};

  static T newInstanceS<T>(String uri,
      {dynamic param, bool canThrowException = false}) {
    return instance.newInstanceByUri(uri,
        param: param, canThrowException: canThrowException);
  }

  static dynamic invokeMethodS<T>(T bean, String methodName,
          {Map<String, dynamic> params, bool canThrowException = true}) =>
      instance.invokeMethod(bean, methodName,
          params: params, canThrowException: canThrowException);

  static dynamic getFieldValueS<T>(T bean, String fieldName,
          {bool canThrowException = true}) =>
      instance.getFieldValue(bean, fieldName,
          canThrowException: canThrowException);

  static void setFieldValueS<T>(T bean, String fieldName, dynamic value,
          {bool canThrowException = true}) =>
      instance.setFieldValue(bean, fieldName, value,
          canThrowException: canThrowException);

  static Map<String, dynamic> getAllFieldValue<T>(T bean,
          {bool canThrowException = true}) =>
      instance.getFieldValues(bean, canThrowException: canThrowException);

  static void setFieldValueByMap<T>(T bean, Map<String, dynamic> values,
          {bool canThrowException = true}) =>
      instance.setFieldValues(bean, values,
          canThrowException: canThrowException);

  static To convertTypeS<To>(dynamic from) => instance.convertType(from);

  To convertType<To>(dynamic from) {
    if (from == null) return null;
    if (from is To) return from;
    Type fromType = from.runtimeType;
    if (fromType == To) {
      return from as To;
    } else if (hasTypeAdapter(fromType, To)) {
      var converter = _typeAdapter[fromType][To];
      return converter.convert(from);
    }
    return from as To;
  }

  static bool hasTypeAdapterS(Type from, Type to) =>
      instance.hasTypeAdapter(from, to);

  static bool hasTypeAdapterS1<From>(Type to) =>
      instance.hasTypeAdapter(From, to);

  static bool hasTypeAdapterS2<To>(Type from) =>
      instance.hasTypeAdapter(from, To);

  static bool hasTypeAdapterS2Value<To>(dynamic fromValue) => fromValue == null
      ? true
      : (fromValue is To) || hasTypeAdapterS2<To>(fromValue.runtimeType);

  static bool hasTypeAdapterSValue(dynamic fromValue, Type to) =>
      fromValue == null
          ? true
          : (fromValue.runtimeType == to) ||
              hasTypeAdapterS(fromValue.runtimeType, to);

  static bool hasTypeAdapterS3<From, To>() => instance.hasTypeAdapter(From, To);

  static Type genType<T>() => T;

  bool hasTypeAdapter(Type from, Type to) =>
      from == to ||
      Object == to ||
      (_typeAdapter.containsKey(from) && _typeAdapter[from].containsKey(to));

  bool canCovertTo<To>(dynamic fromValue) => fromValue == null
      ? true
      : (fromValue is To) || hasTypeAdapterS2<To>(fromValue.runtimeType);

  ClassUriInfo parseUriInfoByUriStr(String uri) {
    return parseUriInfo(Uri.parse(uri));
  }

  ClassUriInfo parseUriInfo(Uri u) {
    var pathSegments = u.pathSegments;

    var queryParameters = u.queryParameters;
//    Map<String, List<String>> queryParametersAll = u.queryParametersAll;
    var namedConstructorInUri = '';
    if (pathSegments.isNotEmpty) {
      var lastPathS = pathSegments[pathSegments.length - 1];
      var lastPathSF = lastPathS.lastIndexOf('.');
      if (lastPathSF > -1) {
        namedConstructorInUri = lastPathS.substring(lastPathSF + 1);
        var lastPathRe = lastPathS.substring(0, lastPathSF);
        pathSegments = List.from(pathSegments, growable: false);
        pathSegments[pathSegments.length - 1] = lastPathRe;
        u = u.replace(pathSegments: pathSegments);
      } else {
        namedConstructorInUri = '';
      }
    } else {
      //如果是如 Invoker://test.named 也可以尝试进行解析  但如 Invoker://xxxx.test.named 为了安全起见 不解析 最好遵照uri的标准用法
      if (u.hasAuthority &&
          !u.authority.contains(':') &&
          u.authority.indexOf('.') == u.authority.lastIndexOf('.')) {
        var authority = u.authority;
        var ni = authority.lastIndexOf('.');
        namedConstructorInUri = ni > -1 ? authority.substring(ni + 1) : '';
        var newAuthority = ni > -1 ? authority.substring(0, ni) : authority;
        u = u.replace(host: newAuthority);
      }
    }
    u = u.replace(queryParameters: {});

    var uri = u.toString();

    if (uri.endsWith('?')) {
      uri = uri.substring(0, uri.length - 1);
    }

    return ClassUriInfo(uri, namedConstructorInUri, queryParameters);
  }

  List<String> loadTypeAdapter() => findKeys<TypeAdapter, TypeConvert>();

  List<String> loadInitializer() =>
      findKeys<OnMirrorInitializer, MirrorInitializer>();

  // List<String> find<T>({Type annotationType}) => mirrorClassesK.values
  //     .where((element) => element.type is TypeToken<T>)
  //     .where((element) =>
  //         annotationType == null ||
  //         element.annotationType.typeValue == annotationType)
  //     .map((e) => e.key)
  //     .toList();

  List<String> findKeys<AnnotationType, ExtendsType>() => mirrorClassesK.values
      .where((element) => element.type is TypeToken<ExtendsType>)
      .where((element) => element.annotationType is TypeToken<AnnotationType>)
      .map((e) => e.key)
      .toList();

  List<String> findKeysByAnnotation<AnnotationType>() => mirrorClassesK.values
      .where((element) => element.annotationType is TypeToken<AnnotationType>)
      .map((e) => e.key)
      .toList();

  List<String> findKeysExtends<ExtendsType>() => mirrorClassesK.values
      .where((element) => element.type is TypeToken<ExtendsType>)
      .map((e) => e.key)
      .toList();

  @override
  List<MirrorClass> classInfos() => _register?.classInfos() ?? [];

  MirrorClass<T> load<T>(String classKey) =>
      mirrorClassesK.containsKey(classKey) ? mirrorClassesK[classKey] : null;

  MirrorClass<T> mirror<T>() {
    Type type = genType<T>();
    return mirrorClassesT.containsKey(type) ? mirrorClassesT[type] : null;
  }

  bool canNewInstance(String classKey, String namedConstructor) {
    MirrorClass clazz = load(classKey);
    return clazz != null && clazz.getConstructor(namedConstructor) != null;
  }

  T newInstanceByUri<T>(String uri,
      {dynamic param, bool canThrowException = false}) {
    var info = parseUriInfoByUriStr(uri);
    return newInstance(info.key, info.namedConstructorInUri, info.uriParams,
        param: param, canThrowException: canThrowException);
  }

  T newInstance<T>(
      String classKey, String namedConstructor, Map<String, String> uriParams,
      {dynamic param, bool canThrowException = false}) {
    try {
      var params = <String, dynamic>{};
      MirrorClass<T> clazz = load<T>(classKey);
      MirrorConstructor constructor;
      if (clazz != null &&
          (constructor = clazz.getConstructor(namedConstructor)) != null) {
        if (constructor.params.isNotEmpty) {
          params = genParams(param, uriParams, constructor.params.first.key);
        }
        return constructor.newInstanceForMap(params);
      }
      if (canThrowException) {
        throw ClassNotFoundException(classKey);
      }
    } catch (e) {
      if (canThrowException) {
        throw e;
      }
    }
    return null;
  }

  T newSingleInstance<T>(String uri, {bool canThrowException = false}) {
    var info = parseUriInfoByUriStr(uri);
    if (_singleInstances.containsKey(info.key)) {
      return _singleInstances[info.key] as T;
    }
    T result = newInstance(info.key, info.namedConstructorInUri, info.uriParams,
        canThrowException: canThrowException);
    if (result != null) _singleInstances[info.key] = result;
    return result;
  }

  R invokeMethod<T, R>(T bean, String methodName,
      {Map<String, dynamic> params, bool canThrowException = true}) {
    try {
      MirrorClass<T> clazz = mirror<T>();
      if (clazz != null) {
        MirrorFunction<T, R> function;
        if ((function = clazz.getFunction(methodName)) != null) {
          return function.invoke(bean, params);
        } else {
          if (canThrowException) {
            throw NoSuchFunctionException(bean.runtimeType, methodName);
          }
        }
      } else {
        if (canThrowException) {
          throw ClassNotFoundException(bean.runtimeType.toString());
        }
      }
    } catch (e) {
      if (canThrowException) {
        throw e;
      }
    }
    return null;
  }

  void setFieldValue<T, V>(T bean, String fieldName, V value,
      {bool canThrowException = true}) {
    try {
      MirrorClass<T> clazz = mirror<T>();
      if (clazz != null) {
        MirrorField<T, dynamic> field;
        if ((field = clazz.getField(fieldName)) != null && field.hasSetter) {
          field.set(bean, value);
        } else {
          if (canThrowException) {
            throw NoSuchFieldException(bean.runtimeType, fieldName);
          }
        }
      } else {
        if (canThrowException) {
          throw ClassNotFoundException(bean.runtimeType.toString());
        }
      }
    } catch (e) {
      if (canThrowException) {
        throw e;
      }
    }
  }

  V getFieldValue<T, V>(T bean, String fieldName,
      {bool canThrowException = true}) {
    try {
      MirrorClass<T> clazz = mirror<T>();
      if (clazz != null) {
        MirrorField<T, dynamic> field;
        if ((field = clazz.getField(fieldName)) != null && field.hasGetter) {
          return field.get(bean);
        } else {
          if (canThrowException) {
            throw NoSuchFieldException(bean.runtimeType, fieldName);
          }
        }
      } else {
        if (canThrowException) {
          throw ClassNotFoundException(bean.runtimeType.toString());
        }
      }
    } catch (e) {
      if (canThrowException) {
        throw e;
      }
    }
    return null;
  }

  void setFieldValues<T>(T bean, Map<String, dynamic> values,
      {bool canThrowException = true}) {
    try {
      MirrorClass<T> clazz = mirror<T>();
      if (clazz != null) {
        clazz.fields.where((element) => element.hasSetter).forEach((element) {
          if (values.containsKey(element.key)) {
            try {
              setFieldValue(bean, element.key, values[element.key]);
            } on IllegalArgumentException {}
          }
        });
      } else {
        if (canThrowException) {
          throw ClassNotFoundException(bean.runtimeType.toString());
        }
      }
    } catch (e) {
      if (canThrowException) {
        throw e;
      }
    }
  }

  Map<String, dynamic> getFieldValues<T>(T bean,
      {bool canThrowException = true}) {
    var result = <String, dynamic>{};
    try {
      MirrorClass<T> clazz = mirror<T>();
      if (clazz != null) {
        clazz.fields.where((element) => element.hasGetter).forEach((element) {
          result[element.key] = element.get(bean);
        });
      } else {
        if (canThrowException) {
          throw ClassNotFoundException(bean.runtimeType.toString());
        }
      }
    } catch (e) {
      if (canThrowException) {
        throw e;
      }
    }
    return result;
  }
}

class ClassUriInfo {
  final String key;
  final String namedConstructorInUri;
  final Map<String, String> uriParams;

  ClassUriInfo(this.key, this.namedConstructorInUri, this.uriParams);
}

class _MirrorRegister implements IMirrorRegister {
  final IMirrorRegister _primaryInvoker;

  IMirrorRegister _secInvoker;

  _MirrorRegister(this._primaryInvoker);

  void bindSecRegister(IMirrorRegister secInvoker) {
    if (_secInvoker == null) {
      _secInvoker = secInvoker;
    } else if (_secInvoker is _MirrorRegister) {
      (_secInvoker as _MirrorRegister).bindSecRegister(secInvoker);
    } else {
      _secInvoker = _MirrorRegister(_secInvoker);
      (_secInvoker as _MirrorRegister).bindSecRegister(secInvoker);
    }
  }

  // @override
  // List<String> loadInitializer() {
  //   var result = List.from(_primaryInvoker.loadInitializer())
  //       .whereType<String>()
  //       .toList(growable: true);
  //   if (_secInvoker != null) {
  //     result.addAll(_secInvoker.loadInitializer());
  //   }
  //   return result;
  // }

  // @override
  // List<String> loadTypeAdapter() {
  //   var result = List.from(_primaryInvoker.loadTypeAdapter())
  //       .whereType<String>()
  //       .toList(growable: true);
  //   if (_secInvoker != null) result.addAll(_secInvoker.loadTypeAdapter());
  //   return result;
  // }

  @override
  List<MirrorClass> classInfos() {
    var result = List.from(_primaryInvoker.classInfos())
        .whereType<MirrorClass>()
        .toList(growable: true);
    if (_secInvoker != null) result.addAll(_secInvoker.classInfos());
    return result;
  }
}
