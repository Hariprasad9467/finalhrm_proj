require('dotenv').config();
const express = require('express');
const http = require("http");
const mongoose = require('mongoose');
const cors = require('cors');
const path = require("path");
const { Server } = require("socket.io");

// ---------------- MODELS ---------------- //
const Employee = require('./models/employee');
const LeaveBalance = require('./models/leaveBalance');
const Payslip = require('./schema/payslip');

// ---------------- ROUTES ---------------- //
const employeeRoutes = require('./routes/employee');
const leaveRoutes = require('./routes/leave');
const profileRoutes = require('./routes/profile_route');
const todoRoutes = require('./routes/todo');
const attendanceRoutes = require('./routes/attendance');
const performanceRoutes = require('./routes/performance');
const reviewRiver = require('./routes/adminperformance');
const reviewscreen = require('./routes/reviewRoutes');
const reviewDecisionRoutes = require('./routes/performanceDecision');
const notificationRoutes = require('./routes/notifications');
const requestsRoutes = require('./routes/changeRequests');
const uploadRoutes = require('./routes/upload');
const payslipRoutes = require('./routes/payslip');

// -------------------- EXPRESS APP -------------------- //
const app = express();
const MONGO_URI = process.env.MONGO_URI; // MongoDB URI from .env
const PORT = process.env.PORT || 5000;
const server = http.createServer(app);

// -------------------- SOCKET.IO -------------------- //
const io = new Server(server, {
  cors: {
    origin: 
      "https://hrm-zeai.netlify.app",
    methods: ["GET", "POST", "PUT", "DELETE"],
    credentials: true,
  },

  transports: ['websocket', 'polling'],
  pingTimeout: 60000,
  pingInterval: 25000,
});

// Add near top of file
const activeUsers = new Map(); // map employeeId -> socket.id

// ---------------- MIDDLEWARE ---------------- //
app.use((req, res, next) => {
  console.log(`📥 ${req.method} ${req.originalUrl}`);
  next();
});

app.use(
  cors({
    origin: [
      "https://hrm-zeai.netlify.app",
    ],
    methods: ["GET", "POST", "PUT", "DELETE"],
    credentials: true,
  })
);

app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use("/uploads", express.static(path.join(__dirname, "uploads")));

// ---------------- ROUTES ---------------- //
app.use('/api', employeeRoutes);
app.use('/apply', leaveRoutes);
app.use('/profile', profileRoutes);
app.use('/todo_planner', todoRoutes);
app.use('/attendance', attendanceRoutes);
app.use('/perform', performanceRoutes);
app.use('/reviews', reviewRiver);
app.use('/reports', reviewscreen);
app.use('/review-decision', reviewDecisionRoutes);
app.use('/notifications', notificationRoutes);
app.use('/requests', requestsRoutes);
app.use('/upload', uploadRoutes);
app.use('/payslip', payslipRoutes);

// ---------------- PAYSLIP APIs ---------------- //
app.get('/get-payslip-details', async (req, res) => {
  try {
    const { employee_id, year, month } = req.query;
    const payslip = await Payslip.findOne({ employee_id });
    if (!payslip) return res.status(404).json({ message: 'Payslip not found' });

    const yearData = payslip.data_years.find(y => y.year === year);
    if (!yearData) return res.status(404).json({ message: 'Year not found' });

    const monthKey = month.toLowerCase().slice(0, 3);
    const monthData = yearData.months[monthKey];
    if (!monthData) return res.status(404).json({ message: 'Month data not found' });

    res.json({
      employee_name: payslip.employee_name,
      employee_id: payslip.employee_id,
      date_of_joining: payslip.date_of_joining,
      no_of_workdays: payslip.no_of_workdays,
      designation: payslip.designation,
      bank_name: payslip.bank_name,
      account_no: payslip.account_no,
      location: payslip.location,
      pan: payslip.pan,
      uan: payslip.uan,
      esic_no: payslip.esic_no,
      lop: payslip.lop,
      earnings: monthData.earnings,
      deductions: monthData.deductions,
    });
  } catch (error) {
    console.error('❌ Fetch Payslip Error:', error);
    res.status(500).json({ message: '❌ Failed to fetch payslip data', error: error.message });
  }
});

