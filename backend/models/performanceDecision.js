
const mongoose = require("mongoose");

const ReviewDecisionSchema = new mongoose.Schema({
  employeeId: { type: String, required: true },
  employeeName: { type: String, required: true },
  position: { type: String, required: true },
  decision: { type: String, enum: ["agree", "disagree"], required: true },
  comment: { type: String, default: "" },   // ✅ optional
  sendTo: [{ type: String }],               // ✅ store who it’s sent to
  reviewId: { type: mongoose.Schema.Types.ObjectId, ref: "reviewmodel", required: true },
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model("performanceDecision", ReviewDecisionSchema);
