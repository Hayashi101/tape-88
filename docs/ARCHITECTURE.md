# Tape 88 — Architecture & Engineering Guide

Tài liệu này mô tả cấu trúc, luồng dữ liệu, thành phần native và những điểm cần lưu ý khi tiếp tục phát triển Tape 88.

## 1. Mục tiêu sản phẩm

Tape 88 là music player cá nhân chạy nhạc local. App không có authentication, cloud backend hay streaming catalog. Thiết kế mô phỏng cassette nhưng các thao tác chính vẫn tuân theo UX điện thoại hiện đại.

Các trạng thái quan trọng cần luôn hoạt động: chưa cấp quyền, thư viện rỗng, đang quét, quét lỗi; không có tape, loading, paused, playing, completed, playback error; foreground, background, khóa màn hình và ngắt tai nghe.

## 2. Kiến trúc tổng thể

```text
Flutter UI
   │
   ▼
Presentation controllers (ChangeNotifier)
   │
   ▼
Domain repository contracts + entities
   ▲
   │
Data repositories / platform services
   │
   ├── just_audio + audio_service
   ├── JSON files in app support directory
   └── Android MethodChannel / EventChannel
```

Quy tắc phụ thuộc:

- `presentation` biết controller và domain entity.
- `domain` không phụ thuộc Flutter UI hoặc platform implementation.
- `data` triển khai repository contract và giao tiếp plugin/native.
- `app/di/service_locator.dart` là composition root, nơi ghép implementation thật.

Project chưa dùng code generation hoặc dependency-injection package. `ServiceLocator` được giữ đơn giản vì quy mô ứng dụng cá nhân.

## 3. Bootstrap và dependency lifecycle

Điểm vào là `lib/main.dart`, sau đó chuyển đến `app/bootstrap/bootstrap.dart`.

Bootstrap thực hiện:

1. Khởi tạo Flutter binding trong cùng zone với `runApp`.
2. Đăng ký global Flutter error handler.
3. Render `_BootstrapGate` ngay để Android nhận frame đầu tiên.
4. Khởi tạo service bất đồng bộ và hiển thị `LOADING DECK...` trong lúc chờ.
5. Chuyển sang `Tape88App` khi dependency sẵn sàng.

Không đưa I/O nặng lên Android main thread. MediaStore scan chạy trong executor Kotlin để tránh treo splash/pre-draw. Khi thêm service mới, khởi tạo tại `ServiceLocator` và dispose theo thứ tự ngược lại.

## 4. Player và background audio

Các file chính:

- `player/domain/entities/playback_state.dart`: state duy nhất của player.
- `player/domain/repositories/audio_player_repository.dart`: playback contract.
- `player/data/services/tape_audio_handler.dart`: `BaseAudioHandler`, media session và `AudioPlayer`.
- `player/data/repositories/just_audio_player_repository.dart`: ánh xạ engine stream sang `PlaybackState`.
- `player/presentation/controllers/player_controller.dart`: API cho UI.
- `player/presentation/controllers/playback_session_controller.dart`: lưu/khôi phục phiên phát.

```text
UI action
  → PlayerController
  → AudioPlayerRepository
  → TapeAudioHandler
  → just_audio
  → player streams
  → PlaybackState
  → ChangeNotifier
  → UI rebuild
```

`TapeAudioHandler` publish `MediaItem` và playback state cho notification/lock screen. Artwork được cache thành file local trước khi gửi sang media session nhằm tránh URI không đọc được từ background service.

`audio_session` xử lý audio focus. Khi tai nghe bị rút, `becomingNoisyEventStream` tự pause. Notification config phải giữ cặp hợp lệ: `androidNotificationOngoing: true` và `androidStopForegroundOnPause: true`.

## 5. Library và artwork

Android dùng `MediaStore.Audio.Media` qua channel `tape_88/media_library`.

Bộ lọc hiện tại:

- `IS_MUSIC != 0`.
- Không ringtone, alarm, notification, podcast hoặc audiobook.
- Thời lượng tối thiểu 30 giây và dung lượng tối thiểu 300 KB.
- Android 10+: chỉ `Music/` và `Download/Music/`.
- Loại thêm các path chứa recording, recorder và voice.

