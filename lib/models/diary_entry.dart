import 'package:equatable/equatable.dart';

// One record in the walk photo journal (LW13).
// Only metadata is stored: the photo itself stays in the local file system.
class DiaryEntry extends Equatable {
  final String id;
  final String imagePath;
  final String caption;
  final String? dogName; // the walk this photo belongs to (if any)
  final double latitude;
  final double longitude;
  final double altitude;
  final double accuracy; // meters
  final double distanceToShelter; // meters
  final DateTime timestamp;

  const DiaryEntry({
    required this.id,
    required this.imagePath,
    required this.caption,
    required this.dogName,
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.accuracy,
    required this.distanceToShelter,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [id];
}
