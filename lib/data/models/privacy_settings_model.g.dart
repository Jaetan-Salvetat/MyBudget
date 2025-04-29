// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'privacy_settings_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PrivacySettingsModelAdapter extends TypeAdapter<PrivacySettingsModel> {
  @override
  final int typeId = 6;

  @override
  PrivacySettingsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PrivacySettingsModel(
      privacyPolicyAccepted: fields[0] as bool,
      marketingConsent: fields[1] as bool,
      consentDate: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, PrivacySettingsModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj._privacyPolicyAccepted)
      ..writeByte(1)
      ..write(obj._marketingConsent)
      ..writeByte(2)
      ..write(obj._consentDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrivacySettingsModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
