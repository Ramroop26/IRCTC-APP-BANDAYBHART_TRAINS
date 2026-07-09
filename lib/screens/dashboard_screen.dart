import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  // Booking Form State variables matching the mockup design
  String _fromStation = "New Delhi (NDLS)";
  String _toStation = "Varanasi (BSB)";
  DateTime _journeyDate = DateTime.now().add(const Duration(days: 1));
  String _travelClass = "AC Chair Car";
  
  int _bottomNavIndex = 0; // "Book" selected active state

  final List<String> _stationsList = [
    "New Delhi (NDLS)",
    "Varanasi (BSB)",
    "Mumbai Central (MMCT)",
    "Gandhinagar Cap (GNC)",
    "Secunderabad Jn (SC)",
    "Visakhapatnam (VSKP)",
    "Hazrat Nizamuddin (NZM)",
    "Jammu Tawi (JAT)",
    "Katra (SVDK)"
  ];

  final List<String> _classesList = [
    "AC Chair Car",
    "Executive Chair",
    "Sleeper (SL)",
    "AC 3 Tier (3A)",
    "AC 2 Tier (2A)",
    "First AC (1A)"
  ];

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

  void _swapStations() {
    setState(() {
      final tmp = _fromStation;
      _fromStation = _toStation;
      _toStation = tmp;
    });
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _journeyDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 120)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.goldAccent,
            onPrimary: AppTheme.primaryNavy,
            surface: AppTheme.cardNavy,
            onSurface: AppTheme.textWhite,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _journeyDate = picked);
  }

  void _showSelectorDialog({
    required String title,
    required List<String> items,
    required String currentValue,
    required ValueChanged<String> onSelected,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardNavy,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppTheme.primaryLightNavy)),
        title: Text(title, style: const TextStyle(color: AppTheme.goldAccent, fontWeight: FontWeight.bold, fontSize: 16)),
        content: SizedBox(
          width: 300,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: items.length,
            itemBuilder: (context, idx) {
              final val = items[idx];
              final isSelected = val == currentValue;
              return ListTile(
                title: Text(val, style: TextStyle(color: isSelected ? AppTheme.goldAccent : AppTheme.textWhite, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                trailing: isSelected ? const Icon(Icons.check_circle_outline, color: AppTheme.goldAccent) : null,
                onTap: () {
                  onSelected(val);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isWide = MediaQuery.of(context).size.width > 900;
    final activeBookings = _bookingService.getActiveBookings();

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
        child: Stack(
          children: [
            // Gold Vector Lines Background Effect
            Positioned.fill(
              child: CustomPaint(
                painter: GoldLinePainter(),
              ),
            ),
            
            // Main content
            Column(
              children: [
                // Custom Navbar matching Mockup
                _buildTopNavBar(isWide),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: isWide 
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left Column (Form & Recent Bookings)
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildBookJourneySection(),
                                  const SizedBox(height: 24),
                                  _buildRecentBookingsSection(activeBookings),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            // Right Column (Live Train Status)
                            Expanded(
                              flex: 2,
                              child: _buildLiveStatusSection(),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildBookJourneySection(),
                            const SizedBox(height: 24),
                            _buildRecentBookingsSection(activeBookings),
                            const SizedBox(height: 24),
                            _buildLiveStatusSection(),
                          ],
                        ),
                  ),
                ),

                // Bottom Nav Bar
                _buildCustomBottomNav(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Custom App Top Header/Bar ─────────────────────────────────────────────
  Widget _buildTopNavBar(bool isWide) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      decoration: BoxDecoration(
        color: AppTheme.primaryDarkNavy.withOpacity(0.4),
        border: const Border(bottom: BorderSide(color: AppTheme.primaryLightNavy, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left Logo Column
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.goldAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.directions_railway_filled, color: AppTheme.goldAccent, size: 28),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Vande Bharat",
                    style: TextStyle(
                      color: AppTheme.goldAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    "Express",
                    style: TextStyle(
                      color: AppTheme.textWhite,
                      fontSize: 12,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Right Menu Links
          Row(
            children: [
              _buildNavButton("Home", true, () {}),
              const SizedBox(width: 8),
              _buildNavButton("Profile", false, () {
                Navigator.pushNamed(context, '/profile');
              }),
              const SizedBox(width: 8),
              _buildNavButton("Help", false, () {
                Navigator.pushNamed(context, '/chatbot');
              }),
              if (isWide) ...[
                const SizedBox(width: 16),
                const VerticalDivider(color: AppTheme.primaryLightNavy, width: 20, thickness: 1),
                Text(
                  "Hi, ${_authService.userName.split(' ').first}",
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.logout_rounded, color: AppTheme.errorRed, size: 20),
                  onPressed: () {
                    _authService.logout();
                    Navigator.pushReplacementNamed(context, '/');
                  },
                )
              ]
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton(String label, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppTheme.textWhite : AppTheme.textMuted,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),
            if (isActive)
              Container(
                margin: const EdgeInsets.only(top: 4),
                height: 2,
                width: 20,
                color: AppTheme.goldAccent,
              ),
          ],
        ),
      ),
    );
  }

  // ── Book Your Journey Section (Card fields matching image) ──────────────────
  Widget _buildBookJourneySection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardNavy.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryLightNavy, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Book Your Journey",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textWhite,
            ),
          ),
          const SizedBox(height: 20),

          // Station Row (From -> Swap -> To)
          LayoutBuilder(builder: (context, constraints) {
            bool isRow = constraints.maxWidth > 500;
            Widget fromInput = _buildMockupFormField(
              label: "From",
              value: _fromStation,
              icon: Icons.radio_button_checked_rounded,
              iconColor: AppTheme.goldAccent,
              onTap: () => _showSelectorDialog(
                title: "From Station",
                items: _stationsList,
                currentValue: _fromStation,
                onSelected: (val) => setState(() => _fromStation = val),
              ),
            );

            Widget toInput = _buildMockupFormField(
              label: "To",
              value: _toStation,
              icon: Icons.location_on_outlined,
              iconColor: AppTheme.goldAccent,
              onTap: () => _showSelectorDialog(
                title: "To Station",
                items: _stationsList,
                currentValue: _toStation,
                onSelected: (val) => setState(() => _toStation = val),
              ),
            );

            Widget swapBtn = Container(
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: FloatingActionButton.small(
                heroTag: "swapStationBtn",
                onPressed: _swapStations,
                backgroundColor: AppTheme.primaryLightNavy,
                foregroundColor: AppTheme.goldAccent,
                shape: const CircleBorder(),
                elevation: 3,
                child: const Icon(Icons.swap_horiz_rounded, size: 22),
              ),
            );

            if (isRow) {
              return Row(
                children: [
                  Expanded(child: fromInput),
                  swapBtn,
                  Expanded(child: toInput),
                ],
              );
            } else {
              return Column(
                children: [
                  fromInput,
                  swapBtn,
                  toInput,
                ],
              );
            }
          }),
          const SizedBox(height: 16),

          // Date & Class Selector fields
          LayoutBuilder(builder: (context, constraints) {
            bool isRow = constraints.maxWidth > 500;
            Widget dateInput = _buildMockupFormField(
              label: "Date",
              value: DateFormat('EEEE, dd MMM yyyy').format(_journeyDate),
              icon: Icons.calendar_today_rounded,
              iconColor: AppTheme.goldAccent,
              onTap: _selectDate,
            );

            Widget classInput = _buildMockupFormField(
              label: "Class",
              value: _travelClass,
              icon: Icons.airline_seat_recline_extra_rounded,
              iconColor: AppTheme.goldAccent,
              hasDropdownArrow: true,
              onTap: () => _showSelectorDialog(
                title: "Travel Class",
                items: _classesList,
                currentValue: _travelClass,
                onSelected: (val) => setState(() => _travelClass = val),
              ),
            );

            if (isRow) {
              return Row(
                children: [
                  Expanded(child: dateInput),
                  const SizedBox(width: 16),
                  Expanded(child: classInput),
                ],
              );
            } else {
              return Column(
                children: [
                  dateInput,
                  const SizedBox(height: 16),
                  classInput,
                ],
              );
            }
          }),
          const SizedBox(height: 24),

          // Search Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                // Navigate to search screen passing search params
                Navigator.pushNamed(
                  context,
                  '/train_search',
                  arguments: {
                    'from': _fromStation,
                    'to': _toStation,
                    'date': _journeyDate,
                    'class': _travelClass,
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.goldAccent,
                foregroundColor: AppTheme.primaryNavy,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 5,
              ),
              child: const Text(
                "Search Vande Bharat Trains",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMockupFormField({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    bool hasDropdownArrow = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.primaryNavy.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primaryLightNavy, width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      color: AppTheme.textWhite,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (hasDropdownArrow)
              const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }

  // ── Recent Bookings Section (Glassmorphic cards) ──────────────────────────
  Widget _buildRecentBookingsSection(List<Booking> actualBookings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Your Recent Bookings",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textWhite,
          ),
        ),
        const SizedBox(height: 12),

        if (actualBookings.isNotEmpty)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: actualBookings.length > 2 ? 2 : actualBookings.length,
            itemBuilder: (context, idx) {
              final b = actualBookings[idx];
              return _buildBookingCard(
                src: b.train.source,
                dest: b.train.destination,
                trainNum: b.train.number,
                date: b.journeyDate,
                pnr: b.pnr,
                status: b.status,
              );
            },
          )
        else ...[
          // Default beautiful static recent bookings matching the mockup image layout
          _buildBookingCard(
            src: "New Delhi (NDLS)",
            dest: "Varanasi (BSB)",
            trainNum: "22436",
            date: "Oct 21",
            pnr: "4567890123",
            status: "Confirmed",
            isCompleted: true,
          ),
          _buildBookingCard(
            src: "Mumbai Central",
            dest: "Gandhinagar Cap.",
            trainNum: "20901",
            date: "Oct 19",
            pnr: "9876543210",
            status: "Completed",
            isCompleted: true,
          ),
        ]
      ],
    );
  }

  Widget _buildBookingCard({
    required String src,
    required String dest,
    required String trainNum,
    required String date,
    required String pnr,
    required String status,
    bool isCompleted = false,
  }) {
    final cleanSrc = src.split(' ').first;
    final cleanDest = dest.split(' ').first;
    bool isCnf = status.toLowerCase() == "confirmed" || status.toLowerCase() == "success";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardNavy.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryLightNavy.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "$cleanSrc → $cleanDest",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textWhite),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isCnf 
                        ? AppTheme.successGreen.withOpacity(0.12)
                        : AppTheme.goldAccent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isCnf ? "Confirmed" : "Completed",
                      style: TextStyle(
                        color: isCnf ? AppTheme.successGreen : AppTheme.goldAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Train $trainNum", style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text("PNR: $pnr", style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("Date: $date", style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                  const SizedBox(height: 2),
                  const Text("Status: Completed", style: TextStyle(color: AppTheme.successGreen, fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Live Train Status Column (matching mockup right panel) ──────────────────
  Widget _buildLiveStatusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Live Train Status",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textWhite,
          ),
        ),
        const SizedBox(height: 12),

        // Live status Card 1
        _buildLiveStatusCard(
          trainNum: "22416",
          route: "New Delhi → Katra",
          statusText: "Delayed 12 min",
          isDelayed: true,
          currentStation: "Jammu Tawi (JAT)",
          nextStop: "Udhampur",
          progress: 0.8,
        ),

        // Live status Card 2
        _buildLiveStatusCard(
          trainNum: "20833",
          route: "Secunderabad → Visakhapatnam",
          statusText: "On Time",
          isDelayed: false,
          currentStation: "Rajahmundry",
          nextStop: "Samalkot",
          progress: 0.65,
        ),
      ],
    );
  }

  Widget _buildLiveStatusCard({
    required String trainNum,
    required String route,
    required String statusText,
    required bool isDelayed,
    required String currentStation,
    required String nextStop,
    required double progress,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardNavy.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryLightNavy.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Train $trainNum",
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted, size: 20),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            route,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textWhite),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                "Status: ",
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
              ),
              Text(
                statusText,
                style: TextStyle(
                  color: isDelayed ? AppTheme.errorRed : AppTheme.successGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "Currently at: $currentStation",
            style: const TextStyle(color: AppTheme.textWhite, fontSize: 12),
          ),
          
          // Progress Line UI
          const SizedBox(height: 12),
          Stack(
            children: [
              Container(
                height: 4,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.primaryLightNavy,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.goldAccent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Positioned(
                left: (MediaQuery.of(context).size.width * 0.3) * progress,
                top: -3,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppTheme.goldAccent,
                    shape: BoxShape.circle,
                  ),
                ),
              )
            ],
          ),
          
          const SizedBox(height: 10),
          Text(
            "Next Stop: $nextStop",
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ── Custom Bottom Nav bar matching design ─────────────────────────────────
  Widget _buildCustomBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryDarkNavy.withOpacity(0.9),
        border: const Border(top: BorderSide(color: AppTheme.primaryLightNavy, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBottomNavItem(0, Icons.calendar_month_outlined, "Book"),
          _buildBottomNavItem(1, Icons.access_time_rounded, "Status"),
          _buildBottomNavItem(2, Icons.card_travel_outlined, "My Trips"),
          _buildBottomNavItem(3, Icons.person_outline_rounded, "Account"),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem(int index, IconData icon, String label) {
    bool isActive = _bottomNavIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _bottomNavIndex = index;
        });
        if (index == 1) {
          Navigator.pushNamed(context, '/live_status');
        } else if (index == 2) {
          Navigator.pushNamed(context, '/order_history');
        } else if (index == 3) {
          Navigator.pushNamed(context, '/profile');
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? AppTheme.goldAccent : AppTheme.textMuted,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppTheme.goldAccent : AppTheme.textMuted,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Background Decorative gold curve effect painter ────────────────────────
class GoldLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = AppTheme.goldAccent.withOpacity(0.04)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path1 = Path();
    path1.moveTo(0, size.height * 0.15);
    path1.quadraticBezierTo(
      size.width * 0.4,
      size.height * 0.4,
      size.width,
      size.height * 0.25,
    );
    canvas.drawPath(path1, paint1);

    final paint2 = Paint()
      ..color = AppTheme.goldAccent.withOpacity(0.02)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path2 = Path();
    path2.moveTo(0, size.height * 0.8);
    path2.quadraticBezierTo(
      size.width * 0.7,
      size.height * 0.65,
      size.width,
      size.height * 0.9,
    );
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
