import 'package:equatable/equatable.dart';

import '../models/reward.dart';

// Immutable state of the rewards cart: items, totalPrice, count.
// Prices are in Paw Points. The balance itself lives in PointsCubit.
class CartState extends Equatable {
  final List<Reward> items;

  const CartState({this.items = const []});

  int get count => items.length;
  int get totalPrice => items.fold(0, (sum, r) => sum + r.cost);

  int remaining(int balance) => balance - totalPrice;
  bool isOverBudget(int balance) => remaining(balance) < 0;

  bool contains(Reward r) => items.any((e) => e.id == r.id);

  @override
  List<Object?> get props => [items];
}
