// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'revenue_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RevenueModelAdapter extends TypeAdapter<RevenueModel> {
  @override
  final int typeId = 1;

  @override
  RevenueModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RevenueModel(
      id: fields[0] as String,
      name: fields[1] as String,
      amount: fields[2] as double,
      isRegular: fields[3] as bool,
      date: fields[4] as DateTime,
      accountId: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, RevenueModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(6)
      ..write(obj.accountId)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.isRegular)
      ..writeByte(4)
      ..write(obj.date);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RevenueModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
