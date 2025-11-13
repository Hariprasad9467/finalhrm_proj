const mongoose = require('mongoose');

// --- Experience Schema ---
const experienceSchema = new mongoose.Schema({
  company_name: { type: String, required: true },
  role: { type: String, required: true },
  start_date: { type: String, required: true },
  end_date: { type: String, required: true },
  description: { type: String },
}, 
// { _id: false }
);

// --- Employee Schema ---
const employeeSchema = new mongoose.Schema({
  id: { type: String, required: true, unique: true },
  full_name: { type: String },
  date_of_appointment: { type: String },
  annual_ctc:{type:String},
  monthly_ctc:{type:String},
  monthly_gross:{type:String},
  department: { type: String },
  designation: { type: String },
  work_email_id: { type: String },
  uan_number: { type: String },
  aadhar_number: { type: String },
  pan_number: { type: String },
  voter_id: { type: String },
  driving_license: { type: String },
  passport_number: { type: String },
  blood_group: { type: String },
  current_address: { type: String },
  permanent_address: { type: String },
  dob: { type: String },
  father_or_husband_name: { type: String },
  gender: { type: String },
  marital_status: { type: String },
  mobile_number: { type: String },
  alternative_mobile: { type: String },
  email_id: { type: String },
  bank_name: { type: String },
  ifsc_code: { type: String },
  bank_account_number: { type: String },
  bank_account_type: { type: String },
  experiences: [experienceSchema],
  profileDocs: {
    aadhar: { type: String },
    pan: { type: String },
    driving_license: { type: String },
    voter_id: { type: String },
    education_10: { type: String },
    education_12: { type: String },
    ug: { type: String },
    pg: { type: String },
    phd: { type: String },
    other_certificate: { type: String },
    passport: { type: String },
    uan: { type: String },
  }




}, { timestamps: true });

// --- Model Export ---
//const Profile = mongoose.model('Profile', employeeSchema);
//module.exports = Profile;
// --- Model Export ---
const Profile = mongoose.models.Profile || mongoose.model('Profile', employeeSchema);
module.exports = Profile;


// --- OPTIONAL: Run this file directly to test adding experience ---
// if (require.main === module) {
//   const MONGO_URI = 'mongodb://localhost:27017/Dashboard_Db';

//   mongoose.connect(MONGO_URI)
//     .then(() => {
//       console.log('✅ MongoDB connected');
//       return addExperience();
//     })
//     .catch(err => console.error('❌ MongoDB connection error:', err));

//   async function addExperience() {
//    // const employeeId = 'EMP001';  // Update this with a valid ID in your DB

//     const newExperience = {
//       company_name: 'FutureTech Innovations',
//       role: 'Lead Engineer',
//       start_date: '2023-01-01',
//       end_date: '2025-06-30',
//       description: 'Managed cross-functional tech teams and infrastructure.'
//     };

//     try {
//       const updatedProfile = await Profile.findOneAndUpdate(
//         { id: employeeId },
//         { $push: { experiences: newExperience } },
//         { new: true }
//       );

//       if (!updatedProfile) {
//         console.log('❌ Employee not found with id:', employeeId);
//       } else {
//         console.log('✅ Experience added successfully.');
//         console.log('📄 Updated Profile:', JSON.stringify(updatedProfile, null, 2));
//       }
//     } catch (err) {
//       console.error('❌ Error updating experience:', err);
//     } finally {
//       mongoose.disconnect();
//     }
//   }
// }