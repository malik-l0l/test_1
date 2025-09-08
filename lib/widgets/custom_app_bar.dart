import 'package:flutter/material.dart';

class CustomAppBar extends StatefulWidget {
  final VoidCallback? onSettingsPressed;
  final VoidCallback? onSummaryPressed;
  final VoidCallback? onPeoplePressed;
  final String? userName;

  const CustomAppBar({
    Key? key,
    this.onSettingsPressed,
    this.onSummaryPressed,
    this.onPeoplePressed,
    this.userName,
  }) : super(key: key);

  @override
  _CustomAppBarState createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  late String _fixedGreeting;

  @override
  void initState() {
    super.initState();
    _fixedGreeting = _getGreeting();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    final greetings = {
      // Early morning (5-8 AM)
      'early_morning': [
        'Rise and shine',
        'Fresh start',
        'New day, new light'
      ],
      // Morning (9-11 AM)
      'morning': [
        'Good morning!',
        'Bright morning!',
        'Hello, sunshine',
        'Feeling fresh?',
        'Feels good, right?'
      ],
      // Afternoon (12-4 PM)
      'afternoon': [
        'Good afternoon!',
        "Hope you're well",
        'Shining bright?',
        'Midday boost!',
        "Happy you're back"
      ],
      // Evening (5-7 PM)
      'evening': [
        'Good evening',
        'Evening',
        'Winding down',
        'Good evening!',
        'Evening calm',
        'Unwind time',
        'Sunset vibes'
      ],
      // Night (8 PM+)
      'night': [
        'Missed you',
        'Welcome back',
        'Time to relax',
        'Nighty night',
        'Rest easy',
        'Peaceful night'
      ],
      // Weekend specific
      'weekend': [
        'Happy weekend',
        'Enjoy your weekend',
        'Weekend vibes',
        'Relax and enjoy'
      ],
      // Welcome back (random)
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

    // 20% chance for welcome message
    if (DateTime.now().millisecond % 5 == 0) {
      final welcomeMessages = greetings['welcome']!;
      return welcomeMessages[DateTime.now().second % welcomeMessages.length];
    }

    // Weekend specific greetings (30% chance on weekends)
    if (isWeekend && DateTime.now().millisecond % 3 == 0) {
      final weekendMessages = greetings['weekend']!;
      return weekendMessages[DateTime.now().second % weekendMessages.length];
    }

    // Time-based greetings
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

    // Return random greeting from the appropriate time category
    return timeBasedGreetings[
        DateTime.now().second % timeBasedGreetings.length];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_fixedGreeting},',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w300,
                    color: Colors.grey[600],
                  ),
                ),
                if (widget.userName != null && widget.userName!.isNotEmpty)
                  Text(
                    widget.userName!,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          Row(
            children: [
              if (widget.onPeoplePressed != null)
                IconButton(
                  onPressed: widget.onPeoplePressed,
                  icon: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.people_outline,
                      color: Colors.purple,
                      size: 20,
                    ),
                  ),
                ),
              SizedBox(width: 8),
              if (widget.onSummaryPressed != null)
                IconButton(
                  onPressed: widget.onSummaryPressed,
                  icon: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.bar_chart_rounded,
                      color: Colors.blue,
                      size: 20,
                    ),
                  ),
                ),
              SizedBox(width: 8),
              if (widget.onSettingsPressed != null)
                IconButton(
                  onPressed: widget.onSettingsPressed,
                  icon: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.settings_outlined,
                      color: Theme.of(context).primaryColor,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}