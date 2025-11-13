class Experience {
  final String companyName;
  final String role;
  final String startDate;
  final String endDate;
  final String description;

  Experience({
    required this.companyName,
    required this.role,
    required this.startDate,
    required this.endDate,
    required this.description,
  });

  factory Experience.fromJson(Map<String, dynamic> json) {
    return Experience(
      companyName: json['companyName'] ?? '',
      role: json['role'] ?? '',
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'companyName': companyName,
      'role': role,
      'startDate': startDate,
      'endDate': endDate,
      'description': description,
    };
  }
}

class Employee {
  final String id;
  final String fullName;
  final String dateOfAppointment;
  final String annualCtc;
  final String monthlyCtc;
  final String annualGross;
  final String monthlyGross;
  final String department;
  final String designation;
  final String workEmail;
  final String uanNumber;
  final String aadharNumber;
  final String panNumber;
  final String dob;
  final String fatherOrHusbandName;
  final String gender;
  final String maritalStatus;
  final String mobileNumber;
  final String alternativeMobileNumber;
  final String currentAddress;
  final String permanentAddress;
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
  final String drivingLicense;
  final String voterId;

  final String previousCompany;
  final String previousRole;
  final String previousExperience;
  final String previousExperienceFileUrl;

  final String emergencyContactNumber;
  final String bloodGroup;
  final String nationality;
  final String passportNumber;
  final String languagesKnown;

  final List<Experience> experiences;

  Employee({
    required this.id,
    required this.fullName,
    required this.dateOfAppointment,
    required this.annualCtc,
    required this.monthlyCtc,
    required this.annualGross,
    required this.monthlyGross,
    required this.department,
    required this.designation,
    required this.workEmail,
    required this.uanNumber,
    required this.aadharNumber,
    required this.panNumber,
    required this.dob,
    required this.fatherOrHusbandName,
    required this.gender,
    required this.maritalStatus,
    required this.mobileNumber,
    required this.alternativeMobileNumber,
    required this.currentAddress,
    required this.permanentAddress,
    required this.personalEmail,
    required this.bankName,
    required this.ifscCode,
    required this.bankAccountNumber,
    required this.bankAccountType,
    this.education10 = '',
    this.education12 = '',
    this.ugCertificate = '',
    this.pgCertificate = '',
    this.phdCertificate = '',
    this.otherCertificate = '',
    this.drivingLicense = '',
    this.voterId = '',
    this.previousCompany = '',
    this.previousRole = '',
    this.previousExperience = '',
    this.previousExperienceFileUrl = '',
    this.emergencyContactNumber = '',
    this.bloodGroup = '',
    this.nationality = '',
    this.passportNumber = '',
    this.languagesKnown = '',
    this.experiences = const [],
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] ?? '',
      fullName: json['fullName'] ?? '',
      dateOfAppointment: json['dateOfAppointment'] ?? '',
      annualCtc: json['annualCtc']?.toString() ?? '',
      monthlyCtc: json['monthlyCtc']?.toString() ?? '',
      annualGross: json['annualGross']?.toString() ?? '',
      monthlyGross: json['monthlyGross']?.toString() ?? '',
      department: json['department'] ?? '',
      designation: json['designation'] ?? '',
      workEmail: json['workEmail'] ?? '',
      uanNumber: json['uanNumber'] ?? '',
      aadharNumber: json['aadharNumber'] ?? '',
      panNumber: json['panNumber'] ?? '',
      dob: json['dob'] ?? '',
      fatherOrHusbandName: json['fatherOrHusbandName'] ?? '',
      gender: json['gender'] ?? '',
      maritalStatus: json['maritalStatus'] ?? '',
      mobileNumber: json['mobileNumber'] ?? '',
      alternativeMobileNumber: json['alternativeMobileNumber'] ?? '',
      currentAddress: json['currentAddress'] ?? '',
      permanentAddress: json['permanentAddress'] ?? '',
      personalEmail: json['personalEmail'] ?? '',
      bankName: json['bankName'] ?? '',
      ifscCode: json['ifscCode'] ?? '',
      bankAccountNumber: json['bankAccountNumber'] ?? '',
      bankAccountType: json['bankAccountType'] ?? '',
      education10: json['education10'] ?? '',
      education12: json['education12'] ?? '',
      ugCertificate: json['ugCertificate'] ?? '',
      pgCertificate: json['pgCertificate'] ?? '',
      phdCertificate: json['phdCertificate'] ?? '',
      otherCertificate: json['otherCertificate'] ?? '',
      drivingLicense: json['drivingLicense'] ?? '',
      voterId: json['voterId'] ?? '',
      previousCompany: json['previousCompany'] ?? '',
      previousRole: json['previousRole'] ?? '',
      previousExperience: json['previousExperience'] ?? '',
      previousExperienceFileUrl: json['previousExperienceFileUrl'] ?? '',
      emergencyContactNumber: json['emergencyContactNumber'] ?? '',
      bloodGroup: json['bloodGroup'] ?? '',
      nationality: json['nationality'] ?? '',
      passportNumber: json['passportNumber'] ?? '',
      languagesKnown: json['languagesKnown'] ?? '',
      experiences: (json['experiences'] as List<dynamic>? ?? [])
          .map((e) => Experience.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'dateOfAppointment': dateOfAppointment,
      'annualCtc': annualCtc,
      'monthlyCtc': monthlyCtc,
      'annualGross': annualGross,
      'monthlyGross': monthlyGross,
      'department': department,
      'designation': designation,
      'workEmail': workEmail,
      'uanNumber': uanNumber,
      'aadharNumber': aadharNumber,
      'panNumber': panNumber,
      'dob': dob,
      'fatherOrHusbandName': fatherOrHusbandName,
      'gender': gender,
      'maritalStatus': maritalStatus,
      'mobileNumber': mobileNumber,
      'alternativeMobileNumber': alternativeMobileNumber,
      'currentAddress': currentAddress,
      'permanentAddress': permanentAddress,
      'personalEmail': personalEmail,
      'bankName': bankName,
      'ifscCode': ifscCode,
      'bankAccountNumber': bankAccountNumber,
      'bankAccountType': bankAccountType,
      'education10': education10,
      'education12': education12,
      'ugCertificate': ugCertificate,
      'pgCertificate': pgCertificate,
      'phdCertificate': phdCertificate,
      'otherCertificate': otherCertificate,
      'drivingLicense': drivingLicense,
      'voterId': voterId,
      'previousCompany': previousCompany,
      'previousRole': previousRole,
      'previousExperience': previousExperience,
      'previousExperienceFileUrl': previousExperienceFileUrl,
      'emergencyContactNumber': emergencyContactNumber,
      'bloodGroup': bloodGroup,
      'nationality': nationality,
      'passportNumber': passportNumber,
      'languagesKnown': languagesKnown,
      'experiences': experiences.map((e) => e.toJson()).toList(),
    };
  }
}
