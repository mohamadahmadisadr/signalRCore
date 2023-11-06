import 'package:flutter_socket_io/signalr_callback.dart';
import 'package:logging/logging.dart';
import 'package:signalr_netcore/signalr_client.dart';

import 'signalR_state.dart';

class SignalR extends CallBack {
  List<SignalRState> stateCallbacks = [];

  HubConnection? hubConnection;

  void initHubConfig() {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((LogRecord rec) {
      print(
          "${rec.level.name}: ${rec.time}: ${rec.message} ${rec.object != null ? '=>' : ''} ${rec.object ?? ''}");
    });

    final hubProtLogger = Logger("SignalR - hub");

    const serverUrl = "https://webrtc.mamakschool.ir/ConnectionHub";
    final connectionOptions = HttpConnectionOptions(
      transport: HttpTransportType.WebSockets,
      logMessageContent: true,
      requestTimeout: 30000,
    );
    hubConnection = HubConnectionBuilder()
        .withUrl(serverUrl, options: connectionOptions)
        .configureLogging(hubProtLogger)
        .build();
  }

  initEventsHandler() {
    hubConnection?.stateStream.listen(_handleEventStream);

    hubConnection?.on('updateUserList', _handleUpdateUserList);

    hubConnection?.on('incomingCall', _handleIncomingCall);

    hubConnection?.on('CallDeclined', _handleCallDeclined);

    hubConnection?.on('receiveSignal', _handleReceiveSignal);

    hubConnection?.on('callAccepted', _handleCallAccepted);

    hubConnection?.on('callEnded', _handleCallEnded);
  }

  void _handleCallDeclined(List<Object?>? arguments) {
    onMessage(MessageType.decline, arguments);
  }

  void _handleCallAccepted(List<Object?>? arguments) {
    onMessage(MessageType.accept, arguments);
  }

  void _handleCallEnded(List<Object?>? arguments) {
    onMessage(MessageType.callEnd, arguments);
  }

  void _handleReceiveSignal(List<Object?>? arguments) {
    onMessage(MessageType.signal, arguments);
  }

  void _handleIncomingCall(List<Object?>? arguments) {
    onMessage(MessageType.calling, arguments);
  }

  void _handleUpdateUserList(List<Object?>? arguments) {
    onMessage(MessageType.updateUsers, arguments);
  }

  void _handleEventStream(HubConnectionState event) {
    onMessage(MessageType.newState, event);
  }

  Future<void> hangUp(){
    return sendMessage("hangUp");
  }

  Future<void> callUser(dynamic user){
    return sendMessage("callUser", args:[user]);
  }

  @override
  onMessage(MessageType type, data) {
    switch (type) {
      case MessageType.calling:
        updateListeners((callBack) => callBack.onNewCall(data));
      case MessageType.decline:
        updateListeners((callBack) => callBack.onDeclined.call(data));
      case MessageType.accept:
        updateListeners((callBack) => callBack.onAccept.call(data));
      case MessageType.signal:
        updateListeners((callBack) => callBack.onNewSignal.call(data));
      case MessageType.updateUsers:
        updateListeners((callBack) => callBack.onNewUserList.call(data));
      case MessageType.callEnd:
        updateListeners((callBack) => callBack.onCallEnd.call(data));
      case MessageType.newState:
        updateListeners((callBack) => callBack.onNewState.call(data));
    }
  }

  updateListeners(Function(SignalRState callBack) callback) {
    for (var element in stateCallbacks) {
      callback.call(element);
    }
  }

  @override
  Future<Object?> sendMessage(String name, {List<Object>? args}) {
    return hubConnection!.invoke(name, args: args);
  }

  @override
  start() {
    initHubConfig();
    initEventsHandler();
    hubConnection?.start();
  }


  void addStateListener(SignalRState state){
    stateCallbacks.add(state);
  }

  @override
  stop() {
    stateCallbacks.clear();
    hubConnection?.stop();
  }
}
