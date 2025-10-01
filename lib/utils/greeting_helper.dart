class GreetingHelper {
  static String getGreeting() {
    final hour = DateTime.now().hour;
    final greetings = {
      'early_morning': [
        'Rise and shine',
        'Fresh start',
        'New day, new light'
      ],
      'morning': [
        'Good morning!',
        'Bright morning!',
        'Hello, sunshine',
        'Feeling fresh?',
        'Feels good, right?'
      ],
      'afternoon': [
        'Good afternoon!',
        "Hope you're well",
        'Shining bright?',
        'Midday boost!',
        "Happy you're back"
      ],
      'evening': [
        'Good evening',
        'Evening',
        'Winding down',
        'Good evening!',
        'Evening calm',
        'Unwind time',
        'Sunset vibes'
      ],
      'night': [
        'Missed you',
        'Welcome back',
        'Time to relax',
        'Nighty night',
        'Rest easy',
        'Peaceful night'
      ],
      'weekend': [
        'Happy weekend',
        'Enjoy your weekend',
        'Weekend vibes',
        'Relax and enjoy'
      ],
      'welcome': [
        'Missed you',
        'Welcome back',
        'Great to see you',
        'Hello there',
        'Missed you',
        'There you are!',
        'Hey again!'
      ],
    };

    final now = DateTime.now();
    final isWeekend =
        now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;

    if (DateTime.now().millisecond % 5 == 0) {
      final welcomeMessages = greetings['welcome']!;
      final greeting = welcomeMessages[DateTime.now().second % welcomeMessages.length];
      return '$greeting,';
    }

    if (isWeekend && DateTime.now().millisecond % 3 == 0) {
      final weekendMessages = greetings['weekend']!;
      final greeting = weekendMessages[DateTime.now().second % weekendMessages.length];
      return '$greeting,';
    }

    List<String> timeBasedGreetings;
    if (hour < 12) {
      if (hour < 9) {
        timeBasedGreetings = greetings['early_morning']!;
      } else {
        timeBasedGreetings = greetings['morning']!;
      }
    } else if (hour < 17) {
      timeBasedGreetings = greetings['afternoon']!;
    } else if (hour < 20) {
      timeBasedGreetings = greetings['evening']!;
    } else {
      timeBasedGreetings = greetings['night']!;
    }

    final greeting = timeBasedGreetings[
        DateTime.now().second % timeBasedGreetings.length];

    return '$greeting,';
  }
}
