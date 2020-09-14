import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';
import 'package:glob/glob.dart';
import 'package:magic_mirror/mirror.dart';
import 'package:path/path.dart' as p;
import 'package:source_gen/source_gen.dart';

import 'entities.dart';
import 'gen_code.dart';
import 'scan.dart';
import 'tools.dart';
///builder的入口
Builder mirror(BuilderOptions options) => MirrorBuilder();
///查找配置信息
final TypeChecker _configChecker = TypeChecker.fromRuntime(MirrorConfig);
///从lib/mirror_config.dart中加载配置信息
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
///将所有医用的库扫描库中的类信息
Future<List<GLibrary>> _importLibs(BuildStep buildStep) async {
  var list = <GLibrary>[];
  for (var lib in config.importLibsNames.entries) {
    var library = await scanLibrary(buildStep, lib.key, lib.value);
    list.add(library);
  }
  return list;
}

///所有已扫描到的库
final Map<String, GLibrary> libraries = {};
///记录配置信息
MirrorConfig _config;

///记录配置信息
MirrorConfig get config => _config;

///设定配置信息
void setMirrorConfig(    MirrorConfig config) {
  if (config == null) return;
  _config = config;
}

///扫描器
class MirrorBuilder implements Builder {
  ///输出文件自动格式化
  final _writeDartFileFormatter = DartFormatter();
  ///缓存已经生成的信息不在二次扫描生成
  String _implementationTemp, _registerTemp;
  ///输入和输出定义
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
  ///register的输出文件
  static AssetId _registerFileOutput(BuildStep buildStep) {
    return AssetId(
      buildStep.inputId.package,
      p.join('lib', '_generated', 'com', 'aymtools', 'mirror',
          'register.mirror.aymtools.dart'),
    );
  }

  ///project的输出文件
  static AssetId _projectFileOutput(BuildStep buildStep) {
    return AssetId(
      buildStep.inputId.package,
      p.join('lib', '_generated', 'com', 'aymtools', 'mirror',
          'project.mirror.aymtools.dart'),
    );
  }

  ///implementation的输出文件
  static AssetId _implementationFileOutput(BuildStep buildStep) {
    return AssetId(
      buildStep.inputId.package,
      p.join('lib', '_generated', 'com', 'aymtools', 'mirror',
          'implementation.mirror.aymtools.dart'),
    );
  }

  ///export 类库的输出文件
  static AssetId _exportFileOutput(BuildStep buildStep) {
    return AssetId(
      buildStep.inputId.package,
      p.join('lib', 'mirror_export.dart'),
    );
  }
  ///构建过程
  @override
  FutureOr<void> build(BuildStep buildStep) async {
    var package = buildStep.inputId.package;
    if (config == null) {
      var conf = await _initConfig(buildStep);
      if (conf == null) {
        throw 'can not find lib/mirror_config.dart';
      }
      setMirrorConfig(conf);
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
      _implementationTemp ??= _writeDartFileFormatter
          .format(genMirrorImplementation(libraries.values.toList()));
      await buildStep.writeAsString(
          _implementationFileOutput(buildStep), _implementationTemp);
      await buildStep.writeAsString(_projectFileOutput(buildStep),
          _writeDartFileFormatter.format(genCodeMirrorInfo(lib)));

      _registerTemp ??= _writeDartFileFormatter.format(genMirrorRegister(
          package, [
        'project.mirror.aymtools.dart',
        'implementation.mirror.aymtools.dart'
      ]));
      await buildStep.writeAsString(
          _registerFileOutput(buildStep), _registerTemp);
    }
    if (config.isGenLibExport) {
      await buildStep.writeAsString(_exportFileOutput(buildStep), '');
    }
  }
}
