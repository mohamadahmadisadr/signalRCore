import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

// Import theses libraries.
import 'package:logging/logging.dart';
import 'package:signalr_netcore/signalr_client.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  RTCVideoRenderer renderer = RTCVideoRenderer();
  late HubConnection hubConnection;


  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  void initState() {
    Logger.root.level = Level.ALL;
// Writes the log messages to the console
    Logger.root.onRecord.listen((LogRecord rec) {
      print('${rec.level.name}: ${rec.time}: ${rec.message}');
    });

// If you want only to log out the message for the higer level hub protocol:
    final hubProtLogger = Logger("SignalR - hub");
// If youn want to also to log out transport messages:
    final transportProtLogger = Logger("SignalR - transport");

// The location of the SignalR Server.
    const serverUrl = "https://webrtc.mamakschool.ir/ConnectionHub";
    final connectionOptions = HttpConnectionOptions(transport: HttpTransportType.WebSockets);
    final httpOptions = new HttpConnectionOptions(logger: transportProtLogger);
    hubConnection = HubConnectionBuilder()
        .withUrl(serverUrl,options: connectionOptions)
        .configureLogging(hubProtLogger)
        .build();
    start();
    super.initState();
  }

  Future<void> start() async{
    await hubConnection.start();
    final result = await hubConnection.invoke("Join", args: <Object>["client"]);
    print("Result: '$result");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
