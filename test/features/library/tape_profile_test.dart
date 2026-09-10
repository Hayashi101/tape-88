import 'package:flutter_test/flutter_test.dart';
import 'package:tape_88/features/library/domain/entities/tape_profile.dart';
import 'package:tape_88/features/library/domain/entities/track.dart';

void main() {
  Track track({String? mimeType, int? bitrate}) => Track(
    id: '1',
    title: 'Track',
    artist: 'Artist',
    source: 'track',
    duration: const Duration(minutes: 3),
    mimeType: mimeType,
    bitrate: bitrate,
  );

  test('maps ordinary or unknown lossy audio to Type I', () {
    expect(
      track(mimeType: 'audio/mpeg', bitrate: 192000).tapeProfile,
      TapeProfile.typeI,
    );
    expect(track().tapeProfile, TapeProfile.typeI);
  });

  test('maps lossless or high bitrate audio to Type II', () {
    expect(track(mimeType: 'audio/flac').tapeProfile, TapeProfile.typeII);
    expect(
      track(mimeType: 'audio/mpeg', bitrate: 320000).tapeProfile,
      TapeProfile.typeII,
    );
    expect(
      track(mimeType: 'audio/x-aiff', bitrate: 128000).tapeProfile,
      TapeProfile.typeII,
    );
    expect(
      track(mimeType: 'audio/mpeg', bitrate: 256000).tapeProfile,
      TapeProfile.typeII,
    );
  });

  test('shows the digital source quality used by the virtual profile', () {
    expect(track(mimeType: 'audio/flac').sourceQualityLabel, 'LOSSLESS SOURCE');
    expect(
      track(mimeType: 'audio/mpeg', bitrate: 320000).sourceQualityLabel,
      '320 KBPS SOURCE',
    );
    expect(track().sourceQualityLabel, 'QUALITY UNKNOWN');
  });
}
