import 'dart:async';

import 'package:chewie/src/center_play_button.dart';
import 'package:chewie/src/chewie_player.dart';
import 'package:chewie/src/chewie_progress_colors.dart';
import 'package:chewie/src/helpers/utils.dart';
import 'package:chewie/src/material/material_progress_bar.dart';
import 'package:chewie/src/material/models/option_item.dart';
import 'package:chewie/src/material/widgets/options_dialog.dart';
import 'package:chewie/src/models/subtitle_model.dart';
import 'package:chewie/src/notifiers/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bili_talk/util/color.dart';
import 'package:flutter_bili_talk/widget/playback_speed_dialog.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

/// 自定义播放器Controller, copy from chewie 源码
/// 支持空安全的皮肤，for chewie: > ^1.2.2

class MaterialControls extends StatefulWidget {
  //初始化时是否展示1oading
  final bool showLoadingOnInitialize;

  //是否展示大播放按钮
  final bool showBigPlayIcon;

  //视频浮层
  final Widget overlayUI;

  //底部渐变
  final Gradient bottonGradient;

  //弹幕浮层
  final Widget barrageUI;

  const MaterialControls(
      {Key key,
      this.showLoadingOnInitialize = true,
      this.showBigPlayIcon = true,
      this.overlayUI,
      this.bottonGradient,
      this.barrageUI})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _MaterialControlsState();
  }
}

