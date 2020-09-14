import '../core.dart';
import 'initializer.dart';
import 'invoker.dart';

///类型转换器 当调用属性 函数 时类型不匹配时来完成转换动作
abstract class TypeConvert<From, To> {
  Type get from => From;

  Type get to => To;

  //转换
  To convert(From value);
}

///定义自定义的转换器
class TypeAdapter extends MClass {
  const TypeAdapter({String adapterName})
      : super(
            key: adapterName == null || adapterName == ''
                ? 'typeAdapter://mirror.aymtools.com/'
                : 'typeAdapter://mirror.aymtools.com/' + adapterName,
            keyGenType: adapterName == null || adapterName == ''
                ? MClass.KEY_GEN_TYPE_BY_SEQUENCE_URI
                : MClass.KEY_GEN_TYPE_BY_URI,
            needAssignableFrom: const <Type>[TypeConvert]);
}

///自动加载所有的转换器的初始化触发器
@OnInitializer()
class LoadTypeAdapter implements Initializer {
  @override
  void onInit(MagicMirror factory) {
    factory.loadTypeAdapter().forEach((element) {
      factory.registerTypeAdapter2(element);
    });
  }
}

///默认的类型转换器 int to String
@TypeAdapter(adapterName: 'Int2String')
class Int2String extends TypeConvert<int, String> {
  @override
  String convert(int value) {
    return value.toString();
  }
}

///默认的类型转换器 bool to String
@TypeAdapter(adapterName: 'Boolean2String')
class Boolean2String extends TypeConvert<bool, String> {
  @override
  String convert(bool value) {
    return value.toString();
  }
}

///默认的类型转换器 double to String
@TypeAdapter(adapterName: 'Double2String')
class Double2String extends TypeConvert<double, String> {
  @override
  String convert(double value) {
    return value.toString();
  }
}

///默认的类型转换器 String to int
@TypeAdapter(adapterName: 'String2Int')
class String2Int extends TypeConvert<String, int> {
  @override
  int convert(String value) {
    return int.tryParse(value);
  }
}

///默认的类型转换器 String to bool
@TypeAdapter(adapterName: 'String2Boolean')
class String2Boolean extends TypeConvert<String, bool> {
  @override
  bool convert(String value) {
    return value == 'true';
  }
}

///默认的类型转换器 String to double
@TypeAdapter(adapterName: 'String2Double')
class String2Double extends TypeConvert<String, double> {
  @override
  double convert(String value) {
    return double.tryParse(value);
  }
}

///默认的类型转换器 int to double
@TypeAdapter(adapterName: 'Int2Double')
class Int2Double extends TypeConvert<int, double> {
  @override
  double convert(int value) {
    return value.toDouble();
  }
}

///默认的类型转换器 double to int
@TypeAdapter(adapterName: 'Double2Int')
class Double2Int extends TypeConvert<double, int> {
  @override
  int convert(double value) {
    return value.toInt();
  }
}

///默认的类型转换器 double to bool
@TypeAdapter(adapterName: 'Double2Bool')
class Double2Bool extends TypeConvert<double, bool> {
  @override
  bool convert(double value) {
    return value == 1;
  }
}

///默认的类型转换器 int to bool
@TypeAdapter(adapterName: 'Int2Bool')
class Int2Bool extends TypeConvert<int, bool> {
  @override
  bool convert(int value) {
    return value == 1;
  }
}

///默认的类型转换器 bool to double
@TypeAdapter(adapterName: 'Double2Bool')
class Bool2Double extends TypeConvert<bool, double> {
  @override
  double convert(bool value) {
    return value ? 1 : 0;
  }
}

///默认的类型转换器 bool to int
@TypeAdapter(adapterName: 'Bool2Int')
class Bool2Int extends TypeConvert<bool, int> {
  @override
  int convert(bool value) {
    return value ? 1 : 0;
  }
}
