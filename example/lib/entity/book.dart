import 'package:magic_mirror/magic_mirror.dart';

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
  Book(this.name, this.author) : this.price = 1.0;

  @MConstructor()
  Book.price(this.name, this.author, this.price);

  @MConstructor()
  Book.custom(this.name, {this.author = '', this.price = 1.0});

  @MFunction()
  void printInfo() {
    print('book info name:$name author:$author price:$price');
  }

  @MFunction()
  double calculatePrice(double sale) => sale * price;

  @MFunction()
  double calculatePrice2(double sale, [double? newPrice]) =>
      sale * (newPrice ?? price);

  @MFunction()
  double calculatePrice3(double sale, {required double? newPrice}) =>
      sale * (newPrice ?? price);
}
