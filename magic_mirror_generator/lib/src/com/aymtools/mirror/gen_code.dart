import 'package:magic_mirror/mirror.dart';
import 'package:source_gen/source_gen.dart';

// ignore: library_prefixes
import 'dart:math' as Math;

import 'builder.dart';
import 'entities.dart';

///生成导入包的缓冲器
class _GenImports {
  final GImports imports;

  _GenImports(this.imports);

  ///类的类型转换为包含As的String
  String classTypeStrMaker(GClass clazz) =>
      imports.getTypeNameAsStr(clazz.type.value);

  ///类的类型转换为包含As的String
  String paramTypeStrMaker(GParam param) =>
      imports.getTypeNameAsStr(param.type.value);

  ///field的类型转换为包含As的String
  String fieldTypeStrMaker(GField field) =>
      imports.getTypeNameAsStr(field.type.value);

  ///returnType的类型转换为包含As的String
  String returnTypeStrMaker(GFunction function) {
    var r = imports.getTypeNameAsStr(function.returnType.value);
    return 'void' == r ? 'Void' : r;
  }

  ///注解的具体类型的类型转换为包含As的String
  String annTypeStrMaker(ConstantReader ann) => ann == null || ann.isNull
      ? 'null'
      : imports.getTypeNameAsStr(ann.objectValue.type);

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
import 'package:magic_mirror/mirror.dart';
${other.map((e) => "import '${e}' as ${imports.getUriAsNameStr(e.replaceAll('.mirror.aymtools', ''))}Register;").fold('', (p, v) => p + v)}
${_genCodeLibInfoMirrorRegisterTemplate([], true, otherStr)}
  ''';
}

///根据类包信息生成的注册器
String genMirrorLibInfoMirror(GLibraryInfo libraryInfo,
    {bool importOtherLib = false, GImports defImports}) {
  var imports = defImports ?? GImports();
  if (importOtherLib) {
    imports.addLibs(libraries.values.toList());
  }
  var genImport = _GenImports(imports);
  var content = genCodeLibInfoMirrorInfo(
      libraryInfo,
      genImport.annTypeStrMaker,
      genImport.classTypeStrMaker,
      genImport.paramTypeStrMaker,
      genImport.fieldTypeStrMaker,
      genImport.returnTypeStrMaker);
  var importsValue = genImport.importsValue;
  var register = _genCodeLibInfoMirrorRegister(libraryInfo.classes,
      imports.getLibInfoAsNameStr(libraryInfo), genImport.classTypeStrMaker);
  return importsValue + content + register;
}

///生成project所有的引用类库的注册信息
String genMirrorImplementation(List<GLibrary> implementations) {
  var imports = GImports(otherImportLibrary: implementations);
  var genImport = _GenImports(imports);
  var content = implementations
      .expand((element) => element.libs)
      .map((e) => genCodeLibInfoMirrorInfo(
          e,
          genImport.annTypeStrMaker,
          genImport.classTypeStrMaker,
          genImport.paramTypeStrMaker,
          genImport.fieldTypeStrMaker,
          genImport.returnTypeStrMaker))
      .toList();
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
String genCodeMirrorInfo(GLibrary library) {
  var imports = GImports(otherImportLibrary: libraries.values.toList());
  var genImport = _GenImports(imports);
  var content = library.libs
      .map((e) => genCodeLibInfoMirrorInfo(
          e,
          genImport.annTypeStrMaker,
          genImport.classTypeStrMaker,
          genImport.paramTypeStrMaker,
          genImport.fieldTypeStrMaker,
          genImport.returnTypeStrMaker))
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
  String Function(GClass param) classTypeStrMaker,
) {
  var classes = <String>[];
  libraryClass.forEach((clazz) {
    classes.add(classTypeStrMaker.call(clazz).replaceAll('.', ''));
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
  List<MirrorClass> classInfos() => <MirrorClass>${classes.isEmpty ? '[]' : classes.map((e) => 'mirror$e').toList()};

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
String genCodeLibInfoMirrorInfo(
    GLibraryInfo library,
    String Function(ConstantReader param) annTypeStrMaker,
    String Function(GClass param) classTypeStrMaker,
    String Function(GParam param) paramTypeStrMaker,
    String Function(GField param) fieldTypeStrMaker,
    String Function(GFunction param) returnTypeStrMaker) {
  return library.classes
      .map((e) => _genCodeClassMirrorInfo(e, annTypeStrMaker, classTypeStrMaker,
          paramTypeStrMaker, fieldTypeStrMaker, returnTypeStrMaker))
      .where((element) => element.isNotEmpty)
      .fold('', (previousValue, element) => '$previousValue$element');
}

///生成具体的类信息
String _genCodeClassMirrorInfo(
    GClass clazz,
    String Function(ConstantReader param) annTypeStrMaker,
    String Function(GClass param) classTypeStrMaker,
    String Function(GParam param) paramTypeStrMaker,
    String Function(GField param) fieldTypeStrMaker,
    String Function(GFunction param) returnTypeStrMaker) {
  var classTypeName = classTypeStrMaker.call(clazz);
  var className = classTypeName.replaceAll('.', '');
  var annotationClass = annTypeStrMaker.call(clazz.annotationValue);

  return '''
 final mirror$className = MirrorClass<$classTypeName>(
    '${clazz.key}',
    ${_genCodeMClass(clazz.annotation)},
    TypeToken<${annotationClass}>(),
    TypeToken<$classTypeName>(),
    '${clazz.element.displayName}',
    <MirrorConstructor<$classTypeName>>[
        ${clazz.constructors.isEmpty ? '' : clazz.constructors.map((e) => _genCodeConstructor(classTypeName, e, annTypeStrMaker, paramTypeStrMaker)).where((e) => e.isNotEmpty).reduce((v, e) => '$v,$e')}
    ],
    <MirrorField<$classTypeName,dynamic>>[
        ${clazz.fields.isEmpty ? '' : clazz.fields.map((e) => _genCodeField(classTypeName, e, annTypeStrMaker, fieldTypeStrMaker)).where((e) => e.isNotEmpty).reduce((v, e) => '$v,$e')}
    ],
    <MirrorFunction<$classTypeName,dynamic>>[
        ${clazz.functions.isEmpty ? '' : clazz.functions.map((e) => _genCodeFunction(classTypeName, e, annTypeStrMaker, paramTypeStrMaker, returnTypeStrMaker)).where((e) => e.isNotEmpty).reduce((v, e) => '$v,$e')}
    ],
  );
  ''';
}

///生成具体的注解的base信息
String _genCodeAnnBase(AnnBase ann) {
  return ''' 
      key: '${ann.key}',
      tag: '${ann.tag}',
      ext: ${ann.ext},
      flag: ${ann.flag},
      tag1: '${ann.tag1}',
      ext1: ${ann.ext1},
      flag1: ${ann.flag1},
      tagList: const [${ann.tagList.isEmpty ? '' : ann.tagList.map((e) => "'e'").reduce((v, e) => '$v,$e')}],
      extList: const [${ann.extList.isEmpty ? '' : ann.extList.map((e) => e.toString()).reduce((v, e) => '$v,$e')}],
  ''';
}

///生成具体的类注解信息
String _genCodeMClass(MClass mClass) {
  if (mClass == null) return 'null';
  return '''
      MClass(
      ${_genCodeAnnBase(mClass)}
      keyGenType: ${mClass.keyGenType},
      needAssignableFrom: ${mClass.needAssignableFrom},
      anyOneAssignableFrom: ${mClass.anyOneAssignableFrom},
      scanConstructors: ${mClass.scanConstructors},
      scanConstructorsUsedBlockList: ${mClass.scanConstructorsUsedBlockList},
      scanFunctions: ${mClass.scanFunctions},
      scanFunctionsUsedBlockList: ${mClass.scanFunctionsUsedBlockList},
      scanSuperFunctions: ${mClass.scanSuperFunctions},
      scanFields: ${mClass.scanFields},
      scanFieldsUsedBlockList: ${mClass.scanFieldsUsedBlockList},
      scanSuperFields: ${mClass.scanSuperFields},
    )
  '''
      .trim();
}

///生成函数信息
String _genCodeConstructor(
    String classTypeName,
    GConstructor constructor,
    String Function(ConstantReader param) annTypeStrMaker,
    String Function(GParam param) paramTypeStrMaker) {
  if (constructor == null) {
    return '';
  }

  var annotationClass = constructor.annotationIsNull
      ? 'MConstructor'
      : annTypeStrMaker.call(constructor.annotationValue);
  return '''
  MirrorConstructor<$classTypeName>(
    ${constructor.annotationIsNull ? '$annotationClass()' : _genCodeMConstructor(constructor.annotation)},
    TypeToken<${annotationClass}>(),
    '${constructor.element.name}',
    <MirrorParam>[
      ${constructor.params.isEmpty ? '' : constructor.params.map((e) => _genCodeParam(e, annTypeStrMaker, paramTypeStrMaker)).where((e) => e.isNotEmpty).reduce((v, e) => '$v,$e')}
    ],
    ${_genCodeConstructorInvoker(classTypeName, constructor, paramTypeStrMaker, classTypeName)},
  )
  '''
      .trim();
}

///生成函数的注解信息
String _genCodeMConstructor(MConstructor constructor) {
  if (constructor == null) return 'null';
  return '''
      MConstructor(
      ${_genCodeAnnBase(constructor)}
    )
  ''';
}

///生成属性信息
String _genCodeField(
    String classTypeName,
    GField field,
    String Function(ConstantReader param) annTypeStrMaker,
    String Function(GField param) fieldTypeStrMaker) {
  if (field == null) {
    return '';
  }
  var annotationClass = field.annotationIsNull
      ? 'MField'
      : annTypeStrMaker.call(field.annotationValue);
  var fieldTypeStr = fieldTypeStrMaker.call(field);
  return '''
    MirrorField<$classTypeName,${fieldTypeStr}>(
    ${field.annotationIsNull ? '$annotationClass()' : _genCodeMField(field.annotation)},
    TypeToken<${annotationClass}>(),
    '${field.element.name}',
    TypeToken<${fieldTypeStr}>(),
    ${field.element.getter == null ? 'null' : _genCodeFieldGetInvoker(classTypeName, field, fieldTypeStr)},
    ${field.element.setter == null ? 'null' : _genCodeFieldSetInvoker(classTypeName, field, fieldTypeStr)},
  )
  '''
      .trim();
}

///生成属性的注解信息
String _genCodeMField(MField field) {
  if (field == null) return 'null';
  return '''
      MField(
      ${_genCodeAnnBase(field)}
    )
  ''';
}

///生成函数信息
String _genCodeFunction(
    String classTypeName,
    GFunction function,
    String Function(ConstantReader param) annTypeStrMaker,
    String Function(GParam param) paramTypeStrMaker,
    String Function(GFunction param) returnTypeStrMaker) {
  if (function == null) {
    return '';
  }
  var annotationClass = function.annotationIsNull
      ? 'MFunction'
      : annTypeStrMaker.call(function.annotationValue);
  var returnTypeStr = returnTypeStrMaker.call(function);
  return '''
    MirrorFunction<$classTypeName,${returnTypeStr}>(
    ${function.annotationIsNull ? '$annotationClass()' : _genCodeMFunction(function.annotation)},
    TypeToken<${annotationClass}>(),
    '${function.element.name}',
    <MirrorParam>[
      ${function.params.isEmpty ? '' : function.params.map((e) => _genCodeParam(e, annTypeStrMaker, paramTypeStrMaker)).where((e) => e.isNotEmpty).reduce((v, e) => '$v,$e')}
    ],
    TypeToken<${returnTypeStr}>(),
    ${_genCodeFunctionInvoker(classTypeName, function, paramTypeStrMaker, returnTypeStr)},
    ${_genCodeFunctionInstance(classTypeName, function)},
  )
  '''
      .trim();
}

///生成函数的注解信息
String _genCodeMFunction(MFunction function) {
  if (function == null) return 'null';
  return '''
      MFunction(
      ${_genCodeAnnBase(function)}
    )
  ''';
}

///生成函数的参数信息
String _genCodeParam(
    GParam param,
    String Function(ConstantReader param) annTypeStrMaker,
    String Function(GParam param) paramTypeStrMaker) {
  if (param == null) {
    return '';
  }
  var annotationClass = param.annotationIsNull
      ? 'MParam'
      : annTypeStrMaker.call(param.annotationValue);
  return '''
  MirrorParam(
    ${param.annotationIsNull ? '$annotationClass()' : _genCodeMParam(param.annotation)},
    TypeToken<${annotationClass}>(), 
    '${param.element.name}', 
    TypeToken<${paramTypeStrMaker.call(param)}>(),
    ${param.element.isNamed ? 'true' : 'false'}
  )
  '''
      .trim();
}

///生成函数的参数注解信息
String _genCodeMParam(MParam param) {
  if (param == null) return 'null';
  return '''
      MParam(
      ${_genCodeAnnBase(param)}
    )
  ''';
}

///生成构造函数的代理执行器
String _genCodeConstructorInvoker(
    String classTypeName,
    GConstructor constructor,
    String Function(GParam param) maker,
    String returnTypeStr) {
  if (constructor == null) return '';
  var named = constructor.element.name;
  var CMD = named.isEmpty
      ? 'return $classTypeName'
      : 'return $classTypeName.${named}';
  if (constructor.isConstructorArgMap) {
    return '''
   (Map<String, dynamic> params) {
     ${_genCodeFunctionInvokerBody(CMD, constructor.params, [
      'params'
    ], cmdAfter: [])}
   }
  ''';
  }

  return '''
   (Map<String, dynamic> params) {
   
   //${constructor.isConstructorArgMap}
   //${constructor.annotationIsNull}
   //${constructor.params.length != 1 ? '略过' : constructor.params[0].element.isNamed || constructor.params[0].annotationIsNull || constructor.params[0].annotation.key.isNotEmpty}
   //${constructor.params.length != 1 ? '略过' : constructor.params[0].type.value.isDartCoreMap}
   
   
     ${_genCodeFunctionInvokerForMapParamsSwitch(CMD, constructor.params, 'params', '''
        throw new IllegalArgumentException(${classTypeName},
            '${constructor.element.name}',
            [${constructor.params.map((e) => "Pair('${e.paramKey}',MagicMirror.genType<${maker.call(e)}>())").fold('', (p, e) => p == '' ? e : "$p,$e")}],
            params.entries.map((e)=>Pair(e.key, e.value.runtimeType)).toList());
     ''', maker)}
   }
  ''';
}

///生成属性的getter的代理执行器
String _genCodeFieldGetInvoker(
    String classTypeName, GField field, String fieldTypeStr) {
  if (field == null) return '';
  return '''
   (${classTypeName} bean) => bean.${field.element.name}
  ''';
}

///生成属性的setter的代理执行器
String _genCodeFieldSetInvoker(
    String classTypeName, GField field, String fieldTypeStr) {
  if (field == null) return '';
  return '''
  (${classTypeName} bean, dynamic  value) {
      if (MagicMirror.hasTypeAdapterS2Value<${fieldTypeStr}>(value)) {
        bean.${field.element.name} = MagicMirror.convertTypeS<${fieldTypeStr}>(value);
      } else {
        throw new IllegalArgumentException(${classTypeName},
            '${field.element.name}',
            [Pair('${field.element.name}', MagicMirror.genType<${fieldTypeStr}>())],
            [Pair('${field.element.name}', value.runtimeType)]);
      }
  }
  ''';
}

///生成函数的代理执行器
String _genCodeFunctionInvoker(String classTypeName, GFunction function,
    String Function(GParam param) maker, String returnTypeStr) {
  if (function == null) return '';
  var CMD =
      '${'Void' == returnTypeStr ? '' : 'return'} bean.${function.element.name}';
  var cmdAfter =
      'Void' == returnTypeStr ? <String>['return Void();'] : <String>[];

  return '''
   (${classTypeName} bean , Map<String, dynamic> params) {
     ${_genCodeFunctionInvokerForMapParamsSwitch(
    CMD,
    function.params,
    'params',
    '''
        throw new IllegalArgumentException(${classTypeName},
            '${function.element.name}',
            [${function.params.map((e) => "Pair('${e.paramKey}',MagicMirror.genType<${maker.call(e)}>())").fold('', (p, e) => p == '' ? e : "$p,$e")}],
            params.entries.map((e)=>Pair(e.key, e.value.runtimeType)).toList());
     ''',
    maker,
    cmdAfter: cmdAfter,
  )}
   }
  ''';
}

///生成直接获取函数对象函数的代理执行器
String _genCodeFunctionInstance(String classTypeName, GFunction function) {
  if (function == null) return '';
  return '''
   (${classTypeName} bean ) => bean.${function.element.displayName}
  ''';
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
