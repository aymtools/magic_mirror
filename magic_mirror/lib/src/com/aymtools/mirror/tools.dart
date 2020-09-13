///查找第一个符合条件的内容 可以返回null
E findFistWhere<E>(List<E> list, bool Function(E element) test, {E orElse}) {
  for (var element in list) {
    if (test(element)) return element;
  }
  return orElse;
}

///深层copy list
List<E> cloneList<E>(List<E> source, E Function(E e) cloneFun) {
  return List.generate(source.length, (e) => cloneFun(source[e]),
      growable: true);
}

///list中根据某条属性去重 keepBehind=true 从后往前去重 保留后边
List<E> removeDuplicate<E, P>(List<E> list, P Function(E element) getProperty,
    {bool keepBehind = true}) {
  var result = <E>[];
  var iterator = keepBehind ? list.reversed.iterator : list.iterator;
  final propertyCache = <P>{};
  while (iterator.moveNext()) {
    var e = iterator.current;
    var p = getProperty(e);
    if (!propertyCache.contains(p)) {
      propertyCache.add(getProperty(e));
      result.add(e);
    }
  }
  return result;
}

///将参数生成为可调用函数的map信息
Map<String, dynamic> genParams(
    dynamic param, Map<String, String> uriParams, String putKey) {
  var params = Map<String, dynamic>.from(uriParams);
  //bool f = param != null && param is Map<String, dynamic>;
  if (param != null) {
    if (param is Map<String, dynamic>) {
      params.addAll(param);
    } else {
      params[putKey] = param;
    }
  }
  return params;
}

///一个键值的容器
class Pair<K, V> {
  ///键
  K key;

  ///值
  V value;

  Pair(this.key, this.value);
}
