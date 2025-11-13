//routes/employee.js
const express = require("express");
const mongoose = require("mongoose");
const multer = require("multer");
const path = require("path");
const Attendance = require("../models/attendance");
const Employee = require("../models/employee"); // 🔹 merged schema we created earlier
const LeaveBalance = require("../models/leaveBalance");

const router = express.Router();
const fs = require("fs");

// Ensure uploads folder exists
const uploadDir = path.join(__dirname, "../uploads");
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir);
}


// ------------------ Multer Setup ------------------ //
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, "uploads/"); // make sure this folder exists
  },
  filename: (req, file, cb) => {
    cb(null, Date.now() + path.extname(file.originalname).toLowerCase());
  },
});

// ✅ File filter: allow only jpg/jpeg images (case-insensitive)
const fileFilter = (req, file, cb) => {
  const ext = path.extname(file.originalname).toLowerCase(); // lowercase extension
  if (ext === ".jpg" || ext === ".jpeg") {
    cb(null, true);
  } else {
    cb(new Error("Only .jpg or .jpeg files are allowed"), false);
  }
};

const upload = multer({ storage, fileFilter });

// 🔹 Utility: always return DD-MM-YYYY
function getToday() {
  const d = new Date();
  const day = String(d.getDate()).padStart(2, "0");
  const month = String(d.getMonth() + 1).padStart(2, "0");
  const year = d.getFullYear();
  return `${day}-${month}-${year}`;
}

// ------------------ Routes ------------------ //

