import 'package:flutter_test/flutter_test.dart';
import 'package:pawtime/blocs/cart_bloc.dart';
import 'package:pawtime/blocs/cart_event.dart';
import 'package:pawtime/blocs/points_cubit.dart';
import 'package:pawtime/blocs/walks_bloc.dart';
import 'package:pawtime/blocs/walks_event.dart';
import 'package:pawtime/blocs/walks_state.dart';
import 'package:pawtime/main.dart';
import 'package:pawtime/models/reward.dart';

Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  testWidgets('App starts on the login screen', (tester) async {
    await tester.pumpWidget(const PawTimeApp());
    expect(find.text('Welcome to PawTime'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });

  group('WalksBloc rules', () {
    test('one dog per day', () async {
      final bloc = WalksBloc();
      bloc.add(const BookWalkEvent(dogName: 'Max', slot: '10:00'));
      bloc.add(const BookWalkEvent(dogName: 'Luna', slot: '13:30'));
      await _settle();
      expect(bloc.state.bookings.length, 1);
      expect(bloc.state.bookingFor('Luna'), isNull);
      await bloc.close();
    });

    test(
      'booked -> reported -> confirmed, reported walk cannot be cancelled',
      () async {
        final bloc = WalksBloc();
        bloc.add(const BookWalkEvent(dogName: 'Max', slot: '10:00'));
        bloc.add(const ReportWalkEvent('Max'));
        bloc.add(const CancelWalkEvent('Max'));
        await _settle();
        final walk = bloc.state.bookingFor('Max')!;
        expect(walk.status, WalkStatus.reported);

        bloc.add(ConfirmWalkEvent(walk.id));
        await _settle();
        expect(bloc.state.bookingFor('Max')!.status, WalkStatus.confirmed);
        await bloc.close();
      },
    );

    test('staff cannot confirm a walk without a photo report', () async {
      final bloc = WalksBloc();
      bloc.add(const BookWalkEvent(dogName: 'Max', slot: '10:00'));
      await _settle();
      bloc.add(ConfirmWalkEvent(bloc.state.bookingFor('Max')!.id));
      await _settle();
      expect(bloc.state.bookingFor('Max')!.status, WalkStatus.booked);
      await bloc.close();
    });
  });

  group('Paw Points', () {
    test('confirmed walk is paid only once', () async {
      final points = PointsCubit();
      final start = points.state.balance;
      final walk = WalkBooking(
        id: 'w1',
        dogName: 'Max',
        slot: '10:00',
        date: DateTime.now(),
        status: WalkStatus.confirmed,
      );
      points.awardWalk(walk);
      points.awardWalk(walk);
      expect(points.state.balance, start + PointsCubit.pointsPerWalk);
      await points.close();
    });

    test('cannot spend more than the balance', () async {
      final points = PointsCubit();
      expect(points.spend(points.state.balance + 1, 'Too much'), isFalse);
      expect(points.spend(40, 'Volunteer pin'), isTrue);
      await points.close();
    });

    test('cart: add, no duplicates, remove', () async {
      final cart = CartBloc();
      cart.add(AddRewardEvent(shelterRewards.first));
      cart.add(AddRewardEvent(shelterRewards.first)); // no duplicates
      await _settle();
      expect(cart.state.count, 1);
      expect(cart.state.totalPrice, shelterRewards.first.cost);
      cart.add(RemoveRewardEvent(shelterRewards.first.id));
      await _settle();
      expect(cart.state.count, 0);
      await cart.close();
    });
  });
}
