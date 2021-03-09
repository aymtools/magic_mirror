import 'dart:mirrors';

import 'package:analyzer/dart/element/type.dart';
import 'package:source_gen/source_gen.dart';

///从DartObjec转换为具体的注解类型
T? genAnnotation<T>(ConstantReader? annotation) {
  if (annotation == null || annotation.isNull) return null;
  var classMirror = reflectClass(T);
  return _gen(classMirror, annotation) as T?;
}

///根据类型的反射来生成
dynamic _gen(ClassMirror classMirror, ConstantReader annotation) {
  try {
    var methodMirror = classMirror.declarations.values
        .whereType<MethodMirror>()
        .where((element) => element.isConstructor)
        .firstWhere((element) => element.constructorName == Symbol.empty);
    var params = methodMirror.parameters;
    var positionalArguments = [];
    var namedArguments = <Symbol, dynamic>{};
    for (var p in params) {
      var value = _type(p.type, annotation.peek(_getName(p.simpleName)));
      // Log.log(
      //     'genAnnotation for 2  ${_getName(p.simpleName)}:${value.toString()} type:${p.type.reflectedType} ');
      if (p.isNamed) {
        namedArguments[p.simpleName] = value;
      } else {
        positionalArguments.add(value);
      }
    }
    var r = classMirror.newInstance(
        Symbol.empty, positionalArguments, namedArguments);
    classMirror.instanceMembers.forEach((Symbol key, DeclarationMirror value) {
      //属性是VariableMirror
      if (value is VariableMirror && !value.isConst && !value.isFinal) {
        try {
          var v = _type(value.type, annotation.peek(_getName(key)));
          if (v != null) r.setField(key, v);

          Log.log(
              'setField for 2 ${_getName(key)}:${value.toString()} type:${value.type} ');
        } catch (e) {
          Log.log(e.toString());
        }
      }
    });
    return r.reflectee;
  } catch (e) {
    Log.log(e.toString());
  }
  return null;
}

///获取Symbol的名字 反射时保证不变
String _getName(Symbol symbol) {
  return MirrorSystem.getName(symbol);
}

///自动转换过程
dynamic _type(TypeMirror typeMirror, ConstantReader? reader) {
  if (reader == null || reader.isNull) return null;
  if (reader.isString && String == typeMirror.reflectedType) {
    return reader.isNull ? '' : reader.stringValue;
  } else if (reader.isDouble && double == typeMirror.reflectedType) {
    return reader.isNull ? -1 : reader.doubleValue;
  } else if (reader.isInt && int == typeMirror.reflectedType) {
    return reader.isNull ? -1 : reader.intValue;
  } else if (reader.isBool && bool == typeMirror.reflectedType) {
    return reader.isNull ? false : reader.boolValue;
  } else if (reader.isMap) {
    var map =
        (typeMirror as ClassMirror).newInstance(Symbol.empty, []).reflectee;
    if (!reader.isNull) {
      reader.mapValue.entries.forEach((e) {
        map[_type(typeMirror.typeArguments[0], ConstantReader(e.key))] =
            _type(typeMirror.typeArguments[1], ConstantReader(e.value));
      });
    }
//     reader == null || reader.isNull
//        ? (typeMirror as ClassMirror).newInstance(Symbol.empty, []).reflectee
//        :
//    Map.fromIterable(reader.mapValue.entries.map((e) => MapEntry(
//            _type(typeMirror.typeArguments[0], ConstantReader(e.key)),
//            _type(typeMirror.typeArguments[1], ConstantReader(e.value)))));
    return map;
  } else if (reader.isList && typeMirror.isAssignableTo(reflectType(List))) {
//    return reader == null || reader.isNull
//        ? []
//        : List.from(reader.listValue
//            .map((e) => _type(typeMirror.typeArguments[0], ConstantReader(e))));

    var list =
        (typeMirror as ClassMirror).newInstance(Symbol.empty, []).reflectee;
    reader.listValue.forEach((e) {
      list.add(_type(typeMirror.typeArguments[0], ConstantReader(e)));
    });
    return list;
  } else if (typeMirror is ClassMirror) {
    return _gen(typeMirror, ConstantReader(reader.objectValue));
  } else if (typeMirror is FunctionTypeMirror) {
    return _gen(typeMirror, ConstantReader(reader.objectValue));
  }

  return null;
}

///判断type是否时core中的类型 无需导包的类型
bool isDartCoreType(DartType type) =>
    type.isDartCoreMap ||
    type.isDynamic ||
    type.isVoid ||
    type.isBottom ||
    type.isDartAsyncFuture ||
    type.isDartAsyncFutureOr ||
    type.isDartCoreBool ||
    type.isDartCoreDouble ||
    type.isDartCoreFunction ||
    type.isDartCoreInt ||
    type.isDartCoreList ||
    type.isDartCoreNull ||
    type.isDartCoreNum ||
    type.isDartCoreObject ||
    type.isDartCoreString ||
    type.isDartCoreSymbol ||
    type.isDartCoreSet;

///默认的日志工具
class Log {
  ///记录日志
  static void log(String msg) {
    print(msg);
  }
}
