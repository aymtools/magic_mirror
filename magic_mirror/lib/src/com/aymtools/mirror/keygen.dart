///定义查找class的键的生成策略 返回结果必定为为uri
abstract class GenUri {
  ///默认值 使用自增长
  static const int GEN_URI_TYPE_BY_DEF = 0;

  ///依据key解析为Uri
  static const int GEN_URI_TYPE_BY_KEY = 1;

  ///依据路径+名字
  static const int GEN_URI_TYPE_BY_NAME = 2;

  ///依据只包含类名 函数名
  static const int GEN_URI_TYPE_BY_SIMPLE_NAME = 3;

  ///自增长
  static const int GEN_URI_TYPE_BY_SEQUENCE = 4;

  ///依据提供的key一部分叠加 一部分自增长
  static const int GEN_URI_TYPE_BY_SEQUENCE_KEY = 5;

  static const GenUri _GEN_TYPE_BY_KEY = _GenUriByKey();
  static const GenUri _GEN_TYPE_BY_NAME = _GenUriByName();
  static const GenUri _GEN_TYPE_BY_SIMPLE_NAME = _GenUriBySimpleName();
  static const GenUri _GEN_TYPE_BY_SEQUENCE = _GenUriBySequence();
  static const GenUri _GEN_TYPE_BY_SEQUENCE_KEY = _GenUriBySequenceAndKey();

  factory GenUri(int type) {
    switch (type) {
      case GEN_URI_TYPE_BY_KEY:
        return _GEN_TYPE_BY_KEY;
      case GEN_URI_TYPE_BY_NAME:
        return _GEN_TYPE_BY_NAME;
      case GEN_URI_TYPE_BY_SIMPLE_NAME:
        return _GEN_TYPE_BY_SIMPLE_NAME;
      case GEN_URI_TYPE_BY_SEQUENCE:
        return _GEN_TYPE_BY_SEQUENCE;
      case GEN_URI_TYPE_BY_SEQUENCE_KEY:
        return _GEN_TYPE_BY_SEQUENCE_KEY;
      default:
        return _GEN_TYPE_BY_NAME;
    }
  }

  ///由一些信息来生成uri的 key
  String gen(String key, String tag, int ext, String className, String libUri);
}

///直接使用传入的key来生成对应的uri
class _GenUriByKey implements GenUri {
  const _GenUriByKey();

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
class _GenUriByName implements GenUri {
  const _GenUriByName();

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
class _GenUriBySimpleName implements GenUri {
  const _GenUriBySimpleName();

  @override
  String gen(
          String key, String tag, int ext, String className, String libUri) =>
      "/${(className?.isNotEmpty ?? false) ? '${className[0].toLowerCase()}${className.substring(1)}' : className}";
}

///自动生成 /class/classSequence$num  num自动增长
class _GenUriBySequence implements GenUri {
  static int next = 0;

  const _GenUriBySequence();

  @override
  String gen(
          String key, String tag, int ext, String className, String libUri) =>
      '/class/classSequence${++next}';
}

///自动生成 ${key}/class/classSequence$num  num自动增长
class _GenUriBySequenceAndKey implements GenUri {
  const _GenUriBySequenceAndKey();

  @override
  String gen(String key, String tag, int ext, String className, String libUri) {
    String keyUri = Uri.parse(key)
        .replace(fragment: '', query: '', path: '')
        .toString()
        .replaceAll('?', '')
        .replaceAll('#', '');
    return '${keyUri}/class/classSequence${++_GenUriBySequence.next}';
  }
}
