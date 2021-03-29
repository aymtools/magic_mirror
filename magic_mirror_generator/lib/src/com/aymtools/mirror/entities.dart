import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:magic_mirror/magic_mirror.dart';
import 'package:source_gen/source_gen.dart';

import 'tools.dart';

///用来生成执行类时自动计入的需要的导入包
class GImports {
  final Set<GLibrary> _otherImportLibrary = {};

  final Map<String, String> _imports = {};

  ///默认加入的lib库
  GImports({List<GLibrary> otherImportLibrary = const []}) {
    if (otherImportLibrary.isNotEmpty) {
      addLibs(otherImportLibrary);
    }
  }

  ///添加默认加入的lib库
  void addLibs(List<GLibrary> otherImportLibrary) {
    _otherImportLibrary.addAll(otherImportLibrary);

    _imports['package:magic_mirror/magic_mirror.dart'] = '';
    if (_otherImportLibrary.isNotEmpty) {
      _otherImportLibrary
          .where((element) => !element.isMirrorLib)
          .forEach((lib) {
        _imports['package:${lib.package}/${lib.name}.dart'] = '${lib.asName}';
      });
    }
    _otherImportLibrary
        .expand((element) => element.libs)
        .where((element) =>
            element.classes.isNotEmpty || element.functions.isNotEmpty)
        .forEach((element) {
      _parseAddImportLib(element.lib);
      element.classes.forEach((cls) {
        if (!cls.annotationValue.isNull) {
          _parseAddImportLib(
              cls.annotationValue.objectValue.type!.element?.library);
        }
        cls.constructors.forEach((constructor) {
          if (!constructor.annotationValue.isNull) {
            _parseAddImportLib(
                constructor.annotationValue.objectValue.type!.element?.library);
          }
          constructor.params.forEach((param) {
            if (!param.annotationValue.isNull) {
              _parseAddImportLib(
                  param.annotationValue.objectValue.type!.element?.library);
            }
            _parseTypeAndInnerType(param.type.value);
          });
        });
        cls.fields.forEach((field) {
          if (!field.annotationValue.isNull) {
            _parseAddImportLib(
                field.annotationValue.objectValue.type!.element?.library);
          }
          _parseTypeAndInnerType(field.type.value);
        });
        cls.functions.forEach((function) {
          if (!function.annotationValue.isNull) {
            _parseAddImportLib(
                function.annotationValue.objectValue.type!.element?.library);
          }
          _parseTypeAndInnerType(function.returnType.value);
          function.params.forEach((param) {
            if (!param.annotationValue.isNull) {
              _parseAddImportLib(
                  param.annotationValue.objectValue.type!.element?.library);
            }
            _parseTypeAndInnerType(param.type.value);
          });
        });
      });
    });
  }

  ///获取扫描到的结果
  Map<String, String> getImports({bool usedCache = true}) {
    return _imports;
  }

  ///解析并加入结果
  String _parseTypeAndInnerType(DartType type) {
    if (type.isDynamic) {
      return 'dynamic';
    }
    if (type.isVoid) {
      return 'void';
    }
    var libAs = isDartCoreType(type)
        ? ''
        : _parseAddImportLib(type.element!.library).value;

    var t = type;
    var ts = <String>[];
    var name = type.element?.name ?? '';
    if (t is ParameterizedType) {
      ts = t.typeArguments.map((e) => _parseTypeAndInnerType(e)).toList();
      if (ts.isNotEmpty) {
        var args = ts.reduce((v, e) => '$v,$e');
        name = '$name<$args>';
      }
    }

    return libAs.isEmpty ? name : '$libAs.${name}';
  }

  ///加入的结果的格式化
  String _formatAsStr(String uri) {
    if ('' == uri || !uri.endsWith('.dart')) return uri;
    var asStr = uri
        .substring(0, uri.length - 5)
        .replaceAll('/', '_')
        .replaceFirst('package:', '')
        .replaceAllMapped(
            RegExp(r'_\w'), (match) => match.group(0)!.toUpperCase())
        .replaceAll('_', '');
    if (asStr.contains('.')) {
      asStr = asStr
          .replaceAllMapped(
              RegExp(r'\.\w'), (match) => match.group(0)!.toUpperCase())
          .replaceAll('.', '');
    }
    // if (asStr.length > 1) {
    //   asStr = asStr[0].toUpperCase() + asStr.substring(1);
    // }
    var i = 0;
    var asStrTemp = asStr;
    while (_imports.containsValue(asStrTemp)) {
      i++;
      asStrTemp = '${asStr}\$$i';
    }
    return asStrTemp;
  }

  ///解析并加入结果
  MapEntry<String, String> _parseAddImportLib(LibraryElement? lib) {
    if (lib == null) return MapEntry('', '');
    MapEntry<String, String>? r;
    _otherImportLibrary
        .where((element) => element.lib != null)
        .forEach((element) {
      if (element.isInLib(lib)) {
        if (element.isMirrorLib) {
          r = MapEntry('package:${element.package}/${element.name}.dart', '');
        } else {
          r = MapEntry('package:${element.package}/${element.name}.dart',
              element.asName);
        }
      }
    });
    return r ?? _parseAddImports(lib.librarySource.uri.toString());
  }

