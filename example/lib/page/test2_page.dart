import 'package:example/entity/book.dart';
import 'package:example/tools/ann.dart';
import 'package:flutter/material.dart';

@RoutePage("router://example.router.aymtools.com/test5")
class TestPage extends StatelessWidget {
  final String title;
  final bool sex;
  final int age;
  final double height;

  TestPage(
      {@RoutePageParam('titleRes') this.title,
      this.sex,
      this.age,
      this.height});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Router Demo"),
      ),
      body: Center(
          child: GestureDetector(
        onTap: () => Navigator.of(context).pushNamed(
          "/test6",
        ),
        child: Text(
          '这是第五个界面的内容\n'
          'title:$title \nsex:$sex  \nage:$age  \nheight:$height',
        ),
      )),
    );
  }
}

@RoutePage("/test6")
class Test6Page extends StatelessWidget {
  final Text cPage;

  Test6Page({this.cPage});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Router Demo"),
      ),
      body: Center(
        child: Column(
          children: _columnChildren(),
        ),
      ),
    );
  }

  List<Widget> _columnChildren() {
    List<Widget> result = [];
    result.add(Text(
      '这是第六个界面的内容',
    ));
    if (cPage != null) result.add(cPage);
    return result;
  }
}

@RoutePage("router://example.router.aymtools.com/test9")
class Test9Page extends StatelessWidget {
  final Book book;

  Test9Page({this.book});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Router Demo"),
      ),
      body: Center(
        child: Text(
          'book details :\n ${book.toString()}',
        ),
      ),
    );
  }
}

@RoutePage("router://example.router.aymtools.com/test7")
class Test7Page extends StatelessWidget {
  final List<Book> books;

  Test7Page({this.books});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Router Demo"),
      ),
      body: Center(
        child: Text(
          'books :\n ${books.map((e) => e.toString()).reduce((v, e) => '$v,$e')}',
        ),
      ),
    );
  }
}

@RoutePage("router://example.router.aymtools.com/test8")
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
