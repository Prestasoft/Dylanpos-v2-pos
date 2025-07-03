importScripts('https://www.gstatic.com/firebasejs/10.8.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.8.0/firebase-messaging-compat.js');

firebase.initializeApp({
    apiKey: "AIzaSyCm5cqfIUlV3wll49QA36IRwUrbnww__lo",
    authDomain: "dylanpos-victorfoto-stodgo.firebaseapp.com",
    databaseURL: "https://dylanpos-victorfoto-stodgo-default-rtdb.firebaseio.com",
    projectId: "dylanpos-victorfoto-stodgo",
    storageBucket: "dylanpos-victorfoto-stodgo.firebasestorage.app",
    messagingSenderId: "892139987413",
    appId: "1:892139987413:web:e93a15d7a74313c78e1d5c",
    measurementId: "G-B6GB7L2RCM",
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage(function(payload) {
  console.log('[firebase-messaging-sw.js] Recibido mensaje en segundo plano', payload);
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: 'https://app.victorguzmanfotografia.com/storage/vg_logo.png'
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
