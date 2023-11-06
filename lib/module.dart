import 'package:flutter_socket_io/my_webrtc_impl.dart';
import 'package:flutter_socket_io/signalr.dart';
import 'package:get_it/get_it.dart';

class Module {
  var getIt = GetIt.instance;
  Future<void> initModule() async {
    var s = getIt.registerSingleton(SignalR());
    getIt.registerSingleton(MyWebRtcImpl(s));
  }
}
