import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class PdfService {
  static Future<void> generateNutritionReport({
    required String motherName,
    required List<Map<String, dynamic>> motherLogs,
    required List<Map<String, dynamic>> motherGrowth,
    required List<Map<String, dynamic>> childrenData, // List of {name: '', logs: [], growth: []}
  }) async {
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.poppinsRegular();
    final boldFont = await PdfGoogleFonts.poppinsBold();

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
                  pw.Text('Laporan Nutrisi & Pertumbuhan', style: pw.TextStyle(font: boldFont, fontSize: 24, color: PdfColors.teal)),
                  pw.Text(DateFormat('dd MMMM yyyy').format(DateTime.now()), style: pw.TextStyle(font: font, fontSize: 12)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            
            // Mother Section
            pw.Text('PROFIL: $motherName (IBU)', style: pw.TextStyle(font: boldFont, fontSize: 16, color: PdfColors.teal)),
            pw.SizedBox(height: 10),
            _buildSummary(motherLogs, font, boldFont),
            pw.SizedBox(height: 10),
            pw.Text('Riwayat Konsumsi:', style: pw.TextStyle(font: boldFont, fontSize: 12)),
            _buildLogsTable(motherLogs, font, boldFont),
            pw.SizedBox(height: 15),
            pw.Text('Riwayat Pertumbuhan:', style: pw.TextStyle(font: boldFont, fontSize: 12)),
            _buildGrowthTable(motherGrowth, font, boldFont),
            
            pw.SizedBox(height: 30),

            // Children Sections
            for (var child in childrenData) ...[
              pw.Text('PROFIL: ${child['name']} (ANAK)', style: pw.TextStyle(font: boldFont, fontSize: 16, color: PdfColors.orange)),
              pw.SizedBox(height: 10),
              _buildSummary(child['logs'], font, boldFont),
              pw.SizedBox(height: 10),
              pw.Text('Riwayat Konsumsi:', style: pw.TextStyle(font: boldFont, fontSize: 12)),
              _buildLogsTable(child['logs'], font, boldFont),
              pw.SizedBox(height: 15),
              pw.Text('Riwayat Pertumbuhan:', style: pw.TextStyle(font: boldFont, fontSize: 12)),
              _buildGrowthTable(child['growth'], font, boldFont),
              pw.SizedBox(height: 30),
            ],
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Laporan_Nutrivision_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  static pw.Widget _buildSummary(List<Map<String, dynamic>> logs, pw.Font font, pw.Font boldFont) {
    double totalCal = 0;
    double totalProt = 0;
    double totalCarbs = 0;

    for (var log in logs) {
      totalCal += double.tryParse(log['calories']?.toString() ?? '0') ?? 0.0;
      totalProt += double.tryParse(log['protein']?.toString() ?? '0') ?? 0.0;
      totalCarbs += double.tryParse(log['carbs']?.toString() ?? '0') ?? 0.0;
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('Total Kalori', '${totalCal.toStringAsFixed(0)} kkal', boldFont, font),
          _buildSummaryItem('Total Protein', '${totalProt.toStringAsFixed(1)}g', boldFont, font),
          _buildSummaryItem('Total Karbo', '${totalCarbs.toStringAsFixed(1)}g', boldFont, font),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryItem(String label, String value, pw.Font boldFont, pw.Font font) {
    return pw.Column(
      children: [
        pw.Text(label, style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey700)),
        pw.Text(value, style: pw.TextStyle(font: boldFont, fontSize: 14, color: PdfColors.teal700)),
      ],
    );
  }

  static pw.Widget _buildLogsTable(List<Map<String, dynamic>> logs, pw.Font font, pw.Font boldFont) {
    if (logs.isEmpty) return pw.Text('Belum ada data konsumsi.', style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey));

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.teal50),
          children: [
            pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Tanggal', style: pw.TextStyle(font: boldFont, fontSize: 9))),
            pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Makanan', style: pw.TextStyle(font: boldFont, fontSize: 9))),
            pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Kalori', style: pw.TextStyle(font: boldFont, fontSize: 9))),
            pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Protein', style: pw.TextStyle(font: boldFont, fontSize: 9))),
          ],
        ),
        for (var log in logs)
          pw.TableRow(
            children: [
              pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(log['date'] ?? '-', style: pw.TextStyle(font: font, fontSize: 8))),
              pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(log['name'] ?? '-', style: pw.TextStyle(font: font, fontSize: 8))),
              pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${log['calories']} kkal', style: pw.TextStyle(font: font, fontSize: 8))),
              pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${log['protein']}g', style: pw.TextStyle(font: font, fontSize: 8))),
            ],
          ),
      ],
    );
  }

  static pw.Widget _buildGrowthTable(List<Map<String, dynamic>> growth, pw.Font font, pw.Font boldFont) {
    if (growth.isEmpty) return pw.Text('Belum ada data pertumbuhan.', style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey));

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.orange50),
          children: [
            pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Tanggal', style: pw.TextStyle(font: boldFont, fontSize: 9))),
            pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('BB (kg)', style: pw.TextStyle(font: boldFont, fontSize: 9))),
            pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('TB (cm)', style: pw.TextStyle(font: boldFont, fontSize: 9))),
            pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Status', style: pw.TextStyle(font: boldFont, fontSize: 9))),
          ],
        ),
        for (var record in growth)
          pw.TableRow(
            children: [
              pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(record['date'] ?? '-', style: pw.TextStyle(font: font, fontSize: 8))),
              pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${record['weight']}', style: pw.TextStyle(font: font, fontSize: 8))),
              pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('${record['height']}', style: pw.TextStyle(font: font, fontSize: 8))),
              pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(record['status'] ?? '-', style: pw.TextStyle(font: font, fontSize: 8))),
            ],
          ),
      ],
    );
  }
}
