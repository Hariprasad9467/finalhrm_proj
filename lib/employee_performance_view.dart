import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EmployeePerformanceView extends StatefulWidget {
  final String employeeId;
  const EmployeePerformanceView({super.key, required this.employeeId});

  @override
  _EmployeePerformanceViewState createState() => _EmployeePerformanceViewState();
}

class _EmployeePerformanceViewState extends State<EmployeePerformanceView> {
  List<dynamic> reviews = [];

  @override
  void initState() {
    super.initState();
    fetchReviews();
  }

  Future<void> fetchReviews() async {
    final url = Uri.parse('http://localhost:5000/perform/performance/get-reviews/${widget.employeeId}');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      setState(() {
        reviews = json.decode(response.body);
      });
    } else {
      print('Failed to load performance reviews');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Your Performance Reviews')),
      body: ListView.builder(
        itemCount: reviews.length,
        itemBuilder: (context, index) {
          final review = reviews[index];
          return Card(
            child: ListTile(
              title: Text('Month: ${review['month']} - Flag: ${review['flag']}'),
              subtitle: Text(review['overallComment']),
            ),
          );
        },
      ),
    );
  }
}