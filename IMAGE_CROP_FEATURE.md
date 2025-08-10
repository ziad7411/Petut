# Image Crop & Edit Feature

## الفيتشرز المضافة:

### 1. رفع صورة مع Crop و Zoom
- لما اليوزر يختار صورة، هيفتح له crop editor
- يقدر يعمل zoom in/out
- يقدر يختار aspect ratio مختلف
- يقدر يحرك الصورة ويعدل عليها

### 2. تعديل الصورة بعد الرفع
- في create post: يقدر يعدل الصورة قبل النشر
- في edit post: يقدر يعدل الصورة الموجودة أو يضيف صورة جديدة

### 3. الأزرار المتاحة:
- **Edit**: لتعديل الصورة الحالية
- **Delete**: لحذف الصورة
- **Add & Crop**: لإضافة صورة جديدة مع crop

## الملفات المضافة:
- `lib/services/image_cropper_service.dart` - Service للتعامل مع crop
- `lib/widgets/image_picker_widget.dart` - Widget للـ create post
- `lib/widgets/edit_image_widget.dart` - Widget للـ edit post

## Dependencies المضافة:
- `image_cropper: ^5.0.1`

## Permissions المضافة في Android:
- Camera permission
- Storage read/write permissions
- UCrop activity

## كيفية الاستخدام:
1. في create post: اضغط "Add & Crop" واختار صورة
2. هيفتح crop editor - عدل الصورة زي ما تحب
3. اضغط Done عشان تحفظ التعديلات
4. يمكنك الضغط على Edit لتعديل الصورة مرة تانية
5. في edit post: نفس الخطوات + يمكنك تعديل الصور الموجودة

الفيتشر شغال على Android و iOS!