import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';
import 'package:glob/glob.dart';
import 'package:magic_mirror/magic_mirror.dart';
import 'package:path/path.dart' as p;
import 'package:source_gen/source_gen.dart';

import 'entities.dart';
import 'gen_code.dart';
import 'scan.dart';
import 'tools.dart';

///builder的入口
Builder mirror(BuilderOptions options) => MirrorBuilder();

///查找配置信息
final TypeChecker _configChecker = TypeChecker.fromRuntime(MMirrorConfig);

///从lib/mirror_config.dart中加载配置信息
Future<MMirrorConfig> _initConfig(BuildStep buildStep) async {
  // var pks=Set<String>();
  // currentMirrorSystem().libraries.forEach((key, value) {
  //   pks.add(value.uri?.pathSegments[0]);
  // });
  //
  // Log.log('MirrorSystem :   $pks  ');
  // Log.log('MirrorSystem :   _initConfig  ');
  MMirrorConfig? config;
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
  if (config == null) {
    await for (final input in buildStep.findAssets(Glob(r'lib/**'))) {
      if (!input.path.startsWith('lib/generated')) {
        final library = await buildStep.resolver.libraryFor(input);
        var annotation = LibraryReader(library)
            .annotatedWith(_configChecker)
            .first
            ?.annotation;
        if (annotation != null) {
          config = genAnnotation(annotation);
          break;
        }
      }
    }
  }
  config ??= MMirrorConfig();

  var imports = <MImport>[_coreImport];
  imports.addAll(config.imports);
  imports.addAll(config.importLibsNames.entries
      .map((e) => MImport(e.key, libName: e.value)));

  config = MMirrorConfig(
    isGenInvoker: config.isGenInvoker,
    isGenLibExport: config.isGenLibExport,
    importLibsNames: {_coreImport.packageName: _coreImport.libName}
      ..addAll(config.importLibsNames),
    imports: imports,
    genGroupBy: config.genGroupBy,
  );

  // Log.log('MirrorSystem :   _initConfig  end');
  return config;
}

///将所有医用的库扫描库中的类信息
Future<List<GLibrary>> _importLibs(BuildStep buildStep) {
  return Stream.fromFutures(config!.imports
          .where((element) => !element.onlyImport && !element.useExport)
          .map((e) => scanLibrary(buildStep, e))
          .whereType<Future<GLibrary>>())
      .toList();
}

///所有已扫描到的库
final Map<String, GLibrary> libraries = {};

///核心包的导入信息
MImport _coreImport =
    MImport('magic_mirror', libName: 'magic_mirror', onlyImport: false);

///记录配置信息
MMirrorConfig? _config;

///记录配置信息
MMirrorConfig? get config => _config;

///设定配置信息
void setMirrorConfig(MMirrorConfig config) {
  _config = config;
}

Map<String, LibraryElement> _assetsLibCache = {};

///扫描器
class MirrorBuilder implements Builder {
  ///输出文件自动格式化
  final _writeDartFileFormatter = DartFormatter();

  ///缓存已经生成的信息不在二次扫描生成
  String _implementationTemp = '', _registerTemp = '';

  ///输入和输出定义
  @override
  Map<String, List<String>> get buildExtensions {
    return const {
      r'$lib$': [
        'generated/aymtools/mirror/register.mirror.aymtools.dart',
        'generated/aymtools/mirror/project.mirror.aymtools.dart',
        'generated/aymtools/mirror/implementation.mirror.aymtools.dart',
        'mirror_export.dart'
      ]
    };
  }

  ///register的输出文件
  static AssetId _registerFileOutput(BuildStep buildStep) {
    return AssetId(
      buildStep.inputId.package,
      p.join('lib', 'generated', 'aymtools', 'mirror',
          'register.mirror.aymtools.dart'),
    );
  }

  ///project的输出文件
  static AssetId _projectFileOutput(BuildStep buildStep) {
    return AssetId(
      buildStep.inputId.package,
      p.join('lib', 'generated', 'aymtools', 'mirror',
          'project.mirror.aymtools.dart'),
    );
  }

  ///implementation的输出文件
  static AssetId _implementationFileOutput(BuildStep buildStep) {
    return AssetId(
      buildStep.inputId.package,
      p.join('lib', 'generated', 'aymtools', 'mirror',
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
      setMirrorConfig(conf);
      Log.log(
          'config info isGenInvoker:${conf.isGenInvoker} isGenLibExport:${conf.isGenLibExport} '
          'importLibsNames:${conf.imports.map((e) => '${e.packageName}/${e.libName}.dart  onlyImport:${e.onlyImport}  useExport:${e.useExport}')}');

      var libs = await _importLibs(buildStep);
      libs.forEach((element) {
        libraries[element.name] = element;
      });

      if (conf.isGenInvoker) {
        // await libraries.values.forEach((e) => _genLibInvoker(e));
      }
    }

    final libraryInfo = <GLibraryInfo>[];
    await for (final input in buildStep.findAssets(Glob(r'lib/**'))) {
      if (!input.path.startsWith('lib/generated')) {
        final library = await buildStep.resolver.libraryFor(input);
        libraryInfo.add(scanLibraryInfo(LibraryReader(library)));
      }
    }

    var lib = GLibrary(package, package, '',
        libs: libraryInfo.where((element) => element.isNotEmpty).toList());
    AssetsTypeParser parser = (uri) async {
      final uriLib = uri.removeFragment();
      final libUri = uriLib.toString();
      LibraryElement? library;
      if (_assetsLibCache.containsKey(libUri)) {
        library = _assetsLibCache[libUri];
      } else {
        library = await buildStep.resolver.libraryFor(AssetId.resolve(uriLib));
      }
      return library?.getType(uri.fragment)?.thisType;
    };
    if (config!.isGenInvoker) {
      if (_implementationTemp.isEmpty) {
        _implementationTemp = _writeDartFileFormatter.format(
            await genMirrorImplementation(libraries.values.toList(), parser));
      }
      await buildStep.writeAsString(
          _implementationFileOutput(buildStep), _implementationTemp);
      await buildStep.writeAsString(_projectFileOutput(buildStep),
          _writeDartFileFormatter.format(await genCodeMirrorInfo(lib, parser)));
      // await buildStep.writeAsString(_projectFileOutput(buildStep),
      //     await genCodeMirrorInfo(lib, parser));
      if (_registerTemp.isEmpty) {
        _registerTemp = _writeDartFileFormatter.format(genMirrorRegister(
            package, [
          'project.mirror.aymtools.dart',
          'implementation.mirror.aymtools.dart'
        ]));
      }
      await buildStep.writeAsString(
          _registerFileOutput(buildStep), _registerTemp);
    }
    if (config!.isGenLibExport) {
      await buildStep.writeAsString(_exportFileOutput(buildStep), '');
    }
  }
}
