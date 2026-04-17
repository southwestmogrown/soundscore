import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soundscore/core/music/instrument.dart';

import 'bloc/settings_bloc.dart';
import 'bloc/settings_event.dart';
import 'bloc/settings_state.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          if (!state.isLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              _SectionHeader(title: 'Instrument'),
              _InstrumentTile(current: state.instrument),
              const Divider(),
              _SectionHeader(title: 'Appearance'),
              _ThemeModeTile(current: state.themeMode),
              const Divider(),
              _SectionHeader(title: 'Detection'),
              _ConfidenceThresholdTile(current: state.confidenceThreshold),
              const Divider(),
              _SectionHeader(title: 'About'),
              const _AboutTile(),
            ],
          );
        },
      ),
    );
  }
}

// ── Section header ─────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

// ── Instrument selector ────────────────────────────────────────────────────

class _InstrumentTile extends StatelessWidget {
  const _InstrumentTile({required this.current});
  final Instrument current;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        current.type == InstrumentType.guitar
            ? Icons.music_note_rounded
            : Icons.graphic_eq_rounded,
      ),
      title: const Text('Default Instrument'),
      subtitle: Text(current.name),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showInstrumentPicker(context),
    );
  }

  void _showInstrumentPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Select Instrument',
                  style: Theme.of(bottomSheetContext).textTheme.titleMedium,
                ),
              ),
              ...Instrument.presets.map((inst) {
                return RadioListTile<Instrument>(
                  title: Text(inst.name),
                  subtitle: Text(
                    '${inst.stringCount} strings',
                  ),
                  value: inst,
                  groupValue: current,
                  onChanged: (value) {
                    if (value != null) {
                      context
                          .read<SettingsBloc>()
                          .add(SettingsInstrumentChanged(value));
                      Navigator.of(bottomSheetContext).pop();
                    }
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

// ── Theme mode selector ────────────────────────────────────────────────────

class _ThemeModeTile extends StatelessWidget {
  const _ThemeModeTile({required this.current});
  final String current;

  static const _options = [
    ('system', 'System', Icons.brightness_auto_rounded),
    ('light', 'Light', Icons.light_mode_rounded),
    ('dark', 'Dark', Icons.dark_mode_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(_iconFor(current)),
      title: const Text('Theme'),
      subtitle: Text(_labelFor(current)),
      trailing: SegmentedButton<String>(
        segments: _options
            .map((o) => ButtonSegment<String>(
                  value: o.$1,
                  icon: Icon(o.$3),
                  tooltip: o.$2,
                ))
            .toList(),
        selected: {current},
        onSelectionChanged: (selected) {
          context
              .read<SettingsBloc>()
              .add(SettingsThemeModeChanged(selected.first));
        },
        showSelectedIcon: false,
      ),
    );
  }

  String _labelFor(String mode) {
    return _options.firstWhere((o) => o.$1 == mode, orElse: () => _options[0]).$2;
  }

  IconData _iconFor(String mode) {
    return _options.firstWhere((o) => o.$1 == mode, orElse: () => _options[0]).$3;
  }
}

// ── Confidence threshold slider ────────────────────────────────────────────

class _ConfidenceThresholdTile extends StatelessWidget {
  const _ConfidenceThresholdTile({required this.current});
  final double current;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.tune_rounded),
      title: const Text('Confidence Threshold'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${(current * 100).toStringAsFixed(0)}% — '
              'Higher = fewer false detections'),
          Slider(
            value: current,
            min: 0.05,
            max: 0.5,
            divisions: 9,
            label: '${(current * 100).toStringAsFixed(0)}%',
            onChanged: (value) {
              context
                  .read<SettingsBloc>()
                  .add(SettingsConfidenceThresholdChanged(value));
            },
          ),
        ],
      ),
    );
  }
}

// ── About tile ─────────────────────────────────────────────────────────────

class _AboutTile extends StatelessWidget {
  const _AboutTile();

  @override
  Widget build(BuildContext context) {
    return const ListTile(
      leading: Icon(Icons.info_outline_rounded),
      title: Text('SoundScore'),
      subtitle: Text('Version 1.0.0\nReal-time guitar & bass transcription'),
    );
  }
}

