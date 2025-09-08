import 'package:hive/hive.dart';

part 'person_contact.g.dart';

@HiveType(typeId: 3)
class PersonContact extends HiveObject {
  @HiveField(0)
  String personName;

  @HiveField(1)
  String phoneNumber;

  @HiveField(2)
  DateTime lastUpdated;

  PersonContact({
    required this.personName,
    required this.phoneNumber,
    required this.lastUpdated,
  });
}