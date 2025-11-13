import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'sidebar.dart';
import 'user_provider.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:intl/intl.dart';

// ---------------- Model ----------------
class PerformanceReview {
  final String id;
  final String reviewedBy;
  final String reviewMonth;
  final String flag;
  String status; // ✅ mutable

  PerformanceReview({
    required this.id,
    required this.reviewedBy,
    required this.reviewMonth,
    required this.flag,
    required this.status,
  });

  factory PerformanceReview.fromJson(Map<String, dynamic> json) {
    return PerformanceReview(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      reviewedBy: json['reviewedBy']?.toString() ?? 'Unknown',
      reviewMonth:
          json['reviewMonth'] != null
              ? _monthName(
                int.tryParse(json['reviewMonth'].toString()) ??
                    DateTime.now().month,
              )
              : _monthName(DateTime.now().month),
      flag: json['flag']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Pending',
    );
  }

  static String _monthName(int month) {
    const months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];
    return months[month - 1];
  }
}

// ---------------- Reports Page ----------------
class ReportsAnalyticsPage extends StatefulWidget {
  const ReportsAnalyticsPage({super.key});

  @override
  State<ReportsAnalyticsPage> createState() => _ReportsAnalyticsPageState();
}

class _ReportsAnalyticsPageState extends State<ReportsAnalyticsPage> {
  final String apiBase = 'http://localhost:5000';
  final String listPath = '/reports';
  final String detailsPath = '/reports';

  List<PerformanceReview> _reviews = [];
  bool _loadingList = true;
   //bool _dataFetched = false;

  int workProgress = 0;
  int leaveUsed = 0;
  String leavePercent = '0';
  String presentPercent = '100';

  @override
  void initState() {
    super.initState();
    fetchPerformanceReviews();
    fetchWorkProgress();
    fetchLeaveStatus();
  }

  // ✅ Fetch performance list
  Future<void> fetchPerformanceReviews([String? empId]) async {
    setState(() => _loadingList = true);
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final employeeId = empId ?? userProvider.employeeId;

      if (employeeId == null || employeeId.isEmpty) {
        _showSnack("No employee logged in");
        setState(() => _loadingList = false);
        return;
      }

      final uri = Uri.parse('$apiBase$listPath/employee/$employeeId');
      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body.trim());
        setState(() {
          _reviews =
              data.map((item) => PerformanceReview.fromJson(item)).toList();
          _loadingList = false;
        });
      } else {
        setState(() {
          _reviews = [];
          _loadingList = false;
        });
      }
    } catch (e) {
      _loadingList = false;
      _showSnack('Error loading list: $e');
    } finally {
      if (mounted) setState(() {});
    }
  }

  // ✅ Fetch review details by ID
  Future<Map<String, dynamic>?> fetchReviewDetails(String id) async {
    try {
      final uri = Uri.parse('$apiBase$detailsPath/$id');
      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body.trim());
      }
    } catch (e) {
      _showSnack('Error fetching details: $e');
    }
    return null;
  }
