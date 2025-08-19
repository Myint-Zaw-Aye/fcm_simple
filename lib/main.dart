import 'package:fcm/firebase_options.dart';
import 'package:fcm/screen/home_page.dart';
import 'package:fcm/screen/product_page.dart';
import 'package:fcm/service/messaging_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';


final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('Notification Message: ${message.data}');
   // --- MODIFICATION START ---
  // Only show local notification if there's no 'notification' payload
  // This means it's a data-only message, and FCM won't auto-display it.
  if (message.notification == null) {
    await MessagingService.initializeBackgroundMessage(); // Ensure local notification setup
    MessagingService.showFlutterNotification(message);
  }
  // --- MODIFICATION END ---
}

Future<void> setupFirebaseMessaging() async {
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage remoteMessage) {
    debugPrint('A new onMessageOpenedApp event was published!');
    final Map<String, dynamic> message = remoteMessage.data;
    MessagingService().onSelectNotification(message,navigatorKey);
  });

  await MessagingService.initialize();
  FirebaseMessaging.onMessage.listen(MessagingService.showFlutterNotification);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
     options: DefaultFirebaseOptions.currentPlatform,
   );
  await setupFirebaseMessaging(); // Move this line BEFORE runApp()
  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Flutter Notification',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomePage(),
      routes: {
        '/product': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as String?;
          return ProductPage(message: args);
        }
      },
    );
  }
}
