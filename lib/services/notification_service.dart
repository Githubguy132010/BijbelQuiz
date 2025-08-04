import 'package:flutter_local_notifications_plus/flutter_local_notifications_plus.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:math';
import 'package:device_info_plus/device_info_plus.dart';
import 'logger.dart';

/// A service to handle local notifications for the application.
///
/// This service is a singleton and provides methods to initialize notifications,
/// schedule daily reminders, and manage notification permissions.
class NotificationService {
  /// The single instance of the [NotificationService].
  static final NotificationService _instance = NotificationService._internal();

  /// Factory constructor to return the singleton instance.
  factory NotificationService() => _instance;

  /// Private internal constructor for the singleton.
  NotificationService._internal();

  /// The plugin instance used to manage notifications.
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static void Function(String message)? onError;

  /// Initializes the notification service.
  ///
  /// This must be called before any other notification methods. It sets up
  /// the timezone database and initializes the plugin with platform-specific settings.
  Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    AppLogger.info('Initializing NotificationService');
    
    // Request notification permissions before initializing
    if (Platform.isAndroid) {
      await _setupAndroidNotificationChannel();
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // Handle iOS/macOS initialization
    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
          onDidReceiveLocalNotification: _onDidReceiveLocalNotification,
        );
        
    const LinuxInitializationSettings initializationSettingsLinux =
        LinuxInitializationSettings(defaultActionName: 'Open notification');
        
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
      linux: initializationSettingsLinux,
    );

    try {
      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
      );
      _initialized = true;
      AppLogger.info('NotificationService initialized');
    } catch (e) {
      AppLogger.error('Failed to initialize notifications: $e');
      rethrow;
    }
  }

  Future<void> _setupAndroidNotificationChannel() async {
    try {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'motivation_channel',
        'Motivation Notifications',
        description: 'Daily motivational reminders to play BijbelQuiz',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
        enableLights: true,
      );

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
      
      // Request notification permission on Android 13+
      if (await _isAndroid13OrHigher()) {
        try {
          final bool? granted = await flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
              ?.requestNotificationsPermission();
              
          AppLogger.info('Notification permission granted: $granted');
        } catch (e) {
          AppLogger.error('Error requesting notification permission: $e');
        }
      }
    } catch (e) {
      AppLogger.error('Error setting up notification channel: $e');
    }
  }

  Future<bool> _isAndroid13OrHigher() async {
    if (!Platform.isAndroid) return false;
    final deviceInfo = await DeviceInfoPlugin().androidInfo;
    return deviceInfo.version.sdkInt >= 33; // Android 13 is API level 33
  }

  // Handle iOS/macOS local notification
  static Future<void> _onDidReceiveLocalNotification(
    int id,
    String? title,
    String? body,
    String? payload,
  ) async {
    // Handle the notification when it's received while the app is in the foreground
    AppLogger.info('Received local notification: $id, $title, $body');
  }

  // Handle notification tap/response
  static Future<void> _onNotificationResponse(NotificationResponse response) async {
    // Handle when the user taps on a notification
    AppLogger.info('Notification tapped: ${response.id}, ${response.payload}');
  }

  /// Plant drie dagelijkse motivatie-meldingen op willekeurige tijden.
  Future<void> scheduleDailyMotivationNotifications() async {
    await cancelAllNotifications();

    if (kIsWeb) return;

    // Genereer 3 willekeurige tijden tussen 8:00 en 22:00 voor vandaag
    final now = DateTime.now();
    final random = Random(now.year * 10000 + now.month * 100 + now.day); // Seed voor reproduceerbaarheid per dag
    final List<TimeOfDay> times = [];
    final Set<int> usedMinutes = {};
    while (times.length < 3) {
      final hour = 8 + random.nextInt(15); // 8 tot 22
      final minute = random.nextInt(60);
      final totalMinutes = hour * 60 + minute;
      if (!usedMinutes.contains(totalMinutes)) {
        times.add(TimeOfDay(hour: hour, minute: minute));
        usedMinutes.add(totalMinutes);
      }
    }
    times.sort((a, b) => a.hour != b.hour ? a.hour - b.hour : a.minute - b.minute);

    final List<String> messages = [
      'Doe mee met een quiz! 🚀',
      'Neem een pauze en speel BijbelQuiz!',
      'Test je kennis met een Bijbelquiz!',
      'Daag jezelf uit met een quiz! 💡',
      'Vergroot je kennis—vraag voor vraag!',
      'Klaar voor een leuke Bijbeluitdaging?',
      'Houd je geest scherp met BijbelQuiz!',
      'Ontdek iets nieuws in de Bijbel!',
      'Blijf actief—speel BijbelQuiz!',
      'Een korte quiz fleurt je dag op!',
      'Test nu je Bijbelkennis!',
      'Hoeveel weet jij? Kom erachter!',
      'Leren is een reis—geniet van de quiz!',
    ];
    messages.shuffle(random);

    if (Platform.isLinux) {
      for (int i = 0; i < times.length; i++) {
        final now = DateTime.now();
        final target = DateTime(now.year, now.month, now.day, times[i].hour, times[i].minute);
        final delay = target.isAfter(now) ? target.difference(now) : Duration.zero;
        Future.delayed(delay, () {
          flutterLocalNotificationsPlugin.show(
            200 + i,
            'BijbelQuiz',
            messages[i],
            const NotificationDetails(linux: LinuxNotificationDetails()),
          );
        });
      }
      return;
    }

    try {
      for (int i = 0; i < times.length; i++) {
        await _scheduleDailyNotification(
          id: 100 + i,
          title: 'BijbelQuiz',
          body: messages[i],
          timeOfDay: times[i],
        );
      }
    } catch (e) {
      onError?.call('Kon meldingen niet plannen: ${e.toString()}');
    }
  }

  /// Schedules a single daily notification at a specific time.
  Future<void> _scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required TimeOfDay timeOfDay,
  }) async {
    try {
      // Ensure timezone is initialized
      tz.initializeTimeZones();
      
      // Get current time in local timezone
      final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
      
      // Create scheduled date with the specified time
      tz.TZDateTime scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        timeOfDay.hour,
        timeOfDay.minute,
      );
      
      // If the time has already passed today, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }
      
      // Log the scheduling attempt
      AppLogger.info('Scheduling notification for ${scheduledDate.toString()}');
      
      // Schedule the notification
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'motivation_channel',
            'Motivation Notifications',
            channelDescription: 'Daily motivational reminders to play BijbelQuiz',
            importance: Importance.max,
            priority: Priority.high,
            enableVibration: true,
            playSound: true,
            showWhen: true,
            styleInformation: BigTextStyleInformation(''),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
          macOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
          linux: const LinuxNotificationDetails(
            urgency: LinuxNotificationUrgency.normal,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'notification_$id',
      );
      
      AppLogger.info('Successfully scheduled notification with id: $id');
    } catch (e, stackTrace) {
      AppLogger.error('Error scheduling notification: $e\n$stackTrace');
      rethrow;
    }
  }

  /// Cancels all scheduled notifications.
  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  /// Requests notification permissions on platforms that require it (iOS, macOS, Android).
  ///
  /// Returns `true` if permissions are granted or not required, `false` otherwise.
  /// On Web and Linux, this method returns `true` as permissions are handled differently.
  static Future<bool> requestNotificationPermission() async {
    if (kIsWeb || Platform.isLinux) return true;
    try {
      final plugin = NotificationService().flutterLocalNotificationsPlugin;
      if (Platform.isAndroid) {
        final androidImplementation = plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        if (androidImplementation != null) {
          final granted = await androidImplementation.requestNotificationsPermission();
          return granted ?? true;
        }
      } else if (Platform.isIOS) {
        final iosImplementation = plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
        if (iosImplementation != null) {
          final granted = await iosImplementation.requestPermissions(alert: true, badge: true, sound: true);
          return granted ?? true;
        }
      } else if (Platform.isMacOS) {
        final macImplementation = plugin.resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>();
        if (macImplementation != null) {
          final granted = await macImplementation.requestPermissions(alert: true, badge: true, sound: true);
          return granted ?? true;
        }
      }
      return true;
    } catch (e) {
      return true;
    }
  }
} 