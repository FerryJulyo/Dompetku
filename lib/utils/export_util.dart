// utils/export_util.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../providers/category_provider.dart';

class ExportUtil {
  // Export report map to CSV, return saved path
  static Future<String> exportReportCsv(Map<String, dynamic> report, CategoryProvider cp) async {
    final rows = <List<dynamic>>[];
    rows.add(['Periode', '${report['month']}/${report['year']}']);
    rows.add(['Total Pemasukan', report['total_in']]);
    rows.add(['Total Pengeluaran', report['total_out']]);
    rows.add([]);
    rows.add(['Kategori', 'Pemasukan', 'Pengeluaran']);
    final perCat = report['per_category'] as Map<String, dynamic>;
    perCat.forEach((key, val) {
      final cat = cp.findByKey(key);
      rows.add([cat?.name ?? key, (val['in'] ?? 0), (val['out'] ?? 0)]);
    });
    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/laporan_${report['year']}_${report['month']}.csv');
    await file.writeAsString(csv);
    return file.path;
  }

  // generate simple PDF bytes for report
  static Future<Uint8List> generateReportPdf(Map<String, dynamic> report, CategoryProvider cp) async {
    final doc = pw.Document();
    final perCat = report['per_category'] as Map<String, dynamic>;
    doc.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(children: [
            pw.Text('Laporan Bulanan', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Text('Periode: ${report['month']}/${report['year']}'),
            pw.SizedBox(height: 10),
            pw.Text('Total Pemasukan: ${report['total_in']}'),
            pw.Text('Total Pengeluaran: ${report['total_out']}'),
            pw.SizedBox(height: 10),
            pw.Divider(),
            pw.ListView.builder(
              itemCount: perCat.keys.length,
              itemBuilder: (context, idx) {
                final key = perCat.keys.elementAt(idx);
                final val = perCat[key];
                final cat = cp.findByKey(key);
                return pw.Container(
                    padding: const pw.EdgeInsets.symmetric(vertical: 6),
                    child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                      pw.Text(cat?.name ?? key),
                      pw.Text('In: ${val['in']}  Out: ${val['out']}')
                    ]));
              },
            )
          ]);
        },
      ),
    );
    return doc.save();
  }

  // Save & share PDF (opens share dialog on supported platforms)
  static Future<void> saveAndSharePdf(Uint8List bytes, String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes);
    // use printing to share/open
    await Printing.sharePdf(bytes: bytes, filename: filename);
  }
}