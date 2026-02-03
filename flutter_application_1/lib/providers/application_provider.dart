import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/application_model.dart';
import '../services/notification_service.dart';

class ApplicationProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<ApplicationModel> _myApplications = [];
  List<ApplicationModel> _receivedApplications = []; // For employers
  bool _isLoading = false;
  String? _error;

  List<ApplicationModel> get myApplications => _myApplications;
  List<ApplicationModel> get receivedApplications => _receivedApplications;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchMyApplications(String seekerId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final snapshot = await _firestore
          .collection('applications')
          .where('seekerId', isEqualTo: seekerId)
          .where('isWithdrawn',
              isEqualTo: false) // Exclude withdrawn applications
          .orderBy('appliedAt', descending: true)
          .get();

      // First, get all applications
      List<ApplicationModel> applications = snapshot.docs
          .map((doc) => ApplicationModel.fromFirestore(doc))
          .toList();

      // OPTIMIZATION: Batch fetch job details instead of sequential queries
      if (applications.isNotEmpty) {
        // Get unique job IDs
        final jobIds = applications.map((app) => app.jobId).toSet().toList();
        final jobData = <String, Map<String, dynamic>>{};

        // Fetch jobs in chunks (Firestore whereIn limit is 10)
        for (int i = 0; i < jobIds.length; i += 10) {
          final chunk = jobIds.skip(i).take(10).toList();

          try {
            final jobSnapshot = await _firestore
                .collection('jobs')
                .where(FieldPath.documentId, whereIn: chunk)
                .get();

            for (final doc in jobSnapshot.docs) {
              jobData[doc.id] = doc.data();
            }
          } catch (e) {
            debugPrint('Error fetching job chunk: $e');
          }
        }

        // Enrich applications with job data using copyWith
        for (int i = 0; i < applications.length; i++) {
          final job = jobData[applications[i].jobId];
          if (job != null) {
            applications[i] = applications[i].copyWith(
              jobTitle: job['title'] as String?,
              companyName: job['companyName'] as String?,
            );
          }
        }
      }

      _myApplications = applications;
    } catch (e) {
      _error = 'Failed to fetch applications: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchReceivedApplications(String employerId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // First get all jobs by this employer
      final jobsSnapshot = await _firestore
          .collection('jobs')
          .where('employerId', isEqualTo: employerId)
          .get();

      final jobIds = jobsSnapshot.docs.map((doc) => doc.id).toList();

      if (jobIds.isNotEmpty) {
        List<ApplicationModel> allApplications = [];

        // OPTIMIZATION: Handle Firestore whereIn limit of 10 items
        // Process in chunks to avoid crashes with many job postings
        for (int i = 0; i < jobIds.length; i += 10) {
          final chunk = jobIds.skip(i).take(10).toList();

          final applicationsSnapshot = await _firestore
              .collection('applications')
              .where('jobId', whereIn: chunk)
              .orderBy('appliedAt', descending: true)
              .get();

          allApplications.addAll(applicationsSnapshot.docs
              .map((doc) => ApplicationModel.fromFirestore(doc))
              .toList());
        }

        _receivedApplications = allApplications;
      } else {
        _receivedApplications = [];
      }
    } catch (e) {
      _error = 'Failed to fetch received applications: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> submitApplication({
    required String jobId,
    required String seekerId,
    String? coverLetter,
    List<Map<String, String>>? documents,
  }) async {
    try {
      // Check if already applied
      final existingApplication = await _firestore
          .collection('applications')
          .where('jobId', isEqualTo: jobId)
          .where('seekerId', isEqualTo: seekerId)
          .get();

      if (existingApplication.docs.isNotEmpty) {
        return 'You have already applied to this job';
      }

      final now = DateTime.now();
      final applicationData = ApplicationModel(
        id: '', // Will be set by Firestore
        jobId: jobId,
        seekerId: seekerId,
        coverLetter: coverLetter,
        documents: documents,
        status: 'pending',
        isWithdrawn: false,
        appliedAt: now,
        updatedAt: now,
      );

      await _firestore
          .collection('applications')
          .add(applicationData.toFirestore());

      // Increment application count on job
      await _firestore.collection('jobs').doc(jobId).update({
        'applicationCount': FieldValue.increment(1),
      });

      return null; // Success
    } catch (e) {
      return 'Failed to submit application: $e';
    }
  }

  Future<String?> updateApplicationStatus({
    required String applicationId,
    required String status,
    String? employerNotes,
    String? rejectionReason,
    String? employerFeedback,
  }) async {
    try {
      final updates = <String, dynamic>{
        'status': status,
        'reviewedAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (employerNotes != null) updates['employerNotes'] = employerNotes;
      if (rejectionReason != null) updates['rejectionReason'] = rejectionReason;
      if (employerFeedback != null) {
        updates['employerFeedback'] = employerFeedback;
      }

      await _firestore
          .collection('applications')
          .doc(applicationId)
          .update(updates);

      // Get application details to notify the job seeker
      final appDoc =
          await _firestore.collection('applications').doc(applicationId).get();

      if (appDoc.exists) {
        final appData = appDoc.data()!;
        final seekerId = appData['seekerId'] as String;
        final jobId = appData['jobId'] as String;

        // Get job title for notification
        final jobDoc = await _firestore.collection('jobs').doc(jobId).get();

        final jobTitle = jobDoc.data()?['title'] ?? 'Job Application';

        // Send notification based on status
        String notificationTitle;
        String notificationBody;

        switch (status.toLowerCase()) {
          case 'accepted':
            notificationTitle = 'Application Accepted! 🎉';
            notificationBody =
                'Congratulations! Your application for $jobTitle has been accepted.';
            break;
          case 'rejected':
            notificationTitle = 'Application Update';
            notificationBody =
                'Your application for $jobTitle has been reviewed.';
            break;
          case 'shortlisted':
            notificationTitle = 'You\'ve Been Shortlisted! ⭐';
            notificationBody =
                'Good news! You\'ve been shortlisted for $jobTitle.';
            break;
          case 'interview_scheduled':
            notificationTitle = 'Interview Scheduled! 📅';
            notificationBody = 'An interview has been scheduled for $jobTitle.';
            break;
          default:
            notificationTitle = 'Application Status Updated';
            notificationBody =
                'Your application for $jobTitle has been updated to: $status';
        }

        await NotificationService.sendNotificationToUser(
          userId: seekerId,
          title: notificationTitle,
          body: notificationBody,
          data: {
            'type': 'application_update',
            'id': applicationId,
            'jobId': jobId,
            'status': status,
          },
        );
      }

      return null; // Success
    } catch (e) {
      return 'Failed to update application: $e';
    }
  }

  Future<String?> withdrawApplication(String applicationId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestore.collection('applications').doc(applicationId).update({
        'isWithdrawn': true,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      return null; // Success
    } catch (e) {
      return 'Failed to withdraw application: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> hasAppliedToJob(String seekerId, String jobId) async {
    try {
      final snapshot = await _firestore
          .collection('applications')
          .where('seekerId', isEqualTo: seekerId)
          .where('jobId', isEqualTo: jobId)
          .where('isWithdrawn', isEqualTo: false)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  List<ApplicationModel> getApplicationsByStatus(String status) {
    return _receivedApplications.where((app) => app.status == status).toList();
  }

  // Get withdrawn applications separately
  List<ApplicationModel> getWithdrawnApplications() {
    return _receivedApplications
        .where((app) => app.isWithdrawn && app.status == 'pending')
        .toList();
  }

  // Delete an application permanently
  Future<String?> deleteApplication(String applicationId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestore.collection('applications').doc(applicationId).delete();

      // Remove from local list
      _receivedApplications.removeWhere((app) => app.id == applicationId);

      return null; // Success
    } catch (e) {
      return 'Failed to delete application: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Map<String, int> get applicationStats {
    final stats = <String, int>{
      'pending': 0,
      'shortlisted': 0,
      'rejected': 0,
      'hired': 0,
    };

    for (final app in _receivedApplications) {
      // Don't count withdrawn applications in stats
      if (!app.isWithdrawn) {
        stats[app.status] = (stats[app.status] ?? 0) + 1;
      }
    }

    return stats;
  }
}
