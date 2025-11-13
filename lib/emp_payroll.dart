import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import 'payslip.dart';
import 'sidebar.dart';
import 'user_provider.dart';

class EmpPayroll extends StatefulWidget {
  const EmpPayroll({super.key});

  @override
  State<EmpPayroll> createState() => _EmpPayrollState();
}

class _EmpPayrollState extends State<EmpPayroll> {
  String? selectedYear;
  List<bool> checkedList = List<bool>.filled(12, false);
  @override
  void initState() {
    super.initState();

    // ✅ Default selected year = current year
    selectedYear = DateTime.now().year.toString();
  }

  bool _areAllAllowedMonthsChecked() {
    int currentYear = DateTime.now().year;
    int currentMonth = DateTime.now().month;
    int selected = int.parse(selectedYear!);

    for (int i = 0; i < checkedList.length; i++) {
      bool isDisabled = false;

      if (selected > currentYear) {
        isDisabled = true;
      } else if (selected == currentYear && i + 1 >= currentMonth) {
        isDisabled = true;
      }

      if (!isDisabled && !checkedList[i]) {
        return false; // Found a valid month not checked
      }
    }
    return true; // ✅ all valid months are checked
  }

//   int getDaysInMonth(int year, int month) {
//   final beginningNextMonth =
//       (month < 12) ? DateTime(year, month + 1, 1) : DateTime(year + 1, 1, 1);
//   return beginningNextMonth.subtract(const Duration(days: 1)).day;
// }

