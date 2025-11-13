import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'sidebar.dart';
import 'package:provider/provider.dart';
import 'user_provider.dart'; // 🔹 import your provider


class MsgPage extends StatefulWidget {
  final String employeeId;
  

  const MsgPage({super.key, required this.employeeId,});

  @override
  State<MsgPage> createState() => _MsgPageState();
}

class _MsgPageState extends State<MsgPage> {
  Map<String, dynamic>? employeeData;
  final TextEditingController _msgController = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    fetchEmployeeDetails();
  }

  Future<void> fetchEmployeeDetails() async {
    try {
      final response = await http.get(
        Uri.parse("http://localhost:5000/api/employees/${widget.employeeId}"),
      );

      if (response.statusCode == 200) {
        setState(() {
          employeeData = json.decode(response.body);
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
        debugPrint("❌ Failed to load employee: ${response.statusCode}");
      }
    } catch (e) {
      setState(() => _loading = false);
      debugPrint("❌ Error fetching employee: $e");
    }
  }
/*
  void sendMessage() {
    if (_msgController.text.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Message sent to ${employeeData?['employeeName']}"),
          backgroundColor: Colors.deepPurple,
        ),
      );
      _msgController.clear();
    }
  }
*/

// 🔴 sendMessage function updated to POST notification
  Future<void> sendMessage() async {
    // 🔹 Fetch sender info from UserProvider
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final senderId = userProvider.employeeId;
    final senderName = userProvider.employeeName;
    if (_msgController.text.isNotEmpty && employeeData != null && senderId != null &&
        senderName != null) {
      try {
        // 🔴 current month get pannurathu
        String month = [
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
          "December"
        ][DateTime.now().month - 1];

        // 🔴 API ku POST panna
        final response = await http.post(
          Uri.parse("http://localhost:5000/notifications"),
          headers: {"Content-Type": "application/json"},
          body: json.encode({
            "month": month,
            "category": "message", // 🔴 temporary fixed category
            "message": _msgController.text,
            "empId": widget.employeeId, // 🔴 target employee ID
            "senderName":senderName,   // 🔹 sender Name  // 👈 extra field
            "senderId": senderId,       // 🔹 sender ID (logged-in user)                 // 👈 extra field
            //  "senderRole": employeeData?['position'],       // 👈 extra field
          }),
        );

        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text("Message sent to ${employeeData?['employeeName']}"),
              backgroundColor: Colors.green,
            ),
          );
          _msgController.clear();
        } else {
          debugPrint("❌ Failed to send message: ${response.body}");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Failed to send message"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        debugPrint("❌ Error sending message: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error sending message"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Sidebar(
      title: "Send Message",
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // ✅ Employee photo
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: (employeeData?['employeeImage'] != null &&
                            employeeData!['employeeImage'].isNotEmpty)
                        ? NetworkImage(
                            "http://localhost:5000${employeeData!['employeeImage']}")
                        : const AssetImage("assets/profile.png")
                            as ImageProvider,
                  ),
                  const SizedBox(height: 12),

                  // ✅ Employee name + position
                  Text(
                    employeeData?['employeeName'] ?? "Unknown",
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  Text(
                    employeeData?['position'] ?? "",
                    style: const TextStyle(
                        fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 25),

                  // ✅ Message box
                  TextField(
                    controller: _msgController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: "Type your message...",
                      filled: true,
                      fillColor: Colors.deepPurple.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ✅ Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: sendMessage,
                        icon: const Icon(Icons.send),
                        label: const Text("Send"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context); // ✅ back to previous page
                        },
                        //=> _msgController.clear(),
                        icon: const Icon(Icons.cancel),
                        label: const Text("Cancel"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[400],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}