import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import '../viewmodels/expense_viewmodel.dart';
import '../services/pdf_report_service.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final TextEditingController _nameController = TextEditingController(text: 'Juan Sebastián Martínez');
  bool _isExporting = false;

  Future<void> _downloadPdf(BuildContext context, ExpenseViewModel vm) async {
    HapticFeedback.mediumImpact();
    setState(() => _isExporting = true);

    try {
      final file = await PdfReportService.savePdfLocally(
        viewModel: vm,
        studentName: _nameController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.teal.shade800,
            behavior: SnackBarBehavior.floating,
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Informe PDF guardado:\n${file.path.split("/").last}'),
                ),
              ],
            ),
            action: SnackBarAction(
              label: 'Compartir',
              textColor: Colors.amber,
              onPressed: () => PdfReportService.shareOrPrintPdf(
                viewModel: vm,
                studentName: _nameController.text.trim(),
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _sharePdf(ExpenseViewModel vm) async {
    HapticFeedback.mediumImpact();
    await PdfReportService.shareOrPrintPdf(
      viewModel: vm,
      studentName: _nameController.text.trim(),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<ExpenseViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Informe Contable Personal (PDF)', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'Compartir o Imprimir PDF',
            icon: const Icon(Icons.share),
            onPressed: () => _sharePdf(vm),
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner de Configuración Rápida del Reporte
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.teal.shade50,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre en el informe',
                      isDense: true,
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person, size: 20),
                    ),
                    onSubmitted: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: _isExporting ? null : () => _downloadPdf(context, vm),
                  icon: _isExporting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.download, size: 18),
                  label: const Text('Descargar'),
                  style: FilledButton.styleFrom(backgroundColor: Colors.teal),
                ),
              ],
            ),
          ),

          // Visor y Previsualización Interactiva del PDF
          Expanded(
            child: PdfPreview(
              build: (format) => PdfReportService.generatePdf(
                viewModel: vm,
                studentName: _nameController.text.trim(),
              ),
              canChangeOrientation: false,
              canChangePageFormat: false,
              canDebug: false,
              dynamicLayout: false,
              previewPageMargin: const EdgeInsets.all(12),
              pdfFileName: 'FinTrack_Informe_Contable.pdf',
              loadingWidget: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Generando plantilla editorial del informe...'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
