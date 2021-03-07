import 'dart:async';

import 'package:magic_mirror/magic_mirror.dart';
import 'package:source_gen/source_gen.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/element.dart';

// ignore: library_prefixes
import 'dart:math' as Math;

import 'builder.dart';
import 'entities.dart';
import 'tools.dart';

typedef AssetsTypeParser = Future<DartType> Function(Uri assetsUri);

///生成导入包的缓冲器
class _GenImports {
  final GImports imports;

  _GenImports(this.imports);

  ///类的类型转换为包含As的String
  String classTypeStrMaker(GClass clazz) => typeStrMaker(clazz.type.value);

  String typeStrMaker(DartType type) => imports.getTypeNameAsStr(type);

  ///类的类型转换为包含As的String
  String paramTypeStrMaker(GParam param) => typeStrMaker(param.type.value);

  ///field的类型转换为包含As的String
  String fieldTypeStrMaker(GField field) => typeStrMaker(field.type.value);

  ///returnType的类型转换为包含As的String
  String returnTypeStrMaker(GFunction function) {
    var r = typeStrMaker(function.returnType.value);
    return 'void' == r ? 'Void' : r;
  }

  ///注解的具体类型的类型转换为包含As的String
  String annTypeStrMaker(ConstantReader ann) =>
      ann == null || ann.isNull ? 'null' : typeStrMaker(ann.objectValue.type);

  ///获取转换后的需要的所有的导入包信息
  String get importsValue => imports
      .getImports()
      .entries
      .map((e) => e.value.isEmpty
          ? "import '${e.key}' ;"
          : "import '${e.key}' as ${e.value} ;")
      .fold('', (p, e) => '$p$e');
}

///生成魔镜的注册器
String genMirrorRegister(String defPackage, List<String> other) {
  var imports = GImports();
  var otherStr = other
      .map((e) =>
          "${imports.getUriAsNameStr(e.replaceAll('.mirror.aymtools', ''))}Register.Register.register();")
      .toList();
  return '''
import 'package:magic_mirror/magic_mirror.dart';
${other.map((e) => "import '${e}' as ${imports.getUriAsNameStr(e.replaceAll('.mirror.aymtools', ''))}Register;").fold('', (p, v) => p + v)}
${_genCodeLibInfoMirrorRegisterTemplate([], true, otherStr)}
  ''';
}

///根据类包信息生成的注册器
Future<String> genMirrorLibInfoMirror(
    GLibraryInfo libraryInfo, AssetsTypeParser parser,
    {bool importOtherLib = false, GImports defImports}) async {
  var imports = defImports ?? GImports();
  if (importOtherLib) {
    imports.addLibs(libraries.values.toList());
  }
  var genImport = _GenImports(imports);
  var content = await genCodeLibInfoMirrorInfo(
    libraryInfo,
    genImport.annTypeStrMaker,
    genImport.classTypeStrMaker,
    genImport.paramTypeStrMaker,
    genImport.fieldTypeStrMaker,
    genImport.returnTypeStrMaker,
    genImport.typeStrMaker,
    parser,
  );
  var importsValue = genImport.importsValue;
  var register = _genCodeLibInfoMirrorRegister(libraryInfo.classes,
      imports.getLibInfoAsNameStr(libraryInfo), genImport.classTypeStrMaker);
  return importsValue + content + register;
}

///生成project所有的引用类库的注册信息
Future<String> genMirrorImplementation(
    List<GLibrary> implementations, AssetsTypeParser parser) async {
  var imports = GImports(otherImportLibrary: implementations);
  var genImport = _GenImports(imports);
  var content = await Stream.fromFutures(implementations
      .expand((element) => element.libs)
      .map((e) => genCodeLibInfoMirrorInfo(
            e,
            genImport.annTypeStrMaker,
            genImport.classTypeStrMaker,
            genImport.paramTypeStrMaker,
            genImport.fieldTypeStrMaker,
            genImport.returnTypeStrMaker,
            genImport.typeStrMaker,
            parser,
          ))).toList();
  var importsValue = genImport.importsValue;
  var classes = <String>[];
  implementations
      .expand((element) => element.libs)
      .expand((element) => element.classes)
      .forEach((clazz) {
    classes.add(genImport.classTypeStrMaker.call(clazz).replaceAll('.', ''));
  });
  var register = _genCodeLibInfoMirrorRegisterTemplate(classes, false, []);
  return importsValue + content.join('') + register;
}