// ------------------ Employee Login ------------------ //
router.post("/employee-login", async (req, res) => {
  const { employeeId, employeeName, position } = req.body;

  if (!employeeId || !employeeName || !position) {
    return res.status(400).json({ message: "All fields are required" });
  }

  try {
    // ✅ Case-insensitive search
    const employee = await Employee.findOne({
      employeeId: employeeId.trim(),
      employeeName: { $regex: `^${employeeName.trim()}$`, $options: "i" },
      position: { $regex: `^${position.trim()}$`, $options: "i" },
    });

    if (!employee) {
      return res.status(401).json({ message: "Invalid credentials" });
    }

    // ✅ Ensure LeaveBalance exists
    await LeaveBalance.updateOne(
      { employeeId: employee.employeeId, year: new Date().getFullYear() },
      {
        $setOnInsert: {
          employeeId: employee.employeeId,
          year: new Date().getFullYear(),
          balances: {
            casual: { total: 12, taken: 0 },
            sick: { total: 12, taken: 0 },
            sad: { total: 12, taken: 0 },
          },
        },
      },
      { upsert: true }
    );

    res.status(201).json({
      message: "✅ Login Successful",
      employeeId: employee.employeeId,
      employeeName: employee.employeeName,
      position: employee.position,
      role: employee.role || "employee",
    });
  } catch (err) {
    console.error("❌ Error during login:", err);
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// ✅ Get all employees (today OR last working day)
router.get("/employees", async (req, res) => {
  try {
    const employees = await Employee.find().sort({ createdAt: -1 });
    const today = getToday();

    const result = await Promise.all(
      employees.map(async (emp) => {
        const lastAttendance = await Attendance.findOne({
          employeeId: emp.employeeId,
        }).sort({ createdAt: -1 });

        let status = "N/A";
        let loginTime = "Not logged in yet";
        let logoutTime = "Not logged out yet";
        let date = today;

        if (lastAttendance) {
          date = lastAttendance.date;
          status = lastAttendance.status;
          loginTime = lastAttendance.loginTime || loginTime;
          logoutTime = lastAttendance.logoutTime || logoutTime;
        }

        return {
          ...emp.toObject(),
          status,
          loginTime,
          logoutTime,
          date,
        };
      })
    );

    res.json(result);
  } catch (err) {
    console.error("❌ Error fetching employees with status:", err);
    res.status(500).json({ message: "Server error" });
  }
});

// ✅ Get employees by domain (for TL performance reviews)
router.get("/employees/domain/:domain", async (req, res) => {
  try {
    const { domain } = req.params;
    const employees = await Employee.find(
      {
        domain: domain,
        position: { $in: [/^employee$/i, /^intern$/i, /^tech trainee$/i] }, // ✅ Case-insensitive
      },
      "employeeId employeeName" // Select only these fields
    );
    res.json(employees);
  } catch (err) {
    res.status(500).json({ message: "❌ Server error fetching employees by domain" });
  }
});

// ✅ Get employees for Superadmin/HR review (only employees and interns)
router.get("/employees/for-review/:reviewerPosition", async (req, res) => {
  try {
    const reviewerPosition = (req.params.reviewerPosition || "").toLowerCase();
    let positionsToFind = [];

    if (reviewerPosition === 'founder') {
      // Founder reviews HR
      positionsToFind = [/^HR$/i,/^TL$/i];
    } else if (reviewerPosition === 'superadmin' || reviewerPosition === 'hr') {
      // Superadmin and HR review TLs and Admins
      positionsToFind = [/^TL$/i, /^Admin$/i];
    }

    const employees = await Employee.find({
      position: { $in: positionsToFind }
    }, "employeeId employeeName");
    res.json(employees);
  } catch (err) {
    res.status(500).json({ message: "❌ Server error fetching employees for review" });
  }
});


// ✅ Get single employee
router.get("/employees/:employeeId", async (req, res) => {
  try {
    const emp = await Employee.findOne({ employeeId: req.params.employeeId });
    if (!emp) {
      return res.status(404).json({ message: "❌ Employee not found" });
    }

    const today = getToday();
    const lastAttendance = await Attendance.findOne({
      employeeId: emp.employeeId,
    }).sort({ createdAt: -1 });

    let status = "Absent";
    let loginTime = "Not logged in yet";
    let logoutTime = "Not logged out yet";
    let date = today;

    if (lastAttendance) {
      date = lastAttendance.date;
      status = lastAttendance.status;
      loginTime = lastAttendance.loginTime || loginTime;
      logoutTime = lastAttendance.logoutTime || logoutTime;
    }

    res.json({
      ...emp.toObject(),
      status,
      loginTime,
      logoutTime,
      date,
    });
  } catch (err) {
    console.error("❌ Error fetching employee with status:", err);
    res.status(500).json({ message: "Server error" });
  }
});

// ✅ Add new employee + optional image
router.post("/employees", upload.single("employeeImage"), async (req, res) => {
  try {
    const { employeeId, employeeName, position, domain } = req.body;

    if (!employeeId || !employeeName || !position || !domain) {
      return res.status(400).json({ message: "⚠ All fields are required" });
    }

    const existing = await Employee.findOne({ employeeId });
    if (existing) {
      return res.status(409).json({ message: "❌ Employee ID already exists" });
    }

    const newEmployee = new Employee({
      employeeId,
      employeeName,
      position,
      domain,
      employeeImage: req.file ? `/uploads/${req.file.filename}` : null,
    });

    await newEmployee.save();

    res.status(201).json({
      message: "✅ Employee added successfully",
      employee: newEmployee,
    });
  } catch (err) {
    console.error("❌ Error adding employee:", err);
    res.status(500).json({ message: "Internal server error" });
  }
});

// ✅ Update employee
router.put("/employees/:id", upload.single("employeeImage"), async (req, res) => {
  try {
    const { employeeName, position, domain } = req.body;

    const updateData = { employeeName, position, domain };
    if (req.file) {
      updateData.employeeImage = `/uploads/${req.file.filename}`;
    }

    const updated = await Employee.findOneAndUpdate(
      { employeeId: req.params.id },
      updateData,
      { new: true }
    );

    if (!updated) {
      return res.status(404).json({ message: "Employee not found" });
    }

    res.json({
      message: "✅ Employee updated successfully",
      employee: updated,
    });
  } catch (err) {
    console.error("❌ Error updating employee:", err);
    res.status(500).json({ message: "❌ Error updating employee" });
  }
});

// ✅ Delete employee (and attendance)
router.delete("/employees/:id", async (req, res) => {
  try {
    const deleted = await Employee.findOneAndDelete({
      employeeId: req.params.id,
    });

    if (!deleted) {
      return res.status(404).json({ message: "Employee not found" });
    }

    await Attendance.deleteMany({ employeeId: req.params.id });

    res.json({
      message: "✅ Employee and attendance deleted successfully",
    });
  } catch (err) {
    console.error("❌ Error deleting employee:", err);
    res.status(500).json({ message: "❌ Error deleting employee" });
  }
});

module.exports = router;