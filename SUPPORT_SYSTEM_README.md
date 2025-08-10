# نظام الدعم الفني - Technical Support System

## نظرة عامة
تم إنشاء نظام دعم فني شامل يسمح للمستخدمين بالتواصل مع فريق الدعم والأدمن لحل مشاكلهم.

## المكونات الرئيسية

### 1. نماذج البيانات (Models)
- **SupportTicket.dart**: نموذج تذكرة الدعم الفني
- **SupportMessage.dart**: نموذج رسائل الدعم الفني

### 2. الخدمات (Services)
- **support_service.dart**: خدمة إدارة تذاكر الدعم الفني

### 3. الشاشات (Screens)
- **contact_us_screen.dart**: شاشة "اتصل بنا" للمستخدمين
- **support_chat_screen.dart**: شاشة شات الدعم الفني
- **admin_support_screen.dart**: شاشة إدارة الدعم (للاستخدام في الويب)

## هيكل قاعدة البيانات Firebase

### Collection: `support_tickets`
```json
{
  "ticketId": {
    "userId": "string",
    "userName": "string", 
    "userEmail": "string",
    "userImage": "string?",
    "subject": "string",
    "status": "open|in_progress|closed",
    "priority": "low|medium|high",
    "createdAt": "timestamp",
    "updatedAt": "timestamp",
    "assignedAdminId": "string?",
    "assignedAdminName": "string?",
    "messages": [
      {
        "id": "string",
        "senderId": "string",
        "senderName": "string",
        "senderRole": "user|admin",
        "message": "string",
        "timestamp": "timestamp",
        "imageUrl": "string?"
      }
    ]
  }
}
```

## الميزات الرئيسية

### للمستخدمين:
1. **إنشاء تذكرة دعم جديدة** من خلال "Contact Us" في الـ drawer
2. **تحديد أولوية المشكلة** (منخفضة، متوسطة، عالية)
3. **متابعة حالة التذكرة** (مفتوحة، قيد المعالجة، مغلقة)
4. **التواصل المباشر** مع فريق الدعم عبر الشات
5. **عرض جميع التذاكر السابقة** والحالية

### للأدمن (عبر الويب):
1. **عرض جميع التذاكر** مقسمة حسب الحالة
2. **تعيين التذاكر** للأدمن المسؤول
3. **الرد على المستخدمين** مباشرة
4. **تغيير حالة التذكرة** (إغلاق، معالجة)
5. **فلترة التذاكر** حسب الحالة

## كيفية الاستخدام

### للمستخدمين (التطبيق):
1. افتح الـ drawer من الشاشة الرئيسية
2. اضغط على "Contact Us"
3. اضغط على "Create New Ticket"
4. املأ البيانات المطلوبة (الموضوع، الأولوية، الرسالة)
5. ابدأ المحادثة مع فريق الدعم

### للأدمن (الويب):
- سيتم إنشاء لوحة تحكم ويب منفصلة لإدارة التذاكر
- الأدمن سيستخدم نفس Firebase collection للرد على المستخدمين

## الإعدادات المطلوبة

### Firebase Security Rules
```javascript
// إضافة هذه القواعد لـ Firestore
match /support_tickets/{ticketId} {
  allow read, write: if request.auth != null;
  allow read: if resource.data.userId == request.auth.uid;
  allow write: if request.auth.uid == resource.data.userId 
    || isAdmin(request.auth.uid);
}

function isAdmin(userId) {
  return exists(/databases/$(database)/documents/admins/$(userId));
}
```

### Firebase Indexes
```javascript
// إنشاء الفهارس التالية في Firestore
Collection: support_tickets
- userId (Ascending), updatedAt (Descending)
- status (Ascending), updatedAt (Descending)
- assignedAdminId (Ascending), updatedAt (Descending)
```

## التحسينات المستقبلية
1. إضافة إشعارات push للأدمن عند إنشاء تذكرة جديدة
2. إضافة إمكانية رفع الصور في الرسائل
3. إضافة تقييم خدمة الدعم
4. إضافة إحصائيات للأدمن
5. إضافة نظام تصنيف التذاكر حسب النوع

## الملاحظات المهمة
- تأكد من إضافة المستخدمين الأدمن في collection منفصل
- يمكن تخصيص ألوان وتصميم الشاشات حسب الحاجة
- النظام يدعم الوضع المظلم والفاتح تلقائياً