// ✅ Send decision helper
Future<void> _sendDecision({
  required String decision,
  required String comment,
  required Map<String, dynamic> reviewData,
  required PerformanceReview review,
}) async {
  final userProvider = Provider.of<UserProvider>(context, listen: false);

  final body = json.encode({
    "employeeId": userProvider.employeeId,
    "employeeName": userProvider.employeeName,   // ✅ logged-in user name
    "position": (userProvider.position ?? "employee").toString().trim().toLowerCase(),// ✅ use login role
    "decision": decision,
    "comment": comment,
    "sendTo": ["hr"], 
    "reviewId": review.id,
  });

  await http.post(
    Uri.parse('$apiBase/review-decision'),
    headers: {"Content-Type": "application/json"},
    body: body,
  );
}

  // ✅ Show review details with Agree & Disagree
  Future<void> _showReviewDetails(PerformanceReview review) async {
    final isFinal = review.status == "Agreed" || review.status == "Disagreed";
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final reviewData = await fetchReviewDetails(review.id);
    if (mounted) Navigator.pop(context);

    if (reviewData != null && mounted) {
      final reviewedAt = reviewData['reviewedAt'] ?? reviewData['createdAt'];
      final flagColor = _getFlagTextColor(review.flag);

      await showDialog(
        context: context,
        builder:
            (_) => Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 8,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: flagColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Performance Review Details",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _detailRow(
                          "Employee ID",
                          reviewData['empId'],
                          textColor: Colors.black,
                        ),
                        _detailRow(
                          "Employee Name",
                          reviewData['empName'],
                          textColor: Colors.black,
                        ),
                        _detailRow(
                          "Communication",
                          reviewData['communication'],
                          textColor: Colors.black,
                        ),
                        _detailRow(
                          "Attitude",
                          reviewData['attitude'],
                          textColor: Colors.black,
                        ),
                        _detailRow(
                          "Technical Knowledge",
                          reviewData['technicalKnowledge'],
                          textColor: Colors.black,
                        ),
                        _detailRow(
                          "Business",
                          reviewData['business'],
                          textColor: Colors.black,
                        ),
                        _detailRow("Flag", review.flag, textColor: flagColor),
                        _detailRow(
                          "Reviewed At",
                          _formatDate(reviewedAt),
                          textColor: Colors.black,
                        ),
                        const SizedBox(height: 16),
                        if (!isFinal)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // ✅ Agree
                              TextButton(
                                onPressed: () async {
                                  final comment = await _askComment(
                                    "Reason for Agree (Optional)",
                                  );
                                  if (comment == null) return;

                                  await _sendDecision(
                                    decision: "agree",
                                    comment: comment,
                                    reviewData: reviewData,
                                    review: review,
                                  );

                                  await fetchPerformanceReviews(); // ✅ refresh from backend
                                  if (mounted) Navigator.pop(context);
                                },
                                child: const Text(
                                  "Agree",
                                  style: TextStyle(color: Colors.green),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // ❌ Disagree
                              TextButton(
                                onPressed: () async {
                                  final comment = await _askComment(
                                    "Reason for Disagree (Optional)",
                                  );
                                  if (comment == null) return;

                                  await _sendDecision(
                                    decision: "disagree",
                                    comment: comment,
                                    reviewData: reviewData,
                                    review: review,
                                  );

                                  await fetchPerformanceReviews(); // ✅ refresh
                                  if (mounted) Navigator.pop(context);
                                },
                                child: const Text(
                                  "Disagree",
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      );
    }
  }

  // ✅ Comment popup
  Future<String?> _askComment(String title) async {
    TextEditingController controller = TextEditingController();
    return await showDialog<String>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(title),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: "Enter comment (optional)",
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, controller.text.trim()),
                child: const Text("Submit"),
              ),
            ],
          ),
    );
  }

  // ---------------- Fetch stats ----------------
  // ---------------- Fetch stats ----------------
Future<void> fetchWorkProgress() async {
  final userProvider = Provider.of<UserProvider>(context, listen: false);
  final employeeId = userProvider.employeeId ?? '';
  if (employeeId.isEmpty) return;

  var url = Uri.parse('$apiBase/todo_planner/todo/progress/$employeeId');
  try {
    var response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        workProgress = data['progress'] ?? 0;
      });
    }
  } catch (e) {
    print('Error fetching work progress: $e');
  }
}

