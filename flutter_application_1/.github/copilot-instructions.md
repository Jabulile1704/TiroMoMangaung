# Tiro Mo Mangaung (Job Seeker App) - AI Agent Instructions

## Project Overview
A dual-role Flutter mobile app (job seekers + employers) built with Firebase backend. Uses Provider for state management and `go_router` for navigation.

## Architecture & Core Patterns

### State Management (Provider Pattern)
- **3 core providers** in `lib/providers/`: `AuthProvider`, `JobProvider`, `ApplicationProvider`
- All providers extend `ChangeNotifier` and are registered in `main.dart` via `MultiProvider`
- Access pattern: `context.read<AuthProvider>()` for actions, `context.watch<AuthProvider>()` for UI updates
- Example: See `lib/screens/job_seeker/home_screen.dart` line 109+ for typical usage

### Data Models
- **3 main models** in `lib/models/`: `UserModel`, `JobModel`, `ApplicationModel`
- All models have `.fromFirestore()` factory constructors for Firebase document deserialization
- `UserModel` supports dual roles via `userType` field: `'job_seeker'` or `'employer'`
- Role-specific fields are nullable (e.g., `skills` for job seekers, `companyName` for employers)

### Screen Structure
```
screens/
├── auth/           # Login, Register
├── job_seeker/     # Home, Profile, JobDetail, InterviewPrep
└── employer/       # EmployerHome, PostJob
```
- **Tab-based navigation**: Both home screens use internal tabs (not router-based)
- Private widgets prefixed with `_` (e.g., `_HomeTab`, `_SavedJobsTab`) are defined inline in screen files
- Example: `lib/screens/job_seeker/home_screen.dart` contains 4 tab widgets in one 900+ line file

### Firebase Integration
- **Auth flow**: Firebase Auth → Firestore user doc creation → Provider state update
- **Collections**: `users`, `jobs`, `applications`, `saved_jobs`, `notifications`
- **Storage paths**: `profile_pictures/{userId}/`, `company_logos/{employerId}/`, `documents/{userId}/`
- Service layer in `lib/services/`: `StorageService` (images), `NotificationService` (FCM)

## Critical Development Workflows

### Android Build Configuration (IMPORTANT)
**Known issue**: This project requires specific Gradle settings to build successfully:
- **JVM heap limited to 3GB** in `android/gradle.properties`: `org.gradle.jvmargs=-Xmx3G`
- **Desugaring enabled** in `android/app/build.gradle` for `flutter_local_notifications` compatibility
- **Single worker**: `org.gradle.workers.max=1` to prevent OOM errors
- If build fails with memory errors, these settings must be preserved

### Image Handling (Recently Updated)
- **DO NOT use `image_cropper`** - removed due to Android embedding issues
- **Use `extended_image`** for cropping: See `lib/services/storage_service.dart` lines 60-110
- Pattern: Pick with `ImagePicker` → crop with `ExtendedImage` dialog → upload to Firebase Storage
- Example: `StorageService.pickAndCropProfilePicture(context)` for full flow

### Running the App
```bash
# Standard workflow
flutter pub get
flutter run

# Firebase must be configured first (see README.md)
# Requires firebase_options.dart (auto-generated via flutterfire configure)
```

## Project-Specific Conventions

### Error Handling
- Providers use try-catch with `debugPrint()` for logging
- UI shows errors via `_error` field in providers (nullable String)
- Example: `JobProvider._error` displayed in `HomeScreen` via `SnackBar`

### Navigation
- Uses `go_router` with named routes defined in `main.dart` lines 50+
- Route paths: `/login`, `/register`, `/home`, `/employer-home`, `/job/:id`, etc.
- Auth guard: `redirect` callback checks `AuthProvider.isAuthenticated`

### Firestore Queries
- All queries filter by `isActive: true` first (soft delete pattern)
- Jobs ordered by `createdAt` descending (newest first)
- Saved jobs stored in separate collection, not as user field

### UI Components
- Colors centralized in `lib/utils/app_colors.dart`
- Navigation bar: `curved_navigation_bar` package (not standard BottomNavigationBar)
- Cached images: Always use `cached_network_image` for network images, never raw `Image.network`

## External Dependencies & Integration

### Firebase Services
- **App Check**: Debug provider enabled in `main.dart` (switch for production)
- **Messaging**: FCM tokens saved to user docs during auth
- **Storage**: All uploads go through `StorageService` static methods
- Security rules in `firestore.rules` and `storage.rules` (not version controlled here)

### Key Packages
- `provider: ^6.1.1` - State management (not Bloc/Riverpod)
- `go_router: ^13.0.0` - Routing
- `extended_image: ^10.0.1` - Image cropping (replaces image_cropper)
- `firebase_messaging: 15.2.10` - Push notifications
- `shared_preferences: ^2.2.2` - Onboarding state & search history

## Common Tasks

### Adding a New Screen
1. Create in `lib/screens/{role}/` (use StatefulWidget for complex state)
2. Add route to `main.dart` GoRouter configuration
3. Link from existing screen via `context.push('/route')`

