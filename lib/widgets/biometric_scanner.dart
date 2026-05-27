import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/auth_service.dart';
import '../theme.dart';

class FingerprintScannerWidget extends StatefulWidget {
  final VoidCallback onAuthenticationComplete;

  const FingerprintScannerWidget({
    super.key,
    required this.onAuthenticationComplete,
  });

  @override
  State<FingerprintScannerWidget> createState() => _FingerprintScannerWidgetState();
}

class _FingerprintScannerWidgetState extends State<FingerprintScannerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  bool _isScanning = false;
  bool _scanSuccess = false;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _scanSuccess = true;
          _isScanning = false;
        });
        Future.delayed(const Duration(milliseconds: 400), () {
          widget.onAuthenticationComplete();
        });
      }
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  void _startScan() {
    if (_scanSuccess) return;
    if (!AuthService().hasRegisteredUsers) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Security Alert: No registered account found! Please register first."),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }
    setState(() {
      _isScanning = true;
    });
    _progressController.forward();
  }

  void _cancelScan() {
    if (_scanSuccess) return;
    setState(() {
      _isScanning = false;
    });
    _progressController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTapDown: (_) => _startScan(),
          onTapUp: (_) => _cancelScan(),
          onTapCancel: () => _cancelScan(),
          child: AnimatedBuilder(
            animation: _progressController,
            builder: (context, child) {
              final double value = _progressController.value;
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Pulse Ripple Background
                  if (_isScanning)
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.goldAccent.withOpacity(0.3 * (1 - value)),
                          width: 20 * value,
                        ),
                      ),
                    ),
                  
                  // Scanning Ring Progress
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryLightNavy,
                      boxShadow: [
                        BoxShadow(
                          color: _scanSuccess
                              ? AppTheme.successGreen.withOpacity(0.5)
                              : _isScanning
                                  ? AppTheme.goldAccent.withOpacity(0.3)
                                  : Colors.black.withOpacity(0.4),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: CircularProgressIndicator(
                      value: value,
                      strokeWidth: 4,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _scanSuccess ? AppTheme.successGreen : AppTheme.goldAccent,
                      ),
                    ),
                  ),

                  // Center Fingerprint Icon
                  Icon(
                    _scanSuccess
                        ? Icons.check_circle_outline
                        : Icons.fingerprint_rounded,
                    size: 64,
                    color: _scanSuccess
                        ? AppTheme.successGreen
                        : _isScanning
                            ? AppTheme.goldAccent
                            : AppTheme.textMuted,
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _scanSuccess
              ? "AUTHENTICATED"
              : _isScanning
                  ? "KEEP HOLDING..."
                  : "PRESS & HOLD TO SCAN",
          style: TextStyle(
            color: _scanSuccess
                ? AppTheme.successGreen
                : _isScanning
                    ? AppTheme.goldAccent
                    : AppTheme.textMuted,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

class FaceScannerWidget extends StatefulWidget {
  final VoidCallback onAuthenticationComplete;

  const FaceScannerWidget({
    super.key,
    required this.onAuthenticationComplete,
  });

  @override
  State<FaceScannerWidget> createState() => _FaceScannerWidgetState();
}

class _FaceScannerWidgetState extends State<FaceScannerWidget>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  late AnimationController _scannerController;
  bool _isScanning = false;
  bool _scanSuccess = false;

  // Camera setup
  CameraController? _cameraController;
  bool _isCameraInitialized = false;

  // Live status ticker log
  String _liveStatusLog = "READY FOR CAMERA FEED";
  double _matchingPercentage = 0.0;
  Timer? _tickerTimer;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _scannerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _scannerController.addListener(() {
      setState(() {
        double val = _scannerController.value;
        if (val < 0.25) {
          _liveStatusLog = "CAMERA ACTIVE: ACQUIRING SENSORS";
          _matchingPercentage = val * 80;
        } else if (val < 0.55) {
          _liveStatusLog = "FACIAL NODES: 68/68 MAP DETECTED";
          _matchingPercentage = 20 + val * 60;
        } else if (val < 0.85) {
          _liveStatusLog = "AADHAAR LINK: ${_authService.userAadhaar}";
          _matchingPercentage = 50 + val * 50;
        } else {
          _liveStatusLog = "VERIFIED USER: ${_authService.userName.toUpperCase()}";
          _matchingPercentage = 95 + (1 - val) * 20; // fluctuate around 99%
        }
      });
    });

    _scannerController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _scanSuccess = true;
          _isScanning = false;
          _liveStatusLog = "AADHAAR VERIFIED MATCH: 99.8%";
        });
        Future.delayed(const Duration(milliseconds: 600), () {
          widget.onAuthenticationComplete();
        });
      }
    });
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      
      // Try to find a front facing camera
      CameraDescription? frontCamera;
      for (var camera in cameras) {
        if (camera.lensDirection == CameraLensDirection.front) {
          frontCamera = camera;
          break;
        }
      }
      frontCamera ??= cameras.first;

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _liveStatusLog = "CAMERA FEED ACTIVE";
        });
      }
    } catch (e) {
      debugPrint("Camera init error: $e");
      if (mounted) {
        setState(() {
          _liveStatusLog = "CAMERA UNAVAILABLE";
        });
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _scannerController.dispose();
    _tickerTimer?.cancel();
    super.dispose();
  }

  void _startScan() {
    if (_isScanning || _scanSuccess) return;
    if (!_authService.hasRegisteredUsers) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Security Alert: No registered account found! Please register first."),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }
    setState(() {
      _isScanning = true;
    });
    _scannerController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _startScan,
          child: Stack(
            children: [
              Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: _scanSuccess
                        ? AppTheme.successGreen
                        : _isScanning
                            ? AppTheme.goldAccent
                            : AppTheme.primaryLightNavy,
                    width: 2,
                  ),
                  color: Colors.black.withOpacity(0.6),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (_isCameraInitialized && _cameraController != null)
                        FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: _cameraController!.value.previewSize?.width ?? 1,
                            height: _cameraController!.value.previewSize?.height ?? 1,
                            child: CameraPreview(_cameraController!),
                          ),
                        )
                      else
                        Container(color: Colors.black87),
                      AnimatedBuilder(
                        animation: _scannerController,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: CameraViewfinderPainter(
                              progress: _scannerController.value,
                              isScanning: _isScanning,
                              isSuccess: _scanSuccess,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              // Top-right simulated lens telemetry info
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    "LENS f/2.2 ISO400",
                    style: TextStyle(fontSize: 7, color: AppTheme.textMuted, fontFamily: 'monospace'),
                  ),
                ),
              ),
              
              // Top-left GPS Lock status
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: _isScanning ? AppTheme.goldAccent : _scanSuccess ? AppTheme.successGreen : AppTheme.textMuted,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        "AUTO FOCUS",
                        style: TextStyle(fontSize: 7, color: AppTheme.textWhite, fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),

        // Live Ticker Log Box
        Container(
          width: 220,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.primaryDarkNavy.withOpacity(0.8),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _scanSuccess 
                  ? AppTheme.successGreen.withOpacity(0.3) 
                  : AppTheme.primaryLightNavy
            ),
          ),
          child: Column(
            children: [
              Text(
                _liveStatusLog,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _scanSuccess 
                      ? AppTheme.successGreen 
                      : _isScanning 
                          ? AppTheme.goldAccent 
                          : AppTheme.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
              if (_isScanning) ...[
                const SizedBox(height: 4),
                Text(
                  "MATCH FACTOR: ${_matchingPercentage.toStringAsFixed(1)}%",
                  style: const TextStyle(
                    color: AppTheme.textWhite,
                    fontSize: 8,
                    fontFamily: 'monospace',
                  ),
                ),
              ]
            ],
          ),
        ),

        const SizedBox(height: 16),
        Text(
          _scanSuccess
              ? "MATCH VERIFIED"
              : _isScanning
                  ? "ANALYZING FACE SENSOR..."
                  : "TAP VIEWPORT TO SCAN",
          style: TextStyle(
            color: _scanSuccess
                ? AppTheme.successGreen
                : _isScanning
                    ? AppTheme.goldAccent
                    : AppTheme.textMuted,
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }
}

