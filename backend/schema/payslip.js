const mongoose = require('mongoose');

const earningsSchema = new mongoose.Schema({
  Basic: { type: String, default: '0' },
  HRA: { type: String, default: '0' },
  Conveyance: { type: String, default: '0' },
  MedicalAllowance: { type: String, default: '0' },
  SpecialAllowance: { type: String, default: '0' },
  Stipend: { type: String, default: '0' },
  GrossTotalSalary: { type: String, default: '0' }
}, { _id: false });

const deductionsSchema = new mongoose.Schema({
  IncomeTax: { type: String, default: '0' },
  PF: { type: String, default: '0' },
  ESIC: { type: String, default: '0' },
  ProfessionalTax: { type: String, default: '0' },
  OtherDeductions: { type: String, default: '0' },
  TotalDeductions: { type: String, default: '0' },
  NetSalary: { type: String, default: '0' }
}, { _id: false });

const monthDataSchema = new mongoose.Schema({
  no_of_workdays: { type: Number, default: 0 },
  earnings: { type: earningsSchema, default: () => ({}) },
  deductions: { type: deductionsSchema, default: () => ({}) }
}, { _id: false });

const yearSchema = new mongoose.Schema({
  year: String,
  months: {
    jan: { type: monthDataSchema, default: () => ({}) },
    feb: { type: monthDataSchema, default: () => ({}) },
    mar: { type: monthDataSchema, default: () => ({}) },
    apr: { type: monthDataSchema, default: () => ({}) },
    may: { type: monthDataSchema, default: () => ({}) },
    jun: { type: monthDataSchema, default: () => ({}) },
    jul: { type: monthDataSchema, default: () => ({}) },
    aug: { type: monthDataSchema, default: () => ({}) },
    sep: { type: monthDataSchema, default: () => ({}) },
    oct: { type: monthDataSchema, default: () => ({}) },
    nov: { type: monthDataSchema, default: () => ({}) },
    dec: { type: monthDataSchema, default: () => ({}) }
  }
}, { _id: false });

const payslipSchema = new mongoose.Schema({
  employee_name: String,
  employee_id: String,
  date_of_joining: String,
  no_of_workdays: String,
  designation: String,
  bank_name: String,
  account_no: String,
  location: String,
  pan: String,
  uan: String,
  esic_no: String,
  lop: { type: String, default: '0.0' },
  data_years: [yearSchema]
}, { timestamps: true });

module.exports = mongoose.model('Payslip', payslipSchema);