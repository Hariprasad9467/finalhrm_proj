import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // ✅ for date formatting
import 'user_provider.dart';
import 'sidebar.dart';
import 'leave_management.dart';

class ApplyLeave extends StatefulWidget {
  final Map<String, dynamic>? existingLeave;

  const ApplyLeave({super.key, this.existingLeave});

  @override
  State<ApplyLeave> createState() => _ApplyLeaveState();
}

class _ApplyLeaveState extends State<ApplyLeave> {
  String? selectedLeaveType;
  DateTime fromDate = DateTime.now();
  DateTime toDate = DateTime.now();
  final TextEditingController reasonController = TextEditingController();
  final TextEditingController fromDateController = TextEditingController();
  final TextEditingController toDateController = TextEditingController();

  List<Map<String, dynamic>> _approvers = [];
  String? _selectedApproverId;
  String? _approverError; // ✅ To hold a specific error message

  final DateFormat dateFormatter = DateFormat(
    'dd-MM-yyyy',
  ); // ✅ dd/MM/yyyy format

  String? employeeName;
  String? position;

  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final employeeId = userProvider.employeeId;
    position = userProvider.position;

    if (employeeId != null) {
      fetchEmployeeName(employeeId);
      _fetchApprovers(employeeId);
    }

    // Pre-fill when editing
    if (widget.existingLeave != null) {
      selectedLeaveType = widget.existingLeave!['leaveType'];
      reasonController.text = widget.existingLeave!['reason'] ?? '';

      // Parse DD-MM-YYYY → DateTime
      String fromStr = widget.existingLeave!['fromDate'];
      String toStr = widget.existingLeave!['toDate'];

      fromDate = DateFormat("dd-MM-yyyy").parse(fromStr);
      toDate = DateFormat("dd-MM-yyyy").parse(toStr);
    }

    // ✅ Update controllers initially
    fromDateController.text = dateFormatter.format(fromDate);
    toDateController.text = dateFormatter.format(toDate);
  }

  Future<void> fetchEmployeeName(String employeeId) async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:5000/get-employee-name/$employeeId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          employeeName = data['employeeName'];
        });
      } else {
        debugPrint('❌ Employee not found');
      }
    } catch (e) {
      debugPrint('❌ Failed to fetch employee name: $e');
    }
  }

  Future<void> _fetchApprovers(String employeeId) async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:5000/apply/approvers/$employeeId'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _approvers = data
              .map(
                (item) => {
                  'employeeId': item['employeeId'],
                  'employeeName': item['employeeName'],
                },
              )
              .toList();
          // If we get exactly one approver (the domain TL), auto-select them.
          if (_approvers.isEmpty) {
            _approverError =
                'No approver found for your domain. Please contact HR.';
          } else if (_approvers.length == 1) {
            _selectedApproverId = _approvers.first['employeeId'];
          } else {
            _approverError = null; // Clear any previous error
          }
        });
      } else {
        setState(() {
          _approverError = 'Failed to load approvers. Please try again.';
        });
      }
    } catch (e) {
      debugPrint('❌ Error fetching approvers: $e');
    }
  }

  Future<void> _selectDate(BuildContext context, bool isFrom) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? fromDate : toDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) {
      setState(() {
        if (isFrom) {
          fromDate = picked;
          fromDateController.text = dateFormatter.format(fromDate);
        } else {
          toDate = picked;
          toDateController.text = dateFormatter.format(toDate);
        }
      });
    }
  }

  void _submitLeave() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final employeeId = userProvider.employeeId;

    if (selectedLeaveType == null ||
        reasonController.text.trim().isEmpty ||
        _selectedApproverId == null ||
        employeeId == null ||
        employeeName == null ||
        position == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // ✅ Date validation
    if (fromDate.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('From Date cannot be earlier than today.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (toDate.isBefore(fromDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('To Date cannot be earlier than From Date.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final leaveData = {
      "employeeId": employeeId,
      "employeeName": employeeName,
      "position": position,
      "leaveType": selectedLeaveType,
      "approverId": _selectedApproverId,
      "fromDate": fromDate.toIso8601String(), // ✅ ISO string
      "toDate": toDate.toIso8601String(), // ✅ ISO string
      "reason": reasonController.text.trim(),
      "status": "Pending",
    };

    final isEditing = widget.existingLeave != null;
    final leaveId = widget.existingLeave?['_id'];
    final url = isEditing
        ? 'http://localhost:5000/apply/update/$employeeId/$leaveId'
        : 'http://localhost:5000/apply/apply-leave';

    final response = await (isEditing
        ? http.put(
            Uri.parse(url),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(leaveData),
          )
        : http.post(
            Uri.parse(url),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(leaveData),
          ));

    if (!mounted) return;

    if (response.statusCode == 200 || response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing
                ? '✅ Leave updated successfully!'
                : '✅ Leave applied successfully!',
          ),
          backgroundColor: Colors.green,
        ),
      );

      await Future.delayed(const Duration(seconds: 1));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LeaveManagement()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: ${response.body}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingLeave != null;

    return Sidebar(
      title: isEditing ? 'Edit Leave' : 'Apply Leave',
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Text(
              isEditing ? 'EDIT LEAVE' : 'APPLY LEAVE',
              style: const TextStyle(
                fontSize: 22,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (employeeName != null) ...[
              const SizedBox(height: 10),
              Text(
                'Welcome, $employeeName',
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
              if (position != null) ...[
                const SizedBox(height: 5),
                Text(
                  'Position: $position',
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                ),
              ],
            ],
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Leave Type',
                        style: TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 5),
                      DropdownButtonFormField<String>(
                        dropdownColor: Colors.white,
                        value: selectedLeaveType,
                        items: ['Sick', 'Casual', 'Sad']
                            .map(
                              (type) => DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => selectedLeaveType = value),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 40),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Approver',
                        style: TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 5),
                      DropdownButtonFormField<String>(
                        value: _selectedApproverId,
                        items: _approvers.map((approver) {
                          return DropdownMenuItem<String>(
                            value: approver['employeeId'],
                            child: Text(approver['employeeName']),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedApproverId = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Select Approver',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                          ),
                        ),
                        isExpanded: true,
                      ),
                      // ✅ Display the approver error message if it exists
                      if (_approverError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            _approverError!,
                            style: TextStyle(
                              color: Colors.yellow[700],
                              fontSize: 14,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('From', style: TextStyle(color: Colors.white)),
                      const SizedBox(height: 5),
                      TextField(
                        readOnly: true,
                        controller: fromDateController,
                        onTap: () => _selectDate(context, true),
                        decoration: InputDecoration(
                          suffixIcon: const Icon(Icons.calendar_today),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 40),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('To', style: TextStyle(color: Colors.white)),
                      const SizedBox(height: 5),
                      TextField(
                        readOnly: true,
                        controller: toDateController,
                        onTap: () => _selectDate(context, false),
                        decoration: InputDecoration(
                          suffixIcon: const Icon(Icons.calendar_today),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Reason for Leave',
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 5),
                TextField(
                  controller: reasonController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 240, 239, 243),
                  ),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  // ✅ Disable button if there's an approver error
                  onPressed: _approverError != null ? null : _submitLeave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 240, 239, 243),
                  ),
                  child: Text(isEditing ? 'Update' : 'Apply'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}