import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tape_88/app/app.dart';
import 'package:tape_88/app/di/service_locator.dart';
import 'package:tape_88/core/logging/app_logger.dart';
import 'package:tape_88/core/presentation/app_error_view.dart';
import 'package:tape_88/core/theme/app_colors.dart';
import 'package:tape_88/core/theme/app_theme.dart';

void bootstrap() {
  runZonedGuarded<void>(
    () {
      WidgetsFlutterBinding.ensureInitialized();
      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        AppLogger.error(
          'Uncaught Flutter error',
          error: details.exception,
          stackTrace: details.stack,
        );
      };
      ErrorWidget.builder = (details) => AppErrorView(details: details);
      runApp(const _BootstrapGate());
    },
    (error, stackTrace) => AppLogger.error(
      'Uncaught asynchronous error',
      error: error,
      stackTrace: stackTrace,
    ),
  );
}

class _BootstrapGate extends StatefulWidget {
  const _BootstrapGate();

  @override
  State<_BootstrapGate> createState() => _BootstrapGateState();
}

class _BootstrapGateState extends State<_BootstrapGate> {
  late final Future<void> _initialization = ServiceLocator.instance
      .initialize();

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: _initialization,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.done &&
          !snapshot.hasError) {
        return const Tape88App();
      }
      if (snapshot.hasError) {
        AppLogger.error('App initialization failed', error: snapshot.error);
      }
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/icon/icon.png',
                  width: 132,
                  filterQuality: FilterQuality.medium,
                ),
                const SizedBox(height: 24),
                if (!snapshot.hasError) ...[
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.amber,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'LOADING DECK...',
                    style: TextStyle(
                      color: AppColors.textWarm,
                      fontSize: 11,
                      letterSpacing: 1.6,
                    ),
                  ),
                ] else
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'DECK STARTUP ERROR\nPlease restart the app.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.error, height: 1.5),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
