import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/duration_utils.dart';
import '../../../data/models/models.dart';

/// Video preview widget with playback controls
class VideoPreview extends StatefulWidget {
  final String videoPath;
  final Duration startTime;
  final Duration endTime;
  final AspectRatioType aspectRatio;
  final BackgroundType backgroundType;
  final Color? backgroundColor;

  const VideoPreview({
    super.key,
    required this.videoPath,
    required this.startTime,
    required this.endTime,
    required this.aspectRatio,
    required this.backgroundType,
    this.backgroundColor,
  });

  @override
  State<VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<VideoPreview> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _hasError = false;
  String? _errorMessage;
  Duration _currentPosition = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void didUpdateWidget(VideoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Seek to new start time if changed
    if (oldWidget.startTime != widget.startTime && _isInitialized) {
      _seekToStart();
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onPlayerUpdate);
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializePlayer() async {
    try {
      // Validate file exists
      final file = File(widget.videoPath);
      if (!await file.exists()) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Video file not found';
        });
        return;
      }

      final controller = VideoPlayerController.file(file);
      await controller.initialize();

      controller.addListener(_onPlayerUpdate);
      await controller.seekTo(widget.startTime);

      if (mounted) {
        setState(() {
          _controller = controller;
          _isInitialized = true;
          _currentPosition = widget.startTime;
        });
      }
    } catch (e) {
      debugPrint('Error initializing video player: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to load video: $e';
        });
      }
    }
  }

  void _onPlayerUpdate() {
    if (!mounted || _controller == null) return;

    final position = _controller!.value.position;
    final isPlaying = _controller!.value.isPlaying;

    // Stop at end time
    if (position >= widget.endTime && isPlaying) {
      _controller!.pause();
      _controller!.seekTo(widget.startTime);
    }

    if (mounted) {
      setState(() {
        _currentPosition = position;
        _isPlaying = isPlaying;
      });
    }
  }

  Future<void> _seekToStart() async {
    if (_controller != null && _isInitialized) {
      await _controller!.seekTo(widget.startTime);
    }
  }

  Future<void> _togglePlayPause() async {
    if (_controller == null || !_isInitialized) return;

    if (_isPlaying) {
      await _controller!.pause();
    } else {
      // If at end, restart from beginning
      if (_currentPosition >= widget.endTime) {
        await _controller!.seekTo(widget.startTime);
      }
      await _controller!.play();
    }
  }

  double get _aspectRatioValue {
    switch (widget.aspectRatio) {
      case AspectRatioType.portrait9x16:
        return 9 / 16;
      case AspectRatioType.square1x1:
        return 1.0;
      case AspectRatioType.landscape16x9:
        return 16 / 9;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
      ),
      child: AspectRatio(
        aspectRatio: _aspectRatioValue,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background
            _buildBackground(),

            // Video or placeholder
            if (_hasError)
              _buildErrorState()
            else if (!_isInitialized)
              _buildLoadingState()
            else
              _buildVideoPlayer(),

            // Play/pause overlay
            if (_isInitialized && !_hasError) _buildPlayPauseOverlay(),

            // Progress bar
            if (_isInitialized && !_hasError)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildProgressBar(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground() {
    switch (widget.backgroundType) {
      case BackgroundType.blur:
        if (_controller != null && _isInitialized) {
          return Positioned.fill(
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.5),
                BlendMode.darken,
              ),
              child: ImageFiltered(
                imageFilter:
                    const ColorFilter.mode(Colors.black, BlendMode.saturation),
                child: Transform.scale(
                  scale: 1.5,
                  child: VideoPlayer(_controller!),
                ),
              ),
            ),
          );
        }
        return Container(color: AppColors.backgroundDark);

      case BackgroundType.blackBars:
        return Container(color: Colors.black);

      case BackgroundType.solidColor:
        return Container(
          color: widget.backgroundColor ?? Colors.black,
        );
    }
  }

  Widget _buildLoadingState() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(AppColors.accent),
        ),
        SizedBox(height: AppConstants.paddingM),
        Text(
          'Loading video...',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.error_outline_rounded,
          size: 48,
          color: AppColors.error,
        ),
        const SizedBox(height: AppConstants.paddingM),
        Text(
          _errorMessage ?? 'Failed to load video',
          style: const TextStyle(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppConstants.paddingM),
        TextButton(
          onPressed: () {
            setState(() {
              _hasError = false;
              _errorMessage = null;
            });
            _initializePlayer();
          },
          child: const Text('RETRY'),
        ),
      ],
    );
  }

  Widget _buildVideoPlayer() {
    if (_controller == null) return const SizedBox();

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppConstants.radiusM),
      child: VideoPlayer(_controller!),
    );
  }

  Widget _buildPlayPauseOverlay() {
    return GestureDetector(
      onTap: _togglePlayPause,
      child: Container(
        color: Colors.transparent,
        child: AnimatedOpacity(
          opacity: _isPlaying ? 0.0 : 1.0,
          duration: AppConstants.animationFast,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withOpacity(0.4),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Icon(
              _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 32,
              color: AppColors.textOnAccent,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    final totalDuration = widget.endTime - widget.startTime;
    final progress = totalDuration.inMilliseconds > 0
        ? ((_currentPosition - widget.startTime).inMilliseconds /
                totalDuration.inMilliseconds)
            .clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingS),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.7),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(AppConstants.radiusM),
          bottomRight: Radius.circular(AppConstants.radiusM),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            ),
            child: Slider(
              value: progress,
              onChanged: (value) async {
                if (_controller == null) return;
                final position = widget.startTime +
                    Duration(
                      milliseconds:
                          (value * totalDuration.inMilliseconds).toInt(),
                    );
                await _controller!.seekTo(position);
              },
            ),
          ),

          // Time labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DurationUtils.formatMinutesSeconds(
                      _currentPosition - widget.startTime),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                Text(
                  DurationUtils.formatMinutesSeconds(totalDuration),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
