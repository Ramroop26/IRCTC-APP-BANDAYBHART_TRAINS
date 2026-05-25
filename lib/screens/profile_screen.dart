import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final _aadhaarController = TextEditingController();
  final _otpController = TextEditingController();

  late String _name;
  late String _email;
  late String _phone;
  String _foodPreference = "Veg";
  String _berthPreference = "Window Seat";
  late bool _isAadhaarLinked;
  bool _isVerifyingOtp = false;

  @override
  void initState() {
    super.initState();
    _name = _authService.userName.isNotEmpty ? _authService.userName : "Passenger";
    _email = _authService.userEmail.isNotEmpty ? _authService.userEmail : "not-logged-in@irctc.co.in";
    _phone = _authService.userMobile.isNotEmpty ? _authService.userMobile : "";
    _isAadhaarLinked = _authService.userAadhaar.isNotEmpty;
  }

  final List<String> _foodOptions = ["Veg", "Non-Veg", "Jain Food", "No Preference"];
  final List<String> _berthOptions = ["No Preference", "Lower Berth", "Middle Berth", "Upper Berth", "Side Lower", "Side Upper", "Window Seat"];

  @override
  void dispose() {
    _aadhaarController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _editPhoneDialog() {
    final controller = TextEditingController(text: _phone);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardNavy,
          title: const Text("Edit Phone Number", style: TextStyle(color: AppTheme.textWhite)),
          content: TextFormField(
            controller: controller,
            style: const TextStyle(color: AppTheme.textWhite),
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: "Phone Number",
              hintText: "+91 XXXXX XXXXX",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCEL", style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              onPressed: () {
                final phoneVal = controller.text.trim();
                setState(() {
                  _phone = phoneVal;
                });
                _authService.updateMobile(phoneVal);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Phone number updated successfully!"), backgroundColor: AppTheme.successGreen),
                );
              },
              child: const Text("SAVE"),
            ),
          ],
        );
      },
    );
  }

  void _verifyAndLinkAadhaar() {
    final aadhaar = _aadhaarController.text.trim();
    if (aadhaar.length < 12) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Aadhaar Number must be 12 digits"), backgroundColor: AppTheme.errorRed),
      );
      return;
    }

    if (_phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add a phone number before linking Aadhaar"), backgroundColor: AppTheme.errorRed),
      );
      return;
    }



    // Send OTP popup
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: AppTheme.cardNavy,
              title: const Row(
                children: [
                  Icon(Icons.message_rounded, color: AppTheme.goldAccent),
                  SizedBox(width: 8),
                  Text("Enter OTP"),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "A secure 6-digit Aadhaar OTP has been sent to $_phone. Enter the code below.",
                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 16),
                  if (_isVerifyingOtp) ...[
                    const CircularProgressIndicator(color: AppTheme.goldAccent),
                  ] else ...[
                    TextFormField(
                      controller: _otpController,
                      style: const TextStyle(color: AppTheme.textWhite, letterSpacing: 6, fontSize: 18),
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        hintText: "123456",
                        counterText: "",
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _otpController.clear();
                    Navigator.pop(context);
                  },
                  child: const Text("CANCEL", style: TextStyle(color: AppTheme.textMuted)),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_otpController.text.trim() == "123456" || _otpController.text.trim().length == 6) {
                      setModalState(() {
                        _isVerifyingOtp = true;
                      });

                      Future.delayed(const Duration(milliseconds: 1200), () {
                        if (!mounted) return;
                        setState(() {
                          _isAadhaarLinked = true;
                        });
                        _authService.updateAadhaar(aadhaar);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Aadhaar successfully verified and linked!"), backgroundColor: AppTheme.successGreen),
                        );
                      });
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Invalid OTP code. Enter 123456"), backgroundColor: AppTheme.errorRed),
                      );
                    }
                  },
                  child: const Text("VERIFY"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("USER PROFILE & PREFERENCES")),
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
              // User header card
              _buildProfileHeaderCard(),
              const SizedBox(height: 20),

              // Aadhaar verification card
              _buildAadhaarKycCard(),
              const SizedBox(height: 20),

              // Travel Preference card
              _buildTravelPreferencesCard(),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Preferences updated successfully!"), backgroundColor: AppTheme.successGreen),
                  );
                  Navigator.pop(context);
                },
                child: const Text("SAVE CHANGES"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardNavy,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryLightNavy),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryLightNavy,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.goldAccent, width: 1.5),
            ),
            child: const Icon(Icons.person_rounded, size: 48, color: AppTheme.goldAccent),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textWhite),
                ),
                Text(
                  _email,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _phone.isEmpty ? "No phone linked" : _phone,
                      style: TextStyle(
                        fontSize: 12,
                        color: _phone.isEmpty ? AppTheme.errorRed : AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _editPhoneDialog,
                      child: const Icon(Icons.edit_rounded, size: 14, color: AppTheme.goldAccent),
                    ),
                    if (_phone.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _phone = "";
                          });
                          _authService.updateMobile("");
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Phone number deleted"), backgroundColor: AppTheme.warningOrange),
                          );
                        },
                        child: const Icon(Icons.delete_outline_rounded, size: 14, color: AppTheme.errorRed),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAadhaarKycCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardNavy,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isAadhaarLinked ? AppTheme.successGreen.withOpacity(0.3) : AppTheme.primaryLightNavy,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "AADHAAR KYC VERIFICATION",
                style: TextStyle(color: AppTheme.goldAccent, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _isAadhaarLinked ? AppTheme.successGreen.withOpacity(0.12) : AppTheme.warningOrange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _isAadhaarLinked ? "VERIFIED ✓" : "PENDING",
                  style: TextStyle(
                    color: _isAadhaarLinked ? AppTheme.successGreen : AppTheme.warningOrange,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: AppTheme.primaryLightNavy, height: 20),
          
          if (_isAadhaarLinked) ...[
            Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppTheme.successGreen, size: 18),
                const SizedBox(width: 8),
                Text(
                  "Linked Document: ${_authService.userAadhaar.isNotEmpty ? _authService.userAadhaar : 'XXXX-XXXX-4982'}",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              "Your monthly booking limit is extended from 6 to 12 tickets.",
              style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                setState(() {
                  _isAadhaarLinked = false;
                });
              },
              child: const Text("UNLINK AADHAAR", style: TextStyle(color: AppTheme.errorRed, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ] else ...[
            const Text(
              "Link your Aadhaar card to authenticate your profile and increase your monthly booking ticket limits.",
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _aadhaarController,
              style: const TextStyle(color: AppTheme.textWhite),
              keyboardType: TextInputType.number,
              maxLength: 12,
              decoration: const InputDecoration(
                labelText: "12-Digit Aadhaar Number",
                hintText: "0000 0000 0000",
                counterText: "",
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _verifyAndLinkAadhaar,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.goldAccent,
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: const Text("LINK & VERIFY VIA OTP", style: TextStyle(fontSize: 13)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTravelPreferencesCard() {
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
          const Text(
            "JOURNEY PREFERENCES",
            style: TextStyle(color: AppTheme.goldAccent, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0),
          ),
          const Divider(color: AppTheme.primaryLightNavy, height: 20),
          
          // Food preference
          DropdownButtonFormField<String>(
            initialValue: _foodPreference,
            dropdownColor: AppTheme.cardNavy,
            decoration: const InputDecoration(labelText: "Onboard Food/Meal Choice"),
            items: _foodOptions.map((f) {
              return DropdownMenuItem(value: f, child: Text(f, style: const TextStyle(color: AppTheme.textWhite)));
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _foodPreference = val);
            },
          ),
          const SizedBox(height: 16),

          // Preferred berth
          DropdownButtonFormField<String>(
            initialValue: _berthPreference,
            dropdownColor: AppTheme.cardNavy,
            decoration: const InputDecoration(labelText: "Preferred Berth Layout"),
            items: _berthOptions.map((b) {
              return DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(color: AppTheme.textWhite)));
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _berthPreference = val);
            },
          ),
        ],
      ),
    );
  }
}
