import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:excel/excel.dart';
import 'package:z_speed/core/enums/user_enums.dart';
import 'package:z_speed/features/restaurant/model/menu_item_variant.dart';

/// Predefined section names for non-restaurant vendor types.
abstract final class VendorSections {
  static const List<String> supermarket = [
    'Fruits & Vegetables',
    'Dairy & Eggs',
    'Bakery',
    'Meat & Seafood',
    'Beverages',
    'Snacks & Confectionery',
    'Frozen Foods',
    'Household',
    'Personal Care',
    'Baby Care',
    'Pet Supplies',
    'Other',
  ];

  static const List<String> pharmacy = [
    'Prescription Medicines',
    'OTC Medicines',
    'Vitamins & Supplements',
    'Personal Care',
    'Baby Care',
    'Medical Devices',
    'First Aid',
    'Cosmetics & Skincare',
    'Other',
  ];

  static const List<String> bookstore = [
    'School Supplies & Bags',
    'Pens & Writing Instruments',
    'Books & Novels',
    'Educational Textbooks',
    'Educational Toys & Aids',
    'Office Equipment',
    'Art & Engineering Supplies',
    'Other',
  ];

  static const List<String> homeFurnishing = [
    'Memory Foam Products',
    'Bedding & Mattresses',
    'Pillows & Cushions',
    'Blankets & Curtains',
    'Bean Bags & Puffs',
    'Thermal Bags',
    'Camping Gear',
    'Beach & Sport Products',
    'Pet Beds',
    'Prayer Mats',
    'Ramadan Collection',
    'Other',
  ];

  static const List<String> meatAndProteins = [
    'Red Meat',
    'Poultry',
    'Fish & Seafood',
    'Dairy & Eggs',
    'Protein Powders & Supplements',
    'Other',
  ];

  static const List<String> clothes = [
    'Men\'s Wear',
    'Women\'s Wear',
    'Kids\' Wear',
    'Shoes & Footwear',
    'Accessories & Bags',
    'Other',
  ];

  static const List<String> buyAndSell = [
    'Electronics',
    'Fashion & Apparel',
    'Home & Garden',
    'Books & Hobbies',
    'Vehicles & Accessories',
    'Other',
  ];

  static const List<String> electronics = [
    'Smartphones & Tablets',
    'Computers & Laptops',
    'Audio & Headphones',
    'TV & Home Theater',
    'Smart Home Devices',
    'Accessories & Cables',
    'Other',
  ];

  /// Returns the predefined section list for a vendor type, or null for
  /// restaurants (whose sections come from Firestore CuisineTypes at runtime).
  static List<String>? forType(VendorType type) {
    switch (type) {
      case VendorType.supermarket:
        return supermarket;
      case VendorType.pharmacy:
        return pharmacy;
      case VendorType.bookstore:
        return bookstore;
      case VendorType.homeFurnishing:
        return homeFurnishing;
      case VendorType.meatAndProteins:
        return meatAndProteins;
      case VendorType.clothes:
        return clothes;
      case VendorType.buyAndSell:
        return buyAndSell;
      case VendorType.electronics:
        return electronics;
      case VendorType.restaurant:
        return null; // fetched from Firestore
    }
  }
}

/// Static helpers for generating an xlsx import template and parsing uploads.
abstract final class MenuExcelService {
  // ── Sheet / column names ────────────────────────────────────────────────────

  static const String _itemsSheet = 'Menu Items';
  static const String _sectionsSheet = 'Sections';
  static const String _instructionsSheet = 'Instructions';

  // Column indices (0-based) in "Menu Items" sheet
  static const int _colNameEn = 0;
  static const int _colNameAr = 1;
  static const int _colDescEn = 2;
  static const int _colDescAr = 3;
  static const int _colPrice = 4;
  static const int _colDiscountedPrice = 5;
  static const int _colSection = 6;
  static const int _colAvailable = 7;
  static const int _colImageUrl = 8;
  static const int _colStock = 9;
  static const int _colWarningLimit = 10;
  static const int _colVariants = 11;

  // ── Header labels ───────────────────────────────────────────────────────────

