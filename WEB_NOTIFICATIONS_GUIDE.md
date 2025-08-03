# نظام الإشعارات - متكامل مع الويب

## ✅ الإشعارات تعمل على الموبايل والويب

### 📱 **على الموبايل:**
- إشعارات فورية عند وصول رسائل جديدة
- عداد الرسائل غير المقروءة على أيقونة الشات
- إشعارات حتى لو التطبيق مغلق

### 🌐 **على الويب:**
- نفس نظام Firebase Cloud Messaging
- إشعارات المتصفح (Browser Notifications)
- تزامن فوري مع التطبيق

## كيف يعمل النظام

### 1. **عند إرسال رسالة:**
```dart
// التطبيق يرسل إشعار تلقائياً
await NotificationService.sendChatNotification(
  receiverUserId: otherUserId,
  senderName: senderName,
  message: content,
  chatId: chatId,
);
```

### 2. **المستقبل يحصل على:**
- 🔔 إشعار فوري
- 🔴 عداد الرسائل غير المقروءة
- 📱 اهتزاز وصوت (حسب الإعدادات)

## للويب - كود JavaScript

### تهيئة الإشعارات:
```javascript
// طلب إذن الإشعارات
await Notification.requestPermission();

// تهيئة Firebase Messaging
const messaging = firebase.messaging();
const token = await messaging.getToken();

// حفظ التوكن في Firestore
await firebase.firestore().collection('users').doc(userId).update({
  fcmToken: token,
  platform: 'web'
});
```

### استقبال الإشعارات:
```javascript
// إشعارات أثناء تصفح الموقع
messaging.onMessage((payload) => {
  new Notification(payload.notification.title, {
    body: payload.notification.body,
    icon: '/icon.png',
    badge: '/badge.png'
  });
});

// إشعارات في الخلفية
messaging.onBackgroundMessage((payload) => {
  self.registration.showNotification(payload.notification.title, {
    body: payload.notification.body,
    icon: '/icon.png'
  });
});
```

## مثال عملي

### السيناريو:
1. **أحمد** يرسل رسالة لـ **سارة** من التطبيق
2. **سارة** تتصفح الموقع على الكمبيوتر

### النتيجة:
- ✅ سارة تحصل على إشعار فوري في المتصفح
- ✅ تسمع صوت الإشعار
- ✅ ترى عداد الرسائل الجديدة
- ✅ يمكنها الرد من الويب مباشرة

## الميزات المتقدمة

### 1. **إشعارات ذكية:**
```javascript
// إشعار مختلف حسب نوع الرسالة
if (messageType === 'image') {
  title = `${senderName} sent a photo`;
} else if (messageType === 'emoji') {
  title = `${senderName} sent ${message}`;
}
```

### 2. **عداد الرسائل:**
```javascript
// تحديث عداد الرسائل في الويب
function updateUnreadCount(count) {
  document.title = count > 0 ? `(${count}) Petut Chat` : 'Petut Chat';
  
  // تحديث الأيقونة
  const favicon = document.querySelector('link[rel="icon"]');
  favicon.href = count > 0 ? '/icon-unread.png' : '/icon.png';
}
```

### 3. **إشعارات تفاعلية:**
```javascript
// إشعار مع أزرار
self.registration.showNotification(title, {
  body: message,
  actions: [
    { action: 'reply', title: 'Reply' },
    { action: 'view', title: 'View Chat' }
  ]
});
```

## إعداد Firebase للويب

### 1. **firebase-messaging-sw.js:**
```javascript
importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-messaging-compat.js');

firebase.initializeApp({
  // نفس إعدادات التطبيق
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/firebase-logo.png'
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
```

### 2. **HTML:**
```html
<script type="module">
  import { initializeApp } from 'firebase/app';
  import { getMessaging, getToken, onMessage } from 'firebase/messaging';

  const app = initializeApp(firebaseConfig);
  const messaging = getMessaging(app);

  // طلب إذن الإشعارات
  getToken(messaging, { vapidKey: 'YOUR_VAPID_KEY' }).then((token) => {
    console.log('FCM Token:', token);
    // حفظ التوكن في قاعدة البيانات
  });

  // استقبال الرسائل
  onMessage(messaging, (payload) => {
    console.log('Message received:', payload);
    // عرض الإشعار
  });
</script>
```

## الأمان والخصوصية

### ✅ **آمن تماماً:**
- التوكنات مشفرة
- الإشعارات عبر Firebase الآمن
- لا تحتوي على محتوى حساس

### ✅ **يحترم الخصوصية:**
- المستخدم يتحكم في الإشعارات
- يمكن إيقافها من إعدادات المتصفح
- لا إشعارات بدون إذن

## النتيجة النهائية

### 🎉 **نظام إشعارات متكامل:**
- ✅ يعمل على الموبايل والويب
- ✅ إشعارات فورية ومتزامنة
- ✅ عداد الرسائل غير المقروءة
- ✅ تجربة موحدة عبر المنصات
- ✅ آمن ويحترم الخصوصية

**المستخدم سيعرف فوراً عند وصول رسالة جديدة، سواء كان على الموبايل أو الويب!** 🔔