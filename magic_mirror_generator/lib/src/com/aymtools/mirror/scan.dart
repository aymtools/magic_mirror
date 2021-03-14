import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:magic_mirror/magic_mirror.dart';
import 'package:source_gen/source_gen.dart';

import 'entities.dart';
import 'tools.dart';

///扫描类库信息
Future<GLibrary?> scanLibrary(BuildStep buildStep, MImport import) async {
  GLibrary? library;
  var libPackageName = import.packageName;
  var libDartFileName = import.libName;
  try {
    var assetId = AssetId(libPackageName, 'lib/${libDartFileName}.dart');
    var lib = await buildStep.resolver.libraryFor(assetId);
    var libInfos = <GLibraryInfo>[];
    libInfos.addAll(await _scanExportedLibrary(lib));
    library = GLibrary(
        libPackageName, libDartFileName, lib.name ?? libPackageName,
        lib: lib, libs: libInfos);

    // Log.log('scanLibrary $libPackageName $libDartFileName  ${libInfos.length}');
  } catch (e) {
    print(
        'Can not load package:${libPackageName} name:${libDartFileName} library!! \n $e');
  }
  return library;
}

///扫描类库中的具体类包信息
Future<List<GLibraryInfo>> _scanExportedLibrary(LibraryElement lib) async {
  var result = await lib.exportedLibraries
      .where((element) => !element.isInSdk)
      .map((element) => scanLibraryInfo(LibraryReader(element)))
      .where((element) => element.classes.isNotEmpty)
      .toList();
  result = removeDuplicate(result, (test) => test.uriStr);
  return result;
}

///判断是否时需要生成反射镜像
const TypeChecker _enableReflectionChecker =
    TypeChecker.fromRuntime(MReflectionEnable);

///判断是否时需要生成反射镜像
const TypeChecker _enableDeclarationChecker =
    TypeChecker.fromRuntime(MAnnotation);

///判断是否时MClass注解的类
const TypeChecker _disableReflectionChecker =
    TypeChecker.fromRuntime(MReflectionDisable);

///扫描所有的类包信息
GLibraryInfo scanLibraryInfo(LibraryReader libraryReader) {
  var classes = libraryReader
      .annotatedWith(_enableReflectionChecker)
      .map((element) => _scanClass(element.element, element.annotation))
      .whereType<GClass>()
      .toList();
  classes = removeDuplicate(classes, (test) => test.key);
  var info = GLibraryInfo(libraryReader.element, classes, []);
  return info;
}

// ///构造函数的注解判定器
// const TypeChecker _classConstructorAnnotation =
//     TypeChecker.fromRuntime(MConstructor);
//
// ///构造函数的注解判定器 禁止模式时使用
// const TypeChecker _classConstructorNotAnnotation =
//     TypeChecker.fromRuntime(MConstructorNot);
//
// ///参数的注解判定器
// const TypeChecker _classParamAnnotation = TypeChecker.fromRuntime(MParam);
//
// ///函数的注解判定器
// const TypeChecker _classMethodAnnotation = TypeChecker.fromRuntime(MFunction);
//
// ///函数的注解判定器 禁止模式时使用
// const TypeChecker _classMethodNotAnnotation =
//     TypeChecker.fromRuntime(MFunctionNot);
//
// ///属性的注解判定器
// const TypeChecker _classFieldAnnotation = TypeChecker.fromRuntime(MField);
//
// ///属性的注解判定器 禁止模式时使用
// const TypeChecker _classFieldNotAnnotation = TypeChecker.fromRuntime(MFieldNot);

///扫描类信息
GClass? _scanClass(Element element, ConstantReader annotation) {
  if (element.kind != ElementKind.CLASS) return null;
  var from = annotation.peek('needAssignableFrom');
  if (!from.isNull &&
      from.isList &&
      from.listValue.isNotEmpty &&
      !from.listValue
          .map((e) => e.toTypeValue())
          .every((c) => TypeChecker.fromStatic(c).isAssignableFrom(element))) {
    return null;
  }

  var fromAnyOne = annotation.peek('anyOneAssignableFrom');
  if (!fromAnyOne.isNull &&
      fromAnyOne.isList &&
      fromAnyOne.listValue.isNotEmpty &&
      !fromAnyOne.listValue
          .map((e) => e.toTypeValue())
          .any((c) => TypeChecker.fromStatic(c).isAssignableFrom(element))) {
    return null;
  }
  var classAnnotation =
      genAnnotation<MReflectionEnable>(annotation) ?? MReflectionEnable();
  var className = element.displayName;
  var classElement = (element as ClassElement);

  var keyGen = KeyGen(classAnnotation.keyGenType);
  var sourceUri = element.librarySource.uri.toString();
  var uriKey = keyGen.gen(classAnnotation.key, classAnnotation.tag,
      classAnnotation.ext, className, sourceUri);
  if ('' == uriKey) {
    keyGen = KeyGen(KeyGen.KEY_GEN_TYPE_BY_CLASS_NAME);
    uriKey = keyGen.gen(classAnnotation.key, classAnnotation.tag,
        classAnnotation.ext, className, sourceUri);
  }
  var constructors = classAnnotation.scanConstructors
      ? _scanConstructors(
          classElement, !classAnnotation.scanConstructorsUsedBlockList)
      : <GConstructor>[];

  var fields = classAnnotation.scanFields
      ? _scanFields(element, classAnnotation.scanSuperFields,
          !classAnnotation.scanFieldsUsedBlockList)
      : <GField>[];
  fields = removeDuplicate<GField, String>(fields, (e) => e.element.name);

  var functions = classAnnotation.scanFunctions
      ? _scanFunctions(element, classAnnotation.scanSuperFunctions,
          !classAnnotation.scanFunctionsUsedBlockList)
      : <GFunction>[];
  functions =
      removeDuplicate<GFunction, String>(functions, (e) => e.element.name);

  var gClass =
      GClass(uriKey, classElement, annotation, constructors, fields, functions);
  return gClass;
}

