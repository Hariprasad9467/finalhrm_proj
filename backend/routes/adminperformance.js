const express = require("express");
const router = express.Router();
const Review = require("../models/adminperformance");

// POST → Add review (only once per employee per month)
router.post("/", async (req, res) => {
  try {
    const {
      empId,
      empName,
      communication,
      attitude,
      technicalKnowledge,
      business,
      reviewedBy,
      flag,
    } = req.body;

    const now = new Date();
    const reviewYear = now.getFullYear();
    const reviewMonth = now.getMonth() + 1;

    // 🔍 Check if already exists
    const existingReview = await Review.findOne({ empId, reviewYear, reviewMonth });

    if (existingReview) {
      return res.status(400).json({
        message: "⚠ Review already submitted for this month.",
        review: existingReview,
      });
    }

    // ✅ Create new review
    const newReview = new Review({
      empId,
      empName,
      communication,
      attitude,
      technicalKnowledge,
      business,
      reviewedBy,
      flag,
      reviewedAt: now,
      reviewYear,
      reviewMonth,
    });

    await newReview.save();

    return res.status(201).json({
      message: "✅ Review submitted successfully",
      review: newReview,
    });
  } catch (err) {
    // Handle Mongo duplicate error
    if (err.code === 11000) {
      return res.status(400).json({
        message: "Review already exists for this employee this month.",
      });
    }

    console.error("Error saving review:", err.message);
    res.status(500).json({ message: "❌ Server error", error: err.message });
  }
});

// GET → Fetch all reviews
router.get("/", async (req, res) => {
  try {
    const reviews = await Review.find().sort({ createdAt: -1 });
    res.json(reviews);
  } catch (err) {
    res.status(500).json({ message: "❌ Server error", error: err.message });
  }
});

module.exports = router;
