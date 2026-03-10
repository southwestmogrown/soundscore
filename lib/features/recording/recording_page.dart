import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:soundscore/core/audio/audio_engine.dart';
import 'package:soundscore/core/audio/ffi_bridge.dart';
import 'package:soundscore/core/dsp/chord_result.dart';
import 'package:soundscore/core/permissions/permission_handler_service.dart';
import 'package:soundscore/features/tablature/bloc/tab_bloc.dart';
import 'package:soundscore/features/tablature/bloc/tab_event.dart';
import 'package:soundscore/shared/router/app_router.dart';

import 'bloc/recording_bloc.dart';
import 'bloc/recording_event.dart';
import 'bloc/recording_state.dart';

/// Home screen — real-time pitch / chord / BPM display.
class RecordingPage extends StatelessWidget {
  const RecordingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RecordingBloc(
        audioEngine: RecordAudioEngine(),
        bridge:      DspFfiBridge(),
        permissions: PermissionHandlerService(),
      ),
      child: const _RecordingView(),
    );
  }
}

class _RecordingView extends StatelessWidget {
  const _RecordingView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<RecordingBloc, RecordingState>(
      // Fire when a new onset note arrives (rising edge: false → true).
      listenWhen: (prev, next) =>
          next.latest.isOnset &&
          next.latest.hasPitch &&
          !prev.latest.isOnset,
      listener: (context, state) {
        context.read<TabBloc>().add(TabNoteAdded(
              midiNote:   state.latest.midiNote,
              confidence: state.latest.confidence,
            ));
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('SoundScore'),
          actions: [
            BlocBuilder<RecordingBloc, RecordingState>(
              buildWhen: (p, n) => p.status != n.status,
              builder: (context, state) {
                if (!state.isRecording) return const SizedBox.shrink();
                return IconButton(
                  tooltip:   'Reset session',
                  icon:      const Icon(Icons.refresh),
                  onPressed: () => context
                      .read<RecordingBloc>()
                      .add(const RecordingResetRequested()),
                );
              },
            ),
          ],
        ),
        body: const Column(
          children: [
            Expanded(child: _DetectionDisplay()),
            _RecordButton(),
            SizedBox(height: 32),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push(Routes.tablature),
          icon:      const Icon(Icons.queue_music_rounded),
          label:     const Text('View Tab'),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      ),
    );
  }
}

// ── Detection display ──────────────────────────────────────────────────────

class _DetectionDisplay extends StatelessWidget {
  const _DetectionDisplay();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RecordingBloc, RecordingState>(
      builder: (context, state) {
        final result = state.latest;

        // Permission-denied banner
        if (state.status == RecordingStatus.permissionDenied) {
          return _PermissionDeniedBanner(
            message: state.errorMessage ?? 'Microphone access denied.',
          );
        }

        // Idle / initial state
        if (state.status == RecordingStatus.idle) {
          return const Center(
            child: Text(
              'Tap the button below to start listening.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          );
        }

        final note      = result.note;
        final chord     = ChordResult.fromLabel(result.chordLabel, 1.0);
        final hasPitch  = result.hasPitch;
        final hasChord  = result.hasChord;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Note display ─────────────────────────────────────────────
              _MetricCard(
                label: 'NOTE',
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 120),
                  child: Text(
                    hasPitch ? note!.fullName : '—',
                    key: ValueKey(hasPitch ? note!.fullName : '—'),
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: hasPitch
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outlineVariant,
                        ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Chord + BPM row ───────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      label: 'CHORD',
                      child: Text(
                        hasChord ? chord.label : '—',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              color: hasChord
                                  ? Theme.of(context).colorScheme.secondary
                                  : Theme.of(context).colorScheme.outlineVariant,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _MetricCard(
                      label: 'BPM',
                      child: Text(
                        result.bpm > 0
                            ? result.bpm.toStringAsFixed(0)
                            : '—',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── Confidence + onset row ────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      label: 'CONFIDENCE',
                      child: _ConfidenceBar(value: hasPitch ? result.confidence : 0),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 100,
                    child: _MetricCard(
                      label: 'ONSET',
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 80),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: result.isOnset
                              ? Theme.of(context).colorScheme.tertiary
                              : Theme.of(context).colorScheme.surfaceContainerHighest,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Record button ──────────────────────────────────────────────────────────

class _RecordButton extends StatelessWidget {
  const _RecordButton();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RecordingBloc, RecordingState>(
      buildWhen: (p, n) => p.status != n.status,
      builder: (context, state) {
        final busy = state.status == RecordingStatus.requestingPermission ||
                     state.status == RecordingStatus.stopping;

        if (busy) {
          return const SizedBox(
            width: 72,
            height: 72,
            child: CircularProgressIndicator(),
          );
        }

        final recording = state.isRecording;
        return GestureDetector(
          onTap: () {
            final bloc = context.read<RecordingBloc>();
            if (recording) {
              bloc.add(const RecordingStopRequested());
            } else {
              bloc.add(const RecordingStartRequested());
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width:  72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: recording
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.primary,
              boxShadow: [
                BoxShadow(
                  color: (recording
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.primary)
                      .withValues(alpha: 0.4),
                  blurRadius: recording ? 16 : 8,
                  spreadRadius: recording ? 4 : 0,
                ),
              ],
            ),
            child: Icon(
              recording ? Icons.stop_rounded : Icons.mic_rounded,
              color: Theme.of(context).colorScheme.onPrimary,
              size: 36,
            ),
          ),
        );
      },
    );
  }
}

// ── Supporting widgets ─────────────────────────────────────────────────────

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color:        Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color:          Theme.of(context).colorScheme.outline,
                  letterSpacing:  1.2,
                ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _ConfidenceBar extends StatelessWidget {
  const _ConfidenceBar({required this.value});
  final double value; // 0.0 – 1.0

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value:            value,
        minHeight:        12,
        backgroundColor:  Theme.of(context).colorScheme.surfaceContainerHighest,
        valueColor: AlwaysStoppedAnimation<Color>(
          value > 0.6
              ? Theme.of(context).colorScheme.primary
              : value > 0.3
                  ? Theme.of(context).colorScheme.tertiary
                  : Theme.of(context).colorScheme.error,
        ),
      ),
    );
  }
}

class _PermissionDeniedBanner extends StatelessWidget {
  const _PermissionDeniedBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.mic_off_rounded,
                size: 64, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => PermissionHandlerService().openSettings(),
              icon:  const Icon(Icons.settings_rounded),
              label: const Text('Open Settings'),
            ),
          ],
        ),
      ),
    );
  }
}
