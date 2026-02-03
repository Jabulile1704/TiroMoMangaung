import 'package:shared_preferences/shared_preferences.dart';

class SearchHistoryService {
  static const String _key = 'search_history';
  static const int _maxHistory = 10;

  // Add search query to history
  static Future<void> addSearch(String query) async {
    if (query.trim().isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> history = prefs.getStringList(_key) ?? [];

      // Remove if already exists (to move to top)
      history.remove(query);

      // Add to beginning
      history.insert(0, query);

      // Keep only last 10
      if (history.length > _maxHistory) {
        history = history.sublist(0, _maxHistory);
      }

      await prefs.setStringList(_key, history);
    } catch (e) {
      print('Error adding search: $e');
    }
  }

  // Get search history
  static Future<List<String>> getSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_key) ?? [];
    } catch (e) {
      print('Error getting search history: $e');
      return [];
    }
  }

  // Remove specific search
  static Future<void> removeSearch(String query) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> history = prefs.getStringList(_key) ?? [];
      history.remove(query);
      await prefs.setStringList(_key, history);
    } catch (e) {
      print('Error removing search: $e');
    }
  }

  // Clear all history
  static Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (e) {
      print('Error clearing history: $e');
    }
  }
}
