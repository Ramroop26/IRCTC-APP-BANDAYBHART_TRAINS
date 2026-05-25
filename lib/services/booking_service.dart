import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import '../models/booking.dart';
import '../models/train.dart';
import '../models/passenger.dart';
import 'wallet_service.dart';
import 'auth_service.dart';

class BookingService extends ChangeNotifier {
  static final BookingService _instance = BookingService._internal();
  factory BookingService() => _instance;
  BookingService._internal();

  final List<Booking> _bookings = [];

  List<Booking> get bookings => List.unmodifiable(_bookings);

  List<Booking> getActiveBookings() {
    return _bookings.where((b) => b.status == 'CONFIRMED').toList();
  }

  Booking? findByPnr(String pnr) {
    try {
      return _bookings.firstWhere((b) => b.pnr == pnr);
    } catch (_) {
      return null;
    }
  }

  // Fetch bookings list from MySQL
  Future<void> fetchBookings() async {
    final email = AuthService().userEmail;
    if (email.isEmpty) return;

    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/bookings?email=$email'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          _bookings.clear();
          final list = data['bookings'] as List;
          for (var b in list) {
            final trainData = b['train'];
            final mockTrain = Train(
              number: trainData['number'],
              name: trainData['name'],
              source: trainData['source'],
              destination: trainData['destination'],
              departureTime: trainData['departureTime'],
              arrivalTime: trainData['arrivalTime'],
              duration: "08h 00m",
              classes: List<String>.from(trainData['classes']),
              prices: {"CC": 1750.0, "EC": 3200.0},
              availability: {"CC": 45, "EC": 12},
              type: trainData['name'].toString().contains("VANDE") ? "Vande Bharat" : "Express",
            );

            final passengers = (b['passengers'] as List).map((p) => Passenger(
              name: p['name'],
              age: p['age'],
              gender: p['gender'],
              berthPreference: p['berthPreference'],
              coach: p['coach'],
              seatNumber: p['seatNumber'],
            )).toList();

            _bookings.add(Booking(
              pnr: b['pnr'],
              train: mockTrain,
              journeyDate: b['journeyDate'],
              passengers: passengers,
              status: b['status'],
              totalAmount: b['totalAmount'].toDouble(),
              paymentMode: b['paymentMode'],
              transactionId: b['transactionId'],
              bookingDate: DateTime.parse(b['bookingDate']),
              bookedSource: b['bookedSource'],
              bookedDestination: b['bookedDestination'],
            ));
          }
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint("Failed to fetch bookings: $e");
    }
  }

  // Create booking in MySQL
  Future<Booking?> createBooking({
    required Train train,
    required String journeyDate,
    required List<Passenger> passengers,
    required String travelClass,
    required double totalAmount,
    required String paymentMode,
    String? bookedSource,
    String? bookedDestination,
  }) async {
    final email = AuthService().userEmail;
    if (email.isEmpty) return null;

    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/bookings/create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'trainNumber': train.number,
          'trainName': train.name,
          'source': bookedSource ?? train.source,
          'destination': bookedDestination ?? train.destination,
          'departureTime': train.departureTime,
          'arrivalTime': train.arrivalTime,
          'journeyDate': journeyDate,
          'passengers': passengers.map((p) => {
            'name': p.name,
            'age': p.age,
            'gender': p.gender,
            'berthPreference': p.berthPreference
          }).toList(),
          'totalAmount': totalAmount,
          'paymentMode': paymentMode
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          final pnr = data['pnr'];
          // Fetch updated bookings list and wallet balance
          await fetchBookings();
          await WalletService().fetchWalletData();
          return findByPnr(pnr);
        }
      }
    } catch (e) {
      debugPrint("Booking creation network error: $e");
    }
    return null;
  }

  // Cancel booking in MySQL
  Future<bool> cancelBooking(String pnr) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/bookings/cancel'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'pnr': pnr}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          await fetchBookings();
          await WalletService().fetchWalletData();
          return true;
        }
      }
    } catch (e) {
      debugPrint("Booking cancellation network error: $e");
    }
    return false;
  }
}
