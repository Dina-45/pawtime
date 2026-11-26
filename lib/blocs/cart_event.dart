import 'package:equatable/equatable.dart';

import '../models/reward.dart';

// Rewards cart events: what happened in the UI.
// (LW12: AddProductEvent / RemoveProductEvent / ClearCartEvent —
//  in PawTime the "product" is a Reward bought with Paw Points.)
abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

class AddRewardEvent extends CartEvent {
  final Reward reward;

  const AddRewardEvent(this.reward);

  @override
  List<Object?> get props => [reward.id];
}

class RemoveRewardEvent extends CartEvent {
  final String rewardId;

  const RemoveRewardEvent(this.rewardId);

  @override
  List<Object?> get props => [rewardId];
}

class ClearCartEvent extends CartEvent {
  const ClearCartEvent();
}
