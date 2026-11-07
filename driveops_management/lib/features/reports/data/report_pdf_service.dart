import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:driveops_management/features/reports/presentation/providers/reports_providers.dart';
import 'package:driveops_management/shared/models/driver.dart';

const _brand = PdfColor.fromInt(0xFF3B82F6);
const _dark = PdfColor.fromInt(0xFF1A1A2E);
const _muted = PdfColor.fromInt(0xFF6B7280);
const _line = PdfColor.fromInt(0xFFE5E7EB);
const _surface = PdfColor.fromInt(0xFFF3F4F6);

class ReportPdfService {
  static Future<Uint8List> buildTripsReportPdf(TripReportData data) async {
    final document = pw.Document(title: 'DriveOps Trips & Revenue Report');

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 36, 36, 32),
        header: (_) =>
            _pageHeader('Trips & Revenue Report', _formatPeriod(data.range)),
        footer: _pageFooter,
        build: (_) => [
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              _summaryCell('Total Trips', data.totalTrips.toString()),
              pw.SizedBox(width: 8),
              _summaryCell('Completed', data.completed.toString()),
              pw.SizedBox(width: 8),
              _summaryCell('Cancelled', data.cancelled.toString()),
              pw.SizedBox(width: 8),
              _summaryCell('Revenue', _formatMoney(data.revenue)),
            ],
          ),
          pw.SizedBox(height: 24),
          pw.Text(
            'Daily Breakdown',
            style: const pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: _dark,
            ),
          ),
          pw.SizedBox(height: 8),
          if (data.daily.isEmpty)
            _emptyNotice('No trips found in the selected period.')
          else
            _table(
              headers: const ['Date', 'Trips', 'Completed', 'Revenue'],
              rows: data.daily
                  .map(
                    (day) => [
                      _formatDate(day.date),
                      day.trips.toString(),
                      day.completed.toString(),
                      _formatMoney(day.revenue),
                    ],
                  )
                  .toList(),
              rightAlignedColumns: const {1, 2, 3},
            ),
        ],
      ),
    );

    return document.save();
  }

  static Future<Uint8List> buildDriverScoreboardPdf(
    List<Driver> drivers,
  ) async {
    final document = pw.Document(
      title: 'DriveOps Driver Performance Scoreboard',
    );

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 36, 36, 32),
        header: (_) => _pageHeader(
          'Driver Performance Scoreboard',
          '${drivers.length} drivers',
        ),
        footer: _pageFooter,
        build: (_) => [
          pw.SizedBox(height: 8),
          if (drivers.isEmpty)
            _emptyNotice('No drivers found.')
          else
            _table(
              headers: const [
                'Rank',
                'Driver',
                'Rating',
                'Trips',
                'Revenue',
                'Status',
              ],
              rows: drivers
                  .asMap()
                  .entries
                  .map(
                    (entry) => [
                      '#${entry.key + 1}',
                      entry.value.driverName,
                      entry.value.rating.toStringAsFixed(1),
                      entry.value.totalTrips.toString(),
                      _formatMoney(entry.value.totalRevenue),
                      _statusLabel(entry.value.status),
                    ],
                  )
                  .toList(),
              rightAlignedColumns: const {0, 2, 3, 4},
            ),
        ],
      ),
    );

    return document.save();
  }

  static pw.Widget _pageHeader(String title, String subtitle) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _line, width: 1)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Container(
            width: 30,
            height: 30,
            alignment: pw.Alignment.center,
            decoration: pw.BoxDecoration(
              color: _brand,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Text(
              'D',
              style: const pw.TextStyle(
                color: PdfColors.white,
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'DriveOps',
                  style: const pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: _dark,
                  ),
                ),
                pw.Text(
                  title,
                  style: const pw.TextStyle(fontSize: 11, color: _muted),
                ),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                subtitle,
                style: const pw.TextStyle(fontSize: 9, color: _dark),
              ),
              pw.Text(
                'Generated ${_formatDateTime(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 8, color: _muted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _pageFooter(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 16),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'DriveOps Management',
            style: const pw.TextStyle(fontSize: 8, color: _muted),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: _muted),
          ),
        ],
      ),
    );
  }

  static pw.Widget _summaryCell(String label, String value) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: pw.BoxDecoration(
          color: _surface,
          borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
          border: pw.Border.all(color: _line, width: 0.5),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 8, color: _muted),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              value,
              style: const pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: _dark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _emptyNotice(String message) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: _surface,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Text(
        message,
        style: const pw.TextStyle(fontSize: 10, color: _muted),
      ),
    );
  }

  static pw.Widget _table({
    required List<String> headers,
    required List<List<String>> rows,
    Set<int> rightAlignedColumns = const {},
  }) {
    pw.Alignment alignmentFor(int index) => rightAlignedColumns.contains(index)
        ? pw.Alignment.centerRight
        : pw.Alignment.centerLeft;

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      headerStyle: const pw.TextStyle(
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(color: _dark),
      headerAlignment: pw.Alignment.centerLeft,
      headerAlignments: {
        for (var i = 0; i < headers.length; i++) i: alignmentFor(i),
      },
      cellStyle: const pw.TextStyle(fontSize: 9, color: _dark),
      cellAlignment: pw.Alignment.centerLeft,
      cellAlignments: {
        for (var i = 0; i < headers.length; i++) i: alignmentFor(i),
      },
      border: pw.TableBorder.all(color: _line, width: 0.5),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      headerPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      oddRowDecoration: const pw.BoxDecoration(color: _surface),
    );
  }

  static String _formatPeriod(DateTimeRange? range) {
    if (range == null) return 'All time';
    return '${_formatDate(range.start)} - ${_formatDate(range.end)}';
  }

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  static String _formatDateTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${_formatDate(date)} $hour:$minute';
  }

  static String _formatMoney(double value) => '\$${value.toStringAsFixed(2)}';

  static String _statusLabel(DriverStatus status) {
    final name = status.name;
    return name.isEmpty ? name : name[0].toUpperCase() + name.substring(1);
  }
}
