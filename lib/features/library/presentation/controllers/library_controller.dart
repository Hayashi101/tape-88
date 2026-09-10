import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:tape_88/features/library/data/android_media_library.dart';
import 'package:tape_88/features/library/domain/entities/track.dart';

enum LibraryStatus { loading, ready, permissionDenied, empty, error }

final class LibraryController extends ChangeNotifier {
  LibraryController(this._mediaLibrary, [this._useDemoOnly = false]);

  final AndroidMediaLibrary _mediaLibrary;
  final bool _useDemoOnly;
  List<Track> tracks = const [];
  LibraryStatus status = LibraryStatus.loading;
  String? errorMessage;

  Future<void> initialize() async {
    if (_useDemoOnly || !Platform.isAndroid) {
      status = LibraryStatus.ready;
      notifyListeners();
      return;
    }
    try {
      if (!await _mediaLibrary.hasPermission()) {
        status = LibraryStatus.permissionDenied;
        notifyListeners();
        return;
      }
      await refresh();
    } catch (error) {
      errorMessage = error.toString();
      status = LibraryStatus.error;
      notifyListeners();
    }
  }

  Future<void> requestPermission() async {
    status = LibraryStatus.loading;
    notifyListeners();
    try {
      if (await _mediaLibrary.requestPermission()) {
        await refresh();
      } else {
        status = LibraryStatus.permissionDenied;
        notifyListeners();
      }
    } catch (error) {
      errorMessage = error.toString();
      status = LibraryStatus.error;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    status = LibraryStatus.loading;
    notifyListeners();
    try {
      tracks = await _mediaLibrary.queryTracks();
      status = tracks.isEmpty ? LibraryStatus.empty : LibraryStatus.ready;
    } catch (error) {
      errorMessage = error.toString();
      status = LibraryStatus.error;
    }
    notifyListeners();
  }
}
