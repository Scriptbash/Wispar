import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:background_fetch/background_fetch.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/journal_entity.dart';
import '../services/database_helper.dart';
import '../services/feed_service.dart';
import '../generated_l10n/app_localizations.dart';

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

Future<void> runFeedJob(
  DatabaseHelper dbHelper,
  FeedService feedService,
  int fetchIntervalInHours,
  int maxConcurrentUpdates,
) async {
  debugPrint('Feed updated in background at ${DateTime.now()}');

  int articleCountBefore = await dbHelper.getArticleCount();

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

Future<void> initBackgroundFetch() async {
  await initializeNotifications();

  await BackgroundFetch.configure(
    BackgroundFetchConfig(
      minimumFetchInterval: 60,
      stopOnTerminate: false,
      enableHeadless: true,
      requiresBatteryNotLow: false,
      requiresCharging: false,
      requiresStorageNotLow: false,
      requiredNetworkType: NetworkType.ANY,
    ),
    (String taskId) async {
      final dbHelper = DatabaseHelper();
      final feedService = FeedService();
      await runFeedJob(
        dbHelper,
        feedService,
        3,
        Platform.isAndroid ? 3 : 2,
      );

      BackgroundFetch.finish(taskId);
    },
    (String taskId) async {
      // Timeout handler
      BackgroundFetch.finish(taskId);
    },
  );

  BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);
}

@pragma('vm:entry-point')
void backgroundFetchHeadlessTask(HeadlessTask task) async {
  final String taskId = task.taskId;
  final bool isTimeout = task.timeout;

  if (isTimeout) {
    BackgroundFetch.finish(taskId);
    return;
  }

  final dbHelper = DatabaseHelper();
  final feedService = FeedService();

  await runFeedJob(
    dbHelper,
    feedService,
    3,
    Platform.isAndroid ? 3 : 2,
  );

  BackgroundFetch.finish(taskId);
}
