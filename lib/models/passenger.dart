class Passenger {
  final String name;
  final int age;
  final String gender;
  final String berthPreference;
  String? seatNumber;
  String? coach;

  Passenger({
    required this.name,
    required this.age,
    required this.gender,
    required this.berthPreference,
    this.seatNumber,
    this.coach,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'age': age,
        'gender': gender,
        'berthPreference': berthPreference,
        'seatNumber': seatNumber,
        'coach': coach,
      };

  factory Passenger.fromJson(Map<String, dynamic> json) => Passenger(
        name: json['name'],
        age: json['age'],
        gender: json['gender'],
        berthPreference: json['berthPreference'],
        seatNumber: json['seatNumber'],
        coach: json['coach'],
      );
}
