import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:driveops_management/features/reports/data/report_pdf_service.dart';
import 'package:driveops_management/features/reports/presentation/providers/reports_providers.dart';
import 'package:driveops_management/shared/models/driver.dart';

enum _RangePreset { allTime, last7Days, last30Days, thisMonth, custom }

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  _RangePreset _preset = _RangePreset.allTime;
  bool _generatingTrips = false;
  bool _generatingScoreboard = false;

  @override
  Widget build(BuildContext context) {
    final tripsReport = ref.watch(tripsReportProvider);
    final scoreboard = ref.watch(driverScoreboardReportProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                children: [
                  _buildTripsReportCard(tripsReport),
                  const SizedBox(height: 16),
                  _buildScoreboardCard(scoreboard),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reports',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Generate PDF reports and print or save them from the system dialog.',
            style: TextStyle(fontSize: 13, color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _buildTripsReportCard(AsyncValue<TripReportData> reportAsync) {
    return _sectionCard(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionIcon(Icons.route_rounded),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trips & Revenue',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Trip volume and revenue for a selected period, with a daily breakdown.',
                    style: TextStyle(fontSize: 12, color: Colors.white54),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _presetChip('All time', _RangePreset.allTime),
            _presetChip('Last 7 days', _RangePreset.last7Days),
            _presetChip('Last 30 days', _RangePreset.last30Days),
            _presetChip('This month', _RangePreset.thisMonth),
            _presetChip('Custom range', _RangePreset.custom),
          ],
        ),
        const SizedBox(height: 16),
        reportAsync.when(
          data: (data) => Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _statTile('Total trips', data.totalTrips.toString()),
              _statTile('Completed', data.completed.toString()),
              _statTile('Cancelled', data.cancelled.toString()),
              _statTile('Revenue', _formatMoney(data.revenue)),
            ],
          ),
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF3B82F6),
              ),
            ),
          ),
          error: (_, _) => const Text(
            'Failed to load trip data.',
            style: TextStyle(color: Color(0xFFEF4444), fontSize: 12),
          ),
        ),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: _generatingTrips ? null : _printTripsReport,
            icon: _generatingTrips
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.print_rounded, size: 18),
            label: Text(
              _generatingTrips ? 'Generating...' : 'Print / Save PDF',
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScoreboardCard(AsyncValue<List<Driver>> scoreboard) {
    return _sectionCard(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionIcon(Icons.emoji_events_rounded),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Driver Performance Scoreboard',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'All drivers ranked by rating, then total trips, including revenue and status.',
                    style: TextStyle(fontSize: 12, color: Colors.white54),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        scoreboard.when(
          data: (drivers) => Text(
            '${drivers.length} drivers available in this report.',
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF3B82F6),
              ),
            ),
          ),
          error: (_, _) => const Text(
            'Failed to load driver data.',
            style: TextStyle(color: Color(0xFFEF4444), fontSize: 12),
          ),
        ),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: _generatingScoreboard ? null : _printScoreboard,
            icon: _generatingScoreboard
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.print_rounded, size: 18),
            label: Text(
              _generatingScoreboard ? 'Generating...' : 'Print / Save PDF',
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF252538),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _sectionIcon(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: const Color(0xFF3B82F6), size: 22),
    );
  }

  Widget _presetChip(String label, _RangePreset preset) {
    final isSelected = _preset == preset;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      showCheckmark: false,
      onSelected: (_) {
        if (preset == _RangePreset.custom) {
          _pickCustomRange();
        } else {
          _applyPreset(preset);
        }
      },
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.white70,
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      backgroundColor: const Color(0xFF1A1A2E),
      selectedColor: const Color(0xFF3B82F6).withValues(alpha: 0.25),
      side: BorderSide(
        color: isSelected ? const Color(0xFF3B82F6) : Colors.white12,
      ),
    );
  }

  Widget _statTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _applyPreset(_RangePreset preset) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final range = switch (preset) {
      _RangePreset.allTime => null,
      _RangePreset.last7Days => DateTimeRange(
        start: today.subtract(const Duration(days: 6)),
        end: today,
      ),
      _RangePreset.last30Days => DateTimeRange(
        start: today.subtract(const Duration(days: 29)),
        end: today,
      ),
      _RangePreset.thisMonth => DateTimeRange(
        start: DateTime(now.year, now.month, 1),
        end: today,
      ),
      _RangePreset.custom => null,
    };

    setState(() => _preset = preset);
    ref.read(reportDateRangeProvider.notifier).setRange(range);
  }

  Future<void> _pickCustomRange() async {
    final current = ref.read(reportDateRangeProvider);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: current,
    );
    if (picked == null) return;

    setState(() => _preset = _RangePreset.custom);
    ref.read(reportDateRangeProvider.notifier).setRange(picked);
  }

  Future<void> _printTripsReport() async {
    final messenger = ScaffoldMessenger.of(context);
    final data = ref.read(tripsReportProvider).value;
    if (data == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Trip data is not available yet.')),
      );
      return;
    }

    setState(() => _generatingTrips = true);
    try {
      final bytes = await ReportPdfService.buildTripsReportPdf(data);
      await Printing.layoutPdf(
        name: _fileName('trips-report'),
        onLayout: (_) async => bytes,
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to generate report: $error')),
      );
    } finally {
      if (mounted) setState(() => _generatingTrips = false);
    }
  }

  Future<void> _printScoreboard() async {
    final messenger = ScaffoldMessenger.of(context);
    final drivers = ref.read(driverScoreboardReportProvider).value;
    if (drivers == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Driver data is not available yet.')),
      );
      return;
    }

    setState(() => _generatingScoreboard = true);
    try {
      final bytes = await ReportPdfService.buildDriverScoreboardPdf(drivers);
      await Printing.layoutPdf(
        name: _fileName('driver-scoreboard'),
        onLayout: (_) async => bytes,
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to generate report: $error')),
      );
    } finally {
      if (mounted) setState(() => _generatingScoreboard = false);
    }
  }

  String _fileName(String prefix) {
    final now = DateTime.now();
    final stamp =
        '${now.year}${_pad(now.month)}${_pad(now.day)}-${_pad(now.hour)}${_pad(now.minute)}';
    return 'driveops-$prefix-$stamp.pdf';
  }

  static String _pad(int value) => value.toString().padLeft(2, '0');

  String _formatMoney(double value) => '\$${value.toStringAsFixed(2)}';
}
