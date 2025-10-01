import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/share_service.dart';
import '../services/contact_service.dart';
import '../services/transaction_analysis_service.dart';
import '../models/person_summary.dart';
import '../models/people_transaction.dart';
import '../widgets/custom_snackbar.dart';

class ShareModal extends StatefulWidget {
  final PersonSummary person;
  final List<PeopleTransaction> allTransactions;

  const ShareModal({
    Key? key,
    required this.person,
    required this.allTransactions,
  }) : super(key: key);

  @override
  _ShareModalState createState() => _ShareModalState();
}

class _ShareModalState extends State<ShareModal> with TickerProviderStateMixin {
  late TextEditingController _phoneController;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late FocusNode _phoneFocus;
  bool _isLoading = false;

  // Transaction selection variables
  int _selectedTransactionCount = 5;
  late int _maxTransactions;
  bool _useDefaultMode = true; // New: Default vs Custom mode
  late List<PeopleTransaction> _defaultTransactions;
  late double _defaultBalance;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _phoneFocus = FocusNode();
    _maxTransactions = widget.allTransactions.length;

    // Calculate default transactions (above last settlement)
    _defaultTransactions =
        TransactionAnalysisService.getTransactionsAboveLastSettlement(
            widget.allTransactions);
    _defaultBalance = TransactionAnalysisService.getBalanceAboveLastSettlement(
        widget.allTransactions);

    // Set default transaction count (max 10 or total available)
    _selectedTransactionCount = (_maxTransactions < 5) ? _maxTransactions : 5;

    // Load existing phone number if available
    final existingPhone =
        ContactService.getPersonPhoneNumber(widget.person.name);
    _phoneController = TextEditingController(text: existingPhone ?? '');

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _phoneController.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  List<PeopleTransaction> get _selectedTransactions {
    if (_useDefaultMode) {
      return _defaultTransactions;
    } else {
      return widget.allTransactions.take(_selectedTransactionCount).toList();
    }
  }

  List<PeopleTransaction> get _previousTransactions {
    if (_useDefaultMode) {
      // For default mode, previous transactions are everything below the last settlement
      final settlementPoints = TransactionAnalysisService.findSettlementPoints(
          widget.allTransactions);
      if (settlementPoints.isEmpty) {
        return [];
      }
      // Get the last (most recent) settlement point
      final lastSettlementIndex = settlementPoints.last;
      return widget.allTransactions.sublist(lastSettlementIndex + 1);
    }

    if (_selectedTransactionCount >= widget.allTransactions.length) {
      return [];
    }
    return widget.allTransactions.skip(_selectedTransactionCount).toList();
  }

