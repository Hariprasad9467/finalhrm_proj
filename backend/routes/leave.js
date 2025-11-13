//routes/leave.js
const mongoose = require("mongoose");
const express = require("express");
const router = express.Router();

const Leave = require("../models/Leave");
const LeaveBalance = require("../models/leaveBalance");
const Employee = require("../models/employee");

// -------------------- Helpers --------------------
const normalize = (s = "") => String(s).trim().toLowerCase();
const isValidObjectId = (id) => mongoose.Types.ObjectId.isValid(id);

// ✅ Format dates as DD-MM-YYYY
function formatDateDDMMYYYY(date) {
  if (!date) return null;
  const d = new Date(date);
  if (isNaN(d)) return null;
  const day = String(d.getDate()).padStart(2, "0");
  const month = String(d.getMonth() + 1).padStart(2, "0");
  const year = d.getFullYear();
  return `${day}-${month}-${year}`;
}

// ✅ Convert Leave document to object with formatted dates
function formatLeaveDates(leave) {
  return {
    ...leave.toObject(),
    fromDate: formatDateDDMMYYYY(leave.fromDate),
    toDate: formatDateDDMMYYYY(leave.toDate),
    cancelledAt: leave.cancelledAt ? formatDateDDMMYYYY(leave.cancelledAt) : undefined,
    createdAt: formatDateDDMMYYYY(leave.createdAt),
    updatedAt: formatDateDDMMYYYY(leave.updatedAt),
  };
}

// ✅ Inclusive day count between two dates
function diffDaysInclusive(fromDate, toDate) {
  try {
    const start = new Date(fromDate);
    const end = new Date(toDate);
    start.setHours(0, 0, 0, 0);
    end.setHours(0, 0, 0, 0);
    const ms = end.getTime() - start.getTime();
    const days = Math.floor(ms / (1000 * 60 * 60 * 24)) + 1;
    return Math.max(days, 1);
  } catch {
    return 1;
  }
}

// ✅ Decide approver role from applicant position
function approverForPosition(position) {
  const p = normalize(position);

  if (p === "employee") return "admin";
  if (p === "admin") return "founder";
  if (p === "tl") return "founder";
  if (p === "founder" || p === "hr"  || p === "superadmin") return "auto-approved";

  return "admin"; // fallback
}

/**
 * Robust date parser that accepts:
 *  - "DD-MM-YYYY" or "D-M-YYYY"
 *  - "DD/MM/YYYY"
 *  - ISO date strings
 *  - Date objects or timestamps
 */
function parseDateInput(input, endOfDay = false) {
  if (!input && input !== 0) return null;

  if (input instanceof Date) {
    const d = new Date(input);
    if (isNaN(d)) return null;
    d.setHours(endOfDay ? 23 : 0, endOfDay ? 59 : 0, endOfDay ? 59 : 0, endOfDay ? 999 : 0);
    return d;
  }

  if (typeof input === "string") {
    const s = input.trim();
    const m = s.match(/^(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{4})$/);
    if (m) {
      const day = Number(m[1]);
      const month = Number(m[2]);
      const year = Number(m[3]);
      if (month < 1 || month > 12 || day < 1 || day > 31) return null;
      const d = new Date(year, month - 1, day);
      if (isNaN(d)) return null;
      d.setHours(endOfDay ? 23 : 0, endOfDay ? 59 : 0, endOfDay ? 59 : 0, endOfDay ? 999 : 0);
      return d;
    }
    const iso = new Date(s);
    if (!isNaN(iso)) {
      iso.setHours(endOfDay ? 23 : 0, endOfDay ? 59 : 0, endOfDay ? 59 : 0, endOfDay ? 999 : 0);
      return iso;
    }
    return null;
  }

  if (typeof input === "number") {
    const d = new Date(input);
    if (isNaN(d)) return null;
    d.setHours(endOfDay ? 23 : 0, endOfDay ? 59 : 0, endOfDay ? 59 : 0, endOfDay ? 999 : 0);
    return d;
  }

  return null;
}

// -------------------- Routes --------------------

