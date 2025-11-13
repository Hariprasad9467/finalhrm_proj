const express = require("express");
const router = express.Router();
// const Payslip = require("../models/Payslip");
const Attendance = require("./attendance"); // ✅ importing from your existing file

// 🔥 Update no_of_workdays from Attendance collection
router.put("/update-workdays/:employeeId/:year/:month", async (req, res) => {
  try {
    const { employeeId, year, month } = req.params;

    // 1. Get attendance logs for employee
    const logs = await Attendance.find({ employeeId });

    // 2. Filter by month & year
    const workdays = new Set(
      logs
        .filter(log => {
          if (!log.date || !log.loginTime) return false;
          const [day, m, y] = log.date.split("-"); // dd-MM-yyyy
          return parseInt(m) === parseInt(month) && parseInt(y) === parseInt(year);
        })
        .map(log => log.date)
    ).size;

    // 3. Convert numeric month to key (e.g. 4 → apr)
    const monthKey = new Date(`${year}-${month}-01`)
       .toLocaleString("default", { month: "short" })
      .toLowerCase();

    // 4. Update payslip document
    const payslip = await Payslip.findOneAndUpdate(
      { employee_id: employeeId, "data_years.year": year },
      {
      $set: {[`data_years.$.months.${monthKey}.no_of_workdays`]: workdays},
      },
      { new: true, upsert: true}
    );

    if (!payslip) {
      return res.status(404).json({ message: "Payslip not found" });
    }

    res.json({
      message: "✅ Workdays updated successfully",
      employeeId,
      year,
      month,
      workdays,
    });

  } catch (err) {
    console.error("❌ Error updating workdays:", err);
    res.status(500).json({ message: "Server error" });
  }
});

module.exports = router;