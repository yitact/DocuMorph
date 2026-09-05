import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';

final logger = Logger();

/// Service for local push notifications
class NotificationService {
  late FlutterLocalNotificationsPlugin _notificationsPlugin;
  bool _isInitialized = false;

  /// Initialize notifications
  Future<void> initialize() async {
    try {
      _notificationsPlugin = FlutterLocalNotificationsPlugin();

      // Android initialization settings
      const androidInitializationSettings =
          AndroidInitializationSettings('@mipmap/launcher_icon');

      // iOS initialization settings
      final iOSInitializationSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        onDidReceiveLocalNotification: _onDidReceiveLocalNotification,
      );

      final initializationSettings = InitializationSettings(
        android: androidInitializationSettings,
        iOS: iOSInitializationSettings,
      );

      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onSelectNotification,
      );

      _isInitialized = true;
      logger.i('NotificationService initialized');
    } catch (e) {
      logger.e('Failed to initialize NotificationService', error: e);
    }
  }

  /// Show budget alert notification
  Future<void> showBudgetAlert({
    required String category,
    required double spent,
    required double budget,
  }) async {
    try {
      _checkInitialized();

      final title = 'Budget Alert: $category';
      final body =
          'Spent \$$spent of \$$budget budget (${((spent / budget) * 100).toStringAsFixed(0)}%)';

      await _showNotification(
        id: category.hashCode,
        title: title,
        body: body,
        payload: 'budget_alert_$category',
      );

      logger.i('Budget alert shown for $category');
    } catch (e) {
      logger.e('Failed to show budget alert', error: e);
    }
  }

  /// Show duplicate receipt warning
  Future<void> showDuplicateWarning({
    required String vendor,
    required double amount,
  }) async {
    try {
      _checkInitialized();

      final title = 'Duplicate Receipt Detected';
      final body = '$vendor - \$$amount';

      await _showNotification(
        id: 'duplicate_${vendor}_$amount'.hashCode,
        title: title,
        body: body,
        payload: 'duplicate_warning',
      );

      logger.i('Duplicate warning shown for $vendor');
    } catch (e) {
      logger.e('Failed to show duplicate warning', error: e);
    }
  }

  /// Show subscription reminder
  Future<void> showSubscriptionReminder({
    required String vendor,
    required double amount,
    required DateTime nextDue,
  }) async {
    try {
      _checkInitialized();

      final title = 'Subscription Reminder';
      final body =
          '$vendor (\$$amount) due on ${nextDue.toString().split(' ')[0]}';

      await _showNotification(
        id: 'subscription_${vendor}'.hashCode,
        title: title,
        body: body,
        payload: 'subscription_reminder',
      );

      logger.i('Subscription reminder shown for $vendor');
    } catch (e) {
      logger.e('Failed to show subscription reminder', error: e);
    }
  }

  /// Show general notification
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      _checkInitialized();

      await _showNotification(
        id: DateTime.now().millisecondsSinceEpoch.hashCode,
        title: title,
        body: body,
        payload: payload,
      );

      logger.i('Notification shown: $title');
    } catch (e) {
      logger.e('Failed to show notification', error: e);
    }
  }

  /// Internal method to show notification
  Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'documorph_channel',
        'DocuMorph Notifications',
        channelDescription: 'Notifications for budget alerts and reminders',
        importance: Importance.high,
        priority: Priority.high,
      );

      const iOSDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBadge: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
      );

      await _notificationsPlugin.show(
        id,
        title,
        body,
        details,
        payload: payload,
      );
    } catch (e) {
      logger.e('Failed to show notification', error: e);
    }
  }

  /// Callback for iOS notifications when app is in foreground
  Future<void> _onDidReceiveLocalNotification(
    int id,
    String? title,
    String? body,
    String? payload,
  ) async {
    logger.i('iOS notification received: $title - $body');
  }

  /// Callback when notification is selected
  Future<void> _onSelectNotification(
    NotificationResponse notificationResponse,
  ) async {
    final payload = notificationResponse.payload;
    logger.i('Notification selected with payload: $payload');
    // Handle notification tap
  }

  /// Cancel a notification
  Future<void> cancelNotification(int id) async {
    try {
      _checkInitialized();
      await _notificationsPlugin.cancel(id);
      logger.i('Notification $id cancelled');
    } catch (e) {
      logger.e('Failed to cancel notification', error: e);
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      _checkInitialized();
      await _notificationsPlugin.cancelAll();
      logger.i('All notifications cancelled');
    } catch (e) {
      logger.e('Failed to cancel all notifications', error: e);
    }
  }

  /// Request notification permissions (Android 13+)
  Future<bool> requestPermissions() async {
    try {
      final result =
          await _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
              ?.requestNotificationsPermission();

      logger.i('Notification permission request: ${result ?? false}');
      return result ?? false;
    } catch (e) {
      logger.e('Failed to request notification permissions', error: e);
      return false;
    }
  }

  void _checkInitialized() {
    if (!_isInitialized) {
      throw Exception(
        'NotificationService not initialized. Call initialize() first.',
      );
    }
  }
}