// ✅ New Route: Get approvers for an employee
router.get("/approvers/:employeeId", async (req, res) => {
  try {
    const { employeeId } = req.params;
    const employee = await Employee.findOne({ employeeId: employeeId.trim() });

    if (!employee) {
      return res.status(404).json({ message: "❌ Employee not found" });
    }

    const position = normalize(employee.position);
    
    // If employee or intern, find their domain's TL.
    if (position === "employee" || position === "intern" || position === "tech trainee") {
      const employeeDomain = employee.domain;
      if (!employeeDomain) {
        return res.status(400).json({ message: "❌ Employee domain not set" });
      }
      // This is the database query that finds the TL in the same domain.
      const approvers = await Employee.find({ position: "TL", domain: employeeDomain }, 'employeeId employeeName');
      return res.json(approvers);
    } 
    // If the user is a TL, their approver is HR.
    else if (position === "tl") {
      const approvers = await Employee.find({ position: "HR" }, 'employeeId employeeName');
      return res.json(approvers);
    } 
    // If the user is HR, their approver is the Founder.
    else if (position === "hr") {
      const approvers = await Employee.find({ position: "Founder" }, 'employeeId employeeName');
      return res.json(approvers);
    }
    // For other roles, return an empty list.
    else {
      return res.json([]); 
    }
  } catch (err) {
    res.status(500).json({ message: "❌ Server error fetching approvers" });
  }
});


// 1) Employee Login 
router.post("/employee-login", async (req, res) => {
  const { employeeId, employeeName, position } = req.body;

  if (!employeeId || !employeeName || !position) {
    return res.status(400).json({ message: "❌ All fields are required" });
  }

  try {
    const employee = await Employee.findOne({
      employeeId: employeeId.trim(),
      employeeName: employeeName.trim(),
      position: position.trim(),
    });

    if (!employee) {
      return res.status(401).json({ message: "❌ Invalid credentials" });
    }

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
    res.status(500).json({ message: "❌ Server error" });
  }
});

// 2) Apply Leave
router.post("/apply-leave", async (req, res) => {
  try {
    const {
      employeeId, employeeName, position, approverId, // ✅ Added approverId
      leaveType, fromDate, toDate, reason, numberOfDays,
    } = req.body;

    if (!employeeId || !employeeName || !position || !leaveType || !fromDate || !toDate || !approverId) {
      return res.status(400).json({ message: "❌ Required fields missing" });
    }

    const from = parseDateInput(fromDate, false);
    const to = parseDateInput(toDate, true);

    if (!from || !to) {
      return res.status(400).json({ message: "❌ Invalid date format" });
    }

    const today = new Date(); today.setHours(0, 0, 0, 0);
    if (from < today) {
      return res.status(400).json({ message: "❌ Cannot apply leave for past dates" });
    }
    if (to < from) {
      return res.status(400).json({ message: "❌ toDate must be same or after fromDate" });
    }

    // const approver = approverForPosition(position); // ❌ No longer needed
    const applicantRole = position.toLowerCase();   // ✅ add this

    const days = Number.isFinite(Number(numberOfDays)) && Number(numberOfDays) > 0
      ? Number(numberOfDays)
      : diffDaysInclusive(from, to);

    const payload = {
      employeeId,
      employeeName,
      position,
      leaveType,
      approver: approverId, // ✅ Use approverId from request
      applicantRole,   // ✅ add this
      fromDate: from,
      toDate: to,
      reason,
      numberOfDays: days,
      status: "Pending", // All leaves go to pending now
    };

    const newLeave = new Leave(payload);
    await newLeave.save();

    res.status(201).json({
      message: "✅ Leave applied successfully",
      leave: formatLeaveDates(newLeave),
    });
  } catch (err) {
    console.error("❌ Apply-leave error:", err);
    res.status(500).json({ message: "❌ Error applying leave" });
  }
});

