import 'package:flutter/material.dart';
import '../services/people_hive_service.dart';
import '../services/hive_service.dart';
import '../models/person_summary.dart';
import '../widgets/add_people_transaction_modal.dart';
import '../widgets/person_summary_card.dart';
import '../widgets/custom_snackbar.dart';
import 'person_detail_screen.dart';

class PeopleManagerScreen extends StatefulWidget {
  const PeopleManagerScreen({Key? key}) : super(key: key);

  @override
  PeopleManagerScreenState createState() => PeopleManagerScreenState();
}

class PeopleManagerScreenState extends State<PeopleManagerScreen> {
  List<PersonSummary> _activePeople = [];
  List<PersonSummary> _settledPeople = [];
  double _youOwe = 0.0;
  double _owesYou = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Public method to refresh data from parent
  void refreshData() {
    _loadData();
  }

  void _loadData() {
    if (!mounted) return;

    try {
      final allPeople = PeopleHiveService.getAllPeopleSummaries();

      setState(() {
        // Separate active and settled people
        _activePeople = allPeople.where((person) => !person.isSettled).toList();
        _settledPeople = allPeople.where((person) => person.isSettled).toList();

        // Calculate amounts you owe and amounts owed to you
        _youOwe = 0.0;
        _owesYou = 0.0;

        for (final person in _activePeople) {
          if (person.totalBalance > 0) {
            _owesYou += person.totalBalance; // People owe you
          } else if (person.totalBalance < 0) {
            _youOwe += person.totalBalance.abs(); // You owe people
          }
        }
      });
    } catch (e) {
      // Handle any potential errors gracefully
      if (mounted) {
        CustomSnackBar.show(context, 'Error loading data', SnackBarType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'People Manager',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadData();
        },
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildQuickStats(),
              SizedBox(height: 32),
              _buildActivePeopleList(),
              if (_settledPeople.isNotEmpty) ...[
                SizedBox(height: 32),
                _buildSettledPeopleList(),
              ],
              // Add bottom padding for navigation bar
              SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Owes You',
            _owesYou,
            Colors.green,
            Icons.arrow_downward,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'You Owe',
            _youOwe,
            Colors.red,
            Icons.arrow_upward,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, double amount, Color color, IconData icon) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            color.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivePeopleList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.account_circle,
              color: Colors.grey[350],
              size: 24,
            ),
            SizedBox(width: 8),
            Text(
              'Active',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[350],
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        if (_activePeople.isEmpty)
          Container(
            height: 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No active transactions with people yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap the + button to add your first transaction',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _activePeople.length,
            itemBuilder: (context, index) {
              final person = _activePeople[index];
              return PersonSummaryCard(
                person: person,
                onTap: () => _navigateToPersonDetail(person.name),
                showTimeAgo: false, // Don't show time ago in people manager
              );
            },
          ),
      ],
    );
  }

  Widget _buildSettledPeopleList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.verified,
              color: Colors.grey[600],
              size: 24,
            ),
            SizedBox(width: 8),
            Text(
              'Settled',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: _settledPeople.length,
          itemBuilder: (context, index) {
            final person = _settledPeople[index];
            return PersonSummaryCard(
              person: person,
              onTap: () => _navigateToPersonDetail(person.name),
              showTimeAgo: false, // Don't show time ago in people manager
              isSettled: true, // Special styling for settled people
            );
          },
        ),
      ],
    );
  }

  void _navigateToPersonDetail(String personName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PersonDetailScreen(personName: personName),
      ),
    ).then((_) => _loadData());
  }
}
