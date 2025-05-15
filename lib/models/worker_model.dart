import 'package:hive/hive.dart';

part 'worker_model.g.dart';

@HiveType(typeId: 1)
class Worker extends HiveObject {
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
  final String description;

  @HiveField(7)
  final List<String> skills;

  @HiveField(8)
  final double rating;

  @HiveField(9)
  final int completedJobs;

  @HiveField(10)
  final List<String> serviceHistory;

  @HiveField(11)
  final List<String> pendingRequests;

  @HiveField(12)
  final List<String> reviews;

  Worker({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.phone,
    required this.address,
    required this.description,
    required this.skills,
    this.rating = 0.0,
    this.completedJobs = 0,
    this.serviceHistory = const [],
    this.pendingRequests = const [],
    this.reviews = const [],
  });

  Worker copyWith({
    String? id,
    String? name,
    String? email,
    String? password,
    String? phone,
    String? address,
    String? description,
    List<String>? skills,
    double? rating,
    int? completedJobs,
    List<String>? serviceHistory,
    List<String>? pendingRequests,
    List<String>? reviews,
  }) {
    return Worker(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      description: description ?? this.description,
      skills: skills ?? this.skills,
      rating: rating ?? this.rating,
      completedJobs: completedJobs ?? this.completedJobs,
      serviceHistory: serviceHistory ?? this.serviceHistory,
      pendingRequests: pendingRequests ?? this.pendingRequests,
      reviews: reviews ?? this.reviews,
    );
  }
}
