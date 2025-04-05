import 'package:background_fetch/background_fetch.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'feed_service.dart';
import '../services/database_helper.dart';

class BackgroundFetchService {
  @pragma('vm:entry-point')
  static Future<void> backgroundFetchHeadlessTask(String taskId) async {
    print("[BackgroundFetch] Headless task started: $taskId");

    await fetchAndUpdateJournals();

    BackgroundFetch.finish(taskId);
  }

  static Future<void> startBackgroundFetch() async {
    print('START BG FETCH');
    await BackgroundFetch.configure(
      BackgroundFetchConfig(
        minimumFetchInterval: 15,
        stopOnTerminate: false,
        enableHeadless: true,
        startOnBoot: true,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
      ),
      backgroundFetchHeadlessTask,
    );
  }

  static Future<void> fetchAndUpdateJournals() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int fetchIntervalInHours = prefs.getInt('fetchInterval') ?? 6;

    try {
      final feedService = FeedService();

      final dbHelper = DatabaseHelper();
      final followedJournals = await dbHelper.getJournals();

      final journalsToUpdate = await feedService.checkJournalsToUpdate(
          followedJournals, fetchIntervalInHours);

      if (journalsToUpdate.isNotEmpty) {
        for (String issn in journalsToUpdate) {
          final journal = followedJournals.firstWhere((j) => j.issn == issn);

          await feedService.updateFeed(
            null,
            followedJournals,
            (journalName) {
              print("Updating: $journalName");
            },
            fetchIntervalInHours,
          );
        }
      }

      final savedQueries = await dbHelper.getSavedQueries();
      await feedService.updateSavedQueryFeed(
        null,
        savedQueries,
        (queryName) {
          print("Updating saved query: $queryName");
        },
        fetchIntervalInHours,
      );
    } catch (e) {
      print("Error during background fetch: $e");
    }
  }

  static void stopBackgroundFetch() async {
    await BackgroundFetch.stop();
  }
}
