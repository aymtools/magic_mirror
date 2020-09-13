///定义查找class的键的生成策略 返回结果必定为为uri
abstract class KeyGen {
  static const int KEY_GEN_TYPE_BY_DEF = 0;
  static const int KEY_GEN_TYPE_BY_URI = 1;
  static const int KEY_GEN_TYPE_BY_CLASS_NAME = 2;
  static const int KEY_GEN_TYPE_BY_CLASS_SIMPLE_NAME = 3;
  static const int KEY_GEN_TYPE_BY_SEQUENCE = 4;

  static const KeyGen _GEN_TYPE_BY_URI = _KeyGenByUri();
  static const KeyGen _GEN_TYPE_BY_CLASS_NAME = _KeyGenByClassName();
  static const KeyGen _GEN_TYPE_BY_CLASS_SIMPLE_NAME =
      _KeyGenByClassSimpleName();
  static const KeyGen _GEN_TYPE_BY_SEQUENCE = _KeyGenBySequence();

  factory KeyGen(int type) {
    switch (type) {
      case KEY_GEN_TYPE_BY_URI:
        return _GEN_TYPE_BY_URI;
      case KEY_GEN_TYPE_BY_CLASS_NAME:
        return _GEN_TYPE_BY_CLASS_NAME;
      case KEY_GEN_TYPE_BY_CLASS_SIMPLE_NAME:
        return _GEN_TYPE_BY_CLASS_SIMPLE_NAME;
      case KEY_GEN_TYPE_BY_SEQUENCE:
        return _GEN_TYPE_BY_SEQUENCE;
      default:
        return _GEN_TYPE_BY_CLASS_NAME;
    }
  }
  ///由一些信息来生成uri的class key
  String gen(String key, String tag, int ext, String className, String libUri);
}

///直接使用传入的key来生成对应的uri
class _KeyGenByUri implements KeyGen {
  const _KeyGenByUri();

  @override
  String gen(
          String key, String tag, int ext, String className, String libUri) =>
      Uri.parse(key)
          .replace(fragment: '', query: '')
          .toString()
          .replaceAll('?', '')
          .replaceAll('#', '');
}

///自动生成 /类库路径首字母小写的类名 如package:bean_factory/bean_factory.dart中的BeanInfo  生成结果为/bean_factory/bean_factory/beanInfo
class _KeyGenByClassName implements KeyGen {
  const _KeyGenByClassName();

  @override
  String gen(String key, String tag, int ext, String className, String libUri) {
    var url = libUri;
    if (url.endsWith('.dart')) url = url.substring(0, libUri.length - 5);
    if (url.startsWith('package:')) {
      url = url.replaceFirst('package:', '');
      if (url.indexOf('/') > 0) {
        var scheme = url.substring(0, url.indexOf('/'));
        url = url.substring(url.indexOf('/') + 1);
        url = scheme + '://' + url;
      } else {
        url = url.replaceAll('.', '_');
        url = '/' + url;
      }
    } else {
      url = url.replaceAll('.', '_');
      url = '/' + url;
    }
    var simpleName =
        "${(className?.isNotEmpty ?? false) ? '${className[0].toLowerCase()}${className.substring(1)}' : className}";
    return '$url/$simpleName';
  }
}

///自动生成 /首字母小写的类名 如BeanInfo  生成结果为/beanInfo  有可能产生冲突的结果
class _KeyGenByClassSimpleName implements KeyGen {
  const _KeyGenByClassSimpleName();

  @override
  String gen(
          String key, String tag, int ext, String className, String libUri) =>
      "/${(className?.isNotEmpty ?? false) ? '${className[0].toLowerCase()}${className.substring(1)}' : className}";
}

///自动生成 /class/classSequence$num  num自动增长
class _KeyGenBySequence implements KeyGen {
  static int next = 0;

  const _KeyGenBySequence();

  @override
  String gen(
          String key, String tag, int ext, String className, String libUri) =>
      '/class/classSequence${++next}';
}
