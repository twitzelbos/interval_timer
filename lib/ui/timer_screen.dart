import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

enum TimerPhase { countdown, work, rest, done }

class TimerScreen extends StatefulWidget {
  final int onSeconds;
  final int offSeconds;
  final int rounds;
  final bool soundOn;

  const TimerScreen({
    super.key,
    required this.onSeconds,
    required this.offSeconds,
    required this.rounds,
    required this.soundOn,
  });

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  Timer? _timer;
  TimerPhase _phase = TimerPhase.countdown;
  int _secondsLeft = 10;
  int _currentRound = 1;
  bool _paused = false;

  final AudioPlayer _highBeep = AudioPlayer();
  final AudioPlayer _lowBeep = AudioPlayer();
  final AudioPlayer _doneBeep = AudioPlayer();
  DeviceFileSource? _highBeepSource;
  DeviceFileSource? _lowBeepSource;
  DeviceFileSource? _doneBeepSource;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _generateSounds();
    _startTimer();
  }

  Future<void> _generateSounds() async {
    final dir = await getTemporaryDirectory();
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    final highPath = '${dir.path}/beep_high.wav';
    final lowPath = '${dir.path}/beep_low.wav';
    final donePath = '${dir.path}/beep_done.wav';
    await File(highPath).writeAsBytes(_buildWav(880, 0.15));
    await File(lowPath).writeAsBytes(_buildWav(440, 0.15));
    await File(donePath).writeAsBytes(_buildWav(1760, 0.4));
    _highBeepSource = DeviceFileSource(highPath);
    _lowBeepSource = DeviceFileSource(lowPath);
    _doneBeepSource = DeviceFileSource(donePath);
  }

  /// Generate a simple sine-wave WAV in memory.
  Uint8List _buildWav(double freq, double durationSec) {
    const sampleRate = 44100;
    final numSamples = (sampleRate * durationSec).toInt();
    final dataSize = numSamples * 2; // 16-bit mono
    final fileSize = 44 + dataSize;

    final bytes = ByteData(fileSize);
    void writeStr(int offset, String s) {
      for (int i = 0; i < s.length; i++) {
        bytes.setUint8(offset + i, s.codeUnitAt(i));
      }
    }

    // WAV header
    writeStr(0, 'RIFF');
    bytes.setUint32(4, fileSize - 8, Endian.little);
    writeStr(8, 'WAVE');
    writeStr(12, 'fmt ');
    bytes.setUint32(16, 16, Endian.little); // chunk size
    bytes.setUint16(20, 1, Endian.little); // PCM
    bytes.setUint16(22, 1, Endian.little); // mono
    bytes.setUint32(24, sampleRate, Endian.little);
    bytes.setUint32(28, sampleRate * 2, Endian.little); // byte rate
    bytes.setUint16(32, 2, Endian.little); // block align
    bytes.setUint16(34, 16, Endian.little); // bits per sample
    writeStr(36, 'data');
    bytes.setUint32(40, dataSize, Endian.little);

    // Sine wave with fade-out envelope
    for (int i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      final envelope = 1.0 - (i / numSamples); // linear fade-out
      final sample = (sin(2 * pi * freq * t) * 32000 * envelope).toInt();
      bytes.setInt16(44 + i * 2, sample.clamp(-32768, 32767), Endian.little);
    }

    return bytes.buffer.asUint8List();
  }

  void _playBeep(TimerPhase nextPhase) {
    if (!widget.soundOn) return;
    switch (nextPhase) {
      case TimerPhase.work:
        if (_highBeepSource != null) _highBeep.play(_highBeepSource!);
      case TimerPhase.rest:
        if (_lowBeepSource != null) _lowBeep.play(_lowBeepSource!);
      case TimerPhase.done:
        if (_doneBeepSource != null) _doneBeep.play(_doneBeepSource!);
      case TimerPhase.countdown:
        break;
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_paused) return;

      setState(() {
        if (_secondsLeft > 1) {
          _secondsLeft--;
          // Tick haptic in last 3 seconds
          if (_secondsLeft <= 3) {
            HapticFeedback.lightImpact();
          }
        } else {
          _advance();
        }
      });
    });
  }

  void _advance() {
    HapticFeedback.heavyImpact();
    switch (_phase) {
      case TimerPhase.countdown:
        _phase = TimerPhase.work;
        _secondsLeft = widget.onSeconds;
        _playBeep(TimerPhase.work);
      case TimerPhase.work:
        if (_currentRound >= widget.rounds) {
          _phase = TimerPhase.done;
          _secondsLeft = 0;
          _timer?.cancel();
          _playBeep(TimerPhase.done);
        } else {
          _phase = TimerPhase.rest;
          _secondsLeft = widget.offSeconds;
          _playBeep(TimerPhase.rest);
        }
      case TimerPhase.rest:
        _currentRound++;
        _phase = TimerPhase.work;
        _secondsLeft = widget.onSeconds;
        _playBeep(TimerPhase.work);
      case TimerPhase.done:
        break;
    }
  }

  void _togglePause() {
    setState(() => _paused = !_paused);
    HapticFeedback.mediumImpact();
  }

  void _stop() {
    _timer?.cancel();
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _highBeep.dispose();
    _lowBeep.dispose();
    _doneBeep.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = switch (_phase) {
      TimerPhase.countdown => (
          const Color(0xFFF59E0B),
          Colors.black,
          'GET READY',
        ),
      TimerPhase.work => (
          const Color(0xFF16A34A),
          Colors.white,
          'GO',
        ),
      TimerPhase.rest => (
          const Color(0xFFDC2626),
          Colors.white,
          'REST',
        ),
      TimerPhase.done => (
          const Color(0xFF2563EB),
          Colors.white,
          'DONE',
        ),
    };

    return GestureDetector(
      onTap: _phase == TimerPhase.done ? null : _togglePause,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        color: bg,
        child: SafeArea(
          child: Stack(
            children: [
              // Main content
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Phase label
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 8,
                        color: fg.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Timer
                    if (_phase != TimerPhase.done)
                      Text(
                        _phase == TimerPhase.countdown
                            ? '$_secondsLeft'
                            : _formatTime(_secondsLeft),
                        style: TextStyle(
                          fontSize: 180,
                          fontWeight: FontWeight.w900,
                          color: fg,
                          height: 1.0,
                          fontFeatures: const [
                            FontFeature.tabularFigures(),
                          ],
                        ),
                      )
                    else
                      Icon(Icons.check_circle_outline,
                          size: 120, color: fg.withValues(alpha: 0.8)),

                    const SizedBox(height: 16),

                    // Round info
                    if (_phase == TimerPhase.work || _phase == TimerPhase.rest)
                      Text(
                        'ROUND $_currentRound of ${widget.rounds}',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 3,
                          color: fg.withValues(alpha: 0.6),
                        ),
                      ),

                    if (_phase == TimerPhase.done) ...[
                      const SizedBox(height: 16),
                      Text(
                        '${widget.rounds} rounds completed',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: fg.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 32),
                      FilledButton(
                        onPressed: _stop,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: bg,
                          minimumSize: const Size(200, 52),
                          textStyle: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('BACK'),
                      ),
                    ],
                  ],
                ),
              ),

              // Pause overlay
              if (_paused)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: Text(
                      'PAUSED',
                      style: TextStyle(
                        fontSize: 72,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 8,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ),

              // Stop button (top-left)
              Positioned(
                top: 8,
                left: 16,
                child: IconButton(
                  onPressed: _stop,
                  icon: Icon(Icons.close, size: 32, color: fg.withValues(alpha: 0.5)),
                ),
              ),

              // Pause hint (top-right)
              if (_phase != TimerPhase.done)
                Positioned(
                  top: 16,
                  right: 24,
                  child: Text(
                    _paused ? 'TAP TO RESUME' : 'TAP TO PAUSE',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                      color: fg.withValues(alpha: 0.3),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(int totalSeconds) {
    if (totalSeconds < 60) return '$totalSeconds';
    final min = totalSeconds ~/ 60;
    final sec = totalSeconds % 60;
    return '$min:${sec.toString().padLeft(2, '0')}';
  }
}
