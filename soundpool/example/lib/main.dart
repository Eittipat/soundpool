import 'package:flutter/material.dart';
import 'package:soundpool/soundpool.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:soundpool_example/platform_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(home: SoundpoolInitializer()));
}

class SoundpoolInitializer extends StatefulWidget {
  @override
  _SoundpoolInitializerState createState() => _SoundpoolInitializerState();
}

class _SoundpoolInitializerState extends State<SoundpoolInitializer> {
  Soundpool? _pool;
  SoundpoolOptions _soundpoolOptions = SoundpoolOptions();

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _initPool(_soundpoolOptions);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_pool == null) {
      return Material(
        child: Center(
          child: ElevatedButton(
            onPressed: () => _initPool(_soundpoolOptions),
            child: Text("Init Soundpool"),
          ),
        ),
      );
    } else {
      return SimpleApp(
        pool: _pool!,
        onOptionsChange: _initPool,
      );
    }
  }

  void _initPool(SoundpoolOptions soundpoolOptions) {
    _pool?.dispose();
    setState(() {
      _soundpoolOptions = soundpoolOptions;
      _pool = Soundpool.fromOptions(options: _soundpoolOptions);
      print('pool updated: $_pool');
    });
  }
}

class SimpleApp extends StatefulWidget {
  final Soundpool pool;
  final ValueSetter<SoundpoolOptions> onOptionsChange;
  SimpleApp({Key? key, required this.pool, required this.onOptionsChange})
      : super(key: key);

  @override
  _SimpleAppState createState() => _SimpleAppState();
}

class _SimpleAppState extends State<SimpleApp> {
  Soundpool get _soundpool => widget.pool;

  String get _cheeringUrl => kIsWeb
      ? '/c-c-1.mp3'
      : 'https://raw.githubusercontent.com/ukasz123/soundpool/feature/web_support/example/web/c-c-1.mp3';

  late Future<int> _soundId;
  late Future<int> _cheeringId;

  // Active stream tracked via AudioStreamControl
  AudioStreamControl? _active;
  int? get _activeStreamId => _active?.stream;

  double _rate = 1.0;
  double _volume = 1.0;
  int? _activeSoundId; // remember which sound is currently active

  @override
  void initState() {
    super.initState();
    _loadSounds();
  }

  void _loadSounds() {
    _soundId = _loadSound();
    _cheeringId = _loadCheering();
  }

  @override
  void didUpdateWidget(SimpleApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pool != widget.pool) {
      _active = null;
      _activeSoundId = null;
      _loadSounds();
    }
  }

  @override
  Widget build(BuildContext context) {
    final streamId = _activeStreamId;
    final playing = _active?.playing ?? false;
    final stopped = _active?.stopped ?? true;

    return Scaffold(
      appBar: AppBar(
        title: Text('Soundpool'),
        actions: [
          IconButton(
            onPressed: () async {
              final newOptions = await Navigator.of(context).push<
                  SoundpoolOptions>(
                  MaterialPageRoute(builder: (context) => PlatformOptions()));
              if (newOptions != null) {
                widget.onOptionsChange(newOptions);
              }
            },
            icon: Icon(Icons.access_alarms),
          ),
        ],
      ),
      body: Center(
        child: SizedBox(
          width: kIsWeb ? 450 : double.infinity,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _soundPicker(),
                SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        Text('Current stream id',
                            style: Theme.of(context).textTheme.labelMedium),
                        SizedBox(height: 4),
                        Text(
                          streamId == null ? '—' : streamId.toString(),
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          stopped
                              ? 'stopped'
                              : (playing ? 'playing' : 'paused'),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _play,
                      icon: Icon(Icons.play_arrow),
                      label: Text('Play'),
                    ),
                    ElevatedButton.icon(
                      onPressed: (_active == null || stopped || !playing)
                          ? null
                          : _pause,
                      icon: Icon(Icons.pause),
                      label: Text('Pause'),
                    ),
                    ElevatedButton.icon(
                      onPressed: (_active == null || stopped || playing)
                          ? null
                          : _resume,
                      icon: Icon(Icons.play_circle_outline),
                      label: Text('Resume'),
                    ),
                    ElevatedButton.icon(
                      onPressed: _active == null || stopped ? null : _stop,
                      icon: Icon(Icons.stop),
                      label: Text('Stop'),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Text('Rate: ${_rate.toStringAsFixed(2)}'),
                Row(children: [
                  Expanded(
                    child: Slider.adaptive(
                      min: 0.5,
                      max: 2.0,
                      value: _rate,
                      onChanged: (v) {
                        setState(() => _rate = v);
                        _applyRate();
                      },
                    ),
                  ),
                  OutlinedButton(
                    onPressed: _applyRate,
                    child: Text('Set'),
                  ),
                ]),
                SizedBox(height: 8),
                Text('Volume: ${_volume.toStringAsFixed(2)}'),
                Row(children: [
                  Expanded(
                    child: Slider.adaptive(
                      min: 0.0,
                      max: 1.0,
                      value: _volume,
                      onChanged: (v) {
                        setState(() => _volume = v);
                        _applyVolume();
                      },
                    ),
                  ),
                  OutlinedButton(
                    onPressed: _applyVolume,
                    child: Text('Set'),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _soundPicker() {
    return FutureBuilder<List<int>>(
      future: Future.wait([_soundId, _cheeringId]),
      builder: (context, snap) {
        if (!snap.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        final ids = snap.data!;
        return SegmentedButton<int>(
          segments: [
            ButtonSegment(value: ids[0], label: Text('Dices')),
            ButtonSegment(value: ids[1], label: Text('Cheering')),
          ],
          selected: {_activeSoundId ?? ids[0]},
          onSelectionChanged: (s) {
            setState(() => _activeSoundId = s.first);
            _stop();
          },
        );
      },
    );
  }

  Future<int> _loadSound() async {
    var asset = await rootBundle.load("sounds/do-you-like-it.wav");
    return await _soundpool.load(asset);
  }

  Future<int> _loadCheering() async {
    return await _soundpool.loadUri(_cheeringUrl);
  }

  Future<void> _play() async {
    // stop any existing stream first
    if (_active != null && !_active!.stopped) {
      await _active!.stop();
    }
    final ids = await Future.wait([_soundId, _cheeringId]);
    final selected = _activeSoundId ?? ids[0];
    final control = await _soundpool.playWithControls(
      selected,
      rate: _rate,
    );
    setState(() {
      _active = control;
      _activeSoundId = selected;
    });
    // apply current volume to the new stream
    await _soundpool.setVolume(streamId: control.stream, volume: _volume);
  }

  Future<void> _pause() async => _active?.pause().then((_) => setState(() {}));

  Future<void> _resume() async =>
      _active?.resume().then((_) => setState(() {}));

  Future<void> _stop() async {
    if (_active != null) {
      await _active!.stop();
    }
    setState(() => _active = null);
  }

  Future<void> _applyRate() async {
    final active = _active;
    if (active == null || active.stopped) return;
    await active.setRate(playbackRate: _rate);
  }

  Future<void> _applyVolume() async {
    final active = _active;
    if (active != null && !active.stopped) {
      await active.setVolume(volume: _volume);
    }
    // also update default volume for the soundId so future plays inherit it
    final id = _activeSoundId;
    if (id != null) {
      await _soundpool.setVolume(soundId: id, volume: _volume);
    }
  }
}
