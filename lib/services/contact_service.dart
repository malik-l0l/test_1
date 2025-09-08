import 'package:hive_flutter/hive_flutter.dart';
import '../models/person_contact.dart';

class ContactService {
  static late Box<PersonContact> _contactsBox;
  static const String contactsBoxName = 'person_contacts';

  static Future<void> init() async {
    _contactsBox = await Hive.openBox<PersonContact>(contactsBoxName);
  }

  static Future<void> savePersonContact(String personName, String phoneNumber) async {
    final contact = PersonContact(
      personName: personName,
      phoneNumber: phoneNumber,
      lastUpdated: DateTime.now(),
    );
    await _contactsBox.put(personName.toLowerCase(), contact);
  }

  static String? getPersonPhoneNumber(String personName) {
    final contact = _contactsBox.get(personName.toLowerCase());
    return contact?.phoneNumber;
  }

  static List<PersonContact> getAllContacts() {
    return _contactsBox.values.toList()
      ..sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
  }

  static Future<void> deleteContact(String personName) async {
    await _contactsBox.delete(personName.toLowerCase());
  }
}