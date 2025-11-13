import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LeaveList extends StatefulWidget {
  const LeaveList({super.key});

  @override
  State<LeaveList> createState() => _LeaveListState();
}

class _LeaveListState extends State<LeaveList> {
  List<dynamic> leaves = [];
  bool isLoading = true;
  String errorMessage = '';

  Future<void> fetchLeaves() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:5000/api/leave'), // Android emulator
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          leaves = data;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Server Error: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to fetch data: $e';
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchLeaves();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Leave List")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage))
              : ListView.builder(
                  itemCount: leaves.length,
                  itemBuilder: (context, index) {
                    final leave = leaves[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: const Icon(Icons.event_note),
                        title: Text(
                          '${leave['leaveType']} - ${leave['reason']}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('From: ${leave['fromDate']}  To: ${leave['toDate']}'),
                      ),
                    );
                  },
                ),
    );
  }
}
