import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';

// Handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling background message: ${message.messageId}');
}

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Initialize notifications
  static Future<void> initialize() async {
    try {
      // Request permission
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ User granted notification permission');
      } else {
        debugPrint('❌ User declined notification permission');
        return;
      }

      // Initialize local notifications
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Get and save FCM token
      final token = await _messaging.getToken();
      if (token != null) {
        debugPrint('📱 FCM Token: $token');
        // TODO: Save token to Firestore for the current user
        // await _saveTokenToFirestore(token);
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        debugPrint('🔄 FCM Token refreshed: $newToken');
        // TODO: Update token in Firestore
        // _saveTokenToFirestore(newToken);
      });

      // Set up message handlers
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint(
            '📨 Foreground message received: ${message.notification?.title}');

        if (message.notification != null) {
          _showLocalNotification(
            title: message.notification!.title ?? 'New Notification',
            body: message.notification!.body ?? '',
            payload: message.data.toString(),
          );
        }
      });

      // Handle notification opened app
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint(
            '📬 Notification opened app: ${message.notification?.title}');
        _handleNotificationNavigation(message.data);
      });

      // Check if app was opened from a notification
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint(
            '🚀 App opened from notification: ${initialMessage.notification?.title}');
        _handleNotificationNavigation(initialMessage.data);
      }
    } catch (e) {
      debugPrint('❌ Error initializing notifications: $e');
    }
  }

  // Save FCM token to Firestore
  static Future<void> saveTokenToFirestore(String userId, String token) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Token saved to Firestore');
    } catch (e) {
      debugPrint('❌ Error saving token: $e');
    }
  }

  // Show local notification
  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'tiro_channel',
      'Tiro Mo Mangaung',
      channelDescription: 'Tiro Mo Mangaung job notifications',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      color: Color(0xFFFF6B35),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      details,
      payload: payload,
    );
  }

  // Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    if (response.payload != null) {
      _handleNotificationNavigation(_parsePayload(response.payload!));
    }
  }

  // Handle navigation based on notification data
  static void _handleNotificationNavigation(Map<String, dynamic> data) {
    // TODO: Implement navigation based on notification type
    final type = data['type'];
    final id = data['id'];

    switch (type) {
      case 'application_update':
        // Navigate to application details
        debugPrint('Navigate to application: $id');
        break;
      case 'new_job':
        // Navigate to job details
        debugPrint('Navigate to job: $id');
        break;
      case 'interview_scheduled':
        // Navigate to interviews
        debugPrint('Navigate to interview: $id');
        break;
      default:
        debugPrint('Unknown notification type: $type');
    }
  }

  // Parse string payload to map
  static Map<String, dynamic> _parsePayload(String payload) {
    // Simple parsing, adjust based on your payload format
    return {};
  }

  // Send notification to specific user (call from Cloud Functions)
  static Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      // Get user's FCM tokens
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      final tokens = List<String>.from(userDoc.data()?['fcmTokens'] ?? []);

      if (tokens.isEmpty) {
        debugPrint('No FCM tokens found for user: $userId');
        return;
      }

      // Save notification to Firestore (for in-app notification center)
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'data': data ?? {},
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Note: Actual push notification sending should be done from Cloud Functions
      // This is just storing the notification in Firestore
      debugPrint('✅ Notification saved to Firestore for user: $userId');
    } catch (e) {
      debugPrint('❌ Error sending notification: $e');
    }
  }

  // Get unread notification count
  static Stream<int> getUnreadCount(String userId) {
    return FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.where((doc) => doc.data()['read'] == false).length);
  }

  // Mark notification as read
  static Future<void> markAsRead(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }
}
