import 'package:flutter/material.dart';
import 'package:tape_88/app/router/app_router.dart';
import 'package:tape_88/core/constants/app_constants.dart';
import 'package:tape_88/core/theme/app_theme.dart';
import 'package:tape_88/core/widgets/retro_screen_overlay.dart';

class Tape88App extends StatelessWidget {
  const Tape88App({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: AppConstants.appName,
    debugShowCheckedModeBanner: false,
    theme: AppTheme.dark,
    initialRoute: AppRoutes.home,
    onGenerateRoute: AppRouter.onGenerateRoute,
    builder: (context, child) =>
        RetroScreenOverlay(child: child ?? const SizedBox.shrink()),
  );
}
