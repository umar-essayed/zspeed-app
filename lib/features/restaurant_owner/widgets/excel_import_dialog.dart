import 'dart:convert';
import 'dart:io' as io;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:z_speed/core/enums/user_enums.dart';
import 'package:z_speed/core/utils/download_bytes.dart';
import 'package:z_speed/features/restaurant/model/menu_item_variant.dart';
import 'package:z_speed/features/restaurant_owner/cubit/restaurant_menu_cubit.dart';
import 'package:z_speed/features/restaurant_owner/services/menu_excel_service.dart';
import 'package:z_speed/l10n/app_localizations.dart';

// Top-level function required by compute() — closures cannot be sent across isolates.
// Phase 1: Decodes the Excel file and returns raw string values per row (CPU-heavy).
List<List<String>> _extractRawRows(List<int> bytes) =>
    MenuExcelService.extractRawRows(bytes);

/// 3-phase bulk-import dialog for menu items.
///
/// Phase 1 — Landing:  Download template OR upload a file.
/// Phase 2 — Preview:  Show parsed rows; highlight errors.
/// Phase 3 — Progress: Import in progress with a counter.
class ExcelImportDialog extends StatefulWidget {
  final RestaurantMenuCubit cubit;
  final VendorType vendorType;
  final List<String> sectionNames;

  const ExcelImportDialog({
    super.key,
    required this.cubit,
    required this.vendorType,
    required this.sectionNames,
  });

  @override
  State<ExcelImportDialog> createState() => _ExcelImportDialogState();
}

enum _ImportPhase { landing, preview, importing, done }

class _ExcelImportDialogState extends State<ExcelImportDialog> {
  _ImportPhase _phase = _ImportPhase.landing;

  // Parsed rows from the uploaded file
  List<Map<String, dynamic>> _rows = [];
  int _importedCount = 0;
  int _totalCount = 0;
  List<String> _skippedLog = [];
  String? _downloadError;
  String? _uploadError;

  // Upload / parse states
  bool _isFilePicking = false; // file picker dialog is open
  bool _isParsing = false; // Excel is being decoded / rows validated
  double _parseProgress = 0.0; // 0.0–1.0 row-validation progress

  List<Map<String, dynamic>> get _validRows =>
      _rows.where((r) => !r.containsKey('error')).toList();

  // ── Download template ───────────────────────────────────────────────────────

  Future<void> _downloadTemplate() async {
    setState(() => _downloadError = null);
    try {
      final bytes = MenuExcelService.generateTemplate(
        sectionNames: widget.sectionNames,
        vendorTypeLabel: widget.vendorType.label,
      );
      final label = widget.vendorType.label.toLowerCase().replaceAll(' ', '_');
      final fileName = '${label}_menu_template.xlsx';
      await downloadBytes(
        bytes,
        fileName,
        '${widget.vendorType.label} Menu Import Template',
      );
    } catch (e) {
      debugPrint('Excel Import Error (Download): $e');
      if (!mounted) return;

      final l10n = AppLocalizations.of(context);
      setState(
        () => _downloadError =
            l10n?.excelImportFailedTemplate('') ?? 'Excel import failed',
      );
    }
  }

  // ── Upload & parse ──────────────────────────────────────────────────────────

