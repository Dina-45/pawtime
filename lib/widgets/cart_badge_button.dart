import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/cart_bloc.dart';
import '../blocs/cart_state.dart';
import '../screens/cart_screen.dart';

// AppBar cart icon with a LIVE counter.
// Used on several routes (Rewards shop, Product detail): every copy listens
// to the same CartBloc, so the number is always in sync.
class CartBadgeButton extends StatelessWidget {
  const CartBadgeButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartBloc, CartState>(
      // rebuild only when the number of items changes
      buildWhen: (prev, curr) => prev.count != curr.count,
      builder: (context, cart) {
        return IconButton(
          tooltip: 'Open cart',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CartScreen()),
          ),
          icon: Badge(
            isLabelVisible: cart.count > 0,
            label: Text('${cart.count}'),
            child: const Icon(Icons.shopping_bag_outlined),
          ),
        );
      },
    );
  }
}
