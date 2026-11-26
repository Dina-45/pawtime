import 'package:flutter_bloc/flutter_bloc.dart';

import 'cart_event.dart';
import 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc() : super(const CartState()) {
    // Add: NEW list, the old one is never changed.
    // A reward is a single item (one pin, one T-shirt), so no duplicates.
    on<AddRewardEvent>((event, emit) {
      if (state.contains(event.reward)) return;
      emit(CartState(items: [...state.items, event.reward]));
    });

    // Remove one reward by id
    on<RemoveRewardEvent>((event, emit) {
      emit(
        CartState(
          items: state.items.where((r) => r.id != event.rewardId).toList(),
        ),
      );
    });

    // Empty the cart
    on<ClearCartEvent>((event, emit) => emit(const CartState()));
  }
}
