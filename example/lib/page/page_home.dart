import 'package:example/tools/ann.dart';
import 'package:example/entity/book.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

@RoutePage("router://example.router.aymtools.com/home")
class HomePage extends StatelessWidget {
  final String content;

  final List<FunMenu> data = [];

  HomePage({this.content}) : super();

  void _initFunMenu() {
    data.clear();
    data.add(FunMenu('正常无参的界面', 'router://example.router.aymtools.com/test1'));
    data.add(FunMenu('uri无scheme无host即 /test6', '/test6'));
    data.add(FunMenu('可传入一个String参数 content=hello',
        'router://example.router.aymtools.com/test2',
        args: 'hello'));
    data.add(FunMenu(
        '可传入各个基本类型的参数', 'router://example.router.aymtools.com/test5', args: {
      'titleRes': 'String type title',
      'sex': true,
      'age': 18,
      'height': 1.88
    }));
    data.add(FunMenu(
        '传入自定义实体类Book', 'router://example.router.aymtools.com/test9',
        args: Book('西游记', '罗贯中', 1.0)));
    data.add(FunMenu(
        '传入自定义实体类集合 List<Book>', 'router://example.router.aymtools.com/test7',
        args: <Book>[
          Book('西游记', '吴承恩', 1.0),
          Book('三国演义', '罗贯中', 2.0),
          Book('红楼梦', '曹雪芹', 3.0),
          Book('水浒传', '施耐庵', 4.0)
        ]));
    data.add(FunMenu('传入自定义Widget 开启套娃模式', '/test6', args: Text('套娃的Text')));
    data.add(FunMenu(
        '使用定义的factory name=hello', 'router://example.router.aymtools.com/test8',
        args: 'hello'));
    data.add(FunMenu(
        '跳入Lib的Page', 'router://example.router.aymtools.com/test10',
        args: 'example'));
    data.add(
        FunMenu('最复杂的参数列表界面', 'router://example.router.aymtools.com/test3'));
  }

  @override
  Widget build(BuildContext context) {
    _initFunMenu();
    return Scaffold(
      appBar: AppBar(
        title: Text("这里是主界面"),
      ),
      body: Container(
        padding: EdgeInsets.all(10),
        child: Center(
          child: Column(
            children: <Widget>[
              Text(
                '来自Uri中的参数\ncontent:$content',
              ),
              Expanded(
                child: ListView.separated(
                    separatorBuilder: (context, index) => Divider(
                          color: Colors.blue,
                        ),
                    itemCount: data.length,
                    itemBuilder: (context, index) => RaisedButton(
                          child: Text('${data[index].title}'),
                          onPressed: () => Navigator.of(context).pushNamed(
                              data[index].uri,
                              arguments: data[index].args),
                        )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class B {

}

class FunMenu {
  final String title;
  final String uri;
  final dynamic args;

  FunMenu(this.title, this.uri, {this.args});
}
