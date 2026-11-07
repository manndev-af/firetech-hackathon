import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colors.dart';

enum ScanMode { food, label }

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({this.pickImage, this.onUsePhoto, super.key});

  final Future<XFile?> Function()? pickImage;
  final Future<void> Function(XFile photo, ScanMode mode)? onUsePhoto;

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with WidgetsBindingObserver {
  CameraController? _camera;
  Future<void> _cameraWork = Future.value();
  XFile? _photo;
  ScanMode _mode = ScanMode.food;
  String? _cameraError;
  String? _photoError;
  bool _loading = true;
  bool _busy = false;
  bool _picking = false;
  bool _showingResult = false;
  bool _foreground = true;

  bool get _wantsCamera =>
      mounted && _foreground && !_picking && !_showingResult && _photo == null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _syncCamera();
  }

  // Serialize opening/closing: permission dialogs, gallery, and backgrounding
  // can otherwise race with controller initialization.
  Future<void> _syncCamera() {
    _cameraWork = _cameraWork
        .then((_) async {
          if (!_wantsCamera) {
            final previous = _camera;
            _camera = null;
            if (mounted) setState(() => _loading = false);
            await previous?.dispose();
            return;
          }
          if (_camera != null || _cameraError != null) return;
          setState(() => _loading = true);
          CameraController? candidate;
          try {
            final cameras = await availableCameras();
            if (!_wantsCamera) return;
            if (cameras.isEmpty) {
              throw CameraException('NoCamera', 'No camera available');
            }
            final rear = cameras.where(
              (c) => c.lensDirection == CameraLensDirection.back,
            );
            candidate = CameraController(
              rear.isEmpty ? cameras.first : rear.first,
              ResolutionPreset.high,
              enableAudio: false,
            );
            await candidate.initialize();
            if (!_wantsCamera) {
              await candidate.dispose();
              return;
            }
            _camera = candidate;
            _camera!.addListener(_onCameraChanged);
          } catch (error) {
            await candidate?.dispose();
            if (_wantsCamera) _cameraError = _errorMessage(error);
          } finally {
            if (mounted) setState(() => _loading = false);
          }
        })
        .catchError((Object error) {
          if (mounted) {
            setState(() {
              _loading = false;
              _cameraError = _errorMessage(error);
            });
          }
        });
    return _cameraWork;
  }

  void _onCameraChanged() {
    if (!mounted || _camera?.value.hasError != true) return;
    setState(
      () => _cameraError =
          'Kamera terputus. Coba buka kembali atau pilih dari galeri.',
    );
  }

  String _errorMessage(Object error) {
    final code = switch (error) {
      CameraException e => e.code,
      PlatformException e => e.code,
      _ => '',
    };
    if (code.startsWith('CameraAccess') || code == 'camera_access_denied') {
      return 'Izin kamera belum tersedia. Izinkan kamera untuk NutriLens di pengaturan perangkat, lalu coba lagi. Kamu juga bisa memilih foto dari galeri.';
    }
    return 'Kamera belum bisa dibuka. Coba lagi atau pilih foto dari galeri.';
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _syncCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _foreground = false;
    unawaited(_syncCamera());
    super.dispose();
  }

  Future<void> _retry() async {
    final previous = _camera;
    setState(() {
      _camera = null;
      _cameraError = null;
      _loading = true;
    });
    _cameraWork = _cameraWork.then((_) async => previous?.dispose());
    await _syncCamera();
  }

  Future<void> _acceptPhoto(XFile photo) async {
    // Decode before accepting a gallery file; a file extension is not proof
    // that the selected image can be displayed.
    Object? decodeError;
    if (!mounted) return;
    await precacheImage(
      FileImage(File(photo.path)),
      context,
      onError: (error, stack) => decodeError = error,
    );
    if (!mounted) return;
    if (decodeError != null) throw StateError('Unreadable photo');
    setState(() {
      _photo = photo;
      _photoError = null;
    });
    await _syncCamera();
  }

  Future<void> _capture() async {
    final camera = _camera;
    if (_busy || camera == null || !camera.value.isInitialized) return;
    setState(() {
      _busy = true;
      _photoError = null;
    });
    try {
      await _acceptPhoto(await camera.takePicture());
    } catch (_) {
      if (mounted)
        setState(() => _photoError = 'Foto belum berhasil diambil. Coba lagi.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _gallery() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _picking = true;
      _photoError = null;
    });
    try {
      await _syncCamera();
      final photo =
          await (widget.pickImage?.call() ??
              ImagePicker().pickImage(
                source: ImageSource.gallery,
                maxWidth: 2000,
                imageQuality: 90,
              ));
      if (photo != null) await _acceptPhoto(photo);
    } catch (_) {
      if (mounted)
        setState(
          () => _photoError =
              'Foto tidak dapat dibuka. Pilih gambar lain dari galeri.',
        );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _picking = false;
        });
        await _syncCamera();
      }
    }
  }

  Future<void> _usePhoto() async {
    if (_photo == null || _busy) return;
    if (widget.onUsePhoto == null) {
      setState(() => _showingResult = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
      return;
    }
    setState(() => _showingResult = true);
    try {
      await widget.onUsePhoto!(_photo!, _mode);
    } finally {
      if (mounted) setState(() => _showingResult = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLabel = _mode == ScanMode.label;
    final review = _photo != null;
    return PopScope(
      canPop: !review || _showingResult,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && review && !_showingResult) _retake();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final previewHeight = (constraints.maxHeight * .58).clamp(
                230.0,
                480.0,
              );
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            IconButton.filledTonal(
                              tooltip: review ? 'Foto ulang' : 'Kembali',
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.background,
                                foregroundColor: AppColors.primaryDark,
                              ),
                              onPressed: _busy
                                  ? null
                                  : review
                                  ? _retake
                                  : () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back_rounded),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                review
                                    ? 'Periksa fotomu'
                                    : isLabel
                                    ? 'Foto label nutrisinya'
                                    : 'Foto makananmu',
                                style: const TextStyle(
                                  fontSize: 21,
                                  height: 1.4,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: Container(
                            height: previewHeight,
                            color: AppColors.background,
                            child: _preview(),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          review
                              ? 'Pastikan foto jelas dan tidak terpotong.'
                              : isLabel
                              ? 'Pastikan komposisi, angka, dan takaran saji terbaca.'
                              : 'Posisikan makanan di tengah, dengan cahaya yang cukup.',
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            for (final mode in ScanMode.values)
                              ChoiceChip(
                                label: Text(
                                  mode == ScanMode.food
                                      ? 'Makanan'
                                      : 'Label produk',
                                ),
                                selected: _mode == mode,
                                selectedColor: AppColors.mint,
                                labelStyle: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.primaryDark,
                                ),
                                onSelected: _busy
                                    ? null
                                    : (_) => setState(() => _mode = mode),
                              ),
                          ],
                        ),
                        if (_photoError != null) ...[
                          const SizedBox(height: 12),
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              _photoError!,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        if (review) ...[
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.heroBackground,
                              minimumSize: const Size(double.infinity, 52),
                            ),
                            onPressed: _busy ? null : _usePhoto,
                            child: Text(
                              widget.onUsePhoto == null
                                  ? 'Selesai'
                                  : 'Gunakan foto',
                            ),
                          ),
                          TextButton(
                            onPressed: _busy ? null : _retake,
                            child: const Text('Foto ulang'),
                          ),
                        ] else
                          Wrap(
                            alignment: WrapAlignment.spaceEvenly,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 24,
                            runSpacing: 16,
                            children: [
                              TextButton.icon(
                                onPressed: _busy ? null : _gallery,
                                icon: const Icon(Icons.photo_library_outlined),
                                label: const Text('Galeri'),
                              ),
                              Semantics(
                                label: 'Ambil foto',
                                button: true,
                                child: Tooltip(
                                  message: 'Ambil foto',
                                  child: SizedBox(
                                    width: 72,
                                    height: 72,
                                    child: FilledButton(
                                      key: const Key('camera-shutter'),
                                      onPressed:
                                          _busy ||
                                              _loading ||
                                              _cameraError != null ||
                                              _camera == null
                                          ? null
                                          : _capture,
                                      style: FilledButton.styleFrom(
                                        shape: const CircleBorder(),
                                        padding: const EdgeInsets.all(7),
                                        backgroundColor:
                                            AppColors.heroBackground,
                                      ),
                                      child: _busy
                                          ? const SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : Container(
                                              decoration: const BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _retake() {
    setState(() {
      _photo = null;
      _photoError = null;
    });
    _syncCamera();
  }

  Widget _preview() {
    if (!_foreground && _photo == null) {
      return const Center(child: Text('Kamera dijeda'));
    }
    if (_photo != null) {
      return Image.file(
        File(_photo!.path),
        fit: BoxFit.contain,
        semanticLabel: 'Foto yang dipilih',
        errorBuilder: (_, error, stack) =>
            const Center(child: Text('Foto tidak dapat ditampilkan.')),
      );
    }
    if (_cameraError != null) {
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.no_photography_outlined,
                size: 40,
                color: AppColors.primaryDark,
              ),
              const SizedBox(height: 16),
              Semantics(
                liveRegion: true,
                child: Text(
                  _cameraError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _loading || _busy ? null : _retry,
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      );
    }
    if (_loading || _camera == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Membuka kamera…'),
          ],
        ),
      );
    }
    return ColoredBox(
      color: Colors.black,
      child: Center(child: CameraPreview(_camera!)),
    );
  }
}
