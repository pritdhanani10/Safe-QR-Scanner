import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/date_helpers.dart';
import '../../models/qr_type.dart';
import '../../models/scan_record.dart';
import '../../models/security_result.dart';
import '../result/result_screen.dart';
import 'history_repository.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final HistoryRepository _repository = HistoryRepository();
  List<ScanRecord> _allScans = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final scans = await _repository.getScans();
    if (mounted) {
      setState(() {
        _allScans = scans;
        _isLoading = false;
      });
    }
  }

  List<ScanRecord> get _filteredScans {
    return _allScans.where((scan) {
      // Filter by type or risk
      if (_selectedFilter == 'URLs' && scan.type != QRType.url) return false;
      if (_selectedFilter == 'UPI' && scan.type != QRType.upi) return false;
      if (_selectedFilter == 'Risky' &&
          scan.securityResult.riskLevel != RiskLevel.high &&
          scan.securityResult.riskLevel != RiskLevel.critical) {
        return false;
      }

      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchTitle = scan.title.toLowerCase().contains(q);
        final matchSub = scan.subtitle.toLowerCase().contains(q);
        final matchRaw = scan.rawContent.toLowerCase().contains(q);
        if (!matchTitle && !matchSub && !matchRaw) return false;
      }

      return true;
    }).toList();
  }

  Map<String, List<ScanRecord>> get _groupedScans {
    final groups = <String, List<ScanRecord>>{};
    for (final scan in _filteredScans) {
      final group = DateHelpers.getRelativeGroup(scan.timestamp);
      groups.putIfAbsent(group, () => []).add(scan);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Scan History',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        actions: [
          if (_allScans.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, size: 22),
              tooltip: 'Clear All History',
              onPressed: _confirmClearAll,
            ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                // Search field
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  decoration: InputDecoration(
                    hintText: 'Search scanned links, payees, texts...',
                    hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    prefixIcon: const Icon(Icons.search, size: 20, color: AppTheme.textMuted),
                    filled: true,
                    fillColor: AppTheme.surfaceElevated,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.surfaceBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.surfaceBorder),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All'),
                      const SizedBox(width: 8),
                      _buildFilterChip('URLs'),
                      const SizedBox(width: 8),
                      _buildFilterChip('UPI'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Risky'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppTheme.surfaceBorder),

          // Content List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : _filteredScans.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadHistory,
                        color: AppTheme.primary,
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          children: _buildGroupedWidgets(),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return ChoiceChip(
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: isSelected ? const Color(0xFF001E28) : AppTheme.textSecondary,
      ),
      selected: isSelected,
      selectedColor: AppTheme.primary,
      backgroundColor: AppTheme.surfaceElevated,
      side: BorderSide(
        color: isSelected ? AppTheme.primary : AppTheme.surfaceBorder,
      ),
      onSelected: (selected) {
        if (selected) setState(() => _selectedFilter = label);
      },
    );
  }

  List<Widget> _buildGroupedWidgets() {
    final list = <Widget>[];
    final groups = _groupedScans;

    for (final entry in groups.entries) {
      list.add(
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 8, left: 4),
          child: Text(
            entry.key.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: AppTheme.textMuted,
            ),
          ),
        ),
      );

      for (final scan in entry.value) {
        list.add(_buildScanItem(scan));
      }
    }

    return list;
  }

  Widget _buildScanItem(ScanRecord scan) {
    final level = scan.securityResult.riskLevel;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: level.backgroundColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: level.color.withOpacity(0.3)),
            ),
            child: Icon(level.icon, size: 20, color: level.color),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  scan.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: level.backgroundColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${scan.securityResult.score}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: level.color,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Text(
                  scan.type.displayName,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
                const Text(' • ', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                Expanded(
                  child: Text(
                    DateHelpers.formatTime(scan.timestamp),
                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),
                ),
              ],
            ),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.textMuted),
            onPressed: () async {
              await _repository.deleteScan(scan.id);
              _loadHistory();
            },
          ),
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ResultScreen(record: scan),
              ),
            );
            _loadHistory();
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.history_toggle_off_rounded, size: 54, color: AppTheme.textMuted),
          const SizedBox(height: 16),
          const Text(
            'No Scans Yet',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            'Codes you scan will be securely logged offline here.',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  void _confirmClearAll() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear Scan History?'),
        content: const Text(
          'This will delete all saved scan logs from your device storage. This action cannot be undone.',
          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.riskCritical),
            child: const Text('Clear All'),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _repository.clearAll();
              _loadHistory();
            },
          ),
        ],
      ),
    );
  }
}
