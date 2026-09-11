import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tape_88/core/theme/app_theme.dart';
import 'package:tape_88/features/library/domain/entities/track.dart';
import 'package:tape_88/features/player/data/repositories/in_memory_audio_player_repository.dart';
import 'package:tape_88/features/player/presentation/controllers/player_controller.dart';
import 'package:tape_88/features/queue/presentation/pages/queue_page.dart';

void main() {
  testWidgets('queue supports duplicate tracks, large text, and swipe eject', (
    tester,
  ) async {
    final repository = InMemoryAudioPlayerRepository();
    final controller = PlayerController(repository);
    const track = Track(
      id: 'same-track',
      title: 'A long cassette track title for layout testing',
      artist: 'Local Artist',
      source: 'same-track.mp3',
      duration: Duration(minutes: 4),
    );
    await controller.loadQueue(const [track, track, track], initialIndex: 2);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.4)),
        child: MaterialApp(
          theme: AppTheme.dark,
          home: QueuePage(controller: controller),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('4:00'), findsNWidgets(3));
    expect(tester.takeException(), isNull);

    await tester.drag(find.byType(Dismissible).first, const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(controller.state.queue, hasLength(2));
    expect(tester.takeException(), isNull);

    controller.dispose();
    await repository.dispose();
  });

  testWidgets('queue reveals the current track when opened near the end', (
    tester,
  ) async {
    final repository = InMemoryAudioPlayerRepository();
    final controller = PlayerController(repository);
    final tracks = List.generate(
      240,
      (index) => Track(
        id: 'track-$index',
        title: 'A variable cassette title for track $index',
        artist: 'Artist $index',
        source: 'track-$index.mp3',
        duration: const Duration(minutes: 4),
      ),
    );
    await controller.loadQueue(tracks, initialIndex: 217);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.4)),
        child: MaterialApp(
          theme: AppTheme.dark,
          home: QueuePage(controller: controller),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('A variable cassette title for track 217'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    controller.dispose();
    await repository.dispose();
  });
}
