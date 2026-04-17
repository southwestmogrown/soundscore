import 'dart:io';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../music/instrument.dart';
import '../music/tab_note.dart';
import '../dsp/note.dart';

/// Exports tablature data in various formats and shares via the system share sheet.
class TabExportService {
  /// Generate a plain-text tablature representation.
  ///
  /// Example output for guitar:
  /// ```
  /// e|---0---5---3---|
  /// B|---1-------0---|
  /// G|---0-------0---|
  /// D|---2-------0---|
  /// A|---3-------2---|
  /// E|-------3-------|
  /// ```
  static String toText(Instrument instrument, List<TabNote> notes) {
    if (notes.isEmpty) return '(empty tablature)';

    final stringCount = instrument.stringCount;
    // Column width per note
    const colWidth = 4;

    // Build label column (string names, high to low for display)
    final labels = <String>[];
    for (int row = 0; row < stringCount; row++) {
      final tuningIdx = stringCount - 1 - row;
      labels.add(Note(instrument.tuning[tuningIdx]).name);
    }
    final maxLabelLen = labels.fold<int>(0, (m, l) => l.length > m ? l.length : m);

    final buffer = StringBuffer();

    for (int row = 0; row < stringCount; row++) {
      final label = labels[row].padLeft(maxLabelLen);
      buffer.write('$label|');

      for (final note in notes) {
        // note.string 0 = lowest string = bottom row on tab
        final displayRow = stringCount - 1 - note.string;
        if (displayRow == row) {
          final fretStr = note.fret.toString();
          final padding = colWidth - fretStr.length;
          final left = padding ~/ 2;
          final right = padding - left;
          buffer.write('-' * left);
          buffer.write(fretStr);
          buffer.write('-' * right);
        } else {
          buffer.write('-' * colWidth);
        }
      }

      buffer.write('-|');
      buffer.writeln();
    }

    return buffer.toString().trimRight();
  }

  /// Generate a PDF document with the tablature rendered as text.
  static Future<Uint8List> toPdf(
    Instrument instrument,
    List<TabNote> notes, {
    String title = 'SoundScore Tablature',
  }) async {
    final pdf = pw.Document();
    final tabText = toText(instrument, notes);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                '${instrument.name}  •  ${notes.length} notes',
                style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
              ),
              pw.SizedBox(height: 24),
              pw.Text(
                tabText,
                style: pw.TextStyle(
                  fontSize: 14,
                  font: pw.Font.courier(),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Share the tablature as plain text via the system share sheet.
  static Future<void> shareText(
    Instrument instrument,
    List<TabNote> notes,
  ) async {
    final text = toText(instrument, notes);
    await Share.share(
      'SoundScore Tablature\n${instrument.name}\n\n$text',
      subject: 'SoundScore Tablature',
    );
  }

  /// Share the tablature as a PDF file via the system share sheet.
  static Future<void> sharePdf(
    Instrument instrument,
    List<TabNote> notes, {
    String title = 'SoundScore Tablature',
  }) async {
    final pdfBytes = await toPdf(instrument, notes, title: title);

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/soundscore_tab.pdf');
    await file.writeAsBytes(pdfBytes);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf')],
      subject: 'SoundScore Tablature',
    );
  }
}
