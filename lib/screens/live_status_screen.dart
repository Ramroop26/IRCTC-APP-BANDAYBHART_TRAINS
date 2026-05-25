import 'dart:async';
import 'package:flutter/material.dart';
import '../services/train_service.dart';
import '../theme.dart';
import '../widgets/live_track_map.dart';

class LiveStatusScreen extends StatefulWidget {
  const LiveStatusScreen({super.key});

  @override
  State<LiveStatusScreen> createState() => _LiveStatusScreenState();
}

class _LiveStatusScreenState extends State<LiveStatusScreen>
    with TickerProviderStateMixin {
  final TrainService _trainService = TrainService();
  final _trainNumberController = TextEditingController(text: "22436");
  LiveTrainRoute? _liveRoute;
  bool _hasSearched = false;
  bool _isLoading = false;
  String _activeTab = "timeline";
  bool _initializedWithArg = false;

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _trainMoveController;
  late Animation<double> _pulseAnimation;

  // Simulated live position between stations (0.0 to 1.0)
  double _liveProgress = 0.62;
  int _currentSpeedKmh = 118;
  String _etaNextStation = "18 min";
  Timer? _liveUpdateTimer;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _trainMoveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Simulate live position updates
    _liveUpdateTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted && _liveRoute != null) {
        setState(() {
          _liveProgress = (_liveProgress + 0.01).clamp(0.0, 0.99);
          _currentSpeedKmh = 100 + (DateTime.now().second % 40);
          final mins = ((1 - _liveProgress) * 30).round();
          _etaNextStation = "$mins min";
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedWithArg) {
      final args = ModalRoute.of(context)?.settings.arguments;
      String? argTrainNumber;
      if (args is String) {
        argTrainNumber = args;
      } else if (args is Map) {
        argTrainNumber = args['trainNumber']?.toString();
      }
      if (argTrainNumber != null && argTrainNumber.isNotEmpty) {
        _trainNumberController.text = argTrainNumber;
        _searchLiveStatus();
      }
      _initializedWithArg = true;
    }
  }

  void _searchLiveStatus() {
    final number = _trainNumberController.text.trim();
    if (number.isEmpty) return;

    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _liveProgress = 0.62;
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      setState(() {
        _liveRoute = _trainService.getLiveRoute(number);
        _isLoading = false;
      });
    });
  }

  @override
  void dispose() {
    _trainNumberController.dispose();
    _pulseController.dispose();
    _trainMoveController.dispose();
    _liveUpdateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("LIVE TRAIN STATUS")),
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.primaryDarkNavy, AppTheme.backgroundDark],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search Header Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardNavy,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryLightNavy),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _trainNumberController,
                      style: const TextStyle(color: AppTheme.textWhite),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Train Number",
                        hintText: "Enter 5-digit Train Number (e.g. 22436, 12302)",
                        prefixIcon: Icon(Icons.train, color: AppTheme.goldAccent),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _searchLiveStatus,
                      child: const Text("TRACK TRAIN"),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40.0),
                    child: CircularProgressIndicator(color: AppTheme.goldAccent),
                  ),
                )
              else if (_hasSearched && _liveRoute != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Live Status Banner ──────────────────────────────────
                    _buildLiveStatusBanner(_liveRoute!),
                    const SizedBox(height: 16),

                    // ── Live Stats Row ──────────────────────────────────────
                    _buildLiveStatsRow(),
                    const SizedBox(height: 20),

                    // ── Tab Switcher ────────────────────────────────────────
                    _buildTabSwitcher(),
                    const SizedBox(height: 20),

                    if (_activeTab == "timeline") ...[
                      _buildCurrentLocationCard(_liveRoute!),
                      const SizedBox(height: 20),
                      const Text(
                        "STATION TIMELINE",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: AppTheme.goldAccent,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildTimeline(_liveRoute!),
                    ] else ...[
                      LiveTrackMap(route: _liveRoute!),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Live Status Banner ────────────────────────────────────────────────────
  Widget _buildLiveStatusBanner(LiveTrainRoute route) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryLightNavy.withOpacity(0.5),
            AppTheme.cardNavy,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.goldAccent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      route.trainName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppTheme.textWhite,
                      ),
                    ),
                    Text(
                      "Train #${route.trainNumber}",
                      style: const TextStyle(
                          color: AppTheme.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              // Live indicator
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (_, __) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.successGreen
                        .withOpacity(0.15 * _pulseAnimation.value + 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.successGreen
                          .withOpacity(0.5 * _pulseAnimation.value + 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.successGreen
                              .withOpacity(_pulseAnimation.value),
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        "LIVE",
                        style: TextStyle(
                          color: AppTheme.successGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.sensors_rounded,
                  color: AppTheme.successGreen, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  route.currentStatusDescription,
                  style: const TextStyle(
                    color: AppTheme.successGreen,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Live Stats Row ────────────────────────────────────────────────────────
  Widget _buildLiveStatsRow() {
    return Row(
      children: [
        _buildStatCard(
          icon: Icons.speed_rounded,
          label: "Speed",
          value: "$_currentSpeedKmh km/h",
          color: AppTheme.goldAccent,
        ),
        const SizedBox(width: 10),
        _buildStatCard(
          icon: Icons.schedule_rounded,
          label: "ETA Next",
          value: _etaNextStation,
          color: const Color(0xFF7EC8E3),
        ),
        const SizedBox(width: 10),
        _buildStatCard(
          icon: Icons.route_rounded,
          label: "Progress",
          value: "${(_liveProgress * 100).round()}%",
          color: AppTheme.successGreen,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab Switcher ──────────────────────────────────────────────────────────
  Widget _buildTabSwitcher() {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.primaryLightNavy.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryLightNavy),
      ),
      child: Row(
        children: [
          _buildTabButton("timeline", Icons.timeline_rounded, "TIMELINE VIEW"),
          _buildTabButton("map", Icons.radar_rounded, "RADAR MAP TRACK"),
        ],
      ),
    );
  }

  Widget _buildTabButton(String tab, IconData icon, String label) {
    final bool isActive = _activeTab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = tab),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.goldAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 14,
                  color: isActive
                      ? AppTheme.primaryNavy
                      : AppTheme.textMuted),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? AppTheme.primaryNavy : AppTheme.textMuted,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Current Location Card ─────────────────────────────────────────────────
  Widget _buildCurrentLocationCard(LiveTrainRoute route) {
    final int curIdx = route.currentStationIndex;
    final bool hasNext = curIdx + 1 < route.stations.length;
    final currentSt = route.stations[curIdx];
    final nextSt = hasNext ? route.stations[curIdx + 1] : null;

    // Distance between current and next station
    final int distBetween = nextSt != null
        ? (nextSt.distanceKm - currentSt.distanceKm)
        : 0;
    final int distCovered = (_liveProgress * distBetween).round();
    final int distRemaining = distBetween - distCovered;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.goldAccent.withOpacity(0.4)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.goldAccent.withOpacity(0.08),
            AppTheme.cardNavy,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                const Icon(Icons.my_location_rounded,
                    color: AppTheme.goldAccent, size: 16),
                const SizedBox(width: 8),
                const Text(
                  "CURRENT LOCATION",
                  style: TextStyle(
                    color: AppTheme.goldAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const Spacer(),
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (_, __) => Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.successGreen
                          .withOpacity(_pulseAnimation.value),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.successGreen.withOpacity(0.5),
                          blurRadius: 6 * _pulseAnimation.value,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Station to Station progress track
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Left station
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentSt.name.split(' (').first,
                        style: const TextStyle(
                          color: AppTheme.textWhite,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Dep: ${currentSt.actualDeparture}",
                        style: const TextStyle(
                          color: AppTheme.successGreen,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                // Progress track with train icon
                Expanded(
                  flex: 4,
                  child: Column(
                    children: [
                      // Animated train track
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Track line
                          Container(
                            height: 4,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.goldAccent,
                                  AppTheme.goldAccent.withOpacity(0.3),
                                ],
                                stops: [_liveProgress, _liveProgress],
                              ),
                            ),
                          ),
                          // Train position
                          Align(
                            alignment: Alignment(
                                (_liveProgress * 2 - 1).clamp(-0.9, 0.9), 0),
                            child: AnimatedBuilder(
                              animation: _pulseController,
                              builder: (_, child) => Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.goldAccent,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.goldAccent.withOpacity(
                                          0.6 * _pulseAnimation.value),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.train_rounded,
                                  size: 14,
                                  color: AppTheme.primaryNavy,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "$distCovered km • $distRemaining km left",
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 9,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                // Right station
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        nextSt?.name.split(' (').first ?? "Destination",
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.right,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "ETA: $_etaNextStation",
                        style: const TextStyle(
                          color: Color(0xFF7EC8E3),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Progress bar full journey
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      route.stations.first.name.split(' (').first,
                      style: const TextStyle(
                          color: AppTheme.textMuted, fontSize: 9),
                    ),
                    Text(
                      "Journey ${(route.progressPercent * 100).round()}% complete",
                      style: const TextStyle(
                          color: AppTheme.textMuted, fontSize: 9),
                    ),
                    Text(
                      route.stations.last.name.split(' (').first,
                      style: const TextStyle(
                          color: AppTheme.textMuted, fontSize: 9),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: route.progressPercent,
                    backgroundColor: AppTheme.primaryLightNavy,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppTheme.goldAccent),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }

  // ── Timeline ──────────────────────────────────────────────────────────────
  Widget _buildTimeline(LiveTrainRoute route) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: route.stations.length,
      itemBuilder: (context, index) {
        final station = route.stations[index];
        final bool isPassed = index <= route.currentStationIndex;
        final bool isCurrent = index == route.currentStationIndex;
        final bool isNext = index == route.currentStationIndex + 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left column: Delay & platform
            SizedBox(
              width: 70,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      station.delayMinutes == 0
                          ? "On Time"
                          : "+${station.delayMinutes} m",
                      style: TextStyle(
                        color: station.delayMinutes == 0
                            ? AppTheme.successGreen
                            : AppTheme.warningOrange,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "PF ${station.platform}",
                      style: const TextStyle(
                          color: AppTheme.textMuted, fontSize: 10),
                    ),
                    Text(
                      "${station.distanceKm} km",
                      style: const TextStyle(
                          color: AppTheme.textMuted, fontSize: 9),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Center: timeline dots & lines
            Column(
              children: [
                // Top line
                Container(
                  width: 2,
                  height: 15,
                  color: index == 0
                      ? Colors.transparent
                      : isPassed
                          ? AppTheme.goldAccent
                          : AppTheme.primaryLightNavy,
                ),

                // Live train between prev and current station
                if (isNext) ...[
                  // Animated moving train dot
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (_, __) => Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF7EC8E3)
                            .withOpacity(0.2 + 0.5 * _pulseAnimation.value),
                        border: Border.all(
                          color: const Color(0xFF7EC8E3)
                              .withOpacity(_pulseAnimation.value),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7EC8E3)
                                .withOpacity(0.4 * _pulseAnimation.value),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.train_rounded,
                        size: 7,
                        color: const Color(0xFF7EC8E3)
                            .withOpacity(_pulseAnimation.value),
                      ),
                    ),
                  ),
                ] else if (isCurrent) ...[
                  // Current station: glowing gold dot
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (_, __) => Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.goldAccent,
                        border: Border.all(
                            color: AppTheme.primaryNavy, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.goldAccent
                                .withOpacity(0.6 * _pulseAnimation.value),
                            blurRadius: 10,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.train_rounded,
                          size: 11, color: AppTheme.primaryNavy),
                    ),
                  ),
                ] else ...[
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isPassed
                          ? AppTheme.goldAccent
                          : AppTheme.primaryLightNavy,
                      border: Border.all(
                        color: isPassed
                            ? AppTheme.goldAccent
                            : AppTheme.primaryLightNavy,
                        width: 2,
                      ),
                    ),
                  ),
                ],

                // Bottom line — dashed when between current & next
                if (isNext)
                  _buildDashedLine(
                    height: 72,
                    color: const Color(0xFF7EC8E3).withOpacity(0.6),
                  )
                else
                  Container(
                    width: 2,
                    height: 72,
                    color: index == route.stations.length - 1
                        ? Colors.transparent
                        : isPassed && !isCurrent
                            ? AppTheme.goldAccent
                            : AppTheme.primaryLightNavy,
                  ),
              ],
            ),
            const SizedBox(width: 16),

            // Right column: Station Info
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isCurrent
                      ? AppTheme.goldAccent.withOpacity(0.08)
                      : isNext
                          ? const Color(0xFF7EC8E3).withOpacity(0.05)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isCurrent
                        ? AppTheme.goldAccent.withOpacity(0.3)
                        : isNext
                            ? const Color(0xFF7EC8E3).withOpacity(0.2)
                            : Colors.transparent,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            station.name,
                            style: TextStyle(
                              fontWeight: isCurrent || isNext
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 13,
                              color: isCurrent
                                  ? AppTheme.goldAccent
                                  : isNext
                                      ? const Color(0xFF7EC8E3)
                                      : isPassed
                                          ? AppTheme.textWhite
                                          : AppTheme.textMuted,
                            ),
                          ),
                        ),
                        if (isCurrent)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.goldAccent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color:
                                      AppTheme.goldAccent.withOpacity(0.4)),
                            ),
                            child: const Text(
                              "LAST HALT",
                              style: TextStyle(
                                color: AppTheme.goldAccent,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        if (isNext)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7EC8E3).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: const Color(0xFF7EC8E3)
                                      .withOpacity(0.4)),
                            ),
                            child: Text(
                              "ETA $_etaNextStation",
                              style: const TextStyle(
                                color: Color(0xFF7EC8E3),
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _timeChip("Sch",
                            station.scheduledArrival.isNotEmpty
                                ? station.scheduledArrival
                                : station.scheduledDeparture,
                            AppTheme.textMuted),
                        const SizedBox(width: 8),
                        _timeChip(
                          "Act",
                          station.actualArrival.isNotEmpty
                              ? station.actualArrival
                              : station.actualDeparture,
                          station.delayMinutes == 0
                              ? AppTheme.successGreen
                              : AppTheme.warningOrange,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _timeChip(String label, String time, Color color) {
    return Row(
      children: [
        Text(
          "$label: ",
          style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
        ),
        Text(
          time,
          style: TextStyle(
              fontSize: 10, color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildDashedLine({required double height, required Color color}) {
    return SizedBox(
      width: 2,
      height: height,
      child: CustomPaint(
        painter: _DashedLinePainter(color: color),
      ),
    );
  }
}

// ── Dashed Line Painter ─────────────────────────────────────────────────────
class _DashedLinePainter extends CustomPainter {
  final Color color;
  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    const dashHeight = 5.0;
    const dashSpace = 4.0;
    double startY = 0;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, startY),
        Offset(size.width / 2, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter old) => old.color != color;
}
