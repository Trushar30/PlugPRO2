// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'worker_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WorkerAdapter extends TypeAdapter<Worker> {
  @override
  final int typeId = 1;

  @override
  Worker read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Worker(
      id: fields[0] as String,
      name: fields[1] as String,
      email: fields[2] as String,
      password: fields[3] as String,
      phone: fields[4] as String,
      address: fields[5] as String,
      description: fields[6] as String,
      skills: (fields[7] as List).cast<String>(),
      rating: fields[8] as double,
      completedJobs: fields[9] as int,
      serviceHistory: (fields[10] as List).cast<String>(),
      pendingRequests: (fields[11] as List).cast<String>(),
      reviews: (fields[12] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, Worker obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.password)
      ..writeByte(4)
      ..write(obj.phone)
      ..writeByte(5)
      ..write(obj.address)
      ..writeByte(6)
      ..write(obj.description)
      ..writeByte(7)
      ..write(obj.skills)
      ..writeByte(8)
      ..write(obj.rating)
      ..writeByte(9)
      ..write(obj.completedJobs)
      ..writeByte(10)
      ..write(obj.serviceHistory)
      ..writeByte(11)
      ..write(obj.pendingRequests)
      ..writeByte(12)
      ..write(obj.reviews);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkerAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
