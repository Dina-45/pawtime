import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'blocs/auth_cubit.dart';
import 'blocs/cart_bloc.dart';
import 'blocs/diary_cubit.dart';
import 'blocs/favorites_cubit.dart';
import 'blocs/points_cubit.dart';
import 'blocs/walks_bloc.dart';
import 'blocs/walks_state.dart';
import 'screens/login_screen.dart';
import 'theme/app_colors.dart';

void main() => runApp(const PawTimeApp());

class PawTimeApp extends StatelessWidget {
  const PawTimeApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Providers are ABOVE MaterialApp, so every screen (volunteer AND staff)
    // works with the same data.
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthCubit()),
        BlocProvider(create: (_) => FavoritesCubit()),
        BlocProvider(create: (_) => WalksBloc()),
        BlocProvider(create: (_) => PointsCubit()),
        BlocProvider(create: (_) => CartBloc()),
        BlocProvider(create: (_) => DiaryCubit()),
      ],
      // BLoC-to-BLoC connection: staff confirms a walk in WalksBloc ->
      // PointsCubit pays Paw Points for it.
      child: BlocListener<WalksBloc, WalksState>(
        listenWhen: (prev, curr) =>
            curr.withStatus(WalkStatus.confirmed).length !=
            prev.withStatus(WalkStatus.confirmed).length,
        listener: (context, state) {
          final points = context.read<PointsCubit>();
          for (final walk in state.withStatus(WalkStatus.confirmed)) {
            points.awardWalk(walk);
          }
        },
        child: MaterialApp(
          title: 'PawTime',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: AppColors.navy),
            scaffoldBackgroundColor: AppColors.background,
            useMaterial3: true,
          ),
          home: const LoginScreen(),
        ),
      ),
    );
  }
}
