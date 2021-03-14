import 'keygen.dart';

/// 定义Class生成器注解 dart特殊机制 自动化的入口 最好为lib/mirror_config.dart 内初始化速度最快
class MMirrorConfig {
  ///需要扫描的类库
  final Map<String, String> importLibsNames;

  ///是否生成执行内容 生成Register
  final bool isGenInvoker;

  ///是否生成lib库文件 包含所有的注解的类
  final bool isGenLibExport;

  static const int GEN_GROUP_BY_NONE = 0;
  static const int GEN_GROUP_BY_SCHEME = 1;

  ///自动根据不同策略生成调用器的顺序，有可能增加调用器的执行效率 暂未实现
  final int genGroupBy;

  ///导包时的完整自定义类库信息
  final List<MImport> imports;

  const MMirrorConfig({
    this.isGenInvoker = true,
    this.isGenLibExport = false,
    this.importLibsNames = const {},
    this.imports = const [],
    this.genGroupBy = GEN_GROUP_BY_NONE,
  });
}

class MImport {
  final String packageName;
  final String libName;
  final bool onlyImport;
  final bool useExport;

  const MImport(this.packageName,
      {String libName = '', this.onlyImport = false, this.useExport = false})
      : this.libName = libName == '' ? packageName : libName;
}

///基本注解需要的内容
class MAnnotation {
  ///key 主键
  final String key;

  ///tag 附加内容
  final String tag;

  ///ext 扩展属性
  final int ext;

  ///flag 标识属性
  final bool flag;

  const MAnnotation(
      {this.key = '', this.tag = '', this.ext = -1, this.flag = false});
}

/// 定义需要扫描的类或者函数的 扫描配置的注解
class MReflectionEnable extends MAnnotation {
  static const int KEY_GEN_TYPE_BY_DEF = KeyGen.KEY_GEN_TYPE_BY_DEF;
  static const int KEY_GEN_TYPE_BY_URI = KeyGen.KEY_GEN_TYPE_BY_URI;
  static const int KEY_GEN_TYPE_BY_CLASS_NAME =
      KeyGen.KEY_GEN_TYPE_BY_CLASS_NAME;
  static const int KEY_GEN_TYPE_BY_CLASS_SIMPLE_NAME =
      KeyGen.KEY_GEN_TYPE_BY_CLASS_SIMPLE_NAME;
  static const int KEY_GEN_TYPE_BY_SEQUENCE = KeyGen.KEY_GEN_TYPE_BY_SEQUENCE;
  static const int KEY_GEN_TYPE_BY_SEQUENCE_URI =
      KeyGen.KEY_GEN_TYPE_BY_SEQUENCE_URI;

  ///生成主键时的策略
  final int keyGenType;

  ///必须是继承目标或实现目标的类
  final List<Type> needAssignableFrom;

  ///继承任意一个目标或实现目标的类
  final List<Type> anyOneAssignableFrom;

  ///是否允许扫描构造函数
  final bool scanConstructors;

  ///扫描构造函数时使用禁止模式 也就是默认加入
  final bool scanConstructorsUsedBlockList;

  ///是否开启扫描函数
  final bool scanFunctions;

  ///扫描函数时使用禁止模式 也就是默认加入
  final bool scanFunctionsUsedBlockList;

  ///扫描函数时是否扫描父类的函数
  final bool scanSuperFunctions;

  ///是否开启扫描属性
  final bool scanFields;

  ///扫描属性时使用禁止模式 也就是默认加入
  final bool scanFieldsUsedBlockList;

  ///扫描属性时是否扫描父类的属性
  final bool scanSuperFields;

  const MReflectionEnable({
    String key = '',
    String tag = '',
    int ext = -1,
    bool flag = false,
    this.keyGenType = KEY_GEN_TYPE_BY_DEF,
    this.needAssignableFrom = const [],
    this.anyOneAssignableFrom = const [],
    this.scanConstructors = true,
    this.scanConstructorsUsedBlockList = true,
    this.scanFunctions = false,
    this.scanFunctionsUsedBlockList = true,
    this.scanSuperFunctions = false,
    this.scanFields = false,
    this.scanFieldsUsedBlockList = true,
    this.scanSuperFields = false,
  }) : super(key: key, tag: tag, ext: ext, flag: flag);
}

class MReflectionDisable extends MAnnotation {
  const MReflectionDisable();
}
