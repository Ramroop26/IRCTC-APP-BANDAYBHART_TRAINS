import 'package:google_sign_in/google_sign_in.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'wallet_service.dart';
import 'booking_service.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  
  AuthService._internal() {
    checkRegistrationStatus();
  }

  final LocalAuthentication _localAuth = LocalAuthentication();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );
  
  bool _isLoggedIn = false;
  
  // Active user details
  String _userName = '';
  String _userPin = '';
  String _userEmail = '';
  String _userAadhaar = '';
  String _userMobile = '';
  final bool _isBiometricEnabled = false;

  bool _hasRegisteredUsers = false;

  bool get isLoggedIn => _isLoggedIn;
  bool get hasRegisteredUsers => _hasRegisteredUsers;
  String get userName => _userName;
  String get userPin => _userPin;
  String get userEmail => _userEmail;
  String get userAadhaar => _userAadhaar;
  String get userMobile => _userMobile;
  bool get isBiometricEnabled => _isBiometricEnabled;

  // Query database to check if there are users registered
  Future<void> checkRegistrationStatus() async {
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/auth/has-users'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _hasRegisteredUsers = data['hasUsers'] ?? false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Failed to check registration status: $e");
    }
  }

  Future<bool> checkBiometricSupport() async {
    try {
      if (kIsWeb) return false;
      final bool canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();
      return canAuthenticate;
    } catch (e) {
      debugPrint("Biometric check error: $e");
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      if (kIsWeb) return [];
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      debugPrint("Get biometrics error: $e");
      return [];
    }
  }

  Future<bool> authenticateWithHardware() async {
    if (!_hasRegisteredUsers) {
      debugPrint("No registered user found for biometric login.");
      return false;
    }
    try {
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access your IRCTC account',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      if (didAuthenticate) {
        final success = await _loadLastRegisteredProfile();
        if (success) {
          _isLoggedIn = true;
          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint("Hardware authentication failed: $e");
      return false;
    }
  }

  // Load last registered profile from backend
  Future<bool> _loadLastRegisteredProfile() async {
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/auth/last-user'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          final user = data['user'];
          _userName = user['name'];
          _userPin = user['pin'];
          _userEmail = user['email'];
          _userAadhaar = user['aadhaar'];
          _userMobile = user['mobile'];
          
          // Pre-fetch data
          WalletService().fetchWalletData();
          BookingService().fetchBookings();
          return true;
        }
      }
    } catch (e) {
      debugPrint("Error loading last registered profile: $e");
    }
    
    // Fallback if server fails but we need a profile
    _userName = 'Ramroop Prajapati';
    _userPin = '1234';
    _userEmail = 'rahul@example.com';
    _userAadhaar = '123456789012';
    _userMobile = '9876543210';
    return true;
  }

  // Simulated biometric authentication
  Future<bool> authenticateSimulated(bool isFace) async {
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!_hasRegisteredUsers) {
      return false;
    }
    final success = await _loadLastRegisteredProfile();
    if (success) {
      _isLoggedIn = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  // Register a new user on MySQL
  Future<bool> registerUser(String name, String email, String pin, String aadhaar, String mobile) async {
    if (name.isEmpty || email.isEmpty || pin.isEmpty || aadhaar.isEmpty || mobile.isEmpty) return false;
    
    final emailKey = email.toLowerCase().trim();
    
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name.trim(),
          'email': emailKey,
          'pin': pin,
          'aadhaar': aadhaar,
          'mobile': mobile
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          _userName = name.trim();
          _userPin = pin;
          _userEmail = emailKey;
          _userAadhaar = aadhaar;
          _userMobile = mobile;
          _isLoggedIn = true;
          _hasRegisteredUsers = true;
          
          // Pre-fetch data
          WalletService().fetchWalletData();
          BookingService().fetchBookings();
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      debugPrint("Registration network error: $e");
    }
    return false;
  }

  // Authenticate PIN on MySQL
  Future<bool> authenticatePin(String pin) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/login-pin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'pin': pin}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          final user = data['user'];
          _userName = user['name'];
          _userPin = user['pin'];
          _userEmail = user['email'];
          _userAadhaar = user['aadhaar'];
          _userMobile = user['mobile'];
          _isLoggedIn = true;
          
          // Pre-fetch data
          WalletService().fetchWalletData();
          BookingService().fetchBookings();
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      debugPrint("PIN Login network error: $e");
    }
    return false;
  }

  // Authenticate Email + PIN on MySQL
  Future<bool> authenticateEmailPin(String email, String pin) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/login-email-pin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'pin': pin
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          final user = data['user'];
          _userName = user['name'];
          _userPin = user['pin'];
          _userEmail = user['email'];
          _userAadhaar = user['aadhaar'];
          _userMobile = user['mobile'];
          _isLoggedIn = true;
          
          // Pre-fetch data
          WalletService().fetchWalletData();
          BookingService().fetchBookings();
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      debugPrint("Email PIN Login network error: $e");
    }
    return false;
  }

  // Update profile mobile
  Future<void> updateMobile(String mobile) async {
    _userMobile = mobile;
    notifyListeners();
    try {
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/update-profile'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _userEmail,
          'mobile': mobile
        }),
      );
    } catch (e) {
      debugPrint("Error updating mobile: $e");
    }
  }

  // Update profile Aadhaar
  Future<void> updateAadhaar(String aadhaar) async {
    _userAadhaar = aadhaar;
    notifyListeners();
    try {
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/update-profile'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _userEmail,
          'aadhaar': aadhaar
        }),
      );
    } catch (e) {
      debugPrint("Error updating Aadhaar: $e");
    }
  }

  // Request OTP
  Future<bool> requestOTP(String mobile) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mobile': mobile}),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['success'] == true;
      }
    } catch (e) {
      debugPrint("OTP request error: $e");
    }
    return false;
  }

  // Verify OTP
  Future<bool> verifyOTP(String mobile, String otp) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'mobile': mobile,
          'otp': otp,
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          final user = data['user'];
          _userName = user['name'];
          _userPin = user['pin'];
          _userEmail = user['email'];
          _userAadhaar = user['aadhaar'];
          _userMobile = user['mobile'];
          _isLoggedIn = true;
          _hasRegisteredUsers = true;
          
          WalletService().fetchWalletData();
          BookingService().fetchBookings();
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      debugPrint("OTP verify error: $e");
    }
    return false;
  }

  // Real Google Login
  Future<bool> loginWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User aborted the sign-in
        return false;
      }

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        debugPrint("Google sign in failed: No ID Token returned");
        return false;
      }

      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/google-login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': idToken}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          final user = data['user'];
          _userName = user['name'];
          _userPin = user['pin'];
          _userEmail = user['email'];
          _userAadhaar = user['aadhaar'];
          _userMobile = user['mobile'];
          _isLoggedIn = true;
          _hasRegisteredUsers = true;
          
          WalletService().fetchWalletData();
          BookingService().fetchBookings();
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      debugPrint("Google login error: $e");
    }
    return false;
  }

  void logout() {
    _isLoggedIn = false;
    _userName = '';
    _userPin = '';
    _userEmail = '';
    _userAadhaar = '';
    _userMobile = '';
    notifyListeners();
  }
}
