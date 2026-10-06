import 'package:flutter_test/flutter_test.dart';
import 'package:z_speed/core/utils/search_helper.dart';

void main() {
  group('SearchHelper tests', () {
    test('normalizes Arabic Alif variants', () {
      expect(SearchHelper.normalize('أرز'), 'ارز');
      expect(SearchHelper.normalize('إيطالي'), 'ايطالي');
      expect(SearchHelper.normalize('آيس كريم'), 'ايس كريم');
    });

    test('normalizes Teh Marbuta and Heh', () {
      expect(SearchHelper.normalize('وجبة'), 'وجبه');
      expect(SearchHelper.normalize('صيدلية'), 'صيدليه');
    });

    test('normalizes Alif Maqsura and Yeh', () {
      expect(SearchHelper.normalize('مشاوى'), 'مشاوي');
      expect(SearchHelper.normalize('مشاوي'), 'مشاوي');
    });

    test('strips Tashkeel diacritics and Tatweel', () {
      expect(SearchHelper.normalize('بِيتْزَا'), 'بيتزا');
      expect(SearchHelper.normalize('بـيـتـزا'), 'بيتزا');
    });

    test('matches Arabic search queries regardless of character variants', () {
      final query1 = SearchHelper.normalize('ارز');
      expect(SearchHelper.matches('أرز بالدجاج', query1), isTrue);

      final query2 = SearchHelper.normalize('وجبة');
      expect(SearchHelper.matches('وجبه عائلية', query2), isTrue);

      final query3 = SearchHelper.normalize('بيتزا');
      expect(SearchHelper.matches('بيتزا بالجبنة', query3), isTrue);
    });

    test('returns false for empty query or null text', () {
      expect(SearchHelper.matches(null, 'test'), isFalse);
      expect(SearchHelper.matches('text', ''), isFalse);
    });
  });
}
