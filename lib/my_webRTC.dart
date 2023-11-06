abstract class MyWebRTC{
  void start();
  void dispose();
  void initMedia();
  void initOffer(partnerClientId, stream);
  void receivedSdpSignal(connection, partnerClientId, sdp, type);
  void receivedCandidateSignal(connection, partnerClientId, candidate);
}