///扫描类所有的构造函数信息
List<GConstructor> _scanConstructors(
    ClassElement element, bool scanUsedAllowList) {
  return element.constructors
      .where((ele) => !_disableReflectionChecker.hasAnnotationOf(ele))
      .where((ele) => !ele.displayName.startsWith('_'))
      .where((ele) =>
          '' == ele.displayName ||
          (!scanUsedAllowList ||
              _enableDeclarationChecker.firstAnnotationOf(ele) != null))
      .map((e) => _scanConstructor(e))
      .toList(growable: true);
}

///扫描类构造函数信息 具体信息
GConstructor _scanConstructor(ConstructorElement element) {
  return GConstructor(
      element,
      ConstantReader(_enableDeclarationChecker.firstAnnotationOf(element)),
      element.parameters.map((e) => _scanParam(e)).toList(growable: true));
}

///扫描类所有的属性信息
List<GField> _scanFields(
    ClassElement element, bool scanSuper, bool scanUsedAllowList) {
  var fields = element.fields
      .where((ele) => !(_disableReflectionChecker.hasAnnotationOf(ele) ||
          (ele.getter != null &&
              _disableReflectionChecker.hasAnnotationOf(ele.getter)) ||
          (ele.setter != null &&
              _disableReflectionChecker.hasAnnotationOf(ele.setter))))
      .where((ele) => !ele.displayName.startsWith('_'))
      .where((ele) =>
          !scanUsedAllowList ||
          ((_enableDeclarationChecker.hasAnnotationOf(ele) ||
              (ele.getter != null &&
                  _enableDeclarationChecker.hasAnnotationOf(ele.getter)) ||
              (ele.setter != null &&
                  _enableDeclarationChecker.hasAnnotationOf(ele.setter)))))
      .map((e) => _scanField(e))
      .toList(growable: true);
  if (scanSuper && element.supertype != null) {
    fields.addAll(
        _scanFields(element.supertype!.element, scanSuper, scanUsedAllowList));
  }
  return fields;
}

///扫描类属性信息 具体信息
GField _scanField(FieldElement element) {
  DartObject? annotation = _enableDeclarationChecker.firstAnnotationOf(element);
  if (annotation == null && element.getter != null) {
    annotation = _enableDeclarationChecker.firstAnnotationOf(element.setter);
  }
  if (annotation == null && element.getter != null) {
    annotation = _enableDeclarationChecker.firstAnnotationOf(element.getter);
  }
  return GField(element, ConstantReader(annotation));
}

///扫描类所有的函数信息
List<GFunction> _scanFunctions(
    ClassElement element, bool scanSuper, bool scanUsedAllowList) {
  var functions = element.methods
      .where((ele) => !_disableReflectionChecker.hasAnnotationOf(ele))
      .where((ele) => !ele.displayName.startsWith('_'))
      .where((ele) => (!scanUsedAllowList ||
          _enableDeclarationChecker.firstAnnotationOf(ele) != null))
      .map((e) => _scanFunction(e))
      .toList(growable: true);
  if (scanSuper && element.supertype != null) {
    functions.addAll(_scanFunctions(
        element.supertype!.element, scanSuper, scanUsedAllowList));
  }
  return functions;
}

///扫描类的函数信息 具体信息
GFunction _scanFunction(MethodElement element) {
  return GFunction(
      element,
      ConstantReader(_enableDeclarationChecker.firstAnnotationOf(element)),
      element.parameters.map((e) => _scanParam(e)).toList(growable: true));
}

//扫描函数所需的参数信息
GParam _scanParam(ParameterElement element) {
  return GParam(element,
      ConstantReader(_enableDeclarationChecker.firstAnnotationOf(element)));
}
