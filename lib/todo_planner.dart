//todo_planner.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import 'sidebar.dart';
import 'user_provider.dart';
import 'dart:ui';

class ToDoPlanner extends StatefulWidget {
  const ToDoPlanner({super.key});

  @override
  State<ToDoPlanner> createState() => _ToDoPlannerState();
}

class _ToDoPlannerState extends State<ToDoPlanner> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<String, dynamic>? _currentTaskData;

  // Map of date → tasks
  final Map<String, List<Map<String, String>>> _tasksByDate = {};

  final statusOptions = ['Yet to start', 'In progress', 'Completed','Hold'];
  final workStatusOptions = ['WFH', 'WFO', 'Casual leave', 'Sick leave', 'Sad leave', 'Holiday'];

  final String baseUrl = 'http://localhost:5000/todo_planner';

  @override
  void initState() {  
    super.initState();
    _fetchAllTasks();
  }

  /// ✅ Fetch ALL tasks for this employee, grouped by date
Future<void> _fetchAllTasks() async {
  try {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final employeeId = userProvider.employeeId ?? '';
    if (employeeId.isEmpty) return;

    final res = await http.get(Uri.parse('$baseUrl/todo/$employeeId'));

    if (res.statusCode == 200 && res.body.isNotEmpty) {
      final data = jsonDecode(res.body);

      // 🔁 Move 'Hold' tasks from previous day to today
      final today = DateTime.now();
      final todayStr = today.toIso8601String().split('T').first;
      final yesterdayStr = today.subtract(const Duration(days: 1)).toIso8601String().split('T').first;

      if (data[yesterdayStr] != null) {
        final yesterdayTasks = List<Map<String, dynamic>>.from(data[yesterdayStr]['tasks']);
        final holdTasks = yesterdayTasks.where((t) => t['status'] == 'Hold').toList();

        if (holdTasks.isNotEmpty) {
          // Avoid duplicate migration
          if (data[todayStr] == null || (data[todayStr]['tasks'] as List).isEmpty) {
            data[todayStr] = {
              'workStatus': data[yesterdayStr]['workStatus'] ?? 'WFO',
              'tasks': [
                {'item': 'SOD Call', 'eta': '', 'status': 'Yet to start'},
                ...holdTasks.map((t) => ({
                      'item': t['item'],
                      'eta': t['eta'],
                      'status': 'Yet to start',
                    })),
              ],
            };
          }
        }
      }

      setState(() {
        _tasksByDate.clear();
        data.forEach((date, taskData) {
          _tasksByDate[date] = (taskData['tasks'] as List)
              .map<Map<String, String>>((e) => {
                    'item': e['item']?.toString() ?? '',
                    'eta': e['eta']?.toString() ?? '',
                    'status': e['status']?.toString() ?? '',
                  })
              .toList();
        });
      });
    }
  } catch (e) {
    print('Fetch all tasks error: $e');
  }
}


  /// ✅ Fetch one day’s task
  Future<void> _fetchTask(String date) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final employeeId = userProvider.employeeId ?? '';

      if (employeeId.isEmpty) return;

      final res = await http.get(Uri.parse('$baseUrl/todo/$employeeId/$date'));

      if (res.statusCode == 200 && res.body.isNotEmpty) {
        final data = jsonDecode(res.body);
        setState(() {
          _currentTaskData = data;
          _tasksByDate[date] = (data['tasks'] as List)
              .map<Map<String, String>>((e) => {
                    'item': e['item']?.toString() ?? '',
                    'eta': e['eta']?.toString() ?? '',
                    'status': e['status']?.toString() ?? '',
                  })
              .toList();
        });
      } else {
        setState(() {
          _currentTaskData = null;
          _tasksByDate.remove(date);
        });
      }
    } catch (e) {
      print('Fetch error: $e');
    }
  }

  /// ✅ Save task
  Future<void> _saveTask(
    String date,
    String workStatus,
    List<Map<String, String>> tasks,
  ) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final employeeId = userProvider.employeeId ?? '';

      if (employeeId.isEmpty) return;

      await http.post(
        Uri.parse('$baseUrl/todo/save'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'employeeId': employeeId,
          'date': date,
          'workStatus': workStatus,
          'tasks': tasks,
        }),
      );

      await _fetchTask(date); // refresh task
      setState(() {
        _selectedDay = DateTime.parse(date);
      });
    } catch (e) {
      print('Save error: $e');
    }
  }

  /// Show add/edit bottom sheet
  void _showAddOrEditDialog(DateTime date, {bool isEdit = false}) {
  String selectedWorkStatus = isEdit && _currentTaskData != null
      ? _currentTaskData!['workStatus']
      : workStatusOptions[0];

  List<Map<String, String>> workItems = [];

  if (isEdit && _currentTaskData != null) {
    workItems = List<Map<String, String>>.from(
      (_currentTaskData!['tasks'] as List).map<Map<String, String>>((e) => {
            'item': e['item'].toString(),
            'eta': e['eta'].toString(),
            'status': e['status'].toString(),
          }),
    );
  } else {
    workItems = [
      {'item': '', 'eta': '', 'status': ''}
    ];
  }

  showModalBottomSheet(
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
    ),
    context: context,
    isScrollControlled: true,
    builder: (context) {
      // <-- Persist these here (outside StatefulBuilder) so they don't reset
      final PageController pageController = PageController();
      int currentIndex = 0;

      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: StatefulBuilder(
          builder: (context, setModalState) {
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  color: Colors.white.withOpacity(0.08),
                  padding: const EdgeInsets.all(20),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 60,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 15),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        Text(
                          '${isEdit ? 'Edit' : 'Add'} Tasks',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 15),

                        // Work Status Dropdown
                        DropdownButtonFormField<String>(
                          value: selectedWorkStatus,
                          dropdownColor: Colors.black.withOpacity(0.9),
                          menuMaxHeight: 250,
                          borderRadius: BorderRadius.circular(15),
                          style: const TextStyle(color: Colors.white),
                          items: workStatusOptions
                              .map((e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  ))
                              .toList(),
                          onChanged: (val) => setModalState(() => selectedWorkStatus = val!),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.05),
                            labelText: 'Work Status',
                            labelStyle: const TextStyle(color: Colors.white70),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Task PageView
                        SizedBox(
                          height: 340,
                          child: PageView.builder(
                            controller: pageController,
                            itemCount: workItems.length,
                            onPageChanged: (i) => setModalState(() => currentIndex = i),
                            itemBuilder: (context, index) {
                              final task = workItems[index];
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.07),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white24, width: 1),
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    Text(
                                      'Task ${index + 1}',
                                      style: const TextStyle(
                                        color: Colors.purpleAccent,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    TextFormField(
                                      initialValue: task['item'],
                                      style: const TextStyle(color: Colors.white),
                                      decoration: InputDecoration(
                                        hintText: 'Enter task description',
                                        hintStyle: const TextStyle(color: Colors.white38),
                                        filled: true,
                                        fillColor: Colors.white.withOpacity(0.05),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(15),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                      onChanged: (val) => workItems[index]['item'] = val,
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            initialValue: task['eta'],
                                            style: const TextStyle(color: Colors.white),
                                            decoration: InputDecoration(
                                              labelText: 'ETA',
                                              labelStyle: const TextStyle(color: Colors.white70),
                                              filled: true,
                                              fillColor: Colors.white.withOpacity(0.05),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(15),
                                                borderSide: BorderSide.none,
                                              ),
                                            ),
                                            onChanged: (val) => workItems[index]['eta'] = val,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: DropdownButtonFormField<String>(
                                                    dropdownColor: Colors.black.withOpacity(0.9),
                                                    menuMaxHeight: 250,
                                                    borderRadius: BorderRadius.circular(15),
                                                    style: const TextStyle(color: Colors.white),

                                            value: task['status']?.isNotEmpty == true ? task['status'] : null,
                                            items: statusOptions
                                                .map((e) => DropdownMenuItem(
                                                      value: e,
                                                      child: Text(e, style: const TextStyle(color: Colors.white)),
                                                    ))
                                                .toList(),
                                            onChanged: (val) => setModalState(() => workItems[index]['status'] = val!),
                                            decoration: InputDecoration(
                                              labelText: 'Status',
                                              labelStyle: const TextStyle(color: Colors.white70),
                                              filled: true,
                                              fillColor: Colors.white.withOpacity(0.05),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(15),
                                                borderSide: BorderSide.none,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 15),

                        // Task Navigation Glowing Dots
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 10,
                          children: List.generate(
                            workItems.length,
                            (i) => GestureDetector(
                              onTap: () {
                                pageController.animateToPage(
                                  i,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                                setModalState(() => currentIndex = i);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: currentIndex == i ? Colors.purpleAccent.withOpacity(0.9) : Colors.white24,
                                  boxShadow: currentIndex == i
                                      ? [
                                          BoxShadow(
                                            color: Colors.purpleAccent.withOpacity(0.7),
                                            blurRadius: 12,
                                            spreadRadius: 3,
                                          ),
                                        ]
                                      : [],
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Floating Add/Delete Buttons (unchanged behavior)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FloatingActionButton.small(
                              heroTag: 'addBtn',
                              backgroundColor: Colors.purpleAccent,
                              onPressed: () {
                                setModalState(() {
                                  workItems.add({'item': '', 'eta': '', 'status': ''});
                                  // ensure page shows new item
                                  currentIndex = workItems.length - 1;
                                  pageController.jumpToPage(currentIndex);
                                });
                              },
                              tooltip: 'Add New Task',
                              child: const Icon(Icons.add, color: Colors.white),
                            ),
                            const SizedBox(width: 20),
                            if (workItems.isNotEmpty)
                              FloatingActionButton.small(
                                heroTag: 'delBtn',
                                backgroundColor: Colors.redAccent,
                                onPressed: () {
                                  setModalState(() {
                                    if (workItems.length > 1) {
                                      workItems.removeAt(currentIndex);
                                      if (currentIndex >= workItems.length) {
                                        currentIndex = workItems.length - 1;
                                      }
                                      pageController.jumpToPage(currentIndex);
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('At least one task is required!'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  });
                                },
                                tooltip: 'Delete Current Task',
                                child: const Icon(Icons.delete, color: Colors.white),
                              ),
                          ],
                        ),
                        const SizedBox(height: 25),

                        // Gradient CTA Button (unchanged)
                        GestureDetector(
                          onTap: () async {
                            if (workItems.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Add at least one task!')),
                              );
                              return;
                            }

                            final validTasks = workItems
                                .where((task) => task['item']!.isNotEmpty || task['eta']!.isNotEmpty || task['status']!.isNotEmpty)
                                .toList();

                            final hasIncomplete = validTasks.any((task) => task['item']!.isEmpty || task['eta']!.isEmpty || task['status']!.isEmpty);

                            if (validTasks.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please add at least one task.'), backgroundColor: Colors.red),
                              );
                            } else if (hasIncomplete) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please complete all fields for each task.'), backgroundColor: Colors.red),
                              );
                            } else {
                              final dateStr = date.toIso8601String().split('T').first;
                              await _saveTask(dateStr, selectedWorkStatus, validTasks);
                              Navigator.pop(context);
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF7A00FF), Color(0xFFE100FF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Center(
                              child: Text(
                                isEdit ? 'Update All Tasks' : 'Add Tasks',
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    },
  );
}




  Widget _buildTaskBox() {
    if (_selectedDay == null || _currentTaskData == null) return const SizedBox();

    final selectedDateStr = _selectedDay!.toIso8601String().split('T').first;
    final todayStr = DateTime.now().toIso8601String().split('T').first;
    bool isTodayOrFuture = selectedDateStr.compareTo(todayStr) >= 0;
    final data = _currentTaskData!;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Work Status: ${data['workStatus']}',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...List<Map<String, dynamic>>.from(data['tasks']).map((task) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                    '• ${task['item']} | ETA: ${task['eta']} | Status: ${task['status']}'),
              )),
          if (isTodayOrFuture)
            Align(
              alignment: Alignment.bottomRight,
              child: TextButton(
                onPressed: () =>
                    _showAddOrEditDialog(_selectedDay!, isEdit: true),
                child: const Text('Edit'),
              ),
            ),
        ],
      ),
    );
  }

  List<Map<String, String>> _getEventsForDay(DateTime day) {
    final dateStr = day.toIso8601String().split('T').first;
    return _tasksByDate[dateStr] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Sidebar(
      title: 'To-Do Planner',
      body: SafeArea(
        child: Column(
          children: [
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2100, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) async {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });

                final selectedDateStr =
                    selectedDay.toIso8601String().split('T').first;
                await _fetchTask(selectedDateStr);

                final todayStr =
                    DateTime.now().toIso8601String().split('T').first;
                if (selectedDateStr.compareTo(todayStr) >= 0 &&
                    _currentTaskData == null) {
                  _showAddOrEditDialog(selectedDay, isEdit: false);
                }
              },
              calendarStyle: const CalendarStyle(
                defaultTextStyle: TextStyle(color: Colors.white),
                weekendTextStyle: TextStyle(color: Colors.white),
                selectedDecoration: BoxDecoration(
                    color: Colors.purple, shape: BoxShape.circle),
                todayDecoration: BoxDecoration(
                    color: Colors.deepPurple, shape: BoxShape.circle),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(color: Colors.white, fontSize: 18),
                leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
                rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
              ),
              eventLoader: _getEventsForDay,
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  if (events.isNotEmpty) {
                    return Positioned(
                      bottom: 1,
                      child: Container(
                        height: 3,
                        width: 20,
                        color: Colors.purpleAccent,
                      ),
                    );
                  }
                  return null;
                },
              ),
              onPageChanged: (focusedDay) => _focusedDay = focusedDay,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(10),
                children: [
                  if (_selectedDay != null && _currentTaskData != null)
                    _buildTaskBox(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}