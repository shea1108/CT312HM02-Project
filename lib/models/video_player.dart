import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class VideoPlayerModel extends ChangeNotifier {
  VideoPlayerController? _controller;
  String currentVideo = '';
  bool isMuted = false;
  List<Map<String, dynamic>> episodes = [];
  double volume = 1.0;

  VideoPlayerController? get controller => _controller;

  Future<void> fetchEpisodes(String movieId) async {
    String baseUrl = "http://10.0.2.2:8090";
    final url = Uri.parse(
        '$baseUrl/api/collections/episodes/records?filter=movies="$movieId"');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        episodes = List<Map<String, dynamic>>.from(data['items']);
        if (episodes.isNotEmpty) {
          changeVideo(episodes.first['id'], episodes.first['video']);
        }
      }
    } catch (e) {
      print('Lỗi kết nối API: $e');
    }
    notifyListeners();
  }

  void setVolume(double newVolume) {
    if (_controller != null) {
      volume = newVolume;
      _controller!.setVolume(volume);
      notifyListeners();
    }
  }

  void changeVideo(String videoId, String videoFile) {
    String baseUrl = "http://10.0.2.2:8090";
    String videoUrl = "$baseUrl/api/files/episodes/$videoId/$videoFile";
    currentVideo = videoUrl;
    _initializeVideo(videoUrl);
    notifyListeners();
  }

  Future<void> _initializeVideo(String videoUrl) async {
    if (videoUrl.isEmpty) return;

    try {
      _controller?.dispose();

      _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl))
        ..initialize().then((_) {
          _controller!.play();
          notifyListeners();
        });
    } catch (e) {
      print("Lỗi khởi tạo VideoPlayerController: $e");
    }
  }

  void togglePlayPause() {
    if (_controller?.value.isInitialized == true) {
      _controller!.value.isPlaying ? _controller!.pause() : _controller!.play();
      notifyListeners();
    }
  }

  void toggleMute() {
    if (_controller != null) {
      isMuted = !isMuted;
      _controller!.setVolume(isMuted ? 0.0 : 1.0);
      notifyListeners();
    }
  }

  void disposeController() {
    _controller?.dispose();
  }
}
