// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';

class YoutubeLivePlayer extends StatefulWidget {
  final String channelId;
  final String title;

  const YoutubeLivePlayer({
    super.key,
    required this.channelId,
    required this.title,
  });

  @override
  State<YoutubeLivePlayer> createState() => _YoutubeLivePlayerState();
}

class _YoutubeLivePlayerState extends State<YoutubeLivePlayer> {
  late final String _viewType;

  @override
  void initState() {
    super.initState();
    _viewType =
        'youtube-live-${widget.channelId}-${DateTime.now().microsecondsSinceEpoch}';

    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      return html.IFrameElement()
        ..src = Uri.https(
          'www.youtube.com',
          '/embed/live_stream',
          {
            'channel': widget.channelId,
            'autoplay': '0',
            'playsinline': '1',
            'rel': '0',
            'modestbranding': '1',
          },
        ).toString()
        ..title = widget.title
        ..allow =
            'accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share'
        ..allowFullscreen = true
        ..style.border = '0'
        ..style.width = '100%'
        ..style.height = '100%';
    });
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
      child: DecoratedBox(
        decoration: const BoxDecoration(color: AppColors.primaryDark),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: HtmlElementView(viewType: _viewType),
        ),
      ),
    );
  }
}
