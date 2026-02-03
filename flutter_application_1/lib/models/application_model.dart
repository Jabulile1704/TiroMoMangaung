import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ApplicationModel {
  final String id;
  final String jobId;
  final String seekerId;
  final String? coverLetter;
  final List<Map<String, String>>?
      documents; // Uploaded documents with name, url, uploadedAt
  final String status; // 'pending', 'shortlisted', 'rejected', 'hired'
  final String? employerNotes;
  final String? rejectionReason;
  final String? employerFeedback;
  final double? relevanceScore;
  final bool? locationMatch;
  final bool isWithdrawn;
  final DateTime appliedAt;
  final DateTime? reviewedAt;
  final DateTime updatedAt;

  // Related data for display
  final String? jobTitle;
  final String? companyName;
  final String? seekerName;
  final String? seekerEmail;

  ApplicationModel({
    required this.id,
    required this.jobId,
    required this.seekerId,
    this.coverLetter,
    this.documents,
    required this.status,
    this.employerNotes,
    this.rejectionReason,
    this.employerFeedback,
    this.relevanceScore,
    this.locationMatch,
    required this.isWithdrawn,
    required this.appliedAt,
    this.reviewedAt,
    required this.updatedAt,
    this.jobTitle,
    this.companyName,
    this.seekerName,
    this.seekerEmail,
  });

  factory ApplicationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse documents array
    List<Map<String, String>>? documents;
    if (data['documents'] != null) {
      documents = (data['documents'] as List)
          .map((doc) => Map<String, String>.from(doc as Map))
          .toList();
    }

    return ApplicationModel(
      id: doc.id,
      jobId: data['jobId'] ?? '',
      seekerId: data['seekerId'] ?? '',
      coverLetter: data['coverLetter'],
      documents: documents,
      status: data['status'] ?? 'pending',
      employerNotes: data['employerNotes'],
      rejectionReason: data['rejectionReason'],
      employerFeedback: data['employerFeedback'],
      relevanceScore: data['relevanceScore']?.toDouble(),
      locationMatch: data['locationMatch'],
      isWithdrawn: data['isWithdrawn'] ?? false,
      appliedAt: (data['appliedAt'] as Timestamp).toDate(),
      reviewedAt: data['reviewedAt'] != null
          ? (data['reviewedAt'] as Timestamp).toDate()
          : null,
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      jobTitle: data['jobTitle'],
      companyName: data['companyName'],
      seekerName: data['seekerName'],
      seekerEmail: data['seekerEmail'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'jobId': jobId,
      'seekerId': seekerId,
      if (coverLetter != null) 'coverLetter': coverLetter,
      if (documents != null) 'documents': documents,
      'status': status,
      if (employerNotes != null) 'employerNotes': employerNotes,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
      if (employerFeedback != null) 'employerFeedback': employerFeedback,
      if (relevanceScore != null) 'relevanceScore': relevanceScore,
      if (locationMatch != null) 'locationMatch': locationMatch,
      'isWithdrawn': isWithdrawn,
      'appliedAt': Timestamp.fromDate(appliedAt),
      if (reviewedAt != null) 'reviewedAt': Timestamp.fromDate(reviewedAt!),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // CopyWith method for easier updates (OPTIMIZATION)
  ApplicationModel copyWith({
    String? id,
    String? jobId,
    String? seekerId,
    String? coverLetter,
    List<Map<String, String>>? documents,
    String? status,
    String? employerNotes,
    String? rejectionReason,
    String? employerFeedback,
    double? relevanceScore,
    bool? locationMatch,
    bool? isWithdrawn,
    DateTime? appliedAt,
    DateTime? reviewedAt,
    DateTime? updatedAt,
    String? jobTitle,
    String? companyName,
    String? seekerName,
    String? seekerEmail,
  }) {
    return ApplicationModel(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      seekerId: seekerId ?? this.seekerId,
      coverLetter: coverLetter ?? this.coverLetter,
      documents: documents ?? this.documents,
      status: status ?? this.status,
      employerNotes: employerNotes ?? this.employerNotes,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      employerFeedback: employerFeedback ?? this.employerFeedback,
      relevanceScore: relevanceScore ?? this.relevanceScore,
      locationMatch: locationMatch ?? this.locationMatch,
      isWithdrawn: isWithdrawn ?? this.isWithdrawn,
      appliedAt: appliedAt ?? this.appliedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      jobTitle: jobTitle ?? this.jobTitle,
      companyName: companyName ?? this.companyName,
      seekerName: seekerName ?? this.seekerName,
      seekerEmail: seekerEmail ?? this.seekerEmail,
    );
  }

  String get statusDisplayName {
    switch (status) {
      case 'pending':
        return 'Pending Review';
      case 'shortlisted':
        return 'Shortlisted';
      case 'rejected':
        return 'Rejected';
      case 'hired':
        return 'Hired';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'pending':
        return const Color(0xFFFF9800); // Orange
      case 'shortlisted':
        return const Color(0xFF2196F3); // Blue
      case 'rejected':
        return const Color(0xFFF44336); // Red
      case 'hired':
        return const Color(0xFF4CAF50); // Green
      default:
        return const Color(0xFF757575); // Grey
    }
  }
}
