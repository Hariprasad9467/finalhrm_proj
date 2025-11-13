
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'sidebar.dart';

class Performance extends StatefulWidget {
  const Performance({super.key});

  @override
  State<Performance> createState() => _PerformanceState();
}

class _PerformanceState extends State<Performance> {
  List<dynamic> performanceData = [];
  bool isLoading = true;
  String errorMsg = '';

  @override
  void initState() {
    super.initState();
    fetchPerformanceData();
  }

  Future<void> fetchPerformanceData() async {
    var url = Uri.parse('http://localhost:5000/perform/performance/all');

    try {
      var response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          performanceData = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          errorMsg = '❌ Error fetching data: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMsg = '❌ Network error: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Sidebar(
      title: 'HR Performance Reviews',
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMsg.isNotEmpty
              ? Center(child: Text(errorMsg))
              : ListView.builder(
                  itemCount: performanceData.length,
                  itemBuilder: (context, index) {
                    return buildPerformanceCard(performanceData[index]);
                  },
                ),
    );
  }

  Widget buildPerformanceCard(Map<String, dynamic> data) {
    Color topColor;

    switch (data['overallStatus'].toString().toLowerCase()) {
      case 'red':
        topColor = Colors.red;
        break;
      case 'yellow':
        topColor = Colors.amber;
        break;
      case 'green':
        topColor = Colors.green;
        break;
      default:
        topColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.grey.shade300, blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 20,
            decoration: BoxDecoration(
              color: topColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${data['employeeName']} - ${data['month']}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Divider(),

                buildSection('Communication', data['communication']),
                buildSection('Attitude', data['attitude']),
                buildSection('Technical Knowledge', data['technicalKnowledge']),
                buildSection('Business Knowledge', data['businessKnowledge']),

                const SizedBox(height: 10),
                Text('Overall Comment:\n${data['overallComment']}', style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 6),
                Text('Reviewed by: ${data['reviewer']}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(content),
        ],
      ),
    );
  }
}