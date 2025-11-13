const mongoose = require("mongoose");

const reviewSchema = new mongoose.Schema({
  empId: String,
  empName: String,
  communication: String,
  attitude: String,
  technicalKnowledge: String,
  business: String,
  reviewedBy: String,
  reviewMonth: String,
  flag: { type: String, enum: ["Green", "Yellow", "Red"], required: true },
  status: { type: String, default: "Pending" },
  createdAt: { type: Date, default: Date.now },
});

// 🔑 Normalize _id → id
reviewSchema.set("toJSON", {
  transform: (doc, ret) => {
    ret.id = ret._id.toString();
    delete ret._id;
    delete ret.__v;
    return ret;
  },
});

module.exports = mongoose.model("reviews",reviewSchema);