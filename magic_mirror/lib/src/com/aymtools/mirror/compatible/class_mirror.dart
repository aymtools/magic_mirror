import 'package:magic_mirror/magic_mirror.dart';

extension ClassCompatible<T, A extends MReflectionEnable> on MirrorClass<T, A> {
  ///根据map内的参数来生成一个类的实例
  @deprecated
  T newInstanceForMap(String constructorName, Map<String, dynamic> params) =>
      this.newInstance(constructorName, params);
}

extension ConstructorCompatible<T, A extends MReflectionEnable>
    on MirrorConstructor<T, A> {
  ///根据map内的参数来生成一个类的实例
  @deprecated
  T newInstanceForMap(Map<String, dynamic> params) => this.newInstance(params);
}
