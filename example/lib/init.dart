import 'package:magic_mirror/mirror.dart';

@OnInitializer()
class OnAppInit extends Initializer {
  void onInit(MagicMirror mirror) {
    print('OnAppInit run');
  }
}
