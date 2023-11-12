importScripts("https://www.gstatic.com/firebasejs/9.6.10/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.6.10/firebase-messaging-compat.js");

// For Firebase JS SDK v7.20.0 and later, measurementId is optional
// For Firebase JS SDK v7.20.0 and later, measurementId is optional
const firebaseConfig = {
  apiKey: "AIzaSyBaceCOayldyPZDh4_qhAnJsmEq_SXAUrY",
  authDomain: "signalr-634ee.firebaseapp.com",
  projectId: "signalr-634ee",
  storageBucket: "signalr-634ee.appspot.com",
  messagingSenderId: "1095935930094",
  appId: "1:1095935930094:web:0762d55bd5a36cffd28dff",
  measurementId: "G-LYP50PGCTC"
};
firebase.initializeApp(firebaseConfig);

const messaging = firebase.messaging();

messaging.onBackgroundMessage((message) => {
  var payload = message.notification;
  var notificationTitle = payload.title;
  var notificationOptions = {
    body: payload.body,
    icon: payload.icon,
    image: payload.image,
    data: message.data.link,
    actions: [{
      action: 'accept',
      title: 'Accept',
    },
    {
      action: 'decline',
      title: 'Decline',
    },
    ]
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});


var onClick = function (event) {
  console.log(event.action);
  event.notification.close();
  const data = event.notification.data;
  if (data) {
    event.waitUntil(clients.openWindow(data));
  }
}

self.addEventListener('notificationclick', onClick);
