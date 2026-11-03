import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as pth;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import '../services/pdf_report_service.dart';
import '../state/app_state.dart';
import '../theme/fintrack_theme.dart';
import 'common.dart';
import 'shell.dart';

class ReportFile {
  final String path, name;
  final Uint8List bytes;
  ReportFile(this.path, this.name, this.bytes);
}

/// Genera el extracto en PDF y lo guarda en la carpeta de documentos de la app.
Future<ReportFile> createReport(AppState s, Period period) async {
  final bytes = await buildStatement(s, period, s.prefs.name, s.prefs.email);
  final dir = await getApplicationDocumentsDirectory();
  final name = reportFileName(period);
  final f = File(pth.join(dir.path, name));
  await f.writeAsBytes(bytes);
  return ReportFile(f.path, name, bytes);
}

class ReportReadyScreen extends StatelessWidget {
  final ReportFile file;
  const ReportReadyScreen(this.file, {super.key});
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(21),
          child: Column(children: [
            const Spacer(),
            const Ilus('informe-listo', 240),
            const SizedBox(height: 20),
            const Text('¡Informe listo!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('${file.name}. Ábrelo y usa «Compartir» para guardarlo en Descargas o enviarlo.',
                textAlign: TextAlign.center, style: TextStyle(color: p.text2)),
            const Spacer(),
            FtButton('Abrir informe', onTap: () => push(context, ReportViewerScreen(file))),
            const SizedBox(height: 12),
            FtButton('Volver', primary: false, onTap: () => Navigator.pop(context)),
          ]),
        ),
      ),
    );
  }
}

class ReportViewerScreen extends StatelessWidget {
  final ReportFile file;
  const ReportViewerScreen(this.file, {super.key});
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Scaffold(
      backgroundColor: p.alt,
      appBar: AppBar(
        backgroundColor: p.bg,
        scrolledUnderElevation: 0,
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        title: Text(file.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        actions: [
          TextButton(onPressed: () => Printing.sharePdf(bytes: file.bytes, filename: file.name), child: Text('Compartir', style: TextStyle(color: p.text))),
        ],
      ),
      body: PdfPreview(
        build: (_) => file.bytes,
        useActions: false,
        allowPrinting: false,
        allowSharing: false,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        scrollViewDecoration: BoxDecoration(color: p.alt),
        pdfPreviewPageDecoration: BoxDecoration(color: Colors.white, border: Border.all(color: p.ink, width: 1.5), boxShadow: [BoxShadow(color: p.ink, offset: const Offset(4, 4))]),
      ),
    );
  }
}
