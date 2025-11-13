const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema({
  month: {
    type: String,
    required: true,
    enum: [
      "January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December"
    ]
  },
  category: {
    type: String,
    required: true,
    enum: ["message","performance", "meeting", "event", "holiday", "leave"] // ✅ Added "leave"
  },
  message: { type: String, required: true },
  empId: { type: String, required: false },   // employee-specific or global
  // 🔴 New sender details
  // 🔹 Only for message (SMS) type
  // senderId: { type: String, required: true },
  // senderName: { type: String, required: true },
  // senderRole: { type: String, required: true },
  senderId: { type: String, required: false, default: "" },
  senderName: { type: String, required: false, default: "" },
  flag: { type: String, required: false, default: "" },
  createdAt: { type: Date, default: Date.now }
});

const Notification = mongoose.model("Notification", notificationSchema);
module.exports = Notification;