///生成类库的注册器
Future<String> genCodeMirrorInfo(
    GLibrary library, AssetsTypeParser parser) async {
  var imports = GImports(otherImportLibrary: libraries.values.toList());
  var genImport = _GenImports(imports);

  var steam = Stream.fromFutures(
    library.libs.map<Future<String>>(
      (e) => genCodeLibInfoMirrorInfo(
        e,
        genImport.annTypeStrMaker,
        genImport.classTypeStrMaker,
        genImport.paramTypeStrMaker,
        genImport.fieldTypeStrMaker,
        genImport.returnTypeStrMaker,
        genImport.typeStrMaker,
        parser,
      ),
    ),
  );
  var list = await steam.toList();

  var content = list
      .where((element) => element.isNotEmpty)
      .fold('', (previousValue, element) => '$previousValue$element');
  var importsValue = imports
      .getImports()
      .entries
      .map((e) => e.value.isEmpty
          ? "import '${e.key}' ;"
          : "import '${e.key}' as ${e.value} ;")
      .fold('', (p, e) => '$p$e');
  return importsValue +
      content +
      _genCodeLibInfoMirrorRegister(
          library.libs.expand((element) => element.classes).toList(),
          imports.getLibAsNameStr(library),
          genImport.classTypeStrMaker);
}

///根据所有的类信息生成注册器
String _genCodeLibInfoMirrorRegister(
  List<GClass> libraryClass,
  String libAsNameStr,
  String Function(GClass clazz) typeStrMaker,
) {
  var classes = <String>[];
  libraryClass.forEach((clazz) {
    classes.add(typeStrMaker.call(clazz).replaceAll('.', ''));
  });

  return _genCodeLibInfoMirrorRegisterTemplate(classes, false, []);
}

///根据所有的类信息生成注册器
String _genCodeLibInfoMirrorRegisterTemplate(
    List<String> classes, bool isFinal, List<String> otherRegister) {
  return '''  
class Register implements IMirrorRegister {
  const Register._();

  static const Register _register = Register._();

  static void register() {
  ${otherRegister.fold('', (p, e) => p + e)}
    MagicMirror.register${isFinal ? '' : 's'}(_register);
  }

  @override
  List<MirrorClass> classInfos() => <MirrorClass>${classes.isEmpty ? '[]' : classes.map((e) => '_${e}Mirror.mirror').toList()};

}
  ''';

  // //
  // @override
  // List<String> loadInitializer() => ${initializers.isEmpty ? '[]' : initializers.map((e) => "'$e'").toList()};
  //
  // @override
  // List<String> loadTypeAdapter() =>${typeAdapters.isEmpty ? '[]' : typeAdapters.map((e) => "'$e'").toList()};
}

///根据类包信息信息生成注册器 的类信息内容
Future<String> genCodeLibInfoMirrorInfo(
  GLibraryInfo library,
  String Function(ConstantReader param) annTypeStrMaker,
  String Function(GClass param) classTypeStrMaker,
  String Function(GParam param) paramTypeStrMaker,
  String Function(GField param) fieldTypeStrMaker,
  String Function(GFunction param) returnTypeStrMaker,
  String Function(DartType type) typeStrMaker,
  AssetsTypeParser parser,
) async {
  return (await Stream.fromFutures(
    library.classes.map<Future<String>>(
      (e) => _genCodeClassMirrorInfo(
          e,
          annTypeStrMaker,
          classTypeStrMaker,
          paramTypeStrMaker,
          fieldTypeStrMaker,
          returnTypeStrMaker,
          typeStrMaker,
          parser),
    ),
  ).toList())
      .where((element) => element.isNotEmpty)
      .fold('', (previousValue, element) => '$previousValue$element');
}

