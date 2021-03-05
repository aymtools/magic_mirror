//import 'package:aym_router/aym_router.dart';
//
//import '../../entity/user.dart';
//
//@RouterInterceptor("/")
//class RouterLogInterceptor extends RouterInterceptorBase {
//  @override
//  RouterPageArg onInterceptor(RouterPageArg rpa) {
//    print(" RouterLogInterceptor start page : " + rpa.name);
//    return rpa;
//  }
//}
//
//@RouterInterceptor("^/test", priority: 102)
//class RouterLog2Interceptor extends RouterInterceptorBase {
//  @override
//  RouterPageArg onInterceptor(RouterPageArg rpa) {
//    print("RouterLog2Interceptor start page : " + rpa.name);
//    return rpa;
//  }
//}
//
import 'package:example/page/page_home.dart';
import 'package:magic_mirror/mirror.dart';

import '../../entity/user.dart';
import '../../tools/ann.dart';

void init() {}

@RouterInterceptor("^/test", priority: 101, type: HomePage, function: init)
class RouterLog3Interceptor extends RouterInterceptorBase {
  @MField()
  String testSearch;

  // @MField()
  // String get onlyGet => testSearch;
  //
  // @MField()
  // set onlySet(String value) => testSearch = value;

  @MField()
  set search(String value) => testSearch = value;
  @MField()
  get search => testSearch;

  @MFunction()
  void init() {}

  @MFunction()
  String init2(String msg) => msg;

  @MFunction()
  bool init3(String msg, {bool flag, User user}) => flag;

  // @MFunction.a(key: 'aaaaaaaa')
  bool init4({String msg, bool flag, User user}) => flag;

  @override
  RouterPageArg onInterceptor(RouterPageArg rpa) {
    print("RouterLog3Interceptor start page : " + rpa.name);
    return rpa;
  }
}
