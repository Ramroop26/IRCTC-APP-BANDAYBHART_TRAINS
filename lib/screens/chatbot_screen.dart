import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/train_service.dart';
import '../services/booking_service.dart';
import '../models/booking.dart';
import '../theme.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final Widget? customWidget;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.customWidget,
  });
}

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final TrainService _trainService = TrainService();
  final BookingService _bookingService = BookingService();
  bool _isTyping = false;

  final List<String> _suggestions = [
    "Track Train 12302",
    "Track Train 22436",
    "Check PNR 4238910476",
    "Refund Rules Help",
  ];

  @override
  void initState() {
    super.initState();
    // Welcome message
    _messages.add(
      ChatMessage(
        text: "Namaste! I am your AI Assistant. 🌟\n\nHow can I help you today? You can ask me to track any train by typing 'track <train_number>' or check your PNR status!",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSendMessage(String text) {
    if (text.trim().isEmpty) return;
    _messageController.clear();

    setState(() {
      _messages.add(
        ChatMessage(
          text: text,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
      _isTyping = true;
    });
    _scrollToBottom();

    // Simulate AI response delay
    Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      _generateAiResponse(text);
    });
  }

  void _generateAiResponse(String userText) {
    final text = userText.toLowerCase().trim();
    String responseText = "";
    Widget? customWidget;

    // 1. Check for 5-digit Train Number (Train Tracking)
    final trainMatch = RegExp(r'\b\d{5}\b').firstMatch(text);
    // 2. Check for PNR (10-digit number)
    final pnrMatch = RegExp(r'\b\d{10}\b').firstMatch(text);

    if (trainMatch != null) {
      final String trainNum = trainMatch.group(0)!;
      try {
        final route = _trainService.getLiveRoute(trainNum);
        responseText = "I found Train #${route.trainNumber} (${route.trainName}). Let me fetch the live telemetry:";
        customWidget = _buildInlineTrainCard(route);
      } catch (e) {
        responseText = "I couldn't locate train number #$trainNum in the database. Please verify the digits.";
      }
    } else if (pnrMatch != null || text.contains("pnr")) {
      String pnrNum = "4238910476"; // default demo pnr
      if (pnrMatch != null) {
        pnrNum = pnrMatch.group(0)!;
      }
      final booking = _bookingService.findByPnr(pnrNum);
      if (booking != null) {
        responseText = "Booking status located for PNR: $pnrNum";
        customWidget = _buildInlinePnrCard(booking);
      } else {
        responseText = "PNR record $pnrNum could not be located in our active database. Please check and try again.";
      }
    } else if (text.contains("hi") || text.contains("hello") || text.contains("hey")) {
      responseText = "Namaste! I am your AI Assistant. How can I help you today? You can ask me to track trains or check your PNR status!";
    } else if (text.contains("refund") || text.contains("cancel")) {
      responseText = "Cancellation Rules:\n• A cancellation fee of ₹120 per passenger applies for confirmed tickets.\n• Cancellation is allowed up to 4 hours before scheduled departure.\n• Refunds are processed instantly to your eWallet.";
    } else if (text.contains("withdraw") || text.contains("withdrawal") || text.contains("transfer to bank")) {
      responseText = "Withdrawal Rules:\n• You can withdraw funds from your eWallet directly to your bank account.\n• Go to the 'eWallet' screen, tap on 'Withdraw to Bank', enter your Bank Name, Account Number, IFSC code, and the amount to withdraw.\n• The amount will be transferred securely to your bank account.";
    } else if (text.contains("deposit") || text.contains("add money") || text.contains("top up") || text.contains("wallet")) {
      responseText = "eWallet Deposit:\n• To add funds, navigate to the eWallet screen, enter the amount, and tap 'ADD MONEY'.\n• Select your bank (SBI, HDFC, ICICI, PNB) and payment method (NetBanking/UPI).\n• Authenticate and enter the OTP (123456) to successfully deposit money.";
    } else if (text.contains("general") || text.contains("gen")) {
      responseText = "Booking General Tickets:\n• To book general unreserved (GEN) tickets, go to 'Search Trains', input source/destination stations, select the train, and choose the 'GEN' class option during seat configuration.\n• Proceed to pay via eWallet to confirm your booking.";
    } else if (text.contains("aadhaar") || text.contains("kyc") || text.contains("limit")) {
      responseText = "Aadhaar KYC Benefits:\n• Verifying Aadhaar KYC raises your monthly booking limits from 12 tickets to 24 tickets.\n• It also unlocks higher limits on wallet deposits and withdrawals.\n• To link Aadhaar, go to 'Profile' from the dashboard, enter your Aadhaar number, and save.";
    } else {
      responseText = "I'm not sure I understood that fully. Try asking:\n• 'track train 12302' or 'pnr status'\n• 'How to deposit or withdraw money?'\n• 'What are the Aadhaar KYC limit benefits?'\n• 'How to book general (GEN) tickets?'\n• 'What are the refund rules?'";
    }

    setState(() {
      _isTyping = false;
      _messages.add(
        ChatMessage(
          text: responseText,
          isUser: false,
          timestamp: DateTime.now(),
          customWidget: customWidget,
        ),
      );
    });
    _scrollToBottom();
  }

  Widget _buildInlineTrainCard(LiveTrainRoute route) {
    final nextStation = route.stations[math.min(route.currentStationIndex + 1, route.stations.length - 1)];
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardNavy,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.goldAccent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    route.trainName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textWhite),
                  ),
                  Text(
                    "Train No: #${route.trainNumber}",
                    style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.successGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.speed_rounded, size: 10, color: AppTheme.successGreen),
                    SizedBox(width: 4),
                    Text(
                      "98 km/h",
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.successGreen),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(color: AppTheme.primaryLightNavy, height: 16),
          Row(
            children: [
              const Icon(Icons.radio_button_checked, size: 14, color: AppTheme.goldAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Last Passed: ${route.stations[route.currentStationIndex].name}",
                  style: const TextStyle(fontSize: 11, color: AppTheme.textWhite),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.arrow_right_alt, size: 14, color: AppTheme.textMuted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Next Stop: ${nextStation.name} (PF ${nextStation.platform})",
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: ElevatedButton.icon(
              onPressed: () {
                // Navigate to live status page with train number
                Navigator.pushNamed(context, '/live_status', arguments: route.trainNumber);
              },
              icon: const Icon(Icons.location_on_outlined, size: 14),
              label: const Text("VIEW LIVE RADAR MAP", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.goldAccent,
                foregroundColor: AppTheme.primaryNavy,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInlinePnrCard(Booking booking) {
    final isConfirmed = booking.status == "CONFIRMED";
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardNavy,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "PNR: ${booking.pnr}",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textWhite, letterSpacing: 1.0),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: (isConfirmed ? AppTheme.successGreen : AppTheme.errorRed).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  booking.status,
                  style: TextStyle(
                    fontSize: 9, 
                    fontWeight: FontWeight.bold, 
                    color: isConfirmed ? AppTheme.successGreen : AppTheme.errorRed,
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: AppTheme.primaryLightNavy, height: 16),
          Text(
            "Train: #${booking.train.number} - ${booking.train.name}",
            style: const TextStyle(fontSize: 11, color: AppTheme.textWhite),
          ),
          const SizedBox(height: 4),
          Text(
            "Date of Journey: ${booking.journeyDate}",
            style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 8),
          const Text(
            "PASSENGER MANIFEST:",
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.goldAccent),
          ),
          const SizedBox(height: 4),
          ...booking.passengers.map((p) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(p.name, style: const TextStyle(fontSize: 11, color: AppTheme.textWhite)),
                Text(
                  isConfirmed ? "${p.coach ?? 'C4'}-${p.seatNumber ?? '28'} (${p.berthPreference})" : "CANCELLED",
                  style: TextStyle(
                    fontSize: 10, 
                    fontWeight: FontWeight.bold, 
                    color: isConfirmed ? AppTheme.goldAccent : AppTheme.errorRed,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Assistant"),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.primaryDarkNavy, AppTheme.backgroundDark],
          ),
        ),
        child: Column(
          children: [
            // Messages Panel
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length) {
                    return _buildTypingIndicator();
                  }
                  return _buildMessageBubble(_messages[index]);
                },
              ),
            ),

            // Suggestion Chips
            if (_messages.length == 1) _buildSuggestions(),

            // Chat Input Bar
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestions() {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _suggestions.length,
        itemBuilder: (context, index) {
          final text = _suggestions[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ActionChip(
              backgroundColor: AppTheme.cardNavy,
              side: BorderSide(color: AppTheme.goldAccent.withOpacity(0.3)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              label: Text(
                text,
                style: const TextStyle(color: AppTheme.goldAccent, fontSize: 11, fontWeight: FontWeight.w600),
              ),
              onPressed: () => _handleSendMessage(text),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final alignment = msg.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor = msg.isUser ? AppTheme.goldAccent : AppTheme.cardNavy;
    final textColor = msg.isUser ? AppTheme.primaryNavy : AppTheme.textWhite;
    final borderRadius = msg.isUser
        ? const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          );

    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        child: Column(
          crossAxisAlignment: alignment,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: borderRadius,
                border: msg.isUser ? null : Border.all(color: AppTheme.primaryLightNavy),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Text(
                msg.text,
                style: TextStyle(color: textColor, fontSize: 13, height: 1.4),
              ),
            ),
            if (msg.customWidget != null) msg.customWidget!,
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.cardNavy,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          border: Border.all(color: AppTheme.primaryLightNavy),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              "AI Assistant is typing",
              style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontStyle: FontStyle.italic),
            ),
            SizedBox(width: 8),
            SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: AppTheme.goldAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardNavy,
        border: const Border(top: BorderSide(color: AppTheme.primaryLightNavy, width: 1)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.primaryDarkNavy,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.primaryLightNavy),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(color: AppTheme.textWhite, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: "Type message or ask to 'track 22436'...",
                    hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                  onSubmitted: _handleSendMessage,
                ),
              ),
            ),
            const SizedBox(width: 8),
            FloatingActionButton(
              mini: true,
              backgroundColor: AppTheme.goldAccent,
              foregroundColor: AppTheme.primaryNavy,
              onPressed: () => _handleSendMessage(_messageController.text),
              child: const Icon(Icons.send_rounded, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