///生成具体的类信息
FutureOr<String> _genCodeClassMirrorInfo(
  GClass clazz,
  String Function(ConstantReader param) annTypeStrMaker,
  String Function(GClass param) classTypeStrMaker,
  String Function(GParam param) paramTypeStrMaker,
  String Function(GField param) fieldTypeStrMaker,
  String Function(GFunction param) returnTypeStrMaker,
  String Function(DartType type) typeStrMaker,
  AssetsTypeParser parser,
) async {
  var classTypeName = classTypeStrMaker.call(clazz);
  var className = classTypeName.replaceAll('.', '');
  var annotation = clazz.annotationValue;
  var annotationClass = annTypeStrMaker.call(annotation);

  var cs = clazz.constructors.map((e) {
    var named = e.element?.name ?? '';
    var CMD = named.isEmpty
        ? 'return $classTypeName'
        : 'return $classTypeName.${named}';
    return '''
   static ${classTypeName} newInstance${capitalize(e.namedConstructorInKey)}(Map<String, dynamic> params){
   ${_genCodeFunctionInvokerForMapParamsSwitch(CMD, e.params, 'params', '''
        throw new IllegalArgumentException(${classTypeName},
            '${named}',
            [${e.params.map((e) => "Pair('${e.paramKey}',MagicMirror.genType<${paramTypeStrMaker.call(e)}>())").fold('', (p, e) => p == '' ? e : "$p,$e")}],
            params.entries.map((e)=>Pair(e.key, e.value.runtimeType)).toList());
     ''', paramTypeStrMaker)}
   }
   ''';
  }).toList();

  var fs = clazz.fields.map((e) {
    var fieldTypeStr = fieldTypeStrMaker.call(e);
    var result = '';
    if (e.element.getter != null) {
      result += '''      
   static ${fieldTypeStr} get${capitalize(e.fieldName)}(${classTypeName} bean)=> bean.${e.element.name};
      ''';
    }
    if (e.element.setter != null) {
      result += '''      
   static void set${capitalize(e.fieldName)}(${classTypeName} bean , dynamic  value) {
      if (MagicMirror.hasTypeAdapterS2Value<${fieldTypeStr}>(value)) {
        bean.${e.element.name} = MagicMirror.convertTypeS<${fieldTypeStr}>(value);
      } else {
        throw new IllegalArgumentException(${classTypeName},
            '${e.element.name}',
            [Pair('${e.element.name}', MagicMirror.genType<${fieldTypeStr}>())],
            [Pair('${e.element.name}', value.runtimeType)]);
      }
  }
      ''';
    }
    return result;
  }).toList();

  var funs = clazz.functions.map((e) {
    var returnTypeStr = returnTypeStrMaker.call(e);
    var CMD =
        '${'Void' == returnTypeStr ? '' : 'return'} bean.${e.element.name}';
    var cmdAfter =
        'Void' == returnTypeStr ? <String>['return Void();'] : <String>[];
    return '''
   static ${returnTypeStr} invoke${capitalize(e.functionName)}(${classTypeName} bean, Map<String, dynamic> params){
    ${_genCodeFunctionInvokerForMapParamsSwitch(
      CMD,
      e.params,
      'params',
      '''
        throw new IllegalArgumentException(${classTypeName},
            '${e.element.name}',
            [${e.params.map((e) => "Pair('${e.paramKey}',MagicMirror.genType<${paramTypeStrMaker.call(e)}>())").fold('', (p, e) => p == '' ? e : "$p,$e")}],
            params.entries.map((e)=>Pair(e.key, e.value.runtimeType)).toList());
     ''',
      paramTypeStrMaker,
      cmdAfter: cmdAfter,
    )}
   }
   
   static Function fun${capitalize(e.functionName)}(${classTypeName} bean) => bean.${e.element.displayName};
   ''';
  }).toList();

  return '''
class _${className}Mirror{
  ${cs.join(' ')}
  ${fs.join(' ')}
  ${funs.join(' ')}
  
     
   static final mirror = const MirrorClass<$classTypeName,$annotationClass>(
    '${clazz.key}',
    const ${await _genCodeAnnotation(clazz.annotationValue, typeStrMaker, parser)},
    '${clazz.element.displayName}',
    const <MirrorConstructor<$classTypeName,MConstructor>>[
        ${clazz.constructors.isEmpty ? '' : await (await Stream.fromFutures(clazz.constructors.map((e) async => await _genCodeConstructor(classTypeName, e, annTypeStrMaker, paramTypeStrMaker, typeStrMaker, parser)).toList())).where((e) => e.isNotEmpty).reduce((v, e) => '$v,$e')}
    ],
    const <MirrorField<$classTypeName,MField,dynamic>>[
        ${clazz.fields.isEmpty ? '' : await (await Stream.fromFutures(clazz.fields.map((e) async => await _genCodeField(classTypeName, e, annTypeStrMaker, fieldTypeStrMaker, typeStrMaker, parser)).toList())).where((e) => e.isNotEmpty).reduce((v, e) => '$v,$e')}
    ],
    const <MirrorFunction<$classTypeName,MFunction,dynamic>>[
        ${clazz.functions.isEmpty ? '' : await (await Stream.fromFutures(clazz.functions.map((e) async => await _genCodeFunction(classTypeName, e, annTypeStrMaker, paramTypeStrMaker, returnTypeStrMaker, typeStrMaker, parser)).toList())).where((e) => e.isNotEmpty).reduce((v, e) => '$v,$e')}
    ],
  );
}
  ''';
}

