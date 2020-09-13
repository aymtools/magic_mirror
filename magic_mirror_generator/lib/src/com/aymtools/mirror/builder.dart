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

Builder mirror(BuilderOptions options) => MirrorBuilder();

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
    var package = buildStep.inputId.package;
    if (config == null) {
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
