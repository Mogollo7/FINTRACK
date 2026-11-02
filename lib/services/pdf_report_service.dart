import 'dart:io';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/expense.dart';
import '../viewmodels/expense_viewmodel.dart';

class PdfReportService {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'es_CO',
    symbol: '\$',
    decimalDigits: 0,
  );
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  /// Genera los bytes del documento PDF con diseño editorial completo
  static Future<Uint8List> generatePdf({
    required ExpenseViewModel viewModel,
    String studentName = 'Estudiante Universitario',
  }) async {
    final pdf = pw.Document();

    final now = DateTime.now();
    final expenses = viewModel.expenses;
    final totalSpent = viewModel.totalSpent;
    final budget = viewModel.weeklyBudget;
    final remaining = viewModel.remainingBudget;
    final percentConsumed = (viewModel.budgetProgressPercentage * 100).toInt();

    // Agrupación por categoría
    final Map<String, double> categoryTotals = {};
    for (var exp in expenses) {
      categoryTotals[exp.category] = (categoryTotals[exp.category] ?? 0.0) + exp.amount;
    }
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Colores corporativos FinTrack
    const primaryTeal = PdfColor.fromInt(0xFF00695C); // Teal 800
    const accentAmber = PdfColor.fromInt(0xFFFFA914); // Amber 500
    const darkBg = PdfColor.fromInt(0xFF0F0D09); // Night 950
    const lightGrey = PdfColor.fromInt(0xFFF5F5F5);
    const borderGrey = PdfColor.fromInt(0xFFE0E0E0);
    const textGrey = PdfColor.fromInt(0xFF555555);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // ENCABEZADO PRINCIPAL
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: primaryTeal,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'FinTrack',
                      style: pw.TextStyle(
                        fontSize: 26,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.Text(
                      'Reporte Contable Personal & Dinero Invisible',
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColor.fromInt(0xFFB2DFDB),
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Fecha: ${DateFormat('dd/MM/yyyy').format(now)}',
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.white),
                    ),
                    pw.Text(
                      'Usuario: $studentName',
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.white),
                    ),
                    pw.Text(
                      'Periodo: Semana en curso',
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // TARJETAS DE INDICADORES FINANCIEROS (KPIS)
          pw.Row(
            children: [
              _buildKpiCard(
                title: 'Total Gastos Hormiga',
                value: _currencyFormat.format(totalSpent),
                color: totalSpent > budget ? PdfColors.red700 : primaryTeal,
              ),
              pw.SizedBox(width: 8),
              _buildKpiCard(
                title: 'Presupuesto Semanal',
                value: _currencyFormat.format(budget),
                color: primaryTeal,
              ),
              pw.SizedBox(width: 8),
              _buildKpiCard(
                title: 'Presupuesto Restante',
                value: _currencyFormat.format(remaining),
                color: remaining > 0 ? primaryTeal : PdfColors.red700,
              ),
              pw.SizedBox(width: 8),
              _buildKpiCard(
                title: 'Consumo',
                value: '$percentConsumed%',
                color: percentConsumed >= 100
                    ? PdfColors.red700
                    : percentConsumed >= 80
                        ? PdfColors.orange700
                        : primaryTeal,
              ),
            ],
          ),
          pw.SizedBox(height: 16),

          // SECCIÓN: CONCIENCIA FINANCIERA Y EQUIVALENCIA COTIDIANA
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFFFF8E1), // Amber claro
              border: pw.Border.all(color: accentAmber, width: 1),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Row(
              children: [
                pw.Container(
                  width: 8,
                  height: 36,
                  color: accentAmber,
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'EQUIVALENCIA DEL DINERO INVISIBLE:',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromInt(0xFFE65100),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        viewModel.dynamicEquivalence,
                        style: const pw.TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // SECCIÓN: DISTRIBUCIÓN POR CATEGORÍAS
          pw.Text(
            'Distribución de Gastos por Categoría',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: darkBg),
          ),
          pw.SizedBox(height: 8),
          if (sortedCategories.isEmpty)
            pw.Text('No hay consumos registrados en este periodo.',
                style: const pw.TextStyle(fontSize: 11, color: textGrey))
          else
            pw.Table(
              border: pw.TableBorder.all(color: borderGrey, width: 0.5),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: lightGrey),
                  children: [
                    _tableCell('Categoría', isHeader: true),
                    _tableCell('Total (\$ COP)', isHeader: true, alignRight: true),
                    _tableCell('% del Gasto Hormiga', isHeader: true, alignRight: true),
                  ],
                ),
                ...sortedCategories.map((entry) {
                  final catPct = totalSpent > 0 ? (entry.value / totalSpent * 100).toStringAsFixed(1) : '0';
                  return pw.TableRow(
                    children: [
                      _tableCell(entry.key),
                      _tableCell(_currencyFormat.format(entry.value), alignRight: true),
                      _tableCell('$catPct %', alignRight: true),
                    ],
                  );
                }),
              ],
            ),
          pw.SizedBox(height: 18),

          // SECCIÓN: DETALLE DE MOVIMIENTOS REGISTRADOS
          pw.Text(
            'Historial Detallado de Microgastos',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: darkBg),
          ),
          pw.SizedBox(height: 8),
          if (expenses.isEmpty)
            pw.Text('No existen transacciones en el historial local.',
                style: const pw.TextStyle(fontSize: 11, color: textGrey))
          else
            pw.Table(
              border: pw.TableBorder.all(color: borderGrey, width: 0.5),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: lightGrey),
                  children: [
                    _tableCell('Fecha / Hora', isHeader: true),
                    _tableCell('Categoría', isHeader: true),
                    _tableCell('Nota / Concepto', isHeader: true),
                    _tableCell('Comprobante', isHeader: true),
                    _tableCell('Monto', isHeader: true, alignRight: true),
                  ],
                ),
                ...expenses.map((e) {
                  return pw.TableRow(
                    children: [
                      _tableCell(_dateFormat.format(e.date)),
                      _tableCell(e.category),
                      _tableCell(e.note.isEmpty ? '—' : e.note),
                      _tableCell(e.photoPath != null ? 'Foto adjunta' : 'Sin foto'),
                      _tableCell(_currencyFormat.format(e.amount),
                          alignRight: true, color: PdfColors.red800),
                    ],
                  );
                }),
              ],
            ),
          pw.SizedBox(height: 20),

          // RESUMEN PATRIMONIAL ESTIMADO (RF-12)
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: primaryTeal, width: 0.8),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Balance Patrimonial Simplificado (RF-12)',
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: primaryTeal),
                ),
                pw.SizedBox(height: 6),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Ingreso estimado de referencia:', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text(_currencyFormat.format(1200000),
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('(-) Total gastos hormiga acumulados:', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('- ${_currencyFormat.format(totalSpent)}',
                        style: pw.TextStyle(fontSize: 10, color: PdfColors.red800)),
                  ],
                ),
                pw.Divider(color: borderGrey, thickness: 0.5),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('(=) Margen disponible para ahorro:',
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    pw.Text(
                      _currencyFormat.format(1200000 - totalSpent),
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryTeal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 24),

          // PIE DE PÁGINA
          pw.Center(
            child: pw.Text(
              'FinTrack Móvil · Proyecto Académico · Corporación Universitaria Lasallista (2026)',
              style: const pw.TextStyle(fontSize: 9, color: textGrey),
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildKpiCard({
    required String title,
    required String value,
    required PdfColor color,
  }) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: color, width: 1),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              title,
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 8, color: PdfColor.fromInt(0xFF555555)),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              value,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _tableCell(
    String text, {
    bool isHeader = false,
    bool alignRight = false,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
        style: pw.TextStyle(
          fontSize: isHeader ? 9 : 8.5,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? (isHeader ? PdfColors.black : const PdfColor.fromInt(0xFF333333)),
        ),
      ),
    );
  }

  /// Guarda el archivo PDF en el almacenamiento local del dispositivo Android
  static Future<File> savePdfLocally({
    required ExpenseViewModel viewModel,
    String studentName = 'Estudiante',
  }) async {
    final bytes = await generatePdf(viewModel: viewModel, studentName: studentName);
    final outputDir = await getApplicationDocumentsDirectory();
    final fileName = 'FinTrack_Informe_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf';
    final file = File('${outputDir.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file;
  }

  /// Abre el diálogo nativo de Android para compartir o guardar el PDF
  static Future<void> shareOrPrintPdf({
    required ExpenseViewModel viewModel,
    String studentName = 'Estudiante',
  }) async {
    final bytes = await generatePdf(viewModel: viewModel, studentName: studentName);
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'FinTrack_Informe_Contable.pdf',
    );
  }
}
