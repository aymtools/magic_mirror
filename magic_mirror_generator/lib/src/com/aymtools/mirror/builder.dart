import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'constants.dart';
import 'entities.dart';
import 'gen_code.dart';
import 'scan.dart';
import 'tools.dart';
import 'package:source_gen/source_gen.dart';
import 'package:magic_mirror/mirror.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;

Builder init(BuilderOptions options) => Init();

Builder scan(BuilderOptions options) => Scan();

Builder mirror(BuilderOptions options) => MirrorBuilder();

class Init extends Builder {
  @override
  FutureOr<void> build(BuildStep buildStep) async {
//    Log.log(
//        'Init  package:${buildStep.inputId.package}  uii:${buildStep.inputId.uri}');
    if (config == null) {
      Log.log('config init start');
      var conf = await _initConfig(buildStep);
      setMirrorConfig(conf, buildStep.inputId.path, buildStep.inputId.package);
//      await libraries.values
//          .forEach((e) => _genLibInvokerCreator(buildStep, e));
      Log.log(
          'config info isGenInvoker:${config.isGenInvoker} isGenLibExport:${config.isGenLibExport} importLibsNames:${config.importLibsNames}');

      var libs = await _importLibs(buildStep);
      libs.forEach((element) {
        libraries[element.name] = element;
      });

      if (config.isGenInvoker) {
        await libraries.values.forEach((e) => _genLibInvoker(e));
      }
      Log.log('config init end');
    }
  }

  @override
  Map<String, List<String>> get buildExtensions => {
        'mirror_config.dart': ['.m.mirror.aymtools.dart'],
        'mirror.dart': ['.m.mirror.aymtools.dart'],
        'mirror.yaml': ['.m.mirror.aymtools.dart'],
        'mirror.yml': ['.m.mirror.aymtools.dart'],
      };
}

class Scan extends Builder {
  @override
  FutureOr<void> build(BuildStep buildStep) async {
//    Log.log('start Scan ${buildStep.inputId.uri.toString()}');
    if (config == null) return;

    var pack = buildStep.inputId.package;
    var library = libraries.putIfAbsent(pack, () => GLibrary(pack, pack, ''));
    // library.libs.where((element) => element.isNotEmpty).forEach((element) {
    //   buildStep.resolver.findLibraryByName(element.)
    // });

    var lib = await buildStep.inputLibrary;
    var inputUri = lib.source.uri.toString();
    var flag = library.removeLib(inputUri);

    if (!flag) {
      if (inputUri.startsWith('package:magic_mirror/src/') ||
          inputUri.startsWith('package:magic_mirror_generator/src/') ||
          inputUri.startsWith('asset:') ||
          inputUri.endsWith('.aymtools.dart') ||
          inputUri.endsWith('/main.dart') ||
          inputUri.contains('_generated') ||
          inputUri.endsWith('mirror_config.dart')) {
        Log.log('Scan Class jump : package:$pack uri: ${inputUri}');
        return;
      }
      // final resolver = buildStep.resolver;
      // if (!await resolver.isLibrary(buildStep.inputId)) return;
      // lib = await buildStep.inputLibrary;
      // if (lib.isInSdk) return;
    } else {
      // lib = await buildStep.inputLibrary;
    }

    // Log.log('start Scan ${buildStep.inputId.uri.toString()}');

    Log.log('Scan Class runing : package:$pack uri: ${inputUri}');
    ++times;

    var libraryInfo = scanLibraryInfo(LibraryReader(lib));
    var result = await _genMirrorLibInfo(libraryInfo);

    library.addGLibraryInfo(libraryInfo);
//    Log.log('Scan end ${buildStep.inputId.uri.toString()}');
    if (times <= 1) {
      Log.log('start gen ???');
      // await _genLibInvoker(libraries[pack]);
      await _genMirrorRegister(library);
    }
    --times;
    return result;
  }

  static int times = 0;

  @override
  Map<String, List<String>> get buildExtensions => {
        '.dart': ['.scan.mirror.aymtools.dart']
      };
}

final TypeChecker _configChecker = TypeChecker.fromRuntime(MirrorConfig);

Future<MirrorConfig> _initConfig(BuildStep buildStep) async {
  MirrorConfig config;
  var package = buildStep.inputId.package;
  var assetId = AssetId(package, 'lib/mirror_config.dart');
  final resolver = buildStep.resolver;
  LibraryElement lib;
  if (await buildStep.canRead(assetId) && await resolver.isLibrary(assetId)) {
    lib = await resolver.libraryFor(assetId);
    var annotation =
        LibraryReader(lib).annotatedWith(_configChecker).first?.annotation;
    config = genAnnotation(annotation);
  }
  config ??= MirrorConfig();
  config.importLibsNames['magic_mirror'] = 'mirror';
  return config;
}

Future<List<GLibrary>> _importLibs(BuildStep buildStep) async {
  var list = <GLibrary>[];
  for (var lib in config.importLibsNames.entries) {
    var library = await scanLibrary(buildStep, lib.key, lib.value);
    list.add(library);
  }
  return list;
}

