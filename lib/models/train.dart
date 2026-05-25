class Train {
  final String number;
  final String name;
  final String source;
  final String destination;
  final String departureTime;
  final String arrivalTime;
  final String duration;
  final List<String> classes;
  final Map<String, double> prices;
  final Map<String, int> availability; // positive for available seats, negative/zero for waitlist count
  final String type; // Vande Bharat, Rajdhani, Shatabdi, Express

  Train({
    required this.number,
    required this.name,
    required this.source,
    required this.destination,
    required this.departureTime,
    required this.arrivalTime,
    required this.duration,
    required this.classes,
    required this.prices,
    required this.availability,
    required this.type,
  });

  String getAvailabilityText(String travelClass) {
    int avail = availability[travelClass] ?? 0;
    if (avail > 0) {
      return "AVAILABLE - $avail";
    } else if (avail == 0) {
      return "REGRET";
    } else {
      return "WL - ${avail.abs()}";
    }
  }

  Map<String, dynamic> toJson() => {
        'number': number,
        'name': name,
        'source': source,
        'destination': destination,
        'departureTime': departureTime,
        'arrivalTime': arrivalTime,
        'duration': duration,
        'classes': classes,
        'prices': prices,
        'availability': availability,
        'type': type,
      };

  factory Train.fromJson(Map<String, dynamic> json) => Train(
        number: json['number'],
        name: json['name'],
        source: json['source'],
        destination: json['destination'],
        departureTime: json['departureTime'],
        arrivalTime: json['arrivalTime'],
        duration: json['duration'],
        classes: List<String>.from(json['classes']),
        prices: Map<String, double>.from(json['prices']),
        availability: Map<String, int>.from(json['availability']),
        type: json['type'],
      );
}
