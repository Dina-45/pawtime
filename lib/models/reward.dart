import 'package:flutter/material.dart';

class Reward {
  final String id;
  final String name;
  final String description;
  final int cost; // price in Paw Points
  final IconData icon;
  final Color color;
  final String? imageUrl;

  const Reward({
    required this.id,
    required this.name,
    required this.description,
    required this.cost,
    required this.icon,
    required this.color,
    this.imageUrl,
  });

  // Two rewards are the same if their id is the same.
  // This makes CartState comparisons (Equatable) work correctly.
  @override
  bool operator ==(Object other) => other is Reward && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

// Rewards from the shelter itself (no internet needed).
// Partner rewards come from the REST API (ProductService).
const List<Reward> shelterRewards = [
  Reward(
    id: 'pin',
    name: 'Volunteer pin',
    description: 'Enamel pin with the PawTime logo',
    cost: 40,
    icon: Icons.military_tech,
    color: Color(0xFFDCF05A),
  ),
  Reward(
    id: 'bandana',
    name: 'Dog bandana',
    description: 'A stylish bandana for your walking buddy',
    cost: 50,
    icon: Icons.pets,
    color: Color(0xFFF7C6D9),
  ),
  Reward(
    id: 'treats',
    name: 'Walk treat kit',
    description: 'Free set of treats for your next walk',
    cost: 60,
    icon: Icons.cookie,
    color: Color(0xFFFFE3A3),
  ),
  Reward(
    id: 'coffee',
    name: 'Coffee voucher',
    description: 'Free coffee at a partner cafe near the shelter',
    cost: 80,
    icon: Icons.local_cafe,
    color: Color(0xFFF9D2BE),
  ),
  Reward(
    id: 'tote',
    name: 'Tote bag',
    description: 'Canvas bag for walks and shopping',
    cost: 90,
    icon: Icons.shopping_bag,
    color: Color(0xFFC8EBD6),
  ),
  Reward(
    id: 'tshirt',
    name: 'Shelter T-shirt',
    description: 'Official volunteer T-shirt',
    cost: 120,
    icon: Icons.checkroom,
    color: Color(0xFFC9D8FA),
  ),
];