///生成具体的注解
Future<String> _genCodeAnnotation(
  ConstantReader annotationValue,
  String Function(DartType type) typeStrMaker,
  AssetsTypeParser parser,
) =>
    _genAnnotation(annotationValue, typeStrMaker, parser);

///生成具体的注解信息
Future<String> _genAnnotation(
  ConstantReader reader,
  String Function(DartType type) typeStrMaker,
  AssetsTypeParser parser,
) async {
  if (reader == null || reader.isNull) return 'null';
  if (reader.isString) {
    return "'${reader.stringValue}'";
  } else if (reader.isDouble) {
    return '${reader.doubleValue}';
  } else if (reader.isInt) {
    return '${reader.intValue}';
  } else if (reader.isBool) {
    return '${reader.boolValue}';
  } else if (reader.isMap) {
    var mapContent = await Stream.fromFutures(reader.mapValue.entries.map(
        (e) async => MapEntry(
            await _genAnnotation(ConstantReader(e.key), typeStrMaker, parser),
            await _genAnnotation(
                ConstantReader(e.value), typeStrMaker, parser)))).toList();
    return '{${mapContent.map((e) => '${e.key}:${e.value}').join(',')}}';
  } else if (reader.isList) {
    var listContent = await Stream.fromFutures(reader.listValue.map(
            (e) => _genAnnotation(ConstantReader(e), typeStrMaker, parser)))
        .toList();
    return '[${listContent.join(',')}]';
  } else if (reader.isSet) {
    var setContent = await Stream.fromFutures(reader.setValue.map(
            (e) => _genAnnotation(ConstantReader(e), typeStrMaker, parser)))
        .toList();
    return '{${setContent.join(',')}}';
  } else if (reader.isType) {
    return typeStrMaker.call(reader.typeValue);
  } else {
    Log.log('_genAnnotation ${reader.objectValue.type}');
    final element =
        reader.objectValue.type.element ?? reader.objectValue.toFunctionValue();

    if (element is FunctionElement) {
      var as = typeStrMaker.call(element.type);
      return '$as';
    } else if (element is MethodElement && element.isStatic) {
      var result = '';
      result += typeStrMaker.call(await parser.call(element.librarySource.uri
          .replace(fragment: element.enclosingElement.name)));
      result += '.${element.name}';
      return result;
    } else {
      var result = '';
      var revive = reader.revive();
      var pArgs = revive?.positionalArguments ?? [];
      var namedArgs = revive?.namedArguments ?? {};
      var accessor = revive?.accessor ?? '';
      if (revive == null) return result;
      if (accessor.isNotEmpty) {
        result += '.$accessor';
      }
      var type = await parser.call(revive.source);
      result += typeStrMaker.call(type);
      // Log.log('_genAnnotation $result $namedArgs');
      result += '(';
      var argsStream = Stream.fromFutures(pArgs.map((e) async =>
          await _genAnnotation(ConstantReader(e), typeStrMaker, parser)));
      var argsS = await argsStream.toList();
      argsS.forEach((element) {
        result += element;
        result += ',';
      });
      // await pArgs.forEach((element) async {
      //   result +=
      //       '${await _genAnnotation(ConstantReader(element), typeStrMaker, parser)},';
      // });

      var namedArgsStream = Stream.fromFutures(namedArgs.entries.map((e) async =>
          '${e.key}:${await _genAnnotation(ConstantReader(e.value), typeStrMaker, parser)}'));

      var namedArgsS = await namedArgsStream.toList();
      namedArgsS.forEach((element) {
        result += element;
        result += ',';
      });
      // await namedArgs.forEach((key, value) async {
      //   result +=
      //       '$key:${await _genAnnotation(ConstantReader(value), typeStrMaker, parser)},';
      // });
      result += ')';
      return result;
    }
  }
}

