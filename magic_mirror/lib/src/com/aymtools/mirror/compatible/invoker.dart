import '../../../../../magic_mirror.dart';

extension Compatible on MagicMirror {
  // ///根据注解类型 CLass的类型来获取对应的类信息
  // List<MirrorClass<ExtendsType, AnnotationType>>
  //     findClasses<AnnotationType extends MClass, ExtendsType>() =>
  //         _mirrorClasses
  //             // .where((element) =>
  //             //     element.type is TypeToken<ExtendsType> &&
  //             //     element.annotationType is TypeToken<AnnotationType>)
  //             .whereType<MirrorClass<ExtendsType, AnnotationType>>()
  //             .toList();
  //
  // ///根据注解类型 CLass的类型来获取对应的类信息
  // List<MirrorClass<dynamic, AnnotationType>>
  //     findClassesByAnnotation<AnnotationType extends MClass>() => _mirrorClasses
  //         .whereType<MirrorClass<dynamic, AnnotationType>>()
  //         // .where(
  //         //     (element) => element.annotationType is TypeToken<AnnotationType>)
  //         .toList();
  //
  // ///根据CLass的类型来获取对应的类信息
  // List<MirrorClass<ExtendsType, MClass>> findClassesByExtends<ExtendsType>() =>
  //     _mirrorClasses
  //         .whereType<MirrorClass<ExtendsType, MClass>>()
  //         // .where((element) => element.type is TypeToken<ExtendsType>)
  //         .toList();

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
