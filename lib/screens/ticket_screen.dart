import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/booking_service.dart';
import '../services/auth_service.dart';
import '../models/booking.dart';
import '../theme.dart';

class TicketDetailScreen extends StatefulWidget {
  const TicketDetailScreen({super.key});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  final BookingService _bookingService = BookingService();

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

  void _confirmCancelTicket(BuildContext context, Booking booking) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardNavy,
          title: const Text("Cancel Ticket", style: TextStyle(color: AppTheme.errorRed, fontWeight: FontWeight.bold)),
          content: Text(
            "Are you sure you want to cancel booking for PNR ${booking.pnr}?\n\nAs per rules, a cancellation fee of ₹120 per passenger will be charged. Refund will be credited instantly to your IRCTC eWallet.",
            style: const TextStyle(color: AppTheme.textWhite),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("NO", style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final success = await _bookingService.cancelBooking(booking.pnr);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Ticket cancelled. Refund credited to eWallet."),
                      backgroundColor: AppTheme.successGreen,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed, foregroundColor: Colors.white),
              child: const Text("YES, CANCEL"),
            ),
          ],
        );
      },
    );
  }

  void _simulateTicketDownload(BuildContext context, Booking booking) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return _DownloadProgressDialog(booking: booking);
      },
    );
  }

  void _simulateWhatsAppShare(BuildContext context, Booking booking) {
    showDialog(
      context: context,
      builder: (context) {
        return _WhatsAppShareDialog(booking: booking);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String pnr = ModalRoute.of(context)!.settings.arguments as String;
    final booking = _bookingService.findByPnr(pnr);

    if (booking == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("TICKET NOT FOUND")),
        body: const Center(
          child: Text("Error: Booking record could not be located.", style: TextStyle(color: AppTheme.errorRed)),
        ),
      );
    }

    final isConfirmed = booking.status == "CONFIRMED";
    final isGeneral = booking.train.classes.contains("GEN") || booking.passengers.any((p) => p.coach == "GEN" || p.seatNumber == null);

    return Scaffold(
      appBar: AppBar(
        title: const Text("IRCTC DIGITAL PASS"),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Ticket details copied to clipboard. Ready to share!")),
              );
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Classic Cream Indian Railways Counter Ticket
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFDF5), // Creamy paper texture
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD4C8B3), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Stack(
                  children: [
                    // Large watermark background
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.train_rounded,
                          size: 240,
                          color: const Color(0xFF5A3A00).withOpacity(0.03),
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Classic Railways Saffron Header Band
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFC05A11), // Indian Railways Orange/Saffron
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Icon(Icons.train_rounded, color: Colors.white, size: 20),
                                    Text(
                                      isGeneral ? "భారతీయ రైల్వేలు / INDIAN RAILWAYS" : "भारतीय रेल / INDIAN RAILWAYS",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                    const Icon(Icons.train_rounded, color: Colors.white, size: 20),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  "ई-टिकट यात्रा रिकॉर्ड / E-TICKET JOURNEY RECORD",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // 2. Ticket Metadata Block (PNR, Train Number, Date)
                          _buildTicketMetaGrid(booking, isGeneral),

                          const SizedBox(height: 8),
                          _buildDivider(),
                          const SizedBox(height: 8),

                          // 3. From / To Stations Block
                          _buildRouteBlock(booking),

                          const SizedBox(height: 8),
                          _buildDivider(),
                          const SizedBox(height: 8),

                          // 4. Passenger Manifest Table
                          const Text(
                            "यात्री विवरण / PASSENGER MANIFEST",
                            style: TextStyle(
                              color: Color(0xFF803D00),
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _buildPassengerTable(booking, isConfirmed, isGeneral),

                          const SizedBox(height: 10),
                          _buildDivider(),
                          const SizedBox(height: 10),

                          // 5. Fare Details Block
                          const Text(
                            "भुगतान विवरण / FARE BREAKDOWN",
                            style: TextStyle(
                              color: Color(0xFF803D00),
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _buildFareTable(booking),

                          const SizedBox(height: 14),
                          _buildDivider(),
                          const SizedBox(height: 14),

                          // 6. QR Code, Barcode & Instructions Section
                          Row(
                            children: [
                              // QR Code
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: const Color(0xFFD4C8B3)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: QrImageView(
                                  data: "PNR:${booking.pnr}|TRAIN:${booking.train.number}|DATE:${booking.journeyDate}|STATUS:${booking.status}",
                                  version: QrVersions.auto,
                                  size: 100.0,
                                  eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
                                  dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
                                ),
                              ),
                              const SizedBox(width: 14),
                              
                              // Barcode & Disclaimer
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildBarcode(booking.pnr),
                                    const SizedBox(height: 6),
                                    const Text(
                                      "Disclaimers & Verification:\n1. Please carry original Identity Proof during the journey.\n2. General tickets are valid only in general unreserved coaches.",
                                      style: TextStyle(
                                        color: Colors.black54,
                                        fontSize: 8,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Download and Share Actions Row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _simulateTicketDownload(context, booking),
                      icon: const Icon(Icons.download_for_offline_rounded, size: 20, color: AppTheme.goldAccent),
                      label: const Text("DOWNLOAD PDF", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.goldAccent,
                        side: const BorderSide(color: AppTheme.goldAccent, width: 1.5),
                        minimumSize: const Size(0, 46),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _simulateWhatsAppShare(context, booking),
                      icon: const Icon(Icons.share_rounded, size: 20, color: Colors.white),
                      label: const Text("WHATSAPP SHARE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 46),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Action Buttons
              if (isConfirmed) ...[
                ElevatedButton.icon(
                  onPressed: () => _confirmCancelTicket(context, booking),
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text("CANCEL TICKET BOOKING", style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.errorRed,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 46),
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.errorRed.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.errorRed.withOpacity(0.3)),
                  ),
                  child: const Text(
                    "TICKET CANCELLED - REFUND PROCESSED IN EWALLET",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.errorRed, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTicketMetaGrid(Booking booking, bool isGeneral) {
    return Table(
      border: TableBorder.all(color: const Color(0xFFE0D6C1), width: 1),
      children: [
        TableRow(
          children: [
            _buildMetaCell("PNR NO", booking.pnr, isBold: true, valueColor: const Color(0xFFC05A11)),
            _buildMetaCell("TRAIN NO & NAME", "${booking.train.number} / ${booking.train.name.split(' ').first}"),
          ],
        ),
        TableRow(
          children: [
            _buildMetaCell("CLASS", isGeneral ? "GENERAL (2S/GEN)" : "CHAIR CAR (CC)", isBold: true),
            _buildMetaCell("QUOTA", "GENERAL (GN)"),
          ],
        ),
        TableRow(
          children: [
            _buildMetaCell("DATE OF JOURNEY", booking.journeyDate),
            _buildMetaCell("BOOKING DATE & TIME", "${booking.bookingDate.day}-${booking.bookingDate.month}-${booking.bookingDate.year} | ${booking.bookingDate.hour}:${booking.bookingDate.minute.toString().padLeft(2, '0')}"),
          ],
        ),
      ],
    );
  }

  Widget _buildMetaCell(String label, String value, {bool isBold = false, Color valueColor = Colors.black}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 8, color: Colors.black54, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteBlock(Booking booking) {
    final srcName = booking.bookedSource ?? booking.train.source;
    final destName = booking.bookedDestination ?? booking.train.destination;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("BOARDING FROM", style: TextStyle(fontSize: 8, color: Colors.black54, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(
                srcName,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const SizedBox(height: 2),
              Text(
                "Departs: ${booking.train.departureTime}",
                style: const TextStyle(fontSize: 10, color: Color(0xFFC05A11), fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: Icon(Icons.arrow_forward_rounded, color: Color(0xFFC05A11), size: 18),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text("RESERVATION UP TO", style: TextStyle(fontSize: 8, color: Colors.black54, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(
                destName,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const SizedBox(height: 2),
              Text(
                "Arrives: ${booking.train.arrivalTime}",
                style: const TextStyle(fontSize: 10, color: Color(0xFFC05A11), fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPassengerTable(Booking booking, bool isConfirmed, bool isGeneral) {
    return Table(
      border: TableBorder.all(color: const Color(0xFFE0D6C1), width: 1),
      columnWidths: const {
        0: FractionColumnWidth(0.08),
        1: FractionColumnWidth(0.42),
        2: FractionColumnWidth(0.15),
        3: FractionColumnWidth(0.35),
      },
      children: [
        // Header
        TableRow(
          decoration: const BoxDecoration(color: Color(0xFFF0E7D5)),
          children: const [
            Padding(padding: EdgeInsets.all(4.0), child: Text("S.N.", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.black))),
            Padding(padding: EdgeInsets.all(4.0), child: Text("NAME / नाम", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.black))),
            Padding(padding: EdgeInsets.all(4.0), child: Text("AGE/SEX", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.black))),
            Padding(padding: EdgeInsets.all(4.0), child: Text("SEAT/COACH/STATUS", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.black))),
          ],
        ),
        // Rows
        ...List.generate(booking.passengers.length, (index) {
          final p = booking.passengers[index];
          final String seatInfo = !isConfirmed 
              ? "CANCELLED" 
              : isGeneral 
                  ? "GEN / UNRESERVED" 
                  : "${p.coach ?? 'C4'} / Seat: ${p.seatNumber ?? '28'} / ${p.berthPreference.toUpperCase()}";
          return TableRow(
            children: [
              Padding(padding: const EdgeInsets.all(4.0), child: Text("${index + 1}", style: const TextStyle(fontSize: 9, color: Colors.black))),
              Padding(padding: const EdgeInsets.all(4.0), child: Text(p.name, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black))),
              Padding(padding: const EdgeInsets.all(4.0), child: Text("${p.age}/${p.gender.substring(0, 1)}", style: const TextStyle(fontSize: 9, color: Colors.black))),
              Padding(
                padding: const EdgeInsets.all(4.0), 
                child: Text(
                  seatInfo, 
                  style: TextStyle(
                    fontSize: 8.5, 
                    fontWeight: FontWeight.bold, 
                    color: !isConfirmed ? Colors.red : const Color(0xFFC05A11),
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildFareTable(Booking booking) {
    final double baseFare = booking.totalAmount - 21.80;
    return Table(
      border: TableBorder.all(color: const Color(0xFFE0D6C1), width: 1),
      columnWidths: const {
        0: FractionColumnWidth(0.7),
        1: FractionColumnWidth(0.3),
      },
      children: [
        TableRow(
          children: [
            const Padding(padding: EdgeInsets.all(4.0), child: Text("Ticket Fare (Basic Journey Charge)", style: TextStyle(fontSize: 8.5, color: Colors.black))),
            Padding(padding: const EdgeInsets.all(4.0), child: Text("₹${baseFare.toStringAsFixed(2)}", style: const TextStyle(fontSize: 9, color: Colors.black, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
          ],
        ),
        TableRow(
          children: [
            const Padding(padding: EdgeInsets.all(4.0), child: Text("IRCTC Convenience Fee (incl. GST)", style: TextStyle(fontSize: 8.5, color: Colors.black))),
            const Padding(padding: EdgeInsets.all(4.0), child: Text("₹11.80", style: TextStyle(fontSize: 9, color: Colors.black, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
          ],
        ),
        TableRow(
          children: [
            const Padding(padding: EdgeInsets.all(4.0), child: Text("Travel Insurance & PG Charges", style: TextStyle(fontSize: 8.5, color: Colors.black))),
            const Padding(padding: EdgeInsets.all(4.0), child: Text("₹10.00", style: TextStyle(fontSize: 9, color: Colors.black, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
          ],
        ),
        TableRow(
          decoration: const BoxDecoration(color: Color(0xFFF7EEDC)),
          children: [
            const Padding(padding: EdgeInsets.all(4.0), child: Text("कुल किराया / TOTAL FARE PAID", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black))),
            Padding(
              padding: const EdgeInsets.all(4.0), 
              child: Text(
                "₹${booking.totalAmount.toStringAsFixed(2)}", 
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFC05A11)),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBarcode(String pnr) {
    final List<double> lineWidths = [1.2, 2.5, 1.2, 3.5, 1.2, 1.2, 2.5, 4.5, 1.2, 2.5, 1.2, 3.5, 1.2, 2.5, 1.2, 1.2, 3.5, 2.5, 1.2, 4.5, 1.2, 2.5, 1.2, 3.5, 1.2, 1.2, 2.5, 3.5, 1.2, 2.5, 1.2];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: lineWidths.map((w) {
            return Container(
              width: w,
              height: 32,
              color: Colors.black87,
              margin: const EdgeInsets.symmetric(horizontal: 0.5),
            );
          }).toList(),
        ),
        const SizedBox(height: 3),
        Text(
          "*IRCTC-$pnr-RES*",
          style: const TextStyle(color: Colors.black54, fontSize: 8, fontWeight: FontWeight.bold, fontFamily: 'monospace', letterSpacing: 1.0),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Row(
      children: List.generate(
        40,
        (index) => Expanded(
          child: Container(
            color: index % 2 == 0 ? Colors.transparent : const Color(0xFFD4C8B3),
            height: 1,
          ),
        ),
      ),
    );
  }
}

// ==========================================
// SIMULATED DOWNLOAD AND WHATSAPP SHARE WIDGETS
// ==========================================

class _DownloadProgressDialog extends StatefulWidget {
  final Booking booking;
  const _DownloadProgressDialog({required this.booking});

  @override
  State<_DownloadProgressDialog> createState() => _DownloadProgressDialogState();
}

class _DownloadProgressDialogState extends State<_DownloadProgressDialog> {
  double _progress = 0.0;
  String _statusText = "Initializing download...";
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _startSimulatedDownload();
  }

  void _startSimulatedDownload() async {
    const steps = [
      (0.15, "Connecting to IRCTC secure nodes..."),
      (0.35, "Compiling PNR manifest data..."),
      (0.60, "Generating High-Res Ticket Layout..."),
      (0.85, "Embedding digital security watermark..."),
      (1.00, "Encrypting & saving PDF document..."),
    ];

    for (var step in steps) {
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 300));
      setState(() {
        _progress = step.$1;
        _statusText = step.$2;
      });
    }

    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) {
      setState(() {
        _isCompleted = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.cardNavy,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_isCompleted) ...[
              const SizedBox(
                width: 65,
                height: 65,
                child: CircularProgressIndicator(
                  color: AppTheme.goldAccent,
                  strokeWidth: 4,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "DOWNLOADING TICKET",
                style: TextStyle(
                  color: AppTheme.goldAccent,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _statusText,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: AppTheme.primaryLightNavy,
                  color: AppTheme.goldAccent,
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "${(_progress * 100).toInt()}%",
                style: const TextStyle(color: AppTheme.textWhite, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ] else ...[
              const Icon(
                Icons.check_circle_rounded,
                color: AppTheme.successGreen,
                size: 70,
              ),
              const SizedBox(height: 16),
              const Text(
                "DOWNLOAD SUCCESSFUL!",
                style: TextStyle(
                  color: AppTheme.successGreen,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Your official E-Ticket for PNR ${widget.booking.pnr} has been successfully compiled and downloaded.",
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textWhite, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryDarkNavy,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "Saved to: Downloads/IRCTC_${widget.booking.bookingDate.millisecondsSinceEpoch}.pdf",
                  style: const TextStyle(color: AppTheme.goldLight, fontFamily: 'monospace', fontSize: 10),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textMuted,
                        side: const BorderSide(color: AppTheme.primaryLightNavy),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text("CLOSE", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showPdfViewer(context, widget.booking);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.goldAccent,
                        foregroundColor: AppTheme.primaryNavy,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text("VIEW PDF", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

void _showPdfViewer(BuildContext context, Booking booking) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: "PDF Viewer",
    pageBuilder: (context, anim1, anim2) {
      return _PdfViewerScreen(booking: booking);
    },
  );
}

class _PdfViewerScreen extends StatelessWidget {
  final Booking booking;
  const _PdfViewerScreen({required this.booking});

  @override
  Widget build(BuildContext context) {
    final double baseFare = booking.totalAmount - 21.80;
    final isConfirmed = booking.status == "CONFIRMED";
    final isGeneral = booking.train.classes.contains("GEN") || booking.passengers.any((p) => p.coach == "GEN" || p.seatNumber == null);

    return Scaffold(
      backgroundColor: const Color(0xFF525659), // Classic PDF viewer dark grey background
      appBar: AppBar(
        backgroundColor: const Color(0xFF323639), // PDF reader toolbar dark color
        title: Text(
          "IRCTC_Ticket_${booking.pnr}.pdf",
          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.normal),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Connecting to local printer...")),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.download_outlined, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("File already saved in local downloads.")),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Container(
            width: MediaQuery.of(context).size.width > 500 ? 500 : double.infinity,
            decoration: BoxDecoration(
              color: Colors.white, // Printed sheet background
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ],
            ),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // PDF Printable Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.train_rounded, color: Color(0xFFC05A11), size: 24),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              "INDIAN RAILWAYS",
                              style: TextStyle(
                                color: Color(0xFF333333),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "CRIS - IRCTC E-TICKET SERVICE",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Text(
                      "ORIGINAL TICKET",
                      style: TextStyle(
                        color: Color(0xFFC05A11),
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(height: 1.5, color: Colors.grey[300]),
                const SizedBox(height: 12),

                // Booking / PNR header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("PNR Number", style: TextStyle(color: Colors.grey, fontSize: 8, fontWeight: FontWeight.bold)),
                        Text(booking.pnr, style: const TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text("Journey Date", style: TextStyle(color: Colors.grey, fontSize: 8, fontWeight: FontWeight.bold)),
                        Text(booking.journeyDate, style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Route section
                Container(
                  padding: const EdgeInsets.all(10),
                  color: Colors.grey[100],
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("FROM (Boarding Station)", style: TextStyle(color: Colors.grey, fontSize: 7, fontWeight: FontWeight.bold)),
                            Text(booking.bookedSource ?? booking.train.source, style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                            Text("Scheduled Departure: ${booking.train.departureTime}", style: const TextStyle(color: Colors.black54, fontSize: 8)),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward, color: Colors.grey, size: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text("TO (Destination Station)", style: TextStyle(color: Colors.grey, fontSize: 7, fontWeight: FontWeight.bold)),
                            Text(booking.bookedDestination ?? booking.train.destination, style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                            Text("Scheduled Arrival: ${booking.train.arrivalTime}", style: const TextStyle(color: Colors.black54, fontSize: 8)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Passenger Manifest
                const Text("PASSENGER DETAILS", style: TextStyle(color: Colors.black87, fontSize: 8, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Table(
                  border: TableBorder.all(color: Colors.grey[300]!, width: 0.8),
                  columnWidths: const {
                    0: FractionColumnWidth(0.08),
                    1: FractionColumnWidth(0.42),
                    2: FractionColumnWidth(0.15),
                    3: FractionColumnWidth(0.35),
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: Colors.grey[200]),
                      children: const [
                        Padding(padding: EdgeInsets.all(3.0), child: Text("S.No.", style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: Colors.black))),
                        Padding(padding: EdgeInsets.all(3.0), child: Text("Name", style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: Colors.black))),
                        Padding(padding: EdgeInsets.all(3.0), child: Text("Age/Sex", style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: Colors.black))),
                        Padding(padding: EdgeInsets.all(3.0), child: Text("Coach / Berth", style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: Colors.black))),
                      ],
                    ),
                    ...List.generate(booking.passengers.length, (idx) {
                      final p = booking.passengers[idx];
                      final String seatInfo = !isConfirmed 
                          ? "CANCELLED" 
                          : isGeneral 
                              ? "GEN / UNRESERVED" 
                              : "${p.coach ?? 'C4'} / Seat: ${p.seatNumber ?? '28'} / ${p.berthPreference.toUpperCase()}";
                      return TableRow(
                        children: [
                          Padding(padding: const EdgeInsets.all(3.0), child: Text("${idx + 1}", style: const TextStyle(fontSize: 8, color: Colors.black))),
                          Padding(padding: const EdgeInsets.all(3.0), child: Text(p.name, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.black))),
                          Padding(padding: const EdgeInsets.all(3.0), child: Text("${p.age}/${p.gender.substring(0,1)}", style: const TextStyle(fontSize: 8, color: Colors.black))),
                          Padding(padding: const EdgeInsets.all(3.0), child: Text(seatInfo, style: const TextStyle(fontSize: 7.5, color: Colors.black, fontWeight: FontWeight.w600))),
                        ],
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 16),

                // Fare Breakdown
                const Text("FARE BREAKDOWN", style: TextStyle(color: Colors.black87, fontSize: 8, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Table(
                  border: TableBorder.all(color: Colors.grey[200]!, width: 0.8),
                  columnWidths: const {
                    0: FractionColumnWidth(0.7),
                    1: FractionColumnWidth(0.3),
                  },
                  children: [
                    TableRow(
                      children: [
                        const Padding(padding: EdgeInsets.all(3.0), child: Text("Ticket Fare (Basic Charge)", style: TextStyle(fontSize: 7.5, color: Colors.black54))),
                        Padding(padding: const EdgeInsets.all(3.0), child: Text("₹${baseFare.toStringAsFixed(2)}", style: const TextStyle(fontSize: 8, color: Colors.black, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                      ],
                    ),
                    TableRow(
                      children: [
                        const Padding(padding: EdgeInsets.all(3.0), child: Text("IRCTC Convenience Fee", style: TextStyle(fontSize: 7.5, color: Colors.black54))),
                        const Padding(padding: EdgeInsets.all(3.0), child: Text("₹11.80", style: TextStyle(fontSize: 8, color: Colors.black, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                      ],
                    ),
                    TableRow(
                      children: [
                        const Padding(padding: EdgeInsets.all(3.0), child: Text("Travel Insurance & PG Charges", style: TextStyle(fontSize: 7.5, color: Colors.black54))),
                        const Padding(padding: EdgeInsets.all(3.0), child: Text("₹10.00", style: TextStyle(fontSize: 8, color: Colors.black, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                      ],
                    ),
                    TableRow(
                      decoration: BoxDecoration(color: Colors.grey[100]),
                      children: [
                        const Padding(padding: EdgeInsets.all(3.0), child: Text("TOTAL AMOUNT PAID", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.black))),
                        Padding(
                          padding: const EdgeInsets.all(3.0), 
                          child: Text(
                            "₹${booking.totalAmount.toStringAsFixed(2)}", 
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFC05A11)),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Digital Sign & Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        QrImageView(
                          data: "PNR:${booking.pnr}|TRAIN:${booking.train.number}|DATE:${booking.journeyDate}|STATUS:${booking.status}",
                          version: QrVersions.auto,
                          size: 55.0,
                        ),
                        const SizedBox(height: 4),
                        const Text("Scan to Verify", style: TextStyle(fontSize: 6, color: Colors.grey)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          "Digitally Signed by IRCTC",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 7,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Icon(Icons.verified, color: Colors.green, size: 16),
                        const SizedBox(height: 4),
                        Text(
                          "Date: ${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}",
                          style: const TextStyle(fontSize: 7, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(height: 1, color: Colors.grey[300]),
                const SizedBox(height: 6),
                const Text(
                  "Note: This is a system-generated secure e-ticket document. Physical copy printed from this PDF is fully valid under Indian Railways rules.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 6, height: 1.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WhatsAppShareDialog extends StatefulWidget {
  final Booking booking;
  const _WhatsAppShareDialog({required this.booking});

  @override
  State<_WhatsAppShareDialog> createState() => _WhatsAppShareDialogState();
}

class _WhatsAppShareDialogState extends State<_WhatsAppShareDialog> {
  late TextEditingController _phoneController;
  bool _isSending = false;
  bool _isSent = false;

  @override
  void initState() {
    super.initState();
    final userMobile = AuthService().userMobile;
    _phoneController = TextEditingController(text: userMobile.isNotEmpty ? userMobile : "9876543210");
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _shareToWhatsApp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a valid 10-digit WhatsApp number."),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    await Future.delayed(const Duration(milliseconds: 1800));

    if (mounted) {
      setState(() {
        _isSending = false;
        _isSent = true;
      });
    }

    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Ticket shared successfully to +91 $phone on WhatsApp!"),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String messageText = _generateWhatsAppMessage(widget.booking);

    return Dialog(
      backgroundColor: AppTheme.cardNavy,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFF25D366),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.share, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      "SHARE TO WHATSAPP",
                      style: TextStyle(
                        color: AppTheme.goldAccent,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "WhatsApp Mobile Number",
                    hintText: "Enter 10-digit mobile number",
                    prefixText: "+91 ",
                    prefixStyle: TextStyle(color: AppTheme.goldAccent, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 18),

                const Text(
                  "MESSAGE PAYLOAD PREVIEW",
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),

                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F2C34),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[800]!),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFF005C4B),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10),
                            topRight: Radius.circular(0),
                            bottomLeft: Radius.circular(10),
                            bottomRight: Radius.circular(10),
                          ),
                        ),
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              messageText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                height: 1.4,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}",
                                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 8),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.done_all, color: Color(0xFF53BDEB), size: 12),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.textMuted,
                          side: const BorderSide(color: AppTheme.primaryLightNavy),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text("CANCEL", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _shareToWhatsApp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text("SHARE NOW", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_isSending)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.75),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      CircularProgressIndicator(color: Color(0xFF25D366)),
                      SizedBox(height: 16),
                      Text(
                        "Connecting with WhatsApp API...",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      SizedBox(height: 6),
                      Text(
                        "Sending secure ticket payload...",
                        style: TextStyle(color: Colors.white60, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (_isSent)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.85),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.check_circle_rounded, color: Color(0xFF25D366), size: 64),
                      SizedBox(height: 16),
                      Text(
                        "Ticket Sent Successfully!",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      SizedBox(height: 6),
                      Text(
                        "Encrypted message delivered to recipient.",
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

String _generateWhatsAppMessage(Booking booking) {
  final srcName = booking.bookedSource ?? booking.train.source;
  final destName = booking.bookedDestination ?? booking.train.destination;
  final passengersList = booking.passengers.asMap().entries.map((entry) {
    final idx = entry.key + 1;
    final p = entry.value;
    final seatInfo = booking.status == "CANCELLED"
        ? "CANCELLED"
        : (booking.train.classes.contains("GEN") || p.coach == "GEN")
            ? "GEN / UNRESERVED"
            : "${p.coach ?? 'C4'}, Seat ${p.seatNumber ?? '28'} (${p.berthPreference.toUpperCase()})";
    return "$idx. ${p.name} ($seatInfo)";
  }).join("\n");

  return """🎫 *IRCTC DIGITAL TICKET CONFIRMATION*
----------------------------------------
*PNR:* ${booking.pnr}
*Train:* ${booking.train.number} / ${booking.train.name}
*Route:* $srcName ➔ $destName
*Date:* ${booking.journeyDate}
*Class:* ${booking.train.classes.contains("GEN") ? "General (2S/GEN)" : "Chair Car (CC)"}
*Status:* ${booking.status}
*Passengers:*
$passengersList
----------------------------------------
Have a safe and happy journey! 🚂✨""";
}
