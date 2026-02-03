# Quick Reference: Using App Constants

This guide shows how to migrate from hardcoded strings to type-safe constants.

## 📚 Import Statement

```dart
import 'package:tiro_mo_mangaung/utils/app_constants.dart';
```

---

## 🔄 Migration Examples

### Application Status

```dart
// ❌ Before (hardcoded strings)
if (application.status == 'pending') { ... }
if (application.status == 'shortlisted') { ... }

// ✅ After (using constants)
if (application.status == ApplicationStatus.pending) { ... }
if (application.status == ApplicationStatus.shortlisted) { ... }
```

### User Type

```dart
// ❌ Before
if (user.userType == 'job_seeker') { ... }
final userData = UserModel(userType: 'employer', ...);

// ✅ After
if (user.userType == UserType.jobSeeker) { ... }
final userData = UserModel(userType: UserType.employer, ...);
```

### Verification Status

```dart
// ❌ Before
if (employer.verificationStatus == 'verified') { ... }
updates['verificationStatus'] = 'pending';

// ✅ After
if (employer.verificationStatus == VerificationStatus.verified) { ... }
updates['verificationStatus'] = VerificationStatus.pending;
```

### Job Type

```dart
// ❌ Before
final job = JobModel(jobType: 'full-time', ...);

// ✅ After
final job = JobModel(jobType: JobType.fullTime, ...);

// Get display name
final displayName = JobType.getDisplayName(job.jobType);
// Returns: "Full-Time"
```

### Firebase Collections

```dart
// ❌ Before
await _firestore.collection('users').doc(userId).get();
await _firestore.collection('applications').where(...);

// ✅ After
await _firestore.collection(FirebaseCollections.users).doc(userId).get();
await _firestore.collection(FirebaseCollections.applications).where(...);
```

### Firestore Limits

```dart
// ❌ Before
for (int i = 0; i < ids.length; i += 10) { ... }

// ✅ After
for (int i = 0; i < ids.length; i += FirestoreConstants.whereInLimit) { ... }
```

### Firebase Storage Paths

```dart
// ❌ Before
final path = 'profile_pictures/$userId/profile.jpg';
final path = 'company_logos/$employerId/logo.png';

// ✅ After
final path = '${StoragePaths.profilePicture(userId)}profile.jpg';
final path = '${StoragePaths.companyLogo(employerId)}logo.png';
```

### Notification Types

```dart
// ❌ Before
data['type'] = 'application_update';
if (data['type'] == 'new_application') { ... }

// ✅ After
data['type'] = NotificationType.applicationUpdate;
if (data['type'] == NotificationType.newApplication) { ... }
```

### App Configuration

```dart
// ❌ Before
if (fileSize > 5 * 1024 * 1024) { ... }  // 5MB
final timeout = Duration(minutes: 5);

// ✅ After
if (fileSize > AppConfig.maxFileUploadSizeMB * 1024 * 1024) { ... }
final timeout = AppConfig.cacheTimeout;
```

---

## 🎯 Benefits of Using Constants

### 1. **Type Safety**
```dart
// Typos caught at compile time
status = ApplicationStatus.pendign;  // ❌ Compile error!
status = ApplicationStatus.pending;  // ✅ Works
```

### 2. **IDE Autocomplete**
```dart
// Type "ApplicationStatus." and get all options
ApplicationStatus.
  ├─ pending
  ├─ shortlisted
  ├─ rejected
  ├─ hired
  └─ interviewScheduled
```

### 3. **Refactoring Safety**
```dart
// Changing a constant updates everywhere automatically
// No need to find/replace strings across files
```

### 4. **Documentation**
```dart
// Constants are self-documenting
ApplicationStatus.allStatuses  // Lists all valid statuses
JobType.getDisplayName(type)   // Converts to user-friendly name
```

---

## 📋 Complete Constants Reference

### ApplicationStatus
- `pending`
- `shortlisted`
- `rejected`
- `hired`
- `interviewScheduled`
- `allStatuses` (list of all)

### UserType
- `jobSeeker`
- `employer`
- `allTypes` (list of all)

### VerificationStatus
- `pending`
- `verified`
- `rejected`
- `allStatuses` (list of all)

### JobType
- `fullTime`
- `partTime`
- `contract`
- `internship`
- `allTypes` (list of all)
- `getDisplayName(jobType)` (helper method)

### NotificationType
- `applicationUpdate`
- `newApplication`
- `jobPosted`
- `verificationUpdate`

### FirebaseCollections
- `users`
- `jobs`
- `applications`
- `savedJobs`
- `notifications`

### FirestoreConstants
- `whereInLimit = 10`
- `defaultPageSize = 20`

### AppConfig
- `maxDistanceKm = 50.0`
- `cacheTimeout = Duration(minutes: 5)`
- `maxFileUploadSizeMB = 5`
- `supportedDocExtensions = ['pdf', 'doc', 'docx']`
- `supportedImageExtensions = ['jpg', 'jpeg', 'png']`

### StoragePaths (methods)
- `profilePicture(userId)` → `'profile_pictures/{userId}/'`
- `companyLogo(employerId)` → `'company_logos/{employerId}/'`
- `document(userId)` → `'documents/{userId}/'`

---

## 🔍 Finding Where to Replace Strings

### Search for these patterns:
1. `'pending'`, `'shortlisted'`, `'rejected'`, `'hired'`
2. `'job_seeker'`, `'employer'`
3. `'verified'`, `'pending'`, `'rejected'`
4. `'full-time'`, `'part-time'`, `'contract'`, `'internship'`
5. `collection('users')`, `collection('jobs')`, etc.
6. Hard-coded `10` in chunking loops
7. Hard-coded paths like `'profile_pictures/'`

### Recommended approach:
1. Start with provider files (most critical)
2. Then model files
3. Then screen files
4. Test after each file

---

## ✅ Testing Checklist

After migrating to constants:

- [ ] All imports added where needed
- [ ] No typos in constant names (IDE will catch)
- [ ] App compiles without errors
- [ ] Test login/registration (UserType)
- [ ] Test application submission (ApplicationStatus)
- [ ] Test employer verification (VerificationStatus)
- [ ] Test job posting (JobType)
- [ ] Test file uploads (StoragePaths, AppConfig)

---

**Note:** The current codebase already uses some hardcoded strings. You can migrate them gradually or all at once. The constants are ready to use!
