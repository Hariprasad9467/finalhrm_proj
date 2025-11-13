//admin_dashboard.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'user_provider.dart';
import 'sidebar.dart';
import 'apply_leave.dart';
import 'todo_planner.dart';
import 'emp_payroll.dart';
import 'company_events.dart';
import 'admin_notification.dart';
import 'attendance_login.dart';
import 'event_banner_slider.dart';
import 'leave_approval.dart';
import 'adminperformance.dart'; // ✅ for Performance Review
import 'package:intl/intl.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String? employeeName;
  bool _isLoading = true;
  String? _error;

  int casualUsed = 0;
  int casualTotal = 0;
  int sickUsed = 0;
  int sickTotal = 0;
  int sadUsed = 0;
  int sadTotal = 0;

  int _pendingCount = 0; // ✅ new state for pending requests

  @override
  void initState() {
    super.initState();
    fetchEmployeeName();
    _refreshPendingCount(); // ✅ fetch badge count on load
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchLeaveBalance(); // refresh balances when dashboard is revisited
  }

  // ✅ Helper to get employeeId and refresh count
  void _refreshPendingCount() {
    final employeeId = Provider.of<UserProvider>(
      context,
      listen: false,
    ).employeeId;
    if (employeeId != null) fetchPendingCount("tl", employeeId);
  }

  Future<void> fetchEmployeeName() async {
    final employeeId = Provider.of<UserProvider>(
      context,
      listen: false,
    ).employeeId;

    if (employeeId == null) return;

    try {
      final response = await http.get(
        Uri.parse("http://localhost:5000/get-employee-name/$employeeId"),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          employeeName = data['employeeName'];
        });
      } else {
        print('❌ Failed to fetch name: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching employee name: $e');
    }
  }

  /// 🔹 Fetch leave balances
  Future<void> _fetchLeaveBalance() async {
    try {
      final employeeId = Provider.of<UserProvider>(
        context,
        listen: false,
      ).employeeId?.trim();

      if (employeeId == null || employeeId.isEmpty) {
        setState(() {
          _error = "Employee ID not found";
          _isLoading = false;
        });
        return;
      }

      final year = DateTime.now().year;
      final url =
          "http://localhost:5000/apply/leave-balance/$employeeId?year=$year";
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          casualUsed = (data["balances"]["casual"]["used"] ?? 0) as int;
          casualTotal = (data["balances"]["casual"]["total"] ?? 12) as int;

          sickUsed = (data["balances"]["sick"]["used"] ?? 0) as int;
          sickTotal = (data["balances"]["sick"]["total"] ?? 12) as int;

          sadUsed = (data["balances"]["sad"]["used"] ?? 0) as int;
          sadTotal = (data["balances"]["sad"]["total"] ?? 12) as int;

          _error = null;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = "Failed to load balances (HTTP ${response.statusCode})";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// ✅ Fetch pending leave requests count for admin
  Future<void> fetchPendingCount(String userRole, String employeeId) async {
    try {
      final response = await http.get(
        Uri.parse(
          // Pass both role and ID to the backend
          "http://localhost:5000/apply/pending-count?approver=$userRole&approverId=$employeeId",
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _pendingCount = data['pendingCount'] ?? 0;
        });
      } else {
        print("❌ Failed to fetch pending count: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error fetching pending count: $e");
    }
  }

  /// Delete employee comment
  Future<void> _deleteEmployeeComment(String id) async {
    try {
      final response = await http.delete(
        Uri.parse("http://localhost:5000/review-decision/$id"),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("🗑️ Comment deleted successfully")),
        );
        Navigator.of(context).pop(); // close current dialog
        await _showEmployeeComments(); // refresh dialog
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Failed to delete (${response.statusCode})"),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Error: $e")));
    }
  }

  Future<void> _showEmployeeComments() async {
    try {
      final response = await http.get(
        Uri.parse(
          "http://localhost:5000/review-decision/feedback?positions=employee,intern",
        ),
        headers: {"Accept": "application/json"},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text(
              "Employee Feedback",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: data.isEmpty
                  ? const Text("No employee feedback available yet.")
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: data.length,
                      itemBuilder: (context, index) {
                        final item = data[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            leading: Icon(
                              item["decision"] == "agree"
                                  ? Icons.thumb_up
                                  : Icons.thumb_down,
                              color: item["decision"] == "agree"
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            title: Text(
                              item["employeeName"] ?? "Unknown",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item["position"] ?? ""),
                                const SizedBox(height: 4),
                                Text(
                                  item["comment"] ?? "",
                                  style: const TextStyle(
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Submitted: ${_formatDate(item["createdAt"])}",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            isThreeLine: true,
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: "Delete Comment",
                              onPressed: () async {
                                await _deleteEmployeeComment(item["_id"]);
                              },
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
          SnackBar(
            content: Text(
              "❌ Failed to load employee feedback (HTTP ${response.statusCode})",
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Error: $e")));
    }
  }

  /*// ✅ Helper: format date nicely
  String _formatDate(dynamic iso) {
    if (iso == null) return 'N/A';
    try {
      final dt = DateTime.tryParse(iso.toString());
      if (dt == null) return iso.toString();
      return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} "
          "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return iso.toString();
    }
  }*/
  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return '';
    try {
      final parsed = DateTime.tryParse(dateStr.toString());
      if (parsed == null) return dateStr.toString();
      return DateFormat('yyyy-MM-dd hh:mm a').format(parsed.toLocal());
    } catch (e) {
      return dateStr.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Text(
            _error!,
            style: const TextStyle(color: Colors.red, fontSize: 16),
          ),
        ),
      );
    }

    return Sidebar(
      title: 'TLDashboard',
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Welcome, ${employeeName ?? '...'}!',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildQuickActions(context),
            const SizedBox(height: 40),
            _buildCardLayout(context),
            const SizedBox(height: 40),
            const EventBannerSlider(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Center(
      child: Wrap(
        spacing: 90,
        runSpacing: 20,
        alignment: WrapAlignment.center,
        children: [
          _quickActionButton('Apply Leave', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ApplyLeave()),
            );
          }),
          _quickActionButton('Download Payslip', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EmpPayroll()),
            );
          }),
          _quickActionButton('Mark Attendance', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AttendanceLoginPage()),
            );
          }),
          _quickActionButton('Notifications Preview', () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AdminNotificationsPage(
                  empId:
                      Provider.of<UserProvider>(
                        context,
                        listen: false,
                      ).employeeId ??
                      '',
                ),
              ),
            );
          }),
          _quickActionButton('Performance Review', () {
            final userProvider = Provider.of<UserProvider>(
              context,
              listen: false,
            );
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PerformanceReviewPage(
                  currentUserId: userProvider.employeeId!,
                ),
              ),
            );
          }),
          _quickActionButton('Employee Feedback', _showEmployeeComments),
          _quickActionButton('Company Events', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CompanyEventsScreen()),
            );
          }),

          // ✅ Leave Approval button with badge (fixed)
          SizedBox(
            width: 160, // same width as other buttons
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _quickActionButton('Leave Approval', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        // Fetch count again when navigating
                        return const LeaveApprovalPage(userRole: "tl");
                      },
                    ),
                  ).then((_) {
                    // refresh badge after returning
                    _refreshPendingCount();
                  });
                }),
                if (_pendingCount > 0)
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        "$_pendingCount",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickActionButton(String title, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromARGB(255, 214, 226, 231),
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 3,
      ),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    );
  }

  Widget _buildCardLayout(BuildContext context) {
    final currentDate = DateTime.now();
    final formattedDate =
        '${currentDate.day}/${currentDate.month}/${currentDate.year}';
    final currentTime = TimeOfDay.now().format(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 60,
          runSpacing: 20,
          children: [
            _AdminDashboardTile(
              icon: Icons.lightbulb,
              title: currentTime,
              subtitle: 'Today: $formattedDate',
              buttonLabel: 'To Do List',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ToDoPlanner()),
                );
              },
            ),
            _leaveCardTile(
              icon: Icons.beach_access,
              title: 'Casual Leave',
              subtitle:
                  'Used: $casualUsed/$casualTotal\nRemaining: ${casualTotal - casualUsed}',
              buttonLabel: 'View',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ApplyLeave()),
                );
              },
            ),
            _leaveCardTile(
              icon: Icons.local_hospital,
              title: 'Sick Leave',
              subtitle:
                  'Used: $sickUsed/$sickTotal\nRemaining: ${sickTotal - sickUsed}',
              buttonLabel: 'View',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ApplyLeave()),
                );
              },
            ),
            _leaveCardTile(
              icon: Icons.mood_bad,
              title: 'Sad Leave',
              subtitle:
                  'Used: $sadUsed/$sadTotal\nRemaining: ${sadTotal - sadUsed}',
              buttonLabel: 'View',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ApplyLeave()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _AdminDashboardTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonLabel,
    VoidCallback? onTap,
  }) {
    return Container(
      width: 200,
      height: 250,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purpleAccent.withOpacity(0.6),
            blurRadius: 18,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 36, color: Colors.deepPurple),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(buttonLabel),
          ),
        ],
      ),
    );
  }

  Widget _leaveCardTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonLabel,
    VoidCallback? onTap,
  }) {
    return _AdminDashboardTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      buttonLabel: buttonLabel,
      onTap: onTap,
    );
  }
}