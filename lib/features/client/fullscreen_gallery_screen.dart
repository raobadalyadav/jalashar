import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';

class FullscreenGalleryScreen extends StatefulWidget {
  const FullscreenGalleryScreen({
    super.key,
    required this.urls,
    required this.initialIndex,
    this.vendorName,
  });

  final List<String> urls;
  final int initialIndex;
  final String? vendorName;

  @override
  State<FullscreenGalleryScreen> createState() => _FullscreenGalleryScreenState();
}

class _FullscreenGalleryScreenState extends State<FullscreenGalleryScreen> {
  late final PageController _ctrl;
  late int _current;
  bool _showUI = true;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _ctrl = PageController(initialPage: widget.initialIndex);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => setState(() => _showUI = !_showUI),
        child: Stack(
          children: [
            // Photo pages with pinch-zoom
            PageView.builder(
              controller: _ctrl,
              itemCount: widget.urls.length,
              onPageChanged: (i) => setState(() => _current = i),
              itemBuilder: (_, i) => InteractiveViewer(
                minScale: 0.8,
                maxScale: 4,
                child: CachedNetworkImage(
                  imageUrl: widget.urls[i],
                  fit: BoxFit.contain,
                  placeholder: (c, u) => const Center(
                    child: CircularProgressIndicator(color: AppColors.violet),
                  ),
                  errorWidget: (c, u, e) => const Center(
                    child: Icon(Icons.broken_image_outlined,
                        color: Colors.white54, size: 60),
                  ),
                ),
              ),
            ),

            // Top bar
            AnimatedOpacity(
              opacity: _showUI ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black87, Colors.transparent],
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          widget.vendorName ?? 'Portfolio',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${_current + 1} / ${widget.urls.length}',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom dot indicators
            if (widget.urls.length > 1)
              AnimatedOpacity(
                opacity: _showUI ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: Positioned(
                  bottom: 32,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(widget.urls.length, (i) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: i == _current ? 20 : 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: i == _current
                              ? AppColors.violet
                              : Colors.white38,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                ),
              ),

            // Left / Right chevrons
            if (widget.urls.length > 1) ...[
              if (_current > 0)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: () => _ctrl.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: const Icon(Icons.chevron_left_rounded,
                            color: Colors.white70, size: 36),
                      ),
                    ),
                  ),
                ),
              if (_current < widget.urls.length - 1)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: () => _ctrl.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: const Icon(Icons.chevron_right_rounded,
                            color: Colors.white70, size: 36),
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
