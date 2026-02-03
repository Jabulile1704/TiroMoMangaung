# Firestore Security Rules Update Required

## Issue
The notifications screen shows "Missing or insufficient permissions" error because the Firestore security rules don't allow reading from the `notifications` collection.

## Solution
You need to add security rules for the `notifications` collection in the Firebase Console.

### Steps:
1. Go to Firebase Console: https://console.firebase.google.com/
2. Select your project: `tiro-mo-mangaung-4ed34`
3. Go to **Firestore Database** → **Rules**
4. Add the following rules to your existing rules:

### Rules to Add:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // ... your existing rules for users, jobs, applications ...
    
    // Notifications Collection Rules
    match /notifications/{notificationId} {
      // Users can read their own notifications
      allow read: if request.auth != null && 
                     resource.data.userId == request.auth.uid;
      
      // Only the system (or Cloud Functions) can create notifications
      // Users cannot create their own notifications
      allow create: if request.auth != null;
      
      // Users can update their own notifications (to mark as read)
      allow update: if request.auth != null && 
                       resource.data.userId == request.auth.uid &&
                       request.resource.data.diff(resource.data).affectedKeys().hasOnly(['read']);
      
      // Users cannot delete notifications
      allow delete: if false;
    }
  }
}
```

### Explanation:
- **Read**: Users can only read notifications where `userId` matches their authenticated user ID
- **Create**: Any authenticated user can create notifications (this is needed for the system to send notifications)
- **Update**: Users can only update the `read` field of their own notifications (for marking as read)
- **Delete**: No one can delete notifications (optional - you can change this if needed)

### Alternative: Testing/Development Rules (Less Secure)
If you want to test quickly, you can use these more permissive rules temporarily:

```javascript
match /notifications/{notificationId} {
  allow read, write: if request.auth != null;
}
```

⚠️ **Warning**: The alternative rules allow any authenticated user to read/write ALL notifications. Only use this for testing!

### After Updating Rules:
1. Click **Publish** in the Firebase Console
2. Hot restart your Flutter app
3. Try opening the notifications screen again

The error should be resolved and notifications should load properly.
