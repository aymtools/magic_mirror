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

///类型转换器 当调用属性 函数 时类型不匹配时来完成转换动作 支持正向转换与反向转换
abstract class TypeConvertAdapter<From, To> extends TypeConvert<From, To> {
  //反转
  From reverse(To value);
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
// @OnInitializer()
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
class Int2String extends TypeConvertAdapter<int, String> {
  @override
  String convert(int value) {
    return value.toString();
  }

  @override
  int reverse(String value) {
    if (value == null || value.isEmpty) return 0;
    return int.tryParse(value);
  }
}

///默认的类型转换器 bool to String
@TypeAdapter(adapterName: 'Boolean2String')
class Boolean2String extends TypeConvertAdapter<bool, String> {
  @override
  String convert(bool value) {
    return value.toString();
  }

  @override
  bool reverse(String value) {
    return ('true' == value);
  }
}

///默认的类型转换器 double to String
@TypeAdapter(adapterName: 'Double2String')
class Double2String extends TypeConvertAdapter<double, String> {
  @override
  String convert(double value) {
    return value.toString();
  }

  @override
  double reverse(String value) {
    if (value == null || value.isEmpty) return 0;
    return double.tryParse(value);
  }
}

///默认的类型转换器 int to double
@TypeAdapter(adapterName: 'Int2Double')
class Int2Double extends TypeConvertAdapter<int, double> {
  @override
  double convert(int value) {
    return value.toDouble();
  }

  @override
  int reverse(double value) {
    return value.toInt();
  }
}

///默认的类型转换器 double to bool
@TypeAdapter(adapterName: 'Double2Bool')
class Double2Bool extends TypeConvertAdapter<double, bool> {
  @override
  bool convert(double value) {
    return value == 1;
  }

  @override
  double reverse(bool value) {
    return value ? 1 : 0;
  }
}

///默认的类型转换器 int to bool
@TypeAdapter(adapterName: 'Int2Bool')
class Int2Bool extends TypeConvertAdapter<int, bool> {
  @override
  bool convert(int value) {
    return value == 1;
  }

  @override
  int reverse(bool value) {
    return value ? 1 : 0;
  }
}
