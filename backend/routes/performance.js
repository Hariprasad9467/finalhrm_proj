const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');

// ✅ Performance Schema
const performanceSchema = new mongoose.Schema({
  employeeId: String,
  employeeName: String,
  month: String,
  flag: String,               // Red Flag / Yellow Flag / Green Flag
  communication: String,
  attitude: String,
  technicalKnowledge: String,
  businessKnowledge: String,
  overallComment: String,
  reviewer: String,
  status: String,              // Eg: Agree / Pending etc
  createdAt: { type: Date, default: Date.now }
});

const PerformanceReview = mongoose.model('PerformanceReview', performanceSchema);

// ✅ POST API - Save HR Performance Review
router.post('/performance/save', async (req, res) => {
  try {
    const review = new PerformanceReview(req.body);
    await review.save();
    res.status(200).json({ message: '✅ Performance saved successfully' });
  } catch (error) {
    console.error('❌ Error saving performance:', error);
    res.status(500).json({ error: '❌ Failed to save review' });
  }
});

// ✅ GET API - List All Performance Reviews
router.get('/performance/list', async (req, res) => {
  try {
    const reviews = await PerformanceReview.find().sort({ createdAt: -1 }); // Latest first
    res.status(200).json(reviews);
  } catch (error) {
    console.error('❌ Error fetching performance reviews:', error);
    res.status(500).json({ error: '❌ Failed to fetch reviews' });
  }
});

module.exports=router;