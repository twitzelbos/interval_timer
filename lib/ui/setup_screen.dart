import 'package:flutter/material.dart';

import 'timer_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  static const _intervalOptions = [15, 30, 45, 60, 90, 120];
  static const _roundOptions = [5, 10, 15, 20, 25];

  int _onSeconds = 30;
  int _offSeconds = 15;
  int _rounds = 10;

  String _formatInterval(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final min = seconds ~/ 60;
    final sec = seconds % 60;
    return sec == 0 ? '${min}m' : '${min}m${sec}s';
  }

  String _formatTotal() {
    final totalSeconds = (_onSeconds + _offSeconds) * _rounds;
    final min = totalSeconds ~/ 60;
    final sec = totalSeconds % 60;
    if (sec == 0) return '${min}m';
    return '${min}m ${sec}s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'INTERVAL TIMER',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 6,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ON interval
                    Expanded(
                      child: _SelectorColumn(
                        label: 'WORK',
                        color: const Color(0xFF22C55E),
                        options: _intervalOptions,
                        selected: _onSeconds,
                        format: _formatInterval,
                        onSelected: (v) => setState(() => _onSeconds = v),
                      ),
                    ),
                    const SizedBox(width: 24),
                    // OFF interval
                    Expanded(
                      child: _SelectorColumn(
                        label: 'REST',
                        color: const Color(0xFFEF4444),
                        options: _intervalOptions,
                        selected: _offSeconds,
                        format: _formatInterval,
                        onSelected: (v) => setState(() => _offSeconds = v),
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Rounds
                    Expanded(
                      child: _SelectorColumn(
                        label: 'ROUNDS',
                        color: const Color(0xFF3B82F6),
                        options: _roundOptions,
                        selected: _rounds,
                        format: (v) => '$v',
                        onSelected: (v) => setState(() => _rounds = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Total: ${_formatTotal()}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white38,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 220,
                  height: 56,
                  child: FilledButton(
                    onPressed: _start,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF22C55E),
                      foregroundColor: Colors.black,
                      textStyle: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('START'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _start() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TimerScreen(
          onSeconds: _onSeconds,
          offSeconds: _offSeconds,
          rounds: _rounds,
        ),
      ),
    );
  }
}

class _SelectorColumn extends StatelessWidget {
  final String label;
  final Color color;
  final List<int> options;
  final int selected;
  final String Function(int) format;
  final ValueChanged<int> onSelected;

  const _SelectorColumn({
    required this.label,
    required this.color,
    required this.options,
    required this.selected,
    required this.format,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 3,
            color: color,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: options.map((v) {
            final isSelected = v == selected;
            return GestureDetector(
              onTap: () => onSelected(v),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? color : color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? color : color.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  format(v),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.black : color,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
