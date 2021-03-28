import 'package:magic_mirror/magic_mirror.dart';

///类镜像的兼容包
extension ClassCompatible<T, A extends MReflectionEnable> on MirrorClass<T, A> {
  ///根据map内的参数来生成一个类的实例
  @deprecated
  T newInstanceForMap(String constructorName, Map<String, dynamic> params) =>
      this.newInstance(constructorName, params);
}

///构造函数的兼容包
extension ConstructorCompatible<T, A extends MReflectionEnable>
    on MirrorConstructor<T, A> {
  ///根据map内的参数来生成一个类的实例
  @deprecated
  T newInstanceForMap(Map<String, dynamic> params) => this.newInstance(params);
}
