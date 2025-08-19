import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class MessagingService {
  // Firebase Messaging instance
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Local Notifications instance
  static final FlutterLocalNotificationsPlugin _localNotification =
      FlutterLocalNotificationsPlugin();

  // Notification channel for Android
  static late AndroidNotificationChannel channel;

  // Streams for message events
  static Stream<RemoteMessage> get onMessage => FirebaseMessaging.onMessage;
  static Stream<RemoteMessage> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp;

  /// Initialize messaging and notifications (Android)
  static Future<void> initialize() async {
      await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

    print(await _messaging.getToken());
    await _initializeLocalNotification();
    await _configureAndroidChannel();
    await _openInitialScreenFromMessage();
    await _subscribeToTopic("general");
  }

  /// Initialize messaging and notifications (iOS)
  static Future<void> initializeIos() async {
    await _initializeLocalNotification();
  }

  /// Initialize for background message handling
  static Future<void> initializeBackgroundMessage() async {
    await _initializeLocalNotification();
    await _configureAndroidChannel();
  }

  /// Subscribe to a topic
  static Future<void> _subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  /// Initialize local notification settings
  static Future<void> _initializeLocalNotification() async {
    final android = AndroidInitializationSettings('@mipmap/ic_launcher');
    final ios = DarwinInitializationSettings();
    final initsetting = InitializationSettings(android: android, iOS: ios);

    await _localNotification.initialize(initsetting);
    await _messaging
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  /// Configure Android notification channel
  static Future<void> _configureAndroidChannel() async {
    channel = AndroidNotificationChannel(
      "generalfcm",
      "General Notifications",
      description: 'This channel is used for general notifications.',
      importance: Importance.max,
    );

    await _localNotification
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Handle initial message when app is opened from a notification
 static Future<void> _openInitialScreenFromMessage() async {
  RemoteMessage? initialMessage = await _messaging.getInitialMessage();
  if (initialMessage?.data != null) {
    debugPrint("on message ${initialMessage!.data}");
    // Call your navigation logic here if you want to handle
    // app launch from a terminated state
    // For example:
    // MessagingService().onSelectNotification(initialMessage.data, navigatorKey);
    // (Note: navigatorKey would need to be accessible here, possibly passed in
    // or handled differently as static context can't directly use GlobalKey easily.)
  }
}


  /// Show a notification from a Firebase message
  static void showFlutterNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    if (notification == null) return;

    if (!kIsWeb) {
      _localNotification.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            icon: 'launch_background',
            importance: Importance.max,
            priority: Priority.max,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    }
  }

  /// Cancel notification with ID 888
  void cancelNotification() async {
    await _localNotification.cancel(888);
  }

  /// Handle notification selection (for navigation, etc.)
  Future onSelectNotification(Map<String, dynamic> data,navigatorKey) async {
    // Implement navigation or logic here if needed
    if (data['redirect'] == "product") {
      navigatorKey.currentState?.pushNamed(
      '/product',
      arguments: data['message'], // pass the message to ProductPage
    );
    }
  }
}