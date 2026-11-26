import 'package:flutter_bloc/flutter_bloc.dart';

import 'walks_event.dart';
import 'walks_state.dart';

// All walk rules live here, not in the widgets.
class WalksBloc extends Bloc<WalksEvent, WalksState> {
  WalksBloc() : super(const WalksState()) {
    on<BookWalkEvent>(_onBook);
    on<CancelWalkEvent>(_onCancel);
    on<ReportWalkEvent>(_onReport);
    on<ConfirmWalkEvent>(_onConfirm);
    on<RejectWalkEvent>(_onReject);
  }

  void _onBook(BookWalkEvent event, Emitter<WalksState> emit) {
    // Rule: each dog can be booked only once
    if (state.bookingFor(event.dogName) != null) {
      _fail(emit, '${event.dogName} is already booked.');
      return;
    }

    // Rule: one dog per day
    final today = state.todayWalk;
    if (today != null) {
      _fail(
        emit,
        'One dog per day: you already walk ${today.dogName} today at ${today.slot}.',
      );
      return;
    }

    final now = DateTime.now();
    final booking = WalkBooking(
      id: '${event.dogName}_${now.millisecondsSinceEpoch}',
      dogName: event.dogName,
      slot: event.slot,
      date: now,
    );
    // New list, the old one is not changed
    emit(WalksState(bookings: [...state.bookings, booking]));
  }

  void _onCancel(CancelWalkEvent event, Emitter<WalksState> emit) {
    final booking = state.bookingFor(event.dogName);
    if (booking == null) return;
    if (!booking.canCancel) {
      _fail(emit, 'This walk is already reported and cannot be cancelled.');
      return;
    }
    emit(
      WalksState(
        bookings: state.bookings
            .where((b) => b.dogName != event.dogName)
            .toList(),
      ),
    );
  }

  void _onReport(ReportWalkEvent event, Emitter<WalksState> emit) {
    final booking = state.bookingFor(event.dogName);
    if (booking == null || !booking.canReport) return;
    _setStatus(emit, booking.id, WalkStatus.reported);
  }

  // Staff: only a reported walk can be confirmed or rejected
  void _onConfirm(ConfirmWalkEvent event, Emitter<WalksState> emit) {
    if (_statusOf(event.walkId) != WalkStatus.reported) return;
    _setStatus(emit, event.walkId, WalkStatus.confirmed);
  }

  void _onReject(RejectWalkEvent event, Emitter<WalksState> emit) {
    if (_statusOf(event.walkId) != WalkStatus.reported) return;
    _setStatus(emit, event.walkId, WalkStatus.rejected);
  }

  WalkStatus? _statusOf(String walkId) {
    for (final b in state.bookings) {
      if (b.id == walkId) return b.status;
    }
    return null;
  }

  void _setStatus(Emitter<WalksState> emit, String walkId, WalkStatus status) {
    emit(
      WalksState(
        bookings: state.bookings
            .map((b) => b.id == walkId ? b.copyWith(status: status) : b)
            .toList(),
      ),
    );
  }

  // Emit the error once, then clear it, so the same error can appear again.
  void _fail(Emitter<WalksState> emit, String message) {
    emit(WalksState(bookings: state.bookings, error: message));
    emit(WalksState(bookings: state.bookings));
  }
}
