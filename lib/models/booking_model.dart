import 'package:hive/hive.dart';

part 'booking_model.g.dart';

enum BookingStatus {
  pending,
  accepted,
  inProgress,
  completed,
  rejected,
  cancelled
}

@HiveType(typeId: 3)
class Booking extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String workerId;

  @HiveField(3)
  final String serviceId;

  @HiveField(4)
  final String problemDescription;

  @HiveField(5)
  final List<String> problemImages;

  @HiveField(6)
  final String location;

  @HiveField(7)
  final String alternatePhone;

  @HiveField(8)
  final double basePrice;

  @HiveField(9)
  final double additionalPrice;

  @HiveField(10)
  final double totalPrice;

  @HiveField(11)
  final String paymentMethod;

  @HiveField(12)
  final bool isPaid;

  @HiveField(13)
  final DateTime bookingTime;

  @HiveField(14)
  final DateTime? serviceTime;

  @HiveField(15)
  final DateTime? completionTime;

  @HiveField(16)
  final BookingStatus status;

  @HiveField(17)
  final double? rating;

  @HiveField(18)
  final String? review;

  Booking({
    required this.id,
    required this.userId,
    required this.workerId,
    required this.serviceId,
    required this.problemDescription,
    this.problemImages = const [],
    required this.location,
    required this.alternatePhone,
    required this.basePrice,
    this.additionalPrice = 0.0,
    required this.totalPrice,
    required this.paymentMethod,
    this.isPaid = false,
    required this.bookingTime,
    this.serviceTime,
    this.completionTime,
    this.status = BookingStatus.pending,
    this.rating,
    this.review,
  });

  Booking copyWith({
    String? id,
    String? userId,
    String? workerId,
    String? serviceId,
    String? problemDescription,
    List<String>? problemImages,
    String? location,
    String? alternatePhone,
    double? basePrice,
    double? additionalPrice,
    double? totalPrice,
    String? paymentMethod,
    bool? isPaid,
    DateTime? bookingTime,
    DateTime? serviceTime,
    DateTime? completionTime,
    BookingStatus? status,
    double? rating,
    String? review,
  }) {
    return Booking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      workerId: workerId ?? this.workerId,
      serviceId: serviceId ?? this.serviceId,
      problemDescription: problemDescription ?? this.problemDescription,
      problemImages: problemImages ?? this.problemImages,
      location: location ?? this.location,
      alternatePhone: alternatePhone ?? this.alternatePhone,
      basePrice: basePrice ?? this.basePrice,
      additionalPrice: additionalPrice ?? this.additionalPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      isPaid: isPaid ?? this.isPaid,
      bookingTime: bookingTime ?? this.bookingTime,
      serviceTime: serviceTime ?? this.serviceTime,
      completionTime: completionTime ?? this.completionTime,
      status: status ?? this.status,
      rating: rating ?? this.rating,
      review: review ?? this.review,
    );
  }
}
