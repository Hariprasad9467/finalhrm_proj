const express = require("express");
const Attendance = require("../models/attendance");
const router = express.Router();

// 🔹 Utility: Always return DD-MM-YYYY
function formatDateToDDMMYYYY(dateInput) {
  if (!dateInput) {
    const today = new Date();
    const day = String(today.getDate()).padStart(2, "0");
    const month = String(today.getMonth() + 1).padStart(2, "0");
    const year = today.getFullYear();
    return `${day}-${month}-${year}`;
  }

  if (typeof dateInput === "string" && /^\d{2}-\d{2}-\d{4}$/.test(dateInput)) {
    return dateInput;
  }

  const d = new Date(dateInput);
  const day = String(d.getDate()).padStart(2, "0");
  const month = String(d.getMonth() + 1).padStart(2, "0");
  const year = d.getFullYear();
  return `${day}-${month}-${year}`;
}

// ✅ POST: Save attendance (Login)
router.post("/attendance/mark/:employeeId", async (req, res) => {
  const { employeeId } = req.params;
  let { date, loginTime, logoutTime, breakTime, loginReason, logoutReason, status } = req.body;

  try {
    date = formatDateToDDMMYYYY(date);

    let existing = await Attendance.findOne({ employeeId, date });

    if (existing) {
      if (existing.status === "Login") {
        return res.status(400).json({ message: "❌ Already Logged In" });
      }

      existing.status = "Login";
      existing.loginTime = loginTime;
      existing.logoutTime = ""; // reset until actual logout
      existing.loginReason = loginReason || existing.loginReason;

      await existing.save();
      return res.status(200).json({ 
        message: "✅ Attendance updated to Login", 
        attendance: existing 
      });
    }

    // ✅ New record
    const newAttendance = new Attendance({
      employeeId,
      date,
      loginTime,
      logoutTime: "", // keep empty, not "Not logged out yet"
      breakTime: breakTime || "-",
      loginReason,
      logoutReason,
      status: status || "Login",
    });

    await newAttendance.save();
    res.status(201).json({ message: "✅ Attendance saved successfully", attendance: newAttendance });

  } catch (error) {
    console.error("❌ Error saving attendance:", error);
    res.status(500).json({ message: "Server Error" });
  }
});

