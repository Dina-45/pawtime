import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/auth_cubit.dart';
import '../blocs/auth_state.dart';
import '../blocs/diary_cubit.dart';
import '../blocs/points_cubit.dart';
import '../blocs/walks_bloc.dart';
import '../blocs/walks_event.dart';
import '../blocs/walks_state.dart';
import '../models/diary_entry.dart';
import '../models/shelter.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/zone_chip.dart';
import 'login_screen.dart';

// Shelter staff side of the app.
// Staff sees walk reports (photo + GPS from LW13) and confirms or rejects them.
// Only a confirmed walk gives the volunteer Paw Points.
class StaffScreen extends StatelessWidget {
  const StaffScreen({super.key});

  void _logout(BuildContext context) {
    context.read<AuthCubit>().logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthCubit>().state;
    final name = auth is AuthSuccess ? auth.name : 'Staff';
    final walks = context.watch<WalksBloc>().state;
    final diary = context.watch<DiaryCubit>().state;

    final toReview = walks.withStatus(WalkStatus.reported);
    final booked = walks.withStatus(WalkStatus.booked);
    final done = walks.bookings
        .where(
          (b) =>
              b.status == WalkStatus.confirmed ||
              b.status == WalkStatus.rejected,
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Shelter staff',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: AppColors.background,
        actions: [
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Hi, $name',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
          const Text(Shelter.name, style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 16),
          _Section('📨 Walk reports to review (${toReview.length})'),
          if (toReview.isEmpty)
            const _Empty(
              'No reports yet. They appear when a volunteer '
              'saves a walk photo in "My Walks".',
            )
          else
            ...toReview.map(
              (w) =>
                  _ReportCard(walk: w, photo: _latestPhoto(diary, w.dogName)),
            ),
          const SizedBox(height: 16),
          _Section('🐕 Booked walks (${booked.length})'),
          if (booked.isEmpty)
            const _Empty('No walks waiting to start.')
          else
            ...booked.map((w) => _SimpleTile(walk: w)),
          const SizedBox(height: 16),
          _Section('✅ Reviewed (${done.length})'),
          if (done.isEmpty)
            const _Empty('Nothing reviewed yet.')
          else
            ...done.map((w) => _SimpleTile(walk: w)),
        ],
      ),
    );
  }

  // Diary is newest-first, so the first match is the latest photo
  static DiaryEntry? _latestPhoto(List<DiaryEntry> diary, String dogName) {
    for (final e in diary) {
      if (e.dogName == dogName) return e;
    }
    return null;
  }
}

class _ReportCard extends StatelessWidget {
  final WalkBooking walk;
  final DiaryEntry? photo;

  const _ReportCard({required this.walk, required this.photo});

  @override
  Widget build(BuildContext context) {
    final entry = photo;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${walk.dogName} · ${walk.slot}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 8),
          if (entry != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                File(entry.imagePath),
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  height: 180,
                  color: AppColors.background,
                  child: const Center(
                    child: Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text('“${entry.caption}”'),
            Text(
              '${formatCoordinates(entry.latitude, entry.longitude)} · '
              '± ${entry.accuracy.toStringAsFixed(0)} m\n'
              '${formatDateTime(entry.timestamp)}',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 6),
            ZoneChip(
              distance: entry.distanceToShelter,
              inZone: entry.distanceToShelter <= Shelter.walkZoneMeters,
            ),
          ] else
            const Text(
              'No photo found for this walk.',
              style: TextStyle(color: Colors.black54),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: () =>
                      context.read<WalksBloc>().add(RejectWalkEvent(walk.id)),
                  icon: const Icon(Icons.close),
                  label: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: AppColors.lime,
                  ),
                  onPressed: () =>
                      context.read<WalksBloc>().add(ConfirmWalkEvent(walk.id)),
                  icon: const Icon(Icons.check),
                  label: const Text('Confirm +${PointsCubit.pointsPerWalk}'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SimpleTile extends StatelessWidget {
  final WalkBooking walk;
  const _SimpleTile({required this.walk});

  @override
  Widget build(BuildContext context) {
    final color = switch (walk.status) {
      WalkStatus.confirmed => AppColors.green,
      WalkStatus.rejected => const Color(0xFFF7C6D9),
      _ => AppColors.background,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${walk.dogName} · ${walk.slot}',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              walk.status.label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String text;
  const _Section(this.text);

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

class _Empty extends StatelessWidget {
  final String text;
  const _Empty(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(text, style: const TextStyle(color: Colors.black54)),
    );
  }
}
