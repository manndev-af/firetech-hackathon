import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilens/app.dart';
import 'package:nutrilens/core/router/app_router.dart';
import 'package:nutrilens/core/router/route_paths.dart';
import 'package:nutrilens/core/theme/app_theme.dart';
import 'package:nutrilens/features/scanner/scanner_screen.dart';
import 'package:nutrilens/services/local_vision.dart';
import 'package:nutrilens/shared/widgets/navigation/bottom_nav.dart';

class FakeCamera extends CameraPlatform {
  Object? failure;
  int opened = 0;
  int closed = 0;
  int captures = 0;
  bool? audio;
  String photoPath = '';
  Completer<void>? initializing;

  @override
  Future<List<CameraDescription>> availableCameras() async {
    if (failure != null) throw failure!;
    return [
      const CameraDescription(
        name: 'rear',
        lensDirection: CameraLensDirection.back,
        sensorOrientation: 90,
      ),
    ];
  }

  @override
  Future<int> createCamera(
    CameraDescription description,
    ResolutionPreset? resolutionPreset, {
    bool enableAudio = false,
  }) async {
    audio = enableAudio;
    return ++opened;
  }

  @override
  Future<void> initializeCamera(
    int cameraId, {
    ImageFormatGroup imageFormatGroup = ImageFormatGroup.unknown,
  }) async {
    await initializing?.future;
  }

  @override
  Stream<CameraInitializedEvent> onCameraInitialized(int cameraId) =>
      Stream.value(
        CameraInitializedEvent(
          cameraId,
          640,
          480,
          ExposureMode.auto,
          false,
          FocusMode.auto,
          false,
        ),
      );
  @override
  Stream<CameraErrorEvent> onCameraError(int cameraId) =>
      Stream.multi((controller) {});
  @override
  Stream<DeviceOrientationChangedEvent> onDeviceOrientationChanged() =>
      const Stream.empty();
  @override
  Widget buildPreview(int cameraId) => const ColoredBox(
    color: Colors.black,
    child: Center(child: Text('Live camera')),
  );
  @override
  Future<void> dispose(int cameraId) async {
    closed++;
  }

  @override
  Future<XFile> takePicture(int cameraId) async {
    captures++;
    return XFile(photoPath);
  }
}

