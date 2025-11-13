import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'sidebar.dart';

class PostPerformancePage extends StatefulWidget {
  const PostPerformancePage({super.key});

  @override
  State<PostPerformancePage> createState() => _PostPerformancePageState();
}

class _PostPerformancePageState extends State<PostPerformancePage> {
  final TextEditingController employeeIdController = TextEditingController();
  final TextEditingController employeeNameController = TextEditingController();
  final TextEditingController monthController = TextEditingController();
  final TextEditingController communicationController = TextEditingController();
  final TextEditingController attitudeController = TextEditingController();
  final TextEditingController techKnowledgeController = TextEditingController();
  final TextEditingController businessKnowledgeController = TextEditingController();
  final TextEditingController overallCommentController = TextEditingController();
  final TextEditingController reviewerController = TextEditingController();

  String overallStatus = 'Green';  // ✅ Default overall color status

  Future<void> postPerformance() async {
    var url = Uri.parse('http://localhost:5000/perform/performance/save');

    var body = jsonEncode({
      "employeeId": employeeIdController.text,
      "employeeName": employeeNameController.text,
      "month": monthController.text,
      "overallStatus": overallStatus,  // ✅ Send selected color
      "communication": communicationController.text,
      "attitude": attitudeController.text,
      "technicalKnowledge": techKnowledgeController.text,
      "businessKnowledge": businessKnowledgeController.text,
      "overallComment": overallCommentController.text,
      "reviewer": reviewerController.text,
      
    });

    try {
      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Performance Saved Successfully')),
        );
        clearFields();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: ${response.body}')),
        );
      }
    } catch (e) {
      print('❌ Error posting performance: $e');
    }
  }

  void clearFields() {
    employeeIdController.clear();
    employeeNameController.clear();
    monthController.clear();
    communicationController.clear();
    attitudeController.clear();
    techKnowledgeController.clear();
    businessKnowledgeController.clear();
    overallCommentController.clear();
    reviewerController.clear();
    overallStatus = 'Green';
  }

  @override
  Widget build(BuildContext context) {
    return Sidebar(
      title: 'Post Performance Review (HR)',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(controller: employeeIdController, decoration: const InputDecoration(labelText: 'Employee ID')),
            TextField(controller: employeeNameController, decoration: const InputDecoration(labelText: 'Employee Name')),
            TextField(controller: monthController, decoration: const InputDecoration(labelText: 'Month (eg: June 2025)')),
            TextField(controller: communicationController, decoration: const InputDecoration(labelText: 'Communication')),
            TextField(controller: attitudeController, decoration: const InputDecoration(labelText: 'Attitude')),
            TextField(controller: techKnowledgeController, decoration: const InputDecoration(labelText: 'Technical Knowledge')),
            TextField(controller: businessKnowledgeController, decoration: const InputDecoration(labelText: 'Business Knowledge')),
            TextField(controller: overallCommentController, decoration: const InputDecoration(labelText: 'Overall Comment')),
            TextField(controller: reviewerController, decoration: const InputDecoration(labelText: 'Reviewer')),

            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Overall Status Color (Top Bar)'),
                DropdownButton<String>(
                  value: overallStatus,
                  items: ['Red', 'Yellow', 'Green'].map((color) {
                    return DropdownMenuItem(value: color, child: Text(color));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      overallStatus = value!;
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: postPerformance,
              child: const Text('Save Performance'),
            ),
          ],
        ),
      ),
    );
  }
}