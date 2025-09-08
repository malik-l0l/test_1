// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'person_contact.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PersonContactAdapter extends TypeAdapter<PersonContact> {
  @override
  final int typeId = 3;

  @override
  PersonContact read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PersonContact(
      personName: fields[0] as String,
      phoneNumber: fields[1] as String,
      lastUpdated: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, PersonContact obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.personName)
      ..writeByte(1)
      ..write(obj.phoneNumber)
      ..writeByte(2)
      ..write(obj.lastUpdated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonContactAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
