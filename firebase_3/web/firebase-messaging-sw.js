importScripts("https://gstatic.com");
importScripts("https://gstatic.com");

// तुमच्या firebase_options.dart मधील वेब कॉन्फिगरेशन व्हॅल्यूज इथे टाका
firebase.initializeApp({
 apiKey: "AIzaSyBZ5fcZynOg9PzT1AvgGENqHj-JyJ9-0Ko",
  authDomain: "fir-three-9752f.firebaseapp.com",
  projectId: "fir-three-9752f",
  storageBucket: "fir-three-9752f.firebasestorage.app",
  messagingSenderId: "727313907190",
  appId: "1:727313907190:web:95fcdaf8ec497908f71bd7",
  measurementId: "G-HX0GZNYEZD"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('Background message received: ', payload);

  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: payload.notification.icon || '/firebase-logo.png'
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
