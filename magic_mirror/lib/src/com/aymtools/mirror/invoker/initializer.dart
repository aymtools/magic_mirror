import '../core.dart';
import 'invoker.dart';

///魔镜初始化触发器 的父类
abstract class MirrorInitializer {
  ///当初始化时自动调用
  void onInit(MagicMirror mirror);
}

///魔镜初始化触发器 的注解
class OnMirrorInitializer extends MClass {
  const OnMirrorInitializer(String initializerName)
      : super(
          scanConstructors: false,
          key: initializerName == null
              ? ''
              : 'initializer://mirror.aymtools.com/' + initializerName,
          keyGenType: MClass.KEY_GEN_TYPE_BY_URI,
          needAssignableFrom: const <Type>[MirrorInitializer],
        );
}
