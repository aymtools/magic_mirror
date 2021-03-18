import '../core.dart';
import '../keygen.dart';
import 'invoker.dart';

///魔镜初始化触发器 的父类
abstract class Initializer {
  ///当初始化时自动调用
  void onInit(MagicMirror mirror);
}

///魔镜初始化触发器 的注解
class OnInitializer extends MReflectionEnable {
  const OnInitializer()
      : super(
          scanConstructors: true,
          key: 'initializer://mirror.aymtools.com/',
          genUriType: GenUri.GEN_URI_TYPE_BY_SEQUENCE_KEY,
          needAssignableFrom: const <Type>[Initializer],
        );
}
