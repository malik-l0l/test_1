// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'people_transaction.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PeopleTransactionAdapter extends TypeAdapter<PeopleTransaction> {
  @override
  final int typeId = 2;

  @override
  PeopleTransaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PeopleTransaction(
      id: fields[0] as String,
      personName: fields[1] as String,
      amount: fields[2] as double,
      reason: fields[3] as String,
      date: fields[4] as DateTime,
      timestamp: fields[5] as DateTime,
      isGiven: fields[6] as bool,
      transactionType: fields[7] == null ? 'give' : fields[7] as String,
    );
  }

  @override
  void write(BinaryWriter writer, PeopleTransaction obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.personName)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.reason)
      ..writeByte(4)
      ..write(obj.date)
      ..writeByte(5)
      ..write(obj.timestamp)
      ..writeByte(6)
      ..write(obj.isGiven)
      ..writeByte(7)
      ..write(obj.transactionType);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PeopleTransactionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