  static const List<String> months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const List<String> monthKeys = [
    'jan',
    'feb',
    'mar',
    'apr',
    'may',
    'jun',
    'jul',
    'aug',
    'sep',
    'oct',
    'nov',
    'dec',
  ];
Future<int> fetchWorkingDays(String employeeId, int month, int year) async {
  try {
    final response = await http.get(
      Uri.parse("http://localhost:5000/attendance/attendance/history/$employeeId"),
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);

      // ✅ Count only valid login days for the given month/year
      final workdays = data.where((item) {
        if (item['date'] != null &&
            item['loginTime'] != null &&
            item['loginTime'].toString().isNotEmpty) {
          final dateParts = item['date'].split('-'); // dd-MM-yyyy
          int m = int.parse(dateParts[1]);
          int y = int.parse(dateParts[2]);
          return m == month && y == year;
        }
        return false;
      }).length;

      return workdays;
    } else {
      print("❌ Attendance fetch failed: ${response.statusCode}");
      return 0;
    }
  } catch (e) {
    print("❌ Attendance error: $e");
    return 0;
  }
}

  Future<void> _downloadAllCheckedPayslips() async {
    final employeeId =
        Provider.of<UserProvider>(context, listen: false).employeeId;

    if (employeeId == null ||
        selectedYear == null ||
        !checkedList.contains(true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select year and at least one month')),
      );
      return;
    }

    final selectedMonths = <String>[];
    for (int i = 0; i < checkedList.length; i++) {
      if (checkedList[i]) {
        selectedMonths.add(monthKeys[i]);
      }
    }

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/get-multiple-payslips'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'year': selectedYear,
          'months': selectedMonths,
          'employee_id': employeeId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final employee = Map<String, dynamic>.from(data['employeeInfo']);
        final pdf = pw.Document();

        final imageLogo = pw.MemoryImage(
          (await rootBundle.load('assets/logo_zeai.png')).buffer.asUint8List(),
        );

        for (final monthKey in selectedMonths) {
          final monthIndex = monthKeys.indexOf(monthKey);
          final monthName = months[monthIndex];

        // ✅ Fetch attendance-based working days
        int attendanceWorkdays = await fetchWorkingDays(
          employeeId,
          monthIndex + 1,
          int.parse(selectedYear!),
        );
          final earnings = Map<String, dynamic>.from(
              data['months'][monthKey]['earnings']);
          final deductions = Map<String, dynamic>.from(
              data['months'][monthKey]['deductions']);

          pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(20),
      build: (pw.Context context) {
        return pw.Container(
          height: PdfPageFormat.a4.availableHeight,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              // ================= Top & Middle Content =================
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Company Header
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Image(imageLogo, height: 50),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text("ZeAI Soft",
                              style: pw.TextStyle(
                                  fontSize: 16, fontWeight: pw.FontWeight.bold)),
                          pw.Text(
                              "3rd Floor,SKCL Tech Square,Lazer St,South Phase",
                              style: pw.TextStyle(fontSize: 12)),
                          pw.Text(
                              "SIDCO Industrial Estate,Guindy,Chennai,Tamil Nadu 600032",
                              style: pw.TextStyle(fontSize: 12)),
                          pw.Text("info@zeaisoft.com | +91 97876 36374",
                              style: pw.TextStyle(fontSize: 12)),
                        ],
                      )
                    ],
                  ),
                  pw.Divider(thickness: 1),
                  pw.SizedBox(height: 5),

                  // Payslip Title
                  pw.Center(
                    child: pw.Text(
                      'Payslip for $monthName $selectedYear',
                      style: pw.TextStyle(
                          fontSize: 20, fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.SizedBox(height: 10),

                  // Employee Details
                  pw.Text('Employee Details',
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 16)),
                  pw.SizedBox(height: 10),
                  pw.Table(
                    border:
                        pw.TableBorder.all(width: 1, color: PdfColors.grey),
                    children: [
                      _detailRow('Employee Name', employee['employee_name'],
                          'Employee ID', employee['employee_id']),
                      _detailRow('Date of Joining',
                          employee['date_of_joining'], 'Bank Name',
                          employee['bank_name']),
                      _detailRow('Designation', employee['designation'],
                          'Account No', employee['account_no']),
                      _detailRow('Location', employee['location'], 'UAN',
                          employee['uan']),
                      _detailRow(
  'No.Of Days Worked',
  attendanceWorkdays.toString(),
  'ESIC No',
  employee['esic_no'],
),
                      _detailRow('PAN', employee['pan'], 'LOP',
                          employee['lop']),
                    ],
                  ),

                  // ✅ Extra space between employee details and earnings
                  pw.SizedBox(height: 30),

                  // Earnings + Deductions
                  pw.Table(
                    border:
                        pw.TableBorder.all(width: 1, color: PdfColors.grey),
                    children: [
                      pw.TableRow(
                        decoration: pw.BoxDecoration(
                            color: PdfColor.fromHex('#9F71F8')),
                        children: [
  _cell('Earnings', isBold: true),
  _cell('Amount (Rs)', isBold: true),
  _cell('Deductions', isBold: true),
  _cell('Amount (Rs)', isBold: true),
],
                      ),
                      ...List.generate(
                        (earnings.length > deductions.length
                            ? earnings.length
                            : deductions.length),
                        (index) {
                          final earningKey = index < earnings.keys.length
                              ? earnings.keys.elementAt(index)
                              : '';
                          final earningValue = index < earnings.values.length
                              ? earnings.values.elementAt(index).toString()
                              : '';
                          final deductionKey = index < deductions.keys.length
                              ? deductions.keys.elementAt(index)
                              : '';
                          final deductionValue = index < deductions.values.length
                              ? deductions.values.elementAt(index).toString()
                              : '';

                          return pw.TableRow(
                            children: [
                              _cell(earningKey),
                              _cell(earningValue),
                              _cell(deductionKey),
                              _cell(deductionValue),
                            ],
                          );
                        },
                      ),
                    ],
                  ),

                  pw.SizedBox(height: 30),

                  // Net Pay
                  pw.Container(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text(
                      "Net Salary: Rs ${deductions['NetSalary'] ?? '-'}",
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              // ================= Footer (Bottom Note) =================
              pw.Column(
                children: [
                  pw.Divider(thickness: 1, color: PdfColors.grey),
                  pw.SizedBox(height: 6),
                  pw.Center(
                    child: pw.Text(
                      "This document has been automatically generated by system; therefore, a signature is not required",
                      style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ),
  );
        }

        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdf.save(),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.body}')),
        );
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exception: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Sidebar(
      title: 'Payroll Management',
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
              ),
            ),
            const SizedBox(height: 10),

            // Header Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PayslipScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2C314A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'Payslip',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 20),
                  DropdownButton<String>(
                    value: selectedYear,
                    hint: const Text(
                      'Select Year',
                      style: TextStyle(color: Colors.white),
                    ),
                    dropdownColor: const Color(0xFF2C314A),
                    icon:
                        const Icon(Icons.arrow_drop_down, color: Colors.white),
                    style: const TextStyle(color: Colors.white),
                    items: [
                      for (int year = 2020;
                          year <= DateTime.now().year;
                          year++)
                        DropdownMenuItem(
                          value: year.toString(),
                          child: Text(
                            year.toString(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedYear = value!;
                        int currentYear = DateTime.now().year;
                        int currentMonth = DateTime.now().month;
                        int selected = int.parse(selectedYear!);

                        for (int i = 0; i < checkedList.length; i++) {
                          bool isDisabled = false;

                          if (selected > currentYear) {
                            isDisabled = true;
                          } else if (selected == currentYear &&
                              i + 1 >= currentMonth) {
                            isDisabled = true;
                          }

                          if (isDisabled) {
                            checkedList[i] = false;
                          } else {
                            checkedList[i] = false;
                          }
                        }
                      });
                    },
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: _downloadAllCheckedPayslips,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2C314A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'Download all',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Scrollable Month List
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C314A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Header Row with Select All
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            flex: 8,
                            child: Text(
                              'Months',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Check All',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Checkbox(
                                  value: _areAllAllowedMonthsChecked(),
                                  onChanged: (bool? value) {
                                    if (selectedYear == null) return;
                                    setState(() {
                                      int currentYear =
                                          DateTime.now().year;
                                      int currentMonth =
                                          DateTime.now().month;
                                      int selected =
                                          int.parse(selectedYear!);

                                      for (int i = 0;
                                          i < checkedList.length;
                                          i++) {
                                        bool isDisabled = false;

                                        if (selected > currentYear) {
                                          isDisabled = true;
                                        } else if (selected ==
                                                currentYear &&
                                            i + 1 >= currentMonth) {
                                          isDisabled = true;
                                        }

                                        if (!isDisabled) {
                                          checkedList[i] = value ?? false;
                                        } else {
                                          checkedList[i] = false;
                                        }
                                      }
                                    });
                                  },
                                  checkColor: Colors.black,
                                  fillColor: WidgetStateProperty.all<Color>(
                                      Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(thickness: 2, color: Colors.white),
                      const SizedBox(height: 10),

                      // Month Rows
                      ...List.generate(12, (index) {
                        int currentYear = DateTime.now().year;
                        int currentMonth = DateTime.now().month;
                        bool isDisabled = false;

                        if (selectedYear != null) {
                          int selected = int.parse(selectedYear!);

                          if (selected > currentYear) {
                            isDisabled = true;
                          } else if (selected == currentYear &&
                              index + 1 >= currentMonth) {
                            isDisabled = true;
                          } else {
                            isDisabled = false;
                          }
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 8,
                                child: Text(
                                  months[index],
                                  style: TextStyle(
                                    color: isDisabled
                                        ? Colors.white.withOpacity(0.3)
                                        : Colors.white,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: AbsorbPointer(
                                  absorbing: isDisabled,
                                  child: Opacity(
                                    opacity: isDisabled ? 0.3 : 1.0,
                                    child: Checkbox(
                                      value: checkedList[index],
                                      onChanged: isDisabled
                                          ? null
                                          : (bool? value) {
                                              setState(() {
                                                checkedList[index] =
                                                    value ?? false;
                                              });
                                            },
                                      checkColor: Colors.black,
                                      fillColor:
                                          WidgetStateProperty.all<Color>(
                                              Colors.white),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// PDF helper methods
pw.TableRow _detailRow(String k1, String? v1, String k2, String? v2) {
  return pw.TableRow(
    children: [
      _cell('$k1: ${v1 ?? ''}'),
      _cell('$k2: ${v2 ?? ''}'),
    ],
  );
}

pw.Widget _cell(String text, {bool isBold = false}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(
      vertical: 7,
      horizontal: 4,
    ),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 14,
        fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
      ),
    ),
  );
}