// lib/models/memo_model.dart
import 'package:intl/intl.dart';

class Memo {
  final int? id;
  final String filePath;
  final DateTime recordedAt;
  final int durationMs;
  final String? description;

  Memo({
    this.id,
    required this.filePath,
    required this.recordedAt,
    this.durationMs = 0,
    this.description,
  });

  String get fileName => filePath.split('/').last;
  String get formattedDate => DateFormat('MMM d, yyyy HH:mm').format(recordedAt);
  String get durationString {
    final duration = Duration(milliseconds: durationMs);
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'filePath': filePath,
      'recordedAt': recordedAt.millisecondsSinceEpoch,
      'durationMs': durationMs,
      'description': description,
    };
  }

  factory Memo.fromMap(Map<String, dynamic> map) {
    return Memo(
      id: map['id'],
      filePath: map['filePath'],
      recordedAt: DateTime.fromMillisecondsSinceEpoch(map['recordedAt']),
      durationMs: map['durationMs'] ?? 0,
      description: map['description'],
    );
  }
}