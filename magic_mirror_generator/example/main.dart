import 'package:magic_mirror/magic_mirror.dart';

// 导入Register
// import 'generated/aymtools/mirror/register.mirror.aymtools.dart';

@MReflectionEnable(
    key: '/class/book',
    keyGenType: KeyGen.KEY_GEN_TYPE_BY_URI,
    scanFields: true,
    scanFunctions: true)
class Book {
  String name;

  String author;

  double price;

  Book(this.name, this.author) : price = 1.0;

  Book.price(this.name, this.author, this.price);

  Book.custom(this.name, {this.author = '', this.price = 1.0});

  void printInfo() {
    print('book info name:$name author:$author price:$price');
  }

  double calculatePrice(double sale) => sale * (price);

  @MReflectionDisable()
  double calculatePriceSale(double sale) => sale * (price);
}

@MMirrorConfig()
void main() {
  //注册相关的类信息
  // Register.register();

  var clazz = MagicMirror.instance.load('/class/book');
  var book = clazz.newInstance('', {'name': 'book1', 'author': 'author1'});

  var authorField = clazz.getField('auth');
  print(authorField.get(book)); // print  author1

  var priceField = clazz.getField('price');
  priceField.set(book, 2.0);
  print(priceField.get(book)); // print  2.0

  var bookPrintFunction = clazz.getFunction('printInfo');
  bookPrintFunction
      .invoke(book, {}); // print book info name:book1 author:author1 price:2'

  var calculatePriceFunction = clazz.getFunction('calculatePrice');
  double currPrice = calculatePriceFunction.invoke(book, {'sale': 0.5});

  print(currPrice); // print  1.0
}
