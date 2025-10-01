import 'package:flutter/material.dart';
import '../services/greeting_service.dart';

class CustomAppBar extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 12),
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
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  GreetingService.getSessionGreeting(),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[600],
                  ),
                ),
                if (userName != null && userName!.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Text(
                      userName!,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onPeoplePressed != null)
                Container(
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
                  child: IconButton(
                    padding: EdgeInsets.all(10),
                    constraints: BoxConstraints(minWidth: 42, minHeight: 42),
                    onPressed: onPeoplePressed,
                    icon: Icon(
                      Icons.people_outline,
                      color: Colors.purple,
                      size: 20,
                    ),
                  ),
                ),
              if (onPeoplePressed != null) SizedBox(width: 8),
              if (onSummaryPressed != null)
                Container(
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
                  child: IconButton(
                    padding: EdgeInsets.all(10),
                    constraints: BoxConstraints(minWidth: 42, minHeight: 42),
                    onPressed: onSummaryPressed,
                    icon: Icon(
                      Icons.analytics_outlined,
                      color: Colors.blue,
                      size: 22,
                    ),
                  ),
                ),
              if (onSummaryPressed != null) SizedBox(width: 8),
              if (onSettingsPressed != null)
                Container(
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
                  child: IconButton(
                    padding: EdgeInsets.all(10),
                    constraints: BoxConstraints(minWidth: 42, minHeight: 42),
                    onPressed: onSettingsPressed,
                    icon: Icon(
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