class Book {
  final String name;
  final String auth;
  final double money;

  Book(this.name, this.auth, this.money);

  @override
  String toString() {
    return "name:$name  auth:$auth money:$money";
  }
}