///生成函数信息
Future<FutureOr<String>> _genCodeConstructor(
  String classTypeName,
  GConstructor constructor,
  String Function(ConstantReader param) annTypeStrMaker,
  String Function(GParam param) paramTypeStrMaker,
  String Function(DartType type) typeStrMaker,
  AssetsTypeParser parser,
) async {
  if (constructor == null) {
    return '';
  }

  var annotation = constructor.annotationValue;
  var annotationClass = constructor.annotationIsNull
      ? 'MConstructor'
      : annTypeStrMaker.call(constructor.annotationValue);

  return '''
  MirrorConstructor<$classTypeName,$annotationClass>(
   const ${constructor.annotationIsNull ? '$annotationClass()' : await _genCodeAnnotation(annotation, typeStrMaker, parser)},
    '${constructor.element.name}',
   const <MirrorParam>[
      ${constructor.params.isEmpty ? '' : await (await Stream.fromFutures(constructor.params.map((e) async => await _genCodeParam(e, annTypeStrMaker, paramTypeStrMaker, typeStrMaker, parser)).toList())).where((e) => e.isNotEmpty).reduce((v, e) => '$v,$e')}
    ],
    newInstance${capitalize(constructor.namedConstructorInKey)},
  )
  '''
      .trim();

  // ${_genCodeConstructorInvoker(classTypeName, constructor, paramTypeStrMaker, classTypeName)},
}

///生成属性信息
FutureOr<String> _genCodeField(
  String classTypeName,
  GField field,
  String Function(ConstantReader param) annTypeStrMaker,
  String Function(GField param) fieldTypeStrMaker,
  String Function(DartType type) typeStrMaker,
  AssetsTypeParser parser,
) async {
  if (field == null) {
    return '';
  }
  var annotationClass = field.annotationIsNull
      ? 'MField'
      : annTypeStrMaker.call(field.annotationValue);
  var fieldTypeStr = fieldTypeStrMaker.call(field);
  return '''
    MirrorField<$classTypeName,${annotationClass},${fieldTypeStr}>(
   const ${field.annotationIsNull ? '$annotationClass()' : await _genCodeAnnotation(field.annotationValue, typeStrMaker, parser)},
    '${field.element.name}',
    ${field.element.getter == null ? 'null' : 'get${capitalize(field.fieldName)}'},
    ${field.element.setter == null ? 'null' : 'set${capitalize(field.fieldName)}'},
  )
  '''
      .trim();
  // ${field.element.getter == null ? 'null' : _genCodeFieldGetInvoker(classTypeName, field, fieldTypeStr)},
  // ${field.element.setter == null ? 'null' : _genCodeFieldSetInvoker(classTypeName, field, fieldTypeStr)},
}