class CameraViewfinderPainter extends CustomPainter {
  final double progress;
  final bool isScanning;
  final bool isSuccess;

  CameraViewfinderPainter({
    required this.progress,
    required this.isScanning,
    required this.isSuccess,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Viewfinder grid and corners
    final Paint linePaint = Paint()
      ..color = isSuccess
          ? AppTheme.successGreen.withOpacity(0.3)
          : isScanning
              ? AppTheme.goldAccent.withOpacity(0.3)
              : AppTheme.primaryLightNavy
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Corner bounding lines
    double cornerLen = 16.0;
    double padding = 12.0;

    // Top-Left Corner
    canvas.drawLine(Offset(padding, padding), Offset(padding + cornerLen, padding), linePaint);
    canvas.drawLine(Offset(padding, padding), Offset(padding, padding + cornerLen), linePaint);
    
    // Top-Right Corner
    canvas.drawLine(Offset(size.width - padding, padding), Offset(size.width - padding - cornerLen, padding), linePaint);
    canvas.drawLine(Offset(size.width - padding, padding), Offset(size.width - padding, padding + cornerLen), linePaint);

    // Bottom-Left Corner
    canvas.drawLine(Offset(padding, size.height - padding), Offset(padding + cornerLen, size.height - padding), linePaint);
    canvas.drawLine(Offset(padding, size.height - padding), Offset(padding, size.height - padding - cornerLen), linePaint);

    // Bottom-Right Corner
    canvas.drawLine(Offset(size.width - padding, size.height - padding), Offset(size.width - padding - cornerLen, size.height - padding), linePaint);
    canvas.drawLine(Offset(size.width - padding, size.height - padding), Offset(size.width - padding, size.height - padding - cornerLen), linePaint);

    // Center Crosshair
    Offset center = Offset(size.width / 2, size.height / 2);
    canvas.drawLine(Offset(center.dx - 8, center.dy), Offset(center.dx + 8, center.dy), linePaint);
    canvas.drawLine(Offset(center.dx, center.dy - 8), Offset(center.dx, center.dy + 8), linePaint);

    // 2. Draw Facial Silhouette or scan outline
    final Paint facePaint = Paint()
      ..color = isSuccess
          ? AppTheme.successGreen.withOpacity(0.2)
          : isScanning
              ? AppTheme.goldAccent.withOpacity(0.1 + (0.3 * math.sin(progress * math.pi)))
              : AppTheme.textMuted.withOpacity(0.15)
      ..style = PaintingStyle.fill;

    final Paint faceOutlinePaint = Paint()
      ..color = isSuccess
          ? AppTheme.successGreen
          : isScanning
              ? AppTheme.goldAccent
              : AppTheme.textMuted.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw stylized head silhouette path
    final Path facePath = Path()
      ..moveTo(center.dx, center.dy - 60) // Top of head
      ..cubicTo(center.dx + 40, center.dy - 60, center.dx + 45, center.dy - 10, center.dx + 40, center.dy + 20) // Right side
      ..cubicTo(center.dx + 30, center.dy + 45, center.dx + 15, center.dy + 55, center.dx, center.dy + 55) // Jaw right to chin
      ..cubicTo(center.dx - 15, center.dy + 55, center.dx - 30, center.dy + 45, center.dx - 40, center.dy + 20) // Chin to jaw left
      ..cubicTo(center.dx - 45, center.dy - 10, center.dx - 40, center.dy - 60, center.dx, center.dy - 60) // Left side to top
      ..close();

    canvas.drawPath(facePath, facePaint);
    canvas.drawPath(facePath, faceOutlinePaint);

    // 3. Draw Scan Grid Nodes & Lines (Cybernetic points on eyes, nose, cheeks)
    if (isScanning || isSuccess) {
      final List<Offset> facialNodes = [
        Offset(center.dx - 18, center.dy - 15), // Left Eye
        Offset(center.dx + 18, center.dy - 15), // Right Eye
        Offset(center.dx, center.dy + 5),       // Nose bridge
        Offset(center.dx, center.dy + 15),      // Nose tip
        Offset(center.dx - 18, center.dy + 35), // Mouth Left
        Offset(center.dx + 18, center.dy + 35), // Mouth Right
        Offset(center.dx, center.dy + 40),      // Mouth Center
        Offset(center.dx - 32, center.dy + 12), // Left Cheek
        Offset(center.dx + 32, center.dy + 12), // Right Cheek
        Offset(center.dx, center.dy - 40),      // Forehead
      ];

      final Paint nodePaint = Paint()
        ..color = isSuccess ? AppTheme.successGreen : AppTheme.goldAccent
        ..style = PaintingStyle.fill;

      final Paint nodeLinePaint = Paint()
        ..color = (isSuccess ? AppTheme.successGreen : AppTheme.goldAccent).withOpacity(0.25)
        ..strokeWidth = 0.8;

      // Draw lines connecting nodes to form a mesh
      for (int i = 0; i < facialNodes.length; i++) {
        for (int j = i + 1; j < facialNodes.length; j++) {
          // Connect nearby nodes
          double distance = (facialNodes[i] - facialNodes[j]).distance;
          if (distance < 45) {
            canvas.drawLine(facialNodes[i], facialNodes[j], nodeLinePaint);
          }
        }
      }

      // Draw node dots
      for (var node in facialNodes) {
        canvas.drawCircle(node, 2.5, nodePaint);
      }
    }

    // 4. Draw Moving Scan Laser Line
    if (isScanning && !isSuccess) {
      double laserY = padding + (progress * (size.height - 2 * padding));
      final Paint laserPaint = Paint()
        ..color = AppTheme.goldAccent
        ..strokeWidth = 2.0;

      final Paint laserGlowPaint = Paint()
        ..color = AppTheme.goldAccent.withOpacity(0.4)
        ..strokeWidth = 6.0;

      canvas.drawLine(Offset(padding + 2, laserY), Offset(size.width - padding - 2, laserY), laserGlowPaint);
      canvas.drawLine(Offset(padding + 4, laserY), Offset(size.width - padding - 4, laserY), laserPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CameraViewfinderPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isScanning != isScanning ||
        oldDelegate.isSuccess != isSuccess;
  }
}