  Future<void> _pickAndParse() async {
    // Clear previous errors; wait for the user to select a file before
    // showing any loading state so the button doesn't prematurely say "Parsing".
    setState(() {
      _uploadError = null;
      _isFilePicking = true;
    });

    try {
      // withReadStream = true: the picker returns as soon as the user taps a
      // file (no byte-loading delay), so "Choosing file…" is brief and accurate.
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      // User cancelled the picker — reset quietly.
      if (result == null || result.files.isEmpty) {
        if (mounted) setState(() => _isFilePicking = false);
        return;
      }

      final file = result.files.first;
      final totalBytes = file.size;

      if (await file.readAsByteStream().isEmpty) {
        if (!mounted) return;
        setState(() {
          _isFilePicking = false;
          _uploadError = AppLocalizations.of(context)!.excelImportCouldNotRead;
        });
        return;
      }

      // Picker returned — switch to the reading phase immediately.
      if (!mounted) return;
      setState(() {
        _isFilePicking = false;
        _isParsing = true;
        _parseProgress = 0.0;
      });

      // ── Phase 1: stream file bytes with real reading progress (0 → 40 %) ─────
      final bytes = <int>[];
      int bytesLoaded = 0;

      await for (final chunk in file.readAsByteStream()) {
        bytes.addAll(chunk);
        bytesLoaded += chunk.length;
        if (mounted && totalBytes > 0) {
          setState(() => _parseProgress = (bytesLoaded / totalBytes) * 0.4);
        }
      }

      if (bytes.isEmpty) {
        if (!mounted) return;
        setState(() {
          _isParsing = false;
          _uploadError = AppLocalizations.of(context)!.excelImportCouldNotRead;
        });
        return;
      }

      // ── Phase 2: decode Excel off-thread (40 → 50 %, indeterminate) ──────────
      if (mounted) setState(() => _parseProgress = 0.4);
      final rawRows = await compute(_extractRawRows, bytes);
      if (mounted) setState(() => _parseProgress = 0.5);

      if (!mounted) return;
      if (rawRows.isEmpty) {
        setState(() => _isParsing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.excelImportNoData),
            backgroundColor: const Color(0xFFD32F2F),
          ),
        );
        return;
      }

      // ── Phase 3: validate rows on the main thread in chunks (50 → 100 %) ─────
      final parsed = <Map<String, dynamic>>[];
      const chunkSize = 500;
      final total = rawRows.length;

      for (int start = 0; start < total; start += chunkSize) {
        final end = start + chunkSize < total ? start + chunkSize : total;
        for (int j = start; j < end; j++) {
          final map = MenuExcelService.parseRawRow(
            rawRows[j],
            j + 3,
            widget.sectionNames,
          );
          if (map != null) parsed.add(map);
        }
        if (mounted) setState(() => _parseProgress = 0.5 + (end / total) * 0.5);
        await Future<void>.delayed(Duration.zero);
      }

      if (!mounted) return;
      if (parsed.isEmpty) {
        setState(() => _isParsing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.excelImportNoData),
            backgroundColor: const Color(0xFFD32F2F),
          ),
        );
        return;
      }

      setState(() {
        _isParsing = false;
        _rows = parsed;
        _phase = _ImportPhase.preview;
      });
    } catch (e) {
      debugPrint('Excel Import Error (Upload/Parse): $e');
      if (!mounted) return;
      setState(() {
        _isFilePicking = false;
        _isParsing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.excelImportFailedRead(e.toString()),
          ),
          backgroundColor: const Color(0xFFD32F2F),
        ),
      );
    }
  }

  // ── Confirm import ──────────────────────────────────────────────────────────

  Future<void> _confirmImport() async {
    setState(() {
      _phase = _ImportPhase.importing;
      _importedCount = 0;
      _totalCount = 0;
    });

    try {
      _skippedLog = await widget.cubit.batchImportFromRows(
        _rows,
        widget.vendorType,
        (done, total) {
          if (mounted) {
            setState(() {
              _importedCount = done;
              _totalCount = total;
            });
          }
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _phase = _ImportPhase.preview);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.excelImportFailed),
          backgroundColor: const Color(0xFFD32F2F),
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _phase = _ImportPhase.done);

    if (_skippedLog.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(
              context,
            )!.excelImportSuccessCount(_importedCount),
          ),
          backgroundColor: const Color(0xFF388E3C),
        ),
      );
      Navigator.of(context).pop();
    }
    // If rows were skipped, stay in done phase so user can download the log.
  }

  Future<void> _downloadSkipLog() async {
    await downloadBytes(
      utf8.encode(_skippedLog.join('\n')),
      'import_skip_log.txt',
      'Import Skip Log',
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 640,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            const Divider(height: 1),
            Flexible(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context)!;
    String title;
    switch (_phase) {
      case _ImportPhase.landing:
        title = l10n.excelImportTitle;
        break;
      case _ImportPhase.preview:
        title = l10n.excelImportPreviewTitle(_rows.length);
        break;
      case _ImportPhase.importing:
        title = l10n.excelImportingTitle;
        break;
      case _ImportPhase.done:
        title = l10n.excelImportDoneTitle;
        break;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFE65100).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.table_chart_outlined,
              color: Color(0xFFE65100),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
          if (_phase == _ImportPhase.landing || _phase == _ImportPhase.preview)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final l10n = AppLocalizations.of(context)!;
    switch (_phase) {
      case _ImportPhase.landing:
        return _LandingPhase(
          vendorType: widget.vendorType,
          sectionNames: widget.sectionNames,
          downloadError: _downloadError,
          uploadError: _uploadError,
          onDownload: _downloadTemplate,
          onUpload: _pickAndParse,
          isFilePicking: _isFilePicking,
          isParsing: _isParsing,
          parseProgress: _parseProgress,
          l10n: l10n,
        );
      case _ImportPhase.preview:
        return _PreviewPhase(
          rows: _rows,
          sectionNames: widget.sectionNames,
          onConfirm: _validRows.isEmpty ? null : _confirmImport,
          onReupload: () => setState(() {
            _rows = [];
            _phase = _ImportPhase.landing;
          }),
          onChanged: () => setState(() {}),
          l10n: l10n,
        );
      case _ImportPhase.importing:
        return _ProgressPhase(
          current: _importedCount,
          total: _totalCount,
          l10n: l10n,
        );
      case _ImportPhase.done:
        return _DonePhase(
          importedCount: _importedCount,
          skippedLog: _skippedLog,
          onDownloadLog: _skippedLog.isNotEmpty ? _downloadSkipLog : null,
          onClose: () => Navigator.of(context).pop(),
          l10n: l10n,
        );
    }
  }
}

