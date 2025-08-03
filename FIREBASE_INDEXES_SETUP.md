# إعداد فهارس Firebase للشات

## المشكلة
عند استخدام نظام الشات، قد تظهر أخطاء تطلب إنشاء فهارس في Firebase. هذا أمر طبيعي ومطلوب للاستعلامات المعقدة.

## الحل السريع
1. اذهب إلى Firebase Console
2. اختر مشروعك (petut-55f40)
3. اذهب إلى Firestore Database
4. اختر "Indexes" من القائمة الجانبية
5. انقر على "Create Index"

## الفهارس المطلوبة

### 1. فهرس للرسائل (Messages Collection)
```
Collection ID: messages
Fields to index:
- chatId (Ascending)
- timestamp (Descending)
```

### 2. فهرس للمحادثات (Chats Collection)
```
Collection ID: chats
Fields to index:
- participants (Array)
- lastMessageTime (Descending)
```

### 3. فهرس للرسائل غير المقروءة (اختياري)
```
Collection ID: messages
Fields to index:
- chatId (Ascending)
- isRead (Ascending)
- senderId (Ascending)
```

## طريقة إنشاء الفهارس

### الطريقة الأولى: من خلال الرابط في الخطأ
1. عندما يظهر الخطأ، سيكون هناك رابط مثل:
   `https://console.firebase.google.com/v1/r/project/petut-55f40/firestore/indexes`
2. انقر على الرابط
3. سيتم إنشاء الفهرس تلقائياً

### الطريقة الثانية: يدوياً
1. اذهب إلى Firebase Console
2. Firestore Database → Indexes
3. انقر "Create Index"
4. أدخل البيانات المطلوبة
5. انقر "Create"

## ملاحظات مهمة
- إنشاء الفهارس قد يستغرق بضع دقائق
- بعد إنشاء الفهارس، أعد تشغيل التطبيق
- الفهارس مطلوبة مرة واحدة فقط لكل مشروع
- إذا لم تعمل الفهارس، جرب حذف البيانات القديمة من Firestore وأعد المحاولة

## حل بديل (مؤقت)
إذا كنت تريد تجنب إنشاء الفهارس مؤقتاً، يمكنك:
1. تعطيل ميزة "تحديد الرسائل كمقروءة"
2. استخدام استعلامات أبسط
3. تقليل عدد الرسائل المعروضة

## اختبار النظام
بعد إنشاء الفهارس:
1. أعد تشغيل التطبيق
2. جرب إنشاء محادثة جديدة
3. أرسل بعض الرسائل
4. تأكد من عمل عداد الرسائل غير المقروءة

إذا استمرت المشاكل، تواصل مع المطور.