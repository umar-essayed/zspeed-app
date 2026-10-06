importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyCQBw4604b_Ww_SkbXdSqyRvgk6iv2Nmxg',
  authDomain: 'zspeed.firebaseapp.com',
  projectId: 'zspeed',
  storageBucket: 'zspeed.firebasestorage.app',
  messagingSenderId: '1048229753879',
  appId: '1:1048229753879:web:467ff9be8a15f412295852',
});

const messaging = firebase.messaging();
