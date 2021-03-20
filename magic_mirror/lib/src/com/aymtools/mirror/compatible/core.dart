import 'package:magic_mirror/magic_mirror.dart';

//兼容旧版本的config
@deprecated
class MirrorConfig extends MMirrorConfig {
  static const int GEN_GROUP_BY_NONE = MMirrorConfig.GEN_GROUP_BY_NONE;
  static const int GEN_GROUP_BY_SCHEME = MMirrorConfig.GEN_GROUP_BY_SCHEME;

  const MirrorConfig({
    bool isGenInvoker = true,
    bool isGenLibExport = false,
    Map<String, String> importLibsNames = const {},
    List<MImport> imports = const [],
    int genGroupBy = GEN_GROUP_BY_NONE,
  }) : super(
          isGenInvoker: isGenInvoker,
          isGenLibExport: isGenLibExport,
          importLibsNames: importLibsNames,
          imports: imports,
          genGroupBy: genGroupBy,
        );
}

/// 定义Class的注解
@deprecated
class MClass extends MReflectionEnable {
  const MClass({
    String key = '',
    String tag = '',
    int ext = -1,
    bool flag = false,
    int keyGenType = GenUri.GEN_URI_TYPE_BY_DEF,
    List<Type> needAssignableFrom = const [],
    List<Type> anyOneAssignableFrom = const [],
    bool scanConstructors = true,
    bool scanConstructorsUsedBlockList = false,
    bool scanFunctions = false,
    bool scanFunctionsUsedBlockList = false,
    bool scanSuperFunctions = false,
    bool scanFields = false,
    bool scanFieldsUsedBlockList = false,
    bool scanSuperFields = false,
  }) : super(
          key: key,
          tag: tag,
          ext: ext,
          flag: flag,
          genUriType: keyGenType,
          needAssignableFrom: needAssignableFrom,
          anyOneAssignableFrom: anyOneAssignableFrom,
          scanConstructors: scanConstructors,
          scanConstructorsUsedBlockList: scanConstructorsUsedBlockList,
          scanFunctions: scanFunctions,
          scanFunctionsUsedBlockList: scanFunctionsUsedBlockList,
          scanSuperFunctions: scanSuperFunctions,
          scanFields: scanFields,
          scanFieldsUsedBlockList: scanFieldsUsedBlockList,
          scanSuperFields: scanSuperFields,
        );
}

/// 指定Class的构造函数
/// 当使用在默认构造函数上时（非命名构造函数）  会生成两种构造路径
/// "" 代表默认构造函数 就是非命名构造函数
@deprecated
class MConstructor extends MAnnotation {
  const MConstructor(
      {String key = '', String tag = '', int ext = -1, bool flag = false})
      : super(key: key, tag: tag, ext: ext, flag: flag);
}

///构造函数必须时必须的map参数 且只有一个参数Map<String,dynamic>类型的参数 默认是uri的参数叠加传入的Map参数 若传入的arg非map则以null的key的值存在
// class MConstructorMapArg extends MConstructor {
//   const MConstructorMapArg({String key = ''}) : super(key: key);
// }

///禁止模式模式时有效 不扫描的构造函数
@deprecated
class MConstructorNot extends MReflectionDisable {
  const MConstructorNot();
}

/// 函数的参数 构造函数也是 可用来指定map中key 与实际不一致
@deprecated
class MParam extends MAnnotation {
  const MParam(
      {String key = '', String tag = '', int ext = -1, bool flag = false})
      : super(key: key, tag: tag, ext: ext, flag: flag);
}

/// 标注Class内的函数
@deprecated
class MFunction extends MAnnotation {
  const MFunction(
      {String key = '', String tag = '', int ext = -1, bool flag = false})
      : super(key: key, tag: tag, ext: ext, flag: flag);
}

///禁止模式模式时有效 不扫描的方法
@deprecated
class MFunctionNot extends MReflectionDisable {
  const MFunctionNot();
}

///指定Class的属性
@deprecated
class MField extends MAnnotation {
  const MField(
      {String key = '', String tag = '', int ext = -1, bool flag = false})
      : super(key: key, tag: tag, ext: ext, flag: flag);
}

///禁止模式时有效 不扫描的属性
@deprecated
class MFieldNot extends MReflectionDisable {
  const MFieldNot();
}
