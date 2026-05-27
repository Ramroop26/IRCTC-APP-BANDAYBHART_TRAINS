import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/wallet_service.dart';
import '../services/booking_service.dart';
import '../models/booking.dart';
import '../theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AuthService _authService = AuthService();
  final WalletService _walletService = WalletService();
  final BookingService _bookingService = BookingService();

  @override
  void initState() {
    super.initState();
    _walletService.addListener(_updateState);
    _bookingService.addListener(_updateState);
    _authService.addListener(_updateState);
  }

  @override
  void dispose() {
    _walletService.removeListener(_updateState);
    _bookingService.removeListener(_updateState);
    _authService.removeListener(_updateState);
    super.dispose();
  }

  void _updateState() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeBookings = _bookingService.getActiveBookings();

    return Scaffold(
      appBar: AppBar(
        title: const Text("IRCTC APP"),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppTheme.goldAccent),
            tooltip: "Notifications",
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.architecture_rounded, color: AppTheme.goldAccent),
            tooltip: "System Design Architecture",
            onPressed: () => Navigator.pushNamed(context, '/architecture'),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppTheme.errorRed),
            tooltip: "Logout",
            onPressed: () {
              _authService.logout();
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryDarkNavy,
              AppTheme.backgroundDark,
            ],
          ),
        ),
        child: TweenAnimationBuilder(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 30 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Welcome, ${_authService.userName}",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textWhite,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Where would you like to travel today?",
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/profile'),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.goldAccent, width: 1.5),
                      ),
                      child: const CircleAvatar(
                        backgroundColor: AppTheme.primaryLightNavy,
                        child: Icon(Icons.person, color: AppTheme.goldAccent),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // eWallet Quick View Card
              _buildWalletCard(),
              const SizedBox(height: 24),

              // Upcoming Journey Banner
              if (activeBookings.isNotEmpty) ...[
                const Text(
                  "UPCOMING JOURNEY",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: AppTheme.goldAccent,
                  ),
                ),
                const SizedBox(height: 10),
                _buildUpcomingTicketCard(activeBookings.first),
                const SizedBox(height: 24),
              ],

              // Dashboard Features Grid Title
              const Text(
                "KEY FEATURES",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: AppTheme.goldAccent,
                ),
              ),
              const SizedBox(height: 12),

              // Grid items
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.95,
                children: [
                  _buildGridItem(
                    "Search Trains",
                    Icons.search_rounded,
                    AppTheme.goldAccent,
                    () => Navigator.pushNamed(context, '/train_search'),
                  ),
                  _buildGridItem(
                    "PNR Status",
                    Icons.receipt_long_rounded,
                    Colors.cyanAccent,
                    () => Navigator.pushNamed(context, '/pnr_status'),
                  ),
                  _buildGridItem(
                    "Live Status",
                    Icons.location_on_outlined,
                    Colors.orangeAccent,
                    () => Navigator.pushNamed(context, '/live_status'),
                  ),
                  _buildGridItem(
                    "eWallet",
                    Icons.account_balance_wallet_outlined,
                    Colors.pinkAccent,
                    () => Navigator.pushNamed(context, '/wallet'),
                  ),
                  _buildGridItem(
                    "My Bookings",
                    Icons.confirmation_num_outlined,
                    Colors.greenAccent,
                    () => Navigator.pushNamed(context, '/order_history'),
                  ),
                  _buildGridItem(
                    "Cancel Ticket",
                    Icons.cancel_presentation_rounded,
                    AppTheme.errorRed,
                    () => Navigator.pushNamed(context, '/order_history'),
                  ),
                  _buildGridItem(
                    "Aadhaar KYC",
                    Icons.verified_user_outlined,
                    Colors.blueAccent,
                    () => Navigator.pushNamed(context, '/profile'),
                  ),
                  _buildGridItem(
                    "Architecture",
                    Icons.architecture_rounded,
                    AppTheme.goldAccent,
                    () => Navigator.pushNamed(context, '/architecture'),
                  ),
                  _buildGridItem(
                    "AI Assistant",
                    Icons.chat_bubble_outline_rounded,
                    Colors.tealAccent,
                    () => Navigator.pushNamed(context, '/chatbot'),
                  ),
                ],
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildWalletCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryLightNavy, AppTheme.cardNavy],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.goldAccent.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.account_balance_wallet, color: AppTheme.goldAccent, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    "IRCTC eWallet Balance",
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "₹${_walletService.balance.toStringAsFixed(2)}",
                style: const TextStyle(
                  color: AppTheme.goldAccent,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/wallet');
            },
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text("TOP UP"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              backgroundColor: AppTheme.goldAccent,
              foregroundColor: AppTheme.primaryNavy,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingTicketCard(Booking booking) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/ticket_detail',
          arguments: booking.pnr,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardNavy,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.greenAccent.withOpacity(0.3), width: 1),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  booking.train.number,
                  style: const TextStyle(color: AppTheme.goldAccent, fontWeight: FontWeight.bold, fontSize: 12),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.successGreen.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    booking.status,
                    style: const TextStyle(color: AppTheme.successGreen, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("DEP", style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                      Text(
                        booking.train.source.split(' ').first,
                        style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(booking.train.departureTime, style: const TextStyle(color: AppTheme.textWhite, fontSize: 12)),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Text(
                      booking.train.duration,
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                    ),
                    const Icon(Icons.arrow_right_alt, color: AppTheme.goldAccent),
                  ],
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text("ARR", style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                      Text(
                        booking.train.destination.split(' ').first,
                        style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(booking.train.arrivalTime, style: const TextStyle(color: AppTheme.textWhite, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(color: AppTheme.primaryLightNavy, height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "PNR: ${booking.pnr}",
                  style: const TextStyle(color: AppTheme.textWhite, fontSize: 12, fontWeight: FontWeight.w500),
                ),
                Text(
                  "Seats: ${booking.passengers.first.coach}-${booking.passengers.first.seatNumber}",
                  style: const TextStyle(color: AppTheme.goldAccent, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridItem(String label, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      color: AppTheme.cardNavy.withOpacity(0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.primaryLightNavy.withOpacity(0.5), width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textWhite,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