Future<void> fetchLeaveStatus() async {
  final userProvider = Provider.of<UserProvider>(context, listen: false);
  final employeeId = userProvider.employeeId ?? '';
  if (employeeId.isEmpty) return;

  var url = Uri.parse('$apiBase/apply/leave-balance/$employeeId'); // updated
  try {
    var response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final balances = data['balances'] ?? {};
      int casualUsed = balances['casual']?['used'] ?? 0;
      int sickUsed = balances['sick']?['used'] ?? 0;
      int sadUsed = balances['sad']?['used'] ?? 0;

      int totalUsed = casualUsed + sickUsed + sadUsed;
      int totalAllowed = 12 * 3; // assuming each type has 12 allowance

      setState(() {
        leaveUsed = totalUsed;
        leavePercent = ((totalUsed / totalAllowed) * 100).toStringAsFixed(1);
        presentPercent = (100 - (totalUsed / totalAllowed * 100)).toStringAsFixed(1);
      });
    }
  } catch (e) {
    print('Error fetching leave stats: $e');
  }
}


  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Sidebar(
      title: 'Reports & Analytics',
      body: SingleChildScrollView(
        child: Column(
          children: [
            _sectionTitle('Reports & Analytics'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                reportCard(
                  'Overall Attendance',
                  '$presentPercent%',
                  'Leave - $leavePercent%\nPresent - $presentPercent%',
                ),
                reportCard(
                  'Overall Leave',
                  '$leavePercent%',
                  'Used - $leaveUsed days\nOut of 36',
                ),
                reportCard(
                  'Overall Work Progress',
                  '$workProgress%',
                  'Working - $workProgress%\nPending - ${100 - workProgress}%',
                ),
              ],
            ),
            const SizedBox(height: 24),
            _sectionTitle('Latest Performance Review'),
            const SizedBox(height: 8),
            _loadingList
                ? const Center(child: CircularProgressIndicator())
                : _buildDataTable(),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade900,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }

  Widget reportCard(String title, String percentText, String details) {
    double percent = double.tryParse(percentText.replaceAll('%', '')) ?? 0;
    Color color =
        percent >= 80
            ? Colors.green
            : percent >= 50
            ? Colors.orange
            : Colors.red;

    return Column(
      children: [
        CircularPercentIndicator(
          radius: 55.0,
          lineWidth: 10.0,
          percent: (percent / 100).clamp(0.0, 1.0),
          center: Text(
            percentText,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          progressColor: color,
          backgroundColor: Colors.grey.shade300,
          animation: true,
          animationDuration: 800,
        ),
        const SizedBox(height: 6),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
        const SizedBox(height: 4),
        Text(
          details,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white60, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildDataTable() {
    if (_reviews.isEmpty) {
      return const Center(
        child: Text(
          "No reviews available",
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    final latestReview = _reviews.first;

    return SizedBox(
      height: 120,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: DataTable(
          headingRowColor: WidgetStateColor.resolveWith(
            (_) => Colors.blueGrey.shade700,
          ),
          columns: const [
            DataColumn(
              label: Text('Reviewed by', style: TextStyle(color: Colors.white)),
            ),
            DataColumn(
              label: Text(
                'Month of review',
                style: TextStyle(color: Colors.white),
              ),
            ),
            DataColumn(
              label: Text('Flag', style: TextStyle(color: Colors.white)),
            ),
            DataColumn(
              label: Text('More', style: TextStyle(color: Colors.white)),
            ),
            DataColumn(
              label: Text('Status', style: TextStyle(color: Colors.white)),
            ),
          ],
          rows: [
            DataRow(
              cells: [
                DataCell(
                  Text(
                    latestReview.reviewedBy,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
                DataCell(
                  Text(
                    latestReview.reviewMonth,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
                DataCell(
                  Text(
                    latestReview.flag,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getFlagTextColor(latestReview.flag),
                    ),
                  ),
                ),
                DataCell(
                  GestureDetector(
                    onTap: () async {
                      await _showReviewDetails(latestReview);
                    },
                    child: const Text(
                      'View',
                      style: TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    latestReview.status,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Flag text color
  Color _getFlagTextColor(String flag) {
    final normalized = flag.toLowerCase().replaceAll(" flag", "").trim();
    switch (normalized) {
      case "red":
        return Colors.red;
      case "yellow":
        return Colors.yellow;
      case "green":
        return Colors.green;
      default:
        return Colors.white70;
    }
  }

  Widget _detailRow(
    String label,
    dynamic value, {
    Color textColor = Colors.white70,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        "$label: ${value ?? 'N/A'}",
        style: TextStyle(color: textColor),
      ),
    );
  }

 String _formatDate(dynamic iso) {
  if (iso == null) return 'N/A';
  try {
    final dt = DateTime.parse(iso.toString()).toLocal();
    return DateFormat('yyyy-MM-dd hh:mm a').format(dt); // 2025-10-03 12:09 PM
  } catch (_) {
    return iso.toString();
  }
}

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}