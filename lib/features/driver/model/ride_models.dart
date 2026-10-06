class RideOption {
  RideOption({
    required this.id,
    required this.type,
    required this.driver,
    required this.rating,
    required this.trips,
    required this.car,
    required this.plate,
    required this.eta,
    required this.price,
    required this.distance,
    required this.image,
    required this.phone,
  });

  final String id;
  final String type;
  final String driver;
  final double rating;
  final int trips;
  final String car;
  final String plate;
  final int eta;
  final int price;
  final double distance;
  final String image;
  final String phone;

  factory RideOption.fromMap(Map<String, dynamic> map) {
    return RideOption(
      id: map['id'] as String,
      type: map['type'] as String,
      driver: map['driver'] as String,
      rating: (map['rating'] as num).toDouble(),
      trips: (map['trips'] as num).toInt(),
      car: map['car'] as String,
      plate: map['plate'] as String,
      eta: (map['eta'] as num).toInt(),
      price: (map['price'] as num).toInt(),
      distance: (map['distance'] as num).toDouble(),
      image: map['image'] as String,
      phone: map['phone'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'driver': driver,
      'rating': rating,
      'trips': trips,
      'car': car,
      'plate': plate,
      'eta': eta,
      'price': price,
      'distance': distance,
      'image': image,
      'phone': phone,
    };
  }
}

class ActiveRide {
  ActiveRide({
    required this.id,
    required this.driver,
    required this.rating,
    required this.car,
    required this.plate,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.pickupTime,
    required this.dropoffTime,
    required this.price,
    required this.status,
    required this.phone,
    required this.driverImage,
  });

  final String id;
  final String driver;
  final double rating;
  final String car;
  final String plate;
  final String pickupLocation;
  final String dropoffLocation;
  final String pickupTime;
  final String dropoffTime;
  final int price;
  final String status;
  final String phone;
  final String driverImage;

  factory ActiveRide.fromMap(Map<String, dynamic> map) {
    return ActiveRide(
      id: map['id'] as String,
      driver: map['driver'] as String,
      rating: (map['rating'] as num).toDouble(),
      car: map['car'] as String,
      plate: map['plate'] as String,
      pickupLocation: map['pickupLocation'] as String,
      dropoffLocation: map['dropoffLocation'] as String,
      pickupTime: map['pickupTime'] as String,
      dropoffTime: map['dropoffTime'] as String,
      price: (map['price'] as num).toInt(),
      status: map['status'] as String,
      phone: map['phone'] as String,
      driverImage: map['driverImage'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'driver': driver,
      'rating': rating,
      'car': car,
      'plate': plate,
      'pickupLocation': pickupLocation,
      'dropoffLocation': dropoffLocation,
      'pickupTime': pickupTime,
      'dropoffTime': dropoffTime,
      'price': price,
      'status': status,
      'phone': phone,
      'driverImage': driverImage,
    };
  }
}

class RideHistoryEntry {
  RideHistoryEntry({
    required this.id,
    required this.date,
    required this.from,
    required this.to,
    required this.price,
    required this.rating,
    required this.driver,
    required this.driverImage,
  });

  final String id;
  final String date;
  final String from;
  final String to;
  final int price;
  final int rating;
  final String driver;
  final String driverImage;

  factory RideHistoryEntry.fromMap(Map<String, dynamic> map) {
    return RideHistoryEntry(
      id: map['id'] as String,
      date: map['date'] as String,
      from: map['from'] as String,
      to: map['to'] as String,
      price: (map['price'] as num).toInt(),
      rating: (map['rating'] as num).toInt(),
      driver: map['driver'] as String,
      driverImage: map['driverImage'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'from': from,
      'to': to,
      'price': price,
      'rating': rating,
      'driver': driver,
      'driverImage': driverImage,
    };
  }
}
