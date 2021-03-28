import '../keygen.dart';

///定义查找class的键的生成策略 返回结果必定为为uri 兼容包
@deprecated
abstract class KeyGen implements GenUri {
  static const int KEY_GEN_TYPE_BY_DEF = GenUri.GEN_URI_TYPE_BY_DEF;
  static const int KEY_GEN_TYPE_BY_URI = GenUri.GEN_URI_TYPE_BY_KEY;
  static const int KEY_GEN_TYPE_BY_CLASS_NAME = GenUri.GEN_URI_TYPE_BY_NAME;
  static const int KEY_GEN_TYPE_BY_CLASS_SIMPLE_NAME =
      GenUri.GEN_URI_TYPE_BY_SIMPLE_NAME;
  static const int KEY_GEN_TYPE_BY_SEQUENCE = GenUri.GEN_URI_TYPE_BY_SEQUENCE;
  static const int KEY_GEN_TYPE_BY_SEQUENCE_URI =
      GenUri.GEN_URI_TYPE_BY_SEQUENCE_KEY;
}