// Leave Approvals
router.get("/leave-approvals/:employeeId", async (req, res) => {
  try {
    const loggedInEmployeeId = req.params.employeeId.trim();
    const approverUser = await Employee.findOne({ employeeId: loggedInEmployeeId });
    if (!approverUser) return res.status(404).json({ message: "❌ Approver not found" });

    const approverRole = normalize(approverUser.position);

    let findCondition = {
      status: "Pending",
      employeeId: { $ne: loggedInEmployeeId }, // Don't show own requests
    };

    // HR and Founder see requests from employees/interns (assigned to a TL) AND requests from TLs.
    if (approverRole === 'founder') {
      findCondition.$or = [
        { applicantRole: { $in: ["employee", "intern", "tech trainee"] } },
        { applicantRole: "tl" },
        { applicantRole: "hr" } // Founder can see HR's leave requests
      ];
    } else if (approverRole === 'hr') {
      // HR sees requests from TLs and below, but NOT from other HRs.
      findCondition.$or = [{ applicantRole: { $in: ["employee", "intern", "tech trainee"] } }, { applicantRole: "tl" }];
    } 
    // A TL sees only the requests specifically assigned to them.
    else if (approverRole === 'tl') {
      findCondition.approver = loggedInEmployeeId;
    } else {
      // Other roles (like Founder) might have different logic, but for now, they see nothing by default.
      findCondition._id = null; // No results
    }

    const leaves = await Leave.find({
      ...findCondition
    }).sort({ createdAt: -1 });


    res.status(200).json({ items: leaves.map(formatLeaveDates) });
  } catch (err) {
    res.status(500).json({ message: "❌ Error fetching leave approvals" });
  }
});

// All by role
router.get("/all/by-role/:role", async (req, res) => {
  try {
    const role = normalize(req.params.role);

    let approverRoles = [role];
    if (role === "founder" || role === "hr" || role === "superadmin") {
      approverRoles = ["admin", "founder", "hr"]; // ✅ see all pending
    }

    const leaves = await Leave.find({
      approver: { $in: approverRoles },
      status: { $in: ["Pending"] },
    }).sort({ createdAt: -1 });

    res.json({ items: leaves.map(formatLeaveDates) });
  } catch (err) {
    res.status(500).json({ message: "❌ Internal server error" });
  }
});