  static const List<String> _headers = [
    'Name (EN)*',
    'Name (AR)',
    'Description (EN)',
    'Description (AR)',
    'Price (EGP)*',
    'Discounted Price',
    'Section*',
    'Available',
    'Image URL',
    'Stock',
    'Warning Limit',
    'Variants (e.g. Med|متوسط|850; Lrg|كبير|1200)',
  ];

  // ── Example rows ────────────────────────────────────────────────────────────

  static List<List<String>> _exampleRows(String firstSection) => [
        [
          'Grilled Chicken',
          'دجاج مشوي',
          'Tender grilled chicken breast',
          'صدر دجاج مشوي طري',
          '89',
          '',
          firstSection,
          'yes',
          '',
          '100',
          '10',
          'Med|متوسط|85; Lrg|كبير|100',
        ],
        [
          'Caesar Salad',
          'سلطة سيزر',
          'Fresh romaine with caesar dressing',
          'رومين طازج مع صوص سيزر',
          '65',
          '55',
          firstSection,
          'yes',
          '',
          '50',
          '5',
          'Sml|صغير|55; Lrg|كبير|65',
        ],
        [
          'Chocolate Lava Cake',
          'كيك شوكولاتة',
          'Warm cake with molten center',
          'كيك دافئ بمركز ذائب',
          '45',
          '',
          firstSection,
          'yes',
          '',
          '30',
          '3',
          '',
        ],
      ];

  // ── Orange accent color for header row ──────────────────────────────────────

  static const String _orangeHex = 'FFE65100';
  static const String _greyHex = 'FFF5F5F5';

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Generates an xlsx template and returns the raw bytes.
  ///
  /// [sectionNames] — valid section names (from Firestore for restaurants, or
  /// from [VendorSections] for supermarkets/pharmacies).
  /// [vendorTypeLabel] — shown in a subtitle cell (e.g. "Supermarket").
  static List<int> generateTemplate({
    required List<String> sectionNames,
    required String vendorTypeLabel,
  }) {
    final excel = Excel.createExcel();

    // Remove the auto-created "Sheet1"
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    _buildSectionsSheet(excel, sectionNames);
    _buildInstructionsSheet(excel);
    _buildItemsSheet(excel, sectionNames, vendorTypeLabel);

    // Make "Menu Items" the default visible sheet
    excel.setDefaultSheet(_itemsSheet);

    final bytes = excel.encode()!;
    // Post-process: inject dropdown data validations into the xlsx XML.
    return _injectDataValidations(bytes, sectionNames.length);
  }

  /// Parses an uploaded xlsx file.
  ///
  /// Returns a list of row maps. Each map has keys matching [_headers] (lower
  /// snake_case), plus an optional `'error'` key for invalid rows.
  ///
  /// Keys: name_en, name_ar, desc_en, desc_ar, price, discounted_price,
  ///       section, available, image_url, error (optional)
  static List<Map<String, dynamic>> parseImport({
    required List<int> bytes,
    required List<String> validSectionNames,
  }) {
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.sheets[_itemsSheet];
    if (sheet == null) return [];

    final rows = sheet.rows;
    if (rows.length <= 2) return []; // subtitle + header only, or empty

    final result = <Map<String, dynamic>>[];

    // Row 0 = subtitle, row 1 = headers — skip both
    for (int i = 2; i < rows.length; i++) {
      final row = rows[i];
      final cells = List<Data?>.from(row);

      // Skip entirely blank rows
      final values = cells.map((c) => _cellString(c)).toList();
      if (values.every((v) => v.isEmpty)) continue;

      final nameEn = _safe(values, _colNameEn);
      final nameAr = _safe(values, _colNameAr);
      final descEn = _safe(values, _colDescEn);
      final descAr = _safe(values, _colDescAr);
      final priceStr = _safe(values, _colPrice);
      final discountedStr = _safe(values, _colDiscountedPrice);
      var section = _safe(values, _colSection);
      if (section.isEmpty) {
        section = 'Other';
      }
      final availableStr = _safe(values, _colAvailable).toLowerCase();
      final imageUrl = _safe(values, _colImageUrl);
      final stockStr = _safe(values, _colStock);
      final warningLimitStr = _safe(values, _colWarningLimit);
      final variantsStr = _safe(values, _colVariants);

      // Validate required fields (description is optional)
      final errors = <String>[];
      if (nameEn.isEmpty) errors.add('Name (EN) is required');

      final price = double.tryParse(priceStr);
      if (priceStr.isEmpty) {
        errors.add('Price is required');
      } else if (price == null || price <= 0) {
        errors.add('Invalid price "$priceStr"');
      }

      double? discountedPrice;
      if (discountedStr.isNotEmpty) {
        discountedPrice = double.tryParse(discountedStr);
        if (discountedPrice == null) {
          errors.add('Invalid discounted price "$discountedStr"');
        } else if (price != null && discountedPrice >= price) {
          errors.add('Discounted price must be less than regular price');
        }
      }

      final bool available = availableStr.isEmpty || availableStr == 'yes';

      // Match section to canonical casing
      final canonicalSection = validSectionNames.firstWhere(
        (s) => s.toLowerCase() == section.toLowerCase(),
        orElse: () => section,
      );

      final int? stock = stockStr.isEmpty ? null : int.tryParse(stockStr);
      final int? warningLimit =
          warningLimitStr.isEmpty ? null : int.tryParse(warningLimitStr);

      final map = <String, dynamic>{
        'row': i + 1,
        'name_en': nameEn,
        'name_ar': nameAr,
        'desc_en': descEn,
        'desc_ar': descAr,
        'price': price ?? 0.0,
        'discounted_price': discountedPrice,
        'section': canonicalSection,
        'available': available,
        'image_url': imageUrl,
        'stock': stock,
        'warning_limit': warningLimit,
        'variants': _parseVariantsString(variantsStr),
      };
      if (errors.isNotEmpty) map['error'] = errors.join('; ');

      result.add(map);
    }

    return result;
  }

