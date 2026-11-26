import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/cart_bloc.dart';
import '../blocs/cart_event.dart';
import '../blocs/cart_state.dart';
import '../blocs/points_cubit.dart';
import '../theme/app_colors.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // BlocBuilder: the screen is redrawn on every CartState change
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, cart) => Scaffold(
        appBar: AppBar(
          title: Text(
            'Cart (${cart.count})',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          backgroundColor: AppColors.background,
        ),
        body: cart.items.isEmpty
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.shopping_bag_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Your cart is empty',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                      ),
                    ),
                    Text(
                      'Go back and pick some rewards',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: cart.items.length,
                      itemBuilder: (context, i) {
                        final r = cart.items[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: r.color,
                                backgroundImage: r.imageUrl != null
                                    ? NetworkImage(r.imageUrl!)
                                    : null,
                                onBackgroundImageError: r.imageUrl != null
                                    ? (_, _) {}
                                    : null,
                                child: r.imageUrl == null
                                    ? Icon(r.icon, color: AppColors.navy)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      r.name,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.navy,
                                      ),
                                    ),
                                    Text(
                                      '${r.cost} pts',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Remove',
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                                onPressed: () => context.read<CartBloc>().add(
                                  RemoveRewardEvent(r.id),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  _Summary(cart: cart),
                ],
              ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  final CartState cart;
  const _Summary({required this.cart});

  // Spend Paw Points (PointsCubit checks the balance), then empty the cart
  void _redeem(BuildContext context) {
    final count = cart.count;
    final ok = context.read<PointsCubit>().spend(
      cart.totalPrice,
      'Redeemed $count reward${count == 1 ? '' : 's'}',
    );

    final messenger = ScaffoldMessenger.of(context)..clearSnackBars();
    if (!ok) {
      messenger.showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Not enough Paw Points'),
        ),
      );
      return;
    }
    context.read<CartBloc>().add(const ClearCartEvent());
    messenger.showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.navy,
        content: Text('Done! Pick up your rewards at the shelter desk.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final balance = context.watch<PointsCubit>().state.balance;
    final over = cart.isOverBudget(balance);

    return SafeArea(
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            _row('Total', '${cart.totalPrice} pts', Colors.white),
            const SizedBox(height: 4),
            _row('Balance', '$balance pts', Colors.white70),
            const SizedBox(height: 4),
            _row(
              'Remaining',
              '${cart.remaining(balance)} pts',
              over ? Colors.redAccent : AppColors.lime,
            ),
            if (over)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Not enough Paw Points — remove something',
                  style: TextStyle(color: Colors.redAccent, fontSize: 12),
                ),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.lime,
                  foregroundColor: AppColors.navy,
                  disabledBackgroundColor: Colors.white24,
                ),
                onPressed: (cart.items.isEmpty || over)
                    ? null
                    : () => _redeem(context),
                icon: const Icon(Icons.redeem),
                label: Text(
                  'Redeem ${cart.totalPrice} pts',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                ),
                onPressed: cart.items.isEmpty
                    ? null
                    : () =>
                          context.read<CartBloc>().add(const ClearCartEvent()),
                icon: const Icon(Icons.delete_sweep),
                label: const Text('Clear All'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: color)),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
