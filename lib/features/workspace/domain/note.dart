import 'package:equatable/equatable.dart';

/// The core Note entity representing the rich-text content attached to a Story.
class Note extends Equatable {
  /// Unique identifier of the note.
  final String id;

  /// Foreign key linking to the parent Story.
  final String storyId;

  /// Stringified JSON representation of the Flutter Quill Delta document format.
  final String deltaJson;

  /// Timestamp of the last editor update.
  final DateTime updatedAt;

  /// Creates a new immutable [Note] instance.
  const Note({
    required this.id,
    required this.storyId,
    required this.deltaJson,
    required this.updatedAt,
  });

  /// Create a modified copy of this [Note] instance.
  Note copyWith({
    String? id,
    String? storyId,
    String? deltaJson,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      storyId: storyId ?? this.storyId,
      deltaJson: deltaJson ?? this.deltaJson,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Serialize this instance to a raw Map schema for SQLite storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'storyId': storyId,
      'deltaJson': deltaJson,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  /// Deserialize an SQLite database map into a [Note] entity.
  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as String,
      storyId: map['storyId'] as String,
      deltaJson: map['deltaJson'] as String,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
    );
  }

  @override
  List<Object?> get props => [id, storyId, deltaJson, updatedAt];
}
