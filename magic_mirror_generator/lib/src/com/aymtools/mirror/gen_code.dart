import 'package:magic_mirror/mirror.dart';
import 'package:source_gen/source_gen.dart';
// ignore: library_prefixes
import 'dart:math' as Math;

import 'constants.dart';
import 'entities.dart';

class _GenImports {
  final GImports imports;

  _GenImports(this.imports);

  String classTypeStrMaker(GClass clazz) =>
      imports.getTypeNameAsStr(clazz.type.value);

  String paramTypeStrMaker(GParam param) =>
      imports.getTypeNameAsStr(param.type.value);

  String fieldTypeStrMaker(GField field) =>
      imports.getTypeNameAsStr(field.type.value);

  String returnTypeStrMaker(GFunction function) {
    var r = imports.getTypeNameAsStr(function.returnType.value);
    return 'void' == r ? 'Void' : r;
  }

  String annTypeStrMaker(ConstantReader ann) => ann == null || ann.isNull
      ? 'null'
      : imports.getTypeNameAsStr(ann.objectValue.type);

  String get importsValue => imports
      .getImports()
      .entries
      .map((e) => e.value.isEmpty
          ? "import '${e.key}' ;"
          : "import '${e.key}' as ${e.value} ;")
      .fold('', (p, e) => '$p$e');
}

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

String _genCodeMClass(MClass mClass) {
  if (mClass == null) return 'null';
  return '''
      MClass(
      ${_genCodeAnnBase(mClass)}
      keyGenType: ${mClass.keyGenType},
      needAssignableFrom: ${mClass.needAssignableFrom},
      anyOneAssignableFrom: ${mClass.anyOneAssignableFrom},
      scanConstructors: ${mClass.scanConstructors},
      scanConstructorsUsedBlackList: ${mClass.scanConstructorsUsedBlackList},
      scanMethods: ${mClass.scanMethods},
      scanMethodsUsedBlackList: ${mClass.scanMethodsUsedBlackList},
      scanSuperMethods: ${mClass.scanSuperMethods},
      scanFields: ${mClass.scanFields},
      scanFieldsUsedBlackList: ${mClass.scanFieldsUsedBlackList},
      scanSuperFields: ${mClass.scanSuperFields},
    )
  '''
      .trim();
}

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

String _genCodeMConstructor(MConstructor constructor) {
  if (constructor == null) return 'null';
  return '''
      MConstructor(
      ${_genCodeAnnBase(constructor)}
    )
  ''';
}

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

String _genCodeMField(MField field) {
  if (field == null) return 'null';
  return '''
      MField(
      ${_genCodeAnnBase(field)}
    )
  ''';
}

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
  )
  '''
      .trim();
}

String _genCodeMFunction(MFunction function) {
  if (function == null) return 'null';
  return '''
      MFunction(
      ${_genCodeAnnBase(function)}
    )
  ''';
}

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
    TypeToken<${paramTypeStrMaker.call(param)}>()
  )
  '''
      .trim();
}

String _genCodeMParam(MParam param) {
  if (param == null) return 'null';
  return '''
      MParam(
      ${_genCodeAnnBase(param)}
    )
  ''';
}

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
  return '''
   (Map<String, dynamic> params) {
     ${_genCodeFunctionInvokerForMapParamsSwitch(CMD, constructor.params, 'params', '''
        throw new IllegalArgumentException(${classTypeName},
            '${constructor.element.name}',
            [${constructor.params.map((e) => "Pair('${e.paramKey}',MagicMirror.genType<${maker.call(e)}>())").fold('', (p, e) => p == '' ? e : "$p,$e")}],
            params.entries.map((e)=>Pair(e.key, e.value.runtimeType)).toList());
     ''', maker)}
   }
  ''';
}

String _genCodeFieldGetInvoker(
    String classTypeName, GField field, String fieldTypeStr) {
  if (field == null) return '';
  return '''
   (${classTypeName} bean) => bean.${field.element.name}
  ''';
}

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

class _IFGenerator {
  final GParam param;
  final String paramsMapName;
  bool isSelect;

  final String Function(GParam param) makeParamTypeStr;

  _IFGenerator(this.param, this.paramsMapName, this.makeParamTypeStr,
      {this.isSelect = false});

  String get whereStr {
    if (!isSelect) return "!$paramsMapName.containsKey('${param.paramKey}')";
    var w =
        "($paramsMapName.containsKey('${param.paramKey}') && MagicMirror.hasTypeAdapterS2Value<${makeParamTypeStr.call(param)}>($paramsMapName['${param.paramKey}']))";
    return w;
  }

  String get contentStr {
    if (!isSelect) return '';
    var c = '';
    c = "MagicMirror.convertTypeS($paramsMapName['${param.paramKey}'])";
    return c;
  }

  _IFGenerator clone() {
    var r = _IFGenerator(param, paramsMapName, makeParamTypeStr,
        isSelect: isSelect);
    return r;
  }
}
