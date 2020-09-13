import 'package:flutter/material.dart';
import 'package:example/tools/ann.dart';
import 'package:example/entity/user.dart';

@RoutePage("router://example.router.aymtools.com/test1")
class TestPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("第一个测试界面"),
      ),
      body: Center(
        child: Text(
          '这是第一个界面的内容',
        ),
      ),
    );
  }
}

@RoutePage("router://example.router.aymtools.com/test2")
class Test2Page extends StatelessWidget {
  final String content;

  Test2Page({@RoutePageParam("content") this.content});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("第二个测试界面"),
      ),
      body: Center(
        child: Text(
          '这是第二个界面，传递的参数是$content',
        ),
      ),
    );
  }
}

@RoutePage("router://example.router.aymtools.com/test3",
    scanConstructorsUsedBlackList: false)
// ignore: must_be_immutable
class Test3Page extends StatelessWidget {
  String title;
  bool content;
  int age;
  double height;
  User user;

  @RoutePageConstructor(namedConstructor: "jsonTest")
  Test3Page(@RoutePageParam("titleRes") this.title,
      {@RoutePageParam("content") this.content, this.age, this.height});

  @RoutePageConstructor(namedConstructor: "json")
  Test3Page.formJson(String json) {
    title = "title form json";
  }

  @RoutePageConstructor(namedConstructor: "height")
  Test3Page.height(this.height) {
    title = "no title  used height";
  }

//  @RoutePageConstructor(namedConstructor: "json2")
  @RoutePageConstructorNot()
  Test3Page.formJson2(User user) {
    title = "title form ${user.name}";
  }

  Test3Page.formXML(String xml) {
    title = "title form xml";
  }

  @RoutePageConstructor(namedConstructor: "formMap")
  Test3Page.formMap(Map<String, dynamic> map) {
    title = "title form xml";
  }

  @RoutePageConstructor(namedConstructor: "formMap2")
  Test3Page.formMap2(@RoutePageParam("map2") Map<String, String> map) {
    title = "title form xml";
  }

  @RoutePageConstructor(namedConstructor: "formMap3")
  Test3Page.formMap3(Map<String, dynamic> map, {this.content}) {
    title = "title form xml";
  }

  @RoutePageConstructor(namedConstructor: "formAll")
  Test3Page.formAll(this.content, Map<String, dynamic> map) {
    title = "title form xml";
  }

  Test3Page.form2Params(dynamic mapEntity, Map<String, dynamic> mapQuery) {
    title = "title form xml";
  }

  @RoutePageConstructor()
  Test3Page.all(@RoutePageParam("titleRes") String title,
      @RoutePageParam("content") bool content, int age, double height)
      : this._pri(title, content, age, height);

  @RoutePageConstructor()
  Test3Page._pri(@RoutePageParam("titleRes") this.title,
      @RoutePageParam("content") this.content, this.age, this.height);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("第三个测试界面:$title"),
      ),
      body: Center(
        child: Text(
          '这是第三个界面，传递的参数是$content',
        ),
      ),
    );
  }
}
