const express = require('express');
const router = express.Router();
const Notification = require("../models/notifications");
//const mongoose = require('mongoose');






// 🔹 Get ALL notifications for a specific employee with optional month & category filter
router.get('/employee/:empId', async (req, res) => {
  try {
    const { empId } = req.params;
    const { month, category } = req.query; // 🔹 Accept query params

    const query = {
      $or: [
        { empId }, 
        { empId: null },
        { empId: "" }
      ]
    };

    if (month) {
      query.month = { $regex: new RegExp(`^${month}$`, 'i') };
    }

    if (category) {
      query.category = { $regex: new RegExp(`^${category}$`, 'i') };
    }
    // const notifications = await Notification.find({
      const notifications = await Notification.find(query).sort({ createdAt: -1 });
    //   $or: [
    //     { empId },       // employee-specific
    //     { empId: null }, // global
    //     { empId: "" }    // global empty
    //   ]
    // }).sort({ createdAt: -1 });

    if (!notifications.length) {
      return res.status(404).json({ message: "No notifications found for this employee" });
    }

    res.json(notifications);
  } catch (err) {
    console.error("Error fetching notifications:", err);
    res.status(500).json({ message: "Server error" });
  }
});

// 🔹 HOLIDAYS
// Employee holidays
router.get('/holiday/employee/:empId', async (req, res) => {
  try {
    const { empId } = req.params;
    const { month } = req.query;

    const query = {
      category: "holiday",
      $or: [{ empId }, { empId: null }, { empId: "" }]
    };

    if (month) {
      query.month = { $regex: new RegExp(month, 'i') };
    }

    const holidays = await Notification.find(query).sort({ createdAt: -1 });

    if (!holidays.length) {
      return res.status(404).json({ message: "No holiday notifications found" });
    }

    res.json(holidays);
  } catch (err) {
    console.error("Error fetching employee holiday notifications:", err);
    res.status(500).json({ message: "Server error" });
  }
});

// Admin holidays
router.get('/holiday/admin/:month', async (req, res) => {
  try {
    const { month } = req.params;

    const query = {
      category: "holiday",
      month: { $regex: new RegExp(month, 'i') }
    };

    const holidays = await Notification.find(query).sort({ createdAt: -1 });

    if (!holidays.length) {
      return res.status(404).json({ message: "No holiday notifications for admin" });
    }

    res.json(holidays);
  } catch (err) {
    console.error("Error fetching admin holiday notifications:", err);
    res.status(500).json({ message: "Server error" });
  }
});

// Performance → Admin view
router.get('/performance/admin/:month/:empId', async (req, res) => {
  const { month, empId } = req.params;
  try {
    const notifications = await Notification.find({
      category: "performance",
      month: { $regex: new RegExp(`^${month}$`, 'i') },
      $or: [
        { empId },       // admin-specific
        { empId: null }, // global
        { empId: "" }    // global
      ]
    });

    if (!notifications.length) {
      return res.status(404).json({ message: 'No performance notifications for this admin' });
    }

    res.json(notifications);
  } catch (err) {
    console.error('Error fetching performance notifications for admin:', err);
    res.status(500).json({ message: 'Server error' });
  }
});

// 3️⃣ Performance → Employee view
// ✅ Get notifications for a SPECIFIC EMPLOYEE (Employee view)
//router.get('/:month/:empId', async (req, res) => {
router.get('/performance/employee/:month/:empId', async (req, res) => {
  const { month, empId } = req.params;
  try {
    const notifications = await Notification.find({
      category: "performance",
      month: { $regex: new RegExp(`^${month}$`, 'i') },
      $or: [
        { empId },      // employee-specific
        { empId: null }, // global notifications
        { empId: "" }   // also allow empty empId for global
      ],
    });

    if (!notifications.length) {
      return res.status(404).json({ message: "No performance notifications for this employee" });
    }

    res.json(notifications);
  } catch (err) {
    console.error("Error fetching performance for employee:", err);
    res.status(500).json({ message: 'Server error' });
  }
});

// ✅ Add a new notification
router.post('/', async (req, res) => {
  try {
    const { month, category, message, empId, senderName, senderId,flag} = req.body;
   // if (!senderName || !senderId || !message) {
   if (!message || !empId || !category) { // only required fields
      return res.status(400).json({ message: "Sender info is required" });
    }
    const newNotification = new Notification({ month, category, message, empId,
      //senderName,  // 🔴 red
      //senderId,
    senderName: senderName || "", // optional
    senderId: senderId || "",
    flag: flag || ""     });


    await newNotification.save();
    res.status(201).json({ message: 'Notification added successfully' });
  } catch (err) {
    console.error('Error adding notification:', err);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;