app.post('/get-multiple-payslips', async (req, res) => {
  try {
    const { employee_id, year, months } = req.body;
    if (!employee_id || !year || !Array.isArray(months)) {
      return res.status(400).json({ message: 'Missing or invalid fields' });
    }

    const payslip = await Payslip.findOne({ employee_id });
    if (!payslip) return res.status(404).json({ message: 'Employee not found' });

    const yearData = payslip.data_years.find(y => y.year === year);
    if (!yearData) return res.status(404).json({ message: 'Year not found' });

    const results = {};
    months.forEach(month => {
      const monthKey = month.toLowerCase().slice(0, 3);
      const monthData = yearData.months[monthKey];
      if (monthData) results[monthKey] = monthData;
    });

    res.status(200).json({
      employeeInfo: {
        employee_name: payslip.employee_name,
        employee_id: payslip.employee_id,
        date_of_joining: payslip.date_of_joining,
        no_of_workdays: payslip.no_of_workdays,
        designation: payslip.designation,
        bank_name: payslip.bank_name,
        account_no: payslip.account_no,
        location: payslip.location,
        pan: payslip.pan,
        uan: payslip.uan,
        esic_no: payslip.esic_no,
        lop: payslip.lop,
      },
      months: results,
    });
  } catch (error) {
    console.error('❌ Get Multiple Payslips Error:', error);
    res.status(500).json({ message: '❌ Failed to fetch payslip data', error: error.message });
  }
});

