import 'package:magic_mirror/magic_mirror.dart';

import 'generated/aymtools/mirror/register.mirror.aymtools.dart';

void main() {
  Register.register();
  var mm = MagicMirror.instance;
  var clazz = mm.loadClass('/class/book');
  var book = clazz.newInstance('', {'name': 'book1', 'author': 'author1'});

  var authorField = clazz.getField('author');
  print(authorField.get(book)); // print  author1

  var priceField = clazz.getField('price');
  priceField.set(book, 2);
  print(priceField.get(book)); // print  2.0

  var bookPrintFunction = clazz.getFunction('printInfo');
  bookPrintFunction
      .invoke(book, {}); // print book info name:book1 author:author1 price:2'

  var calculatePriceFunction = clazz.getFunction('calculatePrice');
  double currPrice = calculatePriceFunction.invoke(book, {'sale': 0.5});

  print(currPrice); // print  1.0
}
