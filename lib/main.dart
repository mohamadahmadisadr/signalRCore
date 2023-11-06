import 'package:flutter/material.dart';
import 'package:flutter_socket_io/module.dart';
import 'package:flutter_socket_io/my_webrtc_impl.dart';
import 'package:flutter_socket_io/signalR_state.dart';
import 'package:get_it/get_it.dart';

void main() async{
  await Module().initModule();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SignalR',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: MyHomePage(title: 'SignalR'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({super.key, required this.title});

  final String title;
  final List<dynamic> peers = [];
  MyWebRtcImpl webRtcImpl = GetIt.I.get();

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> implements SignalRState {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  PersistentBottomSheetController? _controller;

  @override
  void dispose() {
    print('dispose');
    widget.webRtcImpl.dispose();
    super.dispose();
  }

  @override
  void deactivate() {
    print('deactivate');
    widget.webRtcImpl.dispose();
    super.deactivate();
  }

  @override
  void initState() {
    widget.webRtcImpl.signalR.addStateListener(this);
    widget.webRtcImpl.start();

    super.initState();
  }

  // void initHubConfig() {
  //   Logger.root.level = Level.ALL;
  //   Logger.root.onRecord.listen((LogRecord rec) {
  //     print('${rec.level.name}: ${rec.time}: ${rec.message} => ${rec.object}');
  //   });
  //
  //   final hubProtLogger = Logger("SignalR - hub");
  //
  //   const serverUrl = "https://webrtc.mamakschool.ir/ConnectionHub";
  //   final connectionOptions = HttpConnectionOptions(
  //       transport: HttpTransportType.WebSockets,
  //       logMessageContent: true,
  //       requestTimeout: 30000);
  //   hubConnection = HubConnectionBuilder()
  //       .withUrl(serverUrl, options: connectionOptions)
  //       .configureLogging(hubProtLogger)
  //       .build();
  // }

  // @override
  // deactivate() {
  //   super.deactivate();
  //   hubConnection.stop();
  // }

  // Future<void> start() async {
  //   return hubConnection.start();
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: ListView.separated(
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(
                "${widget.peers[index]['username']} ${widget.peers[index]['connectionId'].toString() == widget.webRtcImpl.signalR.hubConnection?.connectionId.toString() ? ' (You)' : ''}"),
            onTap: () {
              if (widget.peers[index]['connectionId'].toString() !=
                  widget.webRtcImpl.signalR.hubConnection?.connectionId
                      .toString()) {
                print('Calling user ${widget.peers[index]['connectionId']}');
                widget.webRtcImpl.signalR
                    .sendMessage("callUser", args: [widget.peers[index]]);
                // hubConnection.invoke('callUser', args: [widget.peers[index]]);
                _controller =
                    _scaffoldKey.currentState?.showBottomSheet((context) {
                  return Card(
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8.0))),
                    child: ListTile(
                        contentPadding: const EdgeInsets.all(16.0),
                        title: Text(
                            'calling to ${widget.peers[index]['username'].toString()}'),
                        trailing: IconButton(
                            onPressed: () async {
                              await widget.webRtcImpl.signalR.hangUp();
                              _controller?.close();
                            },
                            icon: const Icon(
                              Icons.call_end_sharp,
                              color: Colors.red,
                              size: 25,
                            ))),
                  );
                });
              }
            },
          );
        },
        separatorBuilder: (context, index) {
          return const Divider();
        },
        itemCount: widget.peers.length,
      ),
    );
  }

  // String get sdpSemantics => 'unified-plan';

  // initRtc() async {
  //   final Map<String, dynamic> mediaConstraints = {
  //     'audio': true,
  //     'video': false
  //   };
  //   localeStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
  //   if (!kIsWeb) {
  //     localeStream?.getAudioTracks()[0].enableSpeakerphone(false);
  //   }
  // }

  // initOffer(partnerClientId, stream) async {
  //   var connection = await getConnection(partnerClientId);
  //   stream?.getTracks().forEach((track) {
  //     connection.addTrack(track, localeStream!);
  //   });
  //   connection.createOffer().then((offer) {
  //     print('offer is ${offer.toMap()}');
  //     connection.setLocalDescription(offer).then((value) async {
  //       var ld = await connection.getLocalDescription();
  //       print('the ld is ${ld?.toMap()}');
  //       sendHubSignal({"sdp": ld?.toMap()}, partnerClientId);
  //     }).catchError((error) {
  //       print(error);
  //     });
  //   }).catchError((error) {
  //     print(error);
  //   });
  // }

  // Future<RTCPeerConnection> getConnection(partnerClientId) async {
  //   if (connections[partnerClientId] != null) {
  //     return connections[partnerClientId]!;
  //   } else {
  //     return await initializeConnection(partnerClientId);
  //   }
  // }

  // Future<RTCPeerConnection> initializeConnection(
  //     dynamic partnerClientId) async {
  //   RTCPeerConnection connection = await createPeerConnection({
  //     ...peerConnectionConfig,
  //     ...{'sdpSemantics': sdpSemantics}
  //   }, _config);
  //
  //   switch (sdpSemantics) {
  //     case 'plan-b':
  //       connection.onAddStream = (MediaStream stream) {
  //         // _remoteStreams.add(stream);
  //       };
  //       await connection.addStream(localeStream!);
  //       break;
  //     case 'unified-plan':
  //       // Unified-Plan
  //       connection.onTrack = (event) {};
  //       localeStream!.getTracks().forEach((track) async {
  //         connection.addTrack(track, localeStream!);
  //       });
  //       break;
  //   }
  //
  //   connection.onIceCandidate = (candidate) {
  //     print('candidate is ${candidate.toMap()}');
  //     sendHubSignal({"candidate": candidate.toMap()}, partnerClientId);
  //   };
  //
  //   connection.onRemoveStream = (MediaStream stream) {
  //     // onAddRemoteStream?.call(newSession, stream);
  //     // _remoteStreams.removeWhere((it) {
  //     //   return (it.id == stream.id);
  //     // });
  //   }; // Remove stream handler callback
  //
  //   connections[partnerClientId] =
  //       connection; // Store away the connection based on username
  //   //console.log(connection);
  //   return connection;
  // }

  // void sendHubSignal(Map<String, dynamic> map, partnerClientId) {
  //   hubConnection.invoke('sendSignal',
  //       args: [jsonEncode(map), partnerClientId.toString()]);
  // }

  // void newSignal(partnerClientId, signal) async {
  //   var connection = await getConnection(partnerClientId);
  //   var c = signal["candidate"];
  //   var s = signal["sdp"];
  //   print('c => type is ${c.runtimeType} and data is $c');
  //   print('s => type is ${s.runtimeType} and data is $s');
  //   // Route signal based on type
  //   if (c != null) {
  //     receivedCandidateSignal(connection, partnerClientId, c);
  //   }
  //   if (s != null) {
  //     receivedSdpSignal(connection, partnerClientId, s['sdp'], s['type']);
  //   }
  // }

  // void receivedSdpSignal(
  //     RTCPeerConnection connection, partnerClientId, sdp, type) async {
  //   await connection.setRemoteDescription(RTCSessionDescription(sdp, type));
  //   var remoteDescription = await connection.getRemoteDescription();
  //   if (remoteDescription?.type == 'offer') {
  //     localeStream?.getTracks().forEach((track) {
  //       connection.addTrack(track, localeStream!);
  //     });
  //     connection.createAnswer().then((desc) {
  //       connection.setLocalDescription(desc).then((value) async {
  //         var ld = (await connection.getLocalDescription());
  //         print('the ld is ${ld?.toMap()}');
  //         sendHubSignal({"sdp": ld?.toMap()}, partnerClientId);
  //       });
  //     });
  //   } else if (remoteDescription?.type == 'answer') {
  //     print('WebRTC: remote Description type answer');
  //   }
  // }

  // void receivedCandidateSignal(
  //     RTCPeerConnection connection, partnerClientId, candidate) {
  //   print('received new candidate and that is ${candidate}');
  //   try {
  //     connection.addCandidate(RTCIceCandidate(candidate['candidate'],
  //         candidate['sdpMid'], candidate['sdpMLineIndex']));
  //   } on Exception catch (e, s) {
  //     print(s);
  //   }
  // }

  // void closeConnection(signalingUser) {
  //   print('connection lenght is ${connections.length}');
  //   var connection = connections[signalingUser];
  //   connection?.close();
  //   connections.removeWhere(
  //     (key, value) =>
  //         value.iceGatheringState?.index ==
  //         connection?.iceGatheringState?.index,
  //   );
  //   print('connection lenght is ${connections.length}');
  // }

  void _handleCallDeclined(List<Object?>? arguments) {
    print(arguments);
    _controller?.close();
  }

  // void _handleCallAccepted(List<Object?>? arguments) {
  //   print('call accepted');
  //   if (arguments == null && arguments!.isEmpty) return;
  //   var signalingUser = (arguments.first as dynamic);
  //   print('accepted user is $signalingUser');
  //   initOffer(signalingUser['connectionId'], localeStream);
  // }

  // void _handleCallEnded(List<Object?>? arguments) {
  //   if (arguments == null && arguments!.isEmpty) return;
  //   var signalingUser = (arguments.first as dynamic);
  //   var objectobjectsignal = arguments[1];
  //   closeConnection(signalingUser['connectionId']);
  // }

  // void _handleReceiveSignal(List<Object?>? arguments) {
  //   if (arguments == null && arguments!.isEmpty) return;
  //   var signalingUser = (arguments.first as dynamic);
  //   var signal = arguments[1];
  //   print('signal is ${signal}');
  //   newSignal(signalingUser['connectionId'], jsonDecode(signal as String));
  // }

  void _handleIncomingCall(List<Object?>? arguments) {
    _controller = _scaffoldKey.currentState?.showBottomSheet((context) {
      return Card(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8.0))),
        child: ListTile(
            contentPadding: const EdgeInsets.all(16.0),
            title: Text(
                '${(arguments?.first as dynamic)?['username']} is calling'),
            trailing: SizedBox(
              width: 100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                      onPressed: () async {
                        await widget.webRtcImpl.signalR.sendMessage(
                            "AnswerCall",
                            args: [false, arguments!.first!]);
                        _controller?.close();
                      },
                      icon: const Icon(
                        Icons.call_end_sharp,
                        color: Colors.red,
                        size: 25,
                      )),
                  IconButton(
                      onPressed: () async {
                        await widget.webRtcImpl.signalR.sendMessage(
                            "AnswerCall",
                            args: [true, arguments!.first!]);
                        _controller?.close();
                      },
                      icon: const Icon(
                        Icons.call,
                        color: Colors.green,
                        size: 25,
                      ))
                ],
              ),
            )),
      );
    });
  }

  void _handleUpdateUserList(List<Object?>? arguments) {
    print('received data is $arguments');
    setState(() {
      widget.peers.clear();
      widget.peers.addAll(((arguments?.first ?? []) as List<dynamic>));
    });
  }

  @override
  void onAccept(data) {
    // TODO: implement onAccept
  }

  @override
  void onCallEnd(data) {
    // TODO: implement onCallEnd
  }

  @override
  void onDeclined(data) {
    _handleCallDeclined(data);
  }

  @override
  void onNewCall(data) {
    _handleIncomingCall(data);
  }

  @override
  void onNewSignal(data) {
    // TODO: implement onNewSignal
  }

  @override
  void onNewState(data) {
    // TODO: implement onNewState
  }

  @override
  void onNewUserList(data) {
    _handleUpdateUserList(data);
  }
}
