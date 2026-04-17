import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:soundscore/core/export/tab_export_service.dart';
import 'package:soundscore/core/music/instrument.dart';
import 'package:soundscore/core/music/tab_note.dart';

import 'bloc/tab_bloc.dart';
import 'bloc/tab_event.dart';
import 'bloc/tab_state.dart';
import 'tab_painter.dart';

/// Displays the tablature accumulated during the current recording session.
///
/// [TabBloc] is provided at the app level so this page can read notes
/// recorded on the [RecordingPage] without losing state on navigation.
class TabViewerPage extends StatelessWidget {
  const TabViewerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tablature'),
        actions: [
          // ── Instrument selector ─────────────────────────────────────────
          BlocBuilder<TabBloc, TabState>(
            buildWhen: (p, n) => p.instrument != n.instrument,
            builder: (context, state) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: DropdownButton<Instrument>(
                  value:      state.instrument,
                  underline:  const SizedBox.shrink(),
                  isDense:    true,
                  onChanged: (inst) {
                    if (inst != null) {
                      context.read<TabBloc>().add(TabInstrumentChanged(inst));
                    }
                  },
                  items: Instrument.presets.map((inst) {
                    return DropdownMenuItem(
                      value: inst,
                      child: Text(inst.name,
                          style: Theme.of(context).textTheme.bodySmall),
                    );
                  }).toList(),
                ),
              );
            },
          ),
          // ── Clear button ────────────────────────────────────────────────
          IconButton(
            tooltip:   'Clear',
            icon:      const Icon(Icons.delete_sweep_rounded),
            onPressed: () =>
                context.read<TabBloc>().add(const TabCleared()),
          ),
          // ── Share menu ──────────────────────────────────────────────────
          BlocBuilder<TabBloc, TabState>(
            buildWhen: (p, n) => p.notes.length != n.notes.length,
            builder: (context, state) {
              if (state.isEmpty) return const SizedBox.shrink();
              return PopupMenuButton<String>(
                icon: const Icon(Icons.share_rounded),
                tooltip: 'Share / Export',
                onSelected: (value) => _onShareSelected(
                  context, value, state.instrument, state.notes,
                ),
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'text',
                    child: ListTile(
                      leading: Icon(Icons.text_snippet_rounded),
                      title: Text('Share as Text'),
                      dense: true,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'pdf',
                    child: ListTile(
                      leading: Icon(Icons.picture_as_pdf_rounded),
                      title: Text('Share as PDF'),
                      dense: true,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'save',
                    child: ListTile(
                      leading: Icon(Icons.save_rounded),
                      title: Text('Save Session'),
                      dense: true,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<TabBloc, TabState>(
        builder: (context, state) {
          if (state.isEmpty) {
            return const _EmptyState();
          }
          return _TabStaff(state: state);
        },
      ),
    );
  }
}

// ── Share / export handler ─────────────────────────────────────────────────

void _onShareSelected(
  BuildContext context,
  String action,
  Instrument instrument,
  List<TabNote> notes,
) {
  switch (action) {
    case 'text':
      TabExportService.shareText(instrument, notes);
    case 'pdf':
      TabExportService.sharePdf(instrument, notes);
    case 'save':
      _showSaveDialog(context);
  }
}

void _showSaveDialog(BuildContext context) {
  final controller = TextEditingController(
    text: 'Session ${DateTime.now().toString().substring(0, 16)}',
  );

  showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Save Session'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Session name',
            hintText: 'Enter a name for this session',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                context.read<TabBloc>().add(
                      TabSessionSaveRequested(name: name),
                    );
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Session saved')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      );
    },
  );
}

// ── Tab staff ──────────────────────────────────────────────────────────────

class _TabStaff extends StatelessWidget {
  const _TabStaff({required this.state});
  final TabState state;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = TabPainter.staffSize(state.instrument, state.notes.length);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                state.instrument.name,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colorScheme.outline,
                    ),
              ),
              Text(
                '${state.notes.length} note${state.notes.length == 1 ? '' : 's'}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colorScheme.outline,
                    ),
              ),
            ],
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          elevation: 0,
          color: colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: CustomPaint(
                size: size,
                painter: TabPainter(
                  notes:           state.notes,
                  instrument:      state.instrument,
                  lineColor:       colorScheme.onSurface.withValues(alpha: 0.7),
                  numberColor:     colorScheme.onSurface,
                  backgroundColor: colorScheme.surfaceContainerLow,
                ),
              ),
            ),
          ),
        ),
        // ── Note list (secondary reference view) ──────────────────────────
        Expanded(child: _NoteList(state: state)),
      ],
    );
  }
}

// ── Scrollable note list ───────────────────────────────────────────────────

class _NoteList extends StatelessWidget {
  const _NoteList({required this.state});
  final TabState state;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView.builder(
      padding:     const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount:   state.notes.length,
      itemBuilder: (context, i) {
        final note      = state.notes[i];
        final stringNum = state.instrument.stringCount - note.string;
        final openName  = state.instrument.openStringName(note.string);

        return ListTile(
          dense: true,
          leading: CircleAvatar(
            radius:          16,
            backgroundColor: colorScheme.primaryContainer,
            child: Text(
              '${note.fret}',
              style: TextStyle(
                color:      colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
                fontSize:   12,
              ),
            ),
          ),
          title:    Text('String $stringNum ($openName)  •  Fret ${note.fret}'),
          subtitle: Text(
            'MIDI ${note.midiNote}  •  '
            '${(note.confidence * 100).toStringAsFixed(0)}% confidence',
          ),
          trailing: Text(
            '#${i + 1}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.outline,
                ),
          ),
        );
      },
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.queue_music_rounded,
              size:  72,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text('No notes yet',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Play something and tap Record on the home screen.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
