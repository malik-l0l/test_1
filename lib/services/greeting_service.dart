import '../utils/greeting_helper.dart';

class GreetingService {
  static String? _sessionGreeting;

  static String getSessionGreeting() {
    if (_sessionGreeting == null) {
      _sessionGreeting = GreetingHelper.getGreeting();
    }
    return _sessionGreeting!;
  }

  static void resetGreeting() {
    _sessionGreeting = null;
  }
}
