import 'dart:convert';

import 'package:soundscore/core/music/instrument.dart';
import 'package:soundscore/core/music/tab_note.dart';

/// A saved recording session — a snapshot of all notes captured during one
/// recording run, along with the instrument used and session metadata.
class Session {
  final int? id;
  final String name;
  final Instrument instrument;
  final List<TabNote> notes;
  final DateTime createdAt;

  const Session({
    this.id,
    required this.name,
    required this.instrument,
    required this.notes,
    required this.createdAt,
  });

  Session copyWith({
    int? id,
    String? name,
    Instrument? instrument,
    List<TabNote>? notes,
    DateTime? createdAt,
  }) {
    return Session(
      id: id ?? this.id,
      name: name ?? this.name,
      instrument: instrument ?? this.instrument,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Convert to a map suitable for SQLite insertion.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'instrument_name': instrument.name,
      'notes_json': _encodeNotes(notes),
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Reconstruct a [Session] from a SQLite row.
  factory Session.fromMap(Map<String, dynamic> map) {
    final instrumentName = map['instrument_name'] as String;
    final instrument = Instrument.presets.firstWhere(
      (i) => i.name == instrumentName,
      orElse: () => Instrument.guitarStandard,
    );

    return Session(
      id: map['id'] as int?,
      name: map['name'] as String,
      instrument: instrument,
      notes: _decodeNotes(map['notes_json'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  // ── JSON encoding for the notes list ──────────────────────────────────────
  // Schema: [{m: midiNote (int), s: string (int), f: fret (int), c: confidence (double)}]

  /// Encode notes as a JSON array of objects.
  static String _encodeNotes(List<TabNote> notes) {
    return jsonEncode(notes.map((n) => {
      'midi': n.midiNote,
      's': n.string,
      'f': n.fret,
      'c': n.confidence,
    }).toList());
  }

  /// Decode notes from the JSON array format.
  /// Silently returns empty list on malformed JSON.
  static List<TabNote> _decodeNotes(String encoded) {
    if (encoded.isEmpty || encoded == '[]') return [];
    try {
      final list = jsonDecode(encoded) as List<dynamic>;
      return list.map((entry) {
        final map = entry as Map<String, dynamic>;
        return TabNote(
          midiNote: map['midi'] as int,
          string: map['s'] as int,
          fret: map['f'] as int,
          confidence: (map['c'] as num).toDouble(),
        );
      }).toList();
    } catch (_) {
      // Corrupted JSON — return empty rather than crashing
      return [];
    }
  }

  @override
  String toString() =>
      'Session(id=$id, name=$name, notes=${notes.length}, instrument=${instrument.name})';
}
