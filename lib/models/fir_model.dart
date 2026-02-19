import 'package:intl/intl.dart';

class FIR {
  final int? id;
  final String accidentType;
  final String description;
  final String severity;
  final String location;
  final DateTime dateTime;
  final String status;
  final List<String>? photoPaths;
  final List<String>? videoPaths;
  final String? audioPath;

  FIR({
    this.id,
    required this.accidentType,
    required this.description,
    required this.severity,
    required this.location,
    required this.dateTime,
    required this.status,
    this.photoPaths,
    this.videoPaths,
    this.audioPath,
  });

  String get formattedDate => DateFormat('MMM dd, yyyy HH:mm').format(dateTime);
  
  String get formattedDateShort => DateFormat('dd/MM/yyyy').format(dateTime);
  
  String get formattedTime => DateFormat('HH:mm').format(dateTime);

  // Convert FIR to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'accidentType': accidentType,
      'description': description,
      'severity': severity,
      'location': location,
      'dateTime': dateTime.toIso8601String(),
      'status': status,
      'photoPaths': photoPaths?.join(','), // Store as comma-separated string
      'videoPaths': videoPaths?.join(','), // Store as comma-separated string
      'audioPath': audioPath,
    };
  }

  // Create FIR from Map (database retrieval)
  factory FIR.fromMap(Map<String, dynamic> map) {
    return FIR(
      id: map['id']?.toInt(),
      accidentType: map['accidentType'] ?? '',
      description: map['description'] ?? '',
      severity: map['severity'] ?? 'Moderate',
      location: map['location'] ?? '',
      dateTime: DateTime.parse(map['dateTime']),
      status: map['status'] ?? 'Submitted',
      photoPaths: map['photoPaths'] != null && map['photoPaths'].toString().isNotEmpty 
          ? map['photoPaths'].toString().split(',') 
          : null,
      videoPaths: map['videoPaths'] != null && map['videoPaths'].toString().isNotEmpty 
          ? map['videoPaths'].toString().split(',') 
          : null,
      audioPath: map['audioPath'],
    );
  }

  // Copy with method for creating modified instances
  FIR copyWith({
    int? id,
    String? accidentType,
    String? description,
    String? severity,
    String? location,
    DateTime? dateTime,
    String? status,
    List<String>? photoPaths,
    List<String>? videoPaths,
    String? audioPath,
  }) {
    return FIR(
      id: id ?? this.id,
      accidentType: accidentType ?? this.accidentType,
      description: description ?? this.description,
      severity: severity ?? this.severity,
      location: location ?? this.location,
      dateTime: dateTime ?? this.dateTime,
      status: status ?? this.status,
      photoPaths: photoPaths ?? this.photoPaths,
      videoPaths: videoPaths ?? this.videoPaths,
      audioPath: audioPath ?? this.audioPath,
    );
  }

  // Get total evidence count
  int get evidenceCount {
    int count = 0;
    if (photoPaths != null) count += photoPaths!.length;
    if (videoPaths != null) count += videoPaths!.length;
    if (audioPath != null) count += 1;
    return count;
  }

  // Check if has any evidence
  bool get hasEvidence {
    return evidenceCount > 0;
  }

  // Get evidence summary text
  String get evidenceSummary {
    if (!hasEvidence) return "No evidence attached";
    
    List<String> parts = [];
    if (photoPaths != null && photoPaths!.isNotEmpty) {
      parts.add("${photoPaths!.length} photo${photoPaths!.length > 1 ? 's' : ''}");
    }
    if (videoPaths != null && videoPaths!.isNotEmpty) {
      parts.add("${videoPaths!.length} video${videoPaths!.length > 1 ? 's' : ''}");
    }
    if (audioPath != null) {
      parts.add("1 audio recording");
    }
    
    return parts.join(", ");
  }

  @override
  String toString() {
    return 'FIR{id: $id, accidentType: $accidentType, description: $description, severity: $severity, location: $location, dateTime: $dateTime, status: $status, evidenceCount: $evidenceCount}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FIR &&
        other.id == id &&
        other.accidentType == accidentType &&
        other.description == description &&
        other.severity == severity &&
        other.location == location &&
        other.dateTime == dateTime &&
        other.status == status;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        accidentType.hashCode ^
        description.hashCode ^
        severity.hashCode ^
        location.hashCode ^
        dateTime.hashCode ^
        status.hashCode;
  }
}