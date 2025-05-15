import 'package:hive/hive.dart';

part 'subscription_model.g.dart';

@HiveType(typeId: 4)
class Subscription extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final double price;

  @HiveField(4)
  final int durationMonths;

  @HiveField(5)
  final int servicesPerMonth;

  @HiveField(6)
  final List<String> includedServiceCategories;

  Subscription({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.durationMonths,
    required this.servicesPerMonth,
    required this.includedServiceCategories,
  });
}

@HiveType(typeId: 5)
class UserSubscription extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String subscriptionId;

  @HiveField(3)
  final DateTime startDate;

  @HiveField(4)
  final DateTime endDate;

  @HiveField(5)
  final int servicesUsedThisMonth;

  @HiveField(6)
  final int totalServicesUsed;

  UserSubscription({
    required this.id,
    required this.userId,
    required this.subscriptionId,
    required this.startDate,
    required this.endDate,
    this.servicesUsedThisMonth = 0,
    this.totalServicesUsed = 0,
  });

  UserSubscription copyWith({
    String? id,
    String? userId,
    String? subscriptionId,
    DateTime? startDate,
    DateTime? endDate,
    int? servicesUsedThisMonth,
    int? totalServicesUsed,
  }) {
    return UserSubscription(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      servicesUsedThisMonth: servicesUsedThisMonth ?? this.servicesUsedThisMonth,
      totalServicesUsed: totalServicesUsed ?? this.totalServicesUsed,
    );
  }
}
