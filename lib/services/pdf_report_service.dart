import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../state/app_state.dart';

const _amber = PdfColor.fromInt(0xFFFFA914);
const _ink = PdfColor.fromInt(0xFF17140F);
const _cream = PdfColor.fromInt(0xFFFFFDF3);
const _alt = PdfColor.fromInt(0xFFF4F6C4);
const _grey = PdfColor.fromInt(0xFF6B6454);
const _green = PdfColor.fromInt(0xFF1B7F37);
const _red = PdfColor.fromInt(0xFFC62828);

String periodLabel(Period p) {
  final n = DateTime.now();
  final mes = DateFormat('MMMM', 'es').format(n);
  final cap = mes[0].toUpperCase() + mes.substring(1);
  switch (p) {
    case Period.week:
      final (a, b) = (AppState.weekStart(n), AppState.weekStart(n).add(const Duration(days: 6)));
      return 'Semana ${DateFormat('d MMM', 'es').format(a)} - ${DateFormat('d MMM yyyy', 'es').format(b)}';
    case Period.month:
      return '$cap de ${n.year}';
    case Period.year:
      return 'Año ${n.year}';
  }
}

String reportFileName(Period p) {
  final n = DateTime.now();
  return switch (p) {
    Period.week => 'Informe_semana_${DateFormat('yyyyMMdd').format(AppState.weekStart(n))}.pdf',
    Period.month => 'Informe_${DateFormat('MMMM', 'es').format(n)}.pdf',
    Period.year => 'Informe_${n.year}.pdf',
  };
}

