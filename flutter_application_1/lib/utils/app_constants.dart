// Application-wide constants to prevent typos and ensure consistency

/// Application status constants
class ApplicationStatus {
  static const String pending = 'pending';
  static const String shortlisted = 'shortlisted';
  static const String rejected = 'rejected';
  static const String hired = 'hired';
  static const String interviewScheduled = 'interview_scheduled';

  /// Get all valid status values
  static List<String> get allStatuses => [
        pending,
        shortlisted,
        rejected,
        hired,
        interviewScheduled,
      ];
}

/// User type constants
class UserType {
  static const String jobSeeker = 'job_seeker';
  static const String employer = 'employer';

  /// Get all valid user types
  static List<String> get allTypes => [jobSeeker, employer];
}

/// Employer verification status constants
class VerificationStatus {
  static const String pending = 'pending';
  static const String verified = 'verified';
  static const String rejected = 'rejected';

  /// Get all valid verification statuses
  static List<String> get allStatuses => [pending, verified, rejected];
}

/// Job type constants
class JobType {
  static const String fullTime = 'full-time';
  static const String partTime = 'part-time';
  static const String contract = 'contract';
  static const String internship = 'internship';

  /// Get all valid job types
  static List<String> get allTypes => [
        fullTime,
        partTime,
        contract,
        internship,
      ];

  /// Get display name for job type
  static String getDisplayName(String jobType) {
    switch (jobType) {
      case fullTime:
        return 'Full-Time';
      case partTime:
        return 'Part-Time';
      case contract:
        return 'Contract';
      case internship:
        return 'Internship';
      default:
        return jobType;
    }
  }
}

/// Notification type constants
class NotificationType {
  static const String applicationUpdate = 'application_update';
  static const String newApplication = 'new_application';
  static const String jobPosted = 'job_posted';
  static const String verificationUpdate = 'verification_update';
}

/// Firebase collection names
class FirebaseCollections {
  static const String users = 'users';
  static const String jobs = 'jobs';
  static const String applications = 'applications';
  static const String savedJobs = 'saved_jobs';
  static const String notifications = 'notifications';
}

/// Firestore query limits
class FirestoreConstants {
  /// Maximum items allowed in Firestore whereIn queries
  static const int whereInLimit = 10;

  /// Default pagination limit
  static const int defaultPageSize = 20;
}

/// App-wide configuration
class AppConfig {
  /// Maximum distance for "Jobs Near Me" in kilometers
  static const double maxDistanceKm = 50.0;

  /// Cache timeout duration
  static const Duration cacheTimeout = Duration(minutes: 5);

  /// Maximum file upload size in MB
  static const int maxFileUploadSizeMB = 5;

  /// Supported document file extensions
  static const List<String> supportedDocExtensions = [
    'pdf',
    'doc',
    'docx',
  ];

  /// Supported image file extensions
  static const List<String> supportedImageExtensions = [
    'jpg',
    'jpeg',
    'png',
  ];
}

/// Firebase Storage paths
class StoragePaths {
  static String profilePicture(String userId) => 'profile_pictures/$userId/';
  static String companyLogo(String employerId) => 'company_logos/$employerId/';
  static String document(String userId) => 'documents/$userId/';
}
