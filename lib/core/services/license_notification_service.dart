import 'dart:convert';
import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elostaz_travel/core/navigator/navigator.dart';
import 'package:elostaz_travel/data/bus/data_source/bus_remote_data_source_impl.dart';
import 'package:elostaz_travel/domain/bus/entity/bus_entity.dart';
import 'package:elostaz_travel/presentation/home/tabs/bus/bus_details_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

enum LicenseNotificationType {
  thirtyDays(daysBefore: 30, offset: 0, tag: '30'),
  sevenDays(daysBefore: 7, offset: 1, tag: '7'),
  oneDay(daysBefore: 1, offset: 2, tag: '1'),
  expired(daysBefore: 0, offset: 3, tag: 'expired');

  final int daysBefore;
  final int offset;
  final String tag;

  const LicenseNotificationType({
    required this.daysBefore,
    required this.offset,
    required this.tag,
  });
}

class LicenseNotificationService {
  LicenseNotificationService._internal();
  static final LicenseNotificationService instance =
      LicenseNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  static const String channelId = 'bus_license_expiry_channel';
  static const String channelName = 'تنبيهات رخص الأتوبيسات';
  static const String channelDescription =
      'إشعارات تذكيرية بقرب انتهاء رخص الأتوبيسات';

  /// Initialize notifications, timezone, and tap listeners.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 1. Initialize timezone
      tz.initializeTimeZones();
      try {
        final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));
        developer.log(
          'Local timezone set to: ${timeZoneInfo.identifier}',
          name: 'LicenseNotificationService',
        );
      } catch (e) {
        developer.log(
          'Could not get device timezone, falling back to default: $e',
          name: 'LicenseNotificationService',
        );
      }

      // 2. Initialize Flutter Local Notifications
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      );

      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
      );

      // Create Android Notification Channel
      const androidChannel = AndroidNotificationChannel(
        channelId,
        channelName,
        description: channelDescription,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);

      // 3. Request permissions
      await requestPermissions();

      // 4. Handle notification tap if app was launched from terminated state
      final launchDetails =
          await _notificationsPlugin.getNotificationAppLaunchDetails();
      if (launchDetails != null &&
          launchDetails.didNotificationLaunchApp &&
          launchDetails.notificationResponse?.payload != null) {
        final payload = launchDetails.notificationResponse!.payload!;
        Future.delayed(const Duration(milliseconds: 1000), () {
          _handlePayloadNavigation(payload);
        });
      }

      _isInitialized = true;
      developer.log(
        'LicenseNotificationService initialized successfully.',
        name: 'LicenseNotificationService',
      );
    } catch (e, st) {
      developer.log(
        'Error initializing LicenseNotificationService: $e',
        error: e,
        stackTrace: st,
        name: 'LicenseNotificationService',
      );
    }
  }

  /// Request Android 13+ Notification Permission
  Future<bool> requestPermissions() async {
    try {
      final androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      final granted =
          await androidImplementation?.requestNotificationsPermission();
      developer.log(
        'Notification permission status: $granted',
        name: 'LicenseNotificationService',
      );
      return granted ?? false;
    } catch (e) {
      developer.log(
        'Error requesting notification permissions: $e',
        name: 'LicenseNotificationService',
      );
      return false;
    }
  }

  /// Deterministic ID Generation
  /// Generates a stable, unique 32-bit positive integer for every busId and notification type.
  int generateNotificationId(String busId, LicenseNotificationType type) {
    final baseHash = busId.hashCode.abs() % 500000000;
    return (baseHash * 4) + type.offset;
  }

  /// Notification Details configuration
  NotificationDetails _notificationDetails() {
    const androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return const NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );
  }

  /// Get title for a specific notification type
  String _getTitle(LicenseNotificationType type) {
    switch (type) {
      case LicenseNotificationType.thirtyDays:
      case LicenseNotificationType.sevenDays:
        return 'تنبيه انتهاء رخصة الأتوبيس';
      case LicenseNotificationType.oneDay:
        return 'تنبيه مهم';
      case LicenseNotificationType.expired:
        return 'انتهت رخصة الأتوبيس';
    }
  }

  /// Get body for a specific notification type
  String _getBody(
    LicenseNotificationType type,
    String busName,
    String plateNumber,
  ) {
    switch (type) {
      case LicenseNotificationType.thirtyDays:
        return 'رخصة الأتوبيس $busName - لوحة $plateNumber ستنتهي خلال 30 يوم.';
      case LicenseNotificationType.sevenDays:
        return 'رخصة الأتوبيس $busName - لوحة $plateNumber ستنتهي خلال 7 أيام.';
      case LicenseNotificationType.oneDay:
        return 'رخصة الأتوبيس $busName - لوحة $plateNumber ستنتهي غدًا.';
      case LicenseNotificationType.expired:
        return 'رخصة الأتوبيس $busName - لوحة $plateNumber انتهت اليوم.';
    }
  }

  /// Schedule the four expiry notifications for a single bus
  Future<void> scheduleBusLicenseNotifications(BusEntity bus) async {
    if (bus.id == null || bus.id!.trim().isEmpty) {
      developer.log(
        'Skipping schedule: bus.id is missing or empty.',
        name: 'LicenseNotificationService',
      );
      return;
    }

    final busId = bus.id!;
    final busName = bus.busName.trim().isEmpty ? 'الأتوبيس' : bus.busName.trim();
    final plateNumber =
        bus.plateNumber.trim().isEmpty ? '-' : bus.plateNumber.trim();
    final expiryDate = bus.licenseExpiryDate;

    developer.log(
      '================ LICENSE NOTIFICATION SCHEDULE ================\n'
      'Bus ID: $busId\n'
      'Bus Name: $busName\n'
      'Plate: $plateNumber\n'
      'Expiry Date: ${expiryDate.toIso8601String()}',
      name: 'LicenseNotificationService',
    );

    final now = tz.TZDateTime.now(tz.local);

    // Target expiry date at 09:00 AM local time
    final expiryBase = DateTime(
      expiryDate.year,
      expiryDate.month,
      expiryDate.day,
      9,
      0,
      0,
    );

    for (final type in LicenseNotificationType.values) {
      final scheduledDate = expiryBase.subtract(
        Duration(days: type.daysBefore),
      );

      final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);
      final notificationId = generateNotificationId(busId, type);

      if (tzScheduledDate.isBefore(now)) {
        developer.log(
          'Skipping ${type.tag} notification (ID: $notificationId): '
          'Scheduled date ($tzScheduledDate) has already passed.',
          name: 'LicenseNotificationService',
        );
        continue;
      }

      final payload = jsonEncode({
        'type': 'license_expiry',
        'busId': busId,
        'notificationType': type.tag,
      });

      final title = _getTitle(type);
      final body = _getBody(type, busName, plateNumber);

      try {
        await _notificationsPlugin.zonedSchedule(
          id: notificationId,
          title: title,
          body: body,
          scheduledDate: tzScheduledDate,
          notificationDetails: _notificationDetails(),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: payload,
        );

        developer.log(
          'Scheduled ${type.tag} notification:\n'
          '  - ID: $notificationId\n'
          '  - Date: $tzScheduledDate\n'
          '  - Title: $title\n'
          '  - Body: $body',
          name: 'LicenseNotificationService',
        );
      } catch (e, st) {
        developer.log(
          'Failed to schedule ${type.tag} notification (ID: $notificationId): $e',
          error: e,
          stackTrace: st,
          name: 'LicenseNotificationService',
        );
      }
    }
  }

  /// Cancel all 4 scheduled notifications for a bus
  Future<void> cancelBusLicenseNotifications(String busId) async {
    if (busId.trim().isEmpty) return;

    developer.log(
      'Cancelling license notifications for Bus ID: $busId',
      name: 'LicenseNotificationService',
    );

    for (final type in LicenseNotificationType.values) {
      final notificationId = generateNotificationId(busId, type);
      try {
        await _notificationsPlugin.cancel(id: notificationId);
        developer.log(
          'Cancelled notification ID: $notificationId (${type.tag})',
          name: 'LicenseNotificationService',
        );
      } catch (e) {
        developer.log(
          'Error cancelling notification ID $notificationId: $e',
          name: 'LicenseNotificationService',
        );
      }
    }
  }

  /// Reschedule notifications when bus details (date, name, plate) change
  Future<void> rescheduleBusLicenseNotifications(BusEntity bus) async {
    if (bus.id == null || bus.id!.trim().isEmpty) return;

    // 1. Cancel previous notifications for this bus
    await cancelBusLicenseNotifications(bus.id!);

    // 2. Schedule new notifications with updated details
    await scheduleBusLicenseNotifications(bus);
  }

  /// Schedule notifications for all existing buses of the user
  Future<void> scheduleAllExistingBusLicenseNotifications(
    List<BusEntity> buses,
  ) async {
    if (buses.isEmpty) return;

    developer.log(
      'Scheduling license notifications for ${buses.length} existing buses...',
      name: 'LicenseNotificationService',
    );

    for (final bus in buses) {
      await scheduleBusLicenseNotifications(bus);
    }
  }

  /// Development/Testing Helper:
  /// Schedules a test notification to trigger a few seconds in the future
  /// for immediate verification of appearance, Arabic rendering, and tap navigation.
  Future<void> scheduleTestLicenseNotification({
    required BusEntity bus,
    int delaySeconds = 5,
  }) async {
    if (bus.id == null || bus.id!.trim().isEmpty) return;

    final busId = bus.id!;
    final busName = bus.busName.trim().isEmpty ? 'أتوبيس تجريبي' : bus.busName;
    final plateNumber =
        bus.plateNumber.trim().isEmpty ? '123' : bus.plateNumber;

    final testId = (busId.hashCode.abs() % 500000000) * 4 + 99;
    final scheduledDate = tz.TZDateTime.now(tz.local).add(
      Duration(seconds: delaySeconds),
    );

    final payload = jsonEncode({
      'type': 'license_expiry',
      'busId': busId,
      'notificationType': 'test',
    });

    const title = 'تنبيه انتهاء رخصة الأتوبيس (تجريبي)';
    final body =
        'رخصة الأتوبيس $busName - لوحة $plateNumber ستنتهي قريبًا (إشعار تجريبي).';

    await _notificationsPlugin.zonedSchedule(
      id: testId,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
    );

    developer.log(
      'Scheduled TEST notification for Bus $busId in $delaySeconds seconds (ID: $testId).',
      name: 'LicenseNotificationService',
    );
  }

  /// Internal handler for notification responses (tap)
  void _onNotificationResponse(NotificationResponse response) {
    if (response.payload != null && response.payload!.isNotEmpty) {
      _handlePayloadNavigation(response.payload!);
    }
  }

  /// Parses payload and navigates safely to BusDetailsScreen
  Future<void> _handlePayloadNavigation(String payloadString) async {
    try {
      final Map<String, dynamic> data = jsonDecode(payloadString);
      if (data['type'] != 'license_expiry') return;

      final busId = data['busId'] as String?;
      if (busId == null || busId.isEmpty) return;

      developer.log(
        'Notification tapped for busId: $busId, navigating to BusDetailsScreen...',
        name: 'LicenseNotificationService',
      );

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        developer.log(
          'User not authenticated yet; cannot fetch bus details.',
          name: 'LicenseNotificationService',
        );
        return;
      }

      final dataSource = BusRemoteDataSourceImpl(
        firestore: FirebaseFirestore.instance,
        firebaseAuth: FirebaseAuth.instance,
      );

      final bus = await dataSource.getBus(busId: busId);

      NavigatorHandler.push(BusDetailsScreen(bus: bus));
    } catch (e, st) {
      developer.log(
        'Error handling notification navigation payload: $e',
        error: e,
        stackTrace: st,
        name: 'LicenseNotificationService',
      );
    }
  }
}
