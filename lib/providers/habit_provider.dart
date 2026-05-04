import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import '../models/habit.dart';

class HabitProvider extends ChangeNotifier {
  String? _userId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String get _prefsKey => 'user_habits_${_userId ?? "guest"}';
  List<Habit> _habits = [];
  bool _isInitialized = false;

  List<Habit> get habits => _habits;
  bool get isInitialized => _isInitialized;

  HabitProvider() {
    _loadHabits();
  }

  void updateUserId(String? userId) {
    if (_userId != userId) {
      _userId = userId;
      _isInitialized = false;
      notifyListeners();
      _loadHabits();
    }
  }

  Future<void> _loadHabits() async {
    // 1. Load from SharedPreferences first for immediate UI response
    final prefs = await SharedPreferences.getInstance();
    final habitsJson = prefs.getStringList(_prefsKey);

    if (habitsJson != null) {
      _habits = habitsJson.map((h) => Habit.fromJson(h)).toList();
    } else {
      _habits = [];
    }
    
    // Initial UI update
    _isInitialized = true;
    notifyListeners();

    // 2. If logged in, sync with Firestore
    if (_userId != null) {
      try {
        final snapshot = await _firestore
            .collection('users')
            .doc(_userId)
            .collection('habits')
            .get();

        if (snapshot.docs.isNotEmpty) {
          // Firestore has data, it's the source of truth
          _habits = snapshot.docs.map((doc) => Habit.fromMap(doc.data())).toList();
          // Sort by creation date if needed
          _habits.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          
          // Update local cache
          await _saveHabitsLocal();
          notifyListeners();
        } else if (_habits.isNotEmpty) {
          // Firestore is empty but we have local data - this is likely a first-time migration
          // or the user was using the app offline/as guest before logging in.
          debugPrint('Migrating local habits to Firestore for user: $_userId');
          for (final habit in _habits) {
            await _saveHabitToFirestore(habit);
          }
        }
      } catch (e) {
        debugPrint('Error syncing habits with Firestore: $e');
      }
    }
  }