  // ── Two-phase parsing helpers (used by the import dialog for progress %) ────

  /// Decodes [bytes] and returns raw string values for every data row in the
  /// "Menu Items" sheet (skips subtitle + header).  Designed to run inside
  /// [compute] so the heavy [Excel.decodeBytes] call stays off the UI thread.
  /// Empty rows are kept (as empty lists) so row numbers stay consistent.
  static List<List<String>> extractRawRows(List<int> bytes) {
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.sheets[_itemsSheet];
    if (sheet == null) return [];
    final rows = sheet.rows;
    if (rows.length <= 2) return [];

    return [
      for (int i = 2; i < rows.length; i++)
        List<Data?>.from(rows[i]).map(_cellString).toList(),
    ];
  }

  /// Validates and maps one raw row (already converted to strings by
  /// [extractRawRows]).  Returns null for blank rows so the caller can skip.
  /// [rowNum] is the 1-based Excel row number shown in error messages.
  static Map<String, dynamic>? parseRawRow(
    List<String> values,
    int rowNum,
    List<String> validSectionNames,
  ) {
    if (values.every((v) => v.isEmpty)) return null;

    final nameEn = _safe(values, _colNameEn);
    final nameAr = _safe(values, _colNameAr);
    final descEn = _safe(values, _colDescEn);
    final descAr = _safe(values, _colDescAr);
    final priceStr = _safe(values, _colPrice);
    final discountedStr = _safe(values, _colDiscountedPrice);
    var section = _safe(values, _colSection);
    if (section.isEmpty) {
      section = 'Other';
    }
    final availableStr = _safe(values, _colAvailable).toLowerCase();
    final imageUrl = _safe(values, _colImageUrl);
    final stockStr = _safe(values, _colStock);
    final warningLimitStr = _safe(values, _colWarningLimit);
    final variantsStr = _safe(values, _colVariants);

    final errors = <String>[];
    if (nameEn.isEmpty) errors.add('Name (EN) is required');

    final price = double.tryParse(priceStr);
    if (priceStr.isEmpty) {
      errors.add('Price is required');
    } else if (price == null || price <= 0) {
      errors.add('Invalid price "$priceStr"');
    }

    double? discountedPrice;
    if (discountedStr.isNotEmpty) {
      discountedPrice = double.tryParse(discountedStr);
      if (discountedPrice == null) {
        errors.add('Invalid discounted price "$discountedStr"');
      } else if (price != null && discountedPrice >= price) {
        errors.add('Discounted price must be less than regular price');
      }
    }

    final bool available = availableStr.isEmpty || availableStr == 'yes';

    final canonicalSection = validSectionNames.firstWhere(
      (s) => s.toLowerCase() == section.toLowerCase(),
      orElse: () => section,
    );

    final int? stock = stockStr.isEmpty ? null : int.tryParse(stockStr);
    final int? warningLimit =
        warningLimitStr.isEmpty ? null : int.tryParse(warningLimitStr);

    final map = <String, dynamic>{
      'row': rowNum,
      'name_en': nameEn,
      'name_ar': nameAr,
      'desc_en': descEn,
      'desc_ar': descAr,
      'price': price ?? 0.0,
      'discounted_price': discountedPrice,
      'section': canonicalSection,
      'available': available,
      'image_url': imageUrl,
      'stock': stock,
      'warning_limit': warningLimit,
      'variants': _parseVariantsString(variantsStr),
    };
    if (errors.isNotEmpty) map['error'] = errors.join('; ');
    return map;
  }

