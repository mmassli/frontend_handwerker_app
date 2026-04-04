import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:video_player/video_player.dart';
import 'package:handwerker_app/core/constants/app_environment.dart';
import 'package:handwerker_app/core/theme/app_theme.dart';
import 'package:handwerker_app/core/animations/micro_animations.dart';
import 'package:handwerker_app/data/models/models.dart';
import 'package:handwerker_app/data/providers/app_providers.dart';

// ─────────────────────────────────────────────────────────────
// Media URL resolver
// The backend sometimes returns paths relative to the server root
// (e.g. "/uploads/media/…") instead of absolute URLs.
// ─────────────────────────────────────────────────────────────
String _resolveMediaUrl(String raw) {
  if (raw.isEmpty) return raw;
  if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
  // Strip /api/vX suffix to get the bare server root
  final base = AppEnvironment.baseUrl; // e.g. http://192.168.178.54:3000/api/v1
  final apiIdx = base.indexOf('/api/');
  final serverRoot = apiIdx >= 0 ? base.substring(0, apiIdx) : base;
  return raw.startsWith('/') ? '$serverRoot$raw' : '$serverRoot/$raw';
}

// ─────────────────────────────────────────────────────────────
// Main screen
// ─────────────────────────────────────────────────────────────
class JobRequestScreen extends ConsumerStatefulWidget {
  final String orderId;
  const JobRequestScreen({super.key, required this.orderId});

  @override
  ConsumerState<JobRequestScreen> createState() => _JobRequestScreenState();
}

class _JobRequestScreenState extends ConsumerState<JobRequestScreen> {
  final _priceController = TextEditingController();
  final _etaController = TextEditingController();
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _priceController.dispose();
    _etaController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final price = double.tryParse(_priceController.text);
    final eta = int.tryParse(_etaController.text);
    if (price == null || eta == null) return;

