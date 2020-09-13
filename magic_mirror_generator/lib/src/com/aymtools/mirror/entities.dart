import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:magic_mirror/mirror.dart';
import 'package:source_gen/source_gen.dart';

import 'tools.dart';

class GImports {
  final Set<GLibrary> _otherImportLibrary = {};

  final Map<String, String> _imports = {};

  GImports({List<GLibrary> otherImportLibrary}) {
    if (otherImportLibrary != null && otherImportLibrary.isNotEmpty) {
      addLibs(otherImportLibrary);
    }
  }

  void addLibs(List<GLibrary> otherImportLibrary) {
    _otherImportLibrary.addAll(otherImportLibrary);

    _imports['package:magic_mirror/mirror.dart'] = '';
    // if (lib != null && !isMirrorLib) {
    //   _imports['package:$package/$name.dart'] = '$asName';
    // }
    if (_otherImportLibrary.isNotEmpty) {
      _otherImportLibrary
          .where((element) => element.lib != null && !element.isMirrorLib)
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
        if (cls.annotationValue != null && !cls.annotationValue.isNull) {
          _parseAddImportLib(
              cls.annotationValue.objectValue.type.element.library);
        }
        cls.constructors.forEach((constructor) {
          if (constructor.annotationValue != null &&
              !constructor.annotationValue.isNull) {
            _parseAddImportLib(
                constructor.annotationValue.objectValue.type.element.library);
          }
          constructor.params.forEach((param) {
            if (param.annotationValue != null &&
                !param.annotationValue.isNull) {
              _parseAddImportLib(
                  param.annotationValue.objectValue.type.element.library);
            }
            _parseTypeAndInnerType(param.type.value);
          });
        });
        cls.fields.forEach((field) {
          if (field.annotationValue != null && !field.annotationValue.isNull) {
            _parseAddImportLib(
                field.annotationValue.objectValue.type.element.library);
          }
          _parseTypeAndInnerType(field.type.value);
        });
        cls.functions.forEach((function) {
          if (function.annotationValue != null &&
              !function.annotationValue.isNull) {
            _parseAddImportLib(
                function.annotationValue.objectValue.type.element.library);
          }
          _parseTypeAndInnerType(function.returnType.value);
          function.params.forEach((param) {
            if (param.annotationValue != null &&
                !param.annotationValue.isNull) {
              _parseAddImportLib(
                  param.annotationValue.objectValue.type.element.library);
            }
            _parseTypeAndInnerType(param.type.value);
          });
        });
      });
    });
  }

  Map<String, String> getImports({bool usedCache = true}) {
    return _imports;
  }

  String _parseTypeAndInnerType(DartType type) {
    if (type.isDynamic) {
      return 'dynamic';
    }
    if (type.isVoid) {
      return 'void';
    }
    var libAs = type == null || isDartCoreType(type)
        ? ''
        : _parseAddImportLib(type.element.library).value;

    var t = type;
    var ts = <String>[];
    var name = type.element.name;
    if (t is ParameterizedType) {
      ts = t.typeArguments.map((e) => _parseTypeAndInnerType(e)).toList();
      if (ts.isNotEmpty) {
        var args = ts.reduce((v, e) => '$v,$e');
        name = '$name<$args>';
      }
    }

    return libAs.isEmpty ? name : '$libAs.${name}';
  }

  String _formatAsStr(String uri) {
    if ('' == uri || !uri.endsWith('.dart')) return uri;
    var asStr = uri
        .substring(0, uri.length - 5)
        .replaceAll('/', '_')
        .replaceFirst('package:', '')
        .replaceAllMapped(
            RegExp(r'_\w'), (match) => match.group(0).toUpperCase())
        .replaceAll('_', '');
    if (asStr.contains('.')) {
      asStr = asStr
          .replaceAllMapped(
              RegExp(r'\.\w'), (match) => match.group(0).toUpperCase())
          .replaceAll('.', '');
    }
    if (asStr.length > 1) {
      asStr = asStr[0].toUpperCase() + asStr.substring(1);
    }
    var i = 0;
    var asStrTemp = asStr;
    while (_imports.containsValue(asStrTemp)) {
      i++;
      asStrTemp = '${asStr}\$$i';
    }
    return asStrTemp;
  }

  MapEntry<String, String> _parseAddImportLib(LibraryElement lib) {
    if (lib == null) return MapEntry('', '');
    MapEntry<String, String> r;
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
    return MapEntry(librarySourceUriStr, _imports[librarySourceUriStr]);
  }

  String getTypeNameAsStr(DartType type) {
    return _parseTypeAndInnerType(type);
  }

  String getLibAsNameStr(GLibrary library) => _formatAsStr(
      '${library.asName.isEmpty ? library.name : library.asName}.dart');

  String getLibInfoAsNameStr(GLibraryInfo library) =>
      _formatAsStr(library.lib.source.uri.toString());

  String getUriAsNameStr(String uriStr) => _formatAsStr(uriStr);
}