  static List<MenuItemVariant> _parseVariantsString(String valStr) {
    if (valStr.trim().isEmpty) return [];
    final list = <MenuItemVariant>[];
    final parts = valStr.split(';');
    for (final part in parts) {
      final trimmedPart = part.trim();
      if (trimmedPart.isEmpty) continue;
      final fields = trimmedPart.split('|');
      if (fields.isEmpty) continue;

      final nameEn = fields[0].trim();
      if (nameEn.isEmpty) continue;

      String? nameAr;
      if (fields.length > 1) {
        final ar = fields[1].trim();
        if (ar.isNotEmpty) nameAr = ar;
      }

      double price = 0.0;
      if (fields.length > 2) {
        final pStr = fields[2].trim();
        price = double.tryParse(pStr) ?? 0.0;
      }

      final id = 'var_${DateTime.now().microsecondsSinceEpoch}_${list.length}';

      list.add(MenuItemVariant(
        id: id,
        foodItemId: '',
        name: nameEn,
        nameAr: nameAr,
        price: price,
        isAvailable: true,
      ));
    }
    return list;
  }

  // ── Private helpers ─────────────────────────────────────────────────────────

  /// Post-processes xlsx bytes (a ZIP archive) to inject Excel dropdown data
  /// validations that the `excel` package cannot emit natively.
  ///
  /// - Column G (Section*): list sourced from the Sections sheet
  /// - Column H (Available): inline list "yes,no"
  static List<int> _injectDataValidations(List<int> bytes, int sectionCount) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);

      // ── 1. Find the "Menu Items" sheet file via workbook.xml + rels ─────────
      final workbookFile = archive.findFile('xl/workbook.xml');
      if (workbookFile == null) return bytes;
      final workbookXml = utf8.decode(workbookFile.content as List<int>);

      // Locate the <sheet> element for "Menu Items" and extract r:id
      final sheetTagMatch = RegExp(r'<sheet\s[^>]*name="Menu Items"[^>]*/?>')
          .firstMatch(workbookXml);
      if (sheetTagMatch == null) return bytes;
      final rIdMatch =
          RegExp(r'r:id="([^"]+)"').firstMatch(sheetTagMatch.group(0)!);
      if (rIdMatch == null) return bytes;
      final rId = rIdMatch.group(1)!;

      // Resolve the r:id to the actual sheet file path
      final relsFile = archive.findFile('xl/_rels/workbook.xml.rels');
      if (relsFile == null) return bytes;
      final relsXml = utf8.decode(relsFile.content as List<int>);
      final pathMatch =
          RegExp('Id="$rId"[^>]*Target="([^"]+)"').firstMatch(relsXml);
      if (pathMatch == null) return bytes;
      final sheetPath = 'xl/${pathMatch.group(1)!}';

      // ── 2. Patch the sheet XML ───────────────────────────────────────────────
      final sheetFile = archive.findFile(sheetPath);
      if (sheetFile == null) return bytes;
      final sheetXml = utf8.decode(sheetFile.content as List<int>);

      // Sections sheet layout: row 1 = header, rows 2..(sectionCount+1) = data
      final lastSectionRow = sectionCount + 1;

      // dataValidations element — must be inserted before </worksheet>
      final dvXml = '<dataValidations count="2">'
          '<dataValidation type="list" allowBlank="1" sqref="G3:G1000000">'
          '<formula1>Sections!\$A\$2:\$A\$$lastSectionRow</formula1>'
          '</dataValidation>'
          '<dataValidation type="list" allowBlank="1" sqref="H3:H1000000">'
          '<formula1>&quot;yes,no&quot;</formula1>'
          '</dataValidation>'
          '</dataValidations>';

      // <dataValidations> must appear before late-sequence worksheet elements
      // (pageMargins, pageSetup, drawing, etc.) per the OOXML schema.
      // Inserting right before </worksheet> violates that order when the excel
      // package has already emitted those elements, causing Excel to report
      // "content problem" on open.  Try each anchor in schema order.
      const lateAnchors = [
        '<pageMargins',
        '<pageSetup',
        '<drawing',
        '<legacyDrawing',
        '<tableParts',
        '<extLst',
      ];
      String patched = sheetXml;
      bool inserted = false;
      for (final anchor in lateAnchors) {
        if (sheetXml.contains(anchor)) {
          patched = sheetXml.replaceFirst(anchor, '$dvXml$anchor');
          inserted = true;
          break;
        }
      }
      if (!inserted) {
        patched = sheetXml.replaceFirst('</worksheet>', '$dvXml</worksheet>');
      }
      final patchedBytes = utf8.encode(patched);

      // ── 3. Rebuild the archive with the patched sheet ────────────────────────
      final updated = Archive();
      for (final file in archive.files) {
        if (file.name == sheetPath) {
          updated.addFile(
              ArchiveFile(file.name, patchedBytes.length, patchedBytes));
        } else {
          updated.addFile(file);
        }
      }

      return ZipEncoder().encode(updated)!;
    } catch (_) {
      return bytes; // graceful fallback: return original bytes unmodified
    }
  }

  static void _buildSectionsSheet(Excel excel, List<String> sectionNames) {
    final sheet = excel[_sectionsSheet];

    // Header
    final headerCell =
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
    headerCell.value = TextCellValue('Section Name');
    headerCell.cellStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString(_orangeHex),
      fontColorHex: ExcelColor.fromHexString('FFFFFFFF'),
    );

    // Values
    for (int i = 0; i < sectionNames.length; i++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i + 1))
          .value = TextCellValue(sectionNames[i]);
    }

    sheet.setColumnWidth(0, 30);
  }

  static void _buildItemsSheet(
    Excel excel,
    List<String> sectionNames,
    String vendorTypeLabel,
  ) {
    final sheet = excel[_itemsSheet];

    // ── Subtitle row (row 0) ────────────────────────────────────────────────
    final subtitle =
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
    subtitle.value = TextCellValue(
      '$vendorTypeLabel Menu Import Template  •  Fill from row 3 onwards  •  * = required  •  See the "Instructions" sheet for the Variants format',
    );
    subtitle.cellStyle = CellStyle(
      italic: true,
      fontColorHex: ExcelColor.fromHexString('FF757575'),
    );
    // Merge subtitle across all header columns
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      CellIndex.indexByColumnRow(columnIndex: _headers.length - 1, rowIndex: 0),
    );

    // ── Header row (row 1) ──────────────────────────────────────────────────
    for (int col = 0; col < _headers.length; col++) {
      final cell =
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 1));
      cell.value = TextCellValue(_headers[col]);
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString(_orangeHex),
        fontColorHex: ExcelColor.fromHexString('FFFFFFFF'),
      );
    }

    // ── Example rows (rows 2-4) ─────────────────────────────────────────────
    final firstSection = sectionNames.isNotEmpty ? sectionNames.first : '';
    final examples = _exampleRows(firstSection);

    for (int r = 0; r < examples.length; r++) {
      final rowData = examples[r];
      for (int col = 0; col < rowData.length; col++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: col, rowIndex: r + 2),
        );
        cell.value = TextCellValue(rowData[col]);
        cell.cellStyle = CellStyle(
          backgroundColorHex: ExcelColor.fromHexString(_greyHex),
          fontColorHex: ExcelColor.fromHexString('FF9E9E9E'),
          italic: true,
        );
      }
    }

    // ── Column widths ───────────────────────────────────────────────────────
    const widths = [
      24.0, // Name (EN)
      20.0, // Name (AR)
      36.0, // Description (EN)
      28.0, // Description (AR)
      12.0, // Price
      16.0, // Discounted Price
      24.0, // Section
      14.0, // Available
      36.0, // Image URL
      12.0, // Stock
      14.0, // Warning Limit
      48.0, // Variants
    ];
    for (int i = 0; i < widths.length; i++) {
      sheet.setColumnWidth(i, widths[i]);
    }
  }

  static void _buildInstructionsSheet(Excel excel) {
    final sheet = excel[_instructionsSheet];

    // ── Title ───────────────────────────────────────────────────────────────
    final title =
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
    title.value = TextCellValue('📋  Import Guide');
    title.cellStyle = CellStyle(
      bold: true,
      fontSize: 14,
      fontColorHex: ExcelColor.fromHexString('FFFFFFFF'),
      backgroundColorHex: ExcelColor.fromHexString(_orangeHex),
    );
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 0),
    );

    // ── Section header helper ────────────────────────────────────────────────
    void addSection(int row, String text) {
      final cell =
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
      cell.value = TextCellValue(text);
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('FFF5F5F5'),
        fontColorHex: ExcelColor.fromHexString('FFE65100'),
      );
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
        CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row),
      );
    }

    void addRow(int row, String col, String desc) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
          .value = TextCellValue(col);
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
          .value = TextCellValue(desc);
    }

    // ── Column reference ─────────────────────────────────────────────────────
    addSection(2, '  Columns Reference');
    final colInfo = [
      ('A  Name (EN)*', 'Required. English product name.'),
      ('B  Name (AR)', 'Optional. Arabic product name.'),
      ('C  Description (EN)', 'Optional. English description.'),
      ('D  Description (AR)', 'Optional. Arabic description.'),
      ('E  Price (EGP)*', 'Required. Base price (number only, e.g. 89).'),
      ('F  Discounted Price', 'Optional. Must be less than Price.'),
      ('G  Section*', 'Required. Must match a value from the Sections sheet.'),
      ('H  Available', 'yes or no (defaults to yes if blank).'),
      ('I  Image URL', 'Optional. Paste a public image URL. You can upload images via the edit button after import.'),
      ('J  Stock', 'Optional. Current stock quantity (integer).'),
      ('K  Warning Limit', 'Optional. Low-stock alert threshold (integer).'),
      ('L  Variants', 'Optional. See "Variants Format" section below.'),
    ];
    for (int i = 0; i < colInfo.length; i++) {
      addRow(i + 3, colInfo[i].$1, colInfo[i].$2);
    }

    // ── Variants format ───────────────────────────────────────────────────────
    addSection(17, '  Variants Format (Column L)');

    final varInfo = [
      ('Format:', 'NameEN|NameAR|Price; NameEN|NameAR|Price; ...'),
      ('Separator:', 'Use semicolon (;) between variants, pipe (|) between fields.'),
      ('NameAR:', 'Optional — leave empty but keep the pipe, e.g. Small||50'),
      ('Price:', 'Required per variant (number only).'),
      ('', ''),
      ('Example 1:', 'Small|صغير|55; Medium|متوسط|70; Large|كبير|85'),
      ('Example 2 (no AR):', 'Single||120; Double||160'),
      ('Example 3 (one opt):', 'Regular|عادي|45'),
      ('Leave blank:', 'If the item has no variants, leave column L empty.'),
    ];
    for (int i = 0; i < varInfo.length; i++) {
      addRow(i + 18, varInfo[i].$1, varInfo[i].$2);
    }

    // ── Column widths ────────────────────────────────────────────────────────
    sheet.setColumnWidth(0, 24);
    sheet.setColumnWidth(1, 64);
    sheet.setColumnWidth(2, 0); // hidden
  }

  static String _safe(List<String> values, int index) =>
      index < values.length ? values[index].trim() : '';

  static String _cellString(Data? cell) {
    if (cell == null) return '';
    final v = cell.value;
    if (v == null) return '';
    if (v is TextCellValue) return (v.value.text ?? '').trim();
    if (v is IntCellValue) return v.value.toString();
    if (v is DoubleCellValue) return v.value.toString();
    if (v is BoolCellValue) return v.value ? 'yes' : 'no';
    return v.toString().trim();
  }
}