`LibraryController` quản lý `loading`, `ready`, `permissionDenied`, `empty` và `error`. Page không gọi channel trực tiếp.

Artwork:

- `TrackArtwork` hiển thị thumbnail và placeholder.
- `AndroidArtworkCache` yêu cầu native side trích embedded artwork/album art.
- Artwork I/O chạy bằng executor, không chạy trên UI thread.
- Không decode ảnh đầy đủ hoặc gọi platform channel lặp lại trong `build`.

## 6. Queue

- `ReorderableListView` hỗ trợ kéo-thả.
- Swipe phải-sang-trái để eject một track.
- Item key hỗ trợ cùng một bài xuất hiện nhiều lần.
- Repository cập nhật queue state kiểu optimistic trước khi chờ audio engine và rollback khi thất bại.
- Không ép chiều cao item vì accessibility font scale có thể gây overflow.
- Cơ chế jump chính xác tới current item chưa hoàn thiện và đang nằm trong backlog.

## 7. Dữ liệu local

Playlist, favorites, recent, search history, settings và playback session được lưu bằng repository file JSON trong app support directory.

Khi schema thay đổi, cần bổ sung migration hoặc default an toàn để dữ liệu cũ không làm app startup thất bại. Không lưu đường dẫn cache tạm làm định danh duy nhất; track ID/source phải được resolve lại với thư viện hiện tại.

## 8. Settings, volume và equalizer

- Volume Android đồng bộ với `AudioManager.STREAM_MUSIC`.
- `EventChannel` nhận thay đổi từ phím volume vật lý và cập nhật Flutter state.
- Equalizer dùng `AndroidEqualizer` trong audio pipeline của `just_audio`.
- Preset hiện có: Flat, Warm, Bass, Vocal và Bright.
- DSP chỉ bật khi preset khác Flat.

Trên iOS, volume vẫn là player volume nội bộ. iOS không cung cấp API công khai tương đương để app tùy ý thay system volume.

## 9. Native channels Android

Native implementation: `android/app/src/main/kotlin/com/tape88/app/MainActivity.kt`.

| Channel | Loại | Chức năng |
| --- | --- | --- |
| `tape_88/media_library` | MethodChannel | permission, query tracks, artwork load/cache |
| `tape_88/device_volume` | MethodChannel | đọc và đặt media volume |
| `tape_88/device_volume_changes` | EventChannel | phát sự kiện khi system volume đổi |

Nếu đổi channel, phải đổi đồng thời Kotlin và Dart client. `MissingPluginException` thường có nghĩa native build cũ vẫn đang chạy; cần full restart/reinstall thay vì hot reload.

## 10. Widget cần lưu ý

### `CassetteDeck`

Visual trung tâm của Now Playing. Reel animation phải dừng khi pause và tránh repaint toàn trang. Kiểm tra profile mode sau khi sửa painter/animation.

### `VuMeter`

Phản hồi thị giác theo playback, chưa phải dữ liệu PCM analyzer chính xác.

### `MiniPlayer`

Neo phía trên navigation ở màn hình ngoài Now Playing. Ưu tiên listener hẹp để position tick không rebuild danh sách lớn.

### `TrackArtwork`

Điểm dễ gây giật khi scroll. Giữ thumbnail nhỏ, cache kết quả và tránh platform call lặp trong `build`.

### `RetroHeader`

Header dùng chung có logo cassette asset. Khi thay logo phải cập nhật `pubspec.yaml` và kiểm tra trên màn hình mật độ cao.

### `RetroPanel`

Surface dùng chung cho card/panel. Không ép chiều cao cố định nếu chứa text chịu ảnh hưởng bởi accessibility font scale.

### `RetroDialog`, `RetroActionSheet`, `RetroNotice`

Dùng thay cho dialog/snackbar mặc định để giữ style nhất quán. Action phá hủy dùng coral và nội dung xác nhận rõ ràng.

### `RetroScreenOverlay`

CRT scanline/vignette là painter tĩnh trong `RepaintBoundary`. Không thêm animation toàn màn hình vì sẽ làm list và artwork repaint liên tục.

