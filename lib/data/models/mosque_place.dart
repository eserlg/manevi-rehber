class MosquePlace {
  final String id;
  final String name;
  final String? address;
  final double latitude;
  final double longitude;
  final double distanceKm;

  const MosquePlace({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
  });

  String get formattedDistance {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} m';
    }
    return '${distanceKm.toStringAsFixed(1)} km';
  }
}
