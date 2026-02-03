import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String phoneNumber;
  final String userType; // 'job_seeker' or 'employer'
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Job Seeker specific fields
  final String? bio;
  final List<String>? skills;
  final String? workExperience;
  final String? education;
  final String? profilePictureUrl;
  final List<Map<String, String>>?
      documents; // List of uploaded documents with name and URL

  // Employer specific fields
  final String? companyName;
  final String? registrationNumber;
  final String? industryType;
  final String? companyDescription;
  final String? companySize;
  final String? website;
  final Map<String, String>? socialMediaLinks;
  final String? physicalAddress;
  final String? logoUrl;
  final String? verificationStatus; // 'pending', 'verified', 'rejected'

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phoneNumber,
    required this.userType,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.bio,
    this.skills,
    this.workExperience,
    this.education,
    this.profilePictureUrl,
    this.documents,
    this.companyName,
    this.registrationNumber,
    this.industryType,
    this.companyDescription,
    this.companySize,
    this.website,
    this.socialMediaLinks,
    this.physicalAddress,
    this.logoUrl,
    this.verificationStatus,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      userType: data['userType'] ?? 'job_seeker',
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      bio: data['bio'],
      skills: data['skills'] != null ? List<String>.from(data['skills']) : null,
      workExperience: data['workExperience'],
      education: data['education'],
      profilePictureUrl: data['profilePictureUrl'],
      documents: data['documents'] != null
          ? List<Map<String, String>>.from((data['documents'] as List)
              .map((doc) => Map<String, String>.from(doc)))
          : null,
      companyName: data['companyName'],
      registrationNumber: data['registrationNumber'],
      industryType: data['industryType'],
      companyDescription: data['companyDescription'],
      companySize: data['companySize'],
      website: data['website'],
      socialMediaLinks: data['socialMediaLinks'] != null
          ? Map<String, String>.from(data['socialMediaLinks'])
          : null,
      physicalAddress: data['physicalAddress'],
      logoUrl: data['logoUrl'],
      verificationStatus: data['verificationStatus'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'userType': userType,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (bio != null) 'bio': bio,
      if (skills != null) 'skills': skills,
      if (workExperience != null) 'workExperience': workExperience,
      if (education != null) 'education': education,
      if (profilePictureUrl != null) 'profilePictureUrl': profilePictureUrl,
      if (documents != null) 'documents': documents,
      if (companyName != null) 'companyName': companyName,
      if (registrationNumber != null) 'registrationNumber': registrationNumber,
      if (industryType != null) 'industryType': industryType,
      if (companyDescription != null) 'companyDescription': companyDescription,
      if (companySize != null) 'companySize': companySize,
      if (website != null) 'website': website,
      if (socialMediaLinks != null) 'socialMediaLinks': socialMediaLinks,
      if (physicalAddress != null) 'physicalAddress': physicalAddress,
      if (logoUrl != null) 'logoUrl': logoUrl,
      if (verificationStatus != null) 'verificationStatus': verificationStatus,
    };
  }
}
