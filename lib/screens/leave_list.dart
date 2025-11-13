import 'package:flutter/material.dart';
import '../models/leave.dart';
import '../services/api_service.dart';
import 'leave_form.dart';

class LeaveListPage extends StatefulWidget {
  const LeaveListPage({super.key});

  @override
  _LeaveListPageState createState() => _LeaveListPageState();
}

class _LeaveListPageState extends State<LeaveListPage> {
  late Future<List<Leave>> leaves;

  @override
  void initState() {
    super.initState();
    leaves = ApiService.fetchLeaves();
  }

  void _refresh() {
    setState(() {
      leaves = ApiService.fetchLeaves();
    });
  }

  void _delete(String id) async {
    await ApiService.deleteLeave(id);
    _refresh();
  }

  void _edit(Leave leave) async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LeaveFormPage(leave: leave)),
    );
    if (updated != null) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Leave Management')),
      body: FutureBuilder<List<Leave>>(
        future: leaves,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final items = snapshot.data!;
            return ListView.builder(
              itemCount: items.length,
              itemBuilder: (_, i) {
                final leave = items[i];
                return ListTile(
                  title: Text(leave.leaveType),
                  subtitle: Text('${leave.fromDate} - ${leave.toDate}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: Icon(Icons.edit), onPressed: () => _edit(leave)),
                      IconButton(icon: Icon(Icons.delete), onPressed: () => _delete(leave.id)),
                    ],
                  ),
                );
              },
            );
          } else if (snapshot.hasError) {
            return Center(child: Text("Error loading leaves"));
          }
          return Center(child: CircularProgressIndicator());
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final added = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => LeaveFormPage()),
          );
          if (added != null) _refresh();
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
