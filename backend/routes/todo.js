//backend/todo.js

const express = require('express');
const router = express.Router();
const ToDo = require('../models/Todo');


// ✅ Calculate Work Progress for ONE employee
router.get('/todo/progress/:employeeId', async (req, res) => {
  try {
    const { employeeId } = req.params;
    console.log("🔎 Fetching progress for employeeId:", employeeId);

    const todos = await ToDo.find({ employeeId });
    console.log("🔎 Found todos:", todos);

    if (!todos || todos.length === 0) {
      return res.json({ progress: 0 });
    }

    let totalProgress = 0;
    let totalTasks = 0;

    todos.forEach((entry) => {
      entry.tasks.forEach((task) => {
        const status = (task.status || '').toLowerCase().trim();
        const eta = parseInt(task.eta);

        if (status === 'completed') {
          totalProgress += 100;
        } else if (status === 'yet to start') {
          totalProgress += 0;
        } else if (status === 'in progress') {
          totalProgress += !isNaN(eta) ? eta : 50;
        } else if (status === 'hold') {
          totalProgress += 10; // partial progress
        }

        totalTasks++;
      });
    });

    const finalProgress = totalTasks > 0 ? Math.round(totalProgress / totalTasks) : 0;
    res.json({ progress: finalProgress });
  } catch (err) {
    console.error('❌ Progress Calculation Error:', err);
    res.status(500).json({ error: 'Failed to calculate progress' });
  }
});


// ✅ Save or Update Task (NO carry-over here)
router.post('/todo/save', async (req, res) => {
  const { employeeId, date, workStatus, tasks } = req.body;

  try {
    let todo = await ToDo.findOne({ employeeId, date });

    if (todo) {
      // 🔄 Update existing day
      todo.workStatus = workStatus;
      todo.tasks = tasks;
      await todo.save();
    } else {
      // 🆕 Create new entry
      const newTodo = new ToDo({ employeeId, date, workStatus, tasks });
      await newTodo.save();
    }

    res.json({ message: 'Task Saved/Updated Successfully' });
  } catch (err) {
    console.error('❌ Save Error:', err);
    res.status(500).json({ error: 'Save Failed' });
  }
});


// ✅ Fetch ALL tasks for an employee (auto carry-over Hold tasks to login day)
router.get('/todo/:employeeId', async (req, res) => {
  try {
    const { employeeId } = req.params;

    const todos = await ToDo.find({ employeeId }).sort({ date: 1 });
    if (!todos || todos.length === 0) {
      return res.json({});
    }

    const today = new Date();
    const todayStr = today.toISOString().split('T')[0];
    const lastTodo = todos[todos.length - 1];
    const lastDate = new Date(lastTodo.date);

    // ⏭️ If user hasn't logged in for 1+ days → move 'Hold' tasks to today
    const diffDays = Math.floor((today - lastDate) / (1000 * 60 * 60 * 24));
    if (diffDays >= 1) {
      const holdTasks = lastTodo.tasks.filter(t => t.status === 'Hold');
      if (holdTasks.length > 0) {
        let todayTodo = await ToDo.findOne({ employeeId, date: todayStr });

        if (!todayTodo) {
          todayTodo = new ToDo({
            employeeId,
            date: todayStr,
            workStatus: lastTodo.workStatus || 'WFO',
            tasks: [
              { item: 'SOD Call', eta: '', status: 'Yet to start' },
              ...holdTasks.map(t => ({
                item: t.item,
                eta: t.eta,
                status: 'Yet to start',
              })),
            ],
          });
          await todayTodo.save();
        } else {
          // Avoid duplicates
          holdTasks.forEach(t => {
            const exists = todayTodo.tasks.some(nt => nt.item === t.item);
            if (!exists) {
              todayTodo.tasks.push({
                item: t.item,
                eta: t.eta,
                status: 'Yet to start',
              });
            }
          });
          await todayTodo.save();
        }
      }
    }

    // 🧾 Group all tasks by date
    const updatedTodos = await ToDo.find({ employeeId }).sort({ date: 1 });
    const grouped = {};
    updatedTodos.forEach(todo => {
      grouped[todo.date] = {
        workStatus: todo.workStatus,
        tasks: todo.tasks
      };
    });

    res.json(grouped);
  } catch (err) {
    console.error('❌ Fetch all tasks error:', err);
    res.status(500).json({ error: 'Failed to fetch tasks' });
  }
});


// ✅ Get tasks by employee + date
router.get('/todo/:employeeId/:date', async (req, res) => {
  try {
    const { employeeId, date } = req.params;
    const todo = await ToDo.findOne({ employeeId, date });

    if (todo) {
      res.json(todo);
    } else {
      res.status(404).json({ message: 'No tasks found for this employee & date' });
    }
  } catch (err) {
    console.error('❌ Fetch error:', err);
    res.status(500).json({ error: 'Failed to fetch tasks' });
  }
});

module.exports = router;