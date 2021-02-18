import 'keygen.dart';

/// 定义Class生成器注解 dart特殊机制 自动化的入口 必须为lib/mirror_config.dart 内
class MirrorConfig {
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

  final List<MImport> imports;
  final Function function;

  const MirrorConfig({
    bool isGenInvoker,
    bool isGenLibExport,
    Map<String, String> importLibsNames,
    List<MImport> imports,
    int genGroupBy = GEN_GROUP_BY_NONE,
    this.function,
  })  : isGenInvoker = isGenInvoker ?? true,
        isGenLibExport = isGenLibExport ?? false,
        genGroupBy = GEN_GROUP_BY_NONE,
        importLibsNames = importLibsNames ?? const {},
        this.imports = imports ?? const [];
}

class MImport {
  final String packageName;
  final String libName;
  final bool onlyImport;
  final bool useExport;
  final List<String> show;
  final List<String> hide;

  const MImport(
      {String packageName,
      String libName,
      bool onlyImport,
      bool useExport,
      List<String> show,
      List<String> hide})
      : this.packageName = packageName,
        this.libName = libName == null || libName == '' ? packageName : libName,
        this.onlyImport = onlyImport ?? false,
        this.useExport = useExport ?? false,
        this.show = show ?? const [],
        this.hide = hide ?? const [];
}

///基本注解需要的内容
abstract class AnnBase {
  ///key 主键
  final String key;

  ///tag 附加内容
  final String tag;

  ///ext 扩展属性
  final int ext;

  ///flag 标识属性
  final bool flag;

  ///extType 标识Type的属性 暂未实现
  final Type extType;

  ///tag1 附加内容1
  final String tag1;

  ///ext1 扩展属性1
  final int ext1;

  ///flag1 标识属性1
  final bool flag1;

  ///String的标识列表
  final List<String> tagList;

  ///int的标识列表
  final List<int> extList;

  ///Type的标识列表 暂未实现
  final List<Type> extTypeList;

  const AnnBase(
      {this.key,
      this.tag,
      this.ext,
      this.flag,
      this.extType,
      this.tag1,
      this.ext1,
      this.flag1,
      this.tagList,
      this.extList,
      this.extTypeList});
}

/// 定义Class的注解
class MClass extends AnnBase {
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

  const MClass({
    String key = '',
    String tag = '',
    int ext = -1,
    bool flag = false,
    String tag1 = '',
    int ext1 = -1,
    bool flag1 = false,
    List<String> tagList = const [],
    List<int> extList = const [],
    this.keyGenType = KEY_GEN_TYPE_BY_DEF,
    this.needAssignableFrom = const [],
    this.anyOneAssignableFrom = const [],
    this.scanConstructors = true,
    this.scanConstructorsUsedBlockList = false,
    this.scanFunctions = false,
    this.scanFunctionsUsedBlockList = false,
    this.scanSuperFunctions = false,
    this.scanFields = false,
    this.scanFieldsUsedBlockList = false,
    this.scanSuperFields = false,
  }) : super(
            key: key,
            tag: tag,
            ext: ext,
            flag: flag,
            tag1: tag1,
            ext1: ext1,
            flag1: flag1,
            tagList: tagList,
            extList: extList);
}

/// 指定Class的构造函数
/// 当使用在默认构造函数上时（非命名构造函数）  会生成两种构造路径
/// "" 代表默认构造函数 就是非命名构造函数
class MConstructor extends AnnBase {
  const MConstructor({
    String key = '',
    String tag = '',
    int ext = -1,
    bool flag = false,
    String tag1 = '',
    int ext1 = -1,
    bool flag1 = false,
    List<String> tagList = const [],
    List<int> extList = const [],
  }) : super(
            key: key,
            tag: tag,
            ext: ext,
            flag: flag,
            tag1: tag1,
            ext1: ext1,
            flag1: flag1,
            tagList: tagList,
            extList: extList);
}

///构造函数必须时必须的map参数 且只有一个参数Map<String,dynamic>类型的参数 默认是uri的参数叠加传入的Map参数 若传入的arg非map则以null的key的值存在
class MConstructorMapArg extends MConstructor {
  const MConstructorMapArg({String key = ''}) : super(key: key);
}

///禁止模式模式时有效 不扫描的构造函数
class MConstructorNot {
  const MConstructorNot();
}

/// 函数的参数 构造函数也是 可用来指定map中key 与实际不一致
class MParam extends AnnBase {
  const MParam({
    String key = '',
    String tag = '',
    int ext = -1,
    bool flag = false,
    String tag1 = '',
    int ext1 = -1,
    bool flag1 = false,
    List<String> tagList = const [],
    List<int> extList = const [],
  }) : super(
            key: key,
            tag: tag,
            ext: ext,
            flag: flag,
            tag1: tag1,
            ext1: ext1,
            flag1: flag1,
            tagList: tagList,
            extList: extList);
}

/// 标注Class内的函数
class MFunction extends AnnBase {
  const MFunction({
    String key = '',
    String tag = '',
    int ext = -1,
    bool flag = false,
    String tag1 = '',
    int ext1 = -1,
    bool flag1 = false,
    List<String> tagList = const [],
    List<int> extList = const [],
  }) : super(
            key: key,
            tag: tag,
            ext: ext,
            flag: flag,
            tag1: tag1,
            ext1: ext1,
            flag1: flag1,
            tagList: tagList,
            extList: extList);
}

///禁止模式模式时有效 不扫描的方法
class MMethodNot {
  const MMethodNot();
}

///指定Class的属性
class MField extends AnnBase {
  const MField({
    String key = '',
    String tag = '',
    int ext = -1,
    bool flag = false,
    String tag1 = '',
    int ext1 = -1,
    bool flag1 = false,
    List<String> tagList = const [],
    List<int> extList = const [],
  }) : super(
            key: key,
            tag: tag,
            ext: ext,
            flag: flag,
            tag1: tag1,
            ext1: ext1,
            flag1: flag1,
            tagList: tagList,
            extList: extList);
}

///禁止模式时有效 不扫描的属性
class MFieldNot {
  const MFieldNot();
}