///生成函数信息
Future<FutureOr<String>> _genCodeFunction(
  String classTypeName,
  GFunction function,
  String Function(ConstantReader param) annTypeStrMaker,
  String Function(GParam param) paramTypeStrMaker,
  String Function(GFunction param) returnTypeStrMaker,
  String Function(DartType type) typeStrMaker,
  AssetsTypeParser parser,
) async {
  if (function == null) {
    return '';
  }

  var returnTypeStr = returnTypeStrMaker.call(function);

  var annotation = function.annotationValue;
  var annotationClass = function.annotationIsNull
      ? 'MConstructor'
      : annTypeStrMaker.call(function.annotationValue);

  return '''
    MirrorFunction<$classTypeName,$annotationClass,${returnTypeStr}>(
    const ${function.annotationIsNull ? '$annotationClass()' : await _genCodeAnnotation(annotation, typeStrMaker, parser)},
    '${function.element.name}',
    const <MirrorParam>[
      ${function.params.isEmpty ? '' : await (await Stream.fromFutures(function.params.map((e) async => await _genCodeParam(e, annTypeStrMaker, paramTypeStrMaker, typeStrMaker, parser)).toList())).where((e) => e.isNotEmpty).reduce((v, e) => '$v,$e')}
    ],
    invoke${capitalize(function.functionName)},
    fun${capitalize(function.functionName)},
  )
  '''
      .trim();
  // ${_genCodeFunctionInvoker(classTypeName, function, paramTypeStrMaker, returnTypeStr)},
  // ${_genCodeFunctionInstance(classTypeName, function)},
}