  Future<void> _saveHabitsLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final habitsJson = _habits.map((h) => h.toJson()).toList();
    await prefs.setStringList(_prefsKey, habitsJson);
  }

  Future<void> _saveHabitToFirestore(Habit habit) async {
    if (_userId == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('habits')
          .doc(habit.id)
          .set(habit.toMap());
    } catch (e) {
      debugPrint('Error saving habit to Firestore: $e');
    }
  }

  Future<void> _deleteHabitFromFirestore(String habitId) async {
    if (_userId == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('habits')
          .doc(habitId)
          .delete();
    } catch (e) {
      debugPrint('Error deleting habit from Firestore: $e');
    }
  }

  Future<void> addHabit(
    String title,
    IconData icon,
    int goalDays, {
    bool isQuantifiable = false,
    double? targetQuantity,
    String? quantityUnit,
  }) async {
    final newHabit = Habit(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      iconCodePoint: icon.codePoint,
      iconFontFamily: icon.fontFamily,
      createdAt: DateTime.now(),
      goalDays: goalDays,
      isQuantifiable: isQuantifiable,
      targetQuantity: targetQuantity,
      quantityUnit: quantityUnit,
    );
    _habits.add(newHabit);
    await _saveHabitsLocal();
    await _saveHabitToFirestore(newHabit);
    notifyListeners();
  }

  Future<void> deleteHabit(String id) async {
    _habits.removeWhere((h) => h.id == id);
    await _saveHabitsLocal();
    await _deleteHabitFromFirestore(id);
    notifyListeners();
  }

  Future<void> editHabit(
    String id,
    String title,
    IconData icon,
    int goalDays, {
    bool isQuantifiable = false,
    double? targetQuantity,
    String? quantityUnit,
  }) async {
    final habitIndex = _habits.indexWhere((h) => h.id == id);
    if (habitIndex == -1) return;

    _habits[habitIndex] = _habits[habitIndex].copyWith(
      title: title,
      iconCodePoint: icon.codePoint,
      iconFontFamily: icon.fontFamily,
      goalDays: goalDays,
      isQuantifiable: isQuantifiable,
      targetQuantity: targetQuantity,
      quantityUnit: quantityUnit,
    );

    await _saveHabitsLocal();
    await _saveHabitToFirestore(_habits[habitIndex]);
    notifyListeners();
  }

  Future<void> toggleHabitCompletion(String habitId, DateTime date) async {
    final habitIndex = _habits.indexWhere((h) => h.id == habitId);
    if (habitIndex == -1) return;

    final habit = _habits[habitIndex];
    final isCompleted = habit.isCompletedOn(date);

    // Prevent un-completing a habit for a past date — once the day ends, it's locked
    if (isCompleted) {
      final today = DateTime.now();
      final isToday =
          date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;
      if (!isToday) return; // Silently ignore un-toggle for past dates
    }

    List<DateTime> updatedDates = List.from(habit.completedDates);

    if (isCompleted) {
      // Remove the completion for that date (only today, per the guard above)
      updatedDates.removeWhere(
        (d) =>
            d.year == date.year && d.month == date.month && d.day == date.day,
      );
    } else {
      // Add completion for that date
      updatedDates.add(date);
    }


    _habits[habitIndex] = habit.copyWith(completedDates: updatedDates);
    _saveHabitsLocal();
    _saveHabitToFirestore(_habits[habitIndex]);
    notifyListeners();
  }

  /// Returns the current streak: consecutive days where AT LEAST ONE habit was completed.
  /// If today has activity, it counts today + consecutive days before it.
  /// If today has NO activity but yesterday does, the streak is still alive
  /// (user hasn't missed a full day yet) — count from yesterday backward.
  /// The streak resets only when a full day passes with zero habits completed.
  int get currentGlobalStreak {
    if (_habits.isEmpty) return 0;

    // Collect all unique dates where at least one habit was completed
    final Set<String> activeDates = {};
    for (final habit in _habits) {
      for (final date in habit.completedDates) {
        activeDates.add(_dateKey(date));
      }
    }

    if (activeDates.isEmpty) return 0;

    final today = DateTime.now();
    final todayKey = _dateKey(today);
    final yesterday = today.subtract(const Duration(days: 1));
    final yesterdayKey = _dateKey(yesterday);

    // Determine where to start counting
    DateTime startDate;
    if (activeDates.contains(todayKey)) {
      startDate = today;
    } else if (activeDates.contains(yesterdayKey)) {
      // Today isn't done yet, but yesterday was — streak is still alive
      startDate = yesterday;
    } else {
      // Neither today nor yesterday had activity — streak is broken
      return 0;
    }

    // Count consecutive days backward from startDate
    int streak = 0;
    DateTime dateToCheck = startDate;
    while (activeDates.contains(_dateKey(dateToCheck))) {
      streak++;
      dateToCheck = dateToCheck.subtract(const Duration(days: 1));
      if (streak > 3650) break; // Safety limit
    }

    return streak;
  }

  /// Returns the longest streak ever achieved across all history.
  int get bestGlobalStreak {
    // Collect all unique dates where at least one habit was completed
    final Set<String> activeDates = {};
    for (final habit in _habits) {
      for (final date in habit.completedDates) {
        activeDates.add(_dateKey(date));
      }
    }

    if (activeDates.isEmpty) return 0;

    // Parse and sort all active dates chronologically
    final List<DateTime> sortedDates = activeDates.map((s) {
      final parts = s.split('-');
      return DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
    }).toList()..sort();

    int bestStreak = 1;
    int currentRun = 1;

    for (int i = 1; i < sortedDates.length; i++) {
      final diff = sortedDates[i].difference(sortedDates[i - 1]).inDays;
      if (diff == 1) {
        currentRun++;
        bestStreak = math.max(bestStreak, currentRun);
      } else if (diff > 1) {
        currentRun = 1;
      }
      // diff == 0 means duplicate date (shouldn't happen with Set, but safe)
    }

    return bestStreak;
  }

  /// Helper to create a consistent date key string
  String _dateKey(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }

  /// Returns a list of booleans for the past [days] representing if AT LEAST ONE habit was completed that day.
  /// Index 0 is [days]-1 ago, last index is today.
  List<bool> getConsistencyData(int days) {
    final List<bool> consistency = List.filled(days, false);
    final now = DateTime.now();

    for (int i = 0; i < days; i++) {
      final targetDate = now.subtract(Duration(days: days - 1 - i));

      for (final habit in _habits) {
        if (habit.isCompletedOn(targetDate)) {
          consistency[i] = true;
          break;
        }
      }
    }
    return consistency;
  }
}
