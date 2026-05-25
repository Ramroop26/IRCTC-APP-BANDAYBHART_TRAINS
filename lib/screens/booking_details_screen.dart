import 'dart:math';
import 'package:flutter/material.dart';
import '../models/train.dart';
import '../models/passenger.dart';
import '../theme.dart';

class BookingDetailsScreen extends StatefulWidget {
  const BookingDetailsScreen({super.key});

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  final List<Passenger> _passengers = [];
  bool _includeMeals = false;
  bool _includeInsurance = false;
  bool _autoUpgradation = true;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _captchaController = TextEditingController();
  String _captchaText = "";
  String _selectedGender = "Male";
  String _selectedBerth = "No Preference";

  final List<String> _genders = ["Male", "Female", "Other"];
  final List<String> _berthPreferences = [
    "No Preference",
    "Lower Berth",
    "Middle Berth",
    "Upper Berth",
    "Side Lower",
    "Side Upper",
    "Window Seat"
  ];

  @override
  void initState() {
    super.initState();
    _generateCaptcha();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _captchaController.dispose();
    super.dispose();
  }

  void _generateCaptcha() {
    final rand = Random();
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    setState(() {
      _captchaText = List.generate(5, (_) => chars[rand.nextInt(chars.length)]).join();
      _captchaController.clear();
    });
  }

