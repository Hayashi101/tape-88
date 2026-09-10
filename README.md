# Tape 88

Tape 88 là ứng dụng nghe nhạc local viết bằng Flutter, lấy cảm hứng từ máy cassette và thiết bị hi-fi thập niên 1980–1990. Ứng dụng tập trung vào thư viện nhạc trên thiết bị, không sử dụng tài khoản và không phụ thuộc dịch vụ streaming.

## Tính năng hiện có

- Quét nhạc local trên Android từ `Music/` và `Download/Music/`.
- Lọc recording, ringtone, alarm, notification, podcast, audiobook và file quá ngắn/nhỏ.
- Phát, tạm dừng, seek, previous/next, shuffle và repeat.
- Phát nền bằng `audio_service`, hỗ trợ notification, lock screen và media controls.
- Đồng bộ slider với media volume hệ thống Android và phím volume vật lý.
- Queue có kéo-thả, swipe-to-eject và đánh dấu bài đang phát.
- Library, album, search, favorites, recent tracks và playlist lưu local.
- Equalizer preset native Android: Flat, Warm, Bass, Vocal và Bright.
- Khôi phục queue, bài hiện tại và tiến độ phát sau khi mở lại app.
- Giao diện cassette với reel animation, tape counter, VU meter, mini player và CRT overlay.

## Công nghệ chính

- Flutter / Dart
- `just_audio`: playback engine
- `audio_service`: background playback và media session
- `audio_session`: audio focus, headphone disconnect
- `path_provider`: lưu dữ liệu và artwork cache
- Kotlin platform channels: MediaStore, artwork và system media volume trên Android

## Yêu cầu và cách chạy

- Flutter SDK tương thích Dart `^3.12.0`
- Android SDK và thiết bị/emulator Android
- Xcode nếu chạy iOS

```bash
flutter pub get
flutter run
flutter analyze
flutter test
```

Build Android:

```bash
flutter build apk --debug
flutter build apk --release
flutter build appbundle --release
```

Build iOS simulator:

```bash
flutter build ios --simulator
```

## Định danh ứng dụng

- Android application ID: `com.tape88.app`
- iOS bundle identifier: `com.tape88.app`
- App display name: `Tape 88`

## Quyền Android

- `READ_MEDIA_AUDIO` trên Android 13 trở lên.
- `READ_EXTERNAL_STORAGE` đến Android 12.
- `FOREGROUND_SERVICE` và `FOREGROUND_SERVICE_MEDIA_PLAYBACK` cho phát nền.
- `WAKE_LOCK` để playback không bị ngắt khi màn hình tắt.

Ứng dụng chỉ đọc metadata/audio local, không upload thư viện nhạc lên máy chủ.

## Cấu trúc nhanh

```text
lib/
├── app/       # bootstrap, dependency container, router
├── core/      # theme, widgets dùng chung, Result/Failure, logging
└── features/  # albums, library, player, playlists, queue, search, settings
```

Các feature chính được tách theo hướng `presentation → domain ← data`. Dependency được ghép tại `ServiceLocator`, nhờ đó playback repository có thể thay bằng bản in-memory trong test.

Xem tài liệu chi tiết tại [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Lưu ý trước khi phát hành

- Gradle tự dùng release keystore khi có `android/key.properties`; nếu chưa có, APK release local tạm dùng debug key.
- Sao chép `android/key.properties.example` thành `android/key.properties`, điền thông tin keystore thật trước khi đưa lên Google Play. Không commit hai file bí mật này.
- Tape 88 không xin quyền thông báo thông thường. Android hiển thị playback controls thông qua foreground media session khi nhạc đang phát.
- Equalizer và system-volume synchronization hiện chỉ có implementation native Android.
- iOS cần chọn signing team và kiểm tra background audio/Control Center trên thiết bị thật.
- Việc nhảy chính xác đến bài đang phát khi mở Queue đang được để lại cho vòng cải tiến sau.
