import '../../../../../magic_mirror.dart';

///提供之前版本的兼容包
extension Compatible on MagicMirror {
  ///根据注解类型 CLass的类型来获取对应的类信息
  @deprecated
  List<String> findKeys<AnnotationType extends MClass, ExtendsType>() =>
      findClasses<AnnotationType, ExtendsType>().map((e) => e.key).toList();

  ///根据注解类型来获取对应的类信息
  @deprecated
  List<String> findKeysByAnnotation<AnnotationType extends MClass>() =>
      findClassesByAnnotation<AnnotationType>().map((e) => e.key).toList();

  ///根据CLass的类型来获取对应的类信息
  @deprecated
  List<String> findKeysByExtends<ExtendsType>() =>
      findClassesByExtends<ExtendsType>().map((e) => e.key).toList();

  ///根据key信息自动加载对应的类信息
  MirrorClass<T, MClass> load<T>(String classKey) {
    var result = this.load<T>(classKey);
    if (result is MirrorClass<T, MClass>) {
      return result;
    }
    throw ClassNotFoundException(classKey);
  }

  ///根据具体类型 加载对应的类信息 ，可能会找不到 未注册
  MirrorClass<T, MClass> mirror<T>() {
    var result = this.mirrorClass<T>();
    if (result is MirrorClass<T, MClass>) {
      return result;
    }
    throw ClassNotConfigException(MagicMirror.genType<T>());
  }
}