  void _addPassengerDialog() {
    _nameController.clear();
    _ageController.clear();
    _selectedGender = "Male";
    _selectedBerth = "No Preference";

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.cardNavy,
              title: const Text("Add Passenger", style: TextStyle(color: AppTheme.goldAccent)),
              content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(color: AppTheme.textWhite),
                        decoration: const InputDecoration(
                          labelText: "Full Name",
                          hintText: "Enter passenger name",
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return "Please enter name";
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _ageController,
                        style: const TextStyle(color: AppTheme.textWhite),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Age",
                          hintText: "Enter age",
                        ),
                        validator: (value) {
                          if (value == null || int.tryParse(value) == null) return "Enter valid age";
                          if (int.parse(value) <= 0) return "Age must be greater than 0";
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedGender,
                        dropdownColor: AppTheme.cardNavy,
                        decoration: const InputDecoration(labelText: "Gender"),
                        items: _genders.map((g) {
                          return DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(color: AppTheme.textWhite)));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setDialogState(() => _selectedGender = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedBerth,
                        dropdownColor: AppTheme.cardNavy,
                        decoration: const InputDecoration(labelText: "Berth Preference"),
                        items: _berthPreferences.map((b) {
                          return DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(color: AppTheme.textWhite)));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setDialogState(() => _selectedBerth = val);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("CANCEL", style: TextStyle(color: AppTheme.textMuted)),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      setState(() {
                        _passengers.add(
                          Passenger(
                            name: _nameController.text.trim(),
                            age: int.parse(_ageController.text.trim()),
                            gender: _selectedGender,
                            berthPreference: _selectedBerth,
                          ),
                        );
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("ADD"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _removePassenger(int index) {
    setState(() {
      _passengers.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final Train train = args['train'];
    final String travelClass = args['travelClass'];
    final String journeyDate = args['date'];
    final double basePrice = args['price'];
    final String? bookedSource = args['bookedSource'];
    final String? bookedDestination = args['bookedDestination'];

    // Calculations
    final double ticketCost = basePrice * _passengers.length;
    final double mealCost = _includeMeals ? (150.0 * _passengers.length) : 0.0;
    final double insuranceCost = _includeInsurance ? (35.0 * _passengers.length) : 0.0;
    final double convenienceFee = _passengers.isNotEmpty ? 17.70 : 0.0; // GST included fee
    final double totalAmount = ticketCost + mealCost + insuranceCost + convenienceFee;

    return Scaffold(
      appBar: AppBar(title: const Text("PASSENGER DETAILS")),
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
              // Train Summary
              _buildTrainSummaryCard(train, travelClass, journeyDate, bookedSource, bookedDestination),
              const SizedBox(height: 20),

              // Passengers Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "PASSENGERS (${_passengers.length})",
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: AppTheme.goldAccent),
                  ),
                  TextButton.icon(
                    onPressed: _addPassengerDialog,
                    icon: const Icon(Icons.add_rounded, color: AppTheme.goldAccent, size: 18),
                    label: const Text("ADD PASSENGER", style: TextStyle(color: AppTheme.goldAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (_passengers.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  decoration: BoxDecoration(
                    color: AppTheme.cardNavy.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primaryLightNavy.withOpacity(0.5)),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.people_outline_rounded, size: 40, color: AppTheme.textMuted.withOpacity(0.5)),
                      const SizedBox(height: 8),
                      const Text("No Passengers Added Yet", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text("Click ADD PASSENGER to continue.", style: TextStyle(color: AppTheme.textMuted.withOpacity(0.8), fontSize: 11)),
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _passengers.length,
                  itemBuilder: (context, index) {
                    final p = _passengers[index];
                    return Card(
                      color: AppTheme.cardNavy,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppTheme.primaryLightNavy),
                      ),
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLightNavy,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.person, color: AppTheme.goldAccent),
                        ),
                        title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textWhite)),
                        subtitle: Text("${p.gender} | Age: ${p.age} | ${p.berthPreference}", style: const TextStyle(fontSize: 12)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppTheme.errorRed),
                          onPressed: () => _removePassenger(index),
                        ),
                      ),
                    );
                  },
                ),

              const SizedBox(height: 24),

              // Additional preferences card
              _buildPreferencesCard(),
              const SizedBox(height: 24),

              // Checkout price details card
              _buildPriceDetailsCard(ticketCost, mealCost, insuranceCost, convenienceFee, totalAmount),
              const SizedBox(height: 24),

              if (_passengers.isNotEmpty) ...[
                _buildCaptchaCard(),
                const SizedBox(height: 24),
              ],

              ElevatedButton(
                onPressed: _passengers.isEmpty
                    ? null
                    : () {
                        if (_captchaController.text.trim().toUpperCase() != _captchaText) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Invalid Captcha code! Please solve again."),
                              backgroundColor: AppTheme.errorRed,
                            ),
                          );
                          _generateCaptcha();
                          return;
                        }
                        Navigator.pushNamed(
                          context,
                          '/payment',
                          arguments: {
                            'train': train,
                            'travelClass': travelClass,
                            'date': journeyDate,
                            'passengers': _passengers,
                            'amount': totalAmount,
                            'bookedSource': bookedSource,
                            'bookedDestination': bookedDestination,
                          },
                        );
                      },
                child: const Text("PROCEED TO PAYMENT"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrainSummaryCard(Train train, String travelClass, String date, String? bookedSource, String? bookedDestination) {
    final srcName = bookedSource ?? train.source;
    final destName = bookedDestination ?? train.destination;
    return Container(
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
              Text(
                train.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textWhite),
              ),
              Text(
                travelClass,
                style: const TextStyle(color: AppTheme.goldAccent, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "Train: #${train.number} | Date: $date",
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
          const Divider(color: AppTheme.primaryLightNavy, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(srcName.split(' ').first, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const Icon(Icons.arrow_right_alt, color: AppTheme.goldAccent),
              Text(destName.split(' ').first, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardNavy,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryLightNavy),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("TRAVEL OPTIONS & PREFERENCES", style: TextStyle(color: AppTheme.goldAccent, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
          const SizedBox(height: 12),
          
          // Meals
          CheckboxListTile(
            title: const Text("Include Catering Services", style: TextStyle(fontSize: 14, color: AppTheme.textWhite)),
            subtitle: const Text("Veg/Non-Veg onboard meals (+₹150/person)", style: TextStyle(fontSize: 11)),
            value: _includeMeals,
            activeColor: AppTheme.goldAccent,
            checkColor: AppTheme.primaryNavy,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) {
              if (val != null) setState(() => _includeMeals = val);
            },
          ),
          
          // Insurance
          CheckboxListTile(
            title: const Text("Travel Insurance", style: TextStyle(fontSize: 14, color: AppTheme.textWhite)),
            subtitle: const Text("Compulsory coverage up to ₹10 Lakhs (+₹35/person)", style: TextStyle(fontSize: 11)),
            value: _includeInsurance,
            activeColor: AppTheme.goldAccent,
            checkColor: AppTheme.primaryNavy,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) {
              if (val != null) setState(() => _includeInsurance = val);
            },
          ),

          // Auto upgrade
          SwitchListTile(
            title: const Text("Auto-upgradation", style: TextStyle(fontSize: 14, color: AppTheme.textWhite)),
            subtitle: const Text("Upgrade to higher class for free if seats available", style: TextStyle(fontSize: 11)),
            value: _autoUpgradation,
            activeThumbColor: AppTheme.goldAccent,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) {
              setState(() => _autoUpgradation = val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPriceDetailsCard(double ticket, double meal, double insurance, double fee, double total) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardNavy,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryLightNavy),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("FARE BREAKUP", style: TextStyle(color: AppTheme.goldAccent, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
          const SizedBox(height: 12),
          _buildFareRow("Ticket Base Fare (${_passengers.length} passengers)", ticket),
          if (_includeMeals) _buildFareRow("Catering Charges", meal),
          if (_includeInsurance) _buildFareRow("Travel Insurance", insurance),
          if (_passengers.isNotEmpty) _buildFareRow("IRCTC Convenience Fee (incl. GST)", fee),
          const Divider(color: AppTheme.primaryLightNavy, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total Amount Payable", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textWhite)),
              Text("₹${total.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.goldAccent)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFareRow(String description, double price) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(description, style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
          Text("₹${price.toStringAsFixed(2)}", style: const TextStyle(fontSize: 13, color: AppTheme.textWhite)),
        ],
      ),
    );
  }

  Widget _buildCaptchaCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardNavy,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryLightNavy),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text("CAPTCHA SERVICE VERIFICATION", style: TextStyle(color: AppTheme.goldAccent, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
          const Divider(color: AppTheme.primaryLightNavy, height: 20),
          Row(
            children: [
              // Stylized Captcha text display box
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.black54, AppTheme.primaryDarkNavy],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.primaryLightNavy),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Noise grid/lines
                        Positioned.fill(
                          child: CustomPaint(
                            painter: CaptchaNoisePainter(),
                          ),
                        ),
                        // Captcha text
                        Text(
                          _captchaText,
                          style: const TextStyle(
                            color: AppTheme.goldAccent,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                            letterSpacing: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: AppTheme.goldAccent, size: 28),
                tooltip: "Get New Captcha",
                onPressed: _generateCaptcha,
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _captchaController,
            style: const TextStyle(color: AppTheme.textWhite),
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: "Solve Captcha",
              hintText: "Enter the security code shown above",
            ),
          ),
        ],
      ),
    );
  }
}

class CaptchaNoisePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.goldAccent.withOpacity(0.12)
      ..strokeWidth = 1.5;
    
    final rand = Random();
    // Draw some random lines
    for (int i = 0; i < 6; i++) {
      canvas.drawLine(
        Offset(rand.nextDouble() * size.width, rand.nextDouble() * size.height),
        Offset(rand.nextDouble() * size.width, rand.nextDouble() * size.height),
        paint,
      );
    }
    // Draw some random circles
    for (int i = 0; i < 15; i++) {
      canvas.drawCircle(
        Offset(rand.nextDouble() * size.width, rand.nextDouble() * size.height),
        rand.nextDouble() * 5 + 1,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
