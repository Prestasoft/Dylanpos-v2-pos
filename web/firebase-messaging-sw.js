importScripts('https://www.gstatic.com/firebasejs/10.8.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.8.0/firebase-messaging-compat.js');

firebase.initializeApp({
    // SANTO DOMINGO ESTE BASE DE DATOS (ACTIVO)
    apiKey: "AIzaSyDfcwhEq_JuUg23OonfQtYtDGzlXQEXI9c",
    authDomain: "sistema-victor-sde.firebaseapp.com",
    databaseURL: "https://sistema-victor-sde-default-rtdb.firebaseio.com",
    projectId: "sistema-victor-sde",
    storageBucket: "sistema-victor-sde.firebasestorage.app",
    messagingSenderId: "180650620806",
    appId: "1:180650620806:web:5daf2c0d43927db6a61e07",
    measurementId: "G-231GYNFL54",
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
