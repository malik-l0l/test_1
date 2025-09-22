import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../models/people_transaction.dart';
import '../models/person_summary.dart';
import '../utils/date_formatter.dart';

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
    
    // Header with current balance summary
    if (currentBalance > 0) {
      buffer.writeln('💰 You owe ₹${currentBalance.abs().toStringAsFixed(2)} to me');
    } else if (currentBalance < 0) {
      buffer.writeln('💰 I owe ₹${currentBalance.abs().toStringAsFixed(2)} to you');
    } else {
      buffer.writeln('✅ We\'re all settled up!');
    }
    
    buffer.writeln();
    
    if (transactions.isNotEmpty) {
      buffer.writeln('📋 Transactions since last settlement:');
      buffer.writeln();
      
      // Display transactions from newest to oldest with clean format
      for (final transaction in transactions) {
        final emoji = transaction.balanceImpact > 0 ? '➕' : '➖';
        final actionText = _getCleanActionText(transaction);
        final dateText = DateFormatter.formatDate(transaction.date);
        
        buffer.writeln('$emoji ₹${transaction.amount.toStringAsFixed(0).padLeft(3)}  ($actionText)${' ' * (35 - actionText.length)}[$dateText]');
      }
      
      buffer.writeln('——————————————');
      
      if (currentBalance > 0) {
        buffer.writeln('💰 Current: ₹${currentBalance.abs().toStringAsFixed(2)} → You owe me');
      } else if (currentBalance < 0) {
        buffer.writeln('💰 Current: ₹${currentBalance.abs().toStringAsFixed(2)} → I owe you');
      } else {
        buffer.writeln('💰 Current: ₹0.00 → All settled!');
      }
    } else {
      buffer.writeln('📋 No transactions since last settlement');
    }
    
    buffer.writeln();
    buffer.writeln('📱 Sent from Money Manager App');
    
    return buffer.toString();
  }

  static String generateShareTextWithPreviousBalance(
    PersonSummary person, 
    List<PeopleTransaction> transactions, 
    double previousBalance,
    bool hasPreviousTransactions,
  ) {
    final StringBuffer buffer = StringBuffer();
    
    // Header with balance summary
    if (person.totalBalance > 0) {
      buffer.writeln('💰 You owe ₹${person.totalBalance.abs().toStringAsFixed(2)} to me');
    } else if (person.totalBalance < 0) {
      buffer.writeln('💰 I owe ₹${person.totalBalance.abs().toStringAsFixed(2)} to you');
    } else {
      buffer.writeln('✅ We\'re all settled up!');
    }
    
    buffer.writeln();
    
    if (transactions.isNotEmpty) {
      buffer.writeln('📋 Last ${transactions.length} transactions:');
      buffer.writeln();
      
      // Add previous transactions balance if there are older transactions
      if (hasPreviousTransactions && previousBalance != 0) {
        final emoji = previousBalance > 0 ? '➕' : '➖';
        final actionText = previousBalance > 0 
            ? 'from previous transactions (you owe me)'
            : 'from previous transactions (I owe you)';
        
        buffer.writeln('$emoji ₹${previousBalance.abs().toStringAsFixed(0).padLeft(3)}  ($actionText)');
      }
      
      // Display transactions from newest to oldest with clean format
      for (final transaction in transactions) {
        final emoji = transaction.balanceImpact > 0 ? '➕' : '➖';
        final actionText = _getCleanActionText(transaction);
        final dateText = DateFormatter.formatDate(transaction.date);
        
        buffer.writeln('$emoji ₹${transaction.amount.toStringAsFixed(0).padLeft(3)}  ($actionText)${' ' * (35 - actionText.length)}[$dateText]');
      }
      
      buffer.writeln('——————————————');
      
      if (person.totalBalance > 0) {
        buffer.writeln('💰 Total: ₹${person.totalBalance.abs().toStringAsFixed(2)} → You owe me');
      } else if (person.totalBalance < 0) {
        buffer.writeln('💰 Total: ₹${person.totalBalance.abs().toStringAsFixed(2)} → I owe you');
      } else {
        buffer.writeln('💰 Total: ₹0.00 → All settled!');
      }
    } else {
      buffer.writeln('📋 No recent transactions');
    }
    
    buffer.writeln();
    buffer.writeln('📱 Sent from Money Manager App');
    
    return buffer.toString();
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
    // Clean phone number (remove spaces, dashes, etc.)
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