class _MaterialControlsState extends State<MaterialControls>
    with SingleTickerProviderStateMixin {
  PlayerNotifier notifier;
  VideoPlayerValue _latestValue;
  Timer _hideTimer;
  Timer _initTimer;
  var _subtitlesPosition = const Duration();
  bool _subtitleOn = false;
  Timer _showAfterExpandCollapseTimer;
  bool _dragging = false;
  bool _displayTapped = false;

  final barHeight = 48.0;
  final marginSize = 5.0;

  VideoPlayerController controller;
  ChewieController _chewieController;
  // We know that _chewieController is set in didChangeDependencies
  ChewieController get chewieController => _chewieController;

  @override
  void initState() {
    super.initState();
    notifier = Provider.of<PlayerNotifier>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    if (_latestValue.hasError) {
      return chewieController.errorBuilder?.call(
            context,
            chewieController.videoPlayerController.value.errorDescription,
          ) ??
          const Center(
            child: Icon(
              Icons.error,
              color: Colors.white,
              size: 42,
            ),
          );
    }

    return MouseRegion(
      onHover: (_) {
        _cancelAndRestartTimer();
      },
      child: GestureDetector(
        onTap: () => _cancelAndRestartTimer(),
        child: AbsorbPointer(
          absorbing: notifier.hideStuff,
          child: Stack(
            children: [
              widget.barrageUI ?? Container(),
              if (_latestValue.isBuffering)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: primary,
                    ),
                  ),
                )
              else
                _buildHitArea(),
              //_buildActionBar(),
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  if (_subtitleOn)
                    Transform.translate(
                      offset: Offset(
                          0.0, notifier.hideStuff ? barHeight * 0.8 : 0.0),
                      child:
                          _buildSubtitles(context, chewieController.subtitle),
                    ),
                  _buildBottomBar(context),
                ],
              ),
              _overLayUI(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  void _dispose() {
    controller.removeListener(_updateState);
    _hideTimer?.cancel();
    _initTimer?.cancel();
    _showAfterExpandCollapseTimer?.cancel();
  }

  @override
  void didChangeDependencies() {
    final _oldController = _chewieController;
    _chewieController = ChewieController.of(context);
    controller = chewieController.videoPlayerController;

    if (_oldController != chewieController) {
      _dispose();
      _initialize();
    }

    super.didChangeDependencies();
  }

  Widget _buildActionBar() {
    return Positioned(
      top: 0,
      right: 0,
      child: SafeArea(
        child: AnimatedOpacity(
          opacity: notifier.hideStuff ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 250),
          child: Row(
            children: [
              _buildSubtitleToggle(),
              if (chewieController.showOptions) _buildOptionsButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionsButton() {
    final options = <OptionItem>[
      OptionItem(
        onTap: () async {
          Navigator.pop(context);
          _onSpeedButtonTap();
        },
        iconData: Icons.speed,
        title: chewieController.optionsTranslation?.playbackSpeedButtonText ??
            'Playback speed',
      )
    ];

    if (chewieController.subtitle != null &&
        chewieController.subtitle.isNotEmpty) {
      options.add(
        OptionItem(
          onTap: () {
            _onSubtitleTap();
            Navigator.pop(context);
          },
          iconData: _subtitleOn
              ? Icons.closed_caption
              : Icons.closed_caption_off_outlined,
          title: chewieController.optionsTranslation?.subtitlesButtonText ??
              'Subtitles',
        ),
      );
    }

    if (chewieController.additionalOptions != null &&
        chewieController.additionalOptions(context).isNotEmpty) {
      options.addAll(chewieController.additionalOptions(context));
    }

    return AnimatedOpacity(
      opacity: notifier.hideStuff ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 250),
      child: IconButton(
        onPressed: () async {
          _hideTimer?.cancel();

          if (chewieController.optionsBuilder != null) {
            await chewieController.optionsBuilder(context, options);
          } else {
            await showModalBottomSheet<OptionItem>(
              context: context,
              isScrollControlled: true,
              useRootNavigator: true,
              builder: (context) => OptionsDialog(
                options: options,
                cancelButtonText:
                    chewieController.optionsTranslation?.cancelButtonText,
              ),
            );
          }

          if (_latestValue.isPlaying) {
            _startHideTimer();
          }
        },
        icon: const Icon(
          Icons.more_vert,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSubtitles(BuildContext context, Subtitles subtitles) {
    if (!_subtitleOn) {
      return Container();
    }
    final currentSubtitle = subtitles.getByPosition(_subtitlesPosition);
    if (currentSubtitle.isEmpty) {
      return Container();
    }

    if (chewieController.subtitleBuilder != null) {
      return chewieController.subtitleBuilder(
        context,
        currentSubtitle.first.text,
      );
    }

    return Padding(
      padding: EdgeInsets.all(marginSize),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: const Color(0x96000000),
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Text(
          currentSubtitle.first.text.toString(),
          style: const TextStyle(
            fontSize: 18,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  /// 底部控制栏
  AnimatedOpacity _buildBottomBar(
    BuildContext context,
  ) {
    final iconColor = Theme.of(context).textTheme.button.color;

    return AnimatedOpacity(
      opacity: notifier.hideStuff ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        height: barHeight,
        decoration: BoxDecoration(
            //渐变
            gradient: widget.bottonGradient),
        child: Row(
          children: <Widget>[
            _buildPlayPause(controller),
            if (chewieController.isLive)
              const SizedBox()
            else
              _buildProgressBar(),
            if (chewieController.isLive)
              const Expanded(child: Text('LIVE'))
            else
              _buildPosition(iconColor),
            if (chewieController.allowFullScreen) _buildExpandButton(),
          ],
        ),
      ),
    );
  }

  /// 暂停和播放icon
  GestureDetector _buildPlayPause(VideoPlayerController controller) {
    return GestureDetector(
      onTap: _playPause,
      child: Container(
        height: barHeight,
        color: Colors.transparent,
        padding: const EdgeInsets.only(
          left: 10.0,
          right: 10.0,
        ),
        child: Icon(
          controller.value.isPlaying
              ? Icons.pause_rounded
              : Icons.play_arrow_rounded,
          color: Colors.white,
        ),
      ),
    );
  }

  GestureDetector _buildExpandButton() {
    return GestureDetector(
      onTap: _onExpandCollapse,
      child: AnimatedOpacity(
        opacity: notifier.hideStuff ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          height: barHeight + (chewieController.isFullScreen ? 15.0 : 0),
          margin: const EdgeInsets.only(right: 12.0),
          padding: const EdgeInsets.only(
            left: 8.0,
            right: 8.0,
          ),
          child: Center(
            child: Icon(
              chewieController.isFullScreen
                  ? Icons.fullscreen_exit_rounded
                  : Icons.fullscreen_rounded,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  // 点击视频空白区域会调用到
  Widget _buildHitArea() {
    final bool isFinished = _latestValue.position >= _latestValue.duration;

    return widget.showBigPlayIcon
        ? GestureDetector(
            onTap: () {
              if (_latestValue.isPlaying) {
                if (_displayTapped) {
                  setState(() {
                    notifier.hideStuff = true;
                  });
                } else {
                  _cancelAndRestartTimer();
                }
              } else {
                //点空白区域暂停播放
                //_playPause();

                setState(() {
                  notifier.hideStuff = true;
                });
              }
            },
            child: CenterPlayButton(
              backgroundColor: Colors.black54,
              iconColor: Colors.white,
              isFinished: isFinished,
              isPlaying: controller.value.isPlaying,
              show: !_dragging && !notifier.hideStuff,
              onPressed: _playPause,
            ),
          )
        : Container();
  }

  Future<void> _onSpeedButtonTap() async {
    _hideTimer?.cancel();

    final chosenSpeed = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (context) => PlaybackSpeedDialog(
        speeds: chewieController.playbackSpeeds,
        selected: _latestValue.playbackSpeed,
      ),
    );

    if (chosenSpeed != null) {
      controller.setPlaybackSpeed(chosenSpeed);
    }

    if (_latestValue.isPlaying) {
      _startHideTimer();
    }
  }

  Widget _buildPosition(Color iconColor) {
    final position = _latestValue.position;
    final duration = _latestValue.duration;

    return RichText(
      text: TextSpan(
        text: '${formatDuration(position)} ',
        children: <InlineSpan>[
          TextSpan(
            text: '/ ${formatDuration(duration)}',
            style: TextStyle(
              fontSize: 10.0,
              color: Colors.white.withOpacity(.75),
              fontWeight: FontWeight.normal,
            ),
          )
        ],
        style: const TextStyle(
          fontSize: 10.0,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSubtitleToggle() {
    //if don't have subtitle hiden button
    if (chewieController.subtitle?.isEmpty ?? true) {
      return Container();
    }
    return GestureDetector(
      onTap: _onSubtitleTap,
      child: Container(
        height: barHeight,
        color: Colors.transparent,
        padding: const EdgeInsets.only(
          left: 10.0,
          right: 10.0,
        ),
        child: Icon(
          _subtitleOn
              ? Icons.closed_caption
              : Icons.closed_caption_off_outlined,
          color: _subtitleOn ? Colors.white : Colors.grey[700],
        ),
      ),
    );
  }

  void _onSubtitleTap() {
    setState(() {
      _subtitleOn = !_subtitleOn;
    });
  }

  void _cancelAndRestartTimer() {
    _hideTimer?.cancel();
    _startHideTimer();

    setState(() {
      notifier.hideStuff = false;
      _displayTapped = true;
    });
  }

  Future<void> _initialize() async {
    _subtitleOn = chewieController.subtitle?.isNotEmpty ?? false;
    controller.addListener(_updateState);

    _updateState();

    if (controller.value.isPlaying || chewieController.autoPlay) {
      _startHideTimer();
    }

    if (chewieController.showControlsOnInitialize) {
      _initTimer = Timer(const Duration(milliseconds: 200), () {
        setState(() {
          notifier.hideStuff = false;
        });
      });
    }
  }

  void _onExpandCollapse() {
    if (chewieController.videoPlayerController.value.size == null) {
      print('_onExpandCollapse, videoPlayerController.value.size is null');
      return;
    }
    setState(() {
      notifier.hideStuff = true;

      chewieController.toggleFullScreen();
      _showAfterExpandCollapseTimer =
          Timer(const Duration(milliseconds: 300), () {
        setState(() {
          _cancelAndRestartTimer();
        });
      });
    });
  }

  void _playPause() {
    final isFinished = _latestValue.position >= _latestValue.duration;

    setState(() {
      if (controller.value.isPlaying) {
        notifier.hideStuff = false;
        _hideTimer?.cancel();
        controller.pause();
      } else {
        _cancelAndRestartTimer();

        if (!controller.value.isInitialized) {
          controller.initialize().then((_) {
            controller.play();
          });
        } else {
          if (isFinished) {
            controller.seekTo(const Duration());
          }
          controller.play();
        }
      }
    });
  }

  void _startHideTimer() {
    _hideTimer = Timer(const Duration(seconds: 3), () {
      setState(() {
        notifier.hideStuff = true;
      });
    });
  }

  void _updateState() {
    if (!mounted) return;
    setState(() {
      _latestValue = controller.value;
      _subtitlesPosition = controller.value.position;
    });
  }

  Widget _buildProgressBar() {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(right: 15, left: 15),
        child: MaterialVideoProgressBar(
          controller,
          onDragStart: () {
            setState(() {
              _dragging = true;
            });

            _hideTimer?.cancel();
          },
          onDragEnd: () {
            setState(() {
              _dragging = false;
            });

            _startHideTimer();
          },
          colors: chewieController.materialProgressColors ??
              ChewieProgressColors(
                  playedColor: Theme.of(context).accentColor,
                  handleColor: Theme.of(context).accentColor,
                  bufferedColor: Theme.of(context).backgroundColor,
                  backgroundColor: Theme.of(context).disabledColor),
        ),
      ),
    );
  }

// 控制浮层
  _overLayUI() {
    return widget.overlayUI != null
        ? AnimatedOpacity(
            opacity: notifier.hideStuff ? 0.0 : 1.0,
            duration: Duration(milliseconds: 300),
            child: widget.overlayUI)
        : Container();
  }
}
