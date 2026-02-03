import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/auth_provider.dart';
import 'providers/job_provider.dart';
import 'providers/application_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/email_verification_screen.dart';
import 'screens/job_seeker/home_screen.dart';
import 'screens/job_seeker/application_detail_screen.dart';
import 'screens/employer/employer_home_screen.dart';
import 'screens/employer/employer_application_detail_screen.dart';
import 'screens/employer/employer_job_detail_screen.dart';
import 'screens/job_seeker/job_detail_screen.dart';
import 'screens/job_seeker/profile_screen.dart';
import 'screens/job_seeker/notifications_screen.dart';
import 'screens/employer/post_job_screen.dart';
import 'utils/app_colors.dart';
import 'services/notification_service.dart';
import 'screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // SECURITY: Use debug provider only in debug mode, Play Integrity in production
  await FirebaseAppCheck.instance.activate(
    androidProvider:
        kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
  );

  // OPTIMIZATION: Enable Firestore offline persistence for better UX
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  await NotificationService.initialize();

  runApp(const JobSeekerApp());
}

class JobSeekerApp extends StatelessWidget {
  const JobSeekerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => JobProvider()),
        ChangeNotifierProvider(create: (_) => ApplicationProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return MaterialApp.router(
            title: 'Job Seeker App',
            theme: ThemeData(
              primarySwatch: Colors.blue,
              primaryColor: AppColors.primary,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.primary,
                brightness: Brightness.light,
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 0,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            routerConfig: _createRouter(authProvider),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }

  GoRouter _createRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/login',
      refreshListenable: authProvider,
      redirect: (context, state) async {
        final prefs = await SharedPreferences.getInstance();
        final onboardingComplete =
            prefs.getBool('onboarding_complete') ?? false;
        final isLoggedIn = authProvider.isAuthenticated;
        final isEmailVerified = authProvider.isEmailVerified;
        final isLoadingUserData = authProvider.isLoadingUserData;
        final isLoginRoute = state.matchedLocation == '/login' ||
            state.matchedLocation == '/register';
        final isOnboardingRoute = state.matchedLocation == '/onboarding';
        final isVerificationRoute = state.matchedLocation == '/verify-email';

        // Wait for user data to load before redirecting
        if (isLoadingUserData) {
          return null; // Don't redirect while loading
        }

        // Redirect to onboarding if not complete
        if (!onboardingComplete && !isOnboardingRoute) {
          return '/onboarding';
        }

        // Redirect to login if not authenticated
        if (!isLoggedIn && !isLoginRoute && !isOnboardingRoute) {
          return '/login';
        }

        // Redirect to email verification if logged in but email not verified
        if (isLoggedIn &&
            !isEmailVerified &&
            !isVerificationRoute &&
            !isLoginRoute) {
          return '/verify-email';
        }

        // Redirect to home if logged in, verified, and on auth routes
        if (isLoggedIn && isEmailVerified && isLoginRoute) {
          return authProvider.userType == 'job_seeker'
              ? '/home'
              : '/employer-home';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/verify-email',
          builder: (context, state) => const EmailVerificationScreen(),
        ),
        GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/employer-home',
          builder: (context, state) => const EmployerHomeScreen(),
        ),
        GoRoute(
          path: '/employer/application/:applicationId',
          builder: (context, state) => EmployerApplicationDetailScreen(
            applicationId: state.pathParameters['applicationId']!,
          ),
        ),
        GoRoute(
          path: '/employer/job/:jobId',
          builder: (context, state) => EmployerJobDetailScreen(
            jobId: state.pathParameters['jobId']!,
          ),
        ),
        GoRoute(
          path: '/application/:applicationId',
          builder: (context, state) => ApplicationDetailScreen(
            applicationId: state.pathParameters['applicationId']!,
          ),
        ),
        GoRoute(
          path: '/job/:jobId',
          builder: (context, state) =>
              JobDetailScreen(jobId: state.pathParameters['jobId']!),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: '/post-job',
          builder: (context, state) => PostJobScreen(
            jobId: state.uri.queryParameters['jobId'],
          ),
        ),
      ],
    );
  }
}
