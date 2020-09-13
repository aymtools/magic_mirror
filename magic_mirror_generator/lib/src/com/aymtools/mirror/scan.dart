import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:magic_mirror/mirror.dart';
import 'entities.dart';
import 'tools.dart';
import 'package:source_gen/source_gen.dart';

Future<GLibrary> scanLibrary(
    BuildStep buildStep, String libPackageName, String libDartFileName) async {
  GLibrary library;
  try {
    var assetId = AssetId(libPackageName, 'lib/${libDartFileName}.dart');
    var lib = await buildStep.resolver.libraryFor(assetId);
    var libInfos = await _scanExportedLibrary(lib);
    library = GLibrary(
        libPackageName, libDartFileName, lib.name ?? libPackageName,
        lib: lib, libs: libInfos);
  } catch (e) {
    print(
        'Can not load package:${libPackageName} name:${libDartFileName} library!! \n $e');
  }
  return library;
}

Future<List<GLibraryInfo>> _scanExportedLibrary(LibraryElement lib) async {
  var result = await lib.exportedLibraries
      .where((element) => !element.isInSdk)
      .map((element) => scanLibraryInfo(LibraryReader(element)))
      .where((element) => element.classes.isNotEmpty)
      .toList();
  result = removeDuplicate(result, (test) => test.uriStr);
  return result;
}

const TypeChecker _classChecker = TypeChecker.fromRuntime(MClass);

GLibraryInfo scanLibraryInfo(LibraryReader libraryReader) {
  var classes = libraryReader
      .annotatedWith(_classChecker)
      .map((element) => _scanClass(element.element, element.annotation))
      .where((element) => element != null)
      .toList();
  classes = removeDuplicate(classes, (test) => test.key);
  var info = GLibraryInfo(libraryReader.element, classes, []);
  return info;
}

const TypeChecker _classConstructorAnnotation =
    TypeChecker.fromRuntime(MConstructor);
const TypeChecker _classConstructorNotAnnotation =
    TypeChecker.fromRuntime(MConstructorNot);
const TypeChecker _classParamAnnotation = TypeChecker.fromRuntime(MParam);

const TypeChecker _classMethodAnnotation = TypeChecker.fromRuntime(MFunction);
const TypeChecker _classMethodNotAnnotation =
    TypeChecker.fromRuntime(MMethodNot);

const TypeChecker _classFieldAnnotation = TypeChecker.fromRuntime(MField);
const TypeChecker _classFieldNotAnnotation = TypeChecker.fromRuntime(MFieldNot);

GClass _scanClass(Element element, ConstantReader annotation) {
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
  var classAnnotation = genAnnotation<MClass>(annotation);
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

List<GConstructor> _scanConstructors(
    ClassElement element, bool scanUsedAllowList) {
  return element.constructors
      .where((ele) => !ele.displayName.startsWith('_'))
      .where((ele) =>
          '' == ele.displayName ||
          (scanUsedAllowList &&
              _classConstructorAnnotation.firstAnnotationOf(ele) != null) ||
          (!scanUsedAllowList &&
              _classConstructorNotAnnotation.firstAnnotationOf(ele) == null))
      .map((e) => _scanConstructor(e))
      .toList(growable: true);
}

GConstructor _scanConstructor(ConstructorElement element) {
  return GConstructor(
      element,
      ConstantReader(_classConstructorAnnotation.firstAnnotationOf(element)),
      element.parameters.map((e) => _scanParam(e)).toList(growable: true));
}

List<GField> _scanFields(
    ClassElement element, bool scanSuper, bool scanUsedAllowList) {
  var fields = element.fields
      .where((ele) => !ele.displayName.startsWith('_'))
      //当前的gen 不支持set get的属性 不知道后续会不会支持
      // .map((e) {
      //   Log.log(
      //       '${element.displayName}  ${e.name} getter ${e.getter} setter ${e.setter}   ann ${e.metadata}');
      //   return e;
      // })
      .where((ele) =>
          (scanUsedAllowList &&
              _classFieldAnnotation.firstAnnotationOf(ele) != null) ||
          (!scanUsedAllowList &&
              _classFieldNotAnnotation.firstAnnotationOf(ele) == null))
      .map((e) => _scanField(e))
      .toList(growable: true);
  if (scanSuper) {
    fields.addAll(
        _scanFields(element.supertype.element, scanSuper, scanUsedAllowList));
  }
  return fields;
}

GField _scanField(FieldElement element) {
  return GField(element,
      ConstantReader(_classFieldAnnotation.firstAnnotationOf(element)));
}

List<GFunction> _scanFunctions(
    ClassElement element, bool scanSuper, bool scanUsedAllowList) {
  var functions = element.methods
      .where((ele) => !ele.displayName.startsWith('_'))
      .where((ele) =>
          (scanUsedAllowList &&
              _classMethodAnnotation.firstAnnotationOf(ele) != null) ||
          (!scanUsedAllowList &&
              _classMethodNotAnnotation.firstAnnotationOf(ele) == null))
      .map((e) => _scanFunction(e))
      .toList(growable: true);
  if (scanSuper) {
    functions.addAll(_scanFunctions(
        element.supertype.element, scanSuper, scanUsedAllowList));
  }
  return functions;
}

GFunction _scanFunction(MethodElement element) {
  return GFunction(
      element,
      ConstantReader(_classMethodAnnotation.firstAnnotationOf(element)),
      element.parameters.map((e) => _scanParam(e)).toList(growable: true));
}

GParam _scanParam(ParameterElement element) {
  return GParam(element,
      ConstantReader(_classParamAnnotation.firstAnnotationOf(element)));
}
