import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colors.dart';
import '../../services/local_vision.dart';

enum ScanMode { food, label }

typedef UsePhotoCallback =
    Future<dynamic> Function(XFile photo, ScanMode mode, {String? note});

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({this.pickImage, this.onUsePhoto, super.key});

  final Future<XFile?> Function()? pickImage;
  final UsePhotoCallback? onUsePhoto;

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with WidgetsBindingObserver {
  CameraController? _camera;
  Future<void> _cameraWork = Future.value();
  XFile? _photo;
  ScanMode _mode = ScanMode.food;
  final TextEditingController _noteController = TextEditingController();
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
    _noteController.dispose();
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
      if (mounted) {
        setState(() => _photoError = 'Foto belum berhasil diambil. Coba lagi.');
      }
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
      if (mounted) {
        setState(
          () => _photoError =
              'Foto tidak dapat dibuka. Pilih gambar lain dari galeri.',
        );
      }
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
    setState(() => _busy = true);
    final note = _noteController.text.trim();
    try {
      final saved = await widget.onUsePhoto!(
        _photo!,
        _mode,
        note: note.isNotEmpty ? note : null,
      );
      if (mounted && saved == true) {
        _retake();
      }
    } on ScanFailure catch (e) {
      if (mounted) {
        setState(() => _showingResult = false);
        await _showErrorDialog(e.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _showingResult = false);
        await _showErrorDialog(
          'Pemeriksaan foto belum berhasil. Pastikan objek terlihat jelas lalu foto ulang.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _showingResult = false;
        });
      }
    }
  }

  Future<void> _showErrorDialog(String message) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        backgroundColor: Colors.white,
        icon: Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF1F2),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFFECDD3)),
          ),
          child: const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFE11D48),
            size: 28,
          ),
        ),
        title: Text(
          _mode == ScanMode.label
              ? 'Label Gizi Belum Terdeteksi'
              : 'Makanan Belum Terdeteksi',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
            color: AppColors.textSecondary,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.heroBackground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _retake();
              },
              child: const Text(
                'Foto Ulang',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
                                  fontSize: 24,
                                  height: 1.35,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
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
                        const SizedBox(height: 20),
                        Text(
                          review
                              ? 'Pastikan foto jelas dan tidak terpotong.'
                              : isLabel
                              ? 'Pastikan komposisi, angka, dan takaran saji terbaca.'
                              : 'Posisikan makanan di tengah, dengan cahaya yang cukup.',
                          style: const TextStyle(
                            fontSize: 15,
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
                                labelStyle: TextStyle(
                                  fontSize: 15,
                                  fontWeight: _mode == mode
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: AppColors.primaryDark,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                    color: _mode == mode
                                        ? AppColors.cyan
                                        : AppColors.border,
                                  ),
                                ),
                                onSelected: _busy
                                    ? null
                                    : (_) => setState(() => _mode = mode),
                              ),
                          ],
                        ),
                        if (review) ...[
                          const SizedBox(height: 18),
                          _buildNoteField(isLabel),
                        ],
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
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.heroBackground,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 54),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: _busy ? null : _usePhoto,
                            icon: const Icon(Icons.arrow_forward_rounded),
                            label: Text(
                              widget.onUsePhoto == null
                                  ? 'Selesai'
                                  : 'Gunakan foto',
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: _busy ? null : _retake,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Foto ulang'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primaryDark,
                              textStyle: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.primaryDark,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 12,
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Semantics(
                                label: 'Ambil foto',
                                button: true,
                                child: Tooltip(
                                  message: 'Ambil foto',
                                  child: SizedBox(
                                    width: 76,
                                    height: 76,
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
                                        padding: const EdgeInsets.all(5),
                                        backgroundColor:
                                            AppColors.heroBackground,
                                        elevation: 3,
                                      ),
                                      child: _busy
                                          ? const SizedBox(
                                              width: 26,
                                              height: 26,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                color: Colors.white,
                                              ),
                                            )
                                          : Container(
                                              width: 56,
                                              height: 56,
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: AppColors.heroBackground,
                                                  width: 3,
                                                ),
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

  Widget _buildNoteField(bool isLabel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: const [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.edit_note_rounded,
                  size: 20,
                  color: AppColors.primaryDark,
                ),
                SizedBox(width: 6),
                Text(
                  'Deskripsi tambahan',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.all(Radius.circular(6)),
                border: Border.fromBorderSide(
                  BorderSide(color: AppColors.border),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Text(
                  'Opsional',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          key: const Key('scan-note-field'),
          controller: _noteController,
          enabled: !_busy,
          maxLines: 2,
          minLines: 1,
          maxLength: 140,
          textInputAction: TextInputAction.done,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: isLabel
                ? 'Contoh: Varian cokelat, botol 250 ml, rasa tawar'
                : 'Contoh: 1 mangkok sedang, tanpa kuah santan, sambal dipisah',
            hintStyle: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            filled: true,
            fillColor: AppColors.background,
            counterText: '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppColors.heroBackground,
                width: 1.5,
              ),
            ),
            suffixIcon: _noteController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    color: AppColors.textSecondary,
                    onPressed: () => setState(() => _noteController.clear()),
                  )
                : null,
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  void _retake() {
    setState(() {
      _photo = null;
      _photoError = null;
      _noteController.clear();
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
        fit: BoxFit.cover,
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
    return ClipRect(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final landscape =
              MediaQuery.orientationOf(context) == Orientation.landscape;
          final ratio = landscape
              ? _camera!.value.aspectRatio
              : 1 / _camera!.value.aspectRatio;
          final isLabel = _mode == ScanMode.label;
          return Stack(
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: constraints.maxHeight * ratio,
                    height: constraints.maxHeight,
                    child: CameraPreview(_camera!),
                  ),
                ),
              ),
              const Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.all(28),
                  child: CustomPaint(
                    painter: _ViewfinderOverlayPainter(),
                  ),
                ),
              ),
              Positioned(
                top: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: .55),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.cyan,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isLabel ? 'Deteksi Label Gizi' : 'Deteksi Makanan AI',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ViewfinderOverlayPainter extends CustomPainter {
  const _ViewfinderOverlayPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.cyan.withValues(alpha: .85)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLength = 26.0;

    // Top-left
    canvas.drawLine(const Offset(0, cornerLength), Offset.zero, paint);
    canvas.drawLine(Offset.zero, const Offset(cornerLength, 0), paint);

    // Top-right
    canvas.drawLine(Offset(size.width - cornerLength, 0), Offset(size.width, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, cornerLength), paint);

    // Bottom-left
    canvas.drawLine(Offset(0, size.height - cornerLength), Offset(0, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(cornerLength, size.height), paint);

    // Bottom-right
    canvas.drawLine(Offset(size.width - cornerLength, size.height), Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - cornerLength), paint);
  }

  @override
  bool shouldRepaint(covariant _ViewfinderOverlayPainter oldDelegate) => false;
}
