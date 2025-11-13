const express = require('express');
const router = express.Router();
const Reports = require('../models/reviewmodel');

// ---------------- Get All Reviews ----------------
router.get('/', async (req, res) => {
  try {
    const reviews = await Reports.find().sort({ createdAt: -1 }); // ✅ latest first
    res.json(reviews.map(r => r.toJSON()));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ---------------- Get Reviews by Employee ----------------
router.get('/employee/:empId', async (req, res) => {
  try {
    const reviews = await Reports.find({ empId: req.params.empId }).sort({ createdAt: -1 });

    if (!reviews || reviews.length === 0) {
      return res.status(404).json({ message: 'No reviews found for this employee' });
    }

    res.json(reviews.map(r => r.toJSON()));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ---------------- Get Review by ID ----------------
router.get('/:id', async (req, res) => {
  try {
    const review = await Reports.findById(req.params.id);
    if (!review) {
      return res.status(404).json({ message: 'Review not found' });
    }
    res.json(review.toJSON());
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ---------------- Update Review ----------------
router.put('/:id', async (req, res) => {
  try {
    const updated = await Reports.findByIdAndUpdate(
      req.params.id,
      { ...req.body },
      { new: true } // ✅ return updated doc
    );

    if (!updated) {
      return res.status(404).json({ message: 'Review not found' });
    }

    res.json(updated.toJSON()); // ✅ always send latest
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;