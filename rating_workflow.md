# 🌟 Rating System Workflow

## 📱 Mobile App Flow:

### 1. Patient Books Appointment
```dart
booking/{bookingId} {
  doctorId: "doctorUserId",
  userId: "patientUserId",
  username: "Ahmed Hassan",
  status: "booked",        // ← Initial status
  // ... other fields
}
```

### 2. Doctor Completes Appointment (Web Dashboard)
```javascript
// Doctor marks appointment as completed
await db.collection('booking').doc(bookingId).update({
  status: "completed"
});

// Send notification to patient
await db.collection('notifications').add({
  userId: patientUserId,
  title: "Rate Your Experience",
  message: "How was your appointment with Dr. Ahmed? Please rate your experience.",
  type: "rating_request",
  data: {
    bookingId: bookingId,
    doctorId: doctorId,
    doctorName: "Dr. Ahmed"
  },
  isRead: false,
  createdAt: FieldValue.serverTimestamp()
});
```

### 3. Patient Receives Notification
- Patient opens app → sees notification
- Taps notification → opens RatingScreen
- Submits rating → updates doctor's average rating

### 4. Rating Submission Process
```dart
// 1. Add rating to ratings collection
ratings/{ratingId} {
  doctorId: "doctorUserId",
  userId: "patientUserId", 
  username: "Ahmed Hassan",
  bookingId: "bookingId",
  rating: 4.5,
  comment: "Great doctor!",
  createdAt: timestamp
}

// 2. Update booking status
booking/{bookingId} {
  status: "rated"  // ← Final status
}

// 3. Update doctor's average rating
users/{doctorId} {
  rating: 4.2,           // ← Calculated average
  totalReviews: 15       // ← Total count
}
```

## 🌐 Web Dashboard Features:

### Doctor Dashboard:
- **📋 Appointments List:** View all bookings with status
- **✅ Mark Complete:** Change status from "booked" to "completed"
- **⭐ View Ratings:** See all ratings and comments
- **📊 Statistics:** Average rating, total reviews

### Admin Dashboard:
- **👨‍⚕️ Doctor Management:** Approve/reject doctor applications
- **📈 Analytics:** Overall platform statistics
- **🔍 Review System:** Monitor ratings and reviews

## 🔄 Status Flow:
```
booked → completed → rated
  ↑         ↑         ↑
Patient   Doctor    Patient
books     marks     rates
         complete
```

## 📊 Collections Structure:

```
📁 users (doctors & patients)
📁 booking (appointments)
📁 ratings (doctor reviews)
📁 notifications (rating requests)
```

This system ensures:
- ✅ Only completed appointments can be rated
- ✅ Patients get notified to rate after completion
- ✅ Doctor ratings are automatically calculated
- ✅ Web dashboard has full control over appointment flow