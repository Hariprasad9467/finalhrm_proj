const express = require('express');
const router = express.Router();
const Profile = require('../models/profile');

// --- CREATE EMPLOYEE ---
router.post('/', async (req, res) => {
  try {
    const employee = new Profile(req.body);
    await employee.save();
    res.status(201).json({ message: '✅ Employee created successfully', employee });
  } catch (error) {
    console.error('❌ Failed to create employee:', error.message);
    res.status(500).json({ message: 'Internal Server Error' });
  }
});

// --- GET EMPLOYEE BY ID (Flatten profileDocs for Flutter) ---
router.get('/:id', async (req, res) => {
  try {
    const employee = await Profile.findOne({ id: req.params.id }).lean();

    if (!employee) {
      return res.status(404).json({ message: '❌ Employee not found' });
    }

    res.status(200).json(employee);
  } catch (error) {
    console.error('❌ Failed to fetch employee:', error.message);
    res.status(500).json({ message: 'Internal Server Error' });
  }
});


    
// --- GET ALL EMPLOYEES ---
router.get('/', async (req, res) => {
  try {
    const employees = await Profile.find().lean();
    res.status(200).json(employees);
  } catch (error) {
    console.error('❌ Failed to fetch all employees:', error.message);
    res.status(500).json({ message: 'Internal Server Error' });
  }
});

// --- FULL UPDATE EMPLOYEE ---
router.put('/:id', async (req, res) => {
  try {
    const updatedEmployee = await Profile.findOneAndUpdate(
      { id: req.params.id },
      req.body,
      { new: true }
    );

    if (!updatedEmployee) {
      return res.status(404).json({ message: '❌ Employee not found' });
    }

    res.status(200).json({ message: '✅ Employee updated', employee: updatedEmployee });
  } catch (error) {
    console.error('❌ Failed to update employee:', error.message);
    res.status(500).json({ message: 'Internal Server Error' });
  }
});

// --- PATCH SINGLE FIELD ---
router.patch('/:id', async (req, res) => {
  try {
    const updateData = req.body; // { field: value }
    const updatedEmployee = await Profile.findOneAndUpdate(
      { id: req.params.id },
      { $set: updateData },
      { new: true }
    );

    if (!updatedEmployee) {
      return res.status(404).json({ message: '❌ Employee not found' });
    }

    res.status(200).json({ message: '✅ Field updated', employee: updatedEmployee });
  } catch (error) {
    console.error('❌ Failed to patch employee:', error.message);
    res.status(500).json({ message: 'Internal Server Error' });
  }
});

// --- ADD EXPERIENCE ---
router.post('/:id/experience', async (req, res) => {
  try {
    const experience = req.body; // { company_name, role, start_date, end_date, description }
    const updatedEmployee = await Profile.findOneAndUpdate(
      { id: req.params.id },
      { $push: { experiences: experience } },
      { new: true }
    );

    if (!updatedEmployee) {
      return res.status(404).json({ message: '❌ Employee not found' });
    }

    res.status(200).json({ message: '✅ Experience added', employee: updatedEmployee });
  } catch (error) {
    console.error('❌ Failed to add experience:', error.message);
    res.status(500).json({ message: 'Internal Server Error' });
  }
});

// Update experience by expId
router.put('/:employeeId/experience/:expId', async (req, res) => {
  try {
    const { employeeId, expId } = req.params;
    const updatedExp = req.body;

    const employee = await Profile.findOneAndUpdate(
      { id: employeeId, "experiences._id": expId },
      {
        $set: {
          "experiences.$.company_name": updatedExp.company_name,
          "experiences.$.role": updatedExp.role,
          "experiences.$.start_date": updatedExp.start_date,
          "experiences.$.end_date": updatedExp.end_date,
          "experiences.$.description": updatedExp.description,
        },
      },
      { new: true }
    );

    if (!employee) return res.status(404).json({ message: "❌ Experience not found" });
    res.json({ message: "✅ Experience updated", employee });
  } catch (err) {
    console.error("Error updating experience:", err);
    res.status(500).json({ message: err.message });
  }
});

// Delete experience by expId
router.delete('/:employeeId/experience/:expId', async (req, res) => {
  try {
    const { employeeId, expId } = req.params;

    const employee = await Profile.findOneAndUpdate(
      { id: employeeId },
      { $pull: { experiences: { _id: expId } } },
      { new: true }
    );

    if (!employee) return res.status(404).json({ message: "❌ Experience not found" });
    res.json({ message: "✅ Experience deleted", employee });
  } catch (err) {
    console.error("Error deleting experience:", err);
    res.status(500).json({ message: err.message });
  }
});

// --- DELETE EMPLOYEE ---
router.delete('/:id', async (req, res) => {
  try {
    const deletedEmployee = await Profile.findOneAndDelete({ id: req.params.id });

    if (!deletedEmployee) {
      return res.status(404).json({ message: '❌ Employee not found' });
    }

    res.status(200).json({ message: '✅ Employee deleted successfully' });
  } catch (error) {
    console.error('❌ Failed to delete employee:', error.message);
    res.status(500).json({ message: 'Internal Server Error' });
  }
});

module.exports = router;
