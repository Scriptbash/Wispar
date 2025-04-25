import 'dart:ui';
import 'package:flutter/rendering.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/journal_entity.dart';
import '../services/database_helper.dart';
import 'feed_service.dart';
import 'dart:async';
import 'dart:io';
import '../generated_l10n/app_localizations.dart';

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  final dbHelper = DatabaseHelper();
  final feedService = FeedService();

  await initializeNotifications();

  final locale = PlatformDispatcher.instance.locale;
  final localizations = lookupAppLocalizations(locale);
  final notificationContent = localizations.notificationContent;
  final notificationTitle = localizations.notificationTitle;

  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();

    // Set the notification for the foreground service
    service.setForegroundNotificationInfo(
      title: notificationTitle,
      content: notificationContent,
    );
    service.on('stopService').listen((event) {
      service.stopSelf();
    });
  }

  final fetchIntervalInHours = 6;
  final maxConcurrentUpdates = Platform.isAndroid ? 3 : 1;

  const interval = Duration(minutes: 2); // Todo change this to a few hours
  Timer.periodic(interval, (_) async {
    await runFeedJob(
        dbHelper, feedService, fetchIntervalInHours, maxConcurrentUpdates);
  });

  // Saved queries
  /*final savedQueries = await dbHelper.getSavedQueriesToIncludeInFeed();
  await feedService.updateSavedQueryFeed(
    savedQueries,
    (queryNames) {
    },
    fetchIntervalInHours,
    maxConcurrentUpdates,
  );

  service.invoke('update', {
    "status": "Background feed update completed at ${DateTime.now()}",
  });*/
}

Future<void> runFeedJob(
  DatabaseHelper dbHelper,
  FeedService feedService,
  int fetchIntervalInHours,
  int maxConcurrentUpdates,
) async {
  debugPrint('Feed updated in background at ${DateTime.now()}');

  final int articleCountBefore = await dbHelper.getArticleCount();

  List<Journal> followedJournals = await dbHelper.getJournals();
  await feedService.updateFeed(
    followedJournals,
    (journalNames) {},
    fetchIntervalInHours,
    maxConcurrentUpdates,
  );

  final int articleCountAfter = await dbHelper.getArticleCount();
  if (articleCountBefore < articleCountAfter) {
    await showNewArticlesNotification();
  } else {
    debugPrint("No new articles received");
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

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

Future<void> showNewArticlesNotification() async {
  final locale = PlatformDispatcher.instance.locale;
  final localizations = lookupAppLocalizations(locale);
  final notificationContent = localizations.notificationContent;
  final notificationTitle = localizations.notificationTitle;
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'wispar_channel',
    'Wispar Updates',
    channelDescription: 'Notification when new articles are available',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
    icon: 'ic_bg_service_small',
    color: Color.fromARGB(255, 118, 54, 219),
  );

  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

  await flutterLocalNotificationsPlugin.show(
    0,
    notificationTitle,
    notificationContent,
    platformChannelSpecifics,
  );
}
