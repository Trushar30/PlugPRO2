// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SubscriptionAdapter extends TypeAdapter<Subscription> {
  @override
  final int typeId = 4;

  @override
  Subscription read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Subscription(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      price: fields[3] as double,
      durationMonths: fields[4] as int,
      servicesPerMonth: fields[5] as int,
      includedServiceCategories: (fields[6] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, Subscription obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.price)
      ..writeByte(4)
      ..write(obj.durationMonths)
      ..writeByte(5)
      ..write(obj.servicesPerMonth)
      ..writeByte(6)
      ..write(obj.includedServiceCategories);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UserSubscriptionAdapter extends TypeAdapter<UserSubscription> {
  @override
  final int typeId = 5;

  @override
  UserSubscription read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserSubscription(
      id: fields[0] as String,
      userId: fields[1] as String,
      subscriptionId: fields[2] as String,
      startDate: fields[3] as DateTime,
      endDate: fields[4] as DateTime,
      servicesUsedThisMonth: fields[5] as int,
      totalServicesUsed: fields[6] as int,
    );
  }

  @override
  void write(BinaryWriter writer, UserSubscription obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.subscriptionId)
      ..writeByte(3)
      ..write(obj.startDate)
      ..writeByte(4)
      ..write(obj.endDate)
      ..writeByte(5)
      ..write(obj.servicesUsedThisMonth)
      ..writeByte(6)
      ..write(obj.totalServicesUsed);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSubscriptionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
