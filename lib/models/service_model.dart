import 'package:hive/hive.dart';

part 'service_model.g.dart';

@HiveType(typeId: 2)
class Service extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String category;

  @HiveField(4)
  final double basePrice;

  @HiveField(5)
  final String imageUrl;

  @HiveField(6)
  final List<String> availableWorkers;

  Service({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.basePrice,
    required this.imageUrl,
    this.availableWorkers = const [],
  });

  Service copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    double? basePrice,
    String? imageUrl,
    List<String>? availableWorkers,
  }) {
    return Service(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      basePrice: basePrice ?? this.basePrice,
      imageUrl: imageUrl ?? this.imageUrl,
      availableWorkers: availableWorkers ?? this.availableWorkers,
    );
  }
}
