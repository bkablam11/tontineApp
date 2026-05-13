import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _notifications = FlutterLocalNotificationsPlugin();

  // INITIALISATION SIMPLE
  static Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _notifications.initialize(
      // FIX ICI : On ajoute le nom du paramètre 'settings'
      settings: initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Logique au clic
      },
    );
  }

  // ENVOI INSTANTANÉ
  static Future<void> showInstantNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'wari_gbe_id',
      'Wari-Gbê Alertes',
      importance: Importance.max,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      // FIX ICI : Tous les paramètres doivent être NOMMÉS
      id: DateTime.now().millisecond,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
    );
  }
}
