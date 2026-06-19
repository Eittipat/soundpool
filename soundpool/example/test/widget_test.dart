import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundpool/soundpool.dart';
import 'package:soundpool_example/platform_options.dart';
import 'package:soundpool_platform_interface/soundpool_platform_interface.dart';

void main() {
  testWidgets('renders platform options fallback UI', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: PlatformOptions()));

    expect(find.byIcon(Icons.handyman_outlined), findsOneWidget);
    expect(find.text('Work in progress'), findsOneWidget);
  });

  test('AudioStreamControl resumes a paused stream', () async {
    final previousPlatform = SoundpoolPlatform.instance;
    final platform = _FakeSoundpoolPlatform();
    SoundpoolPlatform.instance = platform;
    addTearDown(() {
      SoundpoolPlatform.instance = previousPlatform;
    });

    final pool = Soundpool.fromOptions();
    final control = await pool.playWithControls(7);

    await control.pause();
    await control.resume();

    expect(platform.calls, <String>['init', 'play', 'pause', 'resume']);
    expect(control.playing, isTrue);
    expect(control.stopped, isFalse);
  });
}

class _FakeSoundpoolPlatform extends SoundpoolPlatform {
  final List<String> calls = <String>[];

  @override
  Future<int> init(
    int streamType,
    int maxStreams,
    Map<String, dynamic> plaformOptions,
  ) async {
    calls.add('init');
    return 1;
  }

  @override
  Future<int> loadUint8List(int poolId, rawSound, int priority) async => 1;

  @override
  Future<int> loadUri(int poolId, String uri, int priority) async => 1;

  @override
  Future<void> dispose(int poolId) async {}

  @override
  Future<void> release(int poolId) async {}

  @override
  Future<int> play(int poolId, int soundId, int repeat, double rate) async {
    calls.add('play');
    return 42;
  }

  @override
  Future<void> stop(int poolId, int streamId) async {
    calls.add('stop');
  }

  @override
  Future<void> pause(int poolId, int streamId) async {
    calls.add('pause');
  }

  @override
  Future<void> resume(int poolId, int streamId) async {
    calls.add('resume');
  }

  @override
  Future<void> setVolume(
    int poolId,
    int? soundId,
    int? streamId,
    double? volumeLeft,
    double? volumeRight,
  ) async {}

  @override
  Future<void> setRate(int poolId, int streamId, double playbackRate) async {}
}