/// Extracto financiero en PDF (A4) con la paleta de FinTrack, al estilo de un extracto bancario.
Future<Uint8List> buildStatement(AppState s, Period period, String holder, String email) async {
  final doc = pw.Document(title: 'Extracto FinTrack', author: 'FinTrack');
  final list = s.inPeriod(period)..sort((a, b) => a.date.compareTo(b.date));
  final income = AppState.sum(list.where((m) => m.isIncome));
  final spent = AppState.sum(list.where((m) => !m.isIncome));
  final ant = AppState.sum(list.where((m) => m.isAnt));
  final antPct = spent == 0 ? 0 : ant / spent * 100;
  final df = DateFormat('dd/MM/yyyy');
  final antCats = <String, double>{};
  for (final m in list.where((m) => m.isAnt)) {
    antCats[m.category] = (antCats[m.category] ?? 0) + m.amount;
  }
  final antSorted = antCats.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

  pw.Widget cell(String t, {bool bold = false, pw.TextAlign a = pw.TextAlign.left, PdfColor c = _ink, double size = 8.5}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
        child: pw.Text(t,
            textAlign: a,
            style: pw.TextStyle(fontSize: size, color: c, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
      );

  pw.Widget kv(String k, String v, {PdfColor c = _ink, bool bold = false}) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 3),
        child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Text(k, style: const pw.TextStyle(fontSize: 10, color: _ink)),
          pw.Text(v, style: pw.TextStyle(fontSize: 10, color: c, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ]),
      );

  var running = 0.0;
  final rows = <pw.TableRow>[
    pw.TableRow(
      decoration: const pw.BoxDecoration(color: _amber),
      children: [
        cell('Fecha', bold: true),
        cell('Descripcion', bold: true),
        cell('Categoria', bold: true),
        cell('Tipo', bold: true),
        cell('Debito', bold: true, a: pw.TextAlign.right),
        cell('Credito', bold: true, a: pw.TextAlign.right),
        cell('Saldo', bold: true, a: pw.TextAlign.right),
      ],
    ),
  ];
  for (var i = 0; i < list.length; i++) {
    final m = list[i];
    running += m.isIncome ? m.amount : -m.amount;
    rows.add(pw.TableRow(
      decoration: pw.BoxDecoration(color: i.isEven ? _cream : PdfColors.white),
      children: [
        cell(df.format(m.date)),
        cell(m.note.isEmpty ? m.category : m.note),
        cell(m.category),
        cell(m.isIncome ? 'Ingreso' : (m.isAnt ? 'Hormiga' : m.kind[0].toUpperCase() + m.kind.substring(1))),
        cell(m.isIncome ? '' : money(m.amount), a: pw.TextAlign.right, c: _red),
        cell(m.isIncome ? money(m.amount) : '', a: pw.TextAlign.right, c: _green),
        cell(money(running), a: pw.TextAlign.right, bold: true),
      ],
    ));
  }

  doc.addPage(pw.MultiPage(
    pageTheme: const pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.fromLTRB(32, 28, 32, 36),
    ),
    footer: (c) => pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
      pw.Text('FinTrack - extracto generado en el dispositivo. Documento informativo, sin validez contable.',
          style: const pw.TextStyle(fontSize: 7, color: _grey)),
      pw.Text('Pagina ${c.pageNumber} de ${c.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: _grey)),
    ]),
    build: (c) => [
      pw.Container(
        padding: const pw.EdgeInsets.all(14),
        decoration: pw.BoxDecoration(color: _amber, border: pw.Border.all(color: _ink, width: 1.5), borderRadius: pw.BorderRadius.circular(10)),
        child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
          pw.RichText(
              text: pw.TextSpan(style: const pw.TextStyle(fontSize: 26, color: _ink), children: [
            const pw.TextSpan(text: 'Fin'),
            pw.TextSpan(text: 'Track', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ])),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
            pw.Text('EXTRACTO FINANCIERO', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _ink)),
            pw.Text(periodLabel(period), style: const pw.TextStyle(fontSize: 10, color: _ink)),
          ]),
        ]),
      ),
      pw.SizedBox(height: 12),
      pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Expanded(
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('Titular', style: const pw.TextStyle(fontSize: 8, color: _grey)),
            pw.Text(holder, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.Text(email, style: const pw.TextStyle(fontSize: 9, color: _grey)),
          ]),
        ),
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
          pw.Text('Generado el', style: const pw.TextStyle(fontSize: 8, color: _grey)),
          pw.Text(DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()), style: const pw.TextStyle(fontSize: 10)),
          pw.Text('Moneda: COP', style: const pw.TextStyle(fontSize: 9, color: _grey)),
        ]),
      ]),
      pw.SizedBox(height: 12),
      pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(color: _alt, border: pw.Border.all(color: _ink, width: 1), borderRadius: pw.BorderRadius.circular(8)),
        child: pw.Column(children: [
          pw.Align(alignment: pw.Alignment.centerLeft, child: pw.Text('Resumen del periodo', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold))),
          pw.SizedBox(height: 4),
          kv('Total ingresos (creditos)', money(income), c: _green),
          kv('Total gastos (debitos)', money(spent), c: _red),
          kv('Balance del periodo', money(income - spent, sign: true), bold: true),
          pw.Divider(color: _ink, thickness: .5),
          kv('Patrimonio neto', money(s.netWorth), bold: true),
          kv('Gasto hormiga', '${money(ant)} (${antPct.toStringAsFixed(1).replaceAll('.', ',')} %)'),
        ]),
      ),
      pw.SizedBox(height: 14),
      pw.Text('Detalle de movimientos', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 6),
      if (list.isEmpty)
        pw.Text('Sin movimientos en este periodo.', style: const pw.TextStyle(fontSize: 10, color: _grey))
      else
        pw.Table(
          border: const pw.TableBorder(bottom: pw.BorderSide(color: _ink, width: .8), horizontalInside: pw.BorderSide(color: _alt, width: .5)),
          columnWidths: const {
            0: pw.FixedColumnWidth(58),
            1: pw.FlexColumnWidth(2.0),
            2: pw.FlexColumnWidth(1.3),
            3: pw.FixedColumnWidth(60),
            4: pw.FixedColumnWidth(62),
            5: pw.FixedColumnWidth(62),
            6: pw.FixedColumnWidth(66),
          },
          children: rows,
        ),
      if (antSorted.isNotEmpty) ...[
        pw.SizedBox(height: 16),
        pw.Text('Gastos hormiga por categoria', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        for (final e in antSorted)
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 3),
            child: pw.Row(children: [
              pw.SizedBox(width: 90, child: pw.Text(e.key, style: const pw.TextStyle(fontSize: 9))),
              pw.Expanded(
                child: pw.Container(
                  height: 8,
                  decoration: pw.BoxDecoration(color: _alt, borderRadius: pw.BorderRadius.circular(4)),
                  child: pw.Row(children: [
                    pw.Expanded(
                        flex: (e.value / antSorted.first.value * 100).round().clamp(1, 100),
                        child: pw.Container(decoration: pw.BoxDecoration(color: _amber, borderRadius: pw.BorderRadius.circular(4)))),
                    pw.Expanded(flex: 100 - (e.value / antSorted.first.value * 100).round().clamp(1, 100), child: pw.SizedBox()),
                  ]),
                ),
              ),
              pw.SizedBox(width: 70, child: pw.Text(money(e.value), textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 9))),
            ]),
          ),
      ],
    ],
  ));
  return doc.save();
}
