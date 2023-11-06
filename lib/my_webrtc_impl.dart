import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_socket_io/my_webRTC.dart';
import 'package:flutter_socket_io/signalR_state.dart';
import 'package:flutter_socket_io/signalr.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:signalr_netcore/hub_connection.dart';

class MyWebRtcImpl implements MyWebRTC, SignalRState {
  final SignalR signalR;

  MyWebRtcImpl(this.signalR){
    signalR.addStateListener(this);
  }

  Map<String, RTCPeerConnection> connections = {};
  MediaStream? localeStream;
  var peerConnectionConfig = {
    "iceServers": [
      {
        "urls": "stun:stun.relay.metered.ca:80",
      },
      {
        "urls": "turn:a.relay.metered.ca:80",
        "username": "a79ed1cf48006d9a273abd28",
        "credential": "fhXaHGiPxiaJFes4",
      }
    ]
  };
  final Map<String, dynamic> _config = {
    'mandatory': {},
    'optional': [
      {'DtlsSrtpKeyAgreement': true},
    ]
  };

  String get sdpSemantics => 'unified-plan';

  @override
  void initMedia() async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': false
    };
    localeStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    if (!kIsWeb) {
      localeStream?.getAudioTracks()[0].enableSpeakerphone(false);
    }
  }

  @override
  void initOffer(partnerClientId, stream) async {
    var connection = await getConnection(partnerClientId);
    stream?.getTracks().forEach((track) {
      connection.addTrack(track, localeStream!);
    });
    connection.createOffer().then((offer) {
      connection.setLocalDescription(offer).then((value) async {
        var ld = await connection.getLocalDescription();
        await signalR.sendMessage('sendSignal', args: [
          jsonEncode({"sdp": ld?.toMap()}),
          partnerClientId.toString()
        ]);
      }).catchError((error) {
        print(error);
      });
    }).catchError((error) {
      print(error);
    });
  }

  @override
  void receivedCandidateSignal(connection, partnerClientId, candidate) {
    print('received new candidate and that is ${candidate}');
    try {
      connection.addCandidate(RTCIceCandidate(candidate['candidate'],
          candidate['sdpMid'], candidate['sdpMLineIndex']));
    } on Exception catch (e, s) {
      print(s);
    }
  }

  @override
  void receivedSdpSignal(connection, partnerClientId, sdp, type) async {
    await connection.setRemoteDescription(RTCSessionDescription(sdp, type));
    var remoteDescription = await connection.getRemoteDescription();
    if (remoteDescription?.type == 'offer') {
      localeStream?.getTracks().forEach((track) {
        connection.addTrack(track, localeStream!);
      });
      connection.createAnswer().then((desc) {
        connection.setLocalDescription(desc).then((value) async {
          var ld = (await connection.getLocalDescription());
          print('the ld is ${ld?.toMap()}');
          signalR.sendMessage("sendSignal", args: [
            jsonEncode({"sdp": ld?.toMap()}),
            partnerClientId.toString()
          ]);
        });
      });
    } else if (remoteDescription?.type == 'answer') {
      print('WebRTC: remote Description type answer');
    }
  }

  @override
  void dispose() {
    localeStream?.dispose();
    connections.clear();
    signalR?.stop();
  }

  @override
  void start() {
    print('starting webRtc');
    signalR?.start();
    initMedia();
  }

  Future<RTCPeerConnection> getConnection(partnerClientId) async {
    if (connections[partnerClientId] != null) {
      return connections[partnerClientId]!;
    } else {
      return await initializeConnection(partnerClientId);
    }
  }

  Future<RTCPeerConnection> initializeConnection(
      dynamic partnerClientId) async {
    RTCPeerConnection connection = await createPeerConnection({
      ...peerConnectionConfig,
      ...{'sdpSemantics': sdpSemantics}
    }, _config);

    switch (sdpSemantics) {
      case 'plan-b':
        connection.onAddStream = (MediaStream stream) {
          // _remoteStreams.add(stream);
        };
        await connection.addStream(localeStream!);
        break;
      case 'unified-plan':
        // Unified-Plan
        connection.onTrack = (event) {};
        localeStream!.getTracks().forEach((track) async {
          connection.addTrack(track, localeStream!);
        });
        break;
    }

    connection.onIceCandidate = (candidate) {
      print('candidate is ${candidate.toMap()}');
      signalR.sendMessage('sendSignal', args: [
      jsonEncode({"candidate": candidate.toMap()}),
        partnerClientId.toString()
      ]);
    };

    // connection.onRemoveStream = (MediaStream stream) {
    // onAddRemoteStream?.call(newSession, stream);
    // _remoteStreams.removeWhere((it) {
    //   return (it.id == stream.id);
    // });
    //}; // Remove stream handler callback

    connections[partnerClientId] =
        connection; // Store away the connection based on username
    return connection;
  }

  void newSignal(partnerClientId, signal) async {
    var connection = await getConnection(partnerClientId);
    var c = signal["candidate"];
    var s = signal["sdp"];
    print('c => type is ${c.runtimeType} and data is $c');
    print('s => type is ${s.runtimeType} and data is $s');
    // Route signal based on type
    if (c != null) {
      receivedCandidateSignal(connection, partnerClientId, c);
    }
    if (s != null) {
      receivedSdpSignal(connection, partnerClientId, s['sdp'], s['type']);
    }
  }

  void closeConnection(signalingUser) {
    print('connection lenght is ${connections.length}');
    var connection = connections[signalingUser];
    connection?.close();
    connections.removeWhere(
      (key, value) =>
          value.iceGatheringState?.index ==
          connection?.iceGatheringState?.index,
    );
    print('connection lenght is ${connections.length}');
  }

  @override
  void onAccept(data) {
    print('call accepted');
    if (data == null && data!.isEmpty) return;
    var signalingUser = (data.first as dynamic);
    print('accepted user is $signalingUser');
    initOffer(signalingUser['connectionId'], localeStream);
  }

  @override
  void onCallEnd(data) {
    if (data == null && data!.isEmpty) return;
    var signalingUser = (data.first as dynamic);
    var objectobjectsignal = data[1];
    closeConnection(signalingUser['connectionId']);
  }

  @override
  void onDeclined(data) {
    // print(arguments);
    // _controller?.close();
  }

  @override
  void onNewCall(data) {
    print(data);
  }

  @override
  void onNewSignal(data) {
    if (data == null && data!.isEmpty) return;
    var signalingUser = (data.first as dynamic);
    var signal = data[1];
    print('signal is ${signal}');
    newSignal(signalingUser['connectionId'], jsonDecode(signal as String));
  }

  @override
  void onNewState(data) {
    HubConnectionState event = data;
    if (event == HubConnectionState.Connected) {
      var name = "${kIsWeb ? 'Web' : 'Mobile'}_${Random().nextInt(1000)}";
      print('joining as $name');
      signalR?.sendMessage("Join", args: [name]);

      // initRtc();
    }
  }

  @override
  void onNewUserList(data) {
    print(data);
  }
}
