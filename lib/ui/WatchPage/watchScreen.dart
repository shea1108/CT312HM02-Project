import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../models/video_player.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String movieId;

  const VideoPlayerScreen({super.key, required this.movieId});

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  bool showVolumeSlider = false; // Biến kiểm soát thanh slider

  @override
  void initState() {
    super.initState();
    Provider.of<VideoPlayerModel>(context, listen: false)
        .fetchEpisodes(widget.movieId);
  }

  @override
  void dispose() {
    context.read<VideoPlayerModel>().disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VideoPlayerModel>(
      builder: (context, videoModel, child) {
        String currentTitle = 'Đang tải...';
        if (videoModel.episodes.isNotEmpty) {
          final episode = videoModel.episodes.firstWhere(
              (e) => "${videoModel.currentVideo}".contains(e['video']),
              orElse: () => {'title': 'Không có dữ liệu'});
          currentTitle = episode['title'] ?? 'Không có dữ liệu';
        }

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.onPrimary,
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.onPrimary,
            title: Text(
              'Xem Phim',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
          body: Column(
            children: [
              AspectRatio(
                aspectRatio: videoModel.controller?.value.isInitialized == true
                    ? videoModel.controller!.value.aspectRatio
                    : 16 / 9,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    videoModel.controller?.value.isInitialized == true
                        ? VideoPlayer(videoModel.controller!)
                        : Center(
                            child: CircularProgressIndicator(
                                color:
                                    Theme.of(context).colorScheme.secondary)),
                    Positioned(
                      bottom: 20,
                      left: 20,
                      child: IconButton(
                        icon: Icon(
                            videoModel.controller?.value.isPlaying == true
                                ? Icons.pause
                                : Icons.play_arrow,
                            color: Theme.of(context).colorScheme.secondary,
                            size: 40),
                        onPressed: videoModel.togglePlayPause,
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      right: 20,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            showVolumeSlider = !showVolumeSlider;
                          });
                        },
                        child: Icon(
                          Icons.volume_up,
                          color: Theme.of(context).colorScheme.secondary,
                          size: 40,
                        ),
                      ),
                    ),

                    // Thanh chỉnh âm lượng chỉ hiển thị trong trang VideoPlayerScreen
                    if (showVolumeSlider)
                      Positioned(
                        bottom: 70,
                        right: 25,
                        child: StatefulBuilder(
                          builder: (context, setStateSlider) {
                            return Container(
                              height: 150,
                              width: 40,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.onPrimary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: RotatedBox(
                                quarterTurns: -1,
                                child: Slider(
                                  value: videoModel.volume,
                                  min: 0.0,
                                  max: 1.0,
                                  divisions: 10,
                                  label:
                                      "${(videoModel.volume * 100).round()}%",
                                  onChanged: (newVolume) {
                                    videoModel.setVolume(newVolume);
                                    setStateSlider(
                                        () {}); // Cập nhật UI của slider
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              if (videoModel.controller != null)
                VideoProgressIndicator(videoModel.controller!,
                    allowScrubbing: true,
                    colors: VideoProgressColors(
                        playedColor: Theme.of(context).colorScheme.primary)),
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  currentTitle,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                  child: ListView.builder(
                    itemCount: videoModel.episodes.length,
                    itemBuilder: (context, index) {
                      String videoId = videoModel.episodes[index]['id'];
                      String videoFile = videoModel.episodes[index]['video'];
                      String title = videoModel.episodes[index]['title'];
                      return ListTile(
                        title: Text(
                          title,
                          style: Theme.of(context).textTheme.bodyLarge, 
                        ),
                        trailing: videoModel.currentVideo.contains(videoFile)
                            ? Icon(Icons.play_arrow,
                                color: Theme.of(context).colorScheme.primary)
                            : null,
                        onTap: () => videoModel.changeVideo(videoId, videoFile),
                      );
                    },
                  ),
              ),
            ],
          ),
        );
      },
    );
  }
}
