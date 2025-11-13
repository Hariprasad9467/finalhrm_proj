import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:http_parser/http_parser.dart';


import 'sidebar.dart';
import 'user_provider.dart';

/// 🔹 Employee model with profileDocs paths
class Employee {
  final String companyName;
  final String role;
  final String startDate;
  final String endDate;
  final String description;
  final String id;
  final String fullName;
  final String dateOfAppointment;
  final String department;
  final String designation;
  final String workEmail;
  final String uanNumber;
  final String aadharNumber;
  final String panNumber;
  final String voterId;



  final String drivingLicense;
  final String passportNumber;
  final String bloodGroup;
  final String currentAddress;
  final String permanentAddress;
  final String dob;
  final String fatherOrHusbandName;
  final String gender;
  final String maritalStatus;
  final String mobileNumber;
  final String alternativeMobileNumber;
  final String personalEmail;
  final String bankName;
  final String ifscCode;
  final String bankAccountNumber;
  final String bankAccountType;

  final String education10;
  final String education12;
  final String ugCertificate;
  final String pgCertificate;
  final String phdCertificate;
  final String otherCertificate;

  // File paths from profileDocs
  final String aadharFilePath;
  final String panFilePath;
  final String drivingLicensefilePath;
  final String voterIdfilePath;
  final String education10filePath;
  final String education12filePath;
  final String ugCertificatefilePath;
  final String pgCertificatefilePath;
  final String phdCertificatefilePath;
  final String otherCertificatefilePath;
  final String passportFilePath;
  final String uanFilePath;

  final List<Experience> experiences;

