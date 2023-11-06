abstract class SignalRState{
  void onNewCall(data);
  void onDeclined(data);
  void onAccept(data);
  void onNewSignal(data);
  void onNewUserList(data);
  void onCallEnd(data);
  void onNewState(data);
}