import 'package:magic_mirror/magic_mirror.dart';

extension Compatible on MagicMirror {
  ///根据注解类型 CLass的类型来获取对应的类信息
  @deprecated
  List<String> findKeys<AnnotationType extends MReflectionEnable, ExtendsType>() =>
      findClasses<AnnotationType, ExtendsType>().map((e) => e.key).toList();

  ///根据注解类型来获取对应的类信息
  @deprecated
  List<String> findKeysByAnnotation<AnnotationType extends MReflectionEnable>() =>
      findClassesByAnnotation<AnnotationType>().map((e) => e.key).toList();

  ///根据CLass的类型来获取对应的类信息
  @deprecated
  List<String> findKeysByExtends<ExtendsType>() =>
      findClassesByExtends<ExtendsType>().map((e) => e.key).toList();

  ///根据key信息自动加载对应的类信息
  @deprecated
  MirrorClass<T, MReflectionEnable> load<T>(String classKey) {
    return this.loadClass<T>(classKey);
  }

  ///根据具体类型 加载对应的类信息 ，可能会找不到 未注册
  @deprecated
  MirrorClass<T, MReflectionEnable> mirror<T>() {
    return this.mirrorClass<T>();
  }
}
