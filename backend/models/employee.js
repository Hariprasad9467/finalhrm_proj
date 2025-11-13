const mongoose = require("mongoose");

// --- Experience Schema ---
const experienceSchema = new mongoose.Schema({
  company_name: { type: String, required: true },
  role: { type: String, required: true },
  start_date: { type: String, required: true },
  end_date: { type: String, required: true },
  description: { type: String },
}, { _id: false });

// --- Employee Schema ---
const employeeSchema = new mongoose.Schema({
  employeeId: { type: String, required: true, unique: true, trim: true }, // unified from both schemas
  employeeName: { type: String, required: true, trim: true }, // from addemployee
  position: { type: String, required: true, trim: true },    // from addemployee
  domain: { type: String, required: true, trim: true },      // from addemployee
  employeeImage: { type: String, default: null },            // from addemployee

  // // 🔹 Additional details from original employee.js
  // full_name: { type: String },
  // date_of_appointment: { type: String },
  // department: { type: String },
  // designation: { type: String },
  // work_email_id: { type: String },
  // uan_number: { type: String },
  // aadhar_number: { type: String },
  // pan_number: { type: String },
  // voter_id: { type: String },
  // driving_license: { type: String },
  // passport_number: { type: String },
  // blood_group: { type: String },
  // current_address: { type: String },
  // permanent_address: { type: String },
  // dob: { type: String },
  // father_or_husband_name: { type: String },
  // gender: { type: String },
  // marital_status: { type: String },
  // mobile_number: { type: String },
  // alternative_mobile: { type: String },
  // email_id: { type: String },
  // bank_name: { type: String },
  // ifsc_code: { type: String },
  // bank_account_number: { type: String },
  // bank_account_type: { type: String },

  // experiences: [experienceSchema],
}, { timestamps: true });

// --- Model Export ---
const Employee = mongoose.models.Employee || mongoose.model("Employee", employeeSchema, "employees");
module.exports = Employee;
