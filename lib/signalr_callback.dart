abstract class CallBack{
  start();
  stop();
  onMessage(MessageType type,dynamic data);
  Future<Object?> sendMessage(String name, {List<Object>? args});

}

enum MessageType{
  calling, decline, accept, signal, updateUsers, callEnd, newState;
}