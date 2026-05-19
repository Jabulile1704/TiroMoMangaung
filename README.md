# Job Seeker App - Flutter + Firebase

A comprehensive job seeker and employer mobile application built with Flutter and Firebase.

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (>=3.10.0)
- Firebase CLI
- Android Studio / VS Code
- Git

### 1. Clone the Repository
```bash
git clone <your-repo-url>
cd job_seeker_app
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Firebase Setup

#### Install Firebase CLI
```bash
npm install -g firebase-tools
firebase login
```

#### Initialize Firebase
```bash
firebase init
```
Select:
- Firestore
- Authentication
- Storage
- Functions (optional)

#### Configure Flutter for Firebase
```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

### 4. Configure Firebase Authentication
In Firebase Console:
1. Go to Authentication > Sign-in method
2. Enable Email/Password authentication
3. Configure authorized domains

### 5. Set up Firestore Database
1. Create Firestore database in production mode
2. Apply the security rules from `firestore.rules`
3. Create initial indexes if needed

### 6. Configure Firebase Storage
1. Set up Firebase Storage
2. Apply the security rules from `storage.rules`

### 7. Update Firebase Configuration
Update `lib/firebase_options.dart` with your project configuration.

### 8. Run the Application
```bash
flutter run
```

## 📱 Features

### Job Seekers
- ✅ User registration and authentication
- ✅ Complete profile management with skills and experience
- ✅ Job search with advanced filters
- ✅ Save/bookmark jobs
- ✅ Job application tracking
- ✅ Notifications for application updates
- ✅ Document upload (CV, portfolio)

### Employers
- ✅ Company registration and verification
- ✅ Job posting management
- ✅ Application review and candidate management
- ✅ Interview scheduling
- ✅ Analytics and reporting

### Technical Features
- ✅ Firebase Authentication
- ✅ Firestore real-time database
- ✅ Firebase Storage for file uploads
- ✅ Push notifications
- ✅ Offline support
- ✅ Security rules implementation

## 🏗️ Architecture

```
lib/
├── main.dart
├── models/
│   ├── user_model.dart
│   ├── job_model.dart
│   └── application_model.dart
├── providers/
│   ├── auth_provider.dart
│   ├── job_provider.dart
│   ├── application_provider.dart
│   └── notification_provider.dart
├── screens/
│   ├── auth/
│   ├── job_seeker/
│   └── employer/
├── widgets/
│   ├── job_card.dart
│   └── search_filters.dart
└── utils/
    └── app_colors.dart
```

## 🔐 Security

The app implements comprehensive security rules:
- User data protection
- Role-based access control
- File upload restrictions
- API rate limiting

## 📊 Database Collections

### Core Collections
- `users` - User profiles and authentication data
- `jobs` - Job postings and details
- `applications` - Job applications and status
- `companies` - Company profiles and verification

### Feature Collections
- `saved_jobs` - User's bookmarked jobs
- `notifications` - System notifications
- `documents` - User uploaded documents
- `job_alerts` - Custom job alert preferences
- `messages` - In-app messaging
- `interviews` - Interview scheduling

## 🛠️ Development

### Adding New Features
1. Create the model in `models/`
2. Add provider logic in `providers/`
3. Create UI screens in `screens/`
4. Update security rules if needed

### Testing
```bash
flutter test
```

### Building for Production---
