import '../core.dart';
import 'invoker.dart';

abstract class MirrorInitializer {
  void onInit(MagicMirror factory);
}

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
