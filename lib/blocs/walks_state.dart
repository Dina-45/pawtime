import 'package:equatable/equatable.dart';

// Life of one walk:
// booked -> reported (volunteer sent a geotagged photo, LW13)
//        -> confirmed by staff (Paw Points are awarded) or rejected
// A rejected walk can be reported again with a new photo.
enum WalkStatus { booked, reported, confirmed, rejected }

extension WalkStatusText on WalkStatus {
  String get label => switch (this) {
    WalkStatus.booked => 'Booked',
    WalkStatus.reported => 'Waiting for staff',
    WalkStatus.confirmed => 'Confirmed',
    WalkStatus.rejected => 'Rejected · send a new photo',
  };
}

class WalkBooking extends Equatable {
  final String id;
  final String dogName;
  final String slot;
  final DateTime date;
  final WalkStatus status;

  const WalkBooking({
    required this.id,
    required this.dogName,
    required this.slot,
    required this.date,
    this.status = WalkStatus.booked,
  });

  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  // The volunteer can (re)send a photo report
  bool get canReport =>
      status == WalkStatus.booked || status == WalkStatus.rejected;

  bool get canCancel => status == WalkStatus.booked;

  WalkBooking copyWith({WalkStatus? status}) => WalkBooking(
    id: id,
    dogName: dogName,
    slot: slot,
    date: date,
    status: status ?? this.status,
  );

  @override
  List<Object?> get props => [id, dogName, slot, date, status];
}

// Immutable state of all bookings.
class WalksState extends Equatable {
  final List<WalkBooking> bookings;

  // One-time error message for the UI (shown in a SnackBar by BlocListener).
  final String? error;

  const WalksState({this.bookings = const [], this.error});

  WalkBooking? bookingFor(String dogName) {
    for (final b in bookings) {
      if (b.dogName == dogName) return b;
    }
    return null;
  }

  // Rule "one dog per day": there can be only one walk today.
  WalkBooking? get todayWalk {
    for (final b in bookings) {
      if (b.isToday) return b;
    }
    return null;
  }

  List<WalkBooking> withStatus(WalkStatus status) =>
      bookings.where((b) => b.status == status).toList();

  @override
  List<Object?> get props => [bookings, error];
}
