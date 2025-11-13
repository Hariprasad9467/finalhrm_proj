import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'sidebar.dart';
import 'user_provider.dart';

class LeaveApprovalPage extends StatefulWidget {
  final String userRole;
  const LeaveApprovalPage({super.key, required this.userRole});

  @override
  State<LeaveApprovalPage> createState() => _LeaveApprovalPageState();
}

class _LeaveApprovalPageState extends State<LeaveApprovalPage> {
  final String apiUrl = "http://localhost:5000/apply";

  List<dynamic> leaveRequests = [];
  List<dynamic> filteredLeaves = [];

  String selectedFilter = "All"; // Default filter
  DateTimeRange? customRange;

  DateTime fromDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime toDate = DateTime.now();

  final DateFormat _formatter = DateFormat('yyyy-MM-dd'); // ✅ safe format

  // ✅ Helper for displaying dates from API
  String _formatDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return '';
    try {
      final DateTime parsedDate = DateTime.parse(rawDate).toLocal(); // keep IST
      return DateFormat('dd-MM-yyyy').format(parsedDate);
    } catch (e) {
      return rawDate;
    }
  }

  // ✅ Fetch leaves (employee → own, admin/founder → all)
  Future<void> fetchAllLeaves() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final employeeId = userProvider.employeeId ?? "";

      if (employeeId.isEmpty) {
        print("❌ Employee ID is missing, cannot fetch leaves.");
        return;
      }

      String url = "$apiUrl/leave-approvals/$employeeId";
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          leaveRequests = data["items"];
          filteredLeaves = data["items"];
        });
      }
    } catch (e) {
      print("❌ Error fetching leave requests: $e");
    }
  }

  // ✅ Apply Filter
  Future<void> applyFilter() async {
    try {
      String url = "$apiUrl/filter";

      String? startDate;
      String? endDate;
      final fmt = DateFormat('yyyy-MM-dd');

      if (selectedFilter == "Last 7 Days") {
        final now = DateTime.now();
        final start = now.subtract(const Duration(days: 6));
        startDate = fmt.format(start);
        endDate = fmt.format(now);
      } else if (selectedFilter == "Last 30 Days") {
        final now = DateTime.now();
        final start = now.subtract(const Duration(days: 29));
        startDate = fmt.format(start);
        endDate = fmt.format(now);
      } else if (selectedFilter == "Custom Range" && customRange != null) {
        startDate = fmt.format(customRange!.start);
        endDate = fmt.format(customRange!.end);
      }

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final role = userProvider.position?.toLowerCase() ?? "";
      final employeeId = userProvider.employeeId ?? "";

      // ✅ Map filter → status
      String status;
      if (selectedFilter == "All") {
        status = "All"; // backend will return only Approved & Rejected
      } else if (selectedFilter == "Last 7 Days" ||
          selectedFilter == "Last 30 Days" ||
          selectedFilter == "Custom Range") {
        status = "All"; // still want Approved & Rejected only
      } else {
        status = selectedFilter; // "Approved", "Rejected", etc.
      }

      // employee → filter by id
      if (role != "admin" && role != "founder") {
        if (startDate != null && endDate != null) {
          url +=
              "?employeeId=$employeeId&fromDate=$startDate&toDate=$endDate&status=$status";
        } else {
          url += "?employeeId=$employeeId&status=$status";
        }
      } else {
        // admin/founder → role based
        if (startDate != null && endDate != null) {
          url +=
              "?role=$role&employeeId=$employeeId&fromDate=$startDate&toDate=$endDate&status=$status";
        } else {
          url += "?role=$role&employeeId=$employeeId&status=$status";
        }
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          filteredLeaves = data["items"];
        });
      }
    } catch (e) {
      print("❌ Error applying filter: $e");
    }
  }

  // ✅ Pick Custom Range
  Future<void> _pickDateRange(BuildContext context) async {
    DateTime tempFrom = fromDate;
    DateTime tempTo = toDate;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.all(16),
          content: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Select Custom Date Range",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // From Date
                  TextField(
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: "From Date",
                      suffixIcon: const Icon(Icons.calendar_today),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    controller: TextEditingController(
                      text: _formatter.format(tempFrom),
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: tempFrom,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setModalState(() => tempFrom = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // To Date
                  TextField(
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: "To Date",
                      suffixIcon: const Icon(Icons.calendar_today),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    controller: TextEditingController(
                      text: _formatter.format(tempTo),
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: tempTo,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setModalState(() => tempTo = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 20),

                  // Action Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        fromDate = tempFrom;
                        toDate = tempTo;
                        customRange = DateTimeRange(
                          start: fromDate,
                          end: toDate,
                        );
                        selectedFilter = "Custom Range";
                      });
                      applyFilter();
                    },
                    child: const Text("Apply Filter"),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    fetchAllLeaves();
  }

  @override
  Widget build(BuildContext context) {
    return Sidebar(
      title: "Leave Approval",
      body: Column(
        children: [
          // 🔹 Filter Row
          Padding(
            padding: const EdgeInsets.only(right: 30, top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    final String? value = await showMenu<String>(
                      context: context,
                      position: const RelativeRect.fromLTRB(1000, 80, 20, 0),
                      items: [
                        const PopupMenuItem(value: "All", child: Text("All")),
                        const PopupMenuItem(
                          value: "Last 7 Days",
                          child: Text("Last 7 Days"),
                        ),
                        const PopupMenuItem(
                          value: "Last 30 Days",
                          child: Text("Last 30 Days"),
                        ),
                        const PopupMenuItem(
                          value: "Custom Range",
                          child: Text("Custom Range"),
                        ),
                      ],
                    );

                    if (value != null) {
                      if (value == "Custom Range") {
                        await _pickDateRange(context);
                      } else {
                        setState(() {
                          selectedFilter = value;
                        });
                        applyFilter();
                      }
                    }
                  },
                  icon: const Icon(Icons.filter_list),
                  label: const Text("Filter"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 🔽 Show custom range if selected
          if (selectedFilter == "Custom Range" && customRange != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                "Selected: ${_formatter.format(customRange!.start)} → ${_formatter.format(customRange!.end)}",
                style: const TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.purple,
                ),
              ),
            ),

          // 🔽 Expanded List
          Expanded(
            child: filteredLeaves.isEmpty
                ? const Center(child: Text("No leave requests to show"))
                : ListView.builder(
                    itemCount: filteredLeaves.length,
                    itemBuilder: (context, index) {
                      final leave = filteredLeaves[index];

                      return Card(
                        margin: const EdgeInsets.all(8),
                        child: ListTile(
                          leading: const Icon(
                            Icons.person,
                            color: Colors.purple,
                          ),
                          title: Text(
                            "${leave['employeeName']} - ${leave['leaveType']}",
                          ),
                          subtitle: Text(
                            "From: ${_formatDate(leave['fromDate'])} To: ${_formatDate(leave['toDate'])}\nReason: ${leave['reason']}",
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                ),
                                onPressed: () =>
                                    updateLeaveStatus(leave['_id'], "Approved"),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.cancel,
                                  color: Colors.red,
                                ),
                                onPressed: () =>
                                    updateLeaveStatus(leave['_id'], "Rejected"),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: leave['status'] == "Approved"
                                      ? Colors.green
                                      : leave['status'] == "Rejected"
                                      ? Colors.red
                                      : Colors.orange,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  leave['status'] ?? "Pending",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ✅ Update Leave Status
  Future<void> updateLeaveStatus(String id, String status) async {
    setState(() {
      final index = leaveRequests.indexWhere((leave) => leave['_id'] == id);
      if (index != -1) {
        leaveRequests[index]['status'] = status;
      }
    });

    try {
      final response = await http.put(
        Uri.parse("$apiUrl/status/$id"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"status": status}),
      );

      if (response.statusCode != 200) {
        fetchAllLeaves();
      }
    } catch (e) {
      fetchAllLeaves();
    }
  }
}