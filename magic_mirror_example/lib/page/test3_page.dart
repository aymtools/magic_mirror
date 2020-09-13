import 'package:example/tools/ann.dart';
import 'package:flutter/material.dart';

@RoutePage("router://example.router.aymtools.com/test9")
class Test8Page extends StatelessWidget {
  final String title;

//  final Book book;

//  _Test8Page({this.title, this.book});
  Test8Page._(this.title);

  factory Test8Page(String name) => Test8Page._(name);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Router Demo"),
      ),
      body: Center(
        child: Text(
          '使用定义的factory创建的界面 $title',
        ),
      ),
    );
  }
}

@RoutePage("router://example.router.aymtools.com/test10")
class Test1Page extends StatelessWidget {
  final String title;

//  final Book book;

//  _Test8Page({this.title, this.book});
  Test1Page._(this.title);

  factory Test1Page(String name) => Test1Page._(name);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Router Demo"),
      ),
      body: Center(
        child: Text(
          '使用定义的factory创建的界面 $title',
        ),
      ),
    );
  }
}