  ///解析并加入结果
  MapEntry<String, String> _parseAddImports(String librarySourceUriStr) {
    if ('dart.core' == librarySourceUriStr ||
        librarySourceUriStr.startsWith('dart:')) {
      return MapEntry('', '');
    }
    if ('' == librarySourceUriStr || !librarySourceUriStr.endsWith('.dart')) {
      return MapEntry(librarySourceUriStr, librarySourceUriStr);
    }
    if (librarySourceUriStr.startsWith('package:magic_mirror')) {
      return MapEntry('', '');
    }
    if (!_imports.containsKey(librarySourceUriStr)) {
      var asStr = _formatAsStr(librarySourceUriStr);
      _imports[librarySourceUriStr] = asStr;
    }
    return MapEntry(librarySourceUriStr, _imports[librarySourceUriStr] ?? '');
  }

  ///解析并加入结果 根据DartType
  String getTypeNameAsStr(DartType type) {
    return _parseTypeAndInnerType(type);
  }

  ///解析并加入结果 根据GLibrary
  String getLibAsNameStr(GLibrary library) => _formatAsStr(
      '${library.asName.isEmpty ? library.name : library.asName}.dart');

  ///解析并加入结果 根据GLibraryInfo
  String getLibInfoAsNameStr(GLibraryInfo library) =>
      _formatAsStr(library.lib.source.uri.toString());

  ///解析并加入结果 根据类的library uri信息
  String getUriAsNameStr(String uriStr) => _formatAsStr(uriStr);
}

///扫描到的类库
class GLibrary {
  ///类库的package
  final String package;

  ///类库的name dartFileName
  final String name;

  ///类库的name library name
  final String asName;

  ///类库的类信息 dartFileName转换的来
  final LibraryElement? lib;

  ///类库中所有的类包信息
  final List<GLibraryInfo> _libs = [];

  GLibrary(this.package, this.name, this.asName,
      {this.lib, List<GLibraryInfo> libs = const []}) {
    if (libs.isNotEmpty) _libs.addAll(libs);
  }

  ///添加类包信息
  void addGLibraryInfo(GLibraryInfo info) {
    removeLib(info.uriStr);
    if (info.isNotEmpty) {
      _libs.add(info);
    }
  }

  //移除类包信息
  bool removeLib(String libUriStr) {
    var infoOld =
        findFistWhere<GLibraryInfo>(_libs, (e) => libUriStr == e.uriStr);
    if (infoOld != null) {
      _libs.remove(infoOld);
      return true;
    }
    return false;
  }

  ///判断是否在当前库中
  bool isInLib(Element element) {
    return lib == null
        ? false
        : lib!.exportedLibraries.contains(element.library);
  }

  ///是否时魔镜自身的库
  bool get isMirrorLib => 'magic_mirror' == package;

  ///判断是否时当前执行环境的paoject库
  bool get isProjectLib => (asName.isEmpty) && lib == null;

  ///获取所有的类库信息
  List<GLibraryInfo> get libs => _libs;
}

///类库信息
class GLibraryInfo {
  ///类库信息的扫描对象
  final LibraryElement lib;

  ///所有扫描到的类信息
  final List<GClass> classes;

  ///所有扫描到的函数信息
  final List<GFunction> functions;

  GLibraryInfo(this.lib, this.classes, this.functions);

  ///获取类库对应的uri信息
  String get uriStr => lib.librarySource.uri.toString();

  ///判断当前类库中是否含有扫描到的内容
  bool get isNotEmpty => classes.isNotEmpty;
}

///扫描到的类型
class GType {
  ///类型的具体对象
  final Element? element;

  ///对应的类型的dartType
  final DartType value;

  GType(this.element, this.value);
}

///扫描到的类信息
class GClass {
  ///依据的key uri类型
  final String key;

  ///扫描到的类对象的具体对象
  final ClassElement element;

  ///扫描时的注解信息
  // final MClass annotation;

  ///扫描时的注解信息 原始信息
  final ConstantReader annotationValue;

  ///类的具体type
  final GType type;

  ///所有的扫描到的构造函数
  final List<GFunction> functions;

  ///所有的扫描到的属性
  final List<GField> fields;

  ///所有的扫描到的构造函数
  final List<GConstructor> constructors;

  GClass(this.key, this.element, ConstantReader? annotationValue,
      this.constructors, this.fields, this.functions)
      : type = GType(element, element.thisType),
        this.annotationValue = annotationValue ?? ConstantReader(null);

  ///判断注解信息是否为空
  bool get annotationIsNull => annotationValue.isNull;
}

///扫描到的类的构造函数信息
class GConstructor {
  ///扫描到的类的构造函数的具体信息
  final ConstructorElement element;

  ///扫描时的注解信息
  // final MConstructor annotation;

