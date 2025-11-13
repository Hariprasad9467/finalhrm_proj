const mongoose = require('mongoose');

const LeaveSchema = new mongoose.Schema({
  leaveType: { type: String, required: true },
  approver: { type: String, required: true },
  fromDate: { type: String, required: true },
  toDate: { type: String, required: true },
  reason: { type: String, required: true },
  status: { type: String, default: 'Pending' } // ✅ Add this line
}, { timestamps: true });

const Leave = mongoose.model('Leave', LeaveSchema);

module.exports = Leave;