class GLibrary {
  final String package;
  final String name;

//  final Map<String, List<GBean>> beans = {};
//  final Map<String, List<GBeanCreator>> creators = {};
  final String asName;

  final LibraryElement lib;
  final List<GLibraryInfo> _libs = [];

  GLibrary(this.package, this.name, this.asName,
      {this.lib, List<GLibraryInfo> libs}) {
    if (libs != null) _libs.addAll(libs);
  }

  void addGLibraryInfo(GLibraryInfo info) {
    removeLib(info.uriStr);
    if (info.isNotEmpty) {
      _libs.add(info);
    }
  }

  bool removeLib(String libUriStr) {
    var infoOld =
        findFistWhere<GLibraryInfo>(_libs, (e) => libUriStr == e.uriStr);
    if (infoOld != null) {
      _libs.remove(infoOld);
      return true;
    }
    return false;
  }

  bool isInLib(Element element) {
    return lib == null
        ? false
        : lib.exportedLibraries.contains(element.library);
  }

  bool get isMirrorLib => 'magic_mirror' == package;

  bool get isProjectLib => (null == asName || asName.isEmpty) && lib == null;

  List<GLibraryInfo> get libs => _libs;
}

class GLibraryInfo {
  final LibraryElement lib;

//  Uri libSourceUri;
  final List<GClass> classes;
  final List<GFunction> functions;

  GLibraryInfo(this.lib, List<GClass> classes, List<GFunction> functions)
      : classes = classes ?? [],
        functions = functions ?? [];

  String get uriStr => lib.librarySource.uri.toString();

  bool get isNotEmpty => classes.isNotEmpty;
}

class GType {
  final Element element;
  final DartType value;

  GType(this.element, this.value);
}

class GClass {
  final String key;
  final ClassElement element;
  final MClass annotation;
  final ConstantReader annotationValue;

  final GType type;

  final List<GFunction> functions;
  final List<GField> fields;

  final List<GConstructor> constructors;

  GClass(
      this.key,
      this.element,
      this.annotationValue,
      List<GConstructor> constructors,
      List<GField> fields,
      List<GFunction> functions)
      : annotation = genAnnotation(annotationValue),
        type = GType(element, element.thisType),
        constructors = constructors ?? [],
        functions = functions ?? [],
        fields = fields ?? [];

  bool get annotationIsNull =>
      annotationValue == null || annotationValue.isNull;
}

class GConstructor {
  final ConstructorElement element;
  final MConstructor annotation;
  final ConstantReader annotationValue;

  final List<GParam> params;

  GConstructor(this.element, this.annotationValue, List<GParam> params)
      : annotation = genAnnotation(annotationValue),
        params = params ?? [];

  String get namedConstructorInKey =>
      annotation == null || annotation.key == null || annotation.key.isEmpty
          ? element.name
          : annotation.key;

  bool get isDefConstructor => element.name.isEmpty;

  bool get isConstructorCase2 =>
      element.name.isEmpty &&
      annotation != null &&
      annotation.key != null &&
      annotation.key.isNotEmpty;

  bool get annotationIsNull =>
      annotationValue == null || annotationValue.isNull;
}

class GFunction {
  final MethodElement element;
  final MFunction annotation;
  final ConstantReader annotationValue;
  final List<GParam> params;

  final GType returnType;

  GFunction(this.element, this.annotationValue, List<GParam> params)
      : annotation = genAnnotation(annotationValue),
        returnType = GType(element.returnType.element, element.returnType),
        params = params ?? [];

  String get functionName =>
      annotation == null || annotation.key == null || annotation.key.isEmpty
          ? element.name
          : annotation.key;

  bool get annotationIsNull =>
      annotationValue == null || annotationValue.isNull;
}

class GField {
  final FieldElement element;
  final MField annotation;
  final ConstantReader annotationValue;
  final GType type;

  GField(this.element, this.annotationValue)
      : annotation = genAnnotation(annotationValue),
        type = GType(element, element.type);

  String get fieldName =>
      annotation == null || annotation.key == null || annotation.key.isEmpty
          ? element.name
          : annotation.key;

  bool get annotationIsNull =>
      annotationValue == null || annotationValue.isNull;
}

class GParam {
  final ParameterElement element;
  final MParam annotation;
  final ConstantReader annotationValue;
  final GType type;

  GParam(this.element, this.annotationValue)
      : annotation = genAnnotation(annotationValue),
        type = GType(element, element.type);

  String get paramKey =>
      annotation == null || annotation.key == null || annotation.key.isEmpty
          ? element.name
          : annotation.key;

  bool get annotationIsNull =>
      annotationValue == null || annotationValue.isNull;
}
