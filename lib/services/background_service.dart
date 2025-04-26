import 'dart:ui';
import 'package:flutter/rendering.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/journal_entity.dart';
import '../services/database_helper.dart';
import 'feed_service.dart';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import '../generated_l10n/app_localizations.dart';

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  final dbHelper = DatabaseHelper();
  final feedService = FeedService();

  await initializeNotifications();

  final locale = PlatformDispatcher.instance.locale;
  final localizations = lookupAppLocalizations(locale);
  final notificationContent = localizations.fgNotificationContent;
  final notificationTitle = localizations.fgNotificationTitle;

  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();

    // Set the notification for the foreground service
    await flutterLocalNotificationsPlugin.show(
      24,
      notificationTitle,
      notificationContent,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'wispar_channel',
          'Wispar Updates',
          channelDescription: 'Background service for Wispar.',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: 'ic_bg_service_small',
          color: Color.fromARGB(255, 118, 54, 219),
          enableVibration: false,
        ),
      ),
    );
  }

  final fetchIntervalInHours = 6;
  final maxConcurrentUpdates = Platform.isAndroid ? 3 : 1;

  const interval = Duration(hours: 2);
  Timer.periodic(interval, (_) async {
    await runFeedJob(
        dbHelper, feedService, fetchIntervalInHours, maxConcurrentUpdates);
  });
}

Future<void> runFeedJob(
  DatabaseHelper dbHelper,
  FeedService feedService,
  int fetchIntervalInHours,
  int maxConcurrentUpdates,
) async {
  debugPrint('Feed updated in background at ${DateTime.now()}');

  int articleCountBefore = await dbHelper.getArticleCount();

  // Update journals
  List<Journal> followedJournals = await dbHelper.getJournals();
  await feedService.updateFeed(
    followedJournals,
    (journalNames) {},
    fetchIntervalInHours,
    maxConcurrentUpdates,
  );

  int articleCountAfter = await dbHelper.getArticleCount();
  if (articleCountBefore < articleCountAfter) {
    await showNewJournalArticlesNotification();
  } else {
    debugPrint("No new articles from journals received");
  }

  // Update saved queries
  articleCountBefore = await dbHelper.getArticleCount();
  final savedQueries = await dbHelper.getSavedQueriesToUpdate();
  await feedService.updateSavedQueryFeed(
    savedQueries,
    (queryNames) {},
    fetchIntervalInHours,
    maxConcurrentUpdates,
  );

  articleCountAfter = await dbHelper.getArticleCount();
  if (articleCountBefore < articleCountAfter) {
    await showNewQueryArticlesNotification();
  } else {
    debugPrint("No new articles from queries received");
  }
}

@pragma('vm:entry-point')
Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'wispar_channel',
      initialNotificationTitle: 'Wispar',
      initialNotificationContent: 'Initializing Wispar background services.',
      foregroundServiceNotificationId: 24,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );

  await service.startService();
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> initializeNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('ic_bg_service_small');

  const DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings(
    requestSoundPermission: true,
    requestBadgePermission: true,
    requestAlertPermission: true,
  );

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

Future<void> showNewJournalArticlesNotification() async {
  final locale = PlatformDispatcher.instance.locale;
  final localizations = lookupAppLocalizations(locale);
  final notificationContent = localizations.notificationContent;
  final notificationTitle = localizations.notificationTitleJournal;
  AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'wispar_channel',
    'Wispar Updates',
    channelDescription:
        'Notification when new articles from followed journals are available',
    importance: Importance.high,
    priority: Priority.defaultPriority,
    icon: 'ic_bg_service_small',
    color: Color.fromARGB(255, 118, 54, 219),
    enableVibration: true,
    vibrationPattern: Int64List.fromList([0, 300, 100, 100, 100, 100, 300]),
  );

  NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

  await flutterLocalNotificationsPlugin.show(
    0,
    notificationTitle,
    notificationContent,
    platformChannelSpecifics,
  );
}

Future<void> showNewQueryArticlesNotification() async {
  final locale = PlatformDispatcher.instance.locale;
  final localizations = lookupAppLocalizations(locale);
  final notificationContent = localizations.notificationContent;
  final notificationTitle = localizations.notificationTitleQuery;
  AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'wispar_channel',
    'Wispar Updates',
    channelDescription:
        'Notification when new articles from saved queries are available',
    importance: Importance.high,
    priority: Priority.defaultPriority,
    icon: 'ic_bg_service_small',
    color: Color.fromARGB(255, 118, 54, 219),
    enableVibration: true,
    vibrationPattern: Int64List.fromList([0, 300, 100, 100, 100, 100, 300]),
  );

  NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

  await flutterLocalNotificationsPlugin.show(
    1,
    notificationTitle,
    notificationContent,
    platformChannelSpecifics,
  );
}
