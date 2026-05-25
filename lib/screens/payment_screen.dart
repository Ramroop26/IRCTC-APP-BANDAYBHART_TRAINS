import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/wallet_service.dart';
import '../services/booking_service.dart';
import '../models/train.dart';
import '../models/passenger.dart';
import '../theme.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> with SingleTickerProviderStateMixin {
  final WalletService _walletService = WalletService();
  final BookingService _bookingService = BookingService();

  int _selectedMethod = 0; // 0: eWallet, 1: UPI, 2: Cards
  bool _isProcessing = false;
  String _processingStep = "";
  double _processingProgress = 0.0;
  
  // Card Inputs
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardFormKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  void _executePayment(Train train, String date, List<Passenger> passengers, String travelClass, double amount, String? bookedSource, String? bookedDestination) async {
    setState(() {
      _isProcessing = true;
      _processingProgress = 0.1;
      _processingStep = "Initiating Secure Connection...";
    });

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() {
      _processingProgress = 0.4;
      _processingStep = "Verifying Transaction Details...";
    });
    
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() {
      _processingProgress = 0.8;
      _processingStep = "Awaiting Bank Settlement...";
    });

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() {
      _processingProgress = 0.95;
      _processingStep = "Processing Booking in Database...";
    });

    // Create the booking in DB (asynchronous HTTP call)
    final booking = await _bookingService.createBooking(
      train: train,
      journeyDate: date,
      passengers: passengers,
      travelClass: travelClass,
      totalAmount: amount,
      paymentMode: _selectedMethod == 0
          ? "IRCTC eWallet"
          : _selectedMethod == 1
              ? "UPI Gateway"
              : "Credit Card",
      bookedSource: bookedSource,
      bookedDestination: bookedDestination,
    );

    if (!mounted) return;

    if (booking != null) {
      setState(() {
        _processingProgress = 1.0;
        _processingStep = "Booking Confirmed!";
      });

      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      // Pop payment & booking details, and route to ticket detail
      Navigator.popUntil(context, ModalRoute.withName('/dashboard'));
      Navigator.pushNamed(
        context,
        '/ticket_detail',
        arguments: booking.pnr,
      );
    } else {
      setState(() {
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Booking failed! Please check your network or wallet balance."),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  void _showOtpDialog(Train train, String date, List<Passenger> passengers, String travelClass, double amount, String? bookedSource, String? bookedDestination) {
    final TextEditingController otpController = TextEditingController();
    const String correctOtp = "482912";
    String localError = "";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.cardNavy,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: AppTheme.goldAccent.withOpacity(0.4)),
              ),
              title: Row(
                children: const [
                  Icon(Icons.security_rounded, color: AppTheme.goldAccent, size: 24),
                  SizedBox(width: 8),
                  Text(
                    "BANK VERIFICATION",
                    style: TextStyle(color: AppTheme.textWhite, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryDarkNavy,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.goldAccent.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "SIMULATED BANK SMS:",
                          style: TextStyle(color: AppTheme.goldAccent, fontSize: 8, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "OTP for your transaction of ₹${amount.toStringAsFixed(2)} is 482912. Valid for 10 mins.",
                          style: const TextStyle(color: AppTheme.textWhite, fontSize: 10, fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Please enter the 6-digit OTP sent to your registered mobile number.",
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: otpController,
                    style: const TextStyle(color: AppTheme.textWhite, fontFamily: 'monospace', fontSize: 18, letterSpacing: 8),
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: "000000",
                      hintStyle: TextStyle(color: AppTheme.textMuted.withOpacity(0.5), letterSpacing: 8),
                      counterText: "",
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onChanged: (_) {
                      if (localError.isNotEmpty) {
                        setDialogState(() {
                          localError = "";
                        });
                      }
                    },
                  ),
                  if (localError.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      localError,
                      style: const TextStyle(color: AppTheme.errorRed, fontSize: 11, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ]
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("CANCEL", style: TextStyle(color: AppTheme.textMuted)),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (otpController.text.trim() == correctOtp) {
                      Navigator.pop(context);
                      _executePayment(train, date, passengers, travelClass, amount, bookedSource, bookedDestination);
                    } else {
                      setDialogState(() {
                        localError = "INVALID OTP. PLEASE ENTER 482912";
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.goldAccent,
                    foregroundColor: AppTheme.primaryNavy,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text("VERIFY & PAY", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _processPayment(Train train, String date, List<Passenger> passengers, String travelClass, double amount, String? bookedSource, String? bookedDestination) {
    if (_selectedMethod == 0 && _walletService.balance < amount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Insufficient eWallet balance. Please top up!"),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    if (_selectedMethod == 2) {
      if (!_cardFormKey.currentState!.validate()) {
        return;
      }
      _showOtpDialog(train, date, passengers, travelClass, amount, bookedSource, bookedDestination);
      return;
    }

    _executePayment(train, date, passengers, travelClass, amount, bookedSource, bookedDestination);
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final Train train = args['train'];
    final String travelClass = args['travelClass'];
    final String date = args['date'];
    final List<Passenger> passengers = args['passengers'];
    final double amount = args['amount'];
    final String? bookedSource = args['bookedSource'];
    final String? bookedDestination = args['bookedDestination'];

    final walletSufficient = _walletService.balance >= amount;

    return Scaffold(
      appBar: AppBar(title: const Text("PAYMENT GATEWAY")),
      body: Stack(
        children: [
          Container(
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
                  // Amount banner
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.cardNavy,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.goldAccent.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        const Text("AMOUNT TO PAY", style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                        const SizedBox(height: 6),
                        Text(
                          "₹${amount.toStringAsFixed(2)}",
                          style: const TextStyle(color: AppTheme.goldAccent, fontSize: 32, fontWeight: FontWeight.bold),
                        ),
                        const Divider(color: AppTheme.primaryLightNavy, height: 24),
                        Text(
                          "Booking Train ${train.number} | ${passengers.length} Passenger(s)",
                          style: const TextStyle(color: AppTheme.textWhite, fontSize: 12),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Text("SELECT PAYMENT METHOD", style: TextStyle(color: AppTheme.goldAccent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  const SizedBox(height: 12),

                  // Option 1: eWallet
                  _buildPaymentOption(
                    0,
                    "IRCTC eWallet",
                    Icons.account_balance_wallet_rounded,
                    subtitle: "Available Balance: ₹${_walletService.balance.toStringAsFixed(2)}",
                    isEnabled: walletSufficient,
                    warning: walletSufficient ? null : "Insufficient Balance",
                  ),

                  // Option 2: UPI
                  _buildPaymentOption(
                    1,
                    "BHIM UPI / GooglePay / PhonePe",
                    Icons.qr_code_2_rounded,
                    subtitle: "Instant settlement via virtual payment address",
                  ),

                  // Option 3: Cards
                  _buildPaymentOption(
                    2,
                    "Credit / Debit / ATM Card",
                    Icons.credit_card_rounded,
                    subtitle: "Visa, MasterCard, RuPay, Maestro",
                  ),

                  const SizedBox(height: 20),

                  // Dynamic payment details card based on selection
                  if (_selectedMethod == 2) _buildCardForm(),
                  if (_selectedMethod == 1) _buildUpiInfo(amount),
                  if (_selectedMethod == 0) _buildWalletInfo(amount),

                  const SizedBox(height: 32),

                  ElevatedButton(
                    onPressed: () => _processPayment(train, date, passengers, travelClass, amount, bookedSource, bookedDestination),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.security, size: 18),
                        const SizedBox(width: 8),
                        Text("SECURELY PAY ₹${amount.toStringAsFixed(2)}"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Secure Processing Overlay
          if (_isProcessing) _buildProcessingOverlay(),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(int methodIndex, String title, IconData icon, {String? subtitle, bool isEnabled = true, String? warning}) {
    final isSelected = _selectedMethod == methodIndex;
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: Card(
        color: isSelected ? AppTheme.goldAccent.withOpacity(0.08) : AppTheme.cardNavy,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? AppTheme.goldAccent : AppTheme.primaryLightNavy,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: isEnabled ? () => setState(() => _selectedMethod = methodIndex) : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(icon, color: isSelected ? AppTheme.goldAccent : AppTheme.textMuted, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textWhite),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                      ],
                      if (warning != null) ...[
                        const SizedBox(height: 2),
                        Text(warning, style: const TextStyle(fontSize: 11, color: AppTheme.errorRed, fontWeight: FontWeight.bold)),
                      ],
                    ],
                  ),
                ),
                Radio<int>(
                  value: methodIndex,
                  groupValue: _selectedMethod,
                  activeColor: AppTheme.goldAccent,
                  onChanged: isEnabled ? (val) {
                    if (val != null) setState(() => _selectedMethod = val);
                  } : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardNavy,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryLightNavy),
      ),
      child: Form(
        key: _cardFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("ENTER CARD DETAILS", style: TextStyle(color: AppTheme.goldAccent, fontSize: 10, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cardNumberController,
              style: const TextStyle(color: AppTheme.textWhite),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Card Number",
                hintText: "1234 5678 9876 5432",
              ),
              validator: (val) {
                if (val == null || val.length < 12) return "Enter valid card number";
                return null;
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _expiryController,
                    style: const TextStyle(color: AppTheme.textWhite),
                    keyboardType: TextInputType.datetime,
                    decoration: const InputDecoration(
                      labelText: "Expiry Date",
                      hintText: "MM/YY",
                    ),
                    validator: (val) {
                      if (val == null || !val.contains('/')) return "MM/YY";
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _cvvController,
                    style: const TextStyle(color: AppTheme.textWhite),
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "CVV",
                      hintText: "123",
                    ),
                    validator: (val) {
                      if (val == null || val.length < 3) return "3 digits";
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpiInfo(double amount) {
    final String upiUrl = "upi://pay?pa=irctc@paytm&pn=IRCTC&am=${amount.toStringAsFixed(2)}&cu=INR";
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardNavy,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryLightNavy),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: QrImageView(
              data: upiUrl,
              version: QrVersions.auto,
              size: 160.0,
              gapless: false,
              errorStateBuilder: (cxt, err) {
                return const Center(
                  child: Text(
                    "Error generating QR",
                    style: TextStyle(color: Colors.black),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Unified Payments Interface (UPI)",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textWhite),
          ),
          const SizedBox(height: 6),
          Text(
            "Scan the QR code above with any UPI app (Google Pay, PhonePe, Paytm, BHIM) to pay ₹${amount.toStringAsFixed(2)} instantly.",
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletInfo(double amount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardNavy,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryLightNavy),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("IRCTC eWALLET QUICK CHECKOUT", style: TextStyle(color: AppTheme.goldAccent, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Available balance", style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
              Text("₹${_walletService.balance.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Deduction amount", style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
              Text("-₹${amount.toStringAsFixed(2)}", style: const TextStyle(color: AppTheme.errorRed, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const Divider(color: AppTheme.primaryLightNavy),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Remaining balance", style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
              Text("₹${(_walletService.balance - amount).toStringAsFixed(2)}", style: const TextStyle(color: AppTheme.successGreen, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.85),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.cardNavy,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.goldAccent.withOpacity(0.3)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.goldAccent),
                    strokeWidth: 4,
                  ),
                ),
                const SizedBox(height: 24),
                const Icon(Icons.lock_rounded, color: AppTheme.goldAccent, size: 28),
                const SizedBox(height: 8),
                Text(
                  _processingStep,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textWhite, fontSize: 15),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _processingProgress,
                    backgroundColor: AppTheme.primaryLightNavy,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.goldAccent),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Do not press back or close the app",
                  style: TextStyle(color: AppTheme.textMuted.withOpacity(0.7), fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