void main() {
  late CameraPlatform original;
  late FakeCamera camera;
  setUp(() {
    original = CameraPlatform.instance;
    CameraPlatform.instance = camera = FakeCamera();
  });
  tearDown(() {
    CameraPlatform.instance = original;
  });

  Future<void> show(
    WidgetTester tester, {
    Future<XFile?> Function()? picker,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: ScannerScreen(pickImage: picker),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('opens rear preview without audio; label mode changes guidance', (
    tester,
  ) async {
    await show(tester);
    expect(camera.audio, isFalse);
    expect(find.byType(CameraPreview), findsOneWidget);
    await tap(tester, find.text('Label produk'));
    expect(find.text('Foto label nutrisinya'), findsOneWidget);
    expect(find.textContaining('komposisi, angka'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(camera.closed, 1);
  });

  testWidgets('permission failure supports retry and gallery cancellation', (
    tester,
  ) async {
    camera.failure = CameraException('CameraAccessDenied', 'denied');
    await show(tester, picker: () async => null);
    expect(find.textContaining('Izin kamera'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('camera-shutter')))
          .onPressed,
      isNull,
    );
    await tap(tester, find.text('Galeri'));
    expect(find.text('Periksa fotomu'), findsNothing);
    camera.failure = null;
    await tap(tester, find.text('Coba lagi'));
    expect(find.byType(CameraPreview), findsOneWidget);
  });

  testWidgets('background releases camera and resume opens it again', (
    tester,
  ) async {
    await show(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pumpAndSettle();
    expect(camera.closed, 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(camera.opened, 2);
    expect(find.byType(CameraPreview), findsOneWidget);
  });

  testWidgets('leaving while camera initializes disposes the late controller', (
    tester,
  ) async {
    camera.initializing = Completer<void>();
    await tester.pumpWidget(const MaterialApp(home: ScannerScreen()));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    camera.initializing!.complete();
    await tester.pumpAndSettle();
    expect(camera.closed, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('capture reviews real file and retake reopens camera', (
    tester,
  ) async {
    final folder = Directory.systemTemp.createTempSync('nutrilens-scan-test-');
    final photo = File('${folder.path}/capture.jpg');
    addTearDown(() async {
      if (await photo.exists()) await photo.delete();
      await folder.delete();
    });
    await tester.runAsync(() async {
      final bytes = await rootBundle.load('assets/images/history_yogurt.jpg');
      await photo.writeAsBytes(bytes.buffer.asUint8List());
    });
    camera.photoPath = photo.path;
    await show(tester);
    await tester.runAsync(() async {
      await precacheImage(
        FileImage(photo),
        tester.element(find.byType(ScannerScreen)),
      );
    });
    await tap(tester, find.byKey(const Key('camera-shutter')));
    expect(find.text('Periksa fotomu'), findsOneWidget);
    expect(camera.captures, 1);
    expect(camera.closed, 1);
    await tap(tester, find.widgetWithText(TextButton, 'Foto ulang'));
    expect(find.byType(CameraPreview), findsOneWidget);
    expect(camera.opened, 2);
  });

  testWidgets(
    'camera entry uses root navigator and returns to the previous tab',
    (tester) async {
      appRouter.go(AppRoutes.profile);
      await tester.pumpWidget(const NutriLensApp());
      await tester.pumpAndSettle();
      tester.widget<BottomNav>(find.byType(BottomNav)).onAddTap();
      await tester.pumpAndSettle();
      expect(find.byType(ScannerScreen), findsOneWidget);
      expect(find.byType(BottomNav).hitTestable(), findsNothing);
      await tap(tester, find.byTooltip('Kembali'));
      expect(find.byType(ScannerScreen), findsNothing);
      expect(find.text('Profil kamu'), findsWidgets);
    },
  );

  testWidgets('small screen and large text keep gallery and retry reachable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    camera.failure = CameraException('CameraAccessDenied', 'denied');
    await show(tester, picker: () async => null);
    await tap(tester, find.text('Galeri'));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'onUsePhoto failure shows error dialog and Foto Ulang reopens camera',
    (tester) async {
      final folder = Directory.systemTemp.createTempSync(
        'nutrilens-dialog-test-',
      );
      final photo = File('${folder.path}/capture.jpg');
      addTearDown(() async {
        if (await photo.exists()) await photo.delete();
        await folder.delete();
      });
      await tester.runAsync(() async {
        final bytes = await rootBundle.load('assets/images/history_yogurt.jpg');
        await photo.writeAsBytes(bytes.buffer.asUint8List());
      });
      camera.photoPath = photo.path;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: ScannerScreen(
            onUsePhoto: (file, mode, {note}) async {
              throw const ScanFailure(
                'Tabel nilai gizi tidak ditemukan pada label.',
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await precacheImage(
          FileImage(photo),
          tester.element(find.byType(ScannerScreen)),
        );
      });
      await tap(tester, find.byKey(const Key('camera-shutter')));
      expect(find.text('Periksa fotomu'), findsOneWidget);
      await tap(tester, find.widgetWithText(FilledButton, 'Gunakan foto'));
      await tester.pumpAndSettle();
      expect(find.text('Makanan Belum Terdeteksi'), findsOneWidget);
      expect(
        find.text('Tabel nilai gizi tidak ditemukan pada label.'),
        findsOneWidget,
      );
      await tap(tester, find.widgetWithText(FilledButton, 'Foto Ulang'));
      expect(find.text('Makanan Belum Terdeteksi'), findsNothing);
      expect(find.byType(CameraPreview), findsOneWidget);
    },
  );

  testWidgets(
    'review screen shows optional description field and forwards note',
    (tester) async {
      final folder = Directory.systemTemp.createTempSync(
        'nutrilens-note-test-',
      );
      final photo = File('${folder.path}/capture.jpg');
      addTearDown(() async {
        if (await photo.exists()) await photo.delete();
        await folder.delete();
      });
      await tester.runAsync(() async {
        final bytes = await rootBundle.load('assets/images/history_yogurt.jpg');
        await photo.writeAsBytes(bytes.buffer.asUint8List());
      });
      camera.photoPath = photo.path;
      String? recordedNote;
      ScanMode? recordedMode;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: ScannerScreen(
            onUsePhoto: (file, mode, {note}) async {
              recordedNote = note;
              recordedMode = mode;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await precacheImage(
          FileImage(photo),
          tester.element(find.byType(ScannerScreen)),
        );
      });
      await tap(tester, find.byKey(const Key('camera-shutter')));
      expect(find.text('Periksa fotomu'), findsOneWidget);
      expect(find.text('Deskripsi tambahan'), findsOneWidget);
      expect(find.text('Opsional'), findsOneWidget);
      expect(find.byKey(const Key('scan-note-field')), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('scan-note-field')),
        'Tanpa kuah, sambal dipisah',
      );
      await tester.pumpAndSettle();

      await tap(tester, find.widgetWithText(FilledButton, 'Gunakan foto'));
      await tester.pumpAndSettle();

      expect(recordedMode, ScanMode.food);
      expect(recordedNote, 'Tanpa kuah, sambal dipisah');
    },
  );

  testWidgets(
    'onUsePhoto returning true resets photo, clears note, and reopens camera preview',
    (tester) async {
      final folder = Directory.systemTemp.createTempSync(
        'nutrilens-clear-test-',
      );
      final photo = File('${folder.path}/capture.jpg');
      addTearDown(() async {
        if (await photo.exists()) await photo.delete();
        await folder.delete();
      });
      await tester.runAsync(() async {
        final bytes = await rootBundle.load('assets/images/history_yogurt.jpg');
        await photo.writeAsBytes(bytes.buffer.asUint8List());
      });
      camera.photoPath = photo.path;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: ScannerScreen(
            onUsePhoto: (file, mode, {note}) async {
              return true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await precacheImage(
          FileImage(photo),
          tester.element(find.byType(ScannerScreen)),
        );
      });
      await tap(tester, find.byKey(const Key('camera-shutter')));
      expect(find.text('Periksa fotomu'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('scan-note-field')),
        'Catatan tes',
      );
      await tester.pumpAndSettle();

      await tap(tester, find.widgetWithText(FilledButton, 'Gunakan foto'));
      await tester.pumpAndSettle();

      // Should return to live camera preview and clear photo & review UI
      expect(find.text('Periksa fotomu'), findsNothing);
      expect(find.byType(CameraPreview), findsOneWidget);
    },
  );
}
