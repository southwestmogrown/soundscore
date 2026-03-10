import 'package:flutter/material.dart';
import 'package:soundscore/core/dsp/note.dart';
import 'package:soundscore/core/music/instrument.dart';
import 'package:soundscore/core/music/tab_note.dart';

/// Renders a guitar/bass tablature staff using [CustomPainter].
///
/// The staff shows horizontal string lines (high → low, top → bottom) with
/// fret numbers at each onset column. Place this inside a [CustomPaint] widget
/// whose [size] matches [staffSize].
///
/// Typical usage:
/// ```dart
/// SingleChildScrollView(
///   scrollDirection: Axis.horizontal,
///   child: CustomPaint(
///     size: TabPainter.staffSize(instrument, notes.length),
///     painter: TabPainter(notes: notes, instrument: instrument, ...),
///   ),
/// )
/// ```
class TabPainter extends CustomPainter {
  const TabPainter({
    required this.notes,
    required this.instrument,
    required this.lineColor,
    required this.numberColor,
    required this.backgroundColor,
  });

  final List<TabNote> notes;
  final Instrument    instrument;
  final Color         lineColor;
  final Color         numberColor;
  final Color         backgroundColor;

  // ── Layout constants ──────────────────────────────────────────────────────
  static const double _stringSpacing = 22.0;
  static const double _colWidth      = 44.0;
  static const double _leftMargin    = 36.0;
  static const double _topPadding    = 14.0;
  static const double _bottomPadding = 14.0;

  /// Minimum visible columns before notes start filling the space.
  static const int _minCols = 8;

  /// Total [Size] needed to paint this staff.
  static Size staffSize(Instrument instrument, int noteCount) {
    final cols  = noteCount < _minCols ? _minCols : noteCount;
    final w     = _leftMargin + cols * _colWidth + 8.0;
    final h     = _topPadding +
                  (instrument.stringCount - 1) * _stringSpacing +
                  _bottomPadding;
    return Size(w, h);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color       = lineColor
      ..strokeWidth = 1.0
      ..style       = PaintingStyle.stroke;

    // ── String lines ─────────────────────────────────────────────────────────
    for (int row = 0; row < instrument.stringCount; row++) {
      final y = _yFor(row);
      canvas.drawLine(Offset(_leftMargin, y), Offset(size.width, y), linePaint);
    }

    // ── String labels (high → low on screen, leftmost column) ────────────────
    for (int row = 0; row < instrument.stringCount; row++) {
      // row 0 → highest string (last tuning index)
      final tuningIdx = instrument.stringCount - 1 - row;
      final label     = Note(instrument.tuning[tuningIdx]).name;
      _drawText(
        canvas,
        label,
        Offset(2, _yFor(row) - 7),
        TextStyle(
          color:      lineColor,
          fontSize:   11,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    // ── Note columns ──────────────────────────────────────────────────────────
    final bgPaint = Paint()..color = backgroundColor;

    for (int i = 0; i < notes.length; i++) {
      final note = notes[i];
      final x    = _leftMargin + (i + 0.5) * _colWidth;

      // note.string 0 = lowest string = bottom row on tab
      final row = instrument.stringCount - 1 - note.string;
      final y   = _yFor(row);

      // Erase a small background box so the number sits cleanly on the line.
      final fretStr = note.fret.toString();
      final boxW    = fretStr.length > 1 ? 22.0 : 16.0;
      canvas.drawRect(
        Rect.fromCenter(center: Offset(x, y), width: boxW, height: 16),
        bgPaint,
      );

      // Fret number
      _drawText(
        canvas,
        fretStr,
        Offset(x - boxW / 2 + 1, y - 7),
        TextStyle(
          color:      numberColor,
          fontSize:   13,
          fontWeight: FontWeight.bold,
        ),
      );
    }
  }

  double _yFor(int displayRow) => _topPadding + displayRow * _stringSpacing;

  void _drawText(Canvas canvas, String text, Offset offset, TextStyle style) {
    final painter = TextPainter(
      text:           TextSpan(text: text, style: style),
      textDirection:  TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(TabPainter old) =>
      old.notes != notes ||
      old.instrument != instrument ||
      old.lineColor != lineColor ||
      old.numberColor != numberColor ||
      old.backgroundColor != backgroundColor;
}
