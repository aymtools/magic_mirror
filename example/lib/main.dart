import 'package:magic_mirror/magic_mirror.dart';

import 'generated/aymtools/mirror/register.mirror.aymtools.dart';

void main() {
  Register.register();

  var clazz = MagicMirror.instance.loadClass('/class/book');

  var bookPrintFunction = clazz.getFunction('printInfo');
  var book2 = clazz.newInstance2(
      constructorName: 'custom', positional: ['book2'], params: {'price': 3.0});
  bookPrintFunction
      .invoke(book2); // print book info name:book2 author: price:3.0

  var book3 = clazz.newInstanceForMap(
      'price', {'name': 'book3', 'author': 'author3', 'price': 6.0});
  bookPrintFunction
      .invoke(book3); // print book info name:book3 author:author3 price:6.0

  var book = clazz.newInstance('', {'name': 'book1', 'author': 'author1'});
  var authorField = clazz.getField('author');
  print(authorField.get(book)); // print  author1

  var priceField = clazz.getField('price');
  priceField.set(book, 2);
  print(priceField.get(book)); // print  2.0

  bookPrintFunction
      .invoke(book, {}); // print book info name:book1 author:author1 price:2.0'

  var calculatePriceFunction = clazz.getFunction('calculatePrice');
  double currPrice = calculatePriceFunction.invoke(book, {'sale': 0.5});

  print(currPrice); // print  1.0
}
