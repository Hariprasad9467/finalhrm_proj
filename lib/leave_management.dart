import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'user_provider.dart';
import 'apply_leave.dart';
import 'leave_history_cancelled.dart';
import 'sidebar.dart';

class LeaveManagement extends StatefulWidget {
  const LeaveManagement({super.key});

  @override
  State<LeaveManagement> createState() => _LeaveManagementState();
}

class _LeaveManagementState extends State<LeaveManagement> {
  late Future<List<Map<String, dynamic>>> _leavesFuture;
  String? employeeId;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      setState(() {
        employeeId = userProvider.employeeId;
        _leavesFuture = fetchLeaves();
      });
    });
  }

  Future<List<Map<String, dynamic>>> fetchLeaves() async {
  if (employeeId == null) {
    throw Exception("Employee ID not found");
  }

  final String fetchUrl = 'http://localhost:5000/apply/fetch/$employeeId';
  print("👉 Fetching leaves from: $fetchUrl");

  final response = await http.get(Uri.parse(fetchUrl));

  if (response.statusCode == 200) {
    final decoded = json.decode(response.body);

    // ✅ If backend wraps response in { items: [...] }
    final List<dynamic> data =
        decoded is List ? decoded : (decoded['items'] ?? []);

    final leaves = data.cast<Map<String, dynamic>>();

    // ✅ Filter out cancelled
    return leaves
        .where((leave) => leave['status']?.toLowerCase() != 'cancelled')
        .toList();
  } else {
    throw Exception('Failed to load leave data');
  }
}


  Future<void> _cancelLeave(String leaveId) async {
    if (employeeId == null) return;

    final String deleteUrl =
        'http://localhost:5000/apply/delete/$employeeId/$leaveId';
    print('🔗 Deleting leave via: $deleteUrl');

    final response = await http.delete(Uri.parse(deleteUrl));
    print('🧾 Response status: ${response.statusCode}');
    print('📦 Response body: ${response.body}');

    if (response.statusCode == 200 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Leave cancelled successfully')),
      );
      setState(() {
        _leavesFuture = fetchLeaves();
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel leave: ${response.body}')),
        );
      }
    }
  }

  void _confirmCancel(BuildContext context, String leaveId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Cancellation'),
        content: const Text('Are you sure you want to cancel this leave?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _cancelLeave(leaveId);
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return '';
    try {
      final DateTime parsedDate = DateTime.parse(rawDate);
      // ✅ Correct format: yyyy/MM/dd
      return DateFormat('yyyy/MM/dd').format(parsedDate);
    } catch (e) {
      return rawDate;
    }
  }

  // ✅ Status color mapping
  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Sidebar(
      title: 'Leave Management',
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: employeeId == null
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Row(
                    children: [
                      const Text(
                        'Leave Status',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LeaveHistoryCancelled(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.history),
                        label: const Text('Cancelled History'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: _leavesFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        } else if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return const Center(
                            child: Text('No leave history found.'),
                          );
                        } else {
                          return _buildLeaveTable(snapshot.data!);
                        }
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildLeaveTable(List<Map<String, dynamic>> leaves) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.white),
          dataRowColor: WidgetStateProperty.all(Colors.white),
          columns: const [
            DataColumn(
              label: Text('Leave Type', style: TextStyle(color: Colors.black)),
            ),
            DataColumn(
              label: Text('From Date', style: TextStyle(color: Colors.black)),
            ),
            DataColumn(
              label: Text('To Date', style: TextStyle(color: Colors.black)),
            ),
            DataColumn(
              label: Text('Reason', style: TextStyle(color: Colors.black)),
            ),
            DataColumn(
              label: Text('Status', style: TextStyle(color: Colors.black)),
            ),
            DataColumn(
              label: Text('Actions', style: TextStyle(color: Colors.black)),
            ),
          ],
          rows: leaves.map((leave) {
            final id = leave['_id']?.toString() ?? '';
            final status = leave['status'] ?? 'Pending';

            // ✅ Disable actions if approved/rejected
            final isActionable =
                status.toLowerCase() != 'approved' &&
                status.toLowerCase() != 'rejected';

            return DataRow(
              cells: [
                DataCell(
                  Text(
                    leave['leaveType'] ?? '',
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
                DataCell(
                  Text(
                    _formatDate(leave['fromDate']),
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
                DataCell(
                  Text(
                    _formatDate(leave['toDate']),
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
                DataCell(
                  Text(
                    leave['reason'] ?? '',
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
                DataCell(
                  // ✅ Colored status text
                  Text(
                    status,
                    style: TextStyle(
                      color: _getStatusColor(status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DataCell(
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.edit,
                          color: isActionable
                              ? Colors.blue
                              : Colors.blue.withOpacity(0.5),
                        ),
                        onPressed: isActionable
                            ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ApplyLeave(existingLeave: leave),
                                  ),
                                );
                              }
                            : null,
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete,
                          color: isActionable
                              ? Colors.red
                              : Colors.red.withOpacity(0.5),
                        ),
                        onPressed: isActionable
                            ? () => _confirmCancel(context, id)
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
