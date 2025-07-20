importScripts('https://www.gstatic.com/firebasejs/10.8.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.8.0/firebase-messaging-compat.js');

firebase.initializeApp({
    // SANTO DOMINGO BASE DE DATOS (ACTIVO)
    apiKey: "AIzaSyCm5cqfIUlV3wll49QA36IRwUrbnww__lo",
    authDomain: "dylanpos-victorfoto-stodgo.firebaseapp.com",
    databaseURL: "https://dylanpos-victorfoto-stodgo-default-rtdb.firebaseio.com",
    projectId: "dylanpos-victorfoto-stodgo",
    storageBucket: "dylanpos-victorfoto-stodgo.firebasestorage.app",
    messagingSenderId: "892139987413",
    appId: "1:892139987413:web:e93a15d7a74313c78e1d5c",
    measurementId: "G-B6GB7L2RCM",
    
    // SANTIAGO BASE DE DATOS (INACTIVO)
    // apiKey: "AIzaSyBP1pN3CBRNcUROMYinjTjKCzisLN7RjA0",
    // authDomain: "dylanpos-v2.firebaseapp.com",
    // databaseURL: "https://dylanpos-v2-default-rtdb.firebaseio.com",
    // projectId: "dylanpos-v2",
    // storageBucket: "dylanpos-v2.firebasestorage.app",
    // messagingSenderId: "917502791038",
    // appId: "1:917502791038:web:478334d1eb2748c1c6772f",
    // measurementId: "G-XN9YDWN22N",
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
