import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:convert';
import 'sidebar.dart';
import 'user_provider.dart';
// import 'email_page.dart';
import 'message.dart';
import 'audio_call_page.dart';

class EmployeeDirectoryPage extends StatefulWidget {
  const EmployeeDirectoryPage({super.key});

  @override
  EmployeeDirectoryPageState createState() => EmployeeDirectoryPageState();
}

class EmployeeDirectoryPageState extends State<EmployeeDirectoryPage> {
  List<dynamic> employees = [];
  List<dynamic> filteredEmployees = [];
  bool _isLoading = true; // This will now only control the initial load
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchEmployees();
  }

  Future<void> fetchEmployees() async {
    try {
      final response = await http.get(
        Uri.parse("https://finalhrm-proj.onrender.com/api/employees"),
      );

      if (response.statusCode == 200) {
        setState(() {
          employees = jsonDecode(response.body);
          // The grid will handle its own filtering state
          _isLoading = false;
        });
      } else {
        debugPrint("❌ Failed to load employees: ${response.statusCode}");
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("❌ Error fetching employees: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Sidebar(
      title: 'Employee Directory',
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Search Box
            _searchBox('Search by ID, Name, Position, or Domain...'),
            const SizedBox(height: 20),

            // ✅ Loader or Grid
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    ) // Initial load
                  : _EmployeeGrid(
                      allEmployees: employees,
                      searchController: _searchController,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Search Box
  Widget _searchBox(String hint) {
    return SizedBox(
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white70),
          prefixIcon: const Icon(Icons.search, color: Colors.white70),
          filled: true,
          fillColor: const Color(0xFF2D2F41),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

/// A stateful widget to display and filter the employee grid, preventing focus issues.
class _EmployeeGrid extends StatefulWidget {
  final List<dynamic> allEmployees;
  final TextEditingController searchController;

  const _EmployeeGrid({
    required this.allEmployees,
    required this.searchController,
  });

  @override
  State<_EmployeeGrid> createState() => _EmployeeGridState();
}

class _EmployeeGridState extends State<_EmployeeGrid> {
  List<dynamic> _filteredEmployees = [];

  @override
  void initState() {
    super.initState();
    _filteredEmployees = List.from(widget.allEmployees);
    widget.searchController.addListener(_filterEmployees);
  }

  @override
  void didUpdateWidget(covariant _EmployeeGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.allEmployees != oldWidget.allEmployees) {
      _filterEmployees(); // Re-filter if the source list changes
    }
  }

  @override
  void dispose() {
    widget.searchController.removeListener(_filterEmployees);
    super.dispose();
  }

  void _filterEmployees() {
    final query = widget.searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredEmployees = List.from(widget.allEmployees);
      } else {
        _filteredEmployees = widget.allEmployees.where((emp) {
          final name = (emp['employeeName'] ?? '').toLowerCase();
          final id = (emp['employeeId'] ?? '').toLowerCase();
          final position = (emp['position'] ?? '').toLowerCase();
          final domain = (emp['domain'] ?? '').toLowerCase();
          return name.contains(query) ||
              id.contains(query) ||
              position.contains(query) ||
              domain.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_filteredEmployees.isEmpty) {
      return Center(
        child: Text(
          widget.searchController.text.trim().isEmpty
              ? 'No employees available.'
              : 'No results for "${widget.searchController.text.trim()}"',
          style: const TextStyle(color: Colors.white),
        ),
      );
    }

    return GridView.builder(
      itemCount: _filteredEmployees.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.95,
      ),
      itemBuilder: (context, index) {
        final emp = _filteredEmployees[index];
        final imagePath = emp['employeeImage'];
        final imageUrl = (imagePath != null && imagePath.isNotEmpty)
            ? "https://finalhrm-proj.onrender.com$imagePath"
            : "";
        return _employeeCard(
          emp['employeeId'] ?? "",
          emp['employeeName'] ?? "Unknown",
          emp['position'] ?? "Unknown",
          imageUrl,
        );
      },
    );
  }

  Widget _employeeCard(
    String employeeId,
    String name,
    String role,
    String imageUrl,
  ) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 80,
              backgroundColor: Colors.grey[200],
              backgroundImage: imageUrl.isNotEmpty
                  ? NetworkImage(imageUrl)
                  : const AssetImage("assets/profile.png") as ImageProvider,
              onBackgroundImageError: (_, __) {
                debugPrint('Image load error for $imageUrl');
              },
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13.5,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              role,
              style: const TextStyle(fontSize: 15.5, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.email,
                    size: 25,
                    color: Colors.deepPurple.withOpacity(0.5),
                  ),
                  onPressed: null,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.message,
                    size: 25,
                    color: Colors.deepPurple,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MsgPage(employeeId: employeeId),
                      ),
                    );
                  },
                ),
                //Icon(Icons.message, size: 25, color: Colors.deepPurple),
                IconButton(
                  icon: const Icon(
                    Icons.phone,
                    size: 25,
                    color: Colors.deepPurple,
                   ),
                   onPressed: () {
                         // TODO: replace with your logged-in employee id retrieval
                     //  const currentUserId = "EMPID"; // <<--- get from Provider / auth
                     final currentUserId = Provider.of<UserProvider>(context, listen: false).employeeId!;
                       Navigator.push(
                         context,
                         MaterialPageRoute(
                            builder: (context) => AudioCallPage(
                              currentUserId: currentUserId,
                              targetUserId: employeeId,
                              isCaller: true,
                              isVideo: false,
                            ),
                         ),
                       );
                   },
                ),
                IconButton(
      icon: const Icon(
    Icons.video_call,
    size: 25,
    color: Colors.deepPurple,
            ),
              onPressed: () {
                 // TODO: replace with your logged-in employee id retrieval
               //const currentUserId = "EMPID"; // <<--- get from Provider / auth
               final currentUserId = Provider.of<UserProvider>(context, listen: false).employeeId!;
               Navigator.push(
                 context,
                 MaterialPageRoute(
                   builder: (context) => AudioCallPage(
                     currentUserId: currentUserId,
                     targetUserId: employeeId,
                     isCaller: true,
                     isVideo: true,
                   ),
                  ),
                 );
                },
               ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}