  Employee({
    required this.companyName,
    required this.role,
    required this.startDate,
    required this.endDate,
    this.description = '',
    required this.id,
    required this.fullName,
    required this.dateOfAppointment,
    required this.department,
    required this.designation,
    required this.workEmail,
    required this.uanNumber,
    required this.aadharNumber,
    required this.panNumber,
    required this.voterId,
    required this.drivingLicense,
    required this.passportNumber,
    required this.bloodGroup,
    required this.currentAddress,
    required this.permanentAddress,
    required this.dob,
    required this.fatherOrHusbandName,
    required this.gender,
    required this.maritalStatus,
    required this.mobileNumber,
    required this.alternativeMobileNumber,
    required this.personalEmail,
    required this.bankName,
    required this.ifscCode,
    required this.bankAccountNumber,
    required this.bankAccountType,
     required this.education10,
    required this.education12,
    required this.ugCertificate,
    required this.pgCertificate,
    required this.phdCertificate,
    required this.otherCertificate,
    required this.aadharFilePath,
    required this.panFilePath,
    required this.drivingLicensefilePath,
    required this.voterIdfilePath,
    required this.education10filePath,
    required this.education12filePath,
    required this.ugCertificatefilePath,
    required this.pgCertificatefilePath,
    required this.phdCertificatefilePath,
    required this.otherCertificatefilePath,
    required this.passportFilePath,
    required this.uanFilePath,
    this.experiences = const [],
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      companyName: json['company_name'] ?? '',
      role: json['role'] ?? '',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      description: json['description'] ?? '',
      id: json['id'] ?? '',
      fullName: json['full_name'] ?? '',
      dateOfAppointment: json['date_of_appointment'] ?? '',
      department: json['department'] ?? '',
      designation: json['designation'] ?? '',
      workEmail: json['work_email_id'] ?? '',
      uanNumber: json['uan_number'] ?? '',
      aadharNumber: json['aadhar_number'] ?? '',
      panNumber: json['pan_number'] ?? '',
      voterId: json['voter_id'] ?? '',
      drivingLicense: json['driving_license'] ?? '',
      passportNumber: json['passport_number'] ?? '',
      bloodGroup: json['blood_group'] ?? '',
      currentAddress: json['current_address'] ?? '',
      permanentAddress: json['permanent_address'] ?? '',
      dob: json['dob'] ?? '',
      fatherOrHusbandName: json['father_or_husband_name'] ?? '',
      gender: json['gender'] ?? '',
      maritalStatus: json['marital_status'] ?? '',
      mobileNumber: json['mobile_number'] ?? '',
      alternativeMobileNumber: json['alternative_mobile'] ?? '',
      personalEmail: json['email_id'] ?? '',
      bankName: json['bank_name'] ?? '',
      ifscCode: json['ifsc_code'] ?? '',
      bankAccountNumber: json['bank_account_number'] ?? '',
      bankAccountType: json['bank_account_type'] ?? '',

       // 🔹 Education values
      education10: json['education10'] ?? '',
      education12: json['education12'] ?? '',
      ugCertificate: json['ugCertificate'] ?? '',
      pgCertificate: json['pgCertificate'] ?? '',
      phdCertificate: json['phdCertificate'] ?? '',
      otherCertificate: json['otherCertificate'] ?? '',

      // 🔹 File paths from profileDocs
      aadharFilePath: json['profileDocs']?['aadhar'] ?? '',
      panFilePath: json['profileDocs']?['pan'] ?? '',
      drivingLicensefilePath: json['profileDocs']?['driving_license'] ?? '',
      voterIdfilePath: json['profileDocs']?['voter_id'] ?? '',
      education10filePath: json['profileDocs']?['education_10'] ?? '',
      education12filePath: json['profileDocs']?['education_12'] ?? '',
      ugCertificatefilePath: json['profileDocs']?['ug'] ?? '',
      pgCertificatefilePath: json['profileDocs']?['pg'] ?? '',
      phdCertificatefilePath: json['profileDocs']?['phd'] ?? '',
      otherCertificatefilePath: json['profileDocs']?['other_certificate'] ?? '',
      passportFilePath: json['profileDocs']?['passport'] ?? '',
      uanFilePath: json['profileDocs']?['uan'] ?? '',

      experiences: (json['experiences'] as List<dynamic>? ?? [])
          .map((exp) => Experience.fromJson(exp))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'date_of_appointment': dateOfAppointment,
        'department': department,
        'designation': designation,
        'work_email_id': workEmail,
        'uan_number': uanNumber,
        'aadhar_number': aadharNumber,
        'pan_number': panNumber,
        'voter_id': voterId,
        'driving_license': drivingLicense,
        'passport_number': passportNumber,
        'blood_group': bloodGroup,
        'current_address': currentAddress,
        'permanent_address': permanentAddress,
        'dob': dob,
        'father_or_husband_name': fatherOrHusbandName,
        'gender': gender,
        'marital_status': maritalStatus,
        'mobile_number': mobileNumber,
        'alternative_mobile': alternativeMobileNumber,
        'email_id': personalEmail,
        'bank_name': bankName,
        'ifsc_code': ifscCode,
        'bank_account_number': bankAccountNumber,
        'bank_account_type': bankAccountType,
      };
}

class Experience {
  final String id;
  final String companyName;
  final String role;
  final String startDate;
  final String endDate;
  final String description;

  Experience({
    required this.id,
    required this.companyName,
    required this.role,
    required this.startDate,
    required this.endDate,
    this.description = '',
  });

  factory Experience.fromJson(Map<String, dynamic> json) {
    return Experience(
      id: json['_id']?.toString() ?? '', // ← Use MongoDB _id
      companyName: json['company_name'] ?? '',
      role: json['role'] ?? '',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      description: json['description'] ?? '',
    );
  }
  Map<String, dynamic> toJson() {
    return {
      "_id": id,
      "company_name": companyName,
      "role": role,
      "start_date": startDate,
      "end_date": endDate,
      "description": description,
    };
  }
}
class EmployeeProfilePage extends StatefulWidget {
  const EmployeeProfilePage({super.key});

