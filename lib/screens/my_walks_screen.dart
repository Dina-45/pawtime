import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../blocs/diary_cubit.dart';
import '../blocs/points_cubit.dart';
import '../blocs/walks_bloc.dart';
import '../blocs/walks_event.dart';
import '../blocs/walks_state.dart';
import '../models/diary_entry.dart';
import '../models/shelter.dart';
import '../services/location_service.dart';
import '../services/media_service.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/zone_chip.dart';

// LW13: "Geotagged Photo Diary" adapted to PawTime.
// After a walk the volunteer takes a photo with the dog. The photo gets GPS
// coordinates, so staff can see the walk really happened near the shelter.
class MyWalksScreen extends StatefulWidget {
  const MyWalksScreen({super.key});

  @override
  State<MyWalksScreen> createState() => _MyWalksScreenState();
}

class _MyWalksScreenState extends State<MyWalksScreen> {
  final _captionController = TextEditingController();

  File? _photo;
  DateTime? _capturedAt;
  Position? _position;
  bool _locating = false;
  String? _locationError;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  // ---------------- Camera / Gallery ----------------

  void _chooseSource() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take photo'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Pick from gallery'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickPhoto(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final file = await MediaService.pickPhoto(source);
      if (!mounted || file == null) return; // user cancelled

      setState(() {
        _photo = file;
        _capturedAt = DateTime.now();
      });

      // Automatically geotag the new photo
      await _fetchLocation();
    } on MediaException catch (e) {
      if (!mounted) return;
      if (e.issue == MediaIssue.permanentlyDenied) {
        _showSettingsDialog(
          title: 'Camera access blocked',
          message: e.message,
          onOpen: MediaService.openSettings,
        );
      } else {
        _snack(e.message, color: Colors.red);
      }
    }
  }

  // ---------------- GPS ----------------

  Future<void> _fetchLocation() async {
    setState(() {
      _locating = true;
      _locationError = null;
    });

    try {
      final position = await LocationService.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _position = position;
        _locating = false;
      });
    } on LocationException catch (e) {
      if (!mounted) return;
      setState(() {
        _locating = false;
        _locationError = e.message;
      });

      switch (e.issue) {
        case LocationIssue.serviceDisabled:
          _showSettingsDialog(
            title: 'GPS is turned off',
            message: 'Turn on location services to geotag your walk photo.',
            onOpen: LocationService.openLocationSettings,
          );
        case LocationIssue.deniedForever:
          _showSettingsDialog(
            title: 'Location access blocked',
            message: e.message,
            onOpen: LocationService.openAppSettings,
          );
        case LocationIssue.denied:
        case LocationIssue.timeout:
        case LocationIssue.unknown:
          _snack(e.message, color: Colors.red);
      }
    }
  }

  // ---------------- Save ----------------

  void _save(WalkBooking? todayWalk) {
    final photo = _photo;
    final position = _position;
    if (photo == null) {
      _snack('Take or pick a photo first');
      return;
    }
    if (position == null) {
      _snack('Fetch your GPS location first');
      return;
    }

    // Link the photo to today's walk (booked, or rejected and sent again)
    final linkedDog = (todayWalk != null && todayWalk.canReport)
        ? todayWalk.dogName
        : null;

    final caption = _captionController.text.trim().isEmpty
        ? (linkedDog != null ? 'Walk with $linkedDog' : 'Shelter visit')
        : _captionController.text.trim();

    final entry = DiaryEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      imagePath: photo.path,
      caption: caption,
      dogName: linkedDog,
      latitude: position.latitude,
      longitude: position.longitude,
      altitude: position.altitude,
      accuracy: position.accuracy,
      distanceToShelter: LocationService.distanceToShelter(position),
      timestamp: _capturedAt ?? DateTime.now(),
    );

    context.read<DiaryCubit>().add(entry);
    if (linkedDog != null) {
      context.read<WalksBloc>().add(ReportWalkEvent(linkedDog));
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _photo = null;
      _position = null;
      _capturedAt = null;
      _locationError = null;
      _captionController.clear();
    });

    _snack(
      linkedDog != null
          ? 'Saved! Walk report sent to shelter staff.'
          : 'Saved to your diary.',
    );
  }

  // ---------------- Helpers ----------------

  void _snack(String text, {Color? color}) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(text), backgroundColor: color));
  }

  void _showSettingsDialog({
    required String title,
    required String message,
    required Future<bool> Function() onOpen,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              onOpen();
            },
            child: const Text('Open settings'),
          ),
        ],
      ),
    );
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    final todayWalk = context.watch<WalksBloc>().state.todayWalk;
    final entries = context.watch<DiaryCubit>().state;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'My Walks',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 12),
          _TodayWalkBanner(walk: todayWalk),
          const SizedBox(height: 20),
          const Text(
            '📸 Walk photo journal',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 8),
          _buildPreview(),
          const SizedBox(height: 12),
          _buildLocationInfo(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: AppColors.lime,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => _pickPhoto(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera),
                  label: const Text('Take Photo'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => _pickPhoto(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _locating ? null : _fetchLocation,
              icon: const Icon(Icons.my_location),
              label: const Text('Fetch Current GPS Location'),
            ),
          ),
          const Divider(height: 32),
          TextField(
            controller: _captionController,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Caption',
              hintText: todayWalk != null
                  ? 'Walk with ${todayWalk.dogName}'
                  : 'e.g. Morning at the shelter',
              prefixIcon: const Icon(Icons.edit_note),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 54,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.lime,
                foregroundColor: AppColors.navy,
                disabledBackgroundColor: Colors.grey.shade300,
              ),
              onPressed: (_photo != null && _position != null && !_locating)
                  ? () => _save(todayWalk)
                  : null,
              icon: const Icon(Icons.save),
              label: const Text(
                'SAVE ENTRY TO DIARY',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '📜 Diary entries (${entries.length})',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 8),
          if (entries.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No entries yet. Your walk photos will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
            )
          else
            ...entries.map(
              (e) => _DiaryTile(
                entry: e,
                onDelete: () => context.read<DiaryCubit>().remove(e.id),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    final photo = _photo;
    return GestureDetector(
      onTap: _chooseSource,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 240,
          width: double.infinity,
          color: Colors.white,
          child: photo == null
              ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_a_photo_outlined,
                      size: 56,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tap to add a photo from your walk',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                )
              : Image.file(photo, fit: BoxFit.cover),
        ),
      ),
    );
  }

  Widget _buildLocationInfo() {
    final position = _position;

    Widget child;
    if (_locating) {
      child = const Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Text('Getting GPS lock...'),
        ],
      );
    } else if (position == null) {
      child = Text(
        _locationError ?? 'No location yet. Tap "Fetch Current GPS Location".',
        style: TextStyle(
          color: _locationError != null ? Colors.red : Colors.black54,
        ),
      );
    } else {
      final distance = LocationService.distanceToShelter(position);
      final inZone = distance <= Shelter.walkZoneMeters;
      child = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow('📍 Latitude', position.latitude.toStringAsFixed(6)),
          _InfoRow('📍 Longitude', position.longitude.toStringAsFixed(6)),
          _InfoRow('⛰️ Altitude', '${position.altitude.toStringAsFixed(1)} m'),
          _InfoRow(
            '🎯 Accuracy',
            '± ${position.accuracy.toStringAsFixed(1)} m',
          ),
          if (_capturedAt != null)
            _InfoRow('⏰ Timestamp', formatDateTime(_capturedAt!)),
          const SizedBox(height: 6),
          ZoneChip(distance: distance, inZone: inZone),
        ],
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}

