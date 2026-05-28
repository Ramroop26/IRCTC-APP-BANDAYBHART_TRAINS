import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/biometric_scanner.dart';
import '../theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  
  // Login State
  final List<TextEditingController> _pinControllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  int _selectedTab = 0; // 0: PIN, 1: Touch ID, 2: Face ID, 3: OTP
  String _errorMessage = "";

  // OTP & Google State
  final _otpEmailController = TextEditingController();
  final _otpCodeController = TextEditingController();
  
  final _firebasePhoneController = TextEditingController();
  final _firebaseCodeController = TextEditingController();
  bool _isFirebaseOtpSent = false;
  bool _isFirebaseLoading = false;
  
  bool _isOtpSent = false;
  bool _isGoogleLoading = false;
  bool _isOtpLoading = false;

  // Registration State
  bool _isRegistering = false;
  final _regFormKey = GlobalKey<FormState>();
  final _regNameController = TextEditingController();
  final _regEmailController = TextEditingController();
  final _regPinController = TextEditingController();
  final _regAadhaarController = TextEditingController();
  final _regMobileController = TextEditingController();

  @override
  void dispose() {
    for (var controller in _pinControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _regNameController.dispose();
    _regEmailController.dispose();
    _regPinController.dispose();
    _regAadhaarController.dispose();
    _regMobileController.dispose();
    _otpEmailController.dispose();
    _otpCodeController.dispose();
    _firebasePhoneController.dispose();
    _firebaseCodeController.dispose();
    super.dispose();
  }

  void _onPinChanged(int index, String value) {
    if (value.isNotEmpty) {
      if (index < 3) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        _verifyPin();
      }
    } else {
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }
  }

  void _verifyPin() async {
    final pin = _pinControllers.map((c) => c.text).join();
    if (pin.length == 4) {
      if (!_authService.hasRegisteredUsers) {
        setState(() {
          _errorMessage = "No registered user found. Please register first.";
          for (var controller in _pinControllers) {
            controller.clear();
          }
          _focusNodes[0].requestFocus();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Security Alert: No registered account found! Please register first."),
            backgroundColor: AppTheme.errorRed,
          ),
        );
        return;
      }
      final success = await _authService.authenticatePin(pin);
      if (success) {
        _navigateToDashboard();
      } else {
        setState(() {
          _errorMessage = "Invalid PIN. Try again.";
          for (var controller in _pinControllers) {
            controller.clear();
          }
          _focusNodes[0].requestFocus();
        });
      }
    }
  }

  void _onBiometricAuthenticated() async {
    if (!_authService.hasRegisteredUsers) {
      setState(() {
        _errorMessage = "No registered user found. Please register first.";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Security Alert: No registered account found! Please register first."),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }
    
    final success = await _authService.authenticateSimulated(_selectedTab == 2);
    if (success) {
      _navigateToDashboard();
    } else {
      setState(() {
        _errorMessage = "Biometric authentication failed.";
      });
    }
  }

  void _register() async {
    if (_regFormKey.currentState!.validate()) {
      final success = await _authService.registerUser(
        _regNameController.text.trim(),
        _regEmailController.text.trim(),
        _regPinController.text.trim(),
        _regAadhaarController.text.trim(),
        _regMobileController.text.trim(),
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Account Registered Successfully! Loading Profile..."),
            backgroundColor: AppTheme.successGreen,
          ),
        );
        // Auto-open profile screen: navigate to dashboard first, then push profile
        Navigator.pushReplacementNamed(context, '/dashboard');
        Navigator.pushNamed(context, '/profile');
      } else {
        setState(() {
          _errorMessage = "Registration failed. Email might already be registered.";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Email is already registered! Please use another email."),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  void _navigateToDashboard() {
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryDarkNavy,
              AppTheme.primaryNavy,
              AppTheme.backgroundDark,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // IRCTC Logo & Train Brand
                  Hero(
                    tag: 'app_logo',
                    child: Image.asset(
                      'assets/logo.png',
                      width: 90,
                      height: 90,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "IRCTC NEXT-GEN",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                      color: AppTheme.textWhite,
                      shadows: [
                        Shadow(
                          color: AppTheme.goldAccent.withOpacity(0.5),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    "Search. Book. Travel. Simplified.",
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.goldAccent.withOpacity(0.8),
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Glassmorphic Panel
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.cardNavy.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppTheme.goldAccent.withOpacity(0.15),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Register/Login Header Text
                        Text(
                          _isRegistering ? "CREATE NEW ACCOUNT" : "SECURE USER LOGIN",
                          style: const TextStyle(
                            color: AppTheme.goldAccent,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Form body
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          switchInCurve: Curves.easeOutQuad,
                          switchOutCurve: Curves.easeInQuad,
                          transitionBuilder: (Widget child, Animation<double> animation) {
                            final inAnimation = Tween<Offset>(
                              begin: const Offset(0.3, 0.0),
                              end: Offset.zero,
                            ).animate(animation);
                            final outAnimation = Tween<Offset>(
                              begin: const Offset(-0.3, 0.0),
                              end: Offset.zero,
                            ).animate(animation);
                            return SlideTransition(
                              position: child.key == const ValueKey("register_form") 
                                  ? inAnimation 
                                  : outAnimation,
                              child: FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                            );
                          },
                          child: _isRegistering ? _buildRegisterForm() : _buildLoginForm(),
                        ),

                        if (_errorMessage.isNotEmpty && !_isRegistering && _selectedTab == 0) ...[
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage,
                            style: const TextStyle(color: AppTheme.errorRed, fontSize: 13),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Toggle Login/Register footer button
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isRegistering = !_isRegistering;
                        _errorMessage = "";
                      });
                    },
                    child: Text(
                      _isRegistering 
                          ? "ALREADY HAVE AN ACCOUNT? LOGIN" 
                          : "NEW TO IRCTC? CREATE AN ACCOUNT",
                      style: const TextStyle(
                        color: AppTheme.goldAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),

                  const SizedBox.shrink(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      key: const ValueKey("login_form"),
      children: [
        // Tab Selector
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppTheme.primaryDarkNavy,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              _buildTabItem(0, "PIN", Icons.lock_outline),
              _buildTabItem(1, "Touch", Icons.fingerprint_rounded),
              _buildTabItem(2, "Face", Icons.face_unlock_rounded),
              _buildTabItem(3, "Email OTP", Icons.email_outlined),
              _buildTabItem(4, "SMS OTP", Icons.sms_outlined),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Auth Form depending on tab
        _buildAuthBody(),

        const SizedBox(height: 32),
        const Row(
          children: [
            Expanded(child: Divider(color: AppTheme.primaryLightNavy)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text("OR", style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            Expanded(child: Divider(color: AppTheme.primaryLightNavy)),
          ],
        ),
        const SizedBox(height: 24),
        _buildGoogleLoginButton(),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return Form(
      key: _regFormKey,
      child: Column(
        key: const ValueKey("register_form"),
        children: [
          TextFormField(
            controller: _regNameController,
            style: const TextStyle(color: AppTheme.textWhite),
            decoration: const InputDecoration(
              labelText: "Full Name",
              prefixIcon: Icon(Icons.person_outline, color: AppTheme.goldAccent),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return "Enter your name";
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _regEmailController,
            style: const TextStyle(color: AppTheme.textWhite),
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: "Email Address",
              prefixIcon: Icon(Icons.email_outlined, color: AppTheme.goldAccent),
            ),
            validator: (value) {
              if (value == null || !value.contains('@')) return "Enter valid email";
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _regPinController,
            style: const TextStyle(color: AppTheme.textWhite),
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 4,
            decoration: const InputDecoration(
              labelText: "4-Digit Login PIN",
              prefixIcon: Icon(Icons.pin_outlined, color: AppTheme.goldAccent),
              counterText: "",
            ),
            validator: (value) {
              if (value == null || value.length != 4) return "PIN must be 4 digits";
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _regAadhaarController,
            style: const TextStyle(color: AppTheme.textWhite),
            keyboardType: TextInputType.number,
            maxLength: 12,
            decoration: const InputDecoration(
              labelText: "12-Digit Aadhaar Card",
              prefixIcon: Icon(Icons.verified_user_outlined, color: AppTheme.goldAccent),
              counterText: "",
            ),
            validator: (value) {
              if (value == null || value.length != 12) return "Enter 12-digit Aadhaar";
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _regMobileController,
            style: const TextStyle(color: AppTheme.textWhite),
            keyboardType: TextInputType.phone,
            maxLength: 10,
            decoration: const InputDecoration(
              labelText: "Mobile Number",
              prefixIcon: Icon(Icons.phone_android_rounded, color: AppTheme.goldAccent),
              counterText: "",
            ),
            validator: (value) {
              if (value == null || value.length != 10) return "Enter 10-digit mobile number";
              return null;
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _register,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text("REGISTER & LOGIN"),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, String label, IconData icon) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = index;
            _errorMessage = "";
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.goldAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? AppTheme.primaryNavy : AppTheme.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? AppTheme.primaryNavy : AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuthBody() {
    switch (_selectedTab) {
      case 0:
        return Column(
          children: [
            const Text(
              "ENTER SECURITY PIN",
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 2.0),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(4, (index) {
                return SizedBox(
                  width: 50,
                  height: 60,
                  child: TextField(
                    controller: _pinControllers[index],
                    focusNode: _focusNodes[index],
                    maxLength: 1,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    obscureText: true,
                    style: const TextStyle(fontSize: 24, color: AppTheme.goldAccent, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      counterText: "",
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.primaryLightNavy, width: 2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.goldAccent, width: 2.5),
                      ),
                    ),
                    onChanged: (value) => _onPinChanged(index, value),
                  ),
                );
              }),
            ),
            const SizedBox.shrink(),
          ],
        );
      case 1:
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: FingerprintScannerWidget(
            onAuthenticationComplete: _onBiometricAuthenticated,
          ),
        );
      case 2:
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: FaceScannerWidget(
            onAuthenticationComplete: _onBiometricAuthenticated,
          ),
        );
      case 3:
        return _buildOtpBody();
      case 4:
        return _buildFirebaseOtpBody();
      default:
        return const SizedBox.shrink();
    }
  }

  void _handleSendOtp() async {
    if (!_otpEmailController.text.contains('@')) {
      setState(() => _errorMessage = "Enter valid email address");
      return;
    }
    setState(() {
      _isOtpLoading = true;
      _errorMessage = "";
    });
    final success = await _authService.requestEmailOTP(_otpEmailController.text.trim());
    setState(() {
      _isOtpLoading = false;
    });
    if (success) {
      setState(() {
        _isOtpSent = true;
      });
    } else {
      setState(() {
        _errorMessage = "Failed to send Email OTP.";
      });
    }
  }

  void _handleVerifyOtp() async {
    if (_otpCodeController.text.length < 6) {
      setState(() => _errorMessage = "Enter valid 6-digit OTP.");
      return;
    }
    setState(() {
      _isOtpLoading = true;
      _errorMessage = "";
    });
    final success = await _authService.verifyEmailOTP(_otpEmailController.text.trim(), _otpCodeController.text.trim());
    setState(() {
      _isOtpLoading = false;
    });
    if (success) {
      _navigateToDashboard();
    } else {
      setState(() => _errorMessage = "Invalid OTP.");
    }
  }

  void _handleSendFirebaseOtp() async {
    if (_firebasePhoneController.text.length != 10) {
      setState(() => _errorMessage = "Enter valid 10-digit mobile number");
      return;
    }
    setState(() {
      _isFirebaseLoading = true;
      _errorMessage = "";
    });
    final success = await _authService.requestFirebaseOTP(_firebasePhoneController.text.trim());
    setState(() {
      _isFirebaseLoading = false;
    });
    if (success) {
      setState(() {
        _isFirebaseOtpSent = true;
      });
    } else {
      setState(() {
        _errorMessage = "Failed to send SMS OTP.";
      });
    }
  }

  void _handleVerifyFirebaseOtp() async {
    if (_firebaseCodeController.text.length < 6) {
      setState(() => _errorMessage = "Enter valid 6-digit OTP.");
      return;
    }
    setState(() {
      _isFirebaseLoading = true;
      _errorMessage = "";
    });
    final success = await _authService.verifyFirebaseOTP(_firebaseCodeController.text.trim());
    setState(() {
      _isFirebaseLoading = false;
    });
    if (success) {
      _navigateToDashboard();
    } else {
      setState(() => _errorMessage = "Invalid SMS OTP.");
    }
  }

  void _handleGoogleLogin() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = "";
    });
    final errorMsg = await _authService.loginWithGoogle();
    setState(() {
      _isGoogleLoading = false;
    });
    if (errorMsg == null) {
      _navigateToDashboard();
    } else {
      setState(() => _errorMessage = "Google login failed: $errorMsg");
    }
  }

  Widget _buildOtpBody() {
    return Column(
      children: [
        const Text(
          "LOGIN WITH OTP",
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 2.0),
        ),
        const SizedBox(height: 20),
        if (!_isOtpSent) ...[
          TextField(
            controller: _otpEmailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: AppTheme.textWhite, fontSize: 16),
            decoration: const InputDecoration(
              hintText: "Enter Email Address",
              prefixIcon: Icon(Icons.email_outlined, color: AppTheme.goldAccent),
              counterText: "",
            ),
          ),
          const SizedBox(height: 20),
          _isOtpLoading 
            ? const CircularProgressIndicator(color: AppTheme.goldAccent)
            : ElevatedButton(
                onPressed: _handleSendOtp,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text("SEND OTP"),
              ),
        ] else ...[
          Text(
            "OTP sent to ${_otpEmailController.text}",
            style: const TextStyle(color: AppTheme.successGreen, fontSize: 12),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _otpCodeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textWhite, fontSize: 24, letterSpacing: 8.0, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              hintText: "000000",
              counterText: "",
            ),
          ),
          const SizedBox(height: 20),
          _isOtpLoading 
            ? const CircularProgressIndicator(color: AppTheme.goldAccent)
            : ElevatedButton(
                onPressed: _handleVerifyOtp,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text("VERIFY & LOGIN"),
              ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => setState(() { _isOtpSent = false; _otpCodeController.clear(); }),
            child: const Text("Change Mobile Number", style: TextStyle(color: AppTheme.goldAccent, fontSize: 12)),
          )
        ],
      ],
    );
  }

  Widget _buildFirebaseOtpBody() {
    return Column(
      children: [
        const Text(
          "LOGIN WITH SMS OTP",
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 2.0),
        ),
        const SizedBox(height: 20),
        if (!_isFirebaseOtpSent) ...[
          TextField(
            controller: _firebasePhoneController,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            style: const TextStyle(color: AppTheme.textWhite, fontSize: 16),
            decoration: const InputDecoration(
              hintText: "Enter Mobile Number",
              prefixIcon: Icon(Icons.phone_android, color: AppTheme.goldAccent),
              counterText: "",
            ),
          ),
          const SizedBox(height: 20),
          _isFirebaseLoading 
            ? const CircularProgressIndicator(color: AppTheme.goldAccent)
            : ElevatedButton(
                onPressed: _handleSendFirebaseOtp,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text("SEND SMS OTP"),
              ),
        ] else ...[
          Text(
            "SMS sent to ${_firebasePhoneController.text}",
            style: const TextStyle(color: AppTheme.successGreen, fontSize: 12),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _firebaseCodeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textWhite, fontSize: 24, letterSpacing: 8.0, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              hintText: "000000",
              counterText: "",
            ),
          ),
          const SizedBox(height: 20),
          _isFirebaseLoading 
            ? const CircularProgressIndicator(color: AppTheme.goldAccent)
            : ElevatedButton(
                onPressed: _handleVerifyFirebaseOtp,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text("VERIFY & LOGIN"),
              ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => setState(() { _isFirebaseOtpSent = false; _firebaseCodeController.clear(); }),
            child: const Text("Change Mobile Number", style: TextStyle(color: AppTheme.goldAccent, fontSize: 12)),
          )
        ],
      ],
    );
  }

  Widget _buildGoogleLoginButton() {
    return _isGoogleLoading 
      ? const Center(child: CircularProgressIndicator(color: Colors.white))
      : InkWell(
          onTap: _handleGoogleLogin,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.network(
                  'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg',
                  height: 24,
                  width: 24,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata_rounded, color: Colors.black, size: 36),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Continue with Google",
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
  }
}
