importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyChKg3BlsgsLPo7OlYC4D3JlnrDmMPzygU',
  authDomain: 'focusstone-38201.firebaseapp.com',
  projectId: 'focusstone-38201',
  storageBucket: 'focusstone-38201.firebasestorage.app',
  messagingSenderId: '999739666866',
  appId: '1:999739666866:web:d8d1b61a4cff90ecf934ab',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const title = payload.notification?.title ?? '讀書石頭';
  const body  = payload.notification?.body  ?? '';
  self.registration.showNotification(title, {
    body,
    icon: '/focus-stone/icons/Icon-192.png',
  });
});
