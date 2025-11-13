const mongoose = require('mongoose');

const reviewSchema = new mongoose.Schema({
  empId: { type: String, required: true },
  empName: { type: String, required: true },
  communication: { type: String },
  attitude: { type: String },
  technicalKnowledge: { type: String },
  business: { type: String },
  reviewedBy: { type: String, required: true },
  flag: { 
    type: String, 
    enum: ["Green Flag", "Yellow Flag", "Red Flag"], // ✅ restrict to allowed flags
    default: "Green Flag" 
  },
  reviewedAt: { type: Date, default: Date.now },
}, { timestamps: true });

// Pre-save hook → auto add year & month
reviewSchema.pre("save", function (next) {
  const date = this.reviewedAt || new Date();
  this.reviewYear = date.getFullYear();
  this.reviewMonth = date.getMonth() + 1;
  next();
});

// Compound index → only 1 review per empId per month
reviewSchema.index({ empId: 1, reviewYear: 1, reviewMonth: 1 }, { unique: true });

module.exports = mongoose.model('Review', reviewSchema);
