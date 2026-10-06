/// Menu measurement and addon selection type enumerations.
library;

enum MeasureType {
  piece('Piece', 'pc'),
  gram('Gram', 'g'),
  kilogram('Kilogram', 'kg'),
  liter('Liter', 'L'),
  milliliter('Milliliter', 'mL');

  final String label;
  final String unit;

  const MeasureType(this.label, this.unit);

  String get key => name;

  static MeasureType fromKey(String key) => MeasureType.values
      .firstWhere((e) => e.name == key, orElse: () => MeasureType.piece);
}

enum AddonSelectionType {
  single('Single (Radio)'),
  multi('Multi (Checkbox)');

  final String label;

  const AddonSelectionType(this.label);

  String get key => name;

  static AddonSelectionType fromKey(String key) =>
      AddonSelectionType.values.firstWhere((e) => e.name == key,
          orElse: () => AddonSelectionType.single);
}
