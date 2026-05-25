import 'package:flutter/material.dart';
import '../theme.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  int _selectedFilter = 0; // 0: All, 1: SMS, 2: Bookings, 3: Trains

  final List<NotificationItem> _notifications = [
    NotificationItem(
      title: "Ticket Confirmed",
      body: "PNR 4238910476: Your booking for Train 22436 (NDLS-BSB Vande Bharat) has been confirmed. Seat: C4/28.",
      category: NotificationCategory.bookings,
      time: "Just now",
    ),
    NotificationItem(
      title: "eWallet Load Successful",
      body: "₹2,000.00 credited to your eWallet via UPI transaction ID TXN982471048293.",
      category: NotificationCategory.sms,
      time: "2 hours ago",
    ),
    NotificationItem(
      title: "Train Running Status Update",
      body: "Train 22436 (Vande Bharat Exp) departed Kanpur Central delayed by 5 minutes. Expected platform: 5.",
      category: NotificationCategory.trains,
      time: "4 hours ago",
    ),
    NotificationItem(
      title: "Aadhaar KYC Successful",
      body: "Verification completed. Your account is linked and monthly ticket limit is extended to 12.",
      category: NotificationCategory.sms,
      time: "1 day ago",
    ),
    NotificationItem(
      title: "eWallet Refund Issued",
      body: "₹1,630.00 refund credited for PNR 4238910476 (cancellation fee ₹120 deducted).",
      category: NotificationCategory.bookings,
      time: "2 days ago",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    List<NotificationItem> filteredList = [];
    if (_selectedFilter == 0) {
      filteredList = _notifications;
    } else {
      final category = _selectedFilter == 1
          ? NotificationCategory.sms
          : _selectedFilter == 2
              ? NotificationCategory.bookings
              : NotificationCategory.trains;
      filteredList = _notifications.where((n) => n.category == category).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("NOTIFICATIONS"),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all_rounded),
            tooltip: "Clear All",
            onPressed: () {
              setState(() {
                _notifications.clear();
              });
            },
          ),
        ],
      ),
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.primaryDarkNavy, AppTheme.backgroundDark],
          ),
        ),
        child: Column(
          children: [
            // Filter categories row
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: AppTheme.cardNavy.withOpacity(0.5),
              child: Row(
                children: [
                  _buildFilterTab(0, "ALL"),
                  const SizedBox(width: 6),
                  _buildFilterTab(1, "SMS"),
                  const SizedBox(width: 6),
                  _buildFilterTab(2, "BOOKINGS"),
                  const SizedBox(width: 6),
                  _buildFilterTab(3, "TRAINS"),
                ],
              ),
            ),

            // Notification list
            Expanded(
              child: filteredList.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        return _buildNotificationCard(filteredList[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab(int index, String label) {
    final isSelected = _selectedFilter == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilter = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.goldAccent : AppTheme.primaryLightNavy.withOpacity(0.4),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? AppTheme.goldAccent : AppTheme.primaryLightNavy),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isSelected ? AppTheme.primaryNavy : AppTheme.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.notifications_off_outlined, size: 64, color: AppTheme.textMuted.withOpacity(0.4)),
        const SizedBox(height: 16),
        const Text("Inbox is Clean", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 4),
        Text("No notifications found for this category.", style: TextStyle(color: AppTheme.textMuted.withOpacity(0.8), fontSize: 12)),
      ],
    );
  }

  Widget _buildNotificationCard(NotificationItem item) {
    IconData icon;
    Color iconColor;

    switch (item.category) {
      case NotificationCategory.sms:
        icon = Icons.message_rounded;
        iconColor = Colors.blueAccent;
        break;
      case NotificationCategory.bookings:
        icon = Icons.airplane_ticket_rounded;
        iconColor = AppTheme.successGreen;
        break;
      case NotificationCategory.trains:
        icon = Icons.train_rounded;
        iconColor = AppTheme.goldAccent;
        break;
    }

    return Card(
      color: AppTheme.cardNavy,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.primaryLightNavy),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textWhite, fontSize: 13),
                      ),
                      Text(
                        item.time,
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 9),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.body,
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum NotificationCategory { sms, bookings, trains }

class NotificationItem {
  final String title;
  final String body;
  final NotificationCategory category;
  final String time;

  NotificationItem({
    required this.title,
    required this.body,
    required this.category,
    required this.time,
  });
}
