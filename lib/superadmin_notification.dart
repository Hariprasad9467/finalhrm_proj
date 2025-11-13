import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'reports.dart';
import 'sidebar.dart';

class SuperadminNotificationsPage extends StatefulWidget {
  final String empId; // ✅ required employee ID

  const SuperadminNotificationsPage({super.key, required this.empId});

  @override
  State<SuperadminNotificationsPage> createState() =>
      _EmployeeNotificationsPageState();
}

class _EmployeeNotificationsPageState extends State<SuperadminNotificationsPage> {
  final Color darkBlue = const Color(0xFF0F1020);

  late String selectedMonth;
  bool isLoading = false;
  String? error;
  //int? expandedIndex;
  // 🔴 red: use expandedKey instead of expandedIndex
  String? expandedKey;


  final List<String> months = [
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
  List<Map<String, dynamic>> message = [];
  List<Map<String, dynamic>> performance = [];
  //List<Map<String, dynamic>> meetings = [];
  //List<Map<String, dynamic>> events = [];
  List<Map<String, dynamic>> holidays = [];

  @override
  void initState() {
    super.initState();
    selectedMonth = months[DateTime.now().month - 1];
    fetchNotifs();
  }
  /// 🔹 Main function -> call both API
  Future<void> fetchNotifs() async {
    setState(() {
      isLoading = true;
      error = null;
      message.clear();
      performance.clear();
      //meetings.clear();
      //events.clear();
      holidays.clear();
      //expandedIndex = null;
      // 🔴 red: reset expandedKey on refresh
      expandedKey = null;
    });
/*
    final uri = Uri.parse(
      //"http://localhost:5000/notifications/$selectedMonth/${widget.empId}",
      "http://localhost:5000/api/notifications/employee/${widget.empId}",
    );
    */
    try {
      // 🔹 Call both APIs parallel
      await Future.wait([
        fetchSmsNotifications(),
        fetchPerformanceNotifications(),
        // Future-la meetings/events/holiday/s ku separate API add panna easy
      ]);
    } catch (e) {
      setState(() => error = "Server/network error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }


  /// 🔹 Fetch SMS Notifications
  Future<void> fetchSmsNotifications() async {
    final uri = Uri.parse(
        "http://localhost:5000/notifications/employee/${widget.empId}?month=$selectedMonth&category=message");
    final resp = await http.get(uri);

    if (resp.statusCode == 200) {
      final decoded = jsonDecode(resp.body);
      if (decoded is List) {
        setState(() {
          message = decoded.cast<Map<String, dynamic>>();
        });
      }
    } else if (resp.statusCode == 404) {
    // 🔹 No SMS → empty list
    setState(() => message = []);
  } else {
      throw Exception(
          "Failed to load Message notifications. Code: ${resp.statusCode}");
    }
  }


  /// 🔹 Fetch Performance Notifications
  Future<void> fetchPerformanceNotifications() async {
    final uri = Uri.parse(
       // "http://localhost:5000/api/notifications/$selectedMonth/${widget.empId}");
       "http://localhost:5000/notifications/performance/employee/$selectedMonth/${widget.empId}");
    final resp = await http.get(uri);

    if (resp.statusCode == 200) {
      final decoded = jsonDecode(resp.body);
      if (decoded is List) {
        setState(() {
          performance =
                decoded
                    .where(
                      (n) =>
                          (n['category'] as String).toLowerCase() ==
                          'performance',
                    )
                    .cast<Map<String, dynamic>>()
                    .toList();

                    holidays =
                decoded
                    .where(
                      (n) =>
                          (n['category'] as String).toLowerCase() == 'holiday',
                    )
                    .cast<Map<String, dynamic>>()
                    .toList();
          performance = decoded.cast<Map<String, dynamic>>();
        });
      }
    } else if (resp.statusCode == 404) {
    // 🔹 No Performance → empty list
    setState(() => performance = []);
  } else {
      throw Exception(
          "Failed to load Performance notifications. Code: ${resp.statusCode}");
    }
  }
  /// 🔹 Fetch Holiday Notifications
  Future<void> fetchHolidayNotifications() async {
    final uri = Uri.parse(
        "http://localhost:5000/notifications/holiday/employee/${widget.empId}?month=$selectedMonth");
    final resp = await http.get(uri);

    if (resp.statusCode == 200) {
      final decoded = jsonDecode(resp.body);
      if (decoded is List) {
        setState(() {
          holidays = decoded.cast<Map<String, dynamic>>();
        });
      }
    } else if (resp.statusCode == 404) {
      // 🔹 No Holiday → empty list
      setState(() => holidays = []);
    } else {
      throw Exception(
          "Failed to load Holiday notifications. Code: ${resp.statusCode}");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Sidebar(
      title: "Employee Notifications",
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: ListView(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Notifications",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      _dropdownMonth(),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (error != null)
                    Center(
                      child: Text(
                        error!,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    )
                  else ...[
                    notificationCategory("Message", message),
                    notificationCategory("Performance", performance),
                    // notificationCategory("Meetings", meetings),
                    // notificationCategory("Company Events", events),
                    notificationCategory("Holidays", holidays),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdownMonth() {
    return Container(
      width: 150,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedMonth,
          isExpanded: true,
          items:
              months
                  .map(
                    (m) => DropdownMenuItem<String>(value: m, child: Text(m)),
                  )
                  .toList(),
          onChanged: (val) {
            if (val != null && val != selectedMonth) {
              setState(() => selectedMonth = val);
              fetchNotifs();
            }
          },
        ),
      ),
    );
  }

  Widget notificationCategory(String title, List<Map<String, dynamic>> list) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 16, bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 12),
            child: Text(
              "No $title found",
              style: const TextStyle(color: Colors.white70),
            ),
          )
        else
          ...list.asMap().entries.map((entry) {
            final index = entry.key;
            //final message = entry.value['message'] as String;
            //return notificationCard(message, index, title);
            final notif = entry.value; // full notification map
            return notificationCard(notif,index,title.toLowerCase());
          }),
      ],
    );
  }
// 🔴 red: updated notificationCard with expandedKey & sender info
  //Widget notificationCard(String message, int index, String category) {
  Widget notificationCard(Map<String, dynamic> notif, int index,String categoryParam) {
    //final isExpanded = expandedIndex == index;
    final cardKey = "$categoryParam-$index"; // 🔴 unique key per notification
    final isExpanded = expandedKey == cardKey;
    final message = notif['message'] as String;
    
   final category = (notif['category'] as String).toLowerCase();
   
    final senderName = notif['senderName'] ?? 'Unknown'; // 🔴 red: added senderName
    final senderId = notif['senderId'] ?? ''; 
    
if (category.toLowerCase() == "message") {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        elevation: 2,
        child: InkWell(
          onTap:
              //() => setState(() => expandedIndex = isExpanded ? null : index),
              () => setState(() => expandedKey = isExpanded ? null : cardKey),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "From: $senderName ($senderId)",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // 🔹 Second line -> Message
                    Text(
                      message,
                        //message,
                        //"$message\nFrom: $senderName ($senderId)", // 🔴 red: include sender info
                        style: const TextStyle(fontSize: 14),
                        //color: Colors.black87,
                        maxLines: isExpanded ? null : 1,
                        overflow:
                            isExpanded
                                ? TextOverflow.visible
                                : TextOverflow.ellipsis,
                      ),
                      if (isExpanded) const SizedBox(height: 8),
                      if (isExpanded)
                        Text(
                          "Click again to collapse",
                          //"From: $senderName ($senderId)", // 🔴 red: separate sender info
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                    ],
                  ),
                ),
                /*
                // ✅ Only show "View" for SMS in SMS list
                if ((category == "sms" && sms.contains(notif)) ||
                  (category == "performance" && performance.contains(notif)))
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReportsAnalyticsPage(),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text("View"),
                  ),
                  */
/*
                  if(category.toLowerCase() == "performance")
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReportsAnalyticsPage(),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text("View"),
                  ),



*/

              ],
            ),
          ),
        ),
      ),
    );
  }

  //Performance
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        elevation: 2,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap:
              //() => setState(() => expandedIndex = isExpanded ? null : index),
              () => setState(() => expandedKey = isExpanded ? null : cardKey),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message,
                        style: const TextStyle(fontSize: 14),
                        maxLines: isExpanded ? null : 1,
                        overflow:
                            isExpanded
                                ? TextOverflow.visible
                                : TextOverflow.ellipsis,
                      ),
                      if (isExpanded) const SizedBox(height: 8),
                      if (isExpanded)
                        const Text(
                          "Click again to collapse",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                    ],
                  ),
                ),
                if (category.toLowerCase() == "performance")
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (c) => ReportsAnalyticsPage(),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("View"),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  

  Widget _buildHeader() {
    return Container(
      height: 60,
      color: darkBlue,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: const Text(
        "",
        style: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}