import 'package:flutter_test/flutter_test.dart';
import 'package:z_speed/core/enums/user_enums.dart';
import 'package:z_speed/core/utils/search_helper.dart';

VendorType detectVendorType(String query) {
  final q = SearchHelper.normalize(query);
  var detectedType = VendorType.restaurant;

  if (q.contains('دوا') ||
      q.contains('ادوي') ||
      q.contains('علاج') ||
      q.contains('صيدل') ||
      q.contains('pharmacy') ||
      q.contains('medicine') ||
      q.contains('روشت') ||
      q.contains('دكتور')) {
    detectedType = VendorType.pharmacy;
  } else if (q.contains('سوبر') ||
      q.contains('ماركت') ||
      q.contains('grocery') ||
      q.contains('supermarket') ||
      q.contains('تسوق') ||
      q.contains('جبن') ||
      q.contains('حليب') ||
      q.contains('بقاله') ||
      q.contains('خضار') ||
      q.contains('فواكه') ||
      q.contains('مشروبات') ||
      q.contains('عصير') ||
      q.contains('شيبس')) {
    detectedType = VendorType.supermarket;
  } else if (q.contains('لحم') ||
      q.contains('لحوم') ||
      q.contains('دجاج') ||
      q.contains('فراخ') ||
      q.contains('سمك') ||
      q.contains('اسماك') ||
      q.contains('meat') ||
      q.contains('chicken') ||
      q.contains('fish') ||
      q.contains('protein')) {
    detectedType = VendorType.meatAndProteins;
  } else if (q.contains('ملابس') ||
      q.contains('ازياء') ||
      q.contains('فستان') ||
      q.contains('قميص') ||
      q.contains('عبايه') ||
      q.contains('موضه') ||
      q.contains('clothes') ||
      q.contains('fashion')) {
    detectedType = VendorType.clothes;
  } else if (q.contains('الكترونيات') ||
      q.contains('جوال') ||
      q.contains('هاتف') ||
      q.contains('موبايل') ||
      q.contains('لابتوب') ||
      q.contains('كمبيوتر') ||
      q.contains('تلفزيون') ||
      q.contains('electronics') ||
      q.contains('phone') ||
      q.contains('mobile') ||
      q.contains('laptop')) {
    detectedType = VendorType.electronics;
  } else if (q.contains('كتاب') ||
      q.contains('كتب') ||
      q.contains('مكتبه') ||
      q.contains('قلم') ||
      q.contains('book') ||
      q.contains('stationery')) {
    detectedType = VendorType.bookstore;
  } else if (q.contains('اثاث') ||
      q.contains('مفروشات') ||
      q.contains('سرير') ||
      q.contains('كرسي') ||
      q.contains('furniture') ||
      q.contains('chair')) {
    detectedType = VendorType.homeFurnishing;
  } else if (q.contains('مستعمل') ||
      q.contains('حراج') ||
      q.contains('بيع') ||
      q.contains('شراء') ||
      q.contains('used') ||
      q.contains('sell')) {
    detectedType = VendorType.buyAndSell;
  }
  return detectedType;
}

void main() {
  group('HomeScreen search category detection tests', () {
    test('detects pharmacy keywords with Arabic normalization', () {
      expect(detectVendorType('أدوية'), equals(VendorType.pharmacy));
      expect(detectVendorType('صيدليه'), equals(VendorType.pharmacy));
      expect(detectVendorType('روشتة طبية'), equals(VendorType.pharmacy));
    });

    test('detects supermarket keywords', () {
      expect(detectVendorType('سوبرماركت'), equals(VendorType.supermarket));
      expect(detectVendorType('بقالة'), equals(VendorType.supermarket));
      expect(detectVendorType('خضار وفواكه'), equals(VendorType.supermarket));
    });

    test('detects meat & proteins keywords', () {
      expect(detectVendorType('دجاج طازج'), equals(VendorType.meatAndProteins));
      expect(detectVendorType('لحوم طازجة'), equals(VendorType.meatAndProteins));
      expect(detectVendorType('أسماك'), equals(VendorType.meatAndProteins));
    });

    test('detects clothes & fashion keywords', () {
      expect(detectVendorType('ملابس رجالي'), equals(VendorType.clothes));
      expect(detectVendorType('أزياء وموضة'), equals(VendorType.clothes));
    });

    test('detects electronics keywords', () {
      expect(detectVendorType('إلكترونيات'), equals(VendorType.electronics));
      expect(detectVendorType('جوال أيفون'), equals(VendorType.electronics));
    });

    test('defaults to restaurant if no category matches', () {
      expect(detectVendorType('مطعم البيت السعيد'), equals(VendorType.restaurant));
      expect(detectVendorType('شاورما برجر'), equals(VendorType.restaurant));
    });
  });
}