  double get _previousTransactionsBalance {
    if (_useDefaultMode) {
      return TransactionAnalysisService.getPreviousBalance(
          widget.allTransactions);
    }

    return _previousTransactions.fold<double>(
      0.0,
      (sum, transaction) => sum + transaction.balanceImpact,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              // Background overlay
              FadeTransition(
                opacity: _fadeAnimation,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    color: Colors.black.withOpacity(0.5),
                  ),
                ),
              ),
              // Modal content
              Transform.translate(
                offset: Offset(0,
                    _slideAnimation.value * MediaQuery.of(context).size.height),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.85,
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(24)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildHeader(),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildPhoneNumberField(),
                                SizedBox(height: 24),
                                _buildShareModeSelector(),
                                SizedBox(height: 24),
                                if (!_useDefaultMode)
                                  _buildTransactionSelector(),
                                if (!_useDefaultMode) SizedBox(height: 24),
                                _buildPreview(),
                                SizedBox(height: 32),
                                _buildShareOptions(),
                                SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: 16), // Reduced from 20 to 16
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.share,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Share with ${widget.person.name}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.titleLarge?.color,
                      ),
                    ),
                    Text(
                      'Send transaction summary',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneNumberField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Phone Number',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.titleMedium?.color,
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: TextField(
            controller: _phoneController,
            focusNode: _phoneFocus,
            keyboardType: TextInputType.phone,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
            decoration: InputDecoration(
              hintText: 'Enter 10-digit phone number',
              hintStyle: TextStyle(
                color: Colors.grey[500],
                fontSize: 16,
              ),
              prefixIcon: Icon(
                Icons.phone_outlined,
                color: Theme.of(context).primaryColor,
              ),
              prefixText: '+91 ',
              prefixStyle: TextStyle(
                color: Theme.of(context).primaryColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Theme.of(context).primaryColor,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: Colors.transparent,
              contentPadding: EdgeInsets.all(20),
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            onChanged: (value) {
              // Auto-save phone number as user types
              if (value.length == 10) {
                ContactService.savePersonContact(widget.person.name, value);
              }
            },
          ),
        ),
        SizedBox(height: 8),
        Text(
          'This number will be saved for future sharing',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildShareModeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Share Mode',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.titleMedium?.color,
          ),
        ),
        SizedBox(height: 12),

        Container(
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              // Default Mode
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _useDefaultMode = true;
                    });
                    HapticFeedback.lightImpact();
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    decoration: BoxDecoration(
                      color: _useDefaultMode
                          ? Theme.of(context).primaryColor
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          color: _useDefaultMode
                              ? Colors.white
                              : Theme.of(context).primaryColor,
                          size: 20,
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Default',
                          style: TextStyle(
                            color: _useDefaultMode
                                ? Colors.white
                                : Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Since last settlement',
                          style: TextStyle(
                            color: _useDefaultMode
                                ? Colors.white.withOpacity(0.8)
                                : Colors.grey[600],
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              // Custom Mode
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _useDefaultMode = false;
                    });
                    HapticFeedback.lightImpact();
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    decoration: BoxDecoration(
                      color:
                          !_useDefaultMode ? Colors.purple : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.tune,
                          color:
                              !_useDefaultMode ? Colors.white : Colors.purple,
                          size: 20,
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Custom',
                          style: TextStyle(
                            color:
                                !_useDefaultMode ? Colors.white : Colors.purple,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Choose count',
                          style: TextStyle(
                            color: !_useDefaultMode
                                ? Colors.white.withOpacity(0.8)
                                : Colors.grey[600],
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 12),

        // Mode description
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: (_useDefaultMode
                    ? Theme.of(context).primaryColor
                    : Colors.purple)
                .withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (_useDefaultMode
                      ? Theme.of(context).primaryColor
                      : Colors.purple)
                  .withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _useDefaultMode ? Icons.info_outline : Icons.settings,
                color: _useDefaultMode
                    ? Theme.of(context).primaryColor
                    : Colors.purple,
                size: 16,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  _useDefaultMode
                      ? 'Shares ${_defaultTransactions.length} transactions since last settlement (₹${_defaultBalance.abs().toStringAsFixed(2)})'
                      : 'Choose how many recent transactions to share',
                  style: TextStyle(
                    color: _useDefaultMode
                        ? Theme.of(context).primaryColor
                        : Colors.purple,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transactions to Share',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.titleMedium?.color,
          ),
        ),
        SizedBox(height: 16),

        // Custom transaction count selector
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.format_list_numbered,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Number of Transactions',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$_selectedTransactionCount',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Slider for transaction count
              if (_maxTransactions > 1)
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Theme.of(context).primaryColor,
                    inactiveTrackColor:
                        Theme.of(context).primaryColor.withOpacity(0.3),
                    thumbColor: Theme.of(context).primaryColor,
                    overlayColor:
                        Theme.of(context).primaryColor.withOpacity(0.2),
                    valueIndicatorColor: Theme.of(context).primaryColor,
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: _selectedTransactionCount.toDouble(),
                    min: 1,
                    max: _maxTransactions.toDouble(),
                    divisions:
                        _maxTransactions > 1 ? _maxTransactions - 1 : null,
                    label: '$_selectedTransactionCount transactions',
                    onChanged: (value) {
                      setState(() {
                        _selectedTransactionCount = value.round();
                      });
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreview() {
    String shareText;

    if (_useDefaultMode) {
      shareText = ShareService.generateDefaultShareText(
        widget.person,
        _defaultTransactions,
        _defaultBalance,
      );
    } else {
      shareText = ShareService.generateShareTextWithPreviousBalance(
        widget.person,
        _selectedTransactions,
        _previousTransactionsBalance,
        _previousTransactions.isNotEmpty,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.preview,
              color: Theme.of(context).primaryColor,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              'Message Preview',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.titleMedium?.color,
              ),
            ),
            Spacer(),
            Text(
              _useDefaultMode
                  ? '${_defaultTransactions.length} transactions (default)'
                  : '${_selectedTransactions.length} transactions (custom)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _useDefaultMode
                    ? Theme.of(context).primaryColor
                    : Colors.purple,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Container(
          height: 200,
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.withOpacity(0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Text(
              shareText,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShareOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Share Options',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.titleMedium?.color,
          ),
        ),
        SizedBox(height: 16),

        // Share options in a row with consistent theming
        Row(
          children: [
            // More Options - 30% width with consistent button style
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.2),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _shareAsText,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.share, size: 18),
                      SizedBox(height: 4),
                      Text(
                        'More',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: 12),
            // WhatsApp - 70% width with enhanced styling
            Expanded(
              flex: 7,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF25D366).withOpacity(0.3),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _shareViaWhatsApp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF25D366), // WhatsApp green
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.chat, size: 16, color: Colors.white),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Send via WhatsApp',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _shareViaWhatsApp() async {
    if (!_validatePhoneNumber()) return;

    setState(() => _isLoading = true);

    try {
      final phoneNumber = '+91${_phoneController.text.trim()}';

      String message;
      if (_useDefaultMode) {
        message = ShareService.generateDefaultShareText(
          widget.person,
          _defaultTransactions,
          _defaultBalance,
        );
      } else {
        message = ShareService.generateShareTextWithPreviousBalance(
          widget.person,
          _selectedTransactions,
          _previousTransactionsBalance,
          _previousTransactions.isNotEmpty,
        );
      }

      await ContactService.savePersonContact(
          widget.person.name, _phoneController.text.trim());
      await ShareService.shareViaWhatsApp(phoneNumber, message);

      Navigator.pop(context);
      CustomSnackBar.show(
          context, 'Shared via WhatsApp successfully!', SnackBarType.success);
    } catch (e) {
      CustomSnackBar.show(context,
          'Failed to share via WhatsApp: ${e.toString()}', SnackBarType.error);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _shareAsText() async {
    setState(() => _isLoading = true);

    try {
      String message;
      if (_useDefaultMode) {
        message = ShareService.generateDefaultShareText(
          widget.person,
          _defaultTransactions,
          _defaultBalance,
        );
      } else {
        message = ShareService.generateShareTextWithPreviousBalance(
          widget.person,
          _selectedTransactions,
          _previousTransactionsBalance,
          _previousTransactions.isNotEmpty,
        );
      }

      if (_phoneController.text.trim().isNotEmpty) {
        await ContactService.savePersonContact(
            widget.person.name, _phoneController.text.trim());
      }

      await ShareService.shareAsText(message);

      Navigator.pop(context);
      CustomSnackBar.show(
          context, 'Share options opened!', SnackBarType.success);
    } catch (e) {
      CustomSnackBar.show(
          context, 'Failed to share: ${e.toString()}', SnackBarType.error);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _validatePhoneNumber() {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      CustomSnackBar.show(
          context, 'Please enter a phone number', SnackBarType.warning);
      return false;
    }
    if (phone.length != 10) {
      CustomSnackBar.show(context, 'Please enter a valid 10-digit phone number',
          SnackBarType.warning);
      return false;
    }
    return true;
  }
}
