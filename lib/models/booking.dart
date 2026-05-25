import 'train.dart';
import 'passenger.dart';

class Booking {
  final String pnr;
  final Train train;
  final String journeyDate;
  final List<Passenger> passengers;
  String status; // 'CONFIRMED', 'CANCELLED'
  final double totalAmount;
  final String paymentMode;
  final String transactionId;
  final DateTime bookingDate;
  final String? bookedSource;
  final String? bookedDestination;

  Booking({
    required this.pnr,
    required this.train,
    required this.journeyDate,
    required this.passengers,
    required this.status,
    required this.totalAmount,
    required this.paymentMode,
    required this.transactionId,
    required this.bookingDate,
    this.bookedSource,
    this.bookedDestination,
  });

  Map<String, dynamic> toJson() => {
        'pnr': pnr,
        'train': train.toJson(),
        'journeyDate': journeyDate,
        'passengers': passengers.map((p) => p.toJson()).toList(),
        'status': status,
        'totalAmount': totalAmount,
        'paymentMode': paymentMode,
        'transactionId': transactionId,
        'bookingDate': bookingDate.toIso8601String(),
        'bookedSource': bookedSource,
        'bookedDestination': bookedDestination,
      };

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
        pnr: json['pnr'],
        train: Train.fromJson(json['train']),
        journeyDate: json['journeyDate'],
        passengers: (json['passengers'] as List)
            .map((p) => Passenger.fromJson(p))
            .toList(),
        status: json['status'],
        totalAmount: json['totalAmount'],
        paymentMode: json['paymentMode'],
        transactionId: json['transactionId'],
        bookingDate: DateTime.parse(json['bookingDate']),
        bookedSource: json['bookedSource'],
        bookedDestination: json['bookedDestination'],
      );
}
