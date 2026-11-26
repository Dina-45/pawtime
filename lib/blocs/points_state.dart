import 'package:equatable/equatable.dart';

// One line in the Paw Points history: + for walks, - for rewards.
class PointsTransaction extends Equatable {
  final String title;
  final String subtitle;
  final int amount; // positive = earned, negative = spent
  final String? walkId; // set when the points are for a confirmed walk

  const PointsTransaction({
    required this.title,
    required this.subtitle,
    required this.amount,
    this.walkId,
  });

  @override
  List<Object?> get props => [title, subtitle, amount, walkId];
}

// Levels by total earned points
class WalkerLevel {
  final String name;
  final int from;
  final int? next; // null = last level
  const WalkerLevel(this.name, this.from, this.next);
}

const _levels = [
  WalkerLevel('New Walker', 0, 300),
  WalkerLevel('Trusted Walker', 300, 600),
  WalkerLevel('Pack Leader', 600, null),
];

class PointsState extends Equatable {
  final List<PointsTransaction> history; // newest first

  const PointsState({this.history = const []});

  int get balance => history.fold(0, (sum, t) => sum + t.amount);

  int get totalEarned =>
      history.where((t) => t.amount > 0).fold(0, (sum, t) => sum + t.amount);

  int get confirmedWalks => history.where((t) => t.walkId != null).length;

  bool isAwarded(String walkId) => history.any((t) => t.walkId == walkId);

  WalkerLevel get level => _levels.lastWhere((l) => totalEarned >= l.from);

  // 0..1 progress to the next level (for LinearProgressIndicator)
  double get levelProgress {
    final l = level;
    if (l.next == null) return 1;
    return (totalEarned - l.from) / (l.next! - l.from);
  }

  @override
  List<Object?> get props => [history];
}