// ---------------- GET EMPLOYEE NAME ---------------- //
app.get('/get-employee-name/:employeeId', async (req, res) => {
  try {
    const employee = await Employee.findOne({ employeeId: req.params.employeeId.trim() });
    if (!employee) return res.status(404).json({ message: 'Employee not found' });

    res.status(200).json({
      employeeName: employee.employeeName,
      position: employee.position,
    });
  } catch (error) {
    console.error('❌ Get Employee Name Error:', error);
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// -------------------- SOCKET.IO (ONE-TO-ONE + GROUP CALLS) -------------------- //
io.on("connection", (socket) => {
  console.log("🟢 User connected:", socket.id);

  // --- Basic Join ---
  socket.on("join", (employeeId) => {
    socket.join(employeeId);
    // 🔴 NEW: Store user mapping for WebRTC signaling
    activeUsers.set(employeeId, socket.id);
    console.log(`👤 ${employeeId} joined personal room`);
  });

  // --- Direct Calls ---
  socket.on("call-user", (data) => {
  const target = data.target;
  const targetSocketId = activeUsers.get(target);
  if (targetSocketId) {
    io.to(targetSocketId).emit("incoming-call", {
      from: data.from,
      signal: data.signal,
    });
  } else {
    // fallback to room (if you previously joined users into a room named by employeeId)
    io.to(target).emit("incoming-call", {
      from: data.from,
      signal: data.signal,
    });
  }
});

  socket.on("answer-call", (data) => {
    io.to(data.to).emit("call-accepted", data.signal);
  });

  socket.on("reject-call", (data) => {
    const { to, from } = data;
    if (to) {
      io.to(to).emit("call-rejected", { from });
      console.log(`📞 Call rejected by ${from}`);
    }
  });

  socket.on("end-call", (data) => {
    const { to, from } = data;
    if (to) {
      io.to(to).emit("call-ended", { from });
      console.log(`❌ Call ended between ${from} and ${to}`);
    }
  });

  // --- ICE Relay ---
socket.on("ice-candidate", (data) => {
  const { to, candidate } = data;
  if (to && candidate) {
    const targetSocketId = activeUsers.get(to);
    if (targetSocketId) {
      io.to(targetSocketId).emit("ice-candidate", { candidate });
    } else {
      io.to(to).emit("ice-candidate", { candidate });
    }
    console.log(`🧊 ICE candidate relayed to ${to}`);
  }
});


  // 🔴 NEW: WebRTC Offer Handler - CRITICAL FOR LAPTOP-TO-LAPTOP
  socket.on("offer", (data) => {
    const { to, from, offer, roomId } = data;
    console.log(`📤 Offer sent: ${from} -> ${to}`);
    
    const targetSocketId = activeUsers.get(to);
    if (targetSocketId) {
      io.to(targetSocketId).emit("offer", {
        from,
        offer,
        roomId
      });
      console.log(`✅ Offer delivered to ${to}`);
    } else {
      console.log(`❌ Cannot send offer, ${to} not found`);
      socket.emit("user-offline", { userId: to });
    }
  });

  // 🔴 NEW: WebRTC Answer Handler - CRITICAL FOR LAPTOP-TO-LAPTOP
  socket.on("answer", (data) => {
    const { to, from, answer, roomId } = data;
    console.log(`📤 Answer sent: ${from} -> ${to}`);
    
    const targetSocketId = activeUsers.get(to);
    if (targetSocketId) {
      io.to(targetSocketId).emit("answer", {
        from,
        answer,
        roomId
      });
      console.log(`✅ Answer delivered to ${to}`);
    } else {
      console.log(`❌ Cannot send answer, ${to} not found`);
    }
  });

  // 🔴 NEW: Call Acceptance Handler (for proper signaling flow)
  socket.on("call-accepted", (data) => {
    const { to, from, roomId } = data;
    console.log(`✅ Call accepted: ${from} -> ${to}`);
    
    const targetSocketId = activeUsers.get(to);
    if (targetSocketId) {
      io.to(targetSocketId).emit("call-accepted", { from, roomId });
    }
  });

  // 🔴 NEW: Improved Call Initiation (better than existing call-user)
  socket.on("initiate-call", (data) => {
    const { to, from, roomId, callerName, isVideo } = data;
    console.log(`📞 Call initiated: ${from} -> ${to}, Room: ${roomId}`);
    
    const targetSocketId = activeUsers.get(to);
    if (targetSocketId) {
      io.to(targetSocketId).emit("incoming-call", {
        from,
        roomId,
        callerName: callerName || from,
        isVideo: isVideo !== false
      });
      console.log(`🔔 Incoming call sent to ${to}`);
    } else {
      console.log(`❌ User ${to} not online`);
      socket.emit("user-offline", { userId: to });
    }
  });

  // --- ROOM HANDLING FOR GROUP CALLS ---
  socket.on("create-room", (data) => {
    const { roomId, creator, target, isVideo } = data;
    socket.join(roomId);
    io.to(target).emit("incoming-call", {
      from: creator,
      signal: { roomId, isVideo },
    });
    console.log(`🏠 Room created: ${roomId} by ${creator}`);
  });

  socket.on("add-participant", (data) => {
    const { roomId, from, target, isVideo } = data;
    io.to(target).emit("incoming-call", {
      from,
      signal: { roomId, isVideo },
    });
    console.log(`👥 ${from} invited ${target} to ${roomId}`);
  });

  socket.on("join-room", (data) => {
    const { roomId, userId } = data;
    socket.join(roomId);
    socket.to(roomId).emit("new-participant", { userId });
    console.log(`👤 ${userId} joined room ${roomId}`);
  });

  socket.on("send-room-signal", (data) => {
    const { roomId, from, signal } = data;
    socket.to(roomId).emit("room-signal", { from, signal });
  });

  socket.on("leave-room", (data) => {
    const { roomId, userId } = data;
    socket.leave(roomId);
    socket.to(roomId).emit("participant-left", { userId });
    console.log(`🚪 ${userId} left room ${roomId}`);
  });

  // --- Disconnect ---
 socket.on("disconnect", () => {
  for (const [userId, socketId] of activeUsers.entries()) {
    if (socketId === socket.id) {
      activeUsers.delete(userId);
      console.log(`🔴 User disconnected: ${userId} (${socket.id})`);
      break;
    }
  }
  console.log(`🔴 Socket disconnected: ${socket.id}`);
});

});
// ---------------- ROOT ROUTE (for testing Render) ---------------- //
app.get('/', (req, res) => {
  res.send('✅ HRM Backend is running successfully!');
});

// ---------------- CONNECT MONGODB & START SERVER ---------------- //
mongoose.connect(MONGO_URI)
  .then(() => {
    console.log('✅ MongoDB connected');
    server.listen(PORT, () => console.log(`🚀 Server running on port ${PORT}`));
  })
  .catch(err => console.error('❌ MongoDB connection error:', err));
