import 'package:cloud_firestore/cloud_firestore.dart';

class JobModel {
  final String id;
  final String employerId;
  final String title;
  final String location;
  final String jobType; // 'full-time', 'part-time', 'contract', 'internship'
  final double? salaryMin;
  final double? salaryMax;
  final String description;
  final String requirements;
  final String? benefits;
  final DateTime? applicationDeadline;
  final int viewCount;
  final int applicationCount;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Location coordinates for "Jobs Near Me" feature
  final double? latitude;
  final double? longitude;

  // Related employer data (for display)
  final String? companyName;
  final String? companyLogo;
  final bool? isEmployerVerified; // Whether the employer is verified

  JobModel({
    required this.id,
    required this.employerId,
    required this.title,
    required this.location,
    required this.jobType,
    this.salaryMin,
    this.salaryMax,
    required this.description,
    required this.requirements,
    this.benefits,
    this.applicationDeadline,
    required this.viewCount,
    required this.applicationCount,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.latitude,
    this.longitude,
    this.companyName,
    this.companyLogo,
    this.isEmployerVerified,
  });

  factory JobModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return JobModel(
      id: doc.id,
      employerId: data['employerId'] ?? '',
      title: data['title'] ?? '',
      location: data['location'] ?? '',
      jobType: data['jobType'] ?? 'full-time',
      salaryMin: data['salaryMin']?.toDouble(),
      salaryMax: data['salaryMax']?.toDouble(),
      description: data['description'] ?? '',
      requirements: data['requirements'] ?? '',
      benefits: data['benefits'],
      applicationDeadline: data['applicationDeadline'] != null
          ? (data['applicationDeadline'] as Timestamp).toDate()
          : null,
      viewCount: data['viewCount'] ?? 0,
      applicationCount: data['applicationCount'] ?? 0,
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      companyName: data['companyName'],
      companyLogo: data['companyLogo'],
      isEmployerVerified: data['isEmployerVerified'],
    );
  }

  // CopyWith method for easier updates (OPTIMIZATION: prevents manual field copying)
  JobModel copyWith({
    String? id,
    String? employerId,
    String? title,
    String? location,
    String? jobType,
    double? salaryMin,
    double? salaryMax,
    String? description,
    String? requirements,
    String? benefits,
    DateTime? applicationDeadline,
    int? viewCount,
    int? applicationCount,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? latitude,
    double? longitude,
    String? companyName,
    String? companyLogo,
    bool? isEmployerVerified,
  }) {
    return JobModel(
      id: id ?? this.id,
      employerId: employerId ?? this.employerId,
      title: title ?? this.title,
      location: location ?? this.location,
      jobType: jobType ?? this.jobType,
      salaryMin: salaryMin ?? this.salaryMin,
      salaryMax: salaryMax ?? this.salaryMax,
      description: description ?? this.description,
      requirements: requirements ?? this.requirements,
      benefits: benefits ?? this.benefits,
      applicationDeadline: applicationDeadline ?? this.applicationDeadline,
      viewCount: viewCount ?? this.viewCount,
      applicationCount: applicationCount ?? this.applicationCount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      companyName: companyName ?? this.companyName,
      companyLogo: companyLogo ?? this.companyLogo,
      isEmployerVerified: isEmployerVerified ?? this.isEmployerVerified,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'employerId': employerId,
      'title': title,
      'location': location,
      'jobType': jobType,
      if (salaryMin != null) 'salaryMin': salaryMin,
      if (salaryMax != null) 'salaryMax': salaryMax,
      'description': description,
      'requirements': requirements,
      if (benefits != null) 'benefits': benefits,
      if (applicationDeadline != null)
        'applicationDeadline': Timestamp.fromDate(applicationDeadline!),
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'viewCount': viewCount,
      'applicationCount': applicationCount,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  String get salaryRange {
    if (salaryMin != null && salaryMax != null) {
      return 'R${salaryMin!.toInt()} - R${salaryMax!.toInt()}';
    } else if (salaryMin != null) {
      return 'From R${salaryMin!.toInt()}';
    } else if (salaryMax != null) {
      return 'Up to R${salaryMax!.toInt()}';
    }
    return 'Salary not specified';
  }

  String get formattedJobType {
    return jobType
        .split('-')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  /// Calculate distance from user's location to job location
  /// Returns distance in kilometers, or null if coordinates are not available
  double? distanceFromLocation(double? userLatitude, double? userLongitude) {
    if (userLatitude == null || userLongitude == null) return null;
    if (latitude == null || longitude == null) return null;

    // Import geolocator for distance calculation
    final double distanceInMeters = _calculateDistance(
      userLatitude,
      userLongitude,
      latitude!,
      longitude!,
    );

    return distanceInMeters / 1000; // Convert to kilometers
  }

  /// Calculate distance between two coordinates using Haversine formula
  /// Returns distance in meters
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371000; // Earth's radius in meters
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a = _sin(dLat / 2) * _sin(dLat / 2) +
        _cos(_degreesToRadians(lat1)) *
            _cos(_degreesToRadians(lat2)) *
            _sin(dLon / 2) *
            _sin(dLon / 2);

    final double c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));

    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * 3.14159265359 / 180;
  }

  double _sin(double x) => x - (x * x * x) / 6 + (x * x * x * x * x) / 120;
  double _cos(double x) => 1 - (x * x) / 2 + (x * x * x * x) / 24;
  double _sqrt(double x) {
    if (x == 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 10; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }

  double _atan2(double y, double x) {
    if (x > 0) return _atan(y / x);
    if (x < 0 && y >= 0) return _atan(y / x) + 3.14159265359;
    if (x < 0 && y < 0) return _atan(y / x) - 3.14159265359;
    if (x == 0 && y > 0) return 3.14159265359 / 2;
    if (x == 0 && y < 0) return -3.14159265359 / 2;
    return 0;
  }

  double _atan(double x) {
    return x - (x * x * x) / 3 + (x * x * x * x * x) / 5;
  }
}