// ✅ PUT: Update attendance (Logout / BreakIn / BreakOff)
router.put("/attendance/update/:employeeId", async (req, res) => {
  const { employeeId } = req.params;
  let { date, logoutTime, breakTime, breakStatus, loginReason, logoutReason, status } = req.body;

  try {
    date = formatDateToDDMMYYYY(date || undefined);
    const todayRecord = await Attendance.findOne({ employeeId, date });
    if (!todayRecord) return res.status(404).json({ message: "❌ Attendance not found" });

    // Initialize fields if missing
    if (!todayRecord.breakTime) todayRecord.breakTime = "-";

    // --- ✅ BreakIn: Start break, check total time before allowing ---
    if (breakStatus === "BreakIn") {
      let totalMinutes = 0;
      if (todayRecord.breakTime && todayRecord.breakTime !== "-") {
        const breakSegments = todayRecord.breakTime.split(",");
        for (let seg of breakSegments) {
          const match = seg.match(/\((\d+)\s*mins\)/);
          if (match) totalMinutes += parseInt(match[1]);
        }
      }

      if (totalMinutes >= 60) {
        return res.status(400).json({
          message: "⚠ You have already reached the 60-minute break limit.",
          totalMinutes,
          limitReached: true,
        });
      }

      todayRecord.breakInProgress = breakTime;
      todayRecord.status = "Break";
      await todayRecord.save();

      return res.json({
        message: "⏸ Break started",
        breakInProgress: todayRecord.breakInProgress,
        totalMinutes,
      });
    }

   // --- ✅ BreakOff: finalize break and calculate total ---
if (breakStatus === "BreakOff" && todayRecord.breakInProgress) {
  const breakStart = todayRecord.breakInProgress;
  const breakEnd = breakTime; // current time

  let breakArray = [];
  if (todayRecord.breakTime && todayRecord.breakTime !== "-") {
    breakArray = todayRecord.breakTime
      .split(",")
      .map((b) => b.trim().split(" (")[0]); // remove previous durations
  }

  breakArray.push(`${breakStart} to ${breakEnd}`);
  todayRecord.breakInProgress = null;

  // --- Helper: Convert time string to minutes since midnight ---
  const parseTime = (timeStr) => {
    const [time, modifier] = timeStr.split(" ");
    let [hours, minutes] = time.split(":").map(Number);
    if (modifier === "PM" && hours !== 12) hours += 12;
    if (modifier === "AM" && hours === 12) hours = 0;
    return hours * 60 + minutes;
  };

  // --- Calculate durations and enforce 60-min limit ---
  let totalMinutes = 0;
  const formattedBreaks = [];

  for (const segment of breakArray) {
    const [start, end] = segment.split("to").map((t) => t.trim());
    const diff = Math.max(parseTime(end) - parseTime(start), 0);

    // ✅ If adding this segment exceeds 60 mins, only take remaining minutes
    if (totalMinutes + diff > 60) {
      const remaining = 60 - totalMinutes;
      if (remaining > 0) {
        formattedBreaks.push(`${start} to ${end} (${remaining} mins)`);
        totalMinutes = 60;
      }
      // ✅ Stop adding further breaks once 60 mins reached
      break;
    } else {
      formattedBreaks.push(`${start} to ${end} (${diff} mins)`);
      totalMinutes += diff;
    }
  }

  // ✅ Always store with total duration at the end
  todayRecord.breakTime =
    formattedBreaks.join(", ") + ` (Total: ${totalMinutes} mins)`;
  todayRecord.status = "Login";
  await todayRecord.save();

  const limitReached = totalMinutes >= 60;

  return res.status(limitReached ? 400 : 200).json({
    message: limitReached
      ? "⚠ Total break time reached 60 minutes. No more breaks allowed."
      : "▶ Break ended successfully",
    totalMinutes,
    limitReached,
    breakTime: todayRecord.breakTime,
  });
}


    // --- ✅ Normal logout update ---
    if (logoutTime) {
      todayRecord.logoutTime = logoutTime;
      todayRecord.status = "Logout";
      todayRecord.breakInProgress = null;
    }

    if (loginReason) todayRecord.loginReason = loginReason;
    if (logoutReason) todayRecord.logoutReason = logoutReason;

    await todayRecord.save();
    res.json({ message: "✅ Attendance updated", attendance: todayRecord });
  } catch (error) {
    console.error("❌ Error updating attendance:", error);
    res.status(500).json({ message: "Server Error" });
  }
});



// ✅ GET: Last 5 records
router.get("/attendance/history/:employeeId", async (req, res) => {
  try {
    const { employeeId } = req.params;
    const history = await Attendance.find({ employeeId })
      .sort({ createdAt: -1 })
      .limit(5);

    res.status(200).json(history);
  } catch (error) {
    console.error("❌ Error fetching history:", error);
    res.status(500).json({ message: "Server Error" });
  }
});

// ✅ GET: Get today's status
router.get("/attendance/status/:employeeId", async (req, res) => {
  try {
    const { employeeId } = req.params;
    const todayDate = formatDateToDDMMYYYY();

    const todayRecord = await Attendance.findOne({ employeeId, date: todayDate });

    if (!todayRecord) return res.json({ status: "None", date: todayDate });

    res.json({
      status: todayRecord.status,
      loginTime: todayRecord.loginTime,
      logoutTime: todayRecord.logoutTime,
      loginReason: todayRecord.loginReason,
      logoutReason: todayRecord.logoutReason,
      breakTime: todayRecord.breakTime,
      breakInProgress: todayRecord.breakInProgress || null, // 👈 NEW
      date: todayRecord.date,
    });
  } catch (error) {
    console.error("❌ Error fetching status:", error);
    res.status(500).json({ message: "Server Error" });
  }
});


module.exports = router;