// lib/models/contact.dart - CORRECT PATH AND COMPLETE
class Contact {
  final int? id;
  final String name;
  final String phone;
  final bool isEmergency;
  final DateTime createdAt;
  final String? relationship;
  final String? notes;

  Contact({
    this.id,
    required this.name,
    required this.phone,
    this.isEmergency = false,
    DateTime? createdAt,
    this.relationship,
    this.notes,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'isEmergency': isEmergency ? 1 : 0,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'relationship': relationship,
      'notes': notes,
    };
  }

  factory Contact.fromMap(Map<String, dynamic> map) {
    return Contact(
      id: map['id']?.toInt(),
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      isEmergency: map['isEmergency'] == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
          map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch),
      relationship: map['relationship'],
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'isEmergency': isEmergency,
      'relationship': relationship,
      'notes': notes,
    };
  }

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      isEmergency: json['isEmergency'] ?? false,
      relationship: json['relationship'],
      notes: json['notes'],
    );
  }

  String get formattedPhone {
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length == 10) {
      return '${digits.substring(0, 3)}-${digits.substring(3, 6)}-${digits.substring(6)}';
    }
    return phone;
  }

  String get displayName {
    if (relationship != null && relationship!.isNotEmpty) {
      return '$name ($relationship)';
    }
    return name;
  }
}