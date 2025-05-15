// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BookingAdapter extends TypeAdapter<Booking> {
  @override
  final int typeId = 3;

  @override
  Booking read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Booking(
      id: fields[0] as String,
      userId: fields[1] as String,
      workerId: fields[2] as String,
      serviceId: fields[3] as String,
      problemDescription: fields[4] as String,
      problemImages: (fields[5] as List).cast<String>(),
      location: fields[6] as String,
      alternatePhone: fields[7] as String,
      basePrice: fields[8] as double,
      additionalPrice: fields[9] as double,
      totalPrice: fields[10] as double,
      paymentMethod: fields[11] as String,
      isPaid: fields[12] as bool,
      bookingTime: fields[13] as DateTime,
      serviceTime: fields[14] as DateTime?,
      completionTime: fields[15] as DateTime?,
      status: fields[16] as BookingStatus,
      rating: fields[17] as double?,
      review: fields[18] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Booking obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.workerId)
      ..writeByte(3)
      ..write(obj.serviceId)
      ..writeByte(4)
      ..write(obj.problemDescription)
      ..writeByte(5)
      ..write(obj.problemImages)
      ..writeByte(6)
      ..write(obj.location)
      ..writeByte(7)
      ..write(obj.alternatePhone)
      ..writeByte(8)
      ..write(obj.basePrice)
      ..writeByte(9)
      ..write(obj.additionalPrice)
      ..writeByte(10)
      ..write(obj.totalPrice)
      ..writeByte(11)
      ..write(obj.paymentMethod)
      ..writeByte(12)
      ..write(obj.isPaid)
      ..writeByte(13)
      ..write(obj.bookingTime)
      ..writeByte(14)
      ..write(obj.serviceTime)
      ..writeByte(15)
      ..write(obj.completionTime)
      ..writeByte(16)
      ..write(obj.status)
      ..writeByte(17)
      ..write(obj.rating)
      ..writeByte(18)
      ..write(obj.review);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
