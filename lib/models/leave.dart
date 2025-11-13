class Leave {
  final String id;
  final String leaveType;
  final String approver;
  final String fromDate;
  final String toDate;
  final String reason;

  Leave({
    required this.id,
    required this.leaveType,
    required this.approver,
    required this.fromDate,
    required this.toDate,
    required this.reason,
  });

  factory Leave.fromJson(Map<String, dynamic> json) {
    return Leave(
      id: json['_id'],
      leaveType: json['leaveType'],
      approver: json['approver'],
      fromDate: json['fromDate'],
      toDate: json['toDate'],
      reason: json['reason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "leaveType": leaveType,
      "approver": approver,
      "fromDate": fromDate,
      "toDate": toDate,
      "reason": reason,
    };
  }
}
