// routes/requests.js
const express = require('express');
const router = express.Router();
const ChangeRequest = require('../models/changeRequest');
const Employee = require('../models/profile'); // ✅ fixed import

// --------------------
// Create a change request (employee)
router.post('/profile/:id/request-change', async (req, res) => {
  try {
    const employeeId = req.params.id;
    const { fullName,field, oldValue, newValue, requestedBy } = req.body;

    if (!field || typeof newValue === 'undefined') {
      return res.status(400).json({ message: 'field and newValue required' });
    }
    


    const request = new ChangeRequest({
      employeeId,
      full_name: fullName,   // 👈 add name directly
      field,
      oldValue: oldValue ?? '',
      newValue: newValue.toString(),
      requestedBy: requestedBy ?? employeeId,
    });

    await request.save();
    res.status(201).json({ message: '✅ Request created', request });
  } catch (err) {
    console.error('❌ Failed to create request:', err);
    res.status(500).json({ message: 'Internal Server Error' });
  }
});

// --------------------
// Approve a request (⚡ moved above /:id)
router.post('/:id/approve', async (req, res) => {
  try {
    const requestId = req.params.id.trim();
    console.log("Approve requestId:", requestId);

    const resolver = req.body.resolvedBy || 'superadmin';

    const reqDoc = await ChangeRequest.findById(requestId);
    console.log("Found request:", reqDoc);
    if (!reqDoc) return res.status(404).json({ message: 'Request not found' });
    if (reqDoc.status !== 'pending') {
      return res.status(400).json({ message: 'Request already resolved' });
    }

    // Update employee with requested field
    const updateObj = {};
    updateObj[reqDoc.field] = reqDoc.newValue;

    const updatedEmployee = await Employee.findOneAndUpdate(
      { id: reqDoc.employeeId }, // ✅ fixed to match schema
      { $set: updateObj },
      { new: true }
    );
    console.log("Updated employee:", updatedEmployee);

    if (!updatedEmployee) {
      console.warn(`Employee not found for employeeId=${reqDoc.employeeId}`);
      return res.status(404).json({ message: 'Employee not found' });
    }

    reqDoc.status = 'approved';
    reqDoc.resolvedAt = new Date();
    reqDoc.resolvedBy = resolver;
    await reqDoc.save();

    res.status(200).json({
      message: '✅ Request approved and applied',
      request: reqDoc,
      employee: updatedEmployee,
    });
  } catch (err) {
    console.error('❌ Failed to approve request:', err);
    

    res.status(500).json({ message: 'Internal Server Error' });
  }
});

// --------------------
// Decline a request (⚡ moved above /:id)
router.post('/:id/decline', async (req, res) => {
  try {
    const requestId = req.params.id;
    const resolver = req.body.resolvedBy || 'superadmin';

    const reqDoc = await ChangeRequest.findById(requestId);
    if (!reqDoc) return res.status(404).json({ message: 'Request not found' });
    if (reqDoc.status !== 'pending') {
      return res.status(400).json({ message: 'Request already resolved' });
    }

    reqDoc.status = 'declined';
    reqDoc.resolvedAt = new Date();
    reqDoc.resolvedBy = resolver;
    await reqDoc.save();

    res.status(200).json({ message: '❌ Request declined', request: reqDoc });
  } catch (err) {
    console.error('❌ Failed to decline request:', err);
    res.status(500).json({ message: 'Internal Server Error' });
  }
});
// --------------------
// List all requests
router.get('/', async (req, res) => {
  try {
    const status = req.query.status || 'pending';
    const requests = await ChangeRequest.find(status ? { status } : {})
      .sort({ createdAt: -1 })
      .lean();
    res.status(200).json(requests);
  } catch (err) {
    console.error('❌ Failed to fetch requests:', err);
    res.status(500).json({ message: 'Internal Server Error' });
  }
});
// --------------------
// Get single request (⚡ keep last)
router.get('/:id', async (req, res) => {
  try {
    const reqDoc = await ChangeRequest.findById(req.params.id).lean();
    if (!reqDoc) return res.status(404).json({ message: 'Request not found' });
    res.status(200).json(reqDoc);
  } catch (err) {
    console.error('❌ Failed to fetch request:', err);
    res.status(500).json({ message: 'Internal Server Error' });
  }
});

module.exports = router;