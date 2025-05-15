import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0)
class User extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String email;

  @HiveField(3)
  final String password;

  @HiveField(4)
  final String phone;

  @HiveField(5)
  final String address;

  @HiveField(6)
  final List<String> bookingHistory;

  @HiveField(7)
  final List<String> activeSubscriptions;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.phone,
    required this.address,
    this.bookingHistory = const [],
    this.activeSubscriptions = const [],
  });

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? password,
    String? phone,
    String? address,
    List<String>? bookingHistory,
    List<String>? activeSubscriptions,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      bookingHistory: bookingHistory ?? this.bookingHistory,
      activeSubscriptions: activeSubscriptions ?? this.activeSubscriptions,
    );
  }
}
