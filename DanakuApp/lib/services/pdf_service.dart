import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../data/app_data.dart';

class PdfService {
  static final PdfService instance = PdfService._init();
  PdfService._init();

  Future<void> generateMonthlyReport(List<Transaksi> transactions, DateTime month) async {
    final pdf = pw.Document();

    final formattedMonth = DateFormat('MMMM yyyy', 'id').format(month);
    final totalIncome = transactions
        .where((t) => t.jenis.toLowerCase() == 'masuk' || t.jenis.toLowerCase() == 'pemasukan')
        .fold(0, (sum, t) => sum + t.jumlah);
    final totalExpense = transactions
        .where((t) => t.jenis.toLowerCase() == 'keluar' || t.jenis.toLowerCase() == 'pengeluaran')
        .fold(0, (sum, t) => sum + t.jumlah);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Laporan Keuangan Danaku", style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
                  pw.Text(formattedMonth, style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Ringkasan Card
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: const pw.BoxDecoration(
                color: PdfColors.pink50,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text("Ringkasan Bulanan", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.pink800)),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("Total Pemasukan:"),
                      pw.Text("Rp ${NumberFormat.decimalPattern('id').format(totalIncome)}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.green)),
                    ],
                  ),
                  pw.SizedBox(height: 6),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("Total Pengeluaran:"),
                      pw.Text("Rp ${NumberFormat.decimalPattern('id').format(totalExpense)}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.red)),
                    ],
                  ),
                  pw.SizedBox(height: 6),
                  pw.Divider(color: PdfColors.pink200),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("Selisih Bersih:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(
                        "Rp ${NumberFormat.decimalPattern('id').format(totalIncome - totalExpense)}",
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: (totalIncome - totalExpense) >= 0 ? PdfColors.teal : PdfColors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 24),

            // Table of Transactions
            pw.Text("Daftar Transaksi", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              headers: ['Tanggal', 'Keterangan', 'Kategori', 'Dompet', 'Tipe', 'Jumlah'],
              data: transactions.map((t) {
                return [
                  DateFormat('dd/MM/yyyy').format(t.tanggal),
                  t.keterangan,
                  t.kategori,
                  t.walletNama,
                  t.jenis.toUpperCase(),
                  "Rp ${NumberFormat.decimalPattern('id').format(t.jumlah)}",
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.pink800),
              rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300))),
              cellAlignment: pw.Alignment.centerLeft,
              cellAlignments: {
                5: pw.Alignment.centerRight,
              },
            ),
          ];
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/Laporan_Danaku_${DateFormat('yyyyMM').format(month)}.pdf");
    await file.writeAsBytes(await pdf.save());

    // Share the PDF file
    await Share.shareXFiles([XFile(file.path)], text: "Laporan Bulanan Danaku - $formattedMonth");
  }
}
