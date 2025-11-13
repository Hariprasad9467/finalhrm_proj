const mongoose = require("mongoose");

const leaveBalanceSchema = new mongoose.Schema({
  // use the SAME employeeId you log in with (e.g., "zeai001")
  employeeId: { type: String, required: true },
  year: { type: Number, default: new Date().getFullYear() },
  balances: {
    casual: { total: { type: Number, default: 12 }, taken: { type: Number, default: 0 } },
    sick:   { total: { type: Number, default: 12 }, taken: { type: Number, default: 0 } },
    sad:    { total: { type: Number, default: 12 }, taken: { type: Number, default: 0 } }
  }
}, { timestamps: true });

// avoid duplicates per employee per year
leaveBalanceSchema.index({ employeeId: 1, year: 1 }, { unique: true });

// ✅ Prevent OverwriteModelError
const LeaveBalance = mongoose.models.LeaveBalance || mongoose.model("LeaveBalance", leaveBalanceSchema);

module.exports = LeaveBalance;
