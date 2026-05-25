import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/train_service.dart';
import '../theme.dart';

class LiveTrackMap extends StatefulWidget {
  final LiveTrainRoute route;
  const LiveTrackMap({super.key, required this.route});

  @override
  State<LiveTrackMap> createState() => _LiveTrackMapState();
}

class _LiveTrackMapState extends State<LiveTrackMap> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  Timer? _telemetryTimer;

  // Real-time simulated telemetry
  double _currentSpeed = 108.5; // km/h
  double _currentLat = 0.0;
  double _currentLng = 0.0;
  double _distanceCovered = 0.0;
  double _distanceRemaining = 0.0;
  int _satellites = 12;
  double _radarSweepAngle = 0.0;
  int _etaSeconds = 240;

  @override
  void initState() {
    super.initState();
    
    // Animation for pulsing effects and map sweeps
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _animController.addListener(() {
      setState(() {
        _radarSweepAngle = _animController.value * 2 * math.pi;
      });
    });

    // Calculate initial values
    _updateTelemetry();

    // Telemetry updates every 1.5 seconds
    _telemetryTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (!mounted) return;
      setState(() {
        // Vary speed realistically
        _currentSpeed = 95.0 + math.Random().nextDouble() * 25.0;
        
        // Jitter satellites
        if (math.Random().nextDouble() > 0.8) {
          _satellites = 10 + math.Random().nextInt(5);
        }

        // Count down ETA
        if (_etaSeconds > 10) {
          _etaSeconds -= 1 + math.Random().nextInt(3);
        }

        _updateTelemetry();
      });
    });
  }

  void _updateTelemetry() {
    final route = widget.route;
    final int curIdx = route.currentStationIndex;
    final int nextIdx = math.min(curIdx + 1, route.stations.length - 1);

    final currentStation = route.stations[curIdx];
    final nextStation = route.stations[nextIdx];

    // Determine current train position interpolating between curIdx and nextIdx
    // For Vande Bharat, let's assume it has traveled 65% of the distance.
    double interpolationFactor = route.progressPercent;
    
    // Smooth progress simulation slightly over time
    double elapsedSeconds = (DateTime.now().second % 60) / 60.0;
    // Blend progressPercent with dynamic sub-second elapsed time
    double finalFactor = (interpolationFactor + (elapsedSeconds * 0.02)).clamp(0.0, 1.0);

    // Lat/Lng interpolation
    _currentLat = currentStation.latitude + (nextStation.latitude - currentStation.latitude) * finalFactor;
    _currentLng = currentStation.longitude + (nextStation.longitude - currentStation.longitude) * finalFactor;

    // Add tiny GPS jitter (4 decimal places variance)
    _currentLat += (math.Random().nextDouble() - 0.5) * 0.0002;
    _currentLng += (math.Random().nextDouble() - 0.5) * 0.0002;

    // Distances
    double totalSegmentDist = (nextStation.distanceKm - currentStation.distanceKm).toDouble();
    _distanceCovered = currentStation.distanceKm + (totalSegmentDist * finalFactor);
    _distanceRemaining = nextStation.distanceKm - _distanceCovered;
    if (_distanceRemaining < 0) _distanceRemaining = 0;
  }

  @override
  void dispose() {
    _animController.dispose();
    _telemetryTimer?.cancel();
    super.dispose();
  }

  String _formatDuration(int totalSecs) {
    int m = (totalSecs / 60).floor();
    int s = totalSecs % 60;
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final route = widget.route;
    final nextIdx = math.min(route.currentStationIndex + 1, route.stations.length - 1);
    final nextStation = route.stations[nextIdx];

    return Column(
      children: [
        // Live Telemetry Summary Strip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.cardNavy.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primaryLightNavy),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTelemetryItem(
                Icons.satellite_alt_rounded,
                "GPS STATUS",
                "$_satellites SATS (3D)",
                AppTheme.successGreen,
              ),
              const SizedBox(
                height: 30,
                child: VerticalDivider(color: AppTheme.primaryLightNavy, width: 2),
              ),
              _buildTelemetryItem(
                Icons.speed_rounded,
                "GPS SPEED",
                "${_currentSpeed.toStringAsFixed(1)} km/h",
                AppTheme.goldAccent,
              ),
              const SizedBox(
                height: 30,
                child: VerticalDivider(color: AppTheme.primaryLightNavy, width: 2),
              ),
              _buildTelemetryItem(
                Icons.location_on_rounded,
                "ALTITUDE",
                "124m MSL",
                AppTheme.textWhite,
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),

        // Interactive Map Card
        Stack(
          children: [
            Container(
              height: 380,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.backgroundDark,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.primaryLightNavy),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryNavy.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: InteractiveViewer(
                  maxScale: 4.0,
                  minScale: 0.6,
                  boundaryMargin: const EdgeInsets.all(80.0),
                  child: CustomPaint(
                    size: const Size(double.infinity, 380),
                    painter: MapPainter(
                      route: route,
                      trainLat: _currentLat,
                      trainLng: _currentLng,
                      radarSweepAngle: _radarSweepAngle,
                      pulseValue: _animController.value,
                    ),
                  ),
                ),
              ),
            ),
            
            // Map controls overlay: Pan/Zoom hint
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryDarkNavy.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.primaryLightNavy.withOpacity(0.5)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.zoom_in_map_rounded, size: 12, color: AppTheme.textMuted),
                    SizedBox(width: 6),
                    Text(
                      "PAN & ZOOM MAP",
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
            ),

            // Live Train Tracking HUD Label
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryDarkNavy.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.goldAccent.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppTheme.successGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      "LIVE RADAR ACTIVE",
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.goldAccent, letterSpacing: 0.8),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Glassmorphic Status Box
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryDarkNavy.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryLightNavy.withOpacity(0.8)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "GPS COORDINATES",
                              style: TextStyle(color: AppTheme.textMuted, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "${_currentLat.toStringAsFixed(5)}° N, ${_currentLng.toStringAsFixed(5)}° E",
                              style: const TextStyle(
                                color: AppTheme.textWhite, 
                                fontSize: 13, 
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace'
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "NEXT: ${nextStation.name.split(' (').first.toUpperCase()}",
                              style: const TextStyle(color: AppTheme.goldAccent, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "ETA: ~${_formatDuration(_etaSeconds)} Min",
                              style: const TextStyle(color: AppTheme.textWhite, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(color: AppTheme.primaryLightNavy, height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Covered: ${_distanceCovered.toStringAsFixed(1)} km",
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0),
                            child: LinearProgressIndicator(
                              value: widget.route.progressPercent,
                              backgroundColor: AppTheme.primaryLightNavy,
                              color: AppTheme.goldAccent,
                              minHeight: 4,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        Text(
                          "Left: ${_distanceRemaining.toStringAsFixed(1)} km",
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTelemetryItem(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class MapPainter extends CustomPainter {
  final LiveTrainRoute route;
  final double trainLat;
  final double trainLng;
  final double radarSweepAngle;
  final double pulseValue;

  MapPainter({
    required this.route,
    required this.trainLat,
    required this.trainLng,
    required this.radarSweepAngle,
    required this.pulseValue,
  });

  Offset getOffsetForLatLng(double lat, double lng, Size size) {
    double minLat = 90.0;
    double maxLat = -90.0;
    double minLng = 180.0;
    double maxLng = -180.0;

    for (var station in route.stations) {
      if (station.latitude < minLat) minLat = station.latitude;
      if (station.latitude > maxLat) maxLat = station.latitude;
      if (station.longitude < minLng) minLng = station.longitude;
      if (station.longitude > maxLng) maxLng = station.longitude;
    }

    // Add a small padding to the bounds so points aren't exactly on the border
    double latDiff = maxLat - minLat;
    double lngDiff = maxLng - minLng;
    if (latDiff == 0) latDiff = 1.0;
    if (lngDiff == 0) lngDiff = 1.0;
    
    minLat -= latDiff * 0.15;
    maxLat += latDiff * 0.15;
    minLng -= lngDiff * 0.15;
    maxLng += lngDiff * 0.15;

    double marginX = size.width * 0.1;
    double marginY = size.height * 0.1;
    double drawableWidth = size.width - (2 * marginX);
    double drawableHeight = size.height - (2 * marginY);

    double pctX = (lng - minLng) / (maxLng - minLng);
    double pctY = 1.0 - (lat - minLat) / (maxLat - minLat); // invert y for canvas

    return Offset(
      marginX + (pctX * drawableWidth),
      marginY + (pctY * drawableHeight),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final Paint gridPaint = Paint()
      ..color = AppTheme.primaryLightNavy.withOpacity(0.15)
      ..strokeWidth = 1.0;

    // 1. Draw Grid Lines & Radar Circles
    double gridSpacing = 40.0;
    for (double x = 0; x < size.width; x += gridSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += gridSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    Offset center = Offset(size.width / 2, size.height / 2);
    
    // Draw concentric radar lines
    for (double r = 60.0; r < size.width / 1.5; r += 70.0) {
      canvas.drawCircle(center, r, gridPaint);
    }

    // 2. Draw Radar Sweep Line
    final double sweepRadius = math.max(size.width, size.height);
    final Offset sweepEnd = Offset(
      center.dx + sweepRadius * math.cos(radarSweepAngle),
      center.dy + sweepRadius * math.sin(radarSweepAngle),
    );
    final Paint radarSweepPaint = Paint()
      ..shader = RadialGradient(
        colors: [AppTheme.goldAccent.withOpacity(0.12), Colors.transparent],
      ).createShader(Rect.fromCircle(center: center, radius: sweepRadius))
      ..style = PaintingStyle.fill;
    
    // Dynamic wedge path for sweeping radar glow
    final Path sweepPath = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: sweepRadius),
        radarSweepAngle - 0.25,
        0.25,
        false,
      )
      ..close();
    canvas.drawPath(sweepPath, radarSweepPaint);

    // Draw active sweep line
    final Paint sweepLinePaint = Paint()
      ..color = AppTheme.goldAccent.withOpacity(0.2)
      ..strokeWidth = 1.5;
    canvas.drawLine(center, sweepEnd, sweepLinePaint);

    // 3. Draw Route Path (Line connecting all stations)
    if (route.stations.length >= 2) {
      final Path routePath = Path();
      Offset startOffset = getOffsetForLatLng(route.stations[0].latitude, route.stations[0].longitude, size);
      routePath.moveTo(startOffset.dx, startOffset.dy);

      for (int i = 1; i < route.stations.length; i++) {
        Offset nextOffset = getOffsetForLatLng(route.stations[i].latitude, route.stations[i].longitude, size);
        routePath.lineTo(nextOffset.dx, nextOffset.dy);
      }

      // Draw background glow path
      final Paint pathGlowPaint = Paint()
        ..color = AppTheme.goldAccent.withOpacity(0.12)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 8.0;
      canvas.drawPath(routePath, pathGlowPaint);

      // Draw primary path line
      final Paint pathPaint = Paint()
        ..color = AppTheme.primaryLightNavy
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 3.0;
      canvas.drawPath(routePath, pathPaint);

      // Draw active/passed path line in gold
      final Path activePath = Path();
      activePath.moveTo(startOffset.dx, startOffset.dy);

      for (int i = 1; i <= route.currentStationIndex; i++) {
        Offset nextOffset = getOffsetForLatLng(route.stations[i].latitude, route.stations[i].longitude, size);
        activePath.lineTo(nextOffset.dx, nextOffset.dy);
      }
      
      // Interpolate current train position
      Offset trainOffset = getOffsetForLatLng(trainLat, trainLng, size);
      activePath.lineTo(trainOffset.dx, trainOffset.dy);

      final Paint activePathPaint = Paint()
        ..color = AppTheme.goldAccent
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 3.0;
      canvas.drawPath(activePath, activePathPaint);
    }

    // 4. Draw Station Markers & Text Labels
    for (int i = 0; i < route.stations.length; i++) {
      final station = route.stations[i];
      final Offset offset = getOffsetForLatLng(station.latitude, station.longitude, size);
      final bool isPassed = i <= route.currentStationIndex;

      // Draw station beacon glow
      final double beaconRadius = 6.0 + (pulseValue * 8.0);
      final Paint beaconPaint = Paint()
        ..color = isPassed 
            ? AppTheme.goldAccent.withOpacity(0.25 * (1.0 - pulseValue)) 
            : AppTheme.primaryLightNavy.withOpacity(0.2 * (1.0 - pulseValue))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(offset, beaconRadius, beaconPaint);

      // Draw station center dot
      final Paint dotPaint = Paint()
        ..color = isPassed ? AppTheme.goldAccent : AppTheme.primaryLightNavy
        ..style = PaintingStyle.fill;
      canvas.drawCircle(offset, 4.0, dotPaint);

      // Draw border ring
      final Paint ringPaint = Paint()
        ..color = isPassed ? AppTheme.goldAccent : AppTheme.textMuted.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawCircle(offset, 6.0, ringPaint);

      // Draw station text label
      final String displayName = station.name.split(' (').first; // e.g. "New Delhi"
      final textSpan = TextSpan(
        text: displayName,
        style: TextStyle(
          color: isPassed ? AppTheme.textWhite : AppTheme.textMuted,
          fontSize: 8,
          fontWeight: isPassed ? FontWeight.bold : FontWeight.normal,
          shadows: const [
            Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1, 1))
          ]
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      // Position labels slightly offset from dot
      canvas.save();
      canvas.translate(offset.dx - (textPainter.width / 2), offset.dy - 18.0);
      textPainter.paint(canvas, Offset.zero);
      canvas.restore();
    }

    // 5. Draw Live Train Icon & Pulse
    final Offset trainOffset = getOffsetForLatLng(trainLat, trainLng, size);
    
    // Pulsing outer ring for train
    final double trainPulseRadius = 10.0 + (pulseValue * 16.0);
    final Paint trainPulsePaint = Paint()
      ..color = AppTheme.successGreen.withOpacity(0.35 * (1.0 - pulseValue))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(trainOffset, trainPulseRadius, trainPulsePaint);

    // Inner glowing ring
    final Paint trainRingPaint = Paint()
      ..color = AppTheme.successGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(trainOffset, 8.0, trainRingPaint);

    // Solid center dot
    final Paint trainDotPaint = Paint()
      ..color = AppTheme.successGreen
      ..style = PaintingStyle.fill;
    canvas.drawCircle(trainOffset, 4.5, trainDotPaint);
  }

  @override
  bool shouldRepaint(covariant MapPainter oldDelegate) {
    return oldDelegate.trainLat != trainLat ||
        oldDelegate.trainLng != trainLng ||
        oldDelegate.radarSweepAngle != radarSweepAngle ||
        oldDelegate.pulseValue != pulseValue;
  }
}
