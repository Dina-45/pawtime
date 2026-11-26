import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/cart_bloc.dart';
import '../blocs/cart_event.dart';
import '../blocs/points_cubit.dart';
import '../models/product.dart';
import '../models/reward.dart';
import '../services/product_service.dart';
import '../theme/app_colors.dart';
import '../widgets/cart_badge_button.dart';
import '../widgets/product_image.dart';
import 'product_detail_screen.dart';

// Paw Points shop:
// 1) rewards from the shelter (local list)
// 2) partner store rewards (REST API, fakestoreapi.com)
class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  List<Product> _products = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool fromPullToRefresh = false}) async {
    if (!fromPullToRefresh) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final items = await ProductService.fetchProducts();
      if (!mounted) return;
      setState(() {
        _products = items;
        _loading = false;
        _error = null;
      });
    } on ProductException catch (e) {
      if (!mounted) return;
      if (fromPullToRefresh && _products.isNotEmpty) {
        // data is already shown: keep it, just show the error
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(e.message)));
      } else {
        setState(() {
          _loading = false;
          _error = e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Rewards shop',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: AppColors.background,
        actions: [const CartBadgeButton(), const SizedBox(width: 8)],
      ),
      body: RefreshIndicator(
        onRefresh: () => _load(fromPullToRefresh: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            const _BalanceBanner(),
            const SizedBox(height: 20),
            const _SectionTitle('🐾 From the shelter'),
            ...shelterRewards.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ShelterRewardTile(reward: r),
              ),
            ),
            const SizedBox(height: 8),
            const _SectionTitle('🛍️ Partner store'),
            ..._buildPartnerSection(),
          ],
        ),
      ),
    );
  }

  // Loading / Error + Retry / Success — only for the API part
  List<Widget> _buildPartnerSection() {
    if (_loading) {
      return const [
        Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    if (_error != null) {
      return [_ErrorView(message: _error!, onRetry: _load)];
    }

    return _products
        .map(
          (product) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _PartnerRewardTile(
              product: product,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProductDetailScreen(product: product),
                ),
              ),
            ),
          ),
        )
        .toList();
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.navy,
        ),
      ),
    );
  }
}

class _BalanceBanner extends StatelessWidget {
  const _BalanceBanner();

  @override
  Widget build(BuildContext context) {
    final balance = context.watch<PointsCubit>().state.balance;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lime,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const Icon(Icons.pets, color: AppColors.navy),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Your balance\n(earned on confirmed walks)',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
          ),
          Text(
            '$balance pts',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.navy,
            ),
          ),
        ],
      ),
    );
  }
}

class _CartButton extends StatelessWidget {
  final Reward reward;
  const _CartButton({required this.reward});

  @override
  Widget build(BuildContext context) {
    final inCart = context.select<CartBloc, bool>(
      (b) => b.state.contains(reward),
    );
    final bloc = context.read<CartBloc>();

    return inCart
        ? FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.navy,
              foregroundColor: AppColors.lime,
            ),
            onPressed: () => bloc.add(RemoveRewardEvent(reward.id)),
            icon: const Icon(Icons.check, size: 18),
            label: const Text('In cart'),
          )
        : OutlinedButton(
            onPressed: () => bloc.add(AddRewardEvent(reward)),
            child: const Text('Add'),
          );
  }
}

class _ShelterRewardTile extends StatelessWidget {
  final Reward reward;
  const _ShelterRewardTile({required this.reward});

  @override
  Widget build(BuildContext context) {
    final inCart = context.select<CartBloc, bool>(
      (b) => b.state.contains(reward),
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: inCart ? Border.all(color: AppColors.navy, width: 2) : null,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: reward.color,
            child: Icon(reward.icon, color: AppColors.navy),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reward.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
                Text(
                  reward.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 4),
                Text(
                  '${reward.cost} pts',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _CartButton(reward: reward),
        ],
      ),
    );
  }
}

class _PartnerRewardTile extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const _PartnerRewardTile({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final reward = product.toReward();
    final inCart = context.select<CartBloc, bool>(
      (b) => b.state.contains(reward),
    );

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: inCart ? Border.all(color: AppColors.navy, width: 2) : null,
          ),
          child: Row(
            children: [
              Hero(
                tag: 'product_image_${product.id}',
                child: ProductImage(
                  url: product.imageUrl,
                  width: 72,
                  height: 72,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          '${product.rating.toStringAsFixed(1)} (${product.reviewCount})',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${product.pointsCost} pts',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _CartButton(reward: reward),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
          const SizedBox(height: 8),
          const Text(
            'Partner store is unavailable',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navy,
              foregroundColor: AppColors.lime,
            ),
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry Connection'),
          ),
        ],
      ),
    );
  }
}