Future<void> _genLibInvoker(GLibrary library) async {
  Log.log('_genLibInvoker ${library.package}');

  await _genMirrorInfo(library);
  // await _genMirrorRegister(library);
}

Future<String> _genMirrorInfo(GLibrary library) async {
  var code = genCodeMirrorInfo(library); // genLibBeanFactoryCode(library);
//  Log.log(code);
  await writeDartFile('${library.package}.mirror.aymtools.dart', code);
  return code;
}

Future<String> _genMirrorLibInfo(GLibraryInfo library) async {
  var code = '';
  if (library.classes.isNotEmpty) {
    code = genMirrorLibInfoMirror(library);
    await writeDartFile(
        '${_libInfoName(library.lib)}.mirror.aymtools.dart', code);
  } else {
    await delDartFile('${_libInfoName(library.lib)}.mirror.aymtools.dart');
  }
  return code;
}

Future<String> _genMirrorRegister(GLibrary library) async {
  var package = library.package;
  var others = <String>[];

  others.addAll(libraries.values
      .where((element) => !element.isProjectLib)
      .map((e) => '${e.asName}.mirror.aymtools.dart'));
  others.addAll(library.libs
      .where((element) => element.isNotEmpty)
      .map((e) => '${_libInfoName(e.lib)}.mirror.aymtools.dart'));

  var code =
      genMirrorRegister(package, others); // genLibBeanFactoryCode(library);
  await writeDartFile('${package}.register.aymtools.dart', code);
  return code;
}

String _libInfoName(LibraryElement lib) {
  var uri = lib.librarySource.uri;
  uri = uri.replace(scheme: '');
  var r = uri.toString();
  return r.endsWith('.dart') ? r.substring(0, r.length - 5) : r;
}

class MirrorBuilder implements Builder {
  String implementationTemp, registerTemp;

  @override
  Map<String, List<String>> get buildExtensions {
    return const {
      r'$lib$': [
        '_generated/com/aymtools/mirror/register.mirror.aymtools.dart',
        '_generated/com/aymtools/mirror/project.mirror.aymtools.dart',
        '_generated/com/aymtools/mirror/implementation.mirror.aymtools.dart',
        'mirror_export.dart'
      ]
    };
  }

  static AssetId _registerFileOutput(BuildStep buildStep) {
    return AssetId(
      buildStep.inputId.package,
      p.join('lib', '_generated', 'com', 'aymtools', 'mirror',
          'register.mirror.aymtools.dart'),
    );
  }

  static AssetId _projectFileOutput(BuildStep buildStep) {
    return AssetId(
      buildStep.inputId.package,
      p.join('lib', '_generated', 'com', 'aymtools', 'mirror',
          'project.mirror.aymtools.dart'),
    );
  }

  static AssetId _implementationFileOutput(BuildStep buildStep) {
    return AssetId(
      buildStep.inputId.package,
      p.join('lib', '_generated', 'com', 'aymtools', 'mirror',
          'implementation.mirror.aymtools.dart'),
    );
  }

  static AssetId _exportFileOutput(BuildStep buildStep) {
    return AssetId(
      buildStep.inputId.package,
      p.join('lib', 'mirror_export.dart'),
    );
  }

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    var inputId = await buildStep.inputId;
    var package = buildStep.inputId.package;
    Log.log('uri : ${inputId}');
    var isInitConfig = false;
    if (config == null) {
      isInitConfig = true;
      var conf = await _initConfig(buildStep);
      if (conf == null) {
        throw 'can not find lib/mirror_config.dart';
      }
      setMirrorConfig(conf, 'lib/mirror_config.dart', package);
      Log.log(
          'config info isGenInvoker:${config.isGenInvoker} isGenLibExport:${config.isGenLibExport} importLibsNames:${config.importLibsNames}');

      var libs = await _importLibs(buildStep);
      libs.forEach((element) {
        libraries[element.name] = element;
      });

      if (config.isGenInvoker) {
        // await libraries.values.forEach((e) => _genLibInvoker(e));
      }
    }

    final libraryInfo = <GLibraryInfo>[];
    await for (final input in buildStep.findAssets(Glob(r'lib/**'))) {
      if (!input.path.startsWith('lib/_generated')) {
        final library = await buildStep.resolver.libraryFor(input);
        libraryInfo.add(scanLibraryInfo(LibraryReader(library)));
      }
    }

    var lib = GLibrary(package, package, '',
        libs: libraryInfo.where((element) => element.isNotEmpty).toList());

    if (config.isGenInvoker) {
      implementationTemp ??= genMirrorImplementation(libraries.values.toList());
      await buildStep.writeAsString(
          _implementationFileOutput(buildStep), implementationTemp);
      await buildStep.writeAsString(
          _projectFileOutput(buildStep), genCodeMirrorInfo(lib));

      registerTemp ??= genMirrorRegister(package, [
        'project.mirror.aymtools.dart',
        'implementation.mirror.aymtools.dart'
      ]);
      await buildStep.writeAsString(
          _registerFileOutput(buildStep), registerTemp);
    }
    if (config.isGenLibExport) {
      await buildStep.writeAsString(_exportFileOutput(buildStep), '');
    }
  }
}