///生成函数的参数信息
FutureOr<String> _genCodeParam(
  GParam param,
  String Function(ConstantReader param) annTypeStrMaker,
  String Function(GParam param) paramTypeStrMaker,
  String Function(DartType type) typeStrMaker,
  AssetsTypeParser parser,
) async {
  if (param == null) {
    return '';
  }
  var annotationClass = param.annotationIsNull
      ? 'MParam'
      : annTypeStrMaker.call(param.annotationValue);
  return '''
  MirrorParam<$annotationClass,${paramTypeStrMaker.call(param)}>(
    const ${param.annotationIsNull ? '$annotationClass()' : await _genCodeAnnotation(param.annotationValue, typeStrMaker, parser)},
    '${param.element.name}', 
    ${param.element.isNamed ? 'true' : 'false'}
  )
  '''
      .trim();
}
//
// ///生成构造函数的代理执行器
// String _genCodeConstructorInvoker(
//     String classTypeName,
//     GConstructor constructor,
//     String Function(GParam param) maker,
//     String returnTypeStr) {
//   if (constructor == null) return '';
//   var named = constructor.element.name;
//   var CMD = named.isEmpty
//       ? 'return $classTypeName'
//       : 'return $classTypeName.${named}';
//   if (constructor.isConstructorArgMap) {
//     return '''
//    (Map<String, dynamic> params) {
//      ${_genCodeFunctionInvokerBody(CMD, constructor.params, [
//       'params'
//     ], cmdAfter: [])}
//    }
//   ''';
//   }
//
//   return '''
//    (Map<String, dynamic> params) {
//      ${_genCodeFunctionInvokerForMapParamsSwitch(CMD, constructor.params, 'params', '''
//         throw new IllegalArgumentException(${classTypeName},
//             '${constructor.element.name}',
//             [${constructor.params.map((e) => "Pair('${e.paramKey}',MagicMirror.genType<${maker.call(e)}>())").fold('', (p, e) => p == '' ? e : "$p,$e")}],
//             params.entries.map((e)=>Pair(e.key, e.value.runtimeType)).toList());
//      ''', maker)}
//    }
//   ''';
// }
//
// ///生成属性的getter的代理执行器
// String _genCodeFieldGetInvoker(
//     String classTypeName, GField field, String fieldTypeStr) {
//   if (field == null) return '';
//   return '''
//    (${classTypeName} bean) => bean.${field.element.name}
//   ''';
// }
//
// ///生成属性的setter的代理执行器
// String _genCodeFieldSetInvoker(
//     String classTypeName, GField field, String fieldTypeStr) {
//   if (field == null) return '';
//   return '''
//   (${classTypeName} bean, dynamic  value) {
//       if (MagicMirror.hasTypeAdapterS2Value<${fieldTypeStr}>(value)) {
//         bean.${field.element.name} = MagicMirror.convertTypeS<${fieldTypeStr}>(value);
//       } else {
//         throw new IllegalArgumentException(${classTypeName},
//             '${field.element.name}',
//             [Pair('${field.element.name}', MagicMirror.genType<${fieldTypeStr}>())],
//             [Pair('${field.element.name}', value.runtimeType)]);
//       }
//   }
//   ''';
// }
//
// ///生成函数的代理执行器
// String _genCodeFunctionInvoker(String classTypeName, GFunction function,
//     String Function(GParam param) maker, String returnTypeStr) {
//   if (function == null) return '';
//   var CMD =
//       '${'Void' == returnTypeStr ? '' : 'return'} bean.${function.element.name}';
//   var cmdAfter =
//       'Void' == returnTypeStr ? <String>['return Void();'] : <String>[];
//
//   return '''
//    (${classTypeName} bean , Map<String, dynamic> params) {
//      ${_genCodeFunctionInvokerForMapParamsSwitch(
//     CMD,
//     function.params,
//     'params',
//     '''
//         throw new IllegalArgumentException(${classTypeName},
//             '${function.element.name}',
//             [${function.params.map((e) => "Pair('${e.paramKey}',MagicMirror.genType<${maker.call(e)}>())").fold('', (p, e) => p == '' ? e : "$p,$e")}],
//             params.entries.map((e)=>Pair(e.key, e.value.runtimeType)).toList());
//      ''',
//     maker,
//     cmdAfter: cmdAfter,
//   )}
//    }
//   ''';
// }
//
// ///生成直接获取函数对象函数的代理执行器
// String _genCodeFunctionInstance(String classTypeName, GFunction function) {
//   if (function == null) return '';
//   return '''
//    (${classTypeName} bean ) => bean.${function.element.displayName}
//   ''';
// }

///将函数名 属性名的首字母大写
String capitalize(String name) {
  return name == null || name.isEmpty
      ? ''
      : '${name[0].toUpperCase()}${name.substring(1)}';
}

///生成函数的调用判断逻辑
String _genCodeFunctionInvokerForMapParamsSwitch(
    String CMD,
    List<GParam> params,
    String paramsMapName,
    String finalElse,
    String Function(GParam param) maker,
    {List<String> cmdAfter = const []}) {
  if (params == null || params.isEmpty) {
    return _genCodeFunctionInvokerBody(CMD, [], [], cmdAfter: cmdAfter);
  }
  var paramsNamed = params.where((p) => p.element.isNamed).toList();
  var paramsNeed = params
      .where((p) => !p.element.isNamed)
      .map((p) => _IFGenerator(p, paramsMapName, maker, isSelect: true))
      .toList();

  var ifGenerators = _combination(paramsNamed, paramsMapName, maker);
  var ifsStr = ifGenerators
      .map((e) =>
          cloneList<_IFGenerator>(paramsNeed, (ifg) => ifg.clone())..addAll(e))
      .map((list) => _genCodeFunctionInvokerForMapNamedParamsSwitch(CMD, list,
          cmdAfter: cmdAfter))
      .where((str) => '' != str)
      .map((ifs) => ifs.trimRight().endsWith('}') ? '\n$ifs else ' : ifs)
      .fold('', (i, s) => '$i$s');

  if (ifsStr.trimRight().endsWith('else')) {
    ifsStr = ifsStr.substring(0, ifsStr.length - 6);
  }
  if (ifsStr.trimRight().endsWith('}')) {
    ifsStr += 'else {$finalElse}';
  }
  return (ifsStr);
}

