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
//import 'notification.dart';
import 'employeenotification.dart';
import 'attendance_login.dart';
import 'event_banner_slider.dart';

class EmployeeDashboard extends StatefulWidget {
  const EmployeeDashboard({super.key});

  @override
  State<EmployeeDashboard> createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> {
  String? employeeName;
  bool _isLoading = true;
  String? _error;

  int casualUsed = 0;
  int casualTotal = 0;
  int sickUsed = 0;
  int sickTotal = 0;
  int sadUsed = 0;
  int sadTotal = 0;

  @override
  void initState() {
    super.initState();
    fetchEmployeeName();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchLeaveBalance(); // refresh when dashboard is revisited
  }

  /// 🔹 Fetch employee name from backend
  Future<void> fetchEmployeeName() async {
    final employeeId = Provider.of<UserProvider>(context, listen: false).employeeId;
    if (employeeId == null) return;

    try {
      final response = await http.get(
        Uri.parse('http://localhost:5000/get-employee-name/$employeeId'),
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
      final employeeId = Provider.of<UserProvider>(context, listen: false).employeeId?.trim();
      if (employeeId == null || employeeId.isEmpty) {
        setState(() {
          _error = "Employee ID not found";
          _isLoading = false;
        });
        return;
      }

      final year = DateTime.now().year;
      final url = "http://localhost:5000/apply/leave-balance/$employeeId?year=$year";
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

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context);

    return Sidebar(
      title: 'Dashboard',
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Welcome, ${employeeName ?? user.employeeName ?? '...'}!',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            if (user.position != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "Position: ${user.position}",
                  style: const TextStyle(fontSize: 18, color: Colors.white70),
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
            Navigator.push(context, MaterialPageRoute(builder: (_) => ApplyLeave()))
                .then((_) => _fetchLeaveBalance());
          }),
          _quickActionButton('Download Payslip', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const EmpPayroll()));
          }),
          _quickActionButton('Mark Attendance', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceLoginPage()));
          }),
          _quickActionButton('Notifications Preview', () {
            final empId =
                Provider.of<UserProvider>(context, listen: false).employeeId;
            if (empId != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EmployeeNotificationsPage(empId: empId),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Employee ID not found.')),
              );
            }
          }),
          _quickActionButton('Company Events', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const CompanyEventsScreen()));
          }),
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
    final formattedDate = '${currentDate.day}/${currentDate.month}/${currentDate.year}';
    final currentTime = TimeOfDay.now().format(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 60,
          runSpacing: 20,
          children: [
            _dashboardTile(
              icon: Icons.lightbulb,
              title: currentTime,
              subtitle: 'Today: $formattedDate',
              buttonLabel: 'To Do List',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ToDoPlanner()));
              },
            ),
            _leaveCardTile(
              icon: Icons.beach_access,
              title: 'Casual Leave',
              subtitle: _isLoading
                  ? 'Loading...'
                  : _error != null
                      ? 'Error'
                      : 'Used: $casualUsed/$casualTotal\nRemaining: ${casualTotal - casualUsed}',
              buttonLabel: 'View',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => ApplyLeave()))
                    .then((_) => _fetchLeaveBalance());
              },
            ),
            _leaveCardTile(
              icon: Icons.local_hospital,
              title: 'Sick Leave',
              subtitle: _isLoading
                  ? 'Loading...'
                  : _error != null
                      ? 'Error'
                      : 'Used: $sickUsed/$sickTotal\nRemaining: ${sickTotal - sickUsed}',
              buttonLabel: 'View',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => ApplyLeave()))
                    .then((_) => _fetchLeaveBalance());
              },
            ),
            _leaveCardTile(
              icon: Icons.mood_bad,
              title: 'Sad Leave',
              subtitle: _isLoading
                  ? 'Loading...'
                  : _error != null
                      ? 'Error'
                      : 'Used: $sadUsed/$sadTotal\nRemaining: ${sadTotal - sadUsed}',
              buttonLabel: 'View',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => ApplyLeave()))
                    .then((_) => _fetchLeaveBalance());
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _dashboardTile({
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
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
    return _dashboardTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      buttonLabel: buttonLabel,
      onTap: onTap,
    );
  }
}
