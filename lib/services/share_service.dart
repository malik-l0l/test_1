import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../models/people_transaction.dart';
import '../models/person_summary.dart';
import '../utils/date_formatter.dart';
import 'package:intl/intl.dart';

class ShareService {
  static String generateShareText(PersonSummary person, List<PeopleTransaction> transactions) {
    return generateShareTextWithPreviousBalance(person, transactions, 0.0, false);
  }

  static String generateDefaultShareText(
    PersonSummary person,
    List<PeopleTransaction> transactions,
    double currentBalance,
  ) {
    final StringBuffer buffer = StringBuffer();

    // Calculate totals
    double youGaveMe = 0;
    double iGaveYou = 0;

    for (final transaction in transactions) {
      if (transaction.balanceImpact < 0) {
        youGaveMe += transaction.amount;
      } else {
        iGaveYou += transaction.amount;
      }
    }

    // Header - Balance Summary
    buffer.writeln('**Balance Summary**');
    buffer.writeln();
    buffer.writeln('You gave me: ₹${youGaveMe.toStringAsFixed(0)}');
    buffer.writeln('I gave you: ₹${iGaveYou.toStringAsFixed(0)}');
    buffer.writeln('🔹 Balance: ₹${currentBalance.abs().toStringAsFixed(2)}');

    if (currentBalance > 0) {
      buffer.writeln('📌 You owe me ₹${currentBalance.abs().toStringAsFixed(2)}');
    } else if (currentBalance < 0) {
      buffer.writeln('📌 I owe you ₹${currentBalance.abs().toStringAsFixed(2)}');
    } else {
      buffer.writeln('📌 All settled up!');
    }

    buffer.writeln();
    buffer.writeln('--------------------------');
    buffer.writeln();

    if (transactions.isNotEmpty) {
      buffer.writeln('📅 **Transactions**');
      buffer.writeln();

      // Group transactions by date
      final groupedTransactions = _groupTransactionsByDate(transactions);

      // Display each date group
      for (final entry in groupedTransactions.entries) {
        buffer.writeln('${_formatDateHeader(entry.key)}');

        for (final transaction in entry.value) {
          final prefix = transaction.balanceImpact > 0 ? '+' : '-';
          final amount = '₹${transaction.amount.toStringAsFixed(0)}';
          final direction = _getTransactionDirectionSimple(transaction);
          final reason = _getTransactionReason(transaction);

          buffer.writeln('$prefix ${amount.padRight(7)} $direction ($reason)');
        }

        buffer.writeln();
      }
    }

    buffer.writeln('--------------------------');
    buffer.writeln();
    buffer.writeln('📱 Sent from *PACHAKUTHIRA APP*');

    return buffer.toString();
  }