## 11. Cassette metadata mô phỏng

`TapeProfile` chỉ là visual profile, không phải metadata cassette thật:

- Lossless hoặc bitrate từ 256 kbps: Type II / 70µs.
- Các nguồn còn lại: Type I / 120µs.

File digital không chứa bias/equalization cassette vật lý. UI cần tiếp tục thể hiện đây là quy tắc mô phỏng.

## 12. Cấu hình Android

- Namespace/application ID: `com.tape88.app`.
- Display name: `Tape 88`.
- Activity kế thừa `AudioServiceActivity`.
- Manifest khai báo audio service và media-button receiver.
- Quyền: `READ_MEDIA_AUDIO`, legacy storage, wake lock và media playback foreground service.
- Adaptive icon dùng foreground cassette và nền `#121316`; launcher như ColorOS có thể áp mask riêng.
- Tape 88 không xin quyền notification thông thường; playback controls được Android dựng từ foreground media session đang active.
- `android/app/src/main/res/raw/keep.xml` giữ các drawable control của `audio_service`; plugin tra icon theo tên runtime nên release resource shrinker không được phép loại chúng.
- Gradle dùng release signing khi có `android/key.properties`; nếu thiếu file, build local fallback sang debug signing.

Trước Google Play:

1. Tạo upload/release keystore ngoài repository.
2. Sao chép `android/key.properties.example` thành `android/key.properties` và điền signing credentials; file này được ignore.
3. Đặt keystore theo đường dẫn khai báo trong `storeFile`.
4. Tăng `version` trong `pubspec.yaml`.
5. Build `flutter build appbundle --release`.
6. Kiểm tra notification permission theo target Android hiện hành.

Không commit `local.properties`, keystore, signing password hoặc build output.

## 13. Cấu hình iOS

- Bundle identifier: `com.tape88.app`.
- Display name: `Tape 88`.
- `UIBackgroundModes` có `audio`.
- App icon nằm trong `Runner/Assets.xcassets/AppIcon.appiconset`.

Trước khi chạy máy thật/phát hành:

1. Chọn Apple Development Team trong Xcode.
2. Đảm bảo bundle ID thuộc tài khoản Apple Developer.
3. Test Control Center, lock screen và headphone controls trên máy thật.
4. Kiểm tra signing cho Debug/Profile/Release.
5. Archive và validate bằng Xcode.

## 14. Theme và asset

Palette trong `core/theme/app_colors.dart`:

- Charcoal/background: `#121316`
- Amber: `#FF9F1C`
- Amber soft: `#FFC68B`
- Muted cyan: `#4FDBCC`
- Coral/error: `#FF9996`

Logo nguồn nằm trong `assets/branding/`. Android launcher có foreground riêng cho adaptive safe zone; iOS dùng bộ icon trong asset catalog.

## 15. Testing và hiệu năng

Test hiện phủ Result, player/queue, playback restoration, playlist CRUD, favorites, recent, TapeProfile, settings, Queue widget và app smoke test.

```bash
flutter analyze
flutter test
flutter build apk --debug
```

Với thay đổi native, hot reload chưa đủ; cần full restart hoặc cài lại APK.

Nguyên tắc hiệu năng:

- Dùng `trackStateChanges` cho list không cần position tick.
- Cache artwork và decode theo kích thước hiển thị.
- Không query MediaStore/decode bitmap trên Android main thread.
- Dùng `RepaintBoundary` cho painter/animation đắt.
- Audit bằng Flutter DevTools ở profile mode trong lúc vừa play vừa scroll.

## 16. Giới hạn và backlog

- Queue chưa jump chính xác tới current item với danh sách chiều cao động.
- VU meter chưa phân tích PCM thật.
- System volume sync và equalizer chỉ triển khai Android.
- Cần tạo release keystore thật và `android/key.properties` trước khi phát hành Google Play.
- iOS background playback cần test đầy đủ trên thiết bị thật.
- Cần stress test với hàng nghìn track và cache artwork lớn.
- Chưa có migration version chính thức cho file JSON local.