  @override
  State<EmployeeProfilePage> createState() => _EmployeeProfilePageState();
}

class _EmployeeProfilePageState extends State<EmployeeProfilePage> {
  Employee? employee;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => fetchEmployee());
  }

  Future<void> fetchEmployee() async {
    final employeeId =
        Provider.of<UserProvider>(context, listen: false).employeeId;
    if (employeeId == null) return setState(() => isLoading = false);

    try {
      final response = await http.get(
        Uri.parse('http://localhost:5000/profile/$employeeId'),
      );
      if (response.statusCode == 200) {
        setState(() {
          employee = Employee.fromJson(json.decode(response.body));
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      setState(() => isLoading = false);
    }
  }

  /// 🔹 Request profile update
  Future<void> updateEmployeeField(String field, String newValue) async {
    final employeeId =
        Provider.of<UserProvider>(context, listen: false).employeeId;
    if (employeeId == null) return;

    final oldValue =
        (employee != null) ? (employee!.toJson()[field]?.toString() ?? '') : '';

    try {
      final url =
          Uri.parse('http://localhost:5000/requests/profile/$employeeId/request-change');
      final body = jsonEncode({
        'fullName': employee?.fullName ?? '', 
        'field': field,
        'oldValue': oldValue,
        'newValue': newValue,
        'requestedBy': employeeId,
      });

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Request submitted for $field')),
        );
      } else {
        debugPrint(
            'Failed to submit request: ${response.statusCode} ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Failed to create request')),
        );
      }
    } catch (e) {
      debugPrint('Error submitting request: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Error: $e')));
    }
  }

  /// 🔹 Upload documents
  Future<void> _handleUpload(String docType) async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
  );

  if (result == null || result.files.isEmpty) return;

  final file = result.files.first;
  Uint8List? fileBytes;

  if (kIsWeb) {
    fileBytes = file.bytes;
  } else {
    if (file.path != null) {
      fileBytes = await File(file.path!).readAsBytes();
    }
  }

  if (fileBytes == null && (file.path == null || file.path!.isEmpty)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("❌ Failed to read file bytes or path")),
    );
    return;
  }

  final employeeId = Provider.of<UserProvider>(context, listen: false).employeeId;
  if (employeeId == null) return;

  try {
    final uri = Uri.parse("http://localhost:5000/upload/$employeeId");
    final request = http.MultipartRequest('POST', uri);

    // Determine a simple contentType based on extension (avoid adding extra package)
    final ext = file.name.split('.').last.toLowerCase();
    MediaType? contentType;
    if (ext == 'pdf') {
      contentType = MediaType('application', 'pdf');
    } else if (ext == 'png') {
      contentType = MediaType('image', 'png');
    } else if (ext == 'jpg' || ext == 'jpeg') {
      contentType = MediaType('image', 'jpeg');
    }

    if (kIsWeb || fileBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes ?? [],
          filename: file.name,
          contentType: contentType,
        ),
      );
    } else {
      // fallback for mobile/desktop with path
      request.files.add(
        await http.MultipartFile.fromPath('file', file.path!),
      );
    }

    request.fields['docType'] = _mapDocTypeToField(docType);

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(body['message'] ?? '✅ Uploaded')),
      );
      fetchEmployee(); // refresh profile
    } else {
      String msg;
      try {
        final body = json.decode(response.body);
        msg = body['message'] ?? response.body;
      } catch (_) {
        msg = response.body;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to upload: $msg")),
      );
    }
  } catch (e) {
    debugPrint("Upload error: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("❌ Upload error: $e")),
    );
  }
}


  

  /// 🔹 Map UI labels to backend field names
 String _mapDocTypeToField(String docType) {
  switch (docType) {
    case "Aadhar":
      return "aadhar";
    case "PAN":
      return "pan";
    case "Driving License":
      return "driving_license";
    case "Voter ID":
      return "voter_id";
    case "10th Grade":
      return "education_10";
    case "12th Grade":
      return "education_12";
    case "UG Certificate":
      return "ug";
    case "PG Certificate":
      return "pg";
    case "PhD Certificate":
      return "phd";
    case "Other Certificate":
      return "other_certificate";
    default:
      return docType.toLowerCase().replaceAll(" ", "_");
  }
}


  void _showEditDialog(
    String label,
    String field,
    String currentValue,
    void Function(String) onSubmit,
  ) {
    final controller = TextEditingController(text: currentValue);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text(
          'Edit $label',
          style: const TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Enter new $label",
            hintStyle: const TextStyle(color: Colors.white54),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              onSubmit(controller.text);
              Navigator.pop(context);
            },
            child: const Text("Request"),
          ),
        ],
      ),
    );
  }

  void _showAddExperienceDialog() {
  final companyController = TextEditingController();
  final roleController = TextEditingController();
  final startDateController = TextEditingController();
  final endDateController = TextEditingController();
  final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          "Add Experience",
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: companyController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Company Name",
                hintStyle: TextStyle(color: Colors.white54),
              ),
            ),
            TextField(
              controller: roleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Job Title",
                hintStyle: TextStyle(color: Colors.white54),
              ),
            ),
            TextField(
              controller: startDateController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Start Date (YYYY-MM-DD)",
                hintStyle: TextStyle(color: Colors.white54),
              ),
            ),
            TextField(
              controller: endDateController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "End Date (YYYY-MM-DD)",
                hintStyle: TextStyle(color: Colors.white54),
              ),
            ),
            TextField(
              controller: descriptionController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Description",
                hintStyle: TextStyle(color: Colors.white54),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final experience = {
              "company_name": companyController.text,
              "role": roleController.text,
              "start_date": startDateController.text,
              "end_date": endDateController.text,
              "description": descriptionController.text,
            };


              final employeeId =
                  Provider.of<UserProvider>(context, listen: false).employeeId;
              await http.post(
                Uri.parse(
                    'http://localhost:5000/profile/$employeeId/experience'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode(experience),
              );

              Navigator.pop(context);
              fetchEmployee();
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  Widget _profileTile(
    IconData icon,
    String label,
    String value, {
    required String field,
    bool editable = true,
    bool showUpload = false,
    String? docType,
    String? filePath,
}) {
  final bool hasFile = filePath != null && filePath.isNotEmpty;


    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.deepPurple),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  value.isNotEmpty ? value : "Not Provided",
                  style: const TextStyle(color: Colors.white70),
                ),
                if (hasFile)
                  TextButton(
                    onPressed: () async {
                      final url = "http://localhost:5000$filePath";
                      if (await canLaunchUrl(Uri.parse(url))) {
                        await launchUrl(Uri.parse(url),
                            mode: LaunchMode.externalApplication);
                      }
                    },
                    child: const Text("📂 Open File",
                        style: TextStyle(color: Colors.blue)),
                  ),
              ],
            ),
          ),
          if (editable || showUpload)
            Row(
              children: [
                if (editable)
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18, color: Colors.grey),
                    onPressed: () => _showEditDialog(
                        label, field, value, (newValue) {
                      updateEmployeeField(field, newValue);
                    }),
                  ),
                if (showUpload && docType != null)
                  ElevatedButton.icon(
                    onPressed: () => _handleUpload(docType),
                    icon: const Icon(Icons.upload_file, size: 16),
                    label: Text(
                  hasFile ? "Replace" : "Upload",
                  style: const TextStyle(fontSize: 12),
                ),

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildExperienceSection() {
    return _buildSection("Past Experiences", [
      if (employee!.experiences.isEmpty)
        const Text(
          "No experiences added",
          style: TextStyle(color: Colors.white70),
        ),
      for (final exp in employee!.experiences)
        ListTile(
          title: Text(
            exp.companyName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Company: ${exp.companyName}",
        style: const TextStyle(color: Colors.white70)),
    Text("Role: ${exp.role}",
        style: const TextStyle(color: Colors.white70)),
    Text("Duration: ${exp.startDate} - ${exp.endDate}",
        style: const TextStyle(color: Colors.white70)),
              if (exp.description.isNotEmpty)
      Text("Description: ${exp.description}",
          style: const TextStyle(color: Colors.white60, fontSize: 12)),
            ],
          ),
         trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.amber),
                  onPressed: () => _showEditExperienceDialog(exp),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () => _deleteExperience(exp),
                ),
              ],
            ), 
        ),
      const SizedBox(height: 10),
      Align(
        alignment: Alignment.centerLeft,
        child: ElevatedButton.icon(
          onPressed: _showAddExperienceDialog,
          icon: const Icon(Icons.add),
          label: const Text("Add Experience"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
          ),
        ),
      ),
    ]);
  }

  void _showEditExperienceDialog(Experience exp) {
  final companyController = TextEditingController(text: exp.companyName);
  final roleController = TextEditingController(text: exp.role);
  final startdateController = TextEditingController(text: exp.startDate);
  final enddateController = TextEditingController(text: exp.endDate);
  final descriptionController = TextEditingController(text: exp.description);

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF1A1A2E),
      title: const Text(
        "Edit Experience",
        style: TextStyle(color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: companyController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                  hintText: "Company Name",
                  hintStyle: TextStyle(color: Colors.white54)),
            ),
            TextField(
              controller: roleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                  hintText: "Role", hintStyle: TextStyle(color: Colors.white54)),
            ),
            TextField(
              controller: startdateController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                  hintText: "Start Date",
                  hintStyle: TextStyle(color: Colors.white54)),
            ),
            TextField(
              controller: enddateController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                  hintText: "End Date", hintStyle: TextStyle(color: Colors.white54)),
            ),
            TextField(
              controller: descriptionController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                  hintText: "Description",
                  hintStyle: TextStyle(color: Colors.white54)),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () async {
            final employeeId =
                Provider.of<UserProvider>(context, listen: false).employeeId;
            if (employeeId == null) return;

            final updatedExp = {
              "company_name": companyController.text,
              "role": roleController.text,
              "start_date": startdateController.text,
              "end_date": enddateController.text,
              "description": descriptionController.text,
            };

            try {
              final response = await http.put(
                Uri.parse(
                    'http://localhost:5000/profile/$employeeId/experience/${exp.id}'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode(updatedExp),
              );

              if (response.statusCode == 200) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("✅ Experience updated")),
                );
                fetchEmployee();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("❌ Failed to update: ${response.body}")),
                );
              }
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("❌ Error: $e")),
              );
            }

            Navigator.pop(context);
          },
          child: const Text("Save"),
        ),
      ],
    ),
  );
}

  /// 🔹 Delete Experience
 Future<void> _deleteExperience(Experience exp) async {
  if (exp.id.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("❌ Cannot delete experience: ID missing")),
    );
    return;
  }

  final employeeId =
      Provider.of<UserProvider>(context, listen: false).employeeId;
  if (employeeId == null) return;

  try {
    final response = await http.delete(
      Uri.parse('http://localhost:5000/profile/$employeeId/experience/${exp.id}'),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Experience deleted")),
      );
      fetchEmployee();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed: ${response.body}")),
      );
    }
  } catch (e) {
    debugPrint("Error deleting experience with id: ${exp.id}");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("❌ Error: $e")),
    );
  }
}

  Widget _buildSection(String title, List<Widget> items) {
    return Card(
      color: const Color(0xFF1A1A2E),
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const Divider(color: Colors.white24),
            ...items,
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const CircleAvatar(
          radius: 30,
          backgroundColor: Colors.white10,
          child: Icon(Icons.person, size: 36, color: Colors.white),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(employee?.fullName ?? 'Name',
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            Text("Employee ID: ${employee?.id ?? 'N/A'}",
                style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Sidebar(
      title: 'Employee Profile',
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : employee == null
              ? const Center(
                  child: Text("❌ Failed to load profile",
                      style: TextStyle(color: Colors.white)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 32),

                      /// Personal
                      _buildSection("Personal Details", [
                        _profileTile(Icons.calendar_today, "DOB",
                            employee!.dob, field: "dob"),
                        _profileTile(Icons.person, "Gender", employee!.gender,
                            field: "gender"),
                        _profileTile(
                            Icons.family_restroom,
                            "Father/Husband",
                            employee!.fatherOrHusbandName,
                            field: "father_or_husband_name"),
                        _profileTile(
                            Icons.favorite,
                            "Marital Status",
                            employee!.maritalStatus,
                            field: "marital_status"),
                      ]),

                      /// Contact & Identity
                      _buildSection("Contact & Identity", [
                        _profileTile(Icons.phone, "Mobile",
                            employee!.mobileNumber,
                            field: "mobile_number"),
                        _profileTile(
                            Icons.phone,
                            "Alternative Mobile",
                            employee!.alternativeMobileNumber,
                            field: "alternative_mobile"),
                        _profileTile(Icons.email, "Email",
                            employee!.personalEmail,
                            field: "email_id"),
                        _profileTile(Icons.credit_card, "Aadhar",
                            employee!.aadharNumber,
                            field: "aadhar_number",
                            showUpload: true,
                            docType: "Aadhar",
                            filePath: employee!.aadharFilePath),
                        _profileTile(Icons.badge, "PAN", employee!.panNumber,
                            field: "pan_number",
                            showUpload: true,
                            docType: "PAN",
                            filePath: employee!.panFilePath),
                        _profileTile(Icons.drive_eta, "Driving License",
                            employee!.drivingLicense,
                            field: "driving_license",
                            showUpload: true,
                            docType: "Driving License",
                            filePath: employee!.drivingLicensefilePath),
                        _profileTile(Icons.how_to_vote, "Voter ID",
                            employee!.voterId,
                            field: "voter_id",
                            showUpload: true,
                            docType: "Voter ID",
                            filePath: employee!.voterIdfilePath),
                      ]),

                      /// Job
                      _buildSection("Job Details", [
                        _profileTile(Icons.apartment, "Department",
                            employee!.department,
                            field: "department", editable: false),
                        _profileTile(Icons.work, "Designation",
                            employee!.designation,
                            field: "designation", editable: false),
                        _profileTile(Icons.date_range, "Date of Joining",
                            employee!.dateOfAppointment,
                            field: "date_of_appointment", editable: false),
                        _profileTile(Icons.email_outlined, "Work Email",
                            employee!.workEmail,
                            field: "work_email", editable: false),
                      ]),

                      /// Education
                      _buildSection("Educational Details", [
                        _profileTile(Icons.school, "10th Grade",
                            employee!.education10,
                            field: "education10",
                            editable: false,
                            showUpload: true,
                            docType: "10th Grade",
                            filePath: employee!.education10filePath),
                        _profileTile(Icons.school, "12th Grade",
                            employee!.education12,
                            field: "education12",
                            editable: false,
                            showUpload: true,
                            docType: "12th Grade",
                            filePath: employee!.education12filePath),
                        _profileTile(Icons.file_copy, "UG Certificate",
                            employee!.ugCertificate,
                            field: "ugCertificate",
                            editable: false,
                            showUpload: true,
                            docType: "UG Certificate",
                            filePath: employee!.ugCertificatefilePath),
                        _profileTile(Icons.file_copy, "PG Certificate",
                            employee!.pgCertificate,
                            field: "pgCertificate",
                            editable: false,
                            showUpload: true,
                            docType: "PG Certificate",
                            filePath: employee!.pgCertificatefilePath),
                        _profileTile(Icons.file_copy, "PhD Certificate",
                            employee!.phdCertificate,
                            field: "phdCertificate",
                            editable: false,
                            showUpload: true,
                            docType: "PhD Certificate",
                            filePath: employee!.phdCertificatefilePath),
                        _profileTile(Icons.file_present, "Other Certificate",
                            employee!.otherCertificate,
                            field: "otherCertificate",
                            editable: false,
                            showUpload: true,
                            docType: "Other Certificate",
                            filePath: employee!.otherCertificatefilePath),
                      ]),

                      /// Banking
                      _buildSection("Banking Details", [
                        _profileTile(Icons.account_balance, "Bank Name",
                            employee!.bankName,
                            field: "bank_name"),
                        _profileTile(Icons.qr_code, "IFSC Code",
                            employee!.ifscCode,
                            field: "ifsc_code"),
                        _profileTile(Icons.account_balance_wallet,
                            "Account Number", employee!.bankAccountNumber,
                            field: "bank_account_number"),
                        _profileTile(Icons.account_box, "Account Type",
                            employee!.bankAccountType,
                            field: "bank_account_type"),
                      ]),

                      /// Other
                      _buildSection("Other", [
                        _profileTile(Icons.lock, "UAN Number",
                            employee!.uanNumber,
                            field: "uan_number"),
                        _profileTile(Icons.bloodtype, "Blood Group",
                            employee!.bloodGroup,
                            field: "blood_group"),
                        _profileTile(Icons.travel_explore, "Passport Number",
                            employee!.passportNumber,
                            field: "passport_number"),
                        _profileTile(Icons.location_city, "Current Address",
                            employee!.currentAddress,
                            field: "current_address"),
                        _profileTile(Icons.home, "Permanent Address",
                            employee!.permanentAddress,
                            field: "permanent_address"),
                      ]),

                      _buildExperienceSection(),
                    ],
                  ),
                ),
    );
  }
}