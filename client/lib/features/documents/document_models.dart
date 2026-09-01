import 'package:flutter/material.dart';

enum DocumentType {
  nationalId('NATIONAL_ID', 'National ID', Icons.badge_outlined),
  drivingLicense(
      'DRIVING_LICENSE', 'Driving License', Icons.directions_car_outlined),
  passport('PASSPORT', 'Passport', Icons.flight_outlined),
  subscription('SUBSCRIPTION', 'Subscription', Icons.autorenew_rounded),
  other('OTHER', 'Other', Icons.description_outlined);

  final String code;
  final String label;
  final IconData icon;

  const DocumentType(this.code, this.label, this.icon);

  static DocumentType fromCode(String code) => DocumentType.values
      .firstWhere((t) => t.code == code, orElse: () => DocumentType.other);
}

enum BillingCycle {
  monthly('MONTHLY', 'Monthly'),
  yearly('YEARLY', 'Yearly'),
  custom('CUSTOM', 'Custom');

  final String code;
  final String label;

  const BillingCycle(this.code, this.label);

  static BillingCycle? fromCode(String? code) => code == null
      ? null
      : BillingCycle.values.where((b) => b.code == code).firstOrNull;
}

enum ExpiryUrgency {
  expired('Expired', Color(0xFFEF4444), Color(0xFF450A0A), Color(0xFFFCA5A5)),
  critical('Critical (1–7d)', Color(0xFFF87171), Color(0xFF7F1D1D),
      Color(0xFFFECACA)),
  expiringSoon(
      'Expiring Soon', Color(0xFFFBBF24), Color(0xFF78350F), Color(0xFFFDE68A)),
  upcoming('Upcoming', Color(0xFF60A5FA), Color(0xFF1E3A8A), Color(0xFFBFDBFE)),
  valid('Valid', Color(0xFF34D399), Color(0xFF064E3B), Color(0xFFA7F3D0));

  final String label;
  final Color baseColor;
  final Color darkBg;
  final Color lightBg;

  const ExpiryUrgency(this.label, this.baseColor, this.darkBg, this.lightBg);
}

class ReminderRuleModel {
  final int daysBeforeExpiry;
  final bool enabled;

  const ReminderRuleModel(
      {required this.daysBeforeExpiry, this.enabled = true});

  factory ReminderRuleModel.fromJson(Map<String, dynamic> json) =>
      ReminderRuleModel(
        daysBeforeExpiry: json['daysBeforeExpiry'] as int,
        enabled: json['enabled'] as bool? ?? true,
      );
}

class TrackedDocument {
  final String id;
  final String userId;
  final DocumentType type;
  final String title;
  final DateTime expiryDate;
  final String? notes;
  final String? providerName;
  final double? renewalAmount;
  final BillingCycle? billingCycle;
  final bool isArchived;
  final List<ReminderRuleModel> reminderRules;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TrackedDocument({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.expiryDate,
    this.notes,
    this.providerName,
    this.renewalAmount,
    this.billingCycle,
    this.isArchived = false,
    this.reminderRules = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  int get daysRemaining {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    return target.difference(today).inDays;
  }

  ExpiryUrgency get urgency {
    final days = daysRemaining;
    if (days <= 0) return ExpiryUrgency.expired;
    if (days <= 7) return ExpiryUrgency.critical;
    if (days <= 30) return ExpiryUrgency.expiringSoon;
    if (days <= 90) return ExpiryUrgency.upcoming;
    return ExpiryUrgency.valid;
  }

  factory TrackedDocument.fromJson(Map<String, dynamic> json) {
    final rules = (json['reminderRules'] as List<dynamic>?)
            ?.map((r) => ReminderRuleModel.fromJson(r as Map<String, dynamic>))
            .toList() ??
        [];

    return TrackedDocument(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: DocumentType.fromCode(json['type'] as String),
      title: json['title'] as String,
      expiryDate: DateTime.parse(json['expiryDate'] as String),
      notes: json['notes'] as String?,
      providerName: json['providerName'] as String?,
      renewalAmount: json['renewalAmount'] != null
          ? (json['renewalAmount'] as num).toDouble()
          : null,
      billingCycle: BillingCycle.fromCode(json['billingCycle'] as String?),
      isArchived: json['isArchived'] as bool? ?? false,
      reminderRules: rules,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
