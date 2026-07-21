import 'package:equatable/equatable.dart';

/// The core Story entity representing a primary task unit in FOCUSMITH.
///
/// Contains priority sorting keys, status flags, custom colors,
/// and creation/modification timestamps. Immutable by design.
class Story extends Equatable {
  /// Unique identifier of the story.
  final String id;

  /// Header text.
  final String title;

  /// Sorting weight index (smaller values represent higher priority).
  final int priority;

  /// Story status (e.g. 'todo', 'in_progress', 'done').
  final String status;

  /// Hexadecimal color value for dashboard highlighting.
  final int color;

  /// Creation date.
  final DateTime createdAt;

  /// Modification date.
  final DateTime updatedAt;

  /// Creates a new immutable [Story] instance.
  const Story({
    required this.id,
    required this.title,
    required this.priority,
    required this.status,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a modified copy of this [Story] instance.
  Story copyWith({
    String? id,
    String? title,
    int? priority,
    String? status,
    int? color,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Story(
      id: id ?? this.id,
      title: title ?? this.title,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Serialize this instance to a raw Map schema for SQLite storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'priority': priority,
      'status': status,
      'color': color,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  /// Deserialize an SQLite database map into a [Story] entity.
  factory Story.fromMap(Map<String, dynamic> map) {
    return Story(
      id: map['id'] as String,
      title: map['title'] as String,
      priority: map['priority'] as int,
      status: map['status'] as String,
      color: map['color'] as int,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
    );
  }

  @override
  List<Object?> get props => [id, title, priority, status, color, createdAt, updatedAt];
}
