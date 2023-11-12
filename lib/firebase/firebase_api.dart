import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'firebase_options.dart';

class FireBaseApi {
  late FirebaseMessaging messaging;

  init() async {
    await initFirebaseApi();
    messaging = FirebaseMessaging.instance;
    await requestPermission();
    if (DefaultFirebaseOptions.currentPlatform ==
        DefaultFirebaseOptions.android) {
      backgroundMessageHandler();
    }
    initForegroundMessageListener();
    getToken();
  }

  Future<void> requestPermission() async {
    messaging.setAutoInitEnabled(true);
    await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
  }

  void initForegroundMessageListener() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
      }
    });

    messaging.getInitialMessage().then((message) {
      if (message != null) {
        AndroidNotification? android = message.notification?.android;
        if (message.notification != null && android != null) {
          if (message.data.isNotEmpty) {
            if (message.data.containsKey('link')) {
              var link = message.data['link'];
              //link
            }
          }
        }
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((event) {
      if (event.data.isNotEmpty) {
        if (event.data.containsKey('link')) {
          var link = event.data['link'];
          //link
        }
      }
      print('data is ${event.data.toString()}');
    });
  }

  @pragma('vm:entry-point')
  static Future<void> firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    // If you're going to use other Firebase services in the background, such as Firestore,
    // make sure you call `initializeApp` before using other Firebase services.
    await Firebase.initializeApp();
  }

  Future<void> initFirebaseApi() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  Future<void> getToken() async {
    String? token = await messaging.getToken();

    if (DefaultFirebaseOptions.currentPlatform == DefaultFirebaseOptions.web) {
      String vapidKey =
          'BA9iGtD7uNQgEs5i51ht2ghmzyfygQvpdMkjkwbVfILjyc-GWozDWg-ybIRsfUG8QZzkV8o0jzibeTXqVjKZh2Y';

      token = await messaging.getToken(vapidKey: vapidKey);
    } else {
      token = await messaging.getToken();
    }

    print('Registration Token=$token');
  }

  Future<void> backgroundMessageHandler() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }
}
