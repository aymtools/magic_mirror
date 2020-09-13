E findFistWhere<E>(List<E> list, bool Function(E element) test, {E orElse}) {
  for (var element in list) {
    if (test(element)) return element;
  }
  return orElse;
}

List<E> cloneList<E>(List<E> source, E Function(E e) cloneFun) {
  return List.generate(source.length, (e) => cloneFun(source[e]),
      growable: true);
}

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

class Pair<K, V> {
  K key;
  V value;

  Pair(this.key, this.value);
}

class BoxThree<A, B, C> {
  A a;
  B b;
  C c;

  BoxThree(this.a, this.b, this.c);
}
