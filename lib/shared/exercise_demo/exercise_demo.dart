import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:openlifts/l10n/app_localizations.dart';
import 'package:openlifts/shared/exercise_demo/sprite_sheet.dart';

/// Plays a lift's [sheet] as a looping sprite animation. Tap to pause or
/// resume. Under reduced motion it holds the sheet's poster frame until
/// tapped.
class ExerciseDemo extends StatefulWidget {
  const ExerciseDemo({
    required this.sheet,
    required this.exerciseName,
    this.height = 220,
    super.key,
  });

  final SpriteSheet sheet;

  /// Used for the screen-reader label.
  final String exerciseName;

  final double height;

  @override
  State<ExerciseDemo> createState() => _ExerciseDemoState();
}

class _ExerciseDemoState extends State<ExerciseDemo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.sheet.period,
  )..addListener(_syncFrame);

  /// Notifies only when the frame changes, so painting runs at the sheet's
  /// fps rather than every vsync.
  final _frame = ValueNotifier<int>(0);

  /// Null until the first [didChangeDependencies] reads reduced motion.
  bool? _playing;

  ImageStream? _stream;
  ImageInfo? _image;
  late final _imageListener = ImageStreamListener(_onImage);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveSheet();
    if (_playing != null) return;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _showPoster();
    } else {
      _play();
    }
  }

  @override
  void didUpdateWidget(ExerciseDemo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sheet != widget.sheet) {
      _controller.duration = widget.sheet.period;
      _resolveSheet();
      if (_playing ?? false) {
        _play();
      } else {
        _showPoster();
      }
    }
  }

  @override
  void dispose() {
    _stream?.removeListener(_imageListener);
    _image?.dispose();
    _controller.dispose();
    _frame.dispose();
    super.dispose();
  }

  void _resolveSheet() {
    final stream = AssetImage(
      widget.sheet.asset,
    ).resolve(createLocalImageConfiguration(context));
    if (stream.key == _stream?.key) return;
    _stream?.removeListener(_imageListener);
    _stream = stream..addListener(_imageListener);
  }

  void _onImage(ImageInfo image, bool synchronousCall) {
    setState(() {
      _image?.dispose();
      _image = image;
    });
  }

  void _syncFrame() {
    final count = widget.sheet.frameCount;
    _frame.value = (_controller.value * count).floor().clamp(0, count - 1);
  }

  /// Loops until paused or disposed; nothing awaits the returned future.
  void _play() {
    final _ = _controller.repeat();
    _playing = true;
  }

  void _showPoster() {
    _controller
      ..stop()
      ..value = (widget.sheet.posterFrame + 0.5) / widget.sheet.frameCount;
    _playing = false;
  }

  void _toggle() {
    setState(() {
      if (_playing ?? false) {
        _controller.stop();
        _playing = false;
      } else {
        _play();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final playing = _playing ?? false;

    return Semantics(
      label: loc.exerciseDemoLabel(widget.exerciseName),
      button: true,
      onTap: _toggle,
      onTapHint: playing ? loc.exerciseDemoPause : loc.exerciseDemoPlay,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: _toggle,
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _SpriteFramePainter(
                      sheet: widget.sheet,
                      image: _image?.image,
                      frame: _frame,
                    ),
                  ),
                ),
              ),
              if (!playing)
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: Icon(
                    Icons.play_circle_fill_rounded,
                    key: const Key('exerciseDemoPaused'),
                    size: 32,
                    color: theme.colorScheme.primary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Copies the current frame out of the sheet — the whole sprite "engine".
class _SpriteFramePainter extends CustomPainter {
  _SpriteFramePainter({
    required this.sheet,
    required this.image,
    required this.frame,
  }) : super(repaint: frame);

  final SpriteSheet sheet;
  final ui.Image? image;
  final ValueListenable<int> frame;

  @override
  void paint(Canvas canvas, Size size) {
    final image = this.image;
    if (image == null) return;
    canvas.drawImageRect(
      image,
      sheet.frameRect(frame.value),
      sheet.destinationIn(size),
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(_SpriteFramePainter oldDelegate) =>
      oldDelegate.sheet != sheet ||
      oldDelegate.image != image ||
      oldDelegate.frame != frame;
}