// Fetch All Leaves
router.get("/all", async (req, res) => {
  try {
    const { employeeId } = req.query;
    const query = employeeId ? { employeeId } : {};
    const leaves = await Leave.find(query).sort({ fromDate: -1 });

    res.status(200).json({ items: leaves.map(formatLeaveDates) });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Fetch by employee
router.get("/fetch/:employeeId", async (req, res) => {
  try {
    const { status } = req.query;
    const employeeId = req.params.employeeId.trim();
    const filter = { employeeId };

    if (status) {
      if (status === "Cancelled") filter.status = "Cancelled";
      else filter.status = { $in: [status] };
    } else {
      filter.status = { $nin: ["Cancelled"] };
    }

    const leaves = await Leave.find(filter).sort({ createdAt: -1 }).limit(5);
    res.json({ items: leaves.map(formatLeaveDates) });
  } catch (err) {
    res.status(500).json({ message: "❌ Internal server error" });
  }
});
// Get Employee Name (use Employee collection)

router.get("/get-employee-name/:employeeId", async (req, res) => {
  try {
    const { employeeId } = req.params;
    const emp = await Employee.findOne({ employeeId: employeeId.trim() });

    if (!emp) return res.status(404).json({ message: "❌ Employee not found" });

    res.json({ employeeName: emp.employeeName, position: emp.position, domain: emp.domain });
  } catch (err) {
    res.status(500).json({ message: "❌ Internal server error" });
  }
});


// ✅ Pending count for Admin / Founder / HR / SuperAdmin dashboards
router.get("/pending-count", async (req, res) => {
    try {
        const approverRole = normalize(req.query.approver);
        const approverId = req.query.approverId; // Pass the approver's employeeId from the frontend

        if (!approverRole) {
            return res.status(400).json({ message: "❌ approver role is required" });
        }

        let matchCondition = {
            status: "Pending",
        };

        if (approverRole === 'founder' || approverRole === 'superadmin') {
            // Founder/Superadmin sees requests from TLs, HR, and below.
            matchCondition.$or = [
                { applicantRole: { $in: ["employee", "intern", "tech trainee"] } },
                { applicantRole: "tl" },
                { applicantRole: "hr" }
            ];
        } else if (approverRole === 'hr') {
            // HR sees requests from TLs and below, but NOT from other HRs.
            matchCondition.$or = [
                { applicantRole: { $in: ["employee", "intern", "tech trainee"] } },
                { applicantRole: "tl" }
            ];
        } else if (approverRole === 'tl') {
            // A TL sees only the requests specifically assigned to them.
            if (!approverId) return res.status(400).json({ message: "❌ approverId is required for TL role" });
            matchCondition.approver = approverId;
        } else {
            // Other roles see no pending requests by default.
            return res.json({ pendingCount: 0 });
        }

        const count = await Leave.countDocuments(matchCondition);
        res.json({ pendingCount: count });
    } catch (err) {
        console.error("❌ pending-count error:", err);
        res.status(500).json({ message: "❌ Internal server error" });
    }
});


// (Kept for compatibility if you still call /pending?approver=...&countOnly=...)
// but now it filters by approver role properly.
router.get("/pending", async (req, res) => {
  try {
    const { approver, countOnly } = req.query;
    if (!approver) return res.status(400).json({ message: "❌ approver is required" });

    const filter = { status: "Pending", approver: normalize(approver) };

    if (normalize(countOnly) === "true") {
      const count = await Leave.countDocuments(filter);
      return res.json({ pendingCount: count });
    }

    const pendingLeaves = await Leave.find(filter).sort({ createdAt: -1 });
    res.json({ items: pendingLeaves }); // ✅ wrapped
  } catch (err) {
    res.status(500).json({ message: "❌ Internal server error" });
  }
});

// Cancel Leave
router.delete("/delete/:employeeId/:id", async (req, res) => {
  try {
    const { employeeId, id } = req.params;
    if (!isValidObjectId(id)) return res.status(400).json({ success: false, message: "❌ Invalid leave ID" });

    const leave = await Leave.findOneAndUpdate(
      { _id: id, employeeId: employeeId.trim() },
      { $set: { status: "Cancelled", cancelledAt: new Date() } },
      { new: true, runValidators: true }
    );

    if (!leave) return res.status(404).json({ success: false, message: "❌ Leave not found" });

    res.status(200).json({ success: true, message: "✅ Leave cancelled successfully", leave: formatLeaveDates(leave) });
  } catch (err) {
    res.status(500).json({ success: false, message: "❌ Internal server error" });
  }
});

// Update Leave
router.put("/update/:employeeId/:id", async (req, res) => {
  try {
    const { employeeId, id } = req.params;
    const updatedData = req.body;

    const leave = await Leave.findOne({ _id: id, employeeId: employeeId.trim() });
    if (!leave) return res.status(404).json({ message: "❌ Leave not found" });

    leave.leaveType = updatedData.leaveType ?? leave.leaveType;
    leave.reason = updatedData.reason ?? leave.reason;

    if (updatedData.fromDate) {
      const parsedFrom = parseDateInput(updatedData.fromDate, false);
      if (!parsedFrom) return res.status(400).json({ message: "❌ Invalid fromDate format" });
      leave.fromDate = parsedFrom;
    }
    if (updatedData.toDate) {
      const parsedTo = parseDateInput(updatedData.toDate, true);
      if (!parsedTo) return res.status(400).json({ message: "❌ Invalid toDate format" });
      leave.toDate = parsedTo;
    }

    if (leave.toDate < leave.fromDate) {
      return res.status(400).json({ message: "❌ toDate must be same or after fromDate" });
    }

    if (updatedData.fromDate || updatedData.toDate || !leave.numberOfDays) {
      leave.numberOfDays = diffDaysInclusive(leave.fromDate, leave.toDate);
    }

    if (updatedData.position) {
      leave.position = updatedData.position;
      leave.approver = approverForPosition(updatedData.position);
    }

    leave.status = "Pending";
    await leave.save();

    res.json({ message: "✅ Leave updated successfully", leave: formatLeaveDates(leave) });
  } catch (err) {
    res.status(500).json({ message: "❌ Internal server error" });
  }
});

// Cancelled leave history
router.get("/cancelled/:employeeId", async (req, res) => {
  try {
    const { employeeId } = req.params;
    const cancelledLeaves = await Leave.find({ employeeId, status: "Cancelled" }).sort({ cancelledAt: -1 });

    res.status(200).json({ items: cancelledLeaves.map(formatLeaveDates) });
  } catch (err) {
    res.status(500).json({ message: "❌ Internal server error" });
  }
});

// Update status
async function updateStatus(req, res) {
  try {
    const { id } = req.params;
    const { status } = req.body;

    if (!["Approved", "Rejected", "Cancelled", "Pending"].includes(status)) {
      return res.status(400).json({ message: "❌ Invalid status value" });
    }

    const updatedLeave = await Leave.findByIdAndUpdate(id, { status }, { new: true });
    if (!updatedLeave) return res.status(404).json({ message: "❌ Leave not found" });

    res.json({ message:`✅ Leave ${status}`, leave: formatLeaveDates(updatedLeave) });
  } catch (err) {
    res.status(500).json({ message: "❌ Server error" });
  }
}
router.put("/status/:id", updateStatus);

router.put("/status/:id", async (req, res) => {
    try {
        const { id } = req.params;
        const { status } = req.body;

        if (!["Approved", "Rejected"].includes(status)) {
            return res.status(400).json({ message: "❌ Invalid status value" });
        }

        const updatedLeave = await Leave.findByIdAndUpdate(id, { status }, { new: true });
        if (!updatedLeave) return res.status(404).json({ message: "❌ Leave not found" });

        res.json({ message: `✅ Leave ${status}`, leave: formatLeaveDates(updatedLeave) });
    } catch (err) {
        res.status(500).json({ message: "❌ Server error" });
    }
});
router.put("/update/:id", updateStatus);

// Leave Balance
router.get("/leave-balance/:employeeId", async (req, res) => {
  try {
    const employeeId = req.params.employeeId.trim();
    const year = parseInt(req.query.year || new Date().getFullYear(), 10);

    const approved = await Leave.find({ employeeId, status: "Approved" });

    const totals = { casual: 0, sick: 0, sad: 0 };
    for (const l of approved) {
      const y = new Date(l.fromDate).getFullYear();
      if (y !== year) continue;

      const t = normalize(l.leaveType);
      if (t === "casual") totals.casual += l.numberOfDays || 0;
      if (t === "sick") totals.sick += l.numberOfDays || 0;
      if (t === "sad") totals.sad += l.numberOfDays || 0;
    }

    const ALLOWANCE = 12;
    const build = (used) => ({ used, total: ALLOWANCE, remaining: Math.max(0, ALLOWANCE - used) });

    res.json({
      year,
      balances: {
        casual: build(totals.casual),
        sick: build(totals.sick),
        sad: build(totals.sad),
      },
    });
  } catch (err) {
    res.status(500).json({ message: "❌ Internal server error" });
  }
});

// ✅ Filter leaves by date range + role awareness
router.get("/filter", async (req, res) => {
  try {
    const { employeeId, fromDate, toDate, role, status } = req.query;

    let query = {};

    if (role) {
      query.approver = normalize(role);
      if (employeeId) {
        query.employeeId = { $ne: employeeId.trim() };
      }
    } else if (employeeId) {
      query.employeeId = employeeId.trim();
    }

    // ✅ status filter
    if (status) {
      if (status === "Cancelled") {
        query.status = "Cancelled";
      } else if (status === "All") {
        query.status = { $in: ["Approved", "Rejected"] };
      } else {
        query.status = status;
      }
    } else {
      query.status = { $nin: ["Cancelled"] };
    }

    // ✅ date range filter
if (fromDate && toDate) {
  const start = parseDateInput(fromDate, false); // use helper
  const end = parseDateInput(toDate, true);      // use helper

  if (!start || !end) {
    return res.status(400).json({ message: "❌ Invalid date range format" });
  }

  query.fromDate = { $lte: end };
  query.toDate = { $gte: start };

  console.log("📌 Raw Params:", { fromDate, toDate, status, employeeId, role });
  console.log("📌 Parsed Start:", start, "Parsed End:", end);
  console.log("📌 Final Query:", JSON.stringify(query, null, 2));
}


    const leaves = await Leave.find(query).sort({ fromDate: -1 });
    console.log("📌 Result Count:", leaves.length); // ✅ how many found

    //res.status(200).json({ items: leaves });
    res.status(200).json({ items: leaves.map(formatLeaveDates) });
  } catch (err) {
    console.error("❌ Filter error:", err);
    res.status(500).json({ error: err.message });
  }
});







module.exports = router;