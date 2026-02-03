# Adding Employer Notifications - Implementation Guide

## Overview
This guide shows how to add missing notifications for employers:
1. New application received
2. Application withdrawn by job seeker

## 1. New Application Notification

### When to Send
When a job seeker submits an application for an employer's job posting.

### Implementation

**File**: `lib/providers/application_provider.dart`

**Location**: After line 167 (after creating application document in `submitApplication()` method)

**Add this code:**

```dart
// Send notification to employer about new application
try {
  // Get job and employer details
  final jobDoc = await _firestore.collection('jobs').doc(jobId).get();
  if (jobDoc.exists) {
    final jobData = jobDoc.data()!;
    final employerId = jobData['employerId'] as String;
    final jobTitle = jobData['title'] as String;
    
    // Get applicant name (current user)
    final applicantName = authProvider.currentUser?.fullName ?? 'A job seeker';
    
    // Send notification to employer
    await NotificationService.sendNotificationToUser(
      userId: employerId,
      title: 'New Application Received! 📄',
      body: '$applicantName applied for $jobTitle',
      data: {
        'type': 'new_application',
        'id': docRef.id,
        'jobId': jobId,
        'seekerId': seekerId,
      },
    );
    
    debugPrint('✅ Notified employer about new application');
  }
} catch (e) {
  debugPrint('❌ Error sending employer notification: $e');
  // Don't fail the application submission if notification fails
}
```

### Full Context (Where to Insert)

Find this section in `application_provider.dart` around line 147-170:

```dart
Future<String?> submitApplication({
  required String jobId,
  required String seekerId,
  String? coverLetter,
  List<Map<String, String>>? documents,
}) async {
  try {
    final docRef = await _firestore.collection('applications').add({
      'jobId': jobId,
      'seekerId': seekerId,
      'coverLetter': coverLetter,
      'documents': documents,
      'status': 'pending',
      'isWithdrawn': false,
      'appliedAt': Timestamp.fromDate(DateTime.now()),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });

    // ⬇️ INSERT NEW CODE HERE ⬇️
    // Send notification to employer...
    
    return null; // Success
  } catch (e) {
    return 'Failed to submit application: $e';
  }
}
```

## 2. Application Withdrawn Notification

### When to Send
When a job seeker withdraws their application.

### Implementation

**File**: `lib/providers/application_provider.dart`

**Location**: In `withdrawApplication()` method, before returning (after line 274)

**Add this code:**

```dart
// Send notification to employer about withdrawn application
try {
  // Get application details
  final appDoc = await _firestore.collection('applications').doc(applicationId).get();
  if (appDoc.exists) {
    final appData = appDoc.data()!;
    final jobId = appData['jobId'] as String;
    final seekerId = appData['seekerId'] as String;
    
    // Get job and employer details
    final jobDoc = await _firestore.collection('jobs').doc(jobId).get();
    if (jobDoc.exists) {
      final jobData = jobDoc.data()!;
      final employerId = jobData['employerId'] as String;
      final jobTitle = jobData['title'] as String;
      
      // Get applicant name
      final seekerDoc = await _firestore.collection('users').doc(seekerId).get();
      final seekerName = seekerDoc.data()?['fullName'] ?? 'An applicant';
      
      // Send notification to employer
      await NotificationService.sendNotificationToUser(
        userId: employerId,
        title: 'Application Withdrawn',
        body: '$seekerName has withdrawn their application for $jobTitle',
        data: {
          'type': 'application_withdrawn',
          'id': applicationId,
          'jobId': jobId,
        },
      );
      
      debugPrint('✅ Notified employer about withdrawn application');
    }
  }
} catch (e) {
  debugPrint('❌ Error sending withdrawal notification: $e');
  // Don't fail the withdrawal if notification fails
}
```

### Full Context (Where to Insert)

Find this section in `application_provider.dart` around line 266-277:

```dart
Future<String?> withdrawApplication(String applicationId) async {
  try {
    _isLoading = true;
    notifyListeners();

    await _firestore.collection('applications').doc(applicationId).update({
      'isWithdrawn': true,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
    
    // ⬇️ INSERT NEW CODE HERE ⬇️
    // Send notification to employer...
    
    return null; // Success
  } catch (e) {
    return 'Failed to withdraw application: $e';
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}
```

## 3. Update Notification Service Navigation

**File**: `lib/services/notification_service.dart`

**Location**: `_handleNotificationNavigation()` method (line 169-188)

**Add these cases:**

```dart
case 'new_application':
  // Navigate to application details (employer view)
  debugPrint('Navigate to application: $id');
  // TODO: Implement navigation
  // context.push('/employer/application/$id');
  break;
  
case 'application_withdrawn':
  // Navigate to application details
  debugPrint('Navigate to application: $id');
  // TODO: Implement navigation
  // context.push('/employer/application/$id');
  break;
```

### Full Context

