import 'package:equatable/equatable.dart';

// Walk events: what a volunteer or a staff member did in the UI.
abstract class WalksEvent extends Equatable {
  const WalksEvent();

  @override
  List<Object?> get props => [];
}

// ---- Volunteer ----

class BookWalkEvent extends WalksEvent {
  final String dogName;
  final String slot;

  const BookWalkEvent({required this.dogName, required this.slot});

  @override
  List<Object?> get props => [dogName, slot];
}

class CancelWalkEvent extends WalksEvent {
  final String dogName;

  const CancelWalkEvent(this.dogName);

  @override
  List<Object?> get props => [dogName];
}

// Sent when the volunteer saves a geotagged photo of the walk (LW13).
class ReportWalkEvent extends WalksEvent {
  final String dogName;

  const ReportWalkEvent(this.dogName);

  @override
  List<Object?> get props => [dogName];
}

// ---- Shelter staff ----

class ConfirmWalkEvent extends WalksEvent {
  final String walkId;

  const ConfirmWalkEvent(this.walkId);

  @override
  List<Object?> get props => [walkId];
}

class RejectWalkEvent extends WalksEvent {
  final String walkId;

  const RejectWalkEvent(this.walkId);

  @override
  List<Object?> get props => [walkId];
}