///生成函数的调用判断逻辑
String _genCodeFunctionInvokerForMapNamedParamsSwitch(
    String CMD, List<_IFGenerator> params,
    {List<String> cmdAfter = const []}) {
  var values =
      params.where((ifg) => ifg.isSelect).map((ifg) => ifg.contentStr).toList();
  var wheres =
      params.map((e) => e.whereStr).fold('', (p, e) => '$p && $e').substring(3);
  return '''
  if (${wheres.trimRight().endsWith("&&") ? wheres.substring(0, wheres.length - 3) : wheres} ) {
    ${_genCodeFunctionInvokerBody(CMD, params.where((ifg) => ifg.isSelect).map((ifg) => ifg.param).toList(), values, cmdAfter: cmdAfter)} \n 
   }
  ''';
}

///生成函数的调用判断逻辑
String _genCodeFunctionInvokerBody(
    String CMD, List<GParam> params, List<String> values,
    {List<String> cmdAfter = const []}) {
  if (params.length != values.length) {
    throw Exception('_genCodeFunctionInvokerBody params.length!=values.length');
  }

  var codeBuffer = StringBuffer();
  codeBuffer.write('$CMD(');
  for (var i = 0; i < params.length; i++) {
    var param = params[i];
    var value = values[i];
    if (param.element.isNamed) {
      codeBuffer.write('${param.element.name}:$value');
    } else {
      codeBuffer.write('$value');
    }
    if (i < params.length - 1) {
      codeBuffer.write(',');
    }
  }
  codeBuffer.write(');');
  if (cmdAfter.isNotEmpty) {
    codeBuffer.write(cmdAfter.reduce((v, e) => v + e));
  }
  return codeBuffer.toString();
}

//相比穷举的快速生成方案 参考自来源https://zhenbianshu.github.io/2019/01/charming_alg_permutation_and_combination.html
List<List<_IFGenerator>> _combination(List<GParam> source, String paramsMapName,
    String Function(GParam param) maker) {
  var result = <List<_IFGenerator>>[];
  for (int l = 0, i = Math.pow(2, source.length) - 1; i >= l; i--) {
    var paras = cloneList(source, (s) => s)
        .map((p) => _IFGenerator(p, paramsMapName, maker))
        .toList();
    for (var j = 0, m = source.length - 1; j <= m; j++) {
      if ((i >> (m - j)) & 0x01 == 0x01) {
        paras[j].isSelect = true;
      }
    }
    result.add(paras);
  }

  return result;
}

///生成函数的调用判断逻辑  判断是否包含 以及后续处理
class _IFGenerator {
  ///判断的参数类型
  final GParam param;

  ///在map中的name
  final String paramsMapName;

  ///是否是已选模式
  bool isSelect;

  ///设定参数转换为string时的转换器
  final String Function(GParam param) makeParamTypeStr;

  _IFGenerator(this.param, this.paramsMapName, this.makeParamTypeStr,
      {this.isSelect = false});

  ///生成的where内容
  String get whereStr {
    if (!isSelect) return "!$paramsMapName.containsKey('${param.paramKey}')";
    var w =
        "($paramsMapName.containsKey('${param.paramKey}') && MagicMirror.hasTypeAdapterS2Value<${makeParamTypeStr.call(param)}>($paramsMapName['${param.paramKey}']))";
    return w;
  }

  ///生成的具体执行内容
  String get contentStr {
    if (!isSelect) return '';
    var c = '';
    c = "MagicMirror.convertTypeS($paramsMapName['${param.paramKey}'])";
    return c;
  }

  ///深clone
  _IFGenerator clone() {
    var r = _IFGenerator(param, paramsMapName, makeParamTypeStr,
        isSelect: isSelect);
    return r;
  }
}