// ── Phase 1: Landing ──────────────────────────────────────────────────────────

class _LandingPhase extends StatelessWidget {
  final VendorType vendorType;
  final List<String> sectionNames;
  final String? downloadError;
  final String? uploadError;
  final VoidCallback onDownload;
  final VoidCallback onUpload;
  final bool isFilePicking;
  final bool isParsing;
  final double parseProgress;
  final AppLocalizations l10n;

  const _LandingPhase({
    required this.vendorType,
    required this.sectionNames,
    required this.downloadError,
    required this.uploadError,
    required this.onDownload,
    required this.onUpload,
    required this.isFilePicking,
    required this.isParsing,
    required this.parseProgress,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // How it works
          _InfoCard(
            steps: [
              l10n.excelImportStep1,
              l10n.excelImportStep2,
              l10n.excelImportStep3,
              l10n.excelImportStep4,
            ],
          ),
          const SizedBox(height: 24),

          // Download template button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onDownload,
              icon: const Icon(
                Icons.download_rounded,
                color: Color(0xFFE65100),
              ),
              label: Text(
                l10n.excelImportDownloadTemplate,
                style: const TextStyle(color: Color(0xFFE65100)),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Color(0xFFE65100)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          if (downloadError != null) ...[
            const SizedBox(height: 8),
            Text(
              downloadError!,
              style: const TextStyle(color: Color(0xFFD32F2F), fontSize: 12),
            ),
          ],

          const SizedBox(height: 12),

          // Upload button — three states:
          //   normal       → enabled, "Upload File"
          //   isFilePicking → disabled, "Choosing file…"
          //   isParsing    → disabled, "Parsing X %" + progress bar below
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (isFilePicking || isParsing) ? null : onUpload,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE65100),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(
                  0xFFE65100,
                ).withValues(alpha: 0.6),
                disabledForegroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isFilePicking
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Text('Choosing file…'),
                      ],
                    )
                  : isParsing
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          // 0–40 %: reading bytes  → show 0–100 %
                          // 40–50 %: decoding (off-thread, brief)
                          // 50–100 %: validating rows → show 0–100 %
                          parseProgress < 0.4
                              ? 'Reading… ${(parseProgress / 0.4 * 100).round()}%'
                              : parseProgress < 0.5
                              ? 'Decoding…'
                              : 'Parsing… ${((parseProgress - 0.5) / 0.5 * 100).round()}%',
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.upload_file_rounded),
                        const SizedBox(width: 8),
                        Text(l10n.excelImportUploadFile),
                      ],
                    ),
            ),
          ),
          // Progress bar shown below the button while rows are being validated.
          if (isParsing) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                // Indeterminate during the brief decode phase (40–50 %).
                value:
                    (parseProgress > 0 &&
                        !(parseProgress >= 0.4 && parseProgress < 0.5))
                    ? parseProgress
                    : null,
                minHeight: 4,
                backgroundColor: const Color(0xFFFFCC80),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFFE65100),
                ),
              ),
            ),
          ],
          if (uploadError != null) ...[
            const SizedBox(height: 8),
            Text(
              uploadError!,
              style: const TextStyle(color: Color(0xFFD32F2F), fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Phase 2: Preview ──────────────────────────────────────────────────────────

class _PreviewPhase extends StatefulWidget {
  final List<Map<String, dynamic>> rows;
  final List<String> sectionNames;
  final VoidCallback? onConfirm;
  final VoidCallback onReupload;
  final VoidCallback onChanged;
  final AppLocalizations l10n;

  const _PreviewPhase({
    required this.rows,
    required this.sectionNames,
    required this.onConfirm,
    required this.onReupload,
    required this.onChanged,
    required this.l10n,
  });

  @override
  State<_PreviewPhase> createState() => _PreviewPhaseState();
}

class _PreviewPhaseState extends State<_PreviewPhase> {
  static const _maxPreviewRows = 200;

  int get _validCount =>
      widget.rows.where((r) => !r.containsKey('error')).length;
  int get _errorCount =>
      widget.rows.where((r) => r.containsKey('error')).length;

  void _validateRow(Map<String, dynamic> row) {
    final errors = <String>[];
    final nameEn = (row['name_en'] as String? ?? '').trim();
    final priceStr = row['price']?.toString() ?? '';
    var section = (row['section'] as String? ?? '').trim();
    if (section.isEmpty) {
      section = 'Other';
      row['section'] = 'Other';
    }

    if (nameEn.isEmpty) errors.add('Name (EN) is required');

    final price = double.tryParse(priceStr);
    if (priceStr.isEmpty) {
      errors.add('Price is required');
    } else if (price == null || price <= 0) {
      errors.add('Invalid price "$priceStr"');
    }

    final discountedStr = row['discounted_price']?.toString() ?? '';
    if (discountedStr.isNotEmpty) {
      final discountedPrice = double.tryParse(discountedStr);
      if (discountedPrice == null) {
        errors.add('Invalid discounted price "$discountedStr"');
      } else if (price != null && discountedPrice >= price) {
        errors.add('Discounted price must be less than regular price');
      }
    }

    if (errors.isNotEmpty) {
      row['error'] = errors.join('; ');
    } else {
      row.remove('error');
    }
  }

  void _deleteRow(Map<String, dynamic> row) {
    setState(() {
      widget.rows.remove(row);
    });
    widget.onChanged();
  }

  void _editRow(Map<String, dynamic> row) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return _DraftEditBottomSheet(
          row: row,
          sectionNames: widget.sectionNames,
          onSave: (updatedRow) {
            setState(() {
              row.addAll(updatedRow);
              _validateRow(row);
            });
            widget.onChanged();
          },
          l10n: widget.l10n,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final errorRows = widget.rows.where((r) => r.containsKey('error')).toList();
    final validRows = widget.rows
        .where((r) => !r.containsKey('error'))
        .toList();
    final previewRows = [
      ...errorRows,
      ...validRows,
    ].take(_maxPreviewRows).toList();
    final hasMore = widget.rows.length > _maxPreviewRows;

    return Column(
      children: [
        // Summary bar
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          color: const Color(0xFFF5F5F5),
          child: Row(
            children: [
              _StatusBadge(
                count: _validCount,
                label: widget.l10n.excelImportValid,
                color: const Color(0xFF388E3C),
              ),
              const SizedBox(width: 12),
              if (_errorCount > 0)
                _StatusBadge(
                  count: _errorCount,
                  label: widget.l10n.excelImportErrors,
                  color: const Color(0xFFD32F2F),
                ),
            ],
          ),
        ),

        // Truncation notice
        if (hasMore)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: const Color(0xFFFFF8E1),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 14,
                  color: Color(0xFFFF8F00),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Showing first $_maxPreviewRows of ${widget.rows.length} rows — errors appear first.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF5D4037),
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Horizontal scrollable table view (header + preview list scroll together)
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 650,
              child: Column(
                children: [
                  // Sticky column header
                  Container(
                    color: const Color(0xFFFFF3E0),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: const Row(
                      children: [
                        SizedBox(
                          width: 180,
                          child: Text(
                            'Name (EN)',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        SizedBox(
                          width: 70,
                          child: Text(
                            'Price',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        SizedBox(
                          width: 100,
                          child: Text(
                            'Section',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Issue / Action',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // Preview list
                  Expanded(
                    child: ListView.builder(
                      itemCount: previewRows.length,
                      itemBuilder: (context, i) {
                        final row = previewRows[i];
                        final hasError = row.containsKey('error');
                        return InkWell(
                          onTap: () => _editRow(row),
                          child: Container(
                            color: hasError
                                ? const Color(0xFFFFEBEE)
                                : (i.isOdd
                                      ? const Color(0xFFFAFAFA)
                                      : Colors.white),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 180,
                                  child: Text(
                                    row['name_en']?.toString() ?? '',
                                    style: const TextStyle(fontSize: 12),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 70,
                                  child: Text(
                                    '${row['price']?.toString() ?? ''} EGP',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 100,
                                  child: Text(
                                    row['section']?.toString() ?? '',
                                    style: const TextStyle(fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: hasError
                                            ? Text(
                                                row['error'] ?? '',
                                                style: const TextStyle(
                                                  color: Color(0xFFD32F2F),
                                                  fontSize: 10,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              )
                                            : const Text(
                                                'Draft OK',
                                                style: TextStyle(
                                                  color: Color(0xFF388E3C),
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit_outlined,
                                          color: Color(0xFFE65100),
                                          size: 18,
                                        ),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () => _editRow(row),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline_rounded,
                                          color: Color(0xFFD32F2F),
                                          size: 18,
                                        ),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () => _deleteRow(row),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Action bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              OutlinedButton.icon(
                onPressed: widget.onReupload,
                icon: const Icon(Icons.refresh, size: 16),
                label: Text(widget.l10n.excelImportReupload),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFE65100),
                  side: const BorderSide(color: Color(0xFFE65100)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: widget.onConfirm,
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: Text(widget.l10n.excelImportConfirmBtn(_validCount)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE65100),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFBDBDBD),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Interactive Draft Sheet Editor ────────────────────────────────────────────

class _DraftEditBottomSheet extends StatefulWidget {
  final Map<String, dynamic> row;
  final List<String> sectionNames;
  final ValueChanged<Map<String, dynamic>> onSave;
  final AppLocalizations l10n;

  const _DraftEditBottomSheet({
    required this.row,
    required this.sectionNames,
    required this.onSave,
    required this.l10n,
  });

  @override
  State<_DraftEditBottomSheet> createState() => _DraftEditBottomSheetState();
}

class _DraftEditBottomSheetState extends State<_DraftEditBottomSheet> {
  late final TextEditingController _nameEnController;
  late final TextEditingController _nameArController;
  late final TextEditingController _descEnController;
  late final TextEditingController _descArController;
  late final TextEditingController _priceController;
  late final TextEditingController _discountedPriceController;
  late final TextEditingController _stockController;
  late final TextEditingController _warningLimitController;

  String? _selectedSection;
  late final List<String> _dropdownSections;
  String? _imagePath;
  List<MenuItemVariant> _variants = [];

  @override
  void initState() {
    super.initState();
    _nameEnController = TextEditingController(
      text: widget.row['name_en']?.toString() ?? '',
    );
    _nameArController = TextEditingController(
      text: widget.row['name_ar']?.toString() ?? '',
    );
    _descEnController = TextEditingController(
      text: widget.row['desc_en']?.toString() ?? '',
    );
    _descArController = TextEditingController(
      text: widget.row['desc_ar']?.toString() ?? '',
    );
    _priceController = TextEditingController(
      text: widget.row['price']?.toString() ?? '',
    );
    _discountedPriceController = TextEditingController(
      text: widget.row['discounted_price']?.toString() ?? '',
    );
    _stockController = TextEditingController(
      text: widget.row['stock']?.toString() ?? '',
    );
    _warningLimitController = TextEditingController(
      text: widget.row['warning_limit']?.toString() ?? '',
    );

    _selectedSection = widget.row['section']?.toString().trim();
    if (_selectedSection != null && _selectedSection!.isEmpty) {
      _selectedSection = null;
    }
    _dropdownSections = List<String>.from(widget.sectionNames);
    if (_selectedSection != null && _selectedSection!.isNotEmpty) {
      final exists = _dropdownSections.any(
        (s) => s.toLowerCase() == _selectedSection!.toLowerCase(),
      );
      if (!exists) {
        _dropdownSections.add(_selectedSection!);
      } else {
        _selectedSection = _dropdownSections.firstWhere(
          (s) => s.toLowerCase() == _selectedSection!.toLowerCase(),
        );
      }
    }

    _imagePath = widget.row['image_url']?.toString();
    final rawVars = widget.row['variants'];
    if (rawVars is List<MenuItemVariant>) {
      _variants = List<MenuItemVariant>.from(rawVars);
    } else {
      _variants = [];
    }
  }

  @override
  void dispose() {
    _nameEnController.dispose();
    _nameArController.dispose();
    _descEnController.dispose();
    _descArController.dispose();
    _priceController.dispose();
    _discountedPriceController.dispose();
    _stockController.dispose();
    _warningLimitController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.pickFiles(type: FileType.image);
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _imagePath = result.files.first.path;
        });
      }
    } catch (e) {
      debugPrint('Failed to pick draft image: $e');
    }
  }

  void _addVariant() {
    setState(() {
      _variants.add(
        MenuItemVariant(
          id: 'var_${DateTime.now().microsecondsSinceEpoch}_${_variants.length}',
          foodItemId: '',
          name: '',
          nameAr: '',
          price: 0.0,
          isAvailable: true,
        ),
      );
    });
  }

  void _removeVariant(int idx) {
    setState(() {
      _variants.removeAt(idx);
    });
  }

  void _save() {
    final nameEn = _nameEnController.text.trim();
    final nameAr = _nameArController.text.trim();
    final descEn = _descEnController.text.trim();
    final descAr = _descArController.text.trim();
    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
    final discountedPrice = double.tryParse(
      _discountedPriceController.text.trim(),
    );
    final stock = int.tryParse(_stockController.text.trim());
    final warningLimit = int.tryParse(_warningLimitController.text.trim());

    final data = <String, dynamic>{
      'name_en': nameEn,
      'name_ar': nameAr.isNotEmpty ? nameAr : null,
      'desc_en': descEn,
      'desc_ar': descAr.isNotEmpty ? descAr : null,
      'price': price,
      'discounted_price': discountedPrice,
      'section': _selectedSection,
      'image_url': _imagePath ?? '',
      'stock': stock,
      'warning_limit': warningLimit,
      'variants': _variants,
    };

    widget.onSave(data);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: FractionallySizedBox(
        heightFactor: 0.8,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 50,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Edit Draft Item',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: _save,
                    child: const Text(
                      'Save',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE65100),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 140,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1.5,
                          ),
                        ),
                        child: _imagePath != null && _imagePath!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: _imagePath!.startsWith('http') || kIsWeb
                                    ? Image.network(
                                        _imagePath!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) =>
                                            const Icon(Icons.broken_image),
                                      )
                                    : Image.file(
                                        io.File(_imagePath!),
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) =>
                                            const Icon(Icons.broken_image),
                                      ),
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_a_photo_outlined,
                                    color: Colors.grey,
                                    size: 28,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Pick Image',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _nameEnController,
                    decoration: const InputDecoration(
                      labelText: 'Name (EN) *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameArController,
                    textAlign: TextAlign.right,
                    decoration: const InputDecoration(
                      labelText: 'Name (AR)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _priceController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Price (EGP) *',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _discountedPriceController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Discounted Price',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedSection,
                    items: _dropdownSections
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedSection = val),
                    decoration: const InputDecoration(
                      labelText: 'Category / Section *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _stockController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Stock Quantity',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _warningLimitController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Warning Limit',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descEnController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Description (EN)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descArController,
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Description (AR)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Variants / Sizes',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _addVariant,
                        icon: const Icon(
                          Icons.add,
                          size: 16,
                          color: Color(0xFFE65100),
                        ),
                        label: const Text(
                          'Add Variant',
                          style: TextStyle(
                            color: Color(0xFFE65100),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_variants.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: const Text(
                        'No variants added',
                        style: TextStyle(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  else
                    Column(
                      children: List.generate(_variants.length, (vIdx) {
                        final variant = _variants[vIdx];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          elevation: 0,
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        decoration: const InputDecoration(
                                          labelText: 'Name (EN) *',
                                          isDense: true,
                                        ),
                                        controller:
                                            TextEditingController(
                                                text: variant.name,
                                              )
                                              ..selection =
                                                  TextSelection.fromPosition(
                                                    TextPosition(
                                                      offset:
                                                          variant.name.length,
                                                    ),
                                                  ),
                                        onChanged: (val) {
                                          _variants[vIdx] = variant.copyWith(
                                            name: val,
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextField(
                                        textAlign: TextAlign.right,
                                        decoration: const InputDecoration(
                                          labelText: 'Name (AR)',
                                          isDense: true,
                                        ),
                                        controller:
                                            TextEditingController(
                                                text: variant.nameAr ?? '',
                                              )
                                              ..selection =
                                                  TextSelection.fromPosition(
                                                    TextPosition(
                                                      offset:
                                                          (variant.nameAr ?? '')
                                                              .length,
                                                    ),
                                                  ),
                                        onChanged: (val) {
                                          _variants[vIdx] = variant.copyWith(
                                            nameAr: val.isNotEmpty ? val : null,
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        decoration: const InputDecoration(
                                          labelText: 'Price *',
                                          isDense: true,
                                        ),
                                        controller:
                                            TextEditingController(
                                                text: variant.price.toString(),
                                              )
                                              ..selection =
                                                  TextSelection.fromPosition(
                                                    TextPosition(
                                                      offset: variant.price
                                                          .toString()
                                                          .length,
                                                    ),
                                                  ),
                                        onChanged: (val) {
                                          _variants[vIdx] = variant.copyWith(
                                            price: double.tryParse(val) ?? 0.0,
                                          );
                                        },
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => _removeVariant(vIdx),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Phase 3: Progress ─────────────────────────────────────────────────────────

class _ProgressPhase extends StatelessWidget {
  final int current;
  final int total;
  final AppLocalizations l10n;

  const _ProgressPhase({
    required this.current,
    required this.total,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final bool ready = total > 0;
    final double? progress = ready ? current / total : null;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.cloud_upload_outlined,
            size: 52,
            color: Color(0xFFE65100),
          ),
          const SizedBox(height: 20),
          Text(
            ready
                ? l10n.excelImportProgress(current, total)
                : l10n.excelImportingTitle,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFFFE0B2),
              valueColor: const AlwaysStoppedAnimation(Color(0xFFE65100)),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            ready ? '${((progress ?? 0) * 100).toStringAsFixed(0)}%' : '',
            style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ── Phase 4: Done ─────────────────────────────────────────────────────────────

class _DonePhase extends StatelessWidget {
  final int importedCount;
  final List<String> skippedLog;
  final VoidCallback? onDownloadLog;
  final VoidCallback onClose;
  final AppLocalizations l10n;

  const _DonePhase({
    required this.importedCount,
    required this.skippedLog,
    required this.onDownloadLog,
    required this.onClose,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            size: 52,
            color: Color(0xFF388E3C),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.excelImportSuccessCount(importedCount),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.excelImportAddImages,
            style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)),
            textAlign: TextAlign.center,
          ),
          if (skippedLog.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFB300)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFFFB300),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.excelImportSkippedRows(skippedLog.length),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF5D4037),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onDownloadLog,
                icon: const Icon(
                  Icons.download_rounded,
                  color: Color(0xFFE65100),
                  size: 18,
                ),
                label: Text(
                  l10n.excelImportDownloadSkipLog,
                  style: const TextStyle(color: Color(0xFFE65100)),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE65100)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onClose,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE65100),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(l10n.excelImportClose),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Small reusable widgets ────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final List<String> steps;
  const _InfoCard({required this.steps});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE65100).withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: steps
            .map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  s,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF5D4037),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final int count;
  final String label;
  final Color color;

  const _StatusBadge({
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count $label',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
