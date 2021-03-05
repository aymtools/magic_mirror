import 'package:magic_mirror/mirror.dart';

import 'generated/aymtools/mirror/register.mirror.aymtools.dart';

@MClass(
    key: '/class/book',
    keyGenType: KeyGen.KEY_GEN_TYPE_BY_URI,
    scanFields: true,
    scanFunctions: true)
class Book {
  @MField()
  String name;

  @MField(key: 'auth')
  String author;

  @MField()
  double price;

  @MConstructor()
  Book(this.name, this.author);

  @MConstructor()
  Book.price(this.name, this.author, this.price);

  @MConstructor()
  Book.custom(this.name, {this.author, this.price});

  @MFunction()
  void printInfo() {
    print('book info name:$name author:$author price:$price');
  }

  @MFunction()
  double calculatePrice(double sale) => sale * (price ?? 1);
}

@MirrorConfig()
void main() {

  Register.register();

  var clazz = MagicMirror.instance.load('/class/book');
  var book =
  clazz.newInstanceForMap('', {'name': 'book1', 'author': 'author1'});

  var authorField = clazz.getField('auth');
  print(authorField.get(book)); // print  author1

  var priceField = clazz.getField('price');
  priceField.set(book, 2);
  print(priceField.get(book)); // print  2

  var bookPrintFunction = clazz.getFunction('printInfo');
  bookPrintFunction
      .invoke(book, {}); // print book info name:book1 author:author2 price:2'

  var calculatePriceFunction = clazz.getFunction('calculatePrice');
  double currPrice = calculatePriceFunction.invoke(book, {'sale': 0.5});

  print(currPrice); // print  1
}
