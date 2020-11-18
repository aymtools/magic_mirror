import 'package:magic_mirror/mirror.dart';

/// 定义页面路由注解
class RoutePage extends MClass {
  const RoutePage(String uri, {bool scanConstructorsUsedBlackList = false})
      : super(
            key: uri,
            keyGenType: MClass.KEY_GEN_TYPE_BY_URI,
            scanConstructorsUsedBlockList: scanConstructorsUsedBlackList);
}

/// 每个页面都必须添加一个接受此参数的构造函数
class RoutePageParam extends MParam {
  const RoutePageParam(String keyInMap) : super(key: keyInMap);
}

/// 指定页面的构造函数 结合RoutePageConstructorParam 来指定参数来源 不指定参数来源视为无参构造
/// 只可以使用在命名构造函数上 使用在默认构造函数上时 keyInRouter指定 会生成两种构造路径
/// "" 代表默认构造函数 就是非命名构造函数
class RoutePageConstructor extends MConstructor {
  const RoutePageConstructor({String namedConstructor = ""})
      : super(key: namedConstructor);
}

class RoutePageConstructorNot extends MConstructorNot {
  const RoutePageConstructorNot() : super();
}

/// 定义路由的拦截器
class RouterInterceptor extends MClass {
  ///uri 正则表达式所匹配的url priority等级 默认100 从到到底排序 等级越高约优先执行
  const RouterInterceptor(String uri, {int priority = 100})
      : super(
          key: "",
          tag: uri,
          ext: priority,
          keyGenType: MClass.KEY_GEN_TYPE_BY_CLASS_NAME,
          needAssignableFrom: const [RouterInterceptorBase],
          scanConstructors: false,
          scanFunctions: true,
          scanFields: true,
        );
}

class RouterPageArg {
  String _name;
  Uri _uri;

  Object arg;

  final bool isUseGreenChannel;

  RouterPageArg(this._name, {this.arg, bool isUseGreenChannel})
      : this.isUseGreenChannel = isUseGreenChannel ?? false,
        this._uri = Uri.parse(_name);

  String get pageUri => uri.toString();

  Uri get uri => _uri;

  String get name => _name;

  set name(String value) {
    this._name = name;
    _uri = Uri.parse(_name);
  }
}

///路由拦截器 必须有无参构造函数
abstract class RouterInterceptorBase {
  RouterPageArg onInterceptor(RouterPageArg rpa);
}
