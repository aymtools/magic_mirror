import 'package:magic_mirror/magic_mirror.dart';

@OnInitializer()
class OnAppInit extends Initializer {
  void onInit(MagicMirror mirror) {
    print('OnAppInit run');
  }
}
