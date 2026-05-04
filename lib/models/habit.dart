import 'dart:convert';

class Habit {
  final String id;
  final String title;
  final int iconCodePoint;
  final String? iconFontFamily;
  final DateTime createdAt;
  final List<DateTime> completedDates;
  final int goalDays;
  final bool isQuantifiable;
  final double? targetQuantity;
  final String? quantityUnit;

  Habit({
    required this.id,
    required this.title,
    required this.iconCodePoint,
    this.iconFontFamily,
    required this.createdAt,
    List<DateTime>? completedDates,
    required this.goalDays,
    this.isQuantifiable = false,
    this.targetQuantity,
    this.quantityUnit,
  }) : completedDates = completedDates ?? [];

  Habit copyWith({
    String? id,
    String? title,
    int? iconCodePoint,
    String? iconFontFamily,
    DateTime? createdAt,
    List<DateTime>? completedDates,
    int? goalDays,
    bool? isQuantifiable,
    double? targetQuantity,
    String? quantityUnit,
  }) {
    return Habit(
      id: id ?? this.id,
      title: title ?? this.title,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      iconFontFamily: iconFontFamily ?? this.iconFontFamily,
      createdAt: createdAt ?? this.createdAt,
      completedDates: completedDates ?? List.from(this.completedDates),
      goalDays: goalDays ?? this.goalDays,
      isQuantifiable: isQuantifiable ?? this.isQuantifiable,
      targetQuantity: targetQuantity ?? this.targetQuantity,
      quantityUnit: quantityUnit ?? this.quantityUnit,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'iconCodePoint': iconCodePoint,
      'iconFontFamily': iconFontFamily,
      'createdAt': createdAt.toIso8601String(),
      'completedDates': completedDates.map((d) => d.toIso8601String()).toList(),
      'goalDays': goalDays,
      'isQuantifiable': isQuantifiable,
      'targetQuantity': targetQuantity,
      'quantityUnit': quantityUnit,
    };
  }

  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      iconCodePoint: map['iconCodePoint'] ?? 0,
      iconFontFamily: map['iconFontFamily'],
      createdAt: DateTime.parse(map['createdAt']),
      completedDates:
          (map['completedDates'] as List<dynamic>?)
              ?.map((d) => DateTime.parse(d as String))
              .toList() ??
          [],
      goalDays: map['goalDays'] ?? 30, // Fallback for old data
      isQuantifiable: map['isQuantifiable'] ?? false,
      targetQuantity: map['targetQuantity']?.toDouble(),
      quantityUnit: map['quantityUnit'],
    );
  }

  String toJson() => json.encode(toMap());

  factory Habit.fromJson(String source) => Habit.fromMap(json.decode(source));

  bool isCompletedOn(DateTime date) {
    return completedDates.any(
      (d) => d.year == date.year && d.month == date.month && d.day == date.day,
    );
  }

  double get progressPercentage {
    if (goalDays == 0) return 0;
    return (completedDates.length / goalDays).clamp(0.0, 1.0);
  }

  String get progressText => "${completedDates.length} out of $goalDays days";
}