// ---------------- Small widgets ----------------

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: Colors.black54)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
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

class _TodayWalkBanner extends StatelessWidget {
  final WalkBooking? walk;
  const _TodayWalkBanner({required this.walk});

  @override
  Widget build(BuildContext context) {
    final w = walk;
    final (String title, String subtitle) = w == null
        ? (
            'No walk booked today',
            'Book a dog in the Feed. You can still save photos here.',
          )
        : switch (w.status) {
            WalkStatus.booked => (
              'Today: ${w.dogName} at ${w.slot}',
              'After the walk, take a photo to send your report.',
            ),
            WalkStatus.reported => (
              'Walk with ${w.dogName} reported 📨',
              'Waiting for staff to confirm. Then you get Paw Points.',
            ),
            WalkStatus.confirmed => (
              'Walk with ${w.dogName} confirmed ✅',
              '+${PointsCubit.pointsPerWalk} Paw Points added to your balance.',
            ),
            WalkStatus.rejected => (
              'Report for ${w.dogName} rejected',
              'Staff could not confirm it. Take a new photo at the shelter.',
            ),
          };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}

class _DiaryTile extends StatelessWidget {
  final DiaryEntry entry;
  final VoidCallback onDelete;
  const _DiaryTile({required this.entry, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final inZone = entry.distanceToShelter <= Shelter.walkZoneMeters;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(entry.imagePath),
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: 64,
                height: 64,
                color: AppColors.background,
                child: const Icon(Icons.broken_image, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
                Text(
                  formatCoordinates(entry.latitude, entry.longitude),
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                Text(
                  '${formatDateTime(entry.timestamp)} · ${inZone ? '🏠' : '⚠️'} ${formatDistance(entry.distanceToShelter)}',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                if (entry.dogName != null)
                  Text(
                    '🐕 ${entry.dogName}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Delete',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          ),
        ],
      ),
    );
  }
}
