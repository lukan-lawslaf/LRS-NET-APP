class GpsData {
  final String lat;
  final String lon;
  final String fix;
  final String alt;
  final String course;
  final String date;
  final String time;
  final String rssi;
  final String snr;
  final DateTime receivedAt;

  GpsData({
    required this.lat,
    required this.lon,
    required this.fix,
    required this.alt,
    required this.course,
    required this.date,
    required this.time,
    required this.rssi,
    required this.snr,
    DateTime? receivedAt,
  }) : receivedAt = receivedAt ?? DateTime.now();

  factory GpsData.fromJson(Map<String, dynamic> json) {
    return GpsData(
      lat: json['lat']?.toString() ?? '--',
      lon: json['lon']?.toString() ?? '--',
      fix: json['fix']?.toString() ?? '0',
      alt: json['alt']?.toString() ?? '--',
      course: json['course']?.toString() ?? '--',
      date: json['date']?.toString() ?? '--/--/----',
      time: json['time']?.toString() ?? '--:--:--',
      rssi: json['rssi']?.toString() ?? '--',
      snr: json['snr']?.toString() ?? '--',
    );
  }

  String get fixLabel {
    switch (fix) {
      case '3':
        return '3D Fix';
      case '2':
        return '2D Fix';
      case '0':
        return 'No Fix';
      default:
        return fix;
    }
  }

  String get mapsUrl =>
      'https://www.google.com/maps/search/?api=1&query=$lat,$lon';
}