  static String generateShareTextWithPreviousBalance(
    PersonSummary person,
    List<PeopleTransaction> transactions,
    double previousBalance,
    bool hasPreviousTransactions,
  ) {
    final StringBuffer buffer = StringBuffer();

    // Calculate totals
    double youGaveMe = 0;
    double iGaveYou = 0;

    for (final transaction in transactions) {
      if (transaction.balanceImpact < 0) {
        youGaveMe += transaction.amount;
      } else {
        iGaveYou += transaction.amount;
      }
    }

    // Add previous balance to totals
    if (hasPreviousTransactions && previousBalance != 0) {
      if (previousBalance < 0) {
        youGaveMe += previousBalance.abs();
      } else {
        iGaveYou += previousBalance.abs();
      }
    }

    // Header - Balance Summary
    buffer.writeln('**Balance Summary**');
    buffer.writeln();
    buffer.writeln('You gave me: ₹${youGaveMe.toStringAsFixed(0)}');
    buffer.writeln('I gave you: ₹${iGaveYou.toStringAsFixed(0)}');
    buffer.writeln('🔹 Balance: ₹${person.totalBalance.abs().toStringAsFixed(2)}');

    if (person.totalBalance > 0) {
      buffer.writeln('📌 You owe me ₹${person.totalBalance.abs().toStringAsFixed(2)}');
    } else if (person.totalBalance < 0) {
      buffer.writeln('📌 I owe you ₹${person.totalBalance.abs().toStringAsFixed(2)}');
    } else {
      buffer.writeln('📌 All settled up!');
    }

    buffer.writeln();
    buffer.writeln('--------------------------');
    buffer.writeln();

    if (transactions.isNotEmpty) {
      buffer.writeln('📅 **Transactions**');
      buffer.writeln();

      // Group transactions by date
      final groupedTransactions = _groupTransactionsByDate(transactions);

      // Display each date group
      for (final entry in groupedTransactions.entries) {
        buffer.writeln('${_formatDateHeader(entry.key)}');

        for (final transaction in entry.value) {
          final prefix = transaction.balanceImpact > 0 ? '+' : '-';
          final amount = '₹${transaction.amount.toStringAsFixed(0)}';
          final direction = _getTransactionDirectionSimple(transaction);
          final reason = _getTransactionReason(transaction);

          buffer.writeln('$prefix ${amount.padRight(7)} $direction ($reason)');
        }

        buffer.writeln();
      }
    }

    buffer.writeln('--------------------------');
    buffer.writeln();
    buffer.writeln('📱 Sent from *PACHAKUTHIRA APP*');

    return buffer.toString();
  }

  static Map<DateTime, List<PeopleTransaction>> _groupTransactionsByDate(List<PeopleTransaction> transactions) {
    final Map<DateTime, List<PeopleTransaction>> grouped = {};

    for (final transaction in transactions) {
      final date = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );

      if (!grouped.containsKey(date)) {
        grouped[date] = [];
      }
      grouped[date]!.add(transaction);
    }

    return grouped;
  }

  static String _formatDateHeader(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  static String _getTransactionDirection(PeopleTransaction transaction) {
    switch (transaction.transactionType) {
      case 'give':
        return '+ Me → You';
      case 'take':
        return '- You → Me (Cash)';
      case 'owe':
        return '- You → Me';
      case 'claim':
        return '+ Me → You (Held)';
      default:
        return transaction.isGiven
            ? '+ Me → You'
            : '- You → Me';
    }
  }

  static String _getTransactionDirectionSimple(PeopleTransaction transaction) {
    switch (transaction.transactionType) {
      case 'give':
        return 'Me → You';
      case 'take':
        return 'You → Me';
      case 'owe':
        return 'You → Me';
      case 'claim':
        return 'Me → You';
      default:
        return transaction.isGiven
            ? 'Me → You'
            : 'You → Me';
    }
  }

  static String _getTransactionReason(PeopleTransaction transaction) {
    switch (transaction.transactionType) {
      case 'take':
        return 'Cash - ${transaction.reason}';
      case 'claim':
        return 'Held for ${transaction.reason}';
      default:
        return transaction.reason;
    }
  }

  static String _getCleanActionText(PeopleTransaction transaction) {
    switch (transaction.transactionType) {
      case 'give':
        return 'I gave you for ${transaction.reason}';
      case 'take':
        return 'I took cash from you for ${transaction.reason}';
      case 'owe':
        return 'You paid for me for ${transaction.reason}';
      case 'claim':
        return 'You hold my money for ${transaction.reason}';
      default:
        return transaction.isGiven
            ? 'I gave you for ${transaction.reason}'
            : 'I took cash from you for ${transaction.reason}';
    }
  }

  static Future<void> shareViaWhatsApp(String phoneNumber, String message) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    final whatsappUrl = 'https://wa.me/$cleanNumber?text=${Uri.encodeComponent(message)}';

    if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
      await launchUrl(Uri.parse(whatsappUrl), mode: LaunchMode.externalApplication);
    } else {
      throw Exception('WhatsApp is not installed');
    }
  }

  static Future<void> shareAsText(String message) async {
    await Share.share(message, subject: 'Transaction Summary');
  }
}
