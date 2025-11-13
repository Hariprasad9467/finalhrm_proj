import 'package:flutter/material.dart';
import '../models/leave.dart';
import '../services/api_service.dart';

class LeaveFormPage extends StatefulWidget {
  final Leave? leave;
  const LeaveFormPage({super.key, this.leave});

  @override
  _LeaveFormPageState createState() => _LeaveFormPageState();
}

class _LeaveFormPageState extends State<LeaveFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController leaveType;
  late TextEditingController approver;
  late TextEditingController fromDate;
  late TextEditingController toDate;
  late TextEditingController reason;

  @override
  void initState() {
    super.initState();
    leaveType = TextEditingController(text: widget.leave?.leaveType ?? '');
    approver = TextEditingController(text: widget.leave?.approver ?? '');
    fromDate = TextEditingController(text: widget.leave?.fromDate ?? '');
    toDate = TextEditingController(text: widget.leave?.toDate ?? '');
    reason = TextEditingController(text: widget.leave?.reason ?? '');
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final newLeave = Leave(
        id: widget.leave?.id ?? '',
        leaveType: leaveType.text,
        approver: approver.text,
        fromDate: fromDate.text,
        toDate: toDate.text,
        reason: reason.text,
      );

      if (widget.leave == null) {
        await ApiService.applyLeave(newLeave);
      } else {
        await ApiService.updateLeave(widget.leave!.id, newLeave);
      }

      Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    leaveType.dispose();
    approver.dispose();
    fromDate.dispose();
    toDate.dispose();
    reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.leave == null ? 'Apply Leave' : 'Edit Leave')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(controller: leaveType, decoration: InputDecoration(labelText: 'Leave Type'), validator: (v) => v!.isEmpty ? 'Required' : null),
              TextFormField(controller: approver, decoration: InputDecoration(labelText: 'Approver'), validator: (v) => v!.isEmpty ? 'Required' : null),
              TextFormField(controller: fromDate, decoration: InputDecoration(labelText: 'From Date'), validator: (v) => v!.isEmpty ? 'Required' : null),
              TextFormField(controller: toDate, decoration: InputDecoration(labelText: 'To Date'), validator: (v) => v!.isEmpty ? 'Required' : null),
              TextFormField(controller: reason, decoration: InputDecoration(labelText: 'Reason'), validator: (v) => v!.isEmpty ? 'Required' : null),
              SizedBox(height: 20),
              ElevatedButton(onPressed: _submit, child: Text(widget.leave == null ? 'Apply' : 'Update')),
            ],
          ),
        ),
      ),
    );
  }
}
