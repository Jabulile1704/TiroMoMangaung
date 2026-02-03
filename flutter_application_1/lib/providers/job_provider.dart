import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/job_model.dart';
import '../services/notification_service.dart';

class JobProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<JobModel> _jobs = [];
  List<JobModel> _savedJobs = [];
  List<JobModel> _myJobs = []; // For employers
  bool _isLoading = false;
  String? _error;

  // Search filters
  String _searchQuery = '';
  String _locationFilter = '';
  String _jobTypeFilter = '';
  double? _minSalary;
  double? _maxSalary;

  // User location for "Jobs Near Me" feature
  double? _userLatitude;
  double? _userLongitude;
  double? _maxDistance; // Maximum distance in kilometers

  List<JobModel> get jobs => _jobs;
  List<JobModel> get savedJobs => _savedJobs;
  List<JobModel> get myJobs => _myJobs;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String get locationFilter => _locationFilter;
  String get jobTypeFilter => _jobTypeFilter;
  double? get minSalary => _minSalary;
  double? get maxSalary => _maxSalary;
  double? get userLatitude => _userLatitude;
  double? get userLongitude => _userLongitude;
  double? get maxDistance => _maxDistance;

  /// Set user location for distance-based filtering
  Future<void> setUserLocation(double latitude, double longitude) async {
    _userLatitude = latitude;
    _userLongitude = longitude;
    notifyListeners();
  }

  /// Clear user location
  void clearUserLocation() {
    _userLatitude = null;
    _userLongitude = null;
    _maxDistance = null;
    notifyListeners();
  }

  Future<void> fetchJobs() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      Query query = _firestore
          .collection('jobs')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true);

      final snapshot = await query.get();

      _jobs = snapshot.docs.map((doc) => JobModel.fromFirestore(doc)).toList();

      // Enrich jobs with employer verification status
      await _enrichJobsWithEmployerData(_jobs);

      // Apply client-side filters for complex queries
      if (_searchQuery.isNotEmpty) {
        _jobs = _jobs
            .where((job) =>
                job.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                job.description
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ||
                (job.companyName
                        ?.toLowerCase()
                        .contains(_searchQuery.toLowerCase()) ??
                    false))
            .toList();
      }

      if (_locationFilter.isNotEmpty) {
        _jobs = _jobs
            .where((job) => job.location
                .toLowerCase()
                .contains(_locationFilter.toLowerCase()))
            .toList();
      }

      // Apply job type filter (client-side to avoid Firestore index requirement)
      if (_jobTypeFilter.isNotEmpty) {
        _jobs = _jobs.where((job) => job.jobType == _jobTypeFilter).toList();
      }

      if (_minSalary != null) {
        _jobs = _jobs
            .where(
                (job) => job.salaryMin != null && job.salaryMin! >= _minSalary!)
            .toList();
      }

      if (_maxSalary != null) {
        _jobs = _jobs
            .where(
                (job) => job.salaryMax != null && job.salaryMax! <= _maxSalary!)
            .toList();
      }

      // Apply distance filtering if user location is set
      if (_userLatitude != null && _userLongitude != null) {
        // Filter jobs by distance if maxDistance is set
        if (_maxDistance != null) {
          _jobs = _jobs.where((job) {
            final distance =
                job.distanceFromLocation(_userLatitude, _userLongitude);
            return distance != null && distance <= _maxDistance!;
          }).toList();
        }

        // Sort jobs by distance (nearest first), but prioritize verified employers
        _jobs.sort((a, b) {
          // First priority: Verified employers
          final aVerified = a.isEmployerVerified ?? false;
          final bVerified = b.isEmployerVerified ?? false;
          if (aVerified && !bVerified) return -1;
          if (!aVerified && bVerified) return 1;

          // Second priority: Distance
          final distanceA =
              a.distanceFromLocation(_userLatitude, _userLongitude);
          final distanceB =
              b.distanceFromLocation(_userLatitude, _userLongitude);

          // Jobs without coordinates go to the end
          if (distanceA == null && distanceB == null) return 0;
          if (distanceA == null) return 1;
          if (distanceB == null) return -1;

          return distanceA.compareTo(distanceB);
        });
      } else {
        // Sort by verification status first, then by creation date
        _jobs.sort((a, b) {
          final aVerified = a.isEmployerVerified ?? false;
          final bVerified = b.isEmployerVerified ?? false;
          if (aVerified && !bVerified) return -1;
          if (!aVerified && bVerified) return 1;

          // If same verification status, sort by creation date (newest first)
          return b.createdAt.compareTo(a.createdAt);
        });
      }
    } catch (e) {
      _error = 'Failed to fetch jobs: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchEmployerJobs(String employerId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final snapshot = await _firestore
          .collection('jobs')
          .where('employerId', isEqualTo: employerId)
          .orderBy('createdAt', descending: true)
          .get();

      _myJobs =
          snapshot.docs.map((doc) => JobModel.fromFirestore(doc)).toList();
    } catch (e) {
      _error = 'Failed to fetch your jobs: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Enrich jobs with employer verification status
  Future<void> _enrichJobsWithEmployerData(List<JobModel> jobs) async {
    try {
      // Get unique employer IDs
      final employerIds = jobs.map((job) => job.employerId).toSet().toList();

      if (employerIds.isEmpty) return;

      // Fetch employer data in parallel (OPTIMIZED: was sequential before)
      final employerData = <String, bool>{};

      // Create futures for all employer fetches
      final employerFutures = employerIds.map((employerId) {
        return _firestore.collection('users').doc(employerId).get().then((doc) {
          if (doc.exists) {
            final data = doc.data() as Map<String, dynamic>;
            final verificationStatus = data['verificationStatus'] as String?;
            return MapEntry(employerId, verificationStatus == 'verified');
          }
          return MapEntry(employerId, false);
        }).catchError((e) {
          debugPrint('Error fetching employer $employerId: $e');
          return MapEntry(employerId, false);
        });
      }).toList();

      // Wait for all queries to complete in parallel
      final results = await Future.wait(employerFutures);

      // Convert results to map
      for (final entry in results) {
        employerData[entry.key] = entry.value;
      }

      // Update jobs with verification status (OPTIMIZED: using copyWith)
      for (int i = 0; i < jobs.length; i++) {
        final isVerified = employerData[jobs[i].employerId] ?? false;
        jobs[i] = jobs[i].copyWith(isEmployerVerified: isVerified);
      }
    } catch (e) {
      debugPrint('Error enriching jobs with employer data: $e');
    }
  }

  Future<void> fetchSavedJobs(String seekerId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final savedSnapshot = await _firestore
          .collection('saved_jobs')
          .where('seekerId', isEqualTo: seekerId)
          .get();

      final jobIds =
          savedSnapshot.docs.map((doc) => doc['jobId'] as String).toList();

      if (jobIds.isNotEmpty) {
        final jobsSnapshot = await _firestore
            .collection('jobs')
            .where(FieldPath.documentId, whereIn: jobIds)
            .get();

        _savedJobs = jobsSnapshot.docs
            .map((doc) => JobModel.fromFirestore(doc))
            .toList();
      } else {
        _savedJobs = [];
      }
    } catch (e) {
      _error = 'Failed to fetch saved jobs: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<JobModel?> getJobById(String jobId) async {
    try {
      final doc = await _firestore.collection('jobs').doc(jobId).get();
      if (doc.exists) {
        // Increment view count
        await _firestore.collection('jobs').doc(jobId).update({
          'viewCount': FieldValue.increment(1),
        });

        return JobModel.fromFirestore(doc);
      }
    } catch (e) {
      debugPrint('Error fetching job: $e');
    }
    return null;
  }

  Future<String?> createJob({
    required String employerId,
    required String title,
    required String location,
    required String jobType,
    required String description,
    required String requirements,
    String? benefits,
    double? salaryMin,
    double? salaryMax,
    DateTime? applicationDeadline,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final now = DateTime.now();
      final jobData = JobModel(
        id: '', // Will be set by Firestore
        employerId: employerId,
        title: title,
        location: location,
        jobType: jobType,
        salaryMin: salaryMin,
        salaryMax: salaryMax,
        description: description,
        requirements: requirements,
        benefits: benefits,
        applicationDeadline: applicationDeadline,
        latitude: latitude,
        longitude: longitude,
        viewCount: 0,
        applicationCount: 0,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      final docRef =
          await _firestore.collection('jobs').add(jobData.toFirestore());

      // Notify all job seekers about the new job
      _notifyJobSeekers(
        jobId: docRef.id,
        jobTitle: title,
        jobLocation: location,
      );

      return null; // Success
    } catch (e) {
      return 'Failed to create job: $e';
    }
  }

  Future<String?> updateJob({
    required String jobId,
    String? title,
    String? location,
    String? jobType,
    String? description,
    String? requirements,
    String? benefits,
    double? salaryMin,
    double? salaryMax,
    DateTime? applicationDeadline,
    bool? isActive,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (title != null) updates['title'] = title;
      if (location != null) updates['location'] = location;
      if (jobType != null) updates['jobType'] = jobType;
      if (description != null) updates['description'] = description;
      if (requirements != null) updates['requirements'] = requirements;
      if (benefits != null) updates['benefits'] = benefits;
      if (salaryMin != null) updates['salaryMin'] = salaryMin;
      if (salaryMax != null) updates['salaryMax'] = salaryMax;
      if (applicationDeadline != null) {
        updates['applicationDeadline'] =
            Timestamp.fromDate(applicationDeadline);
      }
      if (isActive != null) updates['isActive'] = isActive;
      if (latitude != null) updates['latitude'] = latitude;
      if (longitude != null) updates['longitude'] = longitude;

      await _firestore.collection('jobs').doc(jobId).update(updates);
      return null; // Success
    } catch (e) {
      return 'Failed to update job: $e';
    }
  }

  Future<String?> deleteJob(String jobId) async {
    try {
      await _firestore.collection('jobs').doc(jobId).delete();
      return null; // Success
    } catch (e) {
      return 'Failed to delete job: $e';
    }
  }

  Future<String?> saveJob(String seekerId, String jobId) async {
    try {
      await _firestore.collection('saved_jobs').add({
        'seekerId': seekerId,
        'jobId': jobId,
        'savedAt': Timestamp.fromDate(DateTime.now()),
      });
      return null; // Success
    } catch (e) {
      return 'Failed to save job: $e';
    }
  }

  Future<String?> unsaveJob(String seekerId, String jobId) async {
    try {
      final snapshot = await _firestore
          .collection('saved_jobs')
          .where('seekerId', isEqualTo: seekerId)
          .where('jobId', isEqualTo: jobId)
          .get();

      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
      return null; // Success
    } catch (e) {
      return 'Failed to unsave job: $e';
    }
  }

  Future<bool> isJobSaved(String seekerId, String jobId) async {
    try {
      final snapshot = await _firestore
          .collection('saved_jobs')
          .where('seekerId', isEqualTo: seekerId)
          .where('jobId', isEqualTo: jobId)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  void updateSearchFilters({
    String? searchQuery,
    String? locationFilter,
    String? jobTypeFilter,
    double? minSalary,
    double? maxSalary,
    double? maxDistance,
  }) {
    _searchQuery = searchQuery ?? _searchQuery;
    _locationFilter = locationFilter ?? _locationFilter;
    _jobTypeFilter = jobTypeFilter ?? _jobTypeFilter;
    _minSalary = minSalary;
    _maxSalary = maxSalary;
    _maxDistance = maxDistance;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _locationFilter = '';
    _jobTypeFilter = '';
    _minSalary = null;
    _maxSalary = null;
    _maxDistance = null;
    notifyListeners();
  }

  // Notify all job seekers about new job posting
  Future<void> _notifyJobSeekers({
    required String jobId,
    required String jobTitle,
    required String jobLocation,
  }) async {
    try {
      // Get all job seekers
      final jobSeekersSnapshot = await _firestore
          .collection('users')
          .where('userType', isEqualTo: 'job_seeker')
          .get();

      // Send notification to each job seeker
      for (final doc in jobSeekersSnapshot.docs) {
        await NotificationService.sendNotificationToUser(
          userId: doc.id,
          title: 'New Job Posted! 🎉',
          body: '$jobTitle in $jobLocation',
          data: {
            'type': 'new_job',
            'id': jobId,
            'title': jobTitle,
            'location': jobLocation,
          },
        );
      }

      debugPrint(
          '✅ Notified ${jobSeekersSnapshot.docs.length} job seekers about new job');
    } catch (e) {
      debugPrint('❌ Error notifying job seekers: $e');
    }
  }
}
