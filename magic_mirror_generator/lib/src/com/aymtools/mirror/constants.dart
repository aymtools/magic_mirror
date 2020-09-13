import 'dart:io';

import 'package:analyzer/dart/element/type.dart';
import 'package:dart_style/dart_style.dart';
import 'package:magic_mirror/mirror.dart';

import 'entities.dart';
import 'tools.dart';

final writeDartFileFormatter = DartFormatter();

final Map<String, GLibrary> libraries = {};

MirrorConfig _config;
String _writePath = '';
String _packageName;

void setMirrorConfig(
    MirrorConfig config, String configInputIdPath, String runWithPackageName) {
  if (config == null) return;
  _config = config;
  var filePath = configInputIdPath;
  Log.log('filepath:' + filePath);
  filePath = filePath.substring(0, filePath.indexOf('/'));
  _writePath = '$filePath/_generated/com/aymtools/mirror/';
  _packageName = runWithPackageName;
  var file = Directory(_writePath);
//  if (!file.existsSync()) {
  file.createSync(recursive: true);
//  }
}

MirrorConfig get config => _config;

String get runWithPackageName => _packageName;

String getWritePath(String writeName) => _writePath + writeName;

Future<void> writeDartFile(String fileName, String dartContent) async {
  var file = File(getWritePath(fileName));
  if (file.existsSync()) {
    file.deleteSync();
  }
  file.createSync(recursive: true);
  await file.writeAsString(writeDartFileFormatter.format(dartContent));
//   await file.writeAsString(dartContent);
}

Future<void> delDartFile(String fileName) async {
  var file = File(getWritePath(fileName));
  if (file.existsSync()) {
    file.deleteSync();
  }
}
//Map<String, String> get imports => _imports;
//
//MapEntry<String, String> parseAddImport(DartType type) {
//  if (isDartCoreType(type)) return MapEntry('', '');
//  if (type.element.library.isDartCore ||
//      'dart.core' == type.element.library.name) {
//    return MapEntry('', '');
//  }
//  if (type is ParameterizedType) {
//    type.typeArguments.forEach((element) => parseAddImport(element));
//  }
//  MapEntry<String, String> r;
//  libraries.entries.forEach((element) {
//    if (element.value.isInLib(type.element)) {
//      if (!_imports.containsKey(type.element.source.uri.toString())) {
//        _imports[type.element.source.uri.toString()] = element.value.asName;
//      }
//      r = MapEntry(type.element.source.uri.toString(), element.value.asName);
//    }
//  });
//  return r ?? _parseAddImports(type.element.librarySource.uri.toString());
//}
//
//MapEntry<String, String> parseAddImportLib(LibraryElement lib) {
//  if (lib == null) return MapEntry('', '');
//  MapEntry<String, String> r;
//  libraries.entries.forEach((element) {
//    if (element.value.isInLib(lib)) {
//      r = MapEntry(lib.source.uri.toString(), element.value.asName);
//    }
//  });
//  return r ?? _parseAddImports(lib.librarySource.uri.toString());
//}
//
//MapEntry<String, String> _parseAddImports(String librarySourceUriStr) {
//  if ('dart.core' == librarySourceUriStr ||
//      librarySourceUriStr.startsWith('dart:')) {
//    return MapEntry('', '');
//  }
//  if ('' == librarySourceUriStr || !librarySourceUriStr.endsWith('.dart')) {
//    return MapEntry(librarySourceUriStr, librarySourceUriStr);
//  }
//  if (librarySourceUriStr.startsWith('package:bean_factory')) {
//    return MapEntry('', '');
//  }
//  if (!_imports.containsKey(librarySourceUriStr)) {
//    var asStr = _formatAsStr(librarySourceUriStr);
//    _imports[librarySourceUriStr] = asStr;
//  }
//  return MapEntry(librarySourceUriStr, _imports[librarySourceUriStr]);
//}
//
//String getImportAsStr(String librarySourceUriStr) =>
//    _imports.containsKey(librarySourceUriStr)
//        ? _imports[librarySourceUriStr]
//        : '';
//
//String _formatAsStr(String uri) {
//  if ('' == uri || !uri.endsWith('.dart')) return uri;
//  var asStr = uri
//      .substring(0, uri.length - 5)
//      .replaceAll('/', '_')
//      .replaceFirst('package:', '')
//      .replaceAllMapped(RegExp(r'_\w'), (match) => match.group(0).toUpperCase())
//      .replaceAll('_', '');
//  if (asStr.contains('.')) {
//    asStr = asStr
//        .replaceAllMapped(
//            RegExp(r'\.\w'), (match) => match.group(0).toUpperCase())
//        .replaceAll('.', '');
//  }
//  if (asStr.length > 1) {
//    asStr = asStr[0].toUpperCase() + asStr.substring(1);
//  }
//  var i = 0;
//  var asStrTemp = asStr;
//  while (_imports.containsValue(asStrTemp)) {
//    i++;
//    asStrTemp = '${asStr}_$i';
//  }
//  return asStrTemp;
//}

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
