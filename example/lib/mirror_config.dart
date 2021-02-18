import 'package:magic_mirror/mirror.dart';

@MirrorConfig(isGenLibExport: false, function: printLog)
class RouterFactory {}

void printLog() {
  print('测试回调');
}