```dart
static void _handleNotificationNavigation(Map<String, dynamic> data) {
  final type = data['type'];
  final id = data['id'];

  switch (type) {
    case 'application_update':
      debugPrint('Navigate to application: $id');
      break;
    case 'new_job':
      debugPrint('Navigate to job: $id');
      break;
    case 'interview_scheduled':
      debugPrint('Navigate to interview: $id');
      break;
    case 'new_application':  // ⬅️ ADD THIS
      debugPrint('Navigate to application: $id');
      break;
    case 'application_withdrawn':  // ⬅️ ADD THIS
      debugPrint('Navigate to application: $id');
      break;
    default:
      debugPrint('Unknown notification type: $type');
  }
}
```

## 4. Testing

### Test New Application Notification

**Prerequisites:**
- Employer logged in on Device 1
- Job seeker logged in on Device 2
- Employer has posted at least one job

**Steps:**
1. On Device 2 (job seeker):
   - Navigate to job listings
   - Tap on employer's job
   - Fill application form
   - Tap "Apply"
2. Wait 2-5 seconds
3. **Expected on Device 1 (employer)**:
   - Notification appears: "New Application Received! 📄"
   - Body: "[Seeker Name] applied for [Job Title]"
   - Tap → navigates to application detail

**Console Logs:**
```
I/flutter: ✅ Notified employer about new application
I/flutter: 📨 Foreground message received: New Application Received! 📄
```

### Test Application Withdrawn Notification

**Prerequisites:**
- Job seeker has submitted an application
- Employer logged in on Device 1
- Job seeker logged in on Device 2

**Steps:**
1. On Device 2 (job seeker):
   - Navigate to "Applications" tab
   - Find the application
   - Tap "Withdraw Application"
   - Confirm withdrawal
2. Wait 2-5 seconds
3. **Expected on Device 1 (employer)**:
   - Notification appears: "Application Withdrawn"
   - Body: "[Seeker Name] has withdrawn their application for [Job Title]"
   - Tap → navigates to application detail (shows withdrawn status)

**Console Logs:**
```
I/flutter: ✅ Notified employer about withdrawn application
I/flutter: 📨 Foreground message received: Application Withdrawn
```

## 5. Implementation Checklist

- [ ] Add new application notification code to `submitApplication()` method
- [ ] Add withdrawal notification code to `withdrawApplication()` method
- [ ] Update notification navigation cases in `NotificationService`
- [ ] Test new application notification (employer receives)
- [ ] Test withdrawal notification (employer receives)
- [ ] Verify notification tap navigation works
- [ ] Check console logs for success messages
- [ ] Verify notifications saved to Firestore `notifications` collection

## 6. Error Handling Notes

Both implementations wrap the notification code in try-catch blocks:

```dart
try {
  // Send notification...
  debugPrint('✅ Notification sent');
} catch (e) {
  debugPrint('❌ Error: $e');
  // Don't fail the main operation
}
```

**Why?**
- Notification failures shouldn't block application submission/withdrawal
- User experience is prioritized (action completes even if notification fails)
- Errors are logged for debugging

## 7. Firestore Data Structure

### New Application Notification Document
```javascript
{
  "userId": "employer123",
  "title": "New Application Received! 📄",
  "body": "John Doe applied for Software Developer",
  "data": {
    "type": "new_application",
    "id": "application456",
    "jobId": "job789",
    "seekerId": "seeker012"
  },
  "read": false,
  "createdAt": Timestamp
}
```

### Application Withdrawn Notification Document
```javascript
{
  "userId": "employer123",
  "title": "Application Withdrawn",
  "body": "Jane Smith has withdrawn their application for Marketing Manager",
  "data": {
    "type": "application_withdrawn",
    "id": "application456",
    "jobId": "job789"
  },
  "read": false,
  "createdAt": Timestamp
}
```

## 8. Optional: Notification Preferences

Consider adding user preferences for notification types:

**Firestore Schema:**
```javascript
users/{userId} {
  ...existing fields...,
  "notificationPreferences": {
    "newApplications": true,      // Employer only
    "applicationUpdates": true,   // Job seeker only
    "newJobs": true,              // Job seeker only
    "applicationWithdrawn": true  // Employer only
  }
}
```

**Check before sending:**
```dart
final userDoc = await _firestore.collection('users').doc(employerId).get();
final prefs = userDoc.data()?['notificationPreferences'];

if (prefs?['newApplications'] == true) {
  // Send notification
}
```

## 9. Production Considerations

1. **Rate Limiting**: Prevent spam by limiting notifications per user per hour
2. **Batch Sending**: Group multiple applications into one notification
3. **Quiet Hours**: Don't send notifications during night hours (21:00-07:00)
4. **Unread Count**: Add badge to app icon showing unread notifications

## Summary

After implementing these changes:
- ✅ Employers receive notifications when job seekers apply
- ✅ Employers receive notifications when applications are withdrawn
- ✅ All notifications are saved to Firestore for in-app notification center
- ✅ Notification tap navigation is configured (needs route implementation)

Total changes: **2 files, ~60 lines of code**

Happy coding! 🚀