    setState(() => _isSubmitting = true);
    try {
      await ref.read(apiServiceProvider).submitProposal(
            widget.orderId,
            price: price,
            etaMinutes: eta,
            comment: _commentController.text.isEmpty
                ? null
                : _commentController.text,
          );
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fehler beim Senden')),
        );
      }
    }
    if (mounted) setState(() => _isSubmitting = false);
  }

  void _openMedia(BuildContext context, OrderMedia media) {
    final url = media.fileUrl == null ? null : _resolveMediaUrl(media.fileUrl!);
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medien-URL nicht verfügbar')),
      );
      return;
    }
    final type = media.type?.toUpperCase() ?? 'PHOTO';
    if (type == 'VIDEO') {
      showDialog(
        context: context,
        builder: (_) => _VideoPlayerDialog(url: url),
      );
    } else if (type == 'AUDIO') {
      showModalBottomSheet(
        context: context,
        backgroundColor: AppTheme.slate800,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => _AudioPlayerSheet(url: url),
      );
    } else {
      showDialog(
        context: context,
        builder: (_) => _ImageViewerDialog(url: url),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderDetailProvider(widget.orderId));

    return Scaffold(
      backgroundColor: AppTheme.slate900,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Auftragsanfrage'),
      ),
      body: orderAsync.when(
        data: (order) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Order info card ─────────────────────────────
              SlideUpFadeIn(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.slate800,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                    border: Border.all(color: AppTheme.slate700),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type badge + PLZ row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: order.requestType == RequestType.immediate
                                  ? AppTheme.error.withValues(alpha: 0.12)
                                  : AppTheme.info.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              order.requestType == RequestType.immediate
                                  ? '⚡ SOFORT'
                                  : '📅 GEPLANT',
                              style: TextStyle(
                                fontFamily: AppTheme.bodyFont,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: order.requestType == RequestType.immediate
                                    ? AppTheme.error
                                    : AppTheme.info,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          const Spacer(),
                          // PLZ: prefer new postleitzahl field, fallback to location
                          if ((order.postleitzahl ??
                                  order.location?.postalCode) !=
                              null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.location_on_outlined,
                                    size: 13, color: AppTheme.slate400),
                                const SizedBox(width: 3),
                                Text(
                                  order.postleitzahl ??
                                      order.location!.postalCode!,
                                  style: const TextStyle(
                                    fontFamily: AppTheme.bodyFont,
                                    fontSize: 13,
                                    color: AppTheme.slate400,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── Category name ─────────────────────
                      // Prefer nested serviceCategory, fall back to flat fields
                      Text(
                        order.serviceCategory?.nameDE ??
                            order.serviceCategoryNameDe ??
                            order.serviceCategory?.nameEN ??
                            'Unbekannte Kategorie',
                        style: const TextStyle(
                          fontFamily: AppTheme.displayFont,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.slate100,
                          letterSpacing: -0.5,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ── Description ───────────────────────
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.slate900.withValues(alpha: 0.5),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSM),
                        ),
                        child: Text(
                          (order.description?.trim().isNotEmpty ?? false)
                              ? order.description!
                              : 'Keine Beschreibung angegeben.',
                          style: TextStyle(
                            fontFamily: AppTheme.bodyFont,
                            fontSize: 14,
                            color: (order.description?.trim().isNotEmpty ??
                                    false)
                                ? AppTheme.slate300
                                : AppTheme.slate500,
                            height: 1.5,
                            fontStyle:
                                (order.description?.trim().isNotEmpty ?? false)
                                    ? FontStyle.normal
                                    : FontStyle.italic,
                          ),
                        ),
                      ),

                      // ── Media ─────────────────────────────
                      if (order.mediaFiles?.isNotEmpty ?? false) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Text(
                              'MEDIEN',
                              style: TextStyle(
                                fontFamily: AppTheme.bodyFont,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.slate500,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '(${order.mediaFiles!.length} Dateien – antippen zum Öffnen)',
                              style: const TextStyle(
                                fontFamily: AppTheme.bodyFont,
                                fontSize: 10,
                                color: AppTheme.slate600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 72,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: order.mediaFiles!.length,
                            itemBuilder: (ctx, i) {
                              final media = order.mediaFiles![i];
                              final isVideo =
                                  media.type?.toUpperCase() == 'VIDEO';
                              final isAudio =
                                  media.type?.toUpperCase() == 'AUDIO';
                              final isPhoto = !isVideo && !isAudio;

                              return GestureDetector(
                                onTap: () => _openMedia(context, media),
                                child: Container(
                                  width: 72,
                                  margin: const EdgeInsets.only(right: 10),
                                  decoration: BoxDecoration(
                                    color: isVideo
                                        ? AppTheme.info.withValues(alpha: 0.12)
                                        : isAudio
                                            ? AppTheme.success
                                                .withValues(alpha: 0.12)
                                            : AppTheme.slate700,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isVideo
                                          ? AppTheme.info.withValues(alpha: 0.4)
                                          : isAudio
                                              ? AppTheme.success
                                                  .withValues(alpha: 0.4)
                                              : AppTheme.amber
                                                  .withValues(alpha: 0.3),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // For photos: try to show thumbnail
                                      if (isPhoto && media.fileUrl != null)
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          child: CachedNetworkImage(
                                            imageUrl: _resolveMediaUrl(media.fileUrl!),
                                            width: 72,
                                            height: 72,
                                            fit: BoxFit.cover,
                                            placeholder: (_, __) => const Icon(
                                                Icons.image_rounded,
                                                color: AppTheme.slate400,
                                                size: 28),
                                            errorWidget: (_, __, ___) =>
                                                const Icon(Icons.image_rounded,
                                                    color: AppTheme.slate400,
                                                    size: 28),
                                          ),
                                        )
                                      else
                                        Icon(
                                          isVideo
                                              ? Icons.videocam_rounded
                                              : isAudio
                                                  ? Icons.mic_rounded
                                                  : Icons.image_rounded,
                                          color: isVideo
                                              ? AppTheme.info
                                              : isAudio
                                                  ? AppTheme.success
                                                  : AppTheme.amber,
                                          size: 28,
                                        ),
                                      // Play overlay for video/audio
                                      if (isVideo || isAudio)
                                        Positioned(
                                          bottom: 4,
                                          right: 4,
                                          child: Container(
                                            width: 20,
                                            height: 20,
                                            decoration: BoxDecoration(
                                              color: isVideo
                                                  ? AppTheme.info
                                                  : AppTheme.success,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.play_arrow_rounded,
                                              size: 13,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ── Proposal form ───────────────────────────────
              SlideUpFadeIn(
                delay: const Duration(milliseconds: 120),
                child: const Text(
                  'Ihr Angebot',
                  style: TextStyle(
                    fontFamily: AppTheme.displayFont,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.slate100,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Price
              SlideUpFadeIn(
                delay: const Duration(milliseconds: 200),
                child: _FormField(
                  label: 'PREIS (EUR)',
                  child: TextField(
                    controller: _priceController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(
                      fontFamily: AppTheme.displayFont,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.slate100,
                    ),
                    decoration: InputDecoration(
                      hintText: '0.00',
                      prefixText: '€ ',
                      prefixStyle: TextStyle(
                        fontFamily: AppTheme.displayFont,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.slate400,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ETA
              SlideUpFadeIn(
                delay: const Duration(milliseconds: 280),
                child: _FormField(
                  label: 'ANKUNFTSZEIT (MINUTEN)',
                  child: TextField(
                    controller: _etaController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontFamily: AppTheme.displayFont,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.slate100,
                    ),
                    decoration: const InputDecoration(
                      hintText: '15',
                      suffixText: 'min',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Comment
              SlideUpFadeIn(
                delay: const Duration(milliseconds: 360),
                child: _FormField(
                  label: 'KOMMENTAR (OPTIONAL)',
                  child: TextField(
                    controller: _commentController,
                    maxLines: 2,
                    maxLength: 500,
                    style: const TextStyle(
                      fontFamily: AppTheme.bodyFont,
                      fontSize: 14,
                      color: AppTheme.slate100,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Nachricht an den Kunden...',
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Submit / Cancel
              SlideUpFadeIn(
                delay: const Duration(milliseconds: 440),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TapScale(
                        onTap: _isSubmitting ? null : _submit,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            color: AppTheme.amber,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMD),
                            boxShadow: AppTheme.glowAmber,
                          ),
                          child: Center(
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: AppTheme.slate900,
                                    ),
                                  )
                                : const Text(
                                    'Angebot senden',
                                    style: TextStyle(
                                      fontFamily: AppTheme.displayFont,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.slate900,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    TapScale(
                      onTap: () => context.pop(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 18, horizontal: 20),
                        decoration: BoxDecoration(
                          color: AppTheme.slate800,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMD),
                          border: Border.all(color: AppTheme.slate600),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: AppTheme.slate300,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppTheme.amber)),
        error: (e, _) => Center(
          child: Text('$e', style: const TextStyle(color: AppTheme.error)),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Form field helper
// ─────────────────────────────────────────────────────────────
class _FormField extends StatelessWidget {
  final String label;
  final Widget child;
  const _FormField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: AppTheme.bodyFont,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppTheme.slate500,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Image viewer dialog
// ─────────────────────────────────────────────────────────────
class _ImageViewerDialog extends StatelessWidget {
  final String url;
  const _ImageViewerDialog({required this.url});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.contain,
                placeholder: (_, __) => const Center(
                    child: CircularProgressIndicator(color: AppTheme.amber)),
                errorWidget: (_, __, ___) => const Center(
                    child: Icon(Icons.broken_image_rounded,
                        color: AppTheme.slate400, size: 64)),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Video player dialog
// ─────────────────────────────────────────────────────────────
class _VideoPlayerDialog extends StatefulWidget {
  final String url;
  const _VideoPlayerDialog({required this.url});

  @override
  State<_VideoPlayerDialog> createState() => _VideoPlayerDialogState();
}

class _VideoPlayerDialogState extends State<_VideoPlayerDialog> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (mounted) setState(() => _initialized = true);
        _controller.play();
      }).catchError((_) {
        if (mounted) setState(() => _hasError = true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Video area
            AspectRatio(
              aspectRatio: _initialized ? _controller.value.aspectRatio : 16 / 9,
              child: _hasError
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline_rounded,
                              color: AppTheme.error, size: 48),
                          SizedBox(height: 8),
                          Text('Video konnte nicht geladen werden',
                              style: TextStyle(color: AppTheme.slate400)),
                        ],
                      ),
                    )
                  : _initialized
                      ? VideoPlayer(_controller)
                      : const Center(
                          child: CircularProgressIndicator(
                              color: AppTheme.amber)),
            ),
            // Controls
            Container(
              color: AppTheme.slate900,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      _controller.value.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: AppTheme.amber,
                    ),
                    onPressed: _initialized
                        ? () => setState(() {
                              _controller.value.isPlaying
                                  ? _controller.pause()
                                  : _controller.play();
                            })
                        : null,
                  ),
                  Expanded(
                    child: _initialized
                        ? VideoProgressIndicator(
                            _controller,
                            allowScrubbing: true,
                            colors: const VideoProgressColors(
                              playedColor: AppTheme.amber,
                              bufferedColor: AppTheme.slate600,
                              backgroundColor: AppTheme.slate700,
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: AppTheme.slate300),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Audio player bottom sheet
// ─────────────────────────────────────────────────────────────
class _AudioPlayerSheet extends StatefulWidget {
  final String url;
  const _AudioPlayerSheet({required this.url});

  @override
  State<_AudioPlayerSheet> createState() => _AudioPlayerSheetState();
}

class _AudioPlayerSheetState extends State<_AudioPlayerSheet> {
  final AudioPlayer _player = AudioPlayer();
  PlayerState _playerState = PlayerState.stopped;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player.onPlayerStateChanged.listen((s) {
      if (mounted) setState(() => _playerState = s);
    });
    _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    // Auto-play
    _player.play(UrlSource(widget.url));
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = _playerState == PlayerState.playing;
    final progress = _duration.inSeconds > 0
        ? _position.inSeconds / _duration.inSeconds
        : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.slate600,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Icon
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mic_rounded,
                color: AppTheme.success, size: 36),
          ),
          const SizedBox(height: 16),
          const Text(
            'Sprachaufnahme',
            style: TextStyle(
              fontFamily: AppTheme.displayFont,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.slate100,
            ),
          ),
          const SizedBox(height: 20),
          // Progress bar
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppTheme.success,
              inactiveTrackColor: AppTheme.slate700,
              thumbColor: AppTheme.success,
              overlayColor: AppTheme.success.withValues(alpha: 0.2),
              trackHeight: 3,
            ),
            child: Slider(
              value: progress.clamp(0.0, 1.0),
              onChanged: (v) {
                final pos = Duration(
                    seconds: (v * _duration.inSeconds).round());
                _player.seek(pos);
              },
            ),
          ),
          // Time labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_fmt(_position),
                    style: const TextStyle(
                        fontFamily: AppTheme.bodyFont,
                        fontSize: 12,
                        color: AppTheme.slate400)),
                Text(_fmt(_duration),
                    style: const TextStyle(
                        fontFamily: AppTheme.bodyFont,
                        fontSize: 12,
                        color: AppTheme.slate400)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Play / Pause button
          TapScale(
            onTap: () {
              if (isPlaying) {
                _player.pause();
              } else {
                _player.play(UrlSource(widget.url));
              }
            },
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.success,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.success.withValues(alpha: 0.35),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

