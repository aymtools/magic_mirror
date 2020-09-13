import 'dart:mirrors';

import 'package:analyzer/dart/element/type.dart';
import 'package:source_gen/source_gen.dart';

T genAnnotation<T>(ConstantReader annotation) {
  if (annotation == null) return null;
  var classMirror = reflectClass(T);
  return _gen(classMirror, annotation) as T;
}

dynamic _gen(ClassMirror classMirror, ConstantReader annotation) {
  try {
    var methodMirror = classMirror.declarations.values
        .whereType<MethodMirror>()
        .where((element) => element.isConstructor)
        .firstWhere((element) => element.constructorName == Symbol.empty);
    if (methodMirror != null) {
      var params = methodMirror.parameters;
      var positionalArguments = [];
      var namedArguments = <Symbol, dynamic>{};
      for (var p in params) {
        var value = _type(p.type, annotation?.peek(_getName(p.simpleName)));
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
      classMirror.instanceMembers
          .forEach((Symbol key, DeclarationMirror value) {
        //属性是VariableMirror
        if (value is VariableMirror && !value.isConst && !value.isFinal) {
          try {
            var v = _type(value.type, annotation?.peek(_getName(key)));
            if (v != null) r.setField(key, v);

            Log.log(
                'setField for 2 ${_getName(key)}:${value.toString()} type:${value.type} ');
          } catch (e) {
            Log.log(e.toString());
          }
        }

//        if (value is MethodMirror) {
//          // 3.方法上的元数据
//          value.metadata.forEach((metadata) {
//            print(metadata.reflectee.who + ' ==> ' + metadata.reflectee.what);
//          });
//          // 方法里的参数列表
//          value.parameters.forEach((param) {
//            //4.方法里参数的元数据
//            param.metadata.forEach((metadata) {
//              print(metadata.reflectee.who + ' ==> ' + metadata.reflectee.what);
//            });
//          });
//        }
      });
      return r.reflectee;
    }
  } catch (e) {
    Log.log(e.toString());
  }
  return null;
}

String _getName(Symbol symbol) {
//  var i = reflect(symbol);
//  i.type.declarations.forEach((key, value) {Log.log(key.toString());});
//  Log.log('dddddddd');
//  i.type.staticMembers.forEach((key, value) { Log.log(key.toString());});
//  Log.log('dd    '+i.type.toString());
//
//  return reflect(symbol).getField(Symbol('_name')).reflectee;
  return symbol.toString().substring(8, symbol.toString().length - 2);
}

dynamic _type(TypeMirror typeMirror, ConstantReader reader) {
  if (reader == null || reader.isNull) return null;
  if (reader.isString && String == typeMirror.reflectedType) {
    return reader == null || reader.isNull ? '' : reader.stringValue;
  } else if (reader.isDouble && double == typeMirror.reflectedType) {
    return reader == null || reader.isNull ? -1 : reader.doubleValue;
  } else if (reader.isInt && int == typeMirror.reflectedType) {
    return reader == null || reader.isNull ? -1 : reader.intValue;
  } else if (reader.isBool && bool == typeMirror.reflectedType) {
    return reader == null || reader.isNull ? false : reader.boolValue;
  } else if (reader.isMap) {
    var map =
        (typeMirror as ClassMirror).newInstance(Symbol.empty, []).reflectee;
    if (reader != null && !reader.isNull) {
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
  }

//  switch (typeMirror.reflectedType) {
//    case String:
//      return reader == null || reader.isNull ? '' : reader.toString();
//    case double:
//      return reader == null || reader.isNull
//          ? -1
//          : reader.doubleValue; //reader.toDoubleValue();
//    case int:
//      return reader == null || reader.isNull
//          ? -1
//          : reader.intValue; // reader.toIntValue();
//    case bool:
//      return reader == null || reader.isNull
//          ? false
//          : reader.boolValue; // reader.toBoolValue();
//    case Type:
//      return reader == null || reader.isNull
//          ? null
//          : reader.typeValue; // reader.toTypeValue();
//    case Map:
//      return reader == null || reader.isNull
//          ? {}
//          : Map.fromIterable(reader.mapValue.entries.map((e) => MapEntry(
//              _type(typeMirror.typeArguments[0], ConstantReader(e.key)),
//              _type(typeMirror.typeArguments[1], ConstantReader(e.value)))));
//    case List:
//      return reader == null || reader.isNull
//          ? []
//          : List.from(reader.listValue.map(
//              (e) => _type(typeMirror.typeArguments[0], ConstantReader(e))));
//  }
  return null;
}


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

class Log {
  static void log(String msg) {
    print(msg);
  }
}
