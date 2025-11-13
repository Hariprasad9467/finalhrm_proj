// routes/upload.js
const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const Profile = require('../models/profile');
 
const router = express.Router();
 
// ensure uploads directory exists
const uploadsDir = path.join(__dirname, '..', 'uploads');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}
 
// storage config
const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, uploadsDir),
  filename: (req, file, cb) => cb(null, `${Date.now()}-${file.originalname}`)
});
 
const upload = multer({ storage });
 
// allowed keys inside profileDocs
const ALLOWED_DOC_TYPES = new Set([
  'aadhar','pan','driving_license','voter_id',
  'education_10','education_12','ug','pg','phd',
  'other_certificate','passport','uan'
]);
 
// POST /upload/:id
router.post('/:id', upload.single('file'), async (req, res) => {
  try {
    console.log('📤 Upload called:', { params: req.params, body: req.body, file: !!req.file });
 
    const { id } = req.params;
    const docType = req.body.docType;
 
    if (!req.file) {
      return res.status(400).json({ message: '❌ No file uploaded' });
    }
    if (!docType || !ALLOWED_DOC_TYPES.has(docType)) {
      return res.status(400).json({ message: '❌ Invalid or missing docType' });
    }
 
    const filePath = `/uploads/${req.file.filename}`;
    const update = {};
    update[`profileDocs.${docType}`] = filePath;
 
    const employee = await Profile.findOneAndUpdate(
      { id },
      { $set: update },
      { new: true }
    );
 
    if (!employee) {
      return res.status(404).json({ message: '❌ Employee not found' });
    }
 
    return res.status(200).json({ message: '✅ File uploaded', filePath, employee });
  } catch (error) {
    console.error('❌ Upload error:', error);
    return res.status(500).json({ message: 'Internal Server Error', error: error.message });
  }
});
 
module.exports = router;