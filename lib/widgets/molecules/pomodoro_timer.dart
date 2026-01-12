import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/theme_constants.dart';
import 'circular_timer.dart';

/// Pomodoro session phase
enum PomodoroPhase {
  work,
  shortBreak,
  longBreak,
}

/// A Pomodoro timer with work/break intervals.
/// Follows the classic 25/5/15 pattern by default.
class PomodoroTimer extends StatefulWidget {
  /// Work session duration in minutes
  final int workMinutes;

  /// Short break duration in minutes
  final int shortBreakMinutes;

  /// Long break duration in minutes
  final int longBreakMinutes;

  /// Number of work sessions before a long break
  final int sessionsBeforeLongBreak;

  /// Size of the timer
  final double size;

  /// Callback when a phase completes
  final ValueChanged<PomodoroPhase>? onPhaseComplete;

  /// Callback when all sessions complete
  final VoidCallback? onAllComplete;

  const PomodoroTimer({
    super.key,
    this.workMinutes = 25,
    this.shortBreakMinutes = 5,
    this.longBreakMinutes = 15,
    this.sessionsBeforeLongBreak = 4,
    this.size = 280,
    this.onPhaseComplete,
    this.onAllComplete,
  });

  @override
  State<PomodoroTimer> createState() => _PomodoroTimerState();
}

class _PomodoroTimerState extends State<PomodoroTimer> {
  PomodoroPhase _currentPhase = PomodoroPhase.work;
  int _completedSessions = 0;
  final GlobalKey<CircularTimerState> _timerKey = GlobalKey();

  Color get _phaseColor {
    switch (_currentPhase) {
      case PomodoroPhase.work:
        return const Color(0xFFFF6B35); // Orange
      case PomodoroPhase.shortBreak:
        return ThemeConstants.polyMint400;
      case PomodoroPhase.longBreak:
        return ThemeConstants.polyPurple300;
    }
  }

  String get _phaseLabel {
    switch (_currentPhase) {
      case PomodoroPhase.work:
        return 'FOCUS';
      case PomodoroPhase.shortBreak:
        return 'SHORT BREAK';
      case PomodoroPhase.longBreak:
        return 'LONG BREAK';
    }
  }

  int get _phaseDurationSeconds {
    switch (_currentPhase) {
      case PomodoroPhase.work:
        return widget.workMinutes * 60;
      case PomodoroPhase.shortBreak:
        return widget.shortBreakMinutes * 60;
      case PomodoroPhase.longBreak:
        return widget.longBreakMinutes * 60;
    }
  }

  void _onPhaseComplete() {
    widget.onPhaseComplete?.call(_currentPhase);

    setState(() {
      if (_currentPhase == PomodoroPhase.work) {
        _completedSessions++;

        if (_completedSessions >= widget.sessionsBeforeLongBreak) {
          _currentPhase = PomodoroPhase.longBreak;
          _completedSessions = 0;
        } else {
          _currentPhase = PomodoroPhase.shortBreak;
        }
      } else {
        // After any break, go back to work
        _currentPhase = PomodoroPhase.work;
      }
    });

    HapticFeedback.heavyImpact();
  }

  void _skipPhase() {
    _timerKey.currentState?.reset();
    _onPhaseComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Phase indicator pills
        _buildPhaseIndicators(),
        const SizedBox(height: 24),

        // Timer
        CircularTimer(
          key: ValueKey('${_currentPhase}_$_completedSessions'),
          durationSeconds: _phaseDurationSeconds,
          mode: TimerMode.countdown,
          size: widget.size,
          progressColor: _phaseColor,
          label: _phaseLabel,
          onComplete: _onPhaseComplete,
          showControls: true,
        ),

        const SizedBox(height: 24),

        // Skip button
        TextButton.icon(
          onPressed: _skipPhase,
          icon: Icon(Icons.skip_next, color: _phaseColor),
          label: Text(
            'Skip to ${_currentPhase == PomodoroPhase.work ? 'break' : 'work'}',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _phaseColor,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Session counter
        Text(
          'Session ${_completedSessions + 1} of ${widget.sessionsBeforeLongBreak}',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.white54,
          ),
        ),
      ],
    );
  }

  Widget _buildPhaseIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.sessionsBeforeLongBreak, (index) {
        final isCompleted = index < _completedSessions;
        final isCurrent = index == _completedSessions && _currentPhase == PomodoroPhase.work;

        return Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? const Color(0xFFFF6B35)
                : isCurrent
                    ? const Color(0xFFFF6B35).withValues(alpha: 0.5)
                    : Colors.white24,
            border: isCurrent
                ? Border.all(color: const Color(0xFFFF6B35), width: 2)
                : null,
          ),
        );
      }),
    );
  }
}