  ///扫描时的注解信息 原始信息
  final ConstantReader annotationValue;

  ///函数所需要的参数信息
  final List<GParam> params;

  GConstructor(this.element, ConstantReader? annotationValue, this.params)
      : this.annotationValue = annotationValue ?? ConstantReader(null);

  ///获取构造函数的具体key 依据注解和name生成
  String get namedConstructorInKey {
    return annotationIsNull ||
            annotationValue.peek('key') == null ||
            annotationValue.peek('key')!.isNull ||
            annotationValue.peek('key')!.stringValue.isEmpty
        ? element.name
        : annotationValue.peek('key')!.stringValue;
  }

  ///是否时默认构造函数
  bool get isDefConstructor => element.name.isEmpty;

  ///判断注解信息是否为空
  bool get annotationIsNull => annotationValue.isNull;

// bool _isConstructorArgMap;

// //判断构造函数的参数是map的 特殊的构造函数
// bool get isConstructorArgMap {
//   if (_isConstructorArgMap != null) return _isConstructorArgMap;
//   if (annotationIsNull) {
//     return _isConstructorArgMap = false;
//   }
//   if (params.length != 1) {
//     return _isConstructorArgMap = false;
//   }
//   var p = params[0];
//   if (p.element.isNamed || !p.annotationIsNull) {
//     return _isConstructorArgMap = false;
//   }
//   var type = p.type.value;
//   if (!type.isDartCoreMap) {
//     return _isConstructorArgMap = false;
//   }
//   var pt = type as ParameterizedType;
//   if (pt.typeArguments[0].isDartCoreString &&
//       pt.typeArguments[1].isDynamic &&
//       _constructorMapArgCheck.hasAnnotationOf(element)) {
//     return _isConstructorArgMap = true;
//   }
//   return _isConstructorArgMap = false;
// }
}

///扫描到的函数信息
class GFunction {
  ///扫描到的类的函数的具体信息
  final MethodElement element;

  ///扫描时的注解信息
  // final MFunction annotation;

  ///扫描时的注解信息 原始信息
  final ConstantReader annotationValue;

  ///函数所需要的参数信息
  final List<GParam> params;

  ///函数的返回类型
  final GType returnType;

  GFunction(this.element, ConstantReader? annotationValue, this.params)
      : returnType = GType(element.returnType.element, element.returnType),
        this.annotationValue = annotationValue ?? ConstantReader(null);

  ///获取函数的具体key 依据注解和name生成
  String get functionName => annotationIsNull ||
          annotationValue.peek('key') == null ||
          annotationValue.peek('key')!.isNull ||
          annotationValue.peek('key')!.stringValue.isEmpty
      ? element.name
      : annotationValue.peek('key')!.stringValue;

  ///判断注解信息是否为空
  bool get annotationIsNull => annotationValue.isNull;

  ///是否是空安全 切不能赋值null
  bool get returnTypeIsNonNullable =>
      element.type.nullabilitySuffix == NullabilitySuffix.none;
}

///扫描到的属性信息
class GField {
  ///扫描到的类的属性的具体信息
  final FieldElement element;

  ///扫描时的注解信息
  // final MField annotation;

  ///扫描时的注解信息 原始信息
  final ConstantReader annotationValue;

  // final PropertyAccessorElement setter;

  ///属性的类型
  final GType type;

  GField(this.element, this.annotationValue)
      : type = GType(element, element.type);

  ///获取属性的具体key 依据注解和name生成
  String get fieldName => annotationIsNull ||
          annotationValue.peek('key') == null ||
          annotationValue.peek('key')!.isNull ||
          annotationValue.peek('key')!.stringValue.isEmpty
      ? element.name
      : annotationValue.peek('key')!.stringValue;

  ///判断注解信息是否为空
  bool get annotationIsNull => annotationValue.isNull;

  ///是否是空安全 切不能赋值null
  bool get isNonNullable =>
      element.type.nullabilitySuffix == NullabilitySuffix.none;
}

///扫描到的参数信息
class GParam {
  ///扫描到的参数具体信息
  final ParameterElement element;

  ///扫描时的注解信息
  // final MParam annotation;

  ///扫描时的注解信息 原始信息
  final ConstantReader annotationValue;

  ///参数的type
  final GType type;

  GParam(this.element, this.annotationValue)
      : type = GType(element, element.type);

  ///获取参数的具体key 依据注解和name生成
  String get paramKey => annotationIsNull ||
          annotationValue.peek('key') == null ||
          annotationValue.peek('key')!.isNull ||
          annotationValue.peek('key')!.stringValue.isEmpty
      ? element.name
      : annotationValue.peek('key')!.stringValue;

  ///判断注解信息是否为空
  bool get annotationIsNull => annotationValue.isNull;

  ///是否未必
  bool get isNeed => element.isRequiredPositional || element.isRequiredNamed;

  ///是否是空安全 切不能赋值null
  bool get isNonNullable =>
      element.type.nullabilitySuffix == NullabilitySuffix.none;
}
