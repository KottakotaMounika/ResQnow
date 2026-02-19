// lib/models/appointment.dart
class Appointment {
  final int? id;
  final String patientName;
  final String phoneNumber;
  final String department;
  final DateTime appointmentDate;
  final String timeSlot;
  final DateTime createdAt;
  final String status;
  final String? notes;

  Appointment({
    this.id,
    required this.patientName,
    required this.phoneNumber,
    required this.department,
    required this.appointmentDate,
    required this.timeSlot,
    DateTime? createdAt,
    this.status = 'Scheduled',
    this.notes,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientName': patientName,
      'phoneNumber': phoneNumber,
      'department': department,
      'appointmentDate': appointmentDate.millisecondsSinceEpoch,
      'timeSlot': timeSlot,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'status': status,
      'notes': notes,
    };
  }

  factory Appointment.fromMap(Map<String, dynamic> map) {
    return Appointment(
      id: map['id']?.toInt(),
      patientName: map['patientName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      department: map['department'] ?? '',
      appointmentDate: DateTime.fromMillisecondsSinceEpoch(map['appointmentDate']),
      timeSlot: map['timeSlot'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      status: map['status'] ?? 'Scheduled',
      notes: map['notes'],
    );
  }

  String get formattedDate {
    return '${appointmentDate.day}/${appointmentDate.month}/${appointmentDate.year}';
  }

  String get displayStatus {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return '⏰ Scheduled';
      case 'completed':
        return '✅ Completed';
      case 'cancelled':
        return '❌ Cancelled';
      case 'confirmed':
        return '✓ Confirmed';
      default:
        return status;
    }
  }
}