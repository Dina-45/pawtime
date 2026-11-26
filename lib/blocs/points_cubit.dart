import 'package:flutter_bloc/flutter_bloc.dart';

import 'points_state.dart';
import 'walks_state.dart';

// Paw Points wallet.
// Rule: points are awarded ONLY after staff confirms a completed walk.
class PointsCubit extends Cubit<PointsState> {
  PointsCubit() : super(const PointsState(history: _demoHistory));

  static const pointsPerWalk = 30;

  // Demo walks from before (Milestone 1 profile data)
  static const _demoHistory = [
    PointsTransaction(
      title: 'Rocky',
      subtitle: '18 Sep · 45 min walk',
      amount: 40,
      walkId: 'demo_rocky',
    ),
    PointsTransaction(
      title: 'Luna',
      subtitle: '25 Sep · 30 min walk',
      amount: 20,
      walkId: 'demo_luna',
    ),
    PointsTransaction(
      title: 'Max',
      subtitle: '2 Oct · 30 min walk',
      amount: 30,
      walkId: 'demo_max',
    ),
    PointsTransaction(
      title: 'Welcome bonus',
      subtitle: 'Volunteer onboarding',
      amount: 150,
    ),
  ];

  // Called when WalksBloc reports a confirmed walk.
  // Safe to call many times: each walk is paid only once.
  void awardWalk(WalkBooking walk) {
    if (walk.status != WalkStatus.confirmed) return;
    if (state.isAwarded(walk.id)) return;

    emit(
      PointsState(
        history: [
          PointsTransaction(
            title: walk.dogName,
            subtitle: 'Today ${walk.slot} · confirmed by staff',
            amount: pointsPerWalk,
            walkId: walk.id,
          ),
          ...state.history,
        ],
      ),
    );
  }

  // Returns false if there are not enough points.
  bool spend(int amount, String title) {
    if (amount <= 0) return true;
    if (amount > state.balance) return false;

    emit(
      PointsState(
        history: [
          PointsTransaction(
            title: title,
            subtitle: 'Rewards shop',
            amount: -amount,
          ),
          ...state.history,
        ],
      ),
    );
    return true;
  }
}
