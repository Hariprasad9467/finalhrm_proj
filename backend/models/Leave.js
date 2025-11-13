const mongoose = require('mongoose');

const leaveSchema = new mongoose.Schema({
  employeeId: { type: String, required: true },
  employeeName: { type: String, required: true },
  position: { type: String, required: true },
  leaveType: { type: String, required: true },
  
  approver: { type: String, required: true }, // "admin" | "superadmin"
  applicantRole: { type: String, required: true }, // "employee" | "intern" | "admin"

  fromDate: { type: Date, required: true },
  toDate: { type: Date, required: true },
  reason: { type: String, required: true },
  status: {
    type: String,
    enum: ["Pending", "Approved", "Rejected", "Cancelled"],
    default: "Pending",
  },
  numberOfDays: { type: Number, default: 1 },
  cancelledAt: { type: Date },
}, { timestamps: true });

const Leave = mongoose.models.Leave || mongoose.model('Leave', leaveSchema);
module.exports = Leave;
