import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tape_88/app/app.dart';
import 'package:tape_88/app/di/service_locator.dart';

void main() {
  setUpAll(() => ServiceLocator.instance.initialize(useInMemory: true));

  testWidgets('app starts with the main navigation', (tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    await tester.pumpWidget(const Tape88App());
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('RETROTAPE'), findsOneWidget);
    expect(find.text('PLAYER'), findsOneWidget);
    expect(find.text('LIBRARY'), findsOneWidget);
    expect(find.text('PLAYLISTS'), findsOneWidget);
    expect(find.text('SETTINGS'), findsOneWidget);

    await tester.tap(find.text('LIBRARY'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('MAGNETIC TAPES'), findsOneWidget);

    await tester.tap(find.text('PLAYLISTS'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('▣ CASSETTE RACK'), findsOneWidget);

    await tester.tap(find.text('SETTINGS'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('MUSIC LIBRARY'), findsOneWidget);
    expect(find.byIcon(Icons.person_outline), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.binding.setSurfaceSize(null);
  });
}
