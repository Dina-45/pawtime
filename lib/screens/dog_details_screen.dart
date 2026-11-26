import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/walks_bloc.dart';
import '../blocs/walks_event.dart';
import '../blocs/walks_state.dart';
import '../models/dog.dart';
import '../theme/app_colors.dart';
import '../widgets/dog_image.dart';

class DogDetailsScreen extends StatefulWidget {
  final Dog dog;

  const DogDetailsScreen({super.key, required this.dog});

  @override
  State<DogDetailsScreen> createState() => _DogDetailsScreenState();
}

class _DogDetailsScreenState extends State<DogDetailsScreen> {
  static const _slots = ['10:00', '13:30', '17:00'];

  // Only the chosen chip is local UI state. The booking itself is in WalksBloc.
  String? _selectedSlot;

  void _book() {
    final slot = _selectedSlot;
    if (slot == null) return;
    context.read<WalksBloc>().add(
      BookWalkEvent(dogName: widget.dog.name, slot: slot),
    );
  }

  void _cancel() {
    context.read<WalksBloc>().add(CancelWalkEvent(widget.dog.name));
    setState(() => _selectedSlot = null);
  }

  void _snack(String text, {Color? color}) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(text), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    final dog = widget.dog;
    final imageHeight = MediaQuery.of(context).size.height * 0.38;

    return BlocConsumer<WalksBloc, WalksState>(
      // React only to: an error, or THIS dog becoming booked
      listenWhen: (prev, curr) =>
          curr.error != null ||
          (prev.bookingFor(dog.name) == null &&
              curr.bookingFor(dog.name) != null),
      listener: (context, state) {
        if (state.error != null) {
          _snack(state.error!, color: Colors.red);
        } else {
          final b = state.bookingFor(dog.name)!;
          _snack(
            'Walk with ${dog.name} booked for ${b.slot}! '
            'Staff will confirm your visit at the shelter.',
          );
        }
      },
      builder: (context, state) {
        final booking = state.bookingFor(dog.name);
        final today = state.todayWalk;
        final booked = booking != null;
        // Rule "one dog per day": another dog is already booked today
        final busyWithOther = !booked && today != null;
        final shownSlot = booking?.slot ?? _selectedSlot;

        String buttonText;
        if (booking != null) {
          buttonText = booking.status == WalkStatus.booked
              ? 'Walk booked at ${booking.slot}'
              : '${booking.slot} · ${booking.status.label}';
        } else if (today != null) {
          buttonText = 'You walk ${today.dogName} today';
        } else if (_selectedSlot == null) {
          buttonText = 'Choose a time';
        } else {
          buttonText = 'Book a Walk at $_selectedSlot';
        }

        final canBook = !booked && !busyWithOther && _selectedSlot != null;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              dog.name,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            backgroundColor: AppColors.background,
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(32),
                            ),
                            child: DogImage(
                              dog: dog,
                              width: double.infinity,
                              height: imageHeight,
                              iconSize: 80,
                            ),
                          ),
                          Positioned(
                            bottom: 16,
                            left: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.lime,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                dog.age,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.navy,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dog.name,
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                color: AppColors.navy,
                              ),
                            ),
                            Text(
                              '${dog.breed} · ${dog.age} · Energy: ${dog.energy}',
                              style: const TextStyle(color: Colors.black54),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: dog.tags
                                  .map(
                                    (t) => Chip(
                                      label: Text(t),
                                      backgroundColor: Colors.white,
                                      side: BorderSide.none,
                                    ),
                                  )
                                  .toList(),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              dog.description,
                              style: const TextStyle(height: 1.4),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Good to know',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.navy,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('• One dog per day'),
                                  SizedBox(height: 4),
                                  Text('• Each dog can be booked only once'),
                                  SizedBox(height: 4),
                                  Text(
                                    '• Staff approval required before the walk',
                                  ),
                                  SizedBox(height: 4),
                                  Text('• Walks only near the shelter (1 km)'),
                                  SizedBox(height: 4),
                                  Text(
                                    '• After the walk, send a photo report in "My Walks"',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Available today',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.navy,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (booking != null)
                              const Padding(
                                padding: EdgeInsets.only(bottom: 8),
                                child: Text(
                                  'You have booked this dog.',
                                  style: TextStyle(color: Colors.black54),
                                ),
                              )
                            else if (today != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  'One dog per day: you already walk ${today.dogName} at ${today.slot}.',
                                  style: const TextStyle(color: Colors.black54),
                                ),
                              ),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _slots.map((slot) {
                                final selected = slot == shownSlot;
                                final locked = booked || busyWithOther;
                                return GestureDetector(
                                  onTap: locked
                                      ? null
                                      : () => setState(
                                          () => _selectedSlot = slot,
                                        ),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? AppColors.navy
                                          : (locked
                                                ? Colors.grey.shade200
                                                : Colors.white),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Text(
                                      slot,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: selected
                                            ? Colors.white
                                            : AppColors.navy,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            if (booking != null && booking.canCancel) ...[
                              const SizedBox(height: 12),
                              TextButton.icon(
                                onPressed: _cancel,
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.red,
                                ),
                                label: const Text(
                                  'Cancel booking',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.navy,
                        foregroundColor: AppColors.lime,
                        disabledBackgroundColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      onPressed: canBook ? _book : null,
                      child: Text(
                        buttonText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