### Adding a New Provider
1. Create in `lib/providers/`, extend `ChangeNotifier`
2. Register in `main.dart` MultiProvider
3. Access via `context.read<NewProvider>()` or `context.watch<NewProvider>()`

### Working with Firestore
- Always use model `.fromFirestore()` constructors
- Write back with `.toMap()` or `.toJson()` methods (defined in models)
- Update providers after write operations: `await provider.fetchData(); notifyListeners();`

## Testing & Debugging

### Manual Testing Procedures
**Note**: No automated test suite exists. Testing is done manually against the live Firebase project.

#### Authentication Flow Testing
1. **Registration**
   - Test job seeker registration: email, password, full name, phone number
   - Test employer registration: include company name, registration number, industry type
   - Verify Firestore `users` collection document creation
   - Check FCM token saved to user document for notifications
   
2. **Login & Session**
   - Test email/password login for both user types
   - Verify correct routing: job seekers → `/home`, employers → `/employer-home`
   - Test session persistence across app restarts
   - Verify email verification status display

#### Job Seeker Features Testing
1. **Home Screen (4 tabs: Home, Saved, Applications, Profile)**
   - Home Tab: Verify job listing loads with latest jobs first (`isActive: true`, ordered by `createdAt`)
   - Search: Test filters (location, job type, salary range)
   - Saved Tab: Bookmark jobs, verify `saved_jobs` collection updates
   - Applications Tab: View submitted applications, check status updates
   
2. **Profile Management**
   - Upload profile picture using `ExtendedImage` cropping dialog
   - Update bio, skills (list), work experience, education
   - Upload documents (CV, portfolio) via `StorageService.uploadDocument()`
   - Verify Firebase Storage paths: `profile_pictures/{userId}/`, `documents/{userId}/`

3. **Job Application Flow**
   - Navigate to job detail screen
   - Submit application with required documents
   - Verify `applications` collection document creation
   - Check notification sent to employer

#### Employer Features Testing
1. **Dashboard Tab**
   - View job posting statistics
   - Recent applications overview
   - Verify real-time updates from Firestore

2. **Post Job**
   - Create new job posting with all required fields
   - Upload company logo using `StorageService.pickAndCropCompanyLogo()`
   - Verify job appears in `jobs` collection with `isActive: true`
   - Test job editing and deactivation (soft delete)

3. **Application Management**
   - View applications for posted jobs
   - Update application status (pending, reviewed, accepted, rejected)
   - Verify notification sent to job seeker on status change

#### Image Handling Testing (Critical)
- **Profile Pictures**: Pick → Crop (1:1 aspect ratio) → Upload → Display with `cached_network_image`
- **Company Logos**: Same flow as profile pictures
- **Documents**: Direct file picker → Upload (no cropping)
- Verify cropping dialog works (should use `extended_image`, NOT `image_cropper`)
- Test on Android (check for Gradle/desugaring issues if cropping fails)

#### Notification Testing
1. **Push Notifications (FCM)**
   - Test foreground notifications (app open)
   - Test background notifications (app closed)
   - Verify notification appears in `notifications` collection
   - Test notification tap navigation

2. **In-App Notifications**
   - Job application received (employer)
   - Application status updated (job seeker)
   - New job matches saved search criteria

#### Error Handling Testing
- **Network Errors**: Test with airplane mode, verify error messages via provider `_error` field
- **Validation Errors**: Test form submissions with invalid data
- **Upload Failures**: Test large file uploads, verify error messages
- **Auth Errors**: Test wrong credentials, verify error display via SnackBar

#### Data Consistency Testing
- **Provider State**: Verify `notifyListeners()` updates UI immediately
- **Firestore Real-time**: Test multiple devices, verify updates appear in real-time
- **Soft Delete**: Deactivate jobs/applications, verify they don't appear in listings
- **Saved Jobs**: Test across sessions, verify persistence

### Debugging Tools
- Use `debugPrint()` for logging (never `print()` in production code)
- Check Firestore console for data structure validation
- Monitor Firebase Storage for upload issues
- Use Flutter DevTools for widget inspection and performance profiling

### Known Issues & Workarounds
- **Gradle OOM**: If build fails with memory errors, verify `android/gradle.properties` has `org.gradle.jvmargs=-Xmx3G` and `org.gradle.workers.max=1`
- **Image Cropping**: If cropping dialog crashes, ensure `flutter_local_notifications` desugaring is enabled in `android/app/build.gradle`
- **Firebase Emulator**: Not configured - all testing uses live Firebase project (be cautious with destructive operations)

## Files to Never Modify
- `lib/firebase_options.dart` (auto-generated by flutterfire CLI)
- `android/app/google-services.json` (Firebase config, regenerate if needed)
- `ios/Runner/GoogleService-Info.plist` (Firebase config for iOS)

## Development Environment Notes
- **Primary Development**: Vibe coding workflow with Claude AI Sonnet 4.5 on extended screen
- **No Environment Variables**: Single live Firebase project for all development (no dev/staging/prod separation)
- **No CI/CD**: Manual builds and testing workflow
- **Code Review**: Standards and processes TBD (documentation support will be specified later for PMP, PBS, WBS, User Manual)

