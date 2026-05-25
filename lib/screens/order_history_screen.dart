import 'package:flutter/material.dart';
import '../services/booking_service.dart';
import '../models/booking.dart';
import '../theme.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> with SingleTickerProviderStateMixin {
  final BookingService _bookingService = BookingService();
  int _selectedFilter = 0; // 0: All, 1: Active, 2: Cancelled

  @override
  void initState() {
    super.initState();
    _bookingService.addListener(_updateState);
  }

  @override
  void dispose() {
    _bookingService.removeListener(_updateState);
    super.dispose();
  }

  void _updateState() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Booking> filteredBookings = [];
    if (_selectedFilter == 0) {
      filteredBookings = _bookingService.bookings;
    } else if (_selectedFilter == 1) {
      filteredBookings = _bookingService.bookings.where((b) => b.status == "CONFIRMED").toList();
    } else if (_selectedFilter == 2) {
      filteredBookings = _bookingService.bookings.where((b) => b.status == "CANCELLED").toList();
    }

    return Scaffold(
      appBar: AppBar(title: const Text("MY BOOKINGS")),
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
            // Filter Tabs
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: AppTheme.cardNavy.withOpacity(0.5),
              child: Row(
                children: [
                  _buildFilterTab(0, "ALL"),
                  const SizedBox(width: 8),
                  _buildFilterTab(1, "ACTIVE"),
                  const SizedBox(width: 8),
                  _buildFilterTab(2, "CANCELLED"),
                ],
              ),
            ),

            // Booking lists
            Expanded(
              child: filteredBookings.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredBookings.length,
                      itemBuilder: (context, index) {
                        return _buildBookingCard(filteredBookings[index]);
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
              fontSize: 12,
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
        Icon(Icons.airplane_ticket_outlined, size: 64, color: AppTheme.textMuted.withOpacity(0.4)),
        const SizedBox(height: 16),
        const Text("No Bookings Found", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 4),
        Text("Your booking records for this category are empty.", style: TextStyle(color: AppTheme.textMuted.withOpacity(0.8), fontSize: 12)),
      ],
    );
  }

  Widget _buildBookingCard(Booking booking) {
    final bool isConfirmed = booking.status == "CONFIRMED";
    return Card(
      color: AppTheme.cardNavy,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isConfirmed ? AppTheme.primaryLightNavy : AppTheme.errorRed.withOpacity(0.4),
          width: 1,
        ),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/ticket_detail',
            arguments: booking.pnr,
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
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
                        booking.train.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textWhite, fontSize: 14),
                      ),
                      Text(
                        "Train No: #${booking.train.number} | PNR: ${booking.pnr}",
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isConfirmed ? AppTheme.successGreen.withOpacity(0.15) : AppTheme.errorRed.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      booking.status,
                      style: TextStyle(
                        color: isConfirmed ? AppTheme.successGreen : AppTheme.errorRed,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(color: AppTheme.primaryLightNavy, height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(booking.train.source.split(' ').first, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textWhite, fontSize: 13)),
                      Text(booking.train.departureTime, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.arrow_right_alt, color: AppTheme.goldAccent, size: 18),
                      const SizedBox(width: 4),
                      Text(booking.journeyDate, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(booking.train.destination.split(' ').first, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textWhite, fontSize: 13)),
                      Text(booking.train.arrivalTime, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${booking.passengers.length} Passenger(s)",
                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),
                  Text(
                    "Total Paid: ₹${booking.totalAmount.toInt()}",
                    style: const TextStyle(color: AppTheme.goldAccent, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
