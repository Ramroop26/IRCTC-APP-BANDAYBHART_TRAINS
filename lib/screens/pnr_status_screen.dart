import 'package:flutter/material.dart';
import '../services/booking_service.dart';
import '../models/booking.dart';
import '../theme.dart';

class PnrStatusScreen extends StatefulWidget {
  const PnrStatusScreen({super.key});

  @override
  State<PnrStatusScreen> createState() => _PnrStatusScreenState();
}

class _PnrStatusScreenState extends State<PnrStatusScreen> {
  final BookingService _bookingService = BookingService();
  final _pnrController = TextEditingController();
  Booking? _bookingResult;
  bool _hasSearched = false;
  bool _isLoading = false;

  void _checkPnr() {
    final pnr = _pnrController.text.trim();
    if (pnr.isEmpty) return;

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    Future.delayed(const Duration(milliseconds: 700), () {
      setState(() {
        _bookingResult = _bookingService.findByPnr(pnr);
        _isLoading = false;
      });
    });
  }

  @override
  void dispose() {
    _pnrController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("PNR INQUIRY")),
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
              // Search Input Card
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
                      controller: _pnrController,
                      style: const TextStyle(color: AppTheme.textWhite),
                      keyboardType: TextInputType.number,
                      maxLength: 10,
                      decoration: const InputDecoration(
                        labelText: "10-Digit PNR Number",
                        hintText: "Enter PNR (e.g. 4238910476)",
                        prefixIcon: Icon(Icons.confirmation_num_rounded, color: AppTheme.goldAccent),
                        counterText: "",
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _checkPnr,
                      child: const Text("GET PNR STATUS"),
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
              else if (_hasSearched)
                _bookingResult == null
                    ? _buildNoResultCard()
                    : _buildPnrDetails(_bookingResult!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoResultCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardNavy,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryLightNavy),
      ),
      child: const Column(
        children: [
          Icon(Icons.report_problem_outlined, size: 48, color: AppTheme.warningOrange),
          SizedBox(height: 12),
          Text(
            "PNR Status Not Found",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 4),
          Text(
            "Please check the 10-digit number. For demo, try booking a ticket first, then search its PNR.",
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPnrDetails(Booking booking) {
    final bool isConfirmed = booking.status == "CONFIRMED";
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Train & PNR Header Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardNavy,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primaryLightNavy),
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
                        "PNR: ${booking.pnr}",
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.goldAccent, fontSize: 18, letterSpacing: 2),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        booking.train.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textWhite, fontSize: 14),
                      ),
                      Text(
                        "Train No: #${booking.train.number} | Date: ${booking.journeyDate}",
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isConfirmed ? AppTheme.successGreen.withOpacity(0.15) : AppTheme.errorRed.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      booking.status,
                      style: TextStyle(color: isConfirmed ? AppTheme.successGreen : AppTheme.errorRed, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const Divider(color: AppTheme.primaryLightNavy, height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Chart Status:", style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                  Text(
                    isConfirmed ? "CHART PREPARED" : "NOT APPLICABLE",
                    style: TextStyle(color: isConfirmed ? AppTheme.successGreen : AppTheme.textMuted, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Passenger Status Table
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardNavy,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primaryLightNavy),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("PASSENGER CURRENT STATUS", style: TextStyle(color: AppTheme.goldAccent, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
              const SizedBox(height: 12),
              
              // Table Header
              const Row(
                children: [
                  Expanded(flex: 3, child: Text("# Passenger Name", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted))),
                  Expanded(flex: 2, child: Text("Booking Status", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted))),
                  Expanded(flex: 2, child: Text("Current Status", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted), textAlign: TextAlign.right)),
                ],
              ),
              const Divider(color: AppTheme.primaryLightNavy),
              
              // Table Row
              ...List.generate(booking.passengers.length, (index) {
                final p = booking.passengers[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          "${index + 1}. ${p.name}",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textWhite),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          isConfirmed ? "${p.coach ?? 'C4'}/${p.seatNumber ?? '28'}" : "CANCELLED",
                          style: const TextStyle(fontSize: 12, color: AppTheme.textWhite),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          isConfirmed ? "CNF" : "REFUNDED",
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: isConfirmed ? AppTheme.successGreen : AppTheme.errorRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Workflow Progress
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardNavy,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primaryLightNavy),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("BOOKING FLOW PROGRESS", style: TextStyle(color: AppTheme.goldAccent, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
              const SizedBox(height: 24),
              _buildProgressSteps(booking),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSteps(Booking booking) {
    final bool isConfirmed = booking.status == "CONFIRMED";
    return Row(
      children: [
        _buildStep(true, "Booked", "Success"),
        _buildConnector(true),
        _buildStep(true, "Paid", booking.paymentMode),
        _buildConnector(isConfirmed),
        _buildStep(isConfirmed, "Chart Prep", isConfirmed ? "CNF" : "N/A"),
        _buildConnector(isConfirmed),
        _buildStep(isConfirmed, "Depart", isConfirmed ? "Journey Pending" : "N/A"),
      ],
    );
  }

  Widget _buildStep(bool isActive, String label, String desc) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? AppTheme.goldAccent : AppTheme.primaryLightNavy,
              border: Border.all(color: AppTheme.primaryNavy, width: 2),
            ),
            child: Icon(
              isActive ? Icons.check : Icons.circle,
              size: 12,
              color: isActive ? AppTheme.primaryNavy : AppTheme.textMuted.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isActive ? AppTheme.textWhite : AppTheme.textMuted,
            ),
          ),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 8,
              color: AppTheme.textMuted.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnector(bool isActive) {
    return Container(
      width: 20,
      height: 2,
      color: isActive ? AppTheme.goldAccent : AppTheme.primaryLightNavy,
      margin: const EdgeInsets.only(bottom: 24),
    );
  }
}
