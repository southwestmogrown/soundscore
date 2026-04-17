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

  // ── JSON encoding for the notes list ─────────────────────────────────────

  /// Encode notes as a compact string: "midiNote,string,fret,confidence;..."
  static String _encodeNotes(List<TabNote> notes) {
    return notes.map((n) {
      return '${n.midiNote},${n.string},${n.fret},${n.confidence}';
    }).join(';');
  }

  /// Decode notes from the compact string format.
  static List<TabNote> _decodeNotes(String encoded) {
    if (encoded.isEmpty) return [];
    return encoded.split(';').map((entry) {
      final parts = entry.split(',');
      return TabNote(
        midiNote: int.parse(parts[0]),
        string: int.parse(parts[1]),
        fret: int.parse(parts[2]),
        confidence: double.parse(parts[3]),
      );
    }).toList();
  }

  @override
  String toString() =>
      'Session(id=$id, name=$name, notes=${notes.length}, instrument=${instrument.name})';
}
