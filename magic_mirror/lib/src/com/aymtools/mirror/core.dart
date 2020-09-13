import 'keygen.dart';

/// 定义Bean生成器注解 dart特殊机制 自动化的入口
class MirrorConfig {
  final Map<String, String> importLibsNames;

  final bool isGenInvoker;
  final bool isGenLibExport;

  static const int GEN_GROUP_BY_NONE = 0;
  static const int GEN_GROUP_BY_SCHEME = 1;

  ///自动根据不同策略生成调用器的顺序，有可能增加调用器的执行效率 暂未实现
  final int genGroupBy;

  const MirrorConfig({
    bool isGenInvoker,
    bool isGenLibExport,
    Map<String, String> importLibsNames,
    int genGroupBy = GEN_GROUP_BY_NONE,
  })  : isGenInvoker = isGenInvoker ?? true,
        isGenLibExport = isGenLibExport ?? false,
        genGroupBy = GEN_GROUP_BY_NONE,
        importLibsNames = importLibsNames ?? const {};
}

///基本注解需要的内容
abstract class AnnBase {
  final String key;
  final String tag;
  final int ext;
  final bool flag;
  final Type extType;
  final String tag1;
  final int ext1;
  final bool flag1;

  final List<String> tagList;
  final List<int> extList;
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

  final int keyGenType;

  ///必须是继承目标或实现目标的类
  final List<Type> needAssignableFrom;

  ///继承任意一个目标或实现目标的类
  final List<Type> anyOneAssignableFrom;

  final bool scanConstructors = true;
  final bool scanConstructorsUsedBlackList;
  final bool scanMethods;
  final bool scanMethodsUsedBlackList;
  final bool scanSuperMethods;
  final bool scanFields;
  final bool scanFieldsUsedBlackList;
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
    bool scanConstructors,
    this.scanConstructorsUsedBlackList = false,
    this.scanMethods = false,
    this.scanMethodsUsedBlackList = false,
    this.scanSuperMethods = false,
    this.scanFields = false,
    this.scanFieldsUsedBlackList = false,
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

//  bool get isNeedScanConstructors => scanConstructors;
//
//  bool get isNeedScanMethods => scanMethods || scanSuperMethods;
//
//  bool get isNeedScanSuperMethods => scanSuperMethods;
//
//  bool get isNeedScanFields => scanFields || scanSuperFields;
//
//  bool get isNeedScanSuperFields => scanSuperMethods;
}

/// 指定Bean的构造函数 结合 BeanCreateParam 来指定参数来源 不指定参数来源视为无参构造
/// 只可以使用在命名构造函数上 使用在默认构造函数上时  会生成两种构造路径
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

///黑名单模式模式时有效 不扫描的构造函数
class MConstructorNot {
  const MConstructorNot();
}

///一般用来测试接受到的参数 构造函数 必须为两个参数 的第一个参数为dynamic类型(调用者传入参数) 第二个为Map<String,dynamic>(uri中参数) 类型 若不符要求则不识别当前的构造函数
class MConstructorFor2Params extends MConstructor {
  const MConstructorFor2Params({
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

/// Bean构造函数或factory或方法体参数指定在map参数中的名字
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

///黑名单模式模式时有效 不扫描的方法
class MMethodNot {
  const MMethodNot();
}

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

///黑名单模式模式时有效 不扫描的属性
class MFieldNot {
  const MFieldNot();
}
