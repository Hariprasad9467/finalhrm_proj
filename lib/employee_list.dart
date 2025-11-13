import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'sidebar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io'; // for File (mobile)
import 'package:flutter/foundation.dart'; // for kIsWeb

class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  List<Map<String, dynamic>> employees = [];
  List<Map<String, dynamic>> filteredEmployees = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    fetchEmployees();
  }

  /// Fetch employees WITH latest attendance status
  Future<void> fetchEmployees() async {
    try {
      final response = await http.get(
        Uri.parse("http://localhost:5000/api/employees"),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          employees = data.cast<Map<String, dynamic>>();
          filteredEmployees = List.from(employees);
        });
      } else {
        print("Failed to fetch employees: ${response.body}");
      }
    } catch (e) {
      print("Error fetching employees: $e");
    }
  }

  // /// Debounced search to prevent excessive calls
  // void _onSearchChanged() {
  //   if (_debounce?.isActive ?? false) _debounce!.cancel();
  //   _debounce = Timer(const Duration(milliseconds: 300), () {
  //     if (mounted) {
  //       _applySearch();
  //     }
  //   });
  // }

  // /// Apply search filter
  // void _applySearch() {
  //   final query = _searchController.text.trim().toLowerCase();
  //   setState(() {
  //     if (query.isEmpty) {
  //       filteredEmployees = List<Map<String, dynamic>>.from(employees);
  //     } else {
  //       filteredEmployees = employees.where((emp) {
  //         final id = (emp["employeeId"] ?? "").toString().toLowerCase();
  //         final name = (emp["employeeName"] ?? "").toString().toLowerCase();
  //         return id.contains(query) || name.contains(query);
  //       }).toList();
  //     }
  //   });
  // }

  /// Delete employee by ID
  Future<void> _deleteEmployee(String employeeId) async {
    try {
      final response = await http.delete(
        Uri.parse("http://localhost:5000/api/employees/$employeeId"),
      );

      if (response.statusCode == 200) {
        setState(() {
          employees.removeWhere((emp) => emp["employeeId"] == employeeId);
          filteredEmployees.removeWhere(
            (emp) => emp["employeeId"] == employeeId,
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Employee removed successfully")),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("❌ Failed: ${response.body}")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Error: $e")));
    }
  }

  /// Edit employee (with image upload support)
  void _editEmployee(Map<String, dynamic> emp) {
    final idController = TextEditingController(text: emp["employeeId"]);
    final nameController = TextEditingController(text: emp["employeeName"]);
    final positionController = TextEditingController(text: emp["position"]);
    final domainController = TextEditingController(text: emp["domain"]);
    final imageController = TextEditingController(
      text: emp["employeeImage"] ?? "",
    );

    Uint8List? pickedImageBytes; // Web
    File? pickedImageFile; // Mobile

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Edit Employee"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: idController,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: "Employee ID"),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Name"),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: positionController,
                  decoration: const InputDecoration(labelText: "Position"),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: domainController,
                  decoration: const InputDecoration(labelText: "Domain"),
                ),
                const SizedBox(height: 12),

                // Image picker
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: imageController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: "Profile Image (.jpg)",
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () async {
                        if (kIsWeb) {
                          FilePickerResult? result = await FilePicker.platform
                              .pickFiles(
                                type: FileType.custom,
                                allowedExtensions: ['jpg', 'jpeg'],
                                withData: true,
                              );
                          if (result != null &&
                              result.files.single.bytes != null) {
                            setState(() {
                              pickedImageBytes = result.files.single.bytes;
                              imageController.text = result.files.single.name;
                            });
                          }
                        } else {
                          final picked = await _picker.pickImage(
                            source: ImageSource.gallery,
                          );
                          if (picked != null) {
                            final lower = picked.path.toLowerCase();
                            if (lower.endsWith(".jpg") ||
                                lower.endsWith(".jpeg")) {
                              setState(() {
                                pickedImageFile = File(picked.path);
                                imageController.text = picked.name;
                              });
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "⚠ Please select a .jpg image only",
                                  ),
                                ),
                              );
                            }
                          }
                        }
                      },
                      child: const Text("Browse"),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if ((pickedImageBytes != null) ||
                    (pickedImageFile != null) ||
                    (emp["employeeImage"] != null))
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: SizedBox(
                      height: 80,
                      width: 80,
                      child: pickedImageBytes != null
                          ? Image.memory(pickedImageBytes!, fit: BoxFit.cover)
                          : pickedImageFile != null
                          ? Image.file(pickedImageFile!, fit: BoxFit.cover)
                          : Image.network(
                              "http://localhost:5000${emp["employeeImage"]}",
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  var request = http.MultipartRequest(
                    'PUT',
                    Uri.parse(
                      "http://localhost:5000/api/employees/${idController.text}",
                    ),
                  );
                  request.fields['employeeName'] = nameController.text;
                  request.fields['position'] = positionController.text;
                  request.fields['domain'] = domainController.text;

                  if (pickedImageBytes != null) {
                    request.files.add(
                      http.MultipartFile.fromBytes(
                        'employeeImage',
                        pickedImageBytes!,
                        filename: imageController.text,
                      ),
                    );
                  } else if (pickedImageFile != null) {
                    request.files.add(
                      await http.MultipartFile.fromPath(
                        'employeeImage',
                        pickedImageFile!.path,
                      ),
                    );
                  }

                  final streamedResponse = await request.send();
                  final response = await http.Response.fromStream(
                    streamedResponse,
                  );

                  if (response.statusCode == 200) {
                    fetchEmployees();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("✅ Employee updated successfully"),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("❌ Failed: ${response.body}")),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text("❌ Error: $e")));
                }
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  /// Helpers
  String _formatDate(dynamic date) => date == null ? "N/A" : date.toString();

  String _formatTime(dynamic isoDate) {
    if (isoDate == null ||
        isoDate == "Not logged in yet" ||
        isoDate == "Not logged out yet") {
      return isoDate.toString();
    }
    try {
      final dt = DateTime.parse(isoDate);
      return DateFormat("hh:mm a").format(dt);
    } catch (_) {
      return isoDate.toString();
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case "Login":
        return Colors.green;
      case "Logout":
        return Colors.orange;
      case "Break":
        return Colors.blue;
      default:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchController = TextEditingController();
    // final screenWidth = MediaQuery.of(context).size.width;

    return Sidebar(
      title: "Employee List",
      body: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    /// Title + Count + Search
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          const Text(
                            'Employee List',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 12),
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.black87,
                            child: Text(
                              employees.length.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // ✅ Search Bar
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 3,
                        right: 3,
                        bottom: 8,
                      ),
                      child: _SearchField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText:
                              "Search by ID, Name, Position, or Domain...",
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey[200],
                        ),
                      ),
                    ),

                    /// Employee Table
                    Expanded(
                      child: _EmployeeDataTable(
                        allEmployees: employees,
                        searchController: searchController,
                        onEdit: _editEmployee,
                        onDelete: _deleteEmployee,
                        formatDate: _formatDate,
                        formatTime: _formatTime,
                        getStatusColor: _getStatusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends TextField {
  const _SearchField({required super.controller, super.decoration});

  @override
  InputDecoration? get decoration => super.decoration?.copyWith(
    hintText: "Search by ID, Name, Position, or Domain...",
    prefixIcon: const Icon(Icons.search),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    filled: true,
    fillColor: Colors.grey[200],
  );
}

class _EmployeeDataTable extends StatefulWidget {
  final List<Map<String, dynamic>> allEmployees;
  final TextEditingController searchController;
  final void Function(Map<String, dynamic>) onEdit;
  final void Function(String) onDelete;
  final String Function(dynamic) formatDate;
  final String Function(dynamic) formatTime;
  final Color Function(String?) getStatusColor;

  const _EmployeeDataTable({
    required this.allEmployees,
    required this.searchController,
    required this.onEdit,
    required this.onDelete,
    required this.formatDate,
    required this.formatTime,
    required this.getStatusColor,
  });

  @override
  State<_EmployeeDataTable> createState() => _EmployeeDataTableState();
}

class _EmployeeDataTableState extends State<_EmployeeDataTable> {
  List<Map<String, dynamic>> _filteredEmployees = [];

  @override
  void initState() {
    super.initState();
    _filteredEmployees = List.from(widget.allEmployees);
    widget.searchController.addListener(_filterEmployees);
  }

  @override
  void dispose() {
    widget.searchController.removeListener(_filterEmployees);
    super.dispose();
  }

  void _filterEmployees() {
    final query = widget.searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredEmployees = List.from(widget.allEmployees);
      } else {
        _filteredEmployees = widget.allEmployees.where((emp) {
          final name = emp['employeeName']?.toString().toLowerCase() ?? '';
          final id = emp['employeeId']?.toString().toLowerCase() ?? '';
          final position = emp['position']?.toString().toLowerCase() ?? '';
          final domain = emp['domain']?.toString().toLowerCase() ?? '';

          return name.contains(query) ||
              id.contains(query) ||
              position.contains(query) ||
              domain.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (_filteredEmployees.isEmpty) {
      return Center(
        child: Text(
          widget.searchController.text.trim().isEmpty
              ? 'No employees available.'
              : 'No results for "${widget.searchController.text.trim()}"',
          style: const TextStyle(color: Colors.black54),
        ),
      );
    }

    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: screenWidth - 48),
          child: DataTable(
            columnSpacing: 40,
            headingRowHeight: 56,
            dataRowHeight: 56,
            columns: const [
              DataColumn(label: Text("Sl.No")),
              DataColumn(label: Text("Employee ID")),
              DataColumn(label: Text("Name")),
              DataColumn(label: Text("Position")),
              DataColumn(label: Text("Domain")),
              DataColumn(label: Text("Date")),
              DataColumn(label: Text("Status")),
              DataColumn(label: Text("Login")),
              DataColumn(label: Text("Logout")),
              DataColumn(label: Text("Actions")),
            ],
            rows: _filteredEmployees.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final emp = entry.value;
              return DataRow(
                cells: [
                  DataCell(Text(index.toString())),
                  DataCell(Text(emp["employeeId"] ?? "N/A")),
                  DataCell(Text(emp["employeeName"] ?? "N/A")),
                  DataCell(Text(emp["position"] ?? "N/A")),
                  DataCell(Text(emp["domain"] ?? "N/A")),
                  DataCell(Text(widget.formatDate(emp["date"]))),
                  DataCell(
                    Text(
                      emp["status"] ?? "N/A",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: widget.getStatusColor(emp["status"]),
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      emp["loginTime"] != null
                          ? widget.formatTime(emp["loginTime"])
                          : "N/A",
                    ),
                  ),
                  DataCell(
                    Text(
                      emp["logoutTime"] != null
                          ? widget.formatTime(emp["logoutTime"])
                          : "N/A",
                    ),
                  ),
                  DataCell(
                    Row(
                      children: [
                        /// 📅 Leave History
                        IconButton(
                          icon: const Icon(
                            Icons.calendar_month,
                            color: Colors.green,
                          ),
                          onPressed: () async {
                            final empId = emp["employeeId"];
                            final url = Uri.parse(
                              "http://localhost:5000/apply/fetch/$empId",
                            );
                            try {
                              final res = await http.get(url);
                              if (res.statusCode == 200) {
                                final data = jsonDecode(res.body);
                                final List<dynamic> items = data["items"] ?? [];
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(
                                      "Leave History - ${emp["employeeName"]}",
                                    ),
                                    content: items.isEmpty
                                        ? const Text("No leave history found.")
                                        : SizedBox(
                                            width: double.maxFinite,
                                            child: ListView.builder(
                                              shrinkWrap: true,
                                              itemCount: items.length,
                                              itemBuilder: (context, index) {
                                                final leave = items[index];
                                                final leaveType =
                                                    (leave["leaveType"] ??
                                                            "Unknown")
                                                        .toString();
                                                final status =
                                                    (leave["status"] ??
                                                            "Pending")
                                                        .toString();

                                                IconData typeIcon;
                                                switch (leaveType
                                                    .toLowerCase()) {
                                                  case "casual":
                                                    typeIcon =
                                                        Icons.beach_access;
                                                    break;
                                                  case "sick":
                                                    typeIcon =
                                                        Icons.local_hospital;
                                                    break;
                                                  case "sad":
                                                    typeIcon = Icons.mood_bad;
                                                    break;
                                                  default:
                                                    typeIcon = Icons.event_note;
                                                }

                                                Color statusColor;
                                                switch (status.toLowerCase()) {
                                                  case "approved":
                                                    statusColor = Colors.green;
                                                    break;
                                                  case "rejected":
                                                    statusColor = Colors.red;
                                                    break;
                                                  default:
                                                    statusColor = Colors.orange;
                                                }

                                                return Card(
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  margin:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 6,
                                                      ),
                                                  child: ListTile(
                                                    leading: Icon(
                                                      typeIcon,
                                                      color: statusColor,
                                                      size: 25,
                                                    ),
                                                    title: Text(
                                                      "$leaveType ($status)",
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.normal,
                                                        color: statusColor,
                                                      ),
                                                    ),
                                                    subtitle: Text(
                                                      "${leave["fromDate"]} → ${leave["toDate"]}\n"
                                                      "Reason: ${leave["reason"] ?? "N/A"}",
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text("Close"),
                                      ),
                                    ],
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "❌ Failed to fetch leave history",
                                    ),
                                  ),
                                );
                              }
                            } catch (err) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("⚠️ Error: $err")),
                              );
                            }
                          },
                        ),

                        /// ✏️ Edit
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => widget.onEdit(emp),
                        ),

                        /// 🗑 Delete
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => widget.onDelete(emp["employeeId"]),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}