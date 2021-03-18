import 'package:magic_mirror/magic_mirror.dart';

@MReflectionEnable(
    key: '/class/book',
    genUriType: GenUri.GEN_URI_TYPE_BY_KEY,
    scanFields: true,
    scanFunctions: true)
class Book {
  String name;

  String author;

  double price;

  Book(this.name, this.author) : this.price = 1.0;

  Book.price(this.name, this.author, this.price);

  Book.custom(this.name, {this.author = '', this.price = 1.0});

  void printInfo() {
    print('book info name:$name author:$author price:$price');
  }

  double calculatePrice(double sale) => sale * price;

  double calculatePrice2(double sale, [double newPrice, bool member = false]) =>
      sale * (newPrice ?? price);

  double calculatePrice3(double sale, {double newPrice}) =>
      sale * (newPrice ?? price);

  @MReflectionDisable()
  double calculatePriceSale(double sale) => sale * (price);
}
