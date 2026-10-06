// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get rememberMe => 'تذكرني';

  @override
  String get criticalUpdateTitle => 'مطلوب تحديث التطبيق';

  @override
  String get criticalUpdateMessage =>
      'يتوفر إصدار جديد من تطبيق زد سبيد. يجب عليك تحديث التطبيق للمتابعة في استخدام خدماتنا.';

  @override
  String get flexibleUpdateTitle => 'تحديث جديد متوفر!';

  @override
  String get flexibleUpdateMessage =>
      'يتوفر إصدار جديد من تطبيق زد سبيد مع تحسينات ومميزات جديدة. هل ترغب في التحديث الآن؟';

  @override
  String get updateNow => 'التحديث الآن';

  @override
  String get updateLater => 'لاحقاً';

  @override
  String get versionSettingsTitle => 'إعدادات تحديث التطبيق';

  @override
  String get minRequiredVersionLabel => 'الحد الأدنى للإصدار المطلوب';

  @override
  String get latestVersionLabel => 'أحدث إصدار للتطبيق';

  @override
  String get iosUrlLabel => 'رابط تحديث iOS (متجر التطبيقات)';

  @override
  String get androidUrlLabel => 'رابط تحديث أندرويد (متجر بلاي)';

  @override
  String get fallbackUrlLabel => 'رابط التحديث الاحتياطي';

  @override
  String get saveSettings => 'حفظ الإعدادات';

  @override
  String get settingsSaved => 'تم حفظ الإعدادات بنجاح';

  @override
  String get onlySuperAdminCanEdit =>
      'يمكن للمسؤول الأعلى فقط تعديل هذه الإعدادات';

  @override
  String get driverEarningsLimitSettings => 'إعدادات حد أرباح السائق';

  @override
  String get globalEarningsLimit => 'حد الأرباح العام (جنيه)';

  @override
  String get earningsLimitDescription =>
      '0.0 أو فارغ يعني بدون حد. سيتم قفل السائقين عندما يتجاوزون هذا الحد.';

  @override
  String get settingsError => 'خطأ في حفظ الإعدادات';

  @override
  String get accountLocked => 'تم قفل الحساب';

  @override
  String get earningsLimitReachedDesc =>
      'لقد وصلت إلى حد الأرباح الخاص بك. لمواصلة استقبال الطلبات، يرجى الاتصال بالإدارة أو زيارة أحد الفروع لتسوية حسابك.';

  @override
  String get currentEarnings => 'الأرباح الحالية:';

  @override
  String get limitThreshold => 'حد الأرباح:';

  @override
  String get refreshStatus => 'تحديث الحالة';

  @override
  String get lockedDueToEarningsLimit =>
      'تم قفل حسابك بسبب تجاوز حد الأرباح. يرجى تسوية حسابك.';

  @override
  String get earningsLimitAndLockStatus => 'حد الأرباح وحالة القفل';

  @override
  String get walletBalanceLabel => 'رصيد المحفظة';

  @override
  String get customEarningsLimit => 'حد الأرباح المخصص';

  @override
  String get noCustomLimit => 'لا يوجد حد مخصص (يتم استخدام الحد العام)';

  @override
  String get settleBalanceAndUnlock => 'تسوية الرصيد وإلغاء القفل';

  @override
  String get setCustomLimitTitle => 'تعيين حد أرباح مخصص';

  @override
  String get earningsLimitLabel => 'حد الأرباح (جنيه)';

  @override
  String get customLimitHint => 'أدخل 0 أو اتركه فارغاً لاستخدام الحد العام';

  @override
  String get customLimitUpdated => 'تم تحديث حد الأرباح المخصص';

  @override
  String get confirmSettleTitle => 'تسوية الرصيد وإلغاء قفل السائق';

  @override
  String confirmSettleBody(Object amount) {
    return 'هل أنت متأكد من أنك تريد إعادة تعيين رصيد بقيمة $amount جنيه إلى 0.0 وإلغاء قفل هذا السائق؟';
  }

  @override
  String get confirmSettleButton => 'تأكيد التسوية';

  @override
  String get settleSuccess => 'تم تسوية رصيد السائق وإلغاء قفل الحساب بنجاح';

  @override
  String settleError(Object error) {
    return 'فشل في إعادة التعيين: $error';
  }

  @override
  String get accountBlockedTitle => 'تم إيقاف الحساب';

  @override
  String get accountBlockedMessage =>
      'تم إيقاف حسابك من قبل الإدارة. إذا كنت تعتقد أن هذا حدث عن طريق الخطأ، يرجى التواصل مع فريق الدعم الفني.';

  @override
  String get contactSupport => 'التواصل مع الدعم';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get registrationDisabledTitle => 'التسجيل مغلق حالياً';

  @override
  String get registrationDisabledMessage =>
      'تم إيقاف تسجيل الحسابات الجديدة مؤقتاً. يرجى التحقق لاحقاً أو تسجيل الدخول بحسابك الحالي.';

  @override
  String get phoneBlacklistedError => 'رقم الهاتف هذا محظور من التسجيل.';

  @override
  String get emailBlacklistedError => 'البريد الإلكتروني هذا محظور من التسجيل.';

  @override
  String get userBlockedError => 'تم إيقاف حسابك. يرجى التواصل مع الدعم الفني.';

  @override
  String get allowNewSignupsLabel => 'السماح بتسجيل مستخدمين جدد';

  @override
  String get allowNewSignupsSubtitle =>
      'تفعيل أو تعطيل إمكانية تسجيل مستخدمين جدد في المنصة';

  @override
  String get signupDisabledMessageLabel => 'رسالة إغلاق التسجيل';

  @override
  String get maintenanceMessageLabel => 'رسالة وضع الصيانة';

  @override
  String get blacklistManagementTitle => 'القائمة المحظورة والمحظورات';

  @override
  String get blacklistSubtitle =>
      'إدارة أرقام الهواتف والبريد الإلكتروني المحظورة';

  @override
  String get addToBlacklist => 'إضافة إلى القائمة المحظورة';

  @override
  String get removeFromBlacklist => 'إزالة';

  @override
  String confirmRemoveBlacklist(Object identifier) {
    return 'هل أنت متأكد من رغبتك في إلغاء حظر $identifier؟';
  }

  @override
  String get blockedIdentifiers => 'العناصر المحظورة';

  @override
  String get blockReason => 'السبب';

  @override
  String get blockReasonHint =>
      'مثال: نشاط احتيالي، انتهاك السياسات، إلغاءات متكررة';

  @override
  String get blockType => 'النوع';

  @override
  String get phoneType => 'رقم الهاتف';

  @override
  String get emailType => 'البريد الإلكتروني';

  @override
  String get uidType => 'معرف المستخدم';

  @override
  String get enterIdentifier => 'أدخل رقم الهاتف أو البريد أو المعرف';

  @override
  String get blacklistEmpty => 'لا توجد عناصر محظورة حالياً.';

  @override
  String get addedToBlacklistSuccess =>
      'تمت إضافة العنصر إلى القائمة المحظورة بنجاح.';

  @override
  String get removedFromBlacklistSuccess => 'تمت إزالة الحظر بنجاح.';

  @override
  String get blacklistUserCheckbox =>
      'حظر رقم الهاتف والبريد الإلكتروني لمنع إعادة التسجيل';

  @override
  String get appTitle => 'زد سبيد';

  @override
  String welcomeMessage(String name) {
    return 'أهلاً بك مجدداً، $name!';
  }

  @override
  String get ok => 'حسناً';

  @override
  String get cancel => 'إلغاء';

  @override
  String get submit => 'تقديم';

  @override
  String get save => 'حفظ';

  @override
  String get loading => 'جاري التحميل...';

  @override
  String get errorOccurred => 'حدث خطأ. يرجى المحاولة مرة أخرى.';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get yes => 'نعم';

  @override
  String get no => 'لا';

  @override
  String get success => 'نجاح';

  @override
  String get confirm => 'تأكيد';

  @override
  String get loginTitle => 'تسجيل الدخول إلى حسابك';

  @override
  String get phoneNumberLabel => 'رقم الهاتف';

  @override
  String get continueButton => 'استمرار';

  @override
  String get otpPrompt => 'أدخل رمز التحقق';

  @override
  String get didNotReceiveCode => 'لم تستلم الرمز؟';

  @override
  String get resendCode => 'إعادة إرسال';

  @override
  String get enterName => 'ما هو اسمك؟';

  @override
  String get accountPending => 'الحساب قيد المراجعة';

  @override
  String get forDeliveryService => 'لخدمات التوصيل';

  @override
  String get emailAddress => 'عنوان البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get logIn => 'تسجيل الدخول';

  @override
  String get signUp => 'إنشاء حساب';

  @override
  String get signInWithGoogle => 'تسجيل الدخول باستخدام جوجل';

  @override
  String get continueWithPhone => 'المتابعة برقم الهاتف';

  @override
  String get orContinueWith => 'أو المتابعة باستخدام';

  @override
  String get dontHaveAnAccount => 'ليس لديك حساب؟';

  @override
  String get alreadyHaveAnAccount => 'هل لديك حساب بالفعل؟';

  @override
  String get orText => 'أو';

  @override
  String get createAccount => 'إنشاء حساب';

  @override
  String get welcomeBack => 'أهلاً بعودتك!';

  @override
  String get joinOurDeliveryService => 'انضم إلى خدمة التوصيل الخاصة بنا';

  @override
  String get loginToYourAccount => 'تسجيل الدخول إلى حسابك';

  @override
  String get forgotPassword => 'هل نسيت كلمة المرور؟';

  @override
  String get emailOrUsername => 'البريد الإلكتروني أو اسم المستخدم';

  @override
  String get emailHint => 'مثال: owner@restaurant.com';

  @override
  String get pleaseEnterYourEmail => 'الرجاء إدخال بريدك الإلكتروني';

  @override
  String get pleaseEnterValidEmail => 'الرجاء إدخال بريد إلكتروني صالح';

  @override
  String get enterYourPassword => 'أدخل كلمة المرور';

  @override
  String get passwordsDoNotMatch => 'كلمات المرور غير متطابقة';

  @override
  String get homeTab => 'الرئيسية';

  @override
  String get browseTab => 'تصفح';

  @override
  String get cartTab => 'عربة التسوق';

  @override
  String get trackOrderTab => 'تتبع الطلب';

  @override
  String get profileTab => 'حسابي';

  @override
  String get ourServices => 'خدماتنا';

  @override
  String get chooseService => 'اختر خدمة للبدء';

  @override
  String get food => 'طعام';

  @override
  String get groceries => 'بقالة';

  @override
  String get transport => 'نقل';

  @override
  String get pharmacy => 'صيدلية';

  @override
  String get comingSoon => 'قريباً';

  @override
  String get searchRestaurants => 'ابحث عن مطاعم أو مأكولات...';

  @override
  String get popularCategories => 'الفئات الشائعة';

  @override
  String get featuredRestaurants => 'مطاعم مميزة';

  @override
  String get freeDelivery => 'توصيل مجاني';

  @override
  String get allRestaurants => 'جميع المطاعم';

  @override
  String get openNow => 'مفتوح الآن';

  @override
  String get closed => 'مغلق';

  @override
  String get yourCart => 'عربة التسوق الخاصة بك';

  @override
  String get total => 'الإجمالي';

  @override
  String get subtotal => 'المجموع الفرعي';

  @override
  String get deliveryFee => 'رسوم التوصيل';

  @override
  String get taxes => 'الضرائب';

  @override
  String get proceedToCheckout => 'متابعة الدفع';

  @override
  String get emptyCart => 'عربة التسوق فارغة';

  @override
  String get addItems => 'أضف عناصر للبدء';

  @override
  String get addToCart => 'أضف إلى السلة';

  @override
  String get checkout => 'الدفع';

  @override
  String get myOrders => 'طلباتي';

  @override
  String get paymentMethods => 'طرق الدفع';

  @override
  String get savedAddresses => 'العناوين المحفوظة';

  @override
  String get settings => 'الإعدادات';

  @override
  String get changeLanguage => 'تغيير اللغة';

  @override
  String get rating => 'التقييم';

  @override
  String get deliveryTimeFilter => 'وقت التوصيل';

  @override
  String get deliveryFeeFilter => 'رسوم التوصيل';

  @override
  String get name => 'الاسم';

  @override
  String get openOnly => 'المفتوحة فقط';

  @override
  String get noRestaurantsFound => 'لم يتم العثور على مطاعم';

  @override
  String get noPharmaciesFound => 'لم يتم العثور على صيدليات';

  @override
  String get noSupermarketsFound => 'لم يتم العثور على سوبر ماركت';

  @override
  String get tryAdjustingFilters => 'جرب تعديل عوامل التصفية أو البحث';

  @override
  String get clearFilters => 'مسح عوامل التصفية';

  @override
  String get addItemsFromRestaurants => 'أضف عناصر من المطاعم';

  @override
  String get completed => 'مكتمل';

  @override
  String get viewDetails => 'عرض التفاصيل';

  @override
  String get edit => 'تعديل';

  @override
  String get close => 'مغلق';

  @override
  String get tripDetails => 'تفاصيل الرحلة';

  @override
  String get tripHistory => 'تاريخ الرحلات';

  @override
  String get callCustomer => 'الاتصال بالعميل';

  @override
  String get call => 'اتصال';

  @override
  String get callRestaurant => 'الاتصال بالمطعم';

  @override
  String get itemsInOrder => 'العناصر في الطلب:';

  @override
  String get noActiveTrip => 'لا توجد رحلة نشطة';

  @override
  String get viewAvailableOrders => 'عرض الطلبات المتاحة';

  @override
  String get back => 'رجوع';

  @override
  String get next => 'التالي';

  @override
  String get enterLicensePlateHint =>
      'أدخل 3 أو 4 أرقام تليها 2 أو 3 أو 4 أحرف.';

  @override
  String get licensePlate => 'لوحة الترخيص';

  @override
  String get navigate => 'تنقل';

  @override
  String get driverApplication => 'طلب السائق';

  @override
  String get applicationSubmitted => 'تم تقديم الطلب!';

  @override
  String get done => 'تم';

  @override
  String get verifyContact => 'يرجى التحقق من البريد الإلكتروني ورقم الهاتف.';

  @override
  String get uploadRequiredDocs => 'يرجى تحميل جميع المستندات المطلوبة.';

  @override
  String get fileExceedsLimit =>
      'يتجاوز حجم الملف الحد المسموح به (10 ميجابايت).';

  @override
  String get trackDriverLocation => 'تتبع موقع السائق';

  @override
  String get bookThisRide => 'احجز هذه الرحلة';

  @override
  String get viewRouteMap => 'عرض المسار (خريطة)';

  @override
  String get markAsPickedUp => 'تحديد كتم الاستلام';

  @override
  String get markAsDelivered => 'تحديد كتم التوصيل';

  @override
  String get confirmDelivery => 'تأكيد التوصيل';

  @override
  String get activeMission => 'مهمة نشطة';

  @override
  String get restaurant => 'المطعم';

  @override
  String get customer => 'العميل';

  @override
  String get openMap => 'فتح الخريطة';

  @override
  String get reject => 'رفض';

  @override
  String get accept => 'قبول';

  @override
  String get orderDetails => 'تفاصيل الطلب';

  @override
  String get itemsToDeliver => 'العناصر المراد توصيلها:';

  @override
  String get noItemDetailsAvailable => 'لا تتوفر تفاصيل للعنصر.';

  @override
  String get closeDetails => 'إغلاق التفاصيل';

  @override
  String get rejectRequest => 'رفض الطلب';

  @override
  String get myProfile => 'ملفي الشخصي';

  @override
  String get noDataAvailable => 'لا توجد بيانات متاحة';

  @override
  String get documents => 'المستندات';

  @override
  String get couldNotOpenDocLink => 'تعذر فتح رابط المستند';

  @override
  String get remove => 'إزالة';

  @override
  String get assignToOrder => 'تعيين للطلب';

  @override
  String get assign => 'تعيين';

  @override
  String get removeDriver => 'إزالة السائق';

  @override
  String get amount => 'المبلغ';

  @override
  String get description => 'الوصف';

  @override
  String get review => 'مراجعة';

  @override
  String get approve => 'موافقة';

  @override
  String get disputeDetails => 'تفاصيل النزاع';

  @override
  String get descriptionLabel => 'الوصف:';

  @override
  String get filterOptionsComingSoon => 'خيارات التصفية قريباً...';

  @override
  String get applyFilters => 'تطبيق عوامل التصفية';

  @override
  String get filterDisputes => 'تصفية النزاعات';

  @override
  String get disputeResolution => 'حل النزاعات';

  @override
  String get sortBy => 'ترتيب حسب';

  @override
  String get gotIt => 'فهمت';

  @override
  String get editUser => 'تعديل المستخدم';

  @override
  String get rejectApplication => 'رفض الطلب';

  @override
  String get analyticsDashboard => 'لوحة معلومات التحليلات';

  @override
  String get generateReport => 'إنشاء تقرير';

  @override
  String get reportGenerationComingSoon => 'إنشاء التقرير قريباً';

  @override
  String get generate => 'إنشاء';

  @override
  String get addRestaurant => 'إضافة مطعم';

  @override
  String get createOrder => 'إنشاء طلب';

  @override
  String get delete => 'حذف';

  @override
  String get provideRejectReason => 'يرجى تقديم سبب لرفض هذا القسم.';

  @override
  String get applicationApproved => 'تمت الموافقة على الطلب';

  @override
  String get applicationRejected => 'تم رفض الطلب';

  @override
  String get allSectionsApproved =>
      'تمت الموافقة على جميع الأقسام — تمت الموافقة على الطلب!';

  @override
  String get recentActivity => 'النشاط الأخير';

  @override
  String get noRecentActivity => 'لا يوجد نشاط حديث';

  @override
  String get saveChanges => 'حفظ التغييرات';

  @override
  String get addNewRestaurant => 'إضافة مطعم جديد';

  @override
  String get editRestaurant => 'تعديل المطعم';

  @override
  String get editVendor => 'Edit Vendor';

  @override
  String get vendorUpdatedSuccessfully => 'Vendor updated successfully';

  @override
  String get deleteRestaurant => 'حذف المطعم';

  @override
  String get addUser => 'إضافة مستخدم';

  @override
  String get changeStatus => 'تغيير الحالة';

  @override
  String get updateStatus => 'تحديث الحالة';

  @override
  String get addNewUser => 'إضافة مستخدم جديد';

  @override
  String get deleteUser => 'حذف المستخدم';

  @override
  String get userDetails => 'تفاصيل المستخدم';

  @override
  String get changeUserStatus => 'تغيير حالة المستخدم';

  @override
  String get newOrder => 'طلب جديد';

  @override
  String get recentOrders => 'الطلبات الأخيرة';

  @override
  String get quickActions => 'إجراءات سريعة';

  @override
  String get add => 'إضافة';

  @override
  String get deleteCuisineType => 'حذف نوع المطبخ';

  @override
  String get addCuisineType => 'إضافة نوع مطبخ';

  @override
  String get create => 'إنشاء';

  @override
  String get editCuisineType => 'تعديل نوع المطبخ';

  @override
  String get cuisineTypeDeleted => 'تم حذف نوع المطبخ';

  @override
  String get bothNamesRequired =>
      'يلزم إدخال الأسماء باللغتين الإنجليزية والعربية';

  @override
  String get cuisineTypeCreated => 'تم إنشاء نوع المطبخ';

  @override
  String get cuisineTypeUpdated => 'تم تحديث نوع المطبخ';

  @override
  String get noApplicationsFound => 'لم يتم العثور على طلبات';

  @override
  String get couldNotLoadImage => 'تعذر تحميل الصورة';

  @override
  String get createNewOrder => 'إنشاء طلب جديد';

  @override
  String get deleteOrder => 'حذف الطلب';

  @override
  String get editOrder => 'تعديل الطلب';

  @override
  String get applicationReview => 'مراجعة الطلب';

  @override
  String get all => 'الكل';

  @override
  String get drivers => 'السائقين';

  @override
  String get restaurants => 'المطاعم';

  @override
  String get logoutAllOthers => 'تسجيل الخروج لكافة الأجهزة الأخرى';

  @override
  String get allOtherSessionsLogged =>
      'تم تسجيل الخروج من جميع الجلسات الأخرى بنجاح';

  @override
  String get samsungGalaxySessionLogged =>
      'تم تسجيل الخروج من جلسة سامسونج جالاكسي';

  @override
  String get ipadAirSessionLogged => 'تم تسجيل الخروج من جلسة آيباد إير';

  @override
  String get macbookProSessionLogged => 'تم تسجيل الخروج من جلسة ماك بوك برو';

  @override
  String get activeSessions => 'الجلسات النشطة';

  @override
  String get updatePassword => 'تحديث كلمة المرور';

  @override
  String get passwordChangedSuccessfully => 'تم تغيير كلمة المرور بنجاح';

  @override
  String get newPasswordsDoNot => 'كلمات المرور الجديدة غير متطابقة';

  @override
  String get passwordMustBeAt => 'كلمة المرور يجب أن تكون 8 أحرف على الأقل';

  @override
  String get pleaseFillAllFields => 'يرجى ملء جميع الحقول';

  @override
  String get pleaseEnterYourCurrent => 'الرجاء إدخال كلمة المرور الحالية';

  @override
  String get oneSpecialCharacter => '• حرف خاص واحد (رمز)';

  @override
  String get oneNumber => '• رقم واحد';

  @override
  String get oneLowercaseLetter => '• حرف صغير واحد';

  @override
  String get oneUppercaseLetter => '• حرف كبير واحد';

  @override
  String get atLeast8Characters => '• 8 أحرف على الأقل';

  @override
  String get changePassword => 'تغيير كلمة المرور';

  @override
  String get twoFaSettingsUpdatedSuccessfully =>
      'تم تحديث إعدادات المصادقة الثنائية بنجاح';

  @override
  String get smsIsGoodFor => '• الرسائل القصيرة جيدة للنسخ الاحتياطي';

  @override
  String get useEmailForPrimary => '• استخدم البريد الإلكتروني للتحقق الأساسي';

  @override
  String get enableAtLeastOne =>
      '• تفعيل طريقة واحدة على الأقل للمصادقة الثنائية';

  @override
  String get receiveCodeViaSms => 'تلقي الرمز عبر رسالة قصيرة';

  @override
  String get smsVerification => 'التحقق عبر الرسائل القصيرة';

  @override
  String get receiveCodeViaEmail => 'تلقي الرمز عبر البريد الإلكتروني';

  @override
  String get emailVerification => 'التحقق عبر البريد الإلكتروني';

  @override
  String get twofactorAuthentication => 'المصادقة الثنائية';

  @override
  String get frequentlyAskedQuestions => 'الأسئلة الشائعة';

  @override
  String get faq => 'الأسئلة الشائعة';

  @override
  String get available9am5pmEst =>
      'متاح من 9 صباحاً إلى 5 مساءً بتوقيت شرق أمريكا';

  @override
  String get liveChat => 'الدردشة المباشرة';

  @override
  String get phoneSupport => 'الدعم الهاتفي';

  @override
  String get emailSupport => 'دعم البريد الإلكتروني';

  @override
  String get helpSupport => 'المساعدة والدعم';

  @override
  String get readFullTerms => 'قراءة الشروط الكاملة';

  @override
  String get pricesAndFeesMay => '• الأسعار والرسوم قد تتغير';

  @override
  String get serviceMayBeInterrupted => '• قد تنقطع الخدمة للصيانة';

  @override
  String get weReserveTheRight => '• نحتفظ بالحق في تعديل الشروط';

  @override
  String get youAreResponsibleFor => '• أنت مسؤول عن أمان حسابك';

  @override
  String get youMustBeAt => '• يجب أن يكون عمرك 18 عاماً على الأقل';

  @override
  String get termsOfService => 'شروط الخدمة';

  @override
  String get readFullPrivacyPolicy => 'قراءة سياسة الخصوصية الكاملة';

  @override
  String get youControlYourPrivacy =>
      '• أنت تتحكم في إعدادات الخصوصية الخاصة بك';

  @override
  String get weNeverSellYour => '• نحن لا نبيع بياناتك أبداً';

  @override
  String get yourDataIsEncrypted => '• بياناتك مشفرة';

  @override
  String get weCollectOnlyNecessary => '• نجمع البيانات الضرورية فقط';

  @override
  String get keyPoints => 'النقاط الرئيسية:';

  @override
  String get privacyPolicy => 'سياسة الخصوصية';

  @override
  String get deleteAccount => 'حذف الحساب';

  @override
  String get pleaseTypeDeleteTo => 'يرجى كتابة DELETE للتأكيد';

  @override
  String get typeDeleteToConfirm => 'اكتب \"DELETE\" للتأكيد:';

  @override
  String get removePaymentInformation => '• إزالة معلومات الدفع';

  @override
  String get deleteAllCustomerReviews => '• حذف جميع مراجعات العملاء';

  @override
  String get removeYourRestaurantFrom => '• إزالة مطعمك من المنصة';

  @override
  String get cancelAllPendingOrders => '• إلغاء جميع الطلبات المعلقة';

  @override
  String get permanentlyDeleteAllYour => '• حذف جميع بياناتك نهائياً';

  @override
  String get thisWill => 'سيؤدي ذلك إلى:';

  @override
  String get areYouSureYou => 'هل أنت متأكد من أنك تريد حذف حسابك؟';

  @override
  String get requestDownload => 'طلب التنزيل';

  @override
  String get activityLogs => '• سجلات الأنشطة';

  @override
  String get preferences => 'التفضيلات';

  @override
  String get restaurantSettings => '• إعدادات المطعم';

  @override
  String get paymentRecords => '• سجلات الدفع';

  @override
  String get orderHistory => '• سجل الطلبات';

  @override
  String get accountInformation => '• معلومات الحساب';

  @override
  String get thisIncludes => 'وهذا يشمل:';

  @override
  String get selectDataFormat => 'اختر صيغة البيانات:';

  @override
  String get downloadYourData => 'تنزيل بياناتك';

  @override
  String get descriptionX => 'الوصف:';

  @override
  String get couldNotOpenDocument => 'لا يمكن فتح رابط المستند';

  @override
  String get pleaseProvideAReason => 'يرجى إعطاء سبب لرفض هذا القسم.';

  @override
  String get allSectionsApprovedApplication =>
      'تمت الموافقة على جميع الأقسام — تمت الموافقة على الطلب!';

  @override
  String get bothEnglishAndArabic =>
      'يجب كتابة الاسم باللغتين الإنجليزية والعربية';

  @override
  String get optionDeletedSuccessfully => 'تم حذف الخيار بنجاح';

  @override
  String get deleteOption => 'حذف الخيار';

  @override
  String get groupDeletedSuccessfully => 'تم حذف المجموعة بنجاح';

  @override
  String get deleteGroup => 'حذف المجموعة';

  @override
  String get optionNameIsRequired => 'اسم الخيار مطلوب';

  @override
  String get customerCanSelectThis => 'يمكن للعميل تحديد هذا الخيار';

  @override
  String get available => 'متاح';

  @override
  String get preselectedForCustomer => 'تم تحديده مسبقاً للعميل';

  @override
  String get defaultSelection => 'الخيار الافتراضي';

  @override
  String get groupUpdatedSuccessfully => 'تم تحديث المجموعة بنجاح';

  @override
  String get groupCreatedSuccessfully => 'تم إنشاء المجموعة بنجاح';

  @override
  String get groupNameIsRequired => 'اسم المجموعة مطلوب';

  @override
  String get customerMustSelectAn => 'يجب على العميل تحديد خيار';

  @override
  String get required => 'مطلوب';

  @override
  String get multiple => 'متعدد';

  @override
  String get single => 'فردي';

  @override
  String get selectionType => 'نوع الاختيار:';

  @override
  String get addOption => 'إضافة خيار';

  @override
  String get addFirstGroup => 'إضافة أول مجموعة';

  @override
  String get itemNotFound => 'العنصر غير موجود';

  @override
  String get manageAddons => 'إدارة الإضافات';

  @override
  String get cuisineTypes => 'أنواع المطابخ';

  @override
  String get loadingCuisines => 'جاري تحميل أنواع المطابخ...';

  @override
  String get cuisineTypesUpdated => 'تم تحديث أنواع المطابخ بنجاح';

  @override
  String get areYouSureYouX => 'هل أنت متأكد أنك تريد تسجيل الخروج؟';

  @override
  String get symbolKey => ' *';

  @override
  String get track => 'تتبع';

  @override
  String get assignDriver => 'تعيين سائق';

  @override
  String get noCuisineTypesAvailable =>
      'لا توجد أنواع طهي متاحة. يرجى الاتصال بالمسؤول.';

  @override
  String get menuManager => 'مدير القائمة';

  @override
  String get pleaseLogInTo => 'يرجى تسجيل الدخول لإدارة القائمة';

  @override
  String get itemDeletedSuccessfully => 'تم حذف العنصر بنجاح';

  @override
  String get addItem => 'إضافة عنصر';

  @override
  String get addFirstItem => 'إضافة أول عنصر';

  @override
  String get coverImage => 'صورة الغلاف';

  @override
  String get restaurantLogo => 'شعار المطعم';

  @override
  String get viewReceipt => 'عرض الإيصال';

  @override
  String get totalX => 'الإجمالي';

  @override
  String get tryAdjustingYourSearch => 'جرب تعديل بحثك أو الفلاتر';

  @override
  String get noOrdersFound => 'لا توجد طلبات';

  @override
  String get lowestAmount => 'أقل مبلغ';

  @override
  String get highestAmount => 'أعلى مبلغ';

  @override
  String get oldestFirst => 'الأقدم أولاً';

  @override
  String get newestFirst => 'الأحدث أولاً';

  @override
  String get manageAndTrackAll => 'إدارة وتتبع جميع الطلبات';

  @override
  String get orderHistoryX => 'سجل الطلبات';

  @override
  String get selectCuisineType => 'اختر نوع الطهي...';

  @override
  String get symbolKeyX => 'إكس';

  @override
  String get operatingHours => 'ساعات العمل';

  @override
  String get workingHours => 'Working Hours';

  @override
  String get basicInformation => 'Basic Information';

  @override
  String get minDeliveryTime => 'Min Delivery Time';

  @override
  String get maxDeliveryTime => 'Max Delivery Time';

  @override
  String get pickOnMap => 'اختر من الخريطة';

  @override
  String get coordinates => 'الإحداثيات';

  @override
  String get documentation => 'الوثائق';

  @override
  String get supportCenter => 'مركز الدعم';

  @override
  String get checkOurDocumentationOr => 'راجع وثائقنا أو اتصل بالدعم.';

  @override
  String get needHelp => 'هل تحتاج لمساعدة؟';

  @override
  String get noOrdersYet => 'لا توجد طلبات بعد';

  @override
  String get thisWeek => 'هذا الأسبوع';

  @override
  String get restaurantCreatedWelcomeAboard =>
      'تم إنشاء المطعم! مرحباً بك معنا 🎉';

  @override
  String get restaurantNameIsRequired => 'اسم المطعم مطلوب';

  @override
  String get createRestaurant => 'إنشاء المطعم';

  @override
  String get notAuthenticatedPleaseLog => 'غير مسجل. يرجى تسجيل الدخول.';

  @override
  String get restaurantDetailsMissing => 'تفاصيل المطعم مفقودة.';

  @override
  String get orderRejected => 'تم رفض الطلب';

  @override
  String get selectAReasonFor => 'حدد سبباً لرفض هذا الطلب:';

  @override
  String get rejectOrder => 'رفض الطلب';

  @override
  String get orderMarkedAsReady => 'تم وضع علامة على الطلب كجاهز للاستلام';

  @override
  String get orderPreparationStarted => 'بدأ تجهيز الطلب';

  @override
  String get orderAcceptedSuccessfully => 'تم قبول الطلب بنجاح';

  @override
  String get awaitingDriverPickup => 'في انتظار استلام السائق...';

  @override
  String get assignDriverOptional => 'تعيين سائق (اختياري)';

  @override
  String get markAsReadyFor => 'وضع علامة جاهز للاستلام';

  @override
  String get startPreparing => 'بدء التحضير';

  @override
  String get trackDriver => 'تتبع السائق';

  @override
  String get paymentMethod => 'طريقة الدفع';

  @override
  String get placedAt => 'تم الطلب في';

  @override
  String get status => 'الحالة';

  @override
  String get camera => 'الكاميرا';

  @override
  String get gallery => 'المعرض';

  @override
  String get chooseLogoFrom => 'اختر الشعار من:';

  @override
  String get changeLogo => 'تغيير الشعار';

  @override
  String get closingTime => 'وقت الإغلاق';

  @override
  String get openingTime => 'وقت الافتتاح';

  @override
  String get markAsReady => 'وضع علامة جاهز';

  @override
  String get waitingForDriverLocation => 'في انتظار موقع السائق...';

  @override
  String get map => 'الخريطة';

  @override
  String get uploadingCover => 'جاري رفع الغلاف...';

  @override
  String get locationUpdatedFromMap => 'تم تحديث الموقع من الخريطة';

  @override
  String get goToDashboard => 'اذهب للوحة التحكم';

  @override
  String get fileExceedsThe10mb => 'الملف يتعدى حجم 10 ميجا بايت.';

  @override
  String get pleaseUploadBothLogo => 'يرجى تحميل الشعار وصورة الغلاف.';

  @override
  String get pleaseUploadAllRequired => 'يرجى تحميل جميع المستندات المطلوبة.';

  @override
  String get selectAtLeastOne => 'اختر نوع طهي واحد على الأقل.';

  @override
  String get pleaseVerifyBothEmail =>
      'يرجى التحقق من البريد الإلكتروني ورقم الهاتف.';

  @override
  String get restaurantApplication => 'طلب المطعم';

  @override
  String vendorApplication(String vendorType) {
    return 'طلب $vendorType';
  }

  @override
  String get vendorTypeStep => 'نوع البائع';

  @override
  String get vendorTypeSubtitle => 'ما نوع النشاط التجاري الذي تسجله؟';

  @override
  String get supermarket => 'سوبر ماركت';

  @override
  String get foodAndDining => 'طعام ومطاعم';

  @override
  String get groceriesAndDailyNeeds => 'بقالة واحتياجات يومية';

  @override
  String get medicineAndHealthProducts => 'أدوية ومنتجات صحية';

  @override
  String get deliveryFeeSettingsSaved => 'تم حفظ إعدادات رسوم التوصيل';

  @override
  String get discard => 'إلغاء';

  @override
  String get discardChanges => 'إلغاء التغييرات؟';

  @override
  String get addTier => 'إضافة مستوى';

  @override
  String get differentRatesForDistance => 'أسعار مختلفة بناءً على المسافات';

  @override
  String get tieredPricing => 'تسعير متدرج';

  @override
  String get baseFeePerKm => 'رسوم أساسية + السعر لكل كيلومتر';

  @override
  String get perKilometer => 'لكل كيلومتر';

  @override
  String get calculateFeeBasedOn => 'حساب الرسوم استناداً إلى مسافة التوصيل';

  @override
  String get distancebasedFee => 'الرسوم حسب المسافة';

  @override
  String get chargeAFixedDelivery => 'فرض رسوم توصيل ثابتة لكل طلب';

  @override
  String get fixedFee => 'رسوم ثابتة';

  @override
  String get youHaveTheLatest => 'لديك أحدث إصدار';

  @override
  String get checkingForUpdates => 'التحقق من التحديثات...';

  @override
  String get checkForUpdates => 'التحقق من وجود تحديثات';

  @override
  String get privacyPolicyContent => 'محتوى سياسة الخصوصية...';

  @override
  String get termsOfServiceContent => 'محتوى شروط الخدمة...';

  @override
  String get issueReportedSuccessfully => 'تم إرسال بلاغ المشكلة بنجاح.';

  @override
  String get files => 'الملفات';

  @override
  String get fileAttachedFromFiles => 'تم إرفاق الملف من الملفات';

  @override
  String get fileAttachedFromCamera => 'تم إرفاق الملف من الكاميرا';

  @override
  String get fileAttachedFromGallery => 'تم إرفاق الملف من المعرض';

  @override
  String get chooseFileFrom => 'اختيار ملف من:';

  @override
  String get attachFile => 'إرفاق ملف';

  @override
  String get blogContent => 'محتوى المدونة';

  @override
  String get blogUpdates => 'المدونة والتحديثات';

  @override
  String get technicalDocumentation => 'الوثائق التقنية';

  @override
  String get videoTutorials => 'دروس فيديو';

  @override
  String get userGuideContent => 'محتوى دليل المستخدم';

  @override
  String get userGuide => 'دليل المستخدم';

  @override
  String get connectedToSupportAgent => 'تم الاتصال بوكيل الدعم';

  @override
  String get connectingToSupportAgent => 'جاري الاتصال بوكيل الدعم...';

  @override
  String get openingLiveChat => 'جاري فتح المحادثة المباشرة...';

  @override
  String get available247 => 'متاح 24/7';

  @override
  String get openingEmail => 'جاري فتح البريد الإلكتروني...';

  @override
  String get supportspeedridescom => 'support@speedrides.com';

  @override
  String get callingSupport => 'جاري الاتصال بالدعم...';

  @override
  String get phoneNumberExample => '+201000000000';

  @override
  String get openMaps => 'فتح الخرائط';

  @override
  String get locationOpenedInMaps => 'تم فتح الموقع في الخرائط!';

  @override
  String get send => 'إرسال';

  @override
  String get messageSentToDriver => 'تم إرسال الرسالة إلى السائق!';

  @override
  String get callingDriver => 'جاري الاتصال بالسائق...';

  @override
  String get shareOrder => 'مشاركة الطلب';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get message => 'رسالة';

  @override
  String get addedToCart => 'تمت الإضافة للسلة';

  @override
  String get labelAndAddressAre => 'التسمية والعنوان حقلان مطلوبان';

  @override
  String get addSavedAddress => 'إضافة عنوان محفوظ';

  @override
  String get addNew => 'إضافة جديد';

  @override
  String get noAddressesSavedYet => 'لا توجد عناوين محفوظة بعد';

  @override
  String get pleaseLogin => 'يرجى تسجيل الدخول';

  @override
  String get ratingFeatureComingSoon => 'ميزة التقييم قادمة قريباً';

  @override
  String get noMenuItemsAvailable => 'لا توجد عناصر متاحة في القائمة';

  @override
  String get goBack => 'رجوع';

  @override
  String get restaurantNotFound => 'لم يتم العثور على المطعم';

  @override
  String get errorLoadingRestaurant => 'خطأ في تحميل المطعم';

  @override
  String get createAMenuSection => 'أنشئ قسم في القائمة أولاً';

  @override
  String get replace => 'استبدال';

  @override
  String get replaceCartItems => 'إستبدال عناصر السلة؟';

  @override
  String get noMenuItemsYet => 'لا توجد عناصر في القائمة بعد';

  @override
  String get cancelOrder => 'إلغاء الطلب';

  @override
  String get keepOrder => 'الاحتفاظ بالطلب';

  @override
  String get pleaseSelectAReason => 'يرجى تحديد سبب للإلغاء:';

  @override
  String get contactSupportFeatureComing => 'ميزة الاتصال بالدعم قادمة قريباً';

  @override
  String get orderNotFound => 'الطلب غير موجود';

  @override
  String get trackOrder => 'تتبع الطلب';

  @override
  String get estimatedDelivery3045Minutes => 'وقت التوصيل المقدر: 30-45 دقيقة';

  @override
  String get orderPlaced => 'تم تقديم الطلب';

  @override
  String get apply => 'تطبيق';

  @override
  String get useCurrentLocation => 'استخدام الموقع الحالي';

  @override
  String get locationPickerComingSoon => 'منتقي الموقع قادم قريباً';

  @override
  String get enter3Or4 => 'أدخل 3 أو 4 أرقام متبوعة بـ 2 أو 3 أو 4 أحرف.';

  @override
  String get symbolKeyXX => '-';

  @override
  String get myAccount => 'حسابي';

  @override
  String get noDocumentsUploaded => 'لم يتم رفع أي مستندات.';

  @override
  String get editAnyway => 'التعديل على أي حال';

  @override
  String get editApprovedSection => 'تعديل القسم المُعتمد؟';

  @override
  String get sectionUpdatedSentBack =>
      'تم تحديث القسم — إعادة الإرسال للمراجعة.';

  @override
  String get noApplicationFound => 'لم يتم العثور على طلبات.';

  @override
  String get myApplication => 'طلبي';

  @override
  String get notificationDeleted => 'تم حذف الإشعار';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get shareReceipt => 'مشاركة الإيصال';

  @override
  String get shareReceiptFeatureComing => 'ميزة مشاركة الإيصال قادمة قريباً!';

  @override
  String get paymentReceipt => 'إيصال التوصيل';

  @override
  String get minimumPayoutAmount => 'الحد الأدنى لمبلغ الدفع';

  @override
  String get monthly => 'شهرياً';

  @override
  String get weekly => 'أسبوعياً';

  @override
  String get daily => 'يومياً';

  @override
  String get payoutFrequency => 'معدل تكرار الدفع';

  @override
  String get savePaymentMethod => 'حفظ طريقة الدفع';

  @override
  String get receivePaymentsViaVodafone => 'استلام المدفوعات عبر فودافون كاش';

  @override
  String get vodafoneCash => 'فودافون كاش';

  @override
  String get receivePaymentsViaInstapay => 'استلام المدفوعات عبر إنستاباي';

  @override
  String get instapay => 'إنستاباي';

  @override
  String get addPaymentMethod => 'إضافة طريقة دفع';

  @override
  String get paymentMethodSaved => 'تم حفظ طريقة الدفع';

  @override
  String get notSignedIn => 'لم تسجل دخولك';

  @override
  String get taxInformationPage => 'صفحة المعلومات الضريبية';

  @override
  String get taxInformation => 'المعلومات الضريبية';

  @override
  String get digitalWallet => 'المحفظة الرقمية';

  @override
  String get creditdebitCard => 'بطاقة الائتمان/الخصم المباشر';

  @override
  String get editDetails => 'تعديل التفاصيل';

  @override
  String get setAsDefault => 'تعيين كافتراضي';

  @override
  String get defaultText => 'افتراضي';

  @override
  String get addNewPaymentMethod => 'إضافة طريقة دفع جديدة';

  @override
  String get addWallet => 'إضافة محفظة';

  @override
  String get addDigitalWallet => 'إضافة محفظة رقمية';

  @override
  String get addCard => 'إضافة بطاقة';

  @override
  String get alreadyHaveAnAccountX => 'لديك حساب بالفعل؟ سجل دخولك';

  @override
  String get getHelpWithPrivacy => 'احصل على مساعدة بشأن قضايا الخصوصية';

  @override
  String get readOurTermsOf => 'اقرأ شروط الخدمة الخاصة بنا';

  @override
  String get readOurPrivacyPolicy => 'اقرأ سياسات الخصوصية الخاصة بنا';

  @override
  String get permanentlyDeleteYourAccount => 'حذف حسابك نهائياً';

  @override
  String get getACopyOf => 'الحصول على نسخة من بياناتك';

  @override
  String get manageLoggedInDevices => 'إدارة الأجهزة المسجلة';

  @override
  String get updateYourPasswordRegularly =>
      'قم بتحديث كلمة المرور الخاصة بك بانتظام';

  @override
  String get addAnExtraLayer => 'أضف طبقة إضافية من الأمان';

  @override
  String get useFingerprintOrFace => 'استخدم بصمة الإصبع أو بصمة الوجه';

  @override
  String get biometricLogin => 'تسجيل الدخول البصمة';

  @override
  String get privacySecurity => 'الخصوصية والأمان';

  @override
  String get continueToPayment => 'استمرار للدفع';

  @override
  String get deliveryDetails => 'تفاصيل التوصيل';

  @override
  String get configureTaxSettings => 'إعدادات الضرائب';

  @override
  String get minimumPayout => 'الحد الأدنى للدفع';

  @override
  String get symbolKeyXXX => 'العربية';

  @override
  String get english => 'English';

  @override
  String get loggedOutSuccessfully => 'تم تسجيل الخروج بنجاح';

  @override
  String get appInformation => 'معلومات التطبيق';

  @override
  String get submitReport => 'إرسال التقرير';

  @override
  String get attachScreenshotsIfNeeded => 'أرفق لقطات شاشة إذا استدعى الأمر';

  @override
  String get foundABugOr => 'وجدت مشكلة أو لديك استفسار؟';

  @override
  String get reportAProblem => 'أبلغ عن مشكلة';

  @override
  String get resources => 'الموارد';

  @override
  String get getInTouchWith => 'تواصل مع فريق الدعم';

  @override
  String get orderPlacedSuccessfully => 'تم تقديم الطلب بنجاح!';

  @override
  String get creditDebitCard => 'بطاقة الائتمان / الخصم المباشر';

  @override
  String get cashOnDelivery => 'الدفع عند الاستلام';

  @override
  String get payment => 'الدفع';

  @override
  String get createYourRestaurantFirst => 'قم بإنشاء مطعمك أولاً.';

  @override
  String get notAuthenticated => 'غير مسجل.';

  @override
  String get confirmLocation => 'تأكيد الموقع';

  @override
  String get couldNotDetectLocation => 'لم يتم العثور على الموقع';

  @override
  String get ordersHistory => 'سجل الطلبات';

  @override
  String get offersPage => 'صفحة العروض';

  @override
  String get restaurantsList => 'قائمة المطاعم';

  @override
  String get speed => 'السرعة';

  @override
  String get downloadReceipt => 'تنزيل الإيصال';

  @override
  String get orderReceipt => 'إيصال الطلب';

  @override
  String get pleaseEnterYourPasswordValidation => 'يرجى إدخال كلمة المرور';

  @override
  String get passwordMinLength => 'يجب أن تكون كلمة المرور 6 أحرف على الأقل';

  @override
  String get pleaseConfirmYourPassword => 'الرجاء تأكيد كلمة المرور';

  @override
  String get bySigningUp => 'بالتسجيل، أنت توافق على شروطنا وسياسة الخصوصية';

  @override
  String get wantToPartnerWithUs => 'هل تريد الشراكة معنا؟';

  @override
  String get joinAsDriver => 'انضم كسائق';

  @override
  String get joinAsRestaurant => 'انضم كبائع';

  @override
  String get google => 'Google';

  @override
  String get phone => 'هاتف';

  @override
  String get drawerMain => 'الرئيسية';

  @override
  String get drawerEngage => 'التفاعل';

  @override
  String get drawerMore => 'المزيد';

  @override
  String get drawerDashboard => 'لوحة التحكم';

  @override
  String get drawerOrders => 'الطلبات';

  @override
  String get drawerMenu => 'القائمة';

  @override
  String get drawerAnalytics => 'التحليلات';

  @override
  String get drawerProfile => 'الملف الشخصي';

  @override
  String get drawerPromotions => 'العروض';

  @override
  String get drawerReviews => 'التقييمات';

  @override
  String get drawerSettings => 'الإعدادات';

  @override
  String get drawerDeliveryFees => 'رسوم التوصيل';

  @override
  String get drawerSupport => 'الدعم';

  @override
  String get drawerAbout => 'حول';

  @override
  String get myRestaurant => 'مطعمي';

  @override
  String get open => 'مفتوح';

  @override
  String get dashboardOverview => 'نظرة عامة على لوحة التحكم';

  @override
  String monitorPerformance(String vendorLabel) {
    return 'مراقبة أداء $vendorLabel';
  }

  @override
  String get totalRevenue => 'إجمالي الإيرادات';

  @override
  String get activeOrders => 'الطلبات النشطة';

  @override
  String get newCustomers => 'عملاء جدد';

  @override
  String get avgPrepTime => 'متوسط وقت التحضير';

  @override
  String get restaurantIsOpen => 'المطعم مفتوح';

  @override
  String get restaurantIsClosed => 'المطعم مغلق';

  @override
  String get customersCanPlaceOrders => 'يمكن للعملاء تقديم الطلبات الآن';

  @override
  String get tapToStartAcceptingOrders => 'اضغط لبدء استقبال الطلبات';

  @override
  String get revenueOverview => 'نظرة عامة على الإيرادات';

  @override
  String get vsLastWeek => 'مقارنة بالأسبوع الماضي';

  @override
  String get sameAsLastWeek => 'نفس الأسبوع الماضي';

  @override
  String get gettingFaster => 'أسرع';

  @override
  String get slower => 'أبطأ';

  @override
  String get somethingWentWrong => 'حدث خطأ ما';

  @override
  String get setUpYourRestaurant => 'إعداد مطعمك';

  @override
  String get fillInDetailsBelow =>
      'املأ التفاصيل أدناه لإنشاء مطعمك\nوابدأ في إدارة القائمة والطلبات.';

  @override
  String get restaurantName => 'اسم المطعم';

  @override
  String get descriptionOptional => 'الوصف (اختياري)';

  @override
  String get address => 'العنوان';

  @override
  String get cuisineTypesCommaSeparated => 'أنواع المأكولات (مفصولة بفاصلة)';

  @override
  String get cuisineTypesHint => 'مثال: إيطالي، بيتزا، باستا';

  @override
  String get creating => 'جاري الإنشاء...';

  @override
  String welcomeTo(String name) {
    return 'مرحباً بك في $name';
  }

  @override
  String fieldIsRequired(String field) {
    return '$field مطلوب';
  }

  @override
  String get statusPending => 'قيد الانتظار';

  @override
  String get statusAccepted => 'مقبول';

  @override
  String get statusPreparing => 'قيد التحضير';

  @override
  String get statusReady => 'جاهز';

  @override
  String get statusDriverAssigned => 'تم تعيين سائق';

  @override
  String get statusPickedUp => 'تم الاستلام';

  @override
  String get statusOnTheWay => 'في الطريق';

  @override
  String get statusDelivered => 'تم التوصيل';

  @override
  String get statusCancelled => 'ملغي';

  @override
  String get statusRefunded => 'مسترد';

  @override
  String get justNow => 'الآن';

  @override
  String minutesAgo(int count) {
    return 'منذ $count دقيقة';
  }

  @override
  String hoursAgo(int count) {
    return 'منذ $count ساعة';
  }

  @override
  String daysAgo(int count) {
    return 'منذ $count يوم';
  }

  @override
  String get dayMon => 'الإثنين';

  @override
  String get dayTue => 'الثلاثاء';

  @override
  String get dayWed => 'الأربعاء';

  @override
  String get dayThu => 'الخميس';

  @override
  String get dayFri => 'الجمعة';

  @override
  String get daySat => 'السبت';

  @override
  String get daySun => 'الأحد';

  @override
  String get failedToLoadOrders => 'فشل تحميل الطلبات';

  @override
  String allCount(int count) {
    return 'الكل ($count)';
  }

  @override
  String newCount(int count) {
    return 'جديد ($count)';
  }

  @override
  String activeCount(int count) {
    return 'نشط ($count)';
  }

  @override
  String readyCount(int count) {
    return 'جاهز ($count)';
  }

  @override
  String get order => 'طلب';

  @override
  String get cash => 'نقدي';

  @override
  String get driverAssignedAwaitingPickup =>
      'تم تعيين سائق — في انتظار الاستلام';

  @override
  String get readyAssignDriver => 'جاهز — قم بتعيين سائق';

  @override
  String manageDriversCount(int count) {
    return 'إدارة السائقين ($count معين)';
  }

  @override
  String get itemsNotAvailable => 'العناصر غير متاحة';

  @override
  String get tooBusy => 'مشغول جداً';

  @override
  String get closingSoon => 'سيتم الإغلاق قريباً';

  @override
  String get duplicateOrder => 'طلب مكرر';

  @override
  String get other => 'أخرى';

  @override
  String assignedDriversCount(int count) {
    return 'السائقون المعينون ($count)';
  }

  @override
  String reason(String reason) {
    return 'السبب: $reason';
  }

  @override
  String get statusRejected => 'مرفوض';

  @override
  String get notAuthenticatedTitle => 'غير مسجل الدخول';

  @override
  String get pleaseLogInToViewProfile => 'يرجى تسجيل الدخول لعرض ملفك الشخصي.';

  @override
  String get noRestaurantProfileYet => 'لا يوجد ملف مطعم بعد';

  @override
  String get createRestaurantFromDashboard =>
      'أنشئ مطعمك من لوحة التحكم\nلبدء إدارة ملفك الشخصي هنا.';

  @override
  String get businessInformation => 'معلومات العمل';

  @override
  String get arabicName => 'الاسم بالعربية';

  @override
  String get notSet => 'غير محدد';

  @override
  String get location => 'الموقع';

  @override
  String get deliverySettings => 'إعدادات التوصيل';

  @override
  String get deliveryTime => 'وقت التوصيل';

  @override
  String get minimumOrder => 'الحد الأدنى للطلب';

  @override
  String deliveryRadius(String km) {
    return '$km كم';
  }

  @override
  String get feeMode => 'نوع الرسوم';

  @override
  String get ratingsAndStats => 'التقييمات والإحصائيات';

  @override
  String get noRatingsYet => 'لا توجد تقييمات بعد';

  @override
  String get totalReviews => 'إجمالي المراجعات';

  @override
  String get memberSince => 'عضو منذ';

  @override
  String get lastUpdated => 'آخر تحديث';

  @override
  String get currentlyOpen => 'مفتوح حالياً';

  @override
  String get currentlyClosed => 'مغلق حالياً';

  @override
  String get customersCanOrderFromRestaurant => 'يمكن للعملاء الطلب من مطعمك';

  @override
  String get restaurantNotAcceptingOrders => 'مطعمك لا يستقبل طلبات';

  @override
  String get wait => 'انتظر';

  @override
  String get gps => 'نظام تحديد المواقع';

  @override
  String get monday => 'الإثنين';

  @override
  String get tuesday => 'الثلاثاء';

  @override
  String get wednesday => 'الأربعاء';

  @override
  String get thursday => 'الخميس';

  @override
  String get friday => 'الجمعة';

  @override
  String get saturday => 'السبت';

  @override
  String get sunday => 'الأحد';

  @override
  String get noHoursSet => 'لم يتم تحديد ساعات';

  @override
  String get editOperatingHours => 'تعديل ساعات العمل';

  @override
  String get operatingHoursSaved => 'تم حفظ ساعات العمل';

  @override
  String failed(String error) {
    return 'فشل: $error';
  }

  @override
  String get totalOrders => 'إجمالي الطلبات';

  @override
  String get completionRate => 'معدل الإتمام';

  @override
  String get avgOrderValue => 'متوسط قيمة الطلب';

  @override
  String get revenueTrend => 'اتجاه الإيرادات';

  @override
  String get orderVolume => 'حجم الطلبات';

  @override
  String get topSellingItems => 'المنتجات الأكثر مبيعاً';

  @override
  String get noItemDataAvailable => 'لا توجد بيانات منتجات';

  @override
  String get peakHours => 'ساعات الذروة';

  @override
  String get noHourlyDataAvailable => 'لا توجد بيانات بالساعة';

  @override
  String get today => 'اليوم';

  @override
  String get thisMonth => 'هذا الشهر';

  @override
  String get lastMonth => 'الشهر الماضي';

  @override
  String get custom => 'مخصص';

  @override
  String get noDataForThisPeriod => 'لا توجد بيانات لهذه الفترة';

  @override
  String get delivered => 'تم التسليم';

  @override
  String get cancelled => 'ملغي';

  @override
  String get refunded => 'مسترد';

  @override
  String get customerInsights => 'إحصائيات العملاء';

  @override
  String get totalCustomers => 'إجمالي العملاء';

  @override
  String get new_ => 'جديد';

  @override
  String get returning => 'العملاء العائدون';

  @override
  String get unknownError => 'خطأ غير معروف';

  @override
  String get createYourRestaurant => 'أنشئ مطعمك';

  @override
  String get setUpRestaurantProfile =>
      'أنشئ ملف مطعمك لبدء إدارة القائمة والطلبات.';

  @override
  String get settingsPreferences => 'التفضيلات';

  @override
  String get manageSettingsSubtitle =>
      'إدارة الإشعارات والدفع وتفضيلات الحساب.';

  @override
  String get notificationsTitle => 'الإشعارات';

  @override
  String get configureAlerts => 'إعداد كيفية تلقي التنبيهات.';

  @override
  String get newOrderAlert => 'تنبيه طلب جديد';

  @override
  String get showNotificationForNewOrders => 'عرض إشعار للطلبات الجديدة';

  @override
  String get emailNotifications => 'إشعارات البريد الإلكتروني';

  @override
  String get receiveEmailUpdates => 'تلقي تحديثات عبر البريد الإلكتروني';

  @override
  String get autoAcceptOrders => 'قبول الطلبات تلقائياً';

  @override
  String get automaticallyAcceptOrders => 'قبول الطلبات الواردة تلقائياً';

  @override
  String get restaurantNameRequired => 'اسم المطعم *';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get restaurantCreatedSuccessfully => 'تم إنشاء المطعم بنجاح!';

  @override
  String failedToCreateRestaurant(String error) {
    return 'فشل إنشاء المطعم: $error';
  }

  @override
  String get promotionsTitle => 'العروض';

  @override
  String get promotionsSubtitle =>
      'قم بإنشاء وإدارة العروض الترويجية لجذب المزيد من العملاء.';

  @override
  String get discountCodes => 'أكواد الخصم';

  @override
  String get discountCodesDesc => 'أنشئ أكواد خصم بنسبة مئوية أو مبلغ ثابت';

  @override
  String get specialOffers => 'عروض خاصة';

  @override
  String get specialOffersDesc =>
      'أنشئ عروض اشترِ واحد واحصل على الثاني، وعروض كومبو، والمزيد';

  @override
  String get scheduledPromotions => 'عروض ترويجية مجدولة';

  @override
  String get scheduledPromotionsDesc => 'خطط للعروض في المناسبات وأوقات الذروة';

  @override
  String get performanceTracking => 'تتبع الأداء';

  @override
  String get performanceTrackingDesc => 'شاهد أداء عروضك';

  @override
  String get reviewsTitle => 'التقييمات';

  @override
  String get reviewsSubtitle => 'شاهد ما يقوله عملاؤك عن مطعمك.';

  @override
  String get customerFeedback => 'ملاحظات العملاء';

  @override
  String get customerFeedbackDesc => 'اقرأ ورد على مراجعات العملاء';

  @override
  String get ratingBreakdown => 'تفاصيل التقييم';

  @override
  String get ratingBreakdownDesc => 'تفصيل مفصل لتقييماتك حسب الفئة';

  @override
  String get sentimentTrends => 'اتجاهات المشاعر';

  @override
  String get sentimentTrendsDesc => 'تابع كيف تتغير تقييماتك بمرور الوقت';

  @override
  String get replyToReviews => 'الرد على المراجعات';

  @override
  String soldCount(int count) {
    return '$count مباع';
  }

  @override
  String get setUpRestaurantProfilePrompt =>
      'قم بإعداد ملف تعريف مطعمك لبدء إدارة القائمة والطلبات.';

  @override
  String get configureAlertsSubtitle => 'تكوين كيفية تلقي التنبيهات.';

  @override
  String get newOrderAlertDescription => 'إظهار إشعار للطلبات الجديدة';

  @override
  String get emailNotificationsDescription => 'تلقي تحديثات البريد الإلكتروني';

  @override
  String get autoAcceptOrdersDescription => 'قبول الطلبات الواردة تلقائياً';

  @override
  String get restaurantNameAsterisk => 'اسم المطعم *';

  @override
  String get discountCodesDescription =>
      'قم بإنشاء أكواد خصم بنسبة مئوية أو بمبلغ ثابت';

  @override
  String get specialOffersDescription =>
      'قم بإعداد عروض اشترِ واحداً واحصل على الآخر مجاناً، وعروض الوجبات، والمزيد';

  @override
  String get scheduledPromotionsDescription =>
      'خطط للعروض الترويجية للعطلات وساعات الذروة';

  @override
  String get performanceTrackingDescription =>
      'شاهد كيف كان أداء عروضك الترويجية';

  @override
  String get customerFeedbackDescription => 'اقرأ مراجعات العملاء ورد عليها';

  @override
  String get ratingBreakdownDescription => 'تفاصيل دقيقة لتقييماتك حسب الفئة';

  @override
  String get sentimentTrendsDescription =>
      'تتبع كيف تتغير تقييماتك بمرور الوقت';

  @override
  String get replyToReviewsDescription =>
      'تواصل مع العملاء من خلال الرد على ملاحظاتهم';

  @override
  String get howCanWeHelp => 'كيف يمكننا مساعدتك؟';

  @override
  String get supportTeamAssist => 'فريق الدعم لدينا هنا لمساعدتك.';

  @override
  String get liveChatAvailability => 'متاح من 9 صباحاً حتى 9 مساءً';

  @override
  String get faqQuestion1 => 'كيف يمكنني تحديث قائمتي؟';

  @override
  String get faqAnswer1 =>
      'انتقل إلى صفحة القائمة من الشريط الجانبي. يمكنك إضافة أو تعديل أو إزالة العناصر والأقسام. تنعكس التغييرات للعملاء في الوقت الفعلي.';

  @override
  String get faqQuestion2 => 'كيف يمكنني تغيير ساعات العمل الخاصة بي؟';

  @override
  String get faqAnswer2 =>
      'انتقل إلى صفحة الملف الشخصي وانتقل إلى قسم ساعات العمل. اضغط على أيقونة التعديل بجوار أي يوم لتحديث ساعاتك.';

  @override
  String get faqQuestion3 => 'كيف يتم حساب رسوم التوصيل؟';

  @override
  String get faqAnswer3 =>
      'انتقل إلى رسوم التوصيل في الشريط الجانبي. يمكنك تحديد رسوم ثابتة أو تسعير يعتمد على المسافة مع فئات.';

  @override
  String get faqQuestion4 => 'كيف أتعامل مع طلب مرفوض؟';

  @override
  String get faqAnswer4 =>
      'عندما ترفض طلباً، حدد سبباً. سيتم إخطار العميل واسترداد المبلغ تلقائياً.';

  @override
  String get faqQuestion5 => 'كيف يمكنني الاتصال بالسائق؟';

  @override
  String get faqAnswer5 =>
      'في صفحة الطلبات، تظهر الطلبات المخصصة اسم السائق ورقم هاتفه. اضغط للاتصال مباشرة.';

  @override
  String get aboutZSpeed => 'عن Z Speed';

  @override
  String get aboutZSpeedDescription =>
      'Z Speed هي منصة توصيل سريعة وموثوقة تربط المطاعم بالعملاء في جميع أنحاء مصر. نحن نمكن أصحاب المطاعم بأدوات حديثة لإدارة أعمالهم بكفاءة.';

  @override
  String get openSourceLicenses => 'تراخيص المصدر المفتوح';

  @override
  String get copyright => '© 2026 Z Speed. جميع الحقوق محفوظة.';

  @override
  String get whatsPlanned => 'ما هو مخطط له:';

  @override
  String editField(String field) {
    return 'تعديل $field';
  }

  @override
  String enterField(String field) {
    return 'أدخل $field';
  }

  @override
  String fieldUpdatedSuccessfully(String field) {
    return 'تم تحديث $field بنجاح';
  }

  @override
  String editDayHours(String day) {
    return 'تعديل ساعات يوم $day';
  }

  @override
  String dayHoursUpdated(String day) {
    return 'تم تحديث ساعات يوم $day';
  }

  @override
  String get selectBothTimes => 'يرجى اختيار وقتي الفتح والإغلاق';

  @override
  String get logoChangedFromGallery => 'تم تغيير الشعار من المعرض';

  @override
  String get logoChangedFromCamera => 'تم تغيير الشعار من الكاميرا';

  @override
  String orderWithId(String id) {
    return 'طلب رقم $id';
  }

  @override
  String get deleteItem => 'حذف العنصر';

  @override
  String confirmDeleteItem(String name) {
    return 'هل أنت متأكد أنك تريد حذف \'$name\'؟';
  }

  @override
  String currencyEgp(String amount) {
    return '$amount ج.م';
  }

  @override
  String get outOfStock => 'نفد من المخزن';

  @override
  String stockCount(int count) {
    return 'المخزون: $count';
  }

  @override
  String get preview => 'معاينة';

  @override
  String failedToPickImage(String error) {
    return 'فشل في اختيار الصورة: $error';
  }

  @override
  String get pleaseSelectCuisineType => 'يرجى اختيار نوع المطبخ';

  @override
  String get englishNameRequired => 'الاسم بالإنجليزية مطلوب';

  @override
  String get arabicNameRequired => 'الاسم بالعربية مطلوب';

  @override
  String get englishDescriptionRequired => 'الوصف بالإنجليزية مطلوب';

  @override
  String get arabicDescriptionRequired => 'الوصف بالعربية مطلوب';

  @override
  String get priceRequired => 'السعر مطلوب';

  @override
  String get invalidPrice => 'السعر غير صالح';

  @override
  String get salePriceError => 'يجب أن يكون سعر العرض أقل من السعر العادي';

  @override
  String get pleaseUploadImage => 'يرجى تحميل صورة لهذا الصنف';

  @override
  String get failedToUploadImage => 'فشل تحميل الصورة';

  @override
  String get itemCreated => 'تم إنشاء الصنف';

  @override
  String get itemUpdated => 'تم تحديث الصنف';

  @override
  String failedToSaveItem(String error) {
    return 'فشل حفظ الصنف: $error';
  }

  @override
  String get addMenuItem => 'إضافة صنف منيو';

  @override
  String get editMenuItem => 'تعديل صنف منيو';

  @override
  String get cuisineTypeRequired => 'نوع المطبخ *';

  @override
  String get itemImageRequired => 'صورة الصنف *';

  @override
  String get itemNameEnglishRequired => 'اسم الصنف (إنجليزية) *';

  @override
  String get itemNameEnglishHint => 'مثال: Grilled Chicken';

  @override
  String get itemNameArabicRequired => 'اسم الصنف (عربية) *';

  @override
  String get itemNameArabicHint => 'مثال: دجاج مشوي';

  @override
  String get descriptionEnglishRequired => 'الوصف (إنجليزية) *';

  @override
  String get descriptionEnglishHint => 'وصف مختصر للصنف';

  @override
  String get descriptionArabicRequired => 'الوصف (عربية) *';

  @override
  String get descriptionArabicHint => 'وصف مختصر للصنف';

  @override
  String get priceEgpRequired => 'السعر (ج.م) *';

  @override
  String get salePriceEgp => 'سعر العرض (ج.م)';

  @override
  String get unavailable => 'غير متاح';

  @override
  String get createItem => 'إنشاء صنف';

  @override
  String get tapToUploadImage => 'اضغط لتحميل صورة';

  @override
  String get imageRequirements => 'مطلوب • JPG أو PNG';

  @override
  String get noAddonGroupsYet => 'لا توجد مجموعات إضافات بعد';

  @override
  String get addGroupPrompt =>
      'أضف مجموعات مثل \"اختر الحجم\" أو \"إضافات إضافية\"';

  @override
  String optionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count خيارات',
      two: 'خياران',
      one: 'خيار واحد',
      zero: 'لا توجد خيارات',
    );
    return '$_temp0';
  }

  @override
  String get editGroup => 'تعديل المجموعة';

  @override
  String get noOptionsYet => 'لا توجد خيارات بعد';

  @override
  String get defaultLabel => 'افتراضي';

  @override
  String extraPriceEgp(String price) {
    return '+ $price ج.م';
  }

  @override
  String get editOption => 'تعديل الخيار';

  @override
  String get addAddonGroup => 'إضافة مجموعة إضافات';

  @override
  String get editAddonGroup => 'تعديل مجموعة إضافات';

  @override
  String get groupNameRequired => 'اسم المجموعة *';

  @override
  String get groupNameHint => 'مثال: اختر الحجم';

  @override
  String get arabicNameOptional => 'الاسم بالعربية (اختياري)';

  @override
  String get arabicNameHint => 'مثال: اختر الحجم';

  @override
  String get minSelections => 'الحد الأدنى للاختيارات';

  @override
  String get maxSelections => 'الحد الأقصى للاختيارات';

  @override
  String failedToSaveGroup(String error) {
    return 'فشل حفظ المجموعة: $error';
  }

  @override
  String get update => 'تحديث';

  @override
  String get addOptionLabel => 'إضافة خيار';

  @override
  String get editOptionLabel => 'تعديل الخيار';

  @override
  String get optionNameRequired => 'اسم الخيار *';

  @override
  String get optionNameHint => 'مثال: كبير';

  @override
  String get extraPriceEgpLabel => 'سعر إضافي (ج.م)';

  @override
  String get optionAdded => 'تم إضافة الخيار';

  @override
  String get optionUpdated => 'تم تحديث الخيار';

  @override
  String failedToSaveOption(String error) {
    return 'فشل حفظ الخيار: $error';
  }

  @override
  String confirmDeleteGroup(String name) {
    return 'هل أنت متأكد أنك تريد حذف مجموعة \'$name\'؟';
  }

  @override
  String confirmDeleteGroupWarning(int count) {
    return 'سيؤدي هذا إلى إزالة جميع الخيارات ($count) في هذه المجموعة.';
  }

  @override
  String failedToDeleteGroup(String error) {
    return 'فشل حذف المجموعة: $error';
  }

  @override
  String confirmDeleteOption(String name) {
    return 'هل أنت متأكد أنك تريد حذف خيار \'$name\'؟';
  }

  @override
  String failedToDeleteOption(String error) {
    return 'فشل حذف الخيار: $error';
  }

  @override
  String andMoreItems(String mainItem, int count) {
    return '$mainItem + $count أخرى';
  }

  @override
  String headingTo(String name) {
    return 'متجه إلى $name';
  }

  @override
  String eta(Object time) {
    return 'الوقت المقدر: $time';
  }

  @override
  String get distance => 'المسافة';

  @override
  String minutesCount(int count) {
    return '$count دقيقة';
  }

  @override
  String get creatingAccount => 'جاري إنشاء حسابك...';

  @override
  String get uploadingDocuments => 'جاري رفع المستندات...';

  @override
  String get uploadingBranding => 'جاري رفع صور العلامة التجارية...';

  @override
  String get savingApplication => 'جاري حفظ طلبك...';

  @override
  String get applicationSubmittedSubtitle =>
      'تم تقديم طلب مطعمك بنجاح. سنراجع طلبك ونخطرك في غضون 1-3 أيام عمل.';

  @override
  String stepProgress(int current, int total, String label) {
    return 'الخطوة $current من $total: $label';
  }

  @override
  String get accountSetupSubtitle =>
      'تحقق من بريدك الإلكتروني ورقم هاتفك للبدء.';

  @override
  String get submitting => 'جاري التقديم...';

  @override
  String get businessInfoStep => 'معلومات العمل';

  @override
  String get locationAndHoursStep => 'الموقع وساعات العمل';

  @override
  String get documentsStep => 'المستندات';

  @override
  String get brandingStep => 'العلامة التجارية';

  @override
  String get bankInfoStep => 'معلومات البنك';

  @override
  String get reviewStep => 'مراجعة';

  @override
  String get completedOrders => 'الطلبات المكتملة';

  @override
  String get cancelledOrders => 'الطلبات الملغاة';

  @override
  String get searchOrdersHint => 'البحث برقم الطلب أو العميل...';

  @override
  String get allOrders => 'كل الطلبات';

  @override
  String ordersFound(int count) {
    return 'تم العثور على $count طلب';
  }

  @override
  String get configureDeliveryFees => 'تكوين كيفية حساب رسوم التوصيل لطلباتك';

  @override
  String get deliveryFeeMode => 'وضع رسوم التوصيل';

  @override
  String get fixedDeliveryFee => 'رسوم توصيل ثابتة';

  @override
  String get distanceBasedFeeLabel => 'رسوم على أساس المسافة';

  @override
  String get subMode => 'الوضع الفرعي';

  @override
  String get pricingTiers => 'شرائح التسعير';

  @override
  String get noTiersConfigured => 'لا توجد شرائح مكونة. أضف شريحة للبدء.';

  @override
  String tierWithNumber(int number) {
    return 'الشريحة $number';
  }

  @override
  String get minKm => 'الحد الأدنى (كم)';

  @override
  String get maxKm => 'الحد الأقصى (كم)';

  @override
  String get feeEgp => 'الرسوم (ج.م)';

  @override
  String get fixedFeeEgp => 'رسوم ثابتة (ج.م)';

  @override
  String get baseFeeEgp => 'الرسوم الأساسية (ج.م)';

  @override
  String get perKmRateEgp => 'سعر الكيلومتر (ج.م)';

  @override
  String get maxDeliveryDistanceKm => 'أقصى مسافة توصيل (كم)';

  @override
  String get fixedFeeDescription =>
      'سيتم تحصيل هذه الرسوم لجميع الطلبات بغض النظر عن المسافة';

  @override
  String get radiusDescription => 'سيتم رفض الطلبات التي تتجاوز هذه المسافة';

  @override
  String get formulaDescription =>
      'الصيغة: الرسوم الأساسية + (المسافة × سعر الكيلومتر)';

  @override
  String get invalidBaseFee => 'يرجى إدخال رسوم أساسية صالحة';

  @override
  String get invalidRadius => 'يرجى إدخال نصف قطر توصيل صالح';

  @override
  String get invalidPerKmRate => 'يرجى إدخال سعر صالح للكيلومتر';

  @override
  String get addAtLeastOneTier => 'يرجى إضافة شريحة تسعير واحدة على الأقل';

  @override
  String get unsavedChangesDescription =>
      'لديك تغييرات غير محفوظة. هل أنت متأكد أنك تريد العودة؟';

  @override
  String get reviewYourApplication => 'مراجعة طلبك';

  @override
  String get reviewInstructions =>
      'يرجى مراجعة كافة المعلومات بعناية قبل التقديم. يمكنك الضغط على \"تعديل\" للعودة وإجراء التغييرات.';

  @override
  String get accountAndContact => 'الحساب وجهات الاتصال';

  @override
  String get notUploaded => 'لم يتم الرفع';

  @override
  String get reviewDisclaimer =>
      'بتقديم هذا الطلب، فإنك تؤكد أن جميع المعلومات المقدمة دقيقة. ستتم مراجعة طلبك خلال 1-3 أيام عمل.';

  @override
  String get notConfigured => 'غير مكون';

  @override
  String get tapToChange => 'اضغط للتغيير';

  @override
  String get am => 'ص';

  @override
  String get pm => 'م';

  @override
  String get descriptionPlaceholder => 'الوصف';

  @override
  String deliveryTimeRange(int min, int max) {
    return '$min – $max دقيقة';
  }

  @override
  String timeRange(String open, String close) {
    return '$open – $close';
  }

  @override
  String failedWithMessage(String error) {
    return 'فشل: $error';
  }

  @override
  String error(String error) {
    return 'خطأ: $error';
  }

  @override
  String get egyptian => 'مصري';

  @override
  String get lebanese => 'لبناني';

  @override
  String get syrian => 'سوري';

  @override
  String get italian => 'إيطالي';

  @override
  String get fastFood => 'وجبات سريعة';

  @override
  String get seafood => 'مأكولات بحرية';

  @override
  String get grills => 'مشويات';

  @override
  String get desserts => 'حلويات';

  @override
  String get beverages => 'مشروبات';

  @override
  String get healthy => 'صحي';

  @override
  String get indian => 'هندي';

  @override
  String get turkish => 'تركي';

  @override
  String get chinese => 'صيني';

  @override
  String get japanese => 'ياباني';

  @override
  String get mexican => 'مكسيكي';

  @override
  String get setHours => 'حدد الساعات';

  @override
  String get businessDocuments => 'مستندات العمل';

  @override
  String get provideBusinessDocs =>
      'قم بتحميل المستندات القانونية المطلوبة لمطعمك.';

  @override
  String get commercialRegistration => 'السجل التجاري';

  @override
  String get commercialRegistrationDesc => 'مستند تسجيل العمل الرسمي';

  @override
  String get businessLicense => 'رخصة العمل';

  @override
  String get businessLicenseDesc => 'رخصة تشغيل عمل/مطعم سارية';

  @override
  String get healthCertificate => 'الشهادة الصحية';

  @override
  String get healthCertificateDesc => 'شهادة فحص الصحة والسلامة';

  @override
  String get taxRegistration => 'التسجيل الضريبي';

  @override
  String get taxRegistrationDesc => 'بطاقة أو شهادة التسجيل الضريبي';

  @override
  String get restaurantBranding => 'العلامة التجارية للمطعم';

  @override
  String get uploadLogoCover =>
      'قم بتحميل شعار مطعمك وصورة غلاف. سيتم عرضها للعملاء.';

  @override
  String get squareImageRecommended =>
      'يوصى بتقديم صورة مربعة (مثلاً 512×512).';

  @override
  String get tapToUploadLogo => 'اضغط لتحميل الشعار';

  @override
  String get coverPhoto => 'صورة الغلاف';

  @override
  String get wideImageRecommended => 'يوصى بتقديم صورة عريضة (مثلاً 1200×600).';

  @override
  String get tapToUploadCover => 'اضغط لتحميل صورة الغلاف';

  @override
  String get imagesRequiredToProceed => 'يجب تحميل كلتا الصورتين للمتابعة.';

  @override
  String get bankAccountDetails => 'تفاصيل الحساب البنكي';

  @override
  String get payoutInfoDesc => 'قدم معلومات حسابك البنكي لتلقي المدفوعات.';

  @override
  String get bankName => 'اسم البنك';

  @override
  String get bankNameHint => 'مثال: CIB، QNB، NBE...';

  @override
  String get bankNameRequired => 'اسم البنك مطلوب';

  @override
  String get accountHolderName => 'اسم صاحب الحساب';

  @override
  String get accountHolderNameHint => 'الاسم كما يظهر في السجلات البنكية';

  @override
  String get accountHolderNameRequired => 'اسم صاحب الحساب مطلوب';

  @override
  String get accountNumberIban => 'رقم الحساب / IBAN';

  @override
  String get accountNumberIbanHint => 'أدخل رقم الـ IBAN الكامل أو رقم الحساب';

  @override
  String get accountNumberIbanRequired => 'رقم الحساب أو الـ IBAN مطلوب';

  @override
  String get branchNameOptional => 'اسم الفرع (اختياري)';

  @override
  String get branchNameHint => 'مثال: المعادي، الزمالك...';

  @override
  String get bankSecurityNote => 'ملاحظة أمنية';

  @override
  String get bankSecurityDesc =>
      'يتم الاحتفاظ بتفاصيل البنك الخاصة بك آمنة ومشفرة.';

  @override
  String get iban => 'رقم الـ IBAN';

  @override
  String get ibanHint => 'EG XX XXXX XXXX XXXX XXXX XXXX';

  @override
  String get ibanRequired => 'رقم الـ IBAN مطلوب';

  @override
  String get ibanMustStartWithEG => 'يجب أن يبدأ رقم الـ IBAN بـ EG';

  @override
  String ibanLengthValidation(int length) {
    return 'يجب أن يتكون رقم الآيبان من 15 إلى 34 حرفًا (الحالي: $length)';
  }

  @override
  String get driverPersonalInfo => 'المعلومات الشخصية للسائق';

  @override
  String get provideBasicDetails => 'قدم تفاصيلك الأساسية';

  @override
  String get fullName => 'الاسم الكامل';

  @override
  String get enterFullName => 'أدخل اسمك الكامل';

  @override
  String get nameAlphaOnly => 'يجب أن يحتوي الاسم على أحرف فقط';

  @override
  String get dateOfBirth => 'تاريخ الميلاد';

  @override
  String get nationalId => 'البطاقة الوطنية';

  @override
  String get nationalIdNumber => 'الرقم القومي';

  @override
  String get nationalIdRequired => 'الرقم القومي مطلوب';

  @override
  String get nationalIdLength => 'يجب أن يكون الرقم القومي 14 رقمًا';

  @override
  String get nationalIdDesc => 'الجهة الأمامية والخلفية لبطاقتك الوطنية';

  @override
  String get driversLicense => 'رخصة القيادة';

  @override
  String get driversLicenseDesc => 'رخصة قيادة سارية';

  @override
  String get vehicleRegistration => 'تسجيل المركبة';

  @override
  String get vehicleRegistrationDesc => 'تسجيل مركبة ساري';

  @override
  String get vehicleInsurance => 'تأمين المركبة';

  @override
  String get vehicleInsuranceDesc => 'تأمين مركبة ساري';

  @override
  String get policeClearance => 'فيش جنائي';

  @override
  String get policeClearanceDesc => 'فيش جنائي حديث (صحيفة حالة جنائية)';

  @override
  String get facePhoto => 'صورة شخصية';

  @override
  String get facePhotoDesc => 'صورة واضحة لوجهك';

  @override
  String get vehiclePhoto => 'صورة المركبة';

  @override
  String get vehiclePhotoDesc => 'صورة واضحة لمركبتك';

  @override
  String get requiredDocuments => 'المستندات المطلوبة';

  @override
  String get uploadClearPhotos =>
      'قم برفع صور واضحة أو مقروءة للمستندات المطلوبة';

  @override
  String tapToUploadDoc(String doc) {
    return 'اضغط لرفع $doc';
  }

  @override
  String get uploaded => 'تم الرفع';

  @override
  String get vehicleInfo => 'معلومات المركبة';

  @override
  String get provideVehicleDetails => 'قدم تفاصيل حول مركبتك';

  @override
  String get vehicleType => 'نوع المركبة';

  @override
  String get car => 'سيارة';

  @override
  String get motorcycle => 'دراجة نارية';

  @override
  String get cycle => 'دراجة هوائية';

  @override
  String get cycleType => 'نوع الدراجة الهوائية';

  @override
  String get normalCycle => 'دراجة عادية';

  @override
  String get electronicCycle => 'دراجة كهربائية';

  @override
  String get selectCycleType => 'اختر نوع الدراجة';

  @override
  String get make => 'الماركة';

  @override
  String get makeRequired => 'الماركة مطلوبة';

  @override
  String get specifyMake => 'حدد الماركة';

  @override
  String get enterBrandManually => 'أدخل العلامة التجارية يدوياً';

  @override
  String get model => 'الموديل';

  @override
  String get corollaCivic => 'مثال: كورولا، سيفيك';

  @override
  String get modelRequired => 'الموديل مطلوب';

  @override
  String get year => 'السنة';

  @override
  String get yearRequired => 'السنة مطلوبة';

  @override
  String get invalidYear => 'سنة غير صالحة';

  @override
  String get exactColor => 'اللون الدقيق';

  @override
  String get matteBlack => 'مثال: أسود مطفي';

  @override
  String get colorRequired => 'اللون مطلوب';

  @override
  String get ownerFullName => 'الاسم الكامل للمالك';

  @override
  String get restaurantPhone => 'هاتف المطعم';

  @override
  String vendorNameLabel(String vendorType) {
    return 'اسم $vendorType';
  }

  @override
  String vendorNameHint(String vendorType) {
    return 'أدخل اسم $vendorType';
  }

  @override
  String vendorNameRequired(String vendorType) {
    return 'اسم $vendorType مطلوب';
  }

  @override
  String vendorPhoneLabel(String vendorType) {
    return 'هاتف $vendorType';
  }

  @override
  String vendorPhoneHint(String vendorType) {
    return 'أدخل هاتف $vendorType';
  }

  @override
  String vendorPhoneRequired(String vendorType) {
    return 'هاتف $vendorType مطلوب';
  }

  @override
  String vendorBrandingTitle(String vendorType) {
    return 'هوية $vendorType';
  }

  @override
  String vendorLogoLabel(String vendorType) {
    return 'شعار $vendorType';
  }

  @override
  String get noCuisinesAvailable => 'لا توجد أنواع مطبخ متاحة';

  @override
  String get contactInfoTitle => 'معلومات التواصل';

  @override
  String get contactInfoSubtitle => 'أدخل بيانات التواصل لصاحب العمل والمطعم.';

  @override
  String get ownerEmail => 'البريد الإلكتروني للمالك';

  @override
  String get ownerEmailHint => 'your.email@example.com';

  @override
  String get ownerPhone => 'هاتف المالك';

  @override
  String get ownerPhoneHint => '+20 1XX XXX XXXX';

  @override
  String get contactRestaurantPhoneHint => 'رقم الهاتف الظاهر للعملاء';

  @override
  String get contactRestaurantPhoneRequired => 'هاتف المطعم مطلوب';

  @override
  String get fullAddress => 'العنوان الكامل';

  @override
  String get city => 'المدينة';

  @override
  String get newSection => 'قسم جديد';

  @override
  String get enterSectionName => 'أدخل اسم القسم';

  @override
  String get addNewSection => 'إضافة قسم جديد';

  @override
  String get active => 'نشط';

  @override
  String get onSale => 'تخفيض';

  @override
  String get tapAddItemToCreate =>
      'اضغط على \'إضافة صنف\' لإنشاء أول صنف في القائمة';

  @override
  String get failedToDeleteItem => 'فشل حذف الصنف';

  @override
  String get accountSetup => 'إعداد الحساب';

  @override
  String get fillDetailsToGetStarted => 'املأ تفاصيلك للبدء';

  @override
  String get applicationSubmittedSuccess => 'تم تقديم طلبك بنجاح!';

  @override
  String get enterCity => 'أدخل المدينة';

  @override
  String get businessInfo => 'معلومات العمل';

  @override
  String get provideBusinessDetails => 'قدم تفاصيل عملك';

  @override
  String get enterRestaurantName => 'أدخل اسم المطعم';

  @override
  String get enterDescription => 'أدخل الوصف';

  @override
  String get enterOwnerName => 'أدخل اسم المالك';

  @override
  String get selectCuisinesPrompt => 'اختر نوع مطبخ واحد على الأقل';

  @override
  String get selectAtLeastOneCuisine => 'الرجاء اختيار نوع مطبخ واحد على الأقل';

  @override
  String get enterRestaurantPhone => 'أدخل هاتف المطعم';

  @override
  String get phoneHint => 'مثال: 01012345678';

  @override
  String get whereIsRestaurant => 'أين يقع مطعمك؟';

  @override
  String get streetBuildingFloor => 'الشارع ، المبنى ، الطابق';

  @override
  String get addressRequired => 'العنوان مطلوب';

  @override
  String get cityRequired => 'المدينة مطلوبة';

  @override
  String get pinpointLocation => 'تحديد الموقع الدقيق';

  @override
  String get locationNotSet => 'لم يتم تحديد الموقع';

  @override
  String get setOpeningClosingTimes => 'تعيين أوقات הפتح والإغلاق';

  @override
  String get noRestaurantFound => 'لم يتم العثور على مطعم';

  @override
  String get completeRestaurantSetup => 'يرجى إكمال إعداد ملف تعريف مطعمك';

  @override
  String get searchMenuItems => 'ابحث في عناصر القائمة…';

  @override
  String get totalItems => 'إجمالي الأصناف';

  @override
  String get tapToUploadCoverImage => 'اضغط لرفع صورة الغلاف';

  @override
  String get optional => 'اختياري';

  @override
  String get deliveryRadiusLabel => 'نطاق التوصيل';

  @override
  String updated(String item) {
    return 'تم تحديث $item بنجاح';
  }

  @override
  String get statusClosed => 'مغلق';

  @override
  String get branding => 'العلامة التجارية';

  @override
  String get uploading => 'جاري الرفع...';

  @override
  String get tapToUpload => 'اضغط للرفع';

  @override
  String get uploadedDocuments => 'المستندات المرفوعة';

  @override
  String documentWithIndex(String index) {
    return 'مستند $index';
  }

  @override
  String get phoneNumber => 'رقم الهاتف';

  @override
  String get currencySymbol => 'ج.م';

  @override
  String get promotions => 'العروض';

  @override
  String get reviews => 'التقييمات';

  @override
  String get contactUs => 'اتصل بنا';

  @override
  String get restaurantDashboard => 'لوحة تحكم المطعم';

  @override
  String get paymentCash => 'نقدًا';

  @override
  String get paymentCard => 'بطاقة التقدمة';

  @override
  String get paymentWallet => 'محفظة';

  @override
  String get statusCompleted => 'مكتمل';

  @override
  String get statusFailed => 'فشل';

  @override
  String get statusActive => 'نشط';

  @override
  String get statusSuspended => 'موقوف';

  @override
  String get protectYourAccountWithAnExtraLayerOfSecurity =>
      'Protect your account with an extra layer of security.';

  @override
  String get yourDataWillBePreparedAndSentToYourEmail =>
      'Your data will be prepared and sent to your email.';

  @override
  String get accountDeletionScheduledYouWillReceiveAConfirmatio =>
      'Account deletion scheduled. You will receive a confirmation email.';

  @override
  String get loadMore => 'Load More';

  @override
  String get locationUpdatedSuccessfully => 'Location updated successfully';

  @override
  String get editPaymentMethodFunctionalityWillBeImplementedHer =>
      'سيتم تطبيق وظيفة تعديل طريقة الدفع هنا.';

  @override
  String egpAmount(String amount) {
    return 'ج.م $amount';
  }

  @override
  String reportedOnDate(String date) {
    return 'تم الإبلاغ في $date';
  }

  @override
  String disputeId(String id) {
    return 'نزاع - $id';
  }

  @override
  String disputeStatusUpdated(String id, String status) {
    return 'تم تحديث حالة النزاع $id إلى $status';
  }

  @override
  String allDisputesCount(int count) {
    return 'جميع النزاعات ($count)';
  }

  @override
  String userStatusUpdated(String id, String status) {
    return 'تم تحديث حالة المستخدم $id إلى $status';
  }

  @override
  String downloadingReport(String report) {
    return 'جاري تحميل $report...';
  }

  @override
  String previewingReport(String report) {
    return 'جاري معاينة $report...';
  }

  @override
  String noTypeApplications(String type) {
    return 'لا توجد طلبات $type';
  }

  @override
  String rejectSection(String section) {
    return 'رفض $section';
  }

  @override
  String allCountParentheses(String count) {
    return 'الكل ($count)';
  }

  @override
  String nameValue(String value) {
    return 'الاسم: $value';
  }

  @override
  String emailValue(String value) {
    return 'البريد الإلكتروني: $value';
  }

  @override
  String phoneValue(String value) {
    return 'الهاتف: $value';
  }

  @override
  String roleValue(String value) {
    return 'الدور: $value';
  }

  @override
  String statusValue(String value) {
    return 'الحالة: $value';
  }

  @override
  String joinDateValue(String value) {
    return 'تاريخ الانضمام: $value';
  }

  @override
  String deleteConfirmItem(String item) {
    return 'هل أنت متأكد أنك تريد حذف \"$item\"؟\nلا يمكن التراجع عن هذا الإجراء.';
  }

  @override
  String errorValue(String error) {
    return 'خطأ: $error';
  }

  @override
  String failedToUpdate(String error) {
    return 'فشل التحديث: $error';
  }

  @override
  String rejectionReasonValue(String reason) {
    return 'سبب الرفض: $reason';
  }

  @override
  String rejectItem(String item) {
    return 'رفض \"$item\"';
  }

  @override
  String orderIdValue(String id) {
    return 'رقم الطلب: $id';
  }

  @override
  String customerValue(String name) {
    return 'العميل: $name';
  }

  @override
  String restaurantValue(String name) {
    return 'المطعم: $name';
  }

  @override
  String amountEgpValue(String amount) {
    return 'المبلغ: ج.م $amount';
  }

  @override
  String itemsValue(String count) {
    return 'العناصر: $count';
  }

  @override
  String dateValue(String date) {
    return 'التاريخ: $date';
  }

  @override
  String timeValue(String time) {
    return 'الوقت: $time';
  }

  @override
  String failedToReorder(String error) {
    return 'فشل إعادة الطلب: $error';
  }

  @override
  String callCustomerName(String name) {
    return 'الاتصال بـ $name؟';
  }

  @override
  String callRestaurantName(String name) {
    return 'الاتصال بـ $name؟';
  }

  @override
  String assignDriverId(String id) {
    return 'تعيين $id';
  }

  @override
  String failedToSave(String error) {
    return 'فشل الحفظ: $error';
  }

  @override
  String payoutFrequencySet(String freq) {
    return 'تم تعيين تكرار الدفع إلى $freq';
  }

  @override
  String minimumPayoutSet(String amount) {
    return 'تم تعيين الحد الأدنى للدفع إلى \$$amount';
  }

  @override
  String editMethodName(String name) {
    return 'تعديل $name';
  }

  @override
  String expiresDate(String date) {
    return 'ينتهي في $date';
  }

  @override
  String addWalletType(String type) {
    return 'إضافة $type';
  }

  @override
  String enterWalletPhone(String type) {
    return 'أدخل رقم هاتف $type الخاص بك';
  }

  @override
  String restaurantIndex(String index) {
    return 'مطعم $index';
  }

  @override
  String lastActiveDate(String date) {
    return 'أخر ظهور: $date';
  }

  @override
  String get networkError => 'خطأ في الشبكة، يرجى التحقق من اتصالك.';

  @override
  String get serverError => 'فشل الاتصال بالخادم.';

  @override
  String get invalidCredentials =>
      'البريد الإلكتروني أو كلمة المرور غير صحيحة.';

  @override
  String get emailInUse => 'هذا البريد الإلكتروني مسجل بالفعل.';

  @override
  String get tooManyRequests => 'طلبات كثيرة. يرجى المحاولة مرة أخرى لاحقاً.';

  @override
  String get authFailed => 'فشلت المصادقة. يرجى المحاولة مرة أخرى.';

  @override
  String get unexpectedError => 'حدث خطأ غير متوقع.';

  @override
  String get driverDeliveries => 'التوصيلات';

  @override
  String get driverHistory => 'السجل';

  @override
  String get youAreOnline => 'أنت متصل';

  @override
  String get youAreOffline => 'أنت غير متصل';

  @override
  String get readyToAcceptDeliveries => 'جاهز لقبول الطلبات';

  @override
  String get notReceivingRequests => 'لن تتلقى طلبات توصيل';

  @override
  String get goOffline => 'تسجيل الخروج';

  @override
  String get goOnline => 'تسجيل الدخول';

  @override
  String get todaysEarnings => 'أرباح اليوم';

  @override
  String get keepDeliveringToIncrease => 'استمر في التوصيل لزيادة أرباحك!';

  @override
  String get activeTrips => 'نشط';

  @override
  String get pendingTrips => 'قيد الانتظار';

  @override
  String get totalTrips => 'إجمالي الرحلات';

  @override
  String get confirmDeliveryProceed => 'هل قمت بتسليم جميع العناصر للعميل؟';

  @override
  String get turnOnToStartReceivingOrders => 'قم بالتشغيل لبدء تلقي الطلبات';

  @override
  String get cantGoOfflineWithActiveOrder =>
      'لا يمكنك قطع الاتصال أثناء وجود طلب نشط';

  @override
  String get chooseTheFoodYouLove => 'اختر الطعام الذي تحبه';

  @override
  String get orderBestDishes =>
      'اطلب أفضل الأطباق من مطاعمك المفضلة مع توصيل سريع حتى باب منزلك.';

  @override
  String get searchForFoodItem => 'ابحث عن عنصر غذائي...';

  @override
  String get orderNow => 'اطلب الآن';

  @override
  String get whatDoYouNeed => 'ماذا نوصل لك اليوم؟';

  @override
  String get soon => 'قريباً';

  @override
  String get fastDelivery => 'توصيل سريع';

  @override
  String get orderFoodBestRestaurants =>
      'اطلب الطعام من أفضل المطاعم القريبة منك مع توصيل سريع جداً.';

  @override
  String get browseRestaurantsBtn => 'تصفح المطاعم';

  @override
  String get activeOrdersTab => 'النشطة';

  @override
  String get pastOrdersTab => 'السابقة';

  @override
  String get noActiveOrders => 'لا توجد طلبات نشطة';

  @override
  String get noPastOrders => 'لا توجد طلبات سابقة';

  @override
  String get activeOrdersAppearHere => 'ستظهر طلباتك النشطة هنا';

  @override
  String get pastOrdersAppearHere => 'ستظهر طلباتك السابقة هنا';

  @override
  String get reorder => 'إعادة الطلب';

  @override
  String get rate => 'تقييم';

  @override
  String get etaCalculating => 'جاري الحساب...';

  @override
  String get orderTimeline => 'الجدول الزمني للطلب';

  @override
  String get waitingForRestaurant => 'في انتظار المطعم';

  @override
  String get dispatching => 'جاري الإرسال';

  @override
  String get waitingToAssignDriver => 'في انتظار تعيين سائق';

  @override
  String get outForDelivery => 'في الطريق للتوصيل';

  @override
  String get waitingForPickUp => 'في انتظار الاستلام من المطعم';

  @override
  String get account => 'الحساب';

  @override
  String get driverRole => 'سائق';

  @override
  String get drawerWallet => 'المحفظة';

  @override
  String get drawerLogout => 'تسجيل الخروج';

  @override
  String get drawerHelpSupport => 'المساعدة والدعم';

  @override
  String get excelImportBtn => 'استيراد';

  @override
  String get excelImportTitle => 'استيراد جماعي من Excel';

  @override
  String excelImportPreviewTitle(int count) {
    return 'معاينة ($count صفوف)';
  }

  @override
  String get excelImportingTitle => 'جاري الاستيراد…';

  @override
  String get excelImportDoneTitle => 'اكتمل الاستيراد';

  @override
  String get excelImportStep1 => '١. حمّل ملف Excel النموذجي أدناه.';

  @override
  String get excelImportStep2 =>
      '٢. أدخل عناصرك — أعمدة القسم والتوفر تحتوي على قوائم منسدلة.';

  @override
  String get excelImportStep3 =>
      '٣. ارفع الملف المعبأ واعرض المعاينة قبل الاستيراد.';

  @override
  String get excelImportStep4 =>
      '٤. أضف صور العناصر بعد الاستيراد باستخدام زر التعديل على كل عنصر.';

  @override
  String excelImportSectionsLabel(String vendorType) {
    return 'أقسام $vendorType';
  }

  @override
  String get excelImportDownloadTemplate => 'تحميل النموذج';

  @override
  String get excelImportUploadFile => 'رفع ملف Excel (.xlsx)';

  @override
  String excelImportFailedTemplate(String error) {
    return 'فشل في إنشاء النموذج: $error';
  }

  @override
  String get excelImportCouldNotRead => 'تعذّر قراءة بيانات الملف.';

  @override
  String get excelImportNoData =>
      'لم يتم العثور على صفوف بيانات. تأكد من أن الملف يحتوي على ورقة \"Menu Items\" وبيانات تبدأ من الصف الثالث.';

  @override
  String excelImportFailedRead(String error) {
    return 'فشل في قراءة الملف: $error';
  }

  @override
  String get excelImportFailed =>
      'فشل الاستيراد. تحقق من اتصالك وحاول مرة أخرى.';

  @override
  String excelImportSuccessCount(int count) {
    return 'تم استيراد $count عنصر بنجاح.';
  }

  @override
  String get excelImportAddImages =>
      'لإضافة صور العناصر، اضغط على زر التعديل لأي عنصر في قائمتك.';

  @override
  String excelImportSkippedRows(int count) {
    return 'تم تخطي $count صف.';
  }

  @override
  String get excelImportDownloadSkipLog => 'تحميل سجل التخطي';

  @override
  String get excelImportClose => 'إغلاق';

  @override
  String get excelImportReupload => 'إعادة الرفع';

  @override
  String excelImportConfirmBtn(int count) {
    return 'استيراد $count عنصر';
  }

  @override
  String get excelImportValid => 'صالح';

  @override
  String get excelImportErrors => 'أخطاء (تم التخطي)';

  @override
  String excelImportProgress(int current, int total) {
    return 'جاري استيراد العنصر $current من $total…';
  }

  @override
  String get editProfile => 'تعديل الملف الشخصي';

  @override
  String get editProfileSubtitle => 'تحديث معلوماتك الشخصية';

  @override
  String get changePasswordSubtitle => 'تحديث كلمة المرور الخاصة بك';

  @override
  String get savedAddressesSubtitle => 'إدارة مواقع التوصيل الخاصة بك';

  @override
  String get preferencesSubtitle => 'إدارة إعدادات اللغة والعرض';

  @override
  String get liveChatSubtitle => 'تحدث مع وكلاء الدعم لدينا';

  @override
  String get emailUs => 'راسلنا';

  @override
  String get emailUsSubtitle => 'support@zspeed.app';

  @override
  String get callUs => 'اتصل بنا';

  @override
  String get callUsSubtitle => '+20 100 000 0000';

  @override
  String get faqSubtitle => 'الأسئلة المتكررة';

  @override
  String get userGuideSubtitle => 'تعرف على كيفية استخدام التطبيق';

  @override
  String get videoTutorialsSubtitle => 'شاهد أدلة خطوة بخطوة';

  @override
  String get contactSupportTitle => 'التواصل مع الدعم';

  @override
  String get contactSupportSubtitle => 'تواصل مع فريق الدعم لدينا';

  @override
  String get resourcesTitle => 'الموارد';

  @override
  String get orderDelivered => 'تم التوصيل';

  @override
  String get enjoyYourMeal => 'استمتع بوجبتك!';

  @override
  String get arrivingSoon => 'يصل قريباً';

  @override
  String get driverAssigned => 'تم تعيين السائق!';

  @override
  String get searchingForNearbyDriver => 'جاري البحث عن سائق قريب...';

  @override
  String get noDriversAvailableVicinity => 'لا يوجد سائقين متاحين في الجوار';

  @override
  String get assigningDriver => 'جاري تعيين سائق...';

  @override
  String get verifyYourPhone => 'تحقق من رقم هاتفك';

  @override
  String get addYourPhoneNumberUpdates =>
      'أضف رقم هاتفك لتحديثات الطلب وتنسيق التوصيل';

  @override
  String get phoneNum => 'رقم الهاتف';

  @override
  String get sendCode => 'إرسال الرمز';

  @override
  String get illDoThisLater => 'سأفعل هذا لاحقاً';

  @override
  String get verifyPhone => 'التحقق من الهاتف';

  @override
  String get minOrderInfo => 'الحد الأدنى';

  @override
  String get deliveryFeeInfo => 'التوصيل';

  @override
  String get deliveryMinInfo => 'دقيقة';

  @override
  String get noItemsInSection => 'لا توجد عناصر في هذا القسم';

  @override
  String get viewCartBtn => 'عرض السلة';

  @override
  String get setDeliveryAddress => 'حدد عنوان التوصيل الخاص بك';

  @override
  String get searchRestaurantsDishes => 'ابحث عن مطاعم أو أطباق أو مأكولات...';

  @override
  String get acceptance => 'القبول';

  @override
  String get currentLocationUpdate => 'الموقع الحالي';

  @override
  String get updateBtn => 'تحديث';

  @override
  String get gpsTrackingActive => 'تتبع GPS نشط - يتم تحديث الموقع كل 30 ثانية';

  @override
  String get checkoutLabel => 'إتمام الشراء';

  @override
  String get orderSummaryLabel => 'ملخص الطلب';

  @override
  String get deliveryAddressLabel => 'عنوان التوصيل';

  @override
  String get enterYourDeliveryAddress => 'أدخل عنوان التوصيل الخاص بك';

  @override
  String get deliveryInstructionsOptional => 'تعليمات التوصيل (اختياري)';

  @override
  String get egRingDoorbell => 'مثل: رن الجرس، الطابق الثاني';

  @override
  String get placeOrderLabel => 'إتمام الطلب';

  @override
  String get subtotalLabel => 'المجموع الفرعي';

  @override
  String get deliveryFeeLabel => 'رسوم التوصيل';

  @override
  String itemsCount(int count) {
    return 'عناصر $count';
  }

  @override
  String get searchRestaurantsPlaceholder =>
      '...ابحث عن المطاعم، الأطباق أو المطابخ';

  @override
  String get setYourDeliveryAddress => 'حدد عنوان التوصيل';

  @override
  String get customerPortal => 'بوابة العميل';

  @override
  String get sortByLabel => 'ترتيب حسب';

  @override
  String get fastFoodCategory => 'وجبات سريعة';

  @override
  String get egyptianCategory => 'مصري';

  @override
  String get allCategory => 'الكل';

  @override
  String get editProfileLabel => 'تعديل الملف الشخصي';

  @override
  String get updatePersonalInfo => 'تحديث معلوماتك الشخصية';

  @override
  String get changePasswordLabel => 'تغيير كلمة المرور';

  @override
  String get updateLoginPassword => 'تحديث كلمة مرور تسجيل الدخول';

  @override
  String get paymentMethodsLabel => 'طرق الدفع';

  @override
  String get managePaymentOptions => 'إدارة طرق الدفع';

  @override
  String get savedAddressesLabel => 'العناوين المحفوظة';

  @override
  String get manageDeliveryLocations => 'إدارة مواقع التوصيل';

  @override
  String get preferencesLabel => 'التفضيلات';

  @override
  String get notificationsLabel => 'الإشعارات';

  @override
  String get receiveOrderUpdates => 'استلام تحديثات الطلبات والعروض';

  @override
  String get languageLabel => 'اللغة';

  @override
  String get choosePreferredLanguage => 'اختر لغتك المفضلة';

  @override
  String get englishLanguage => 'الإنجليزية';

  @override
  String get arabicLanguage => 'العربية';

  @override
  String get verifyPhoneTitle => 'تأكيد رقم هاتفك';

  @override
  String get verifyPhoneSubtitle =>
      'أضف رقم هاتفك لتحديثات الطلب والتنسيق للتوصيل.';

  @override
  String get phoneNumberPlaceholder => 'رقم الهاتف';

  @override
  String get sendCodeButton => 'إرسال الرمز';

  @override
  String get deliveryDriver => 'مندوب التوصيل';

  @override
  String get driverNotAssignedYet => 'لم يتم تعيين مندوب بعد';

  @override
  String get assignDriverOnceReady =>
      'سنقوم بتعيين مندوب بمجرد أن يكون طلبك جاهزاً';

  @override
  String get paymentSection => 'الدفع';

  @override
  String welcomeBackToast(String firstName) {
    return 'مرحباً بعودتك، $firstName! 👋';
  }

  @override
  String get whatAreYouCravingToday => 'ماذا تشتهي اليوم؟';

  @override
  String get chooseFoodYouLove => 'اختر الطعام الذي تحبه';

  @override
  String get selectLocationOnMap => 'حدد الموقع على الخريطة';

  @override
  String get tapToPinYourDeliveryLocation => 'اضغط لتحديد موقع التوصيل';

  @override
  String get deliveryLocation => 'موقع التوصيل';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get signOutWarning =>
      'سيتم تسجيل خروجك من حسابك. سجّل الدخول مجدداً للمتابعة.';

  @override
  String get logoutFailed => 'فشل تسجيل الخروج';

  @override
  String get role => 'الدور';

  @override
  String get resetPassword => 'إعادة تعيين كلمة المرور';

  @override
  String get resetPasswordInstructions =>
      'أدخل بريدك الإلكتروني وسنرسل لك رابط إعادة التعيين.';

  @override
  String get sendResetLink => 'إرسال رابط الاسترداد';

  @override
  String get resetLinkSent => 'تم إرسال رابط الاسترداد! تحقق من بريدك الوارد.';

  @override
  String get failedToSendResetEmail =>
      'فشل إرسال بريد إعادة التعيين. حاول مجدداً.';

  @override
  String get signUpFailed => 'فشل إنشاء الحساب';

  @override
  String get loginFailed => 'فشل تسجيل الدخول';

  @override
  String get googleSignInFailed => 'فشل تسجيل الدخول بـ Google';

  @override
  String get signInWithPhone => 'تسجيل الدخول برقم الهاتف';

  @override
  String get phoneVerificationSmsHint =>
      'سنرسل لك رمز تحقق عبر الرسائل القصيرة';

  @override
  String get enterValidPhoneNumber => 'أدخل رقم هاتف صحيح (مثال: 01012345678 )';

  @override
  String get failedToSendCode => 'فشل إرسال الرمز';

  @override
  String get autoVerificationFailed => 'فشل التحقق التلقائي';

  @override
  String get failedToSendSms => 'فشل إرسال الرسالة القصيرة';

  @override
  String get verifyAndSignIn => 'تحقق وسجّل الدخول';

  @override
  String get sendVerificationCode => 'إرسال رمز التحقق';

  @override
  String get enterSixDigitCode => 'أدخل الرمز المكوّن من 6 أرقام';

  @override
  String get verificationFailed => 'فشل التحقق';

  @override
  String get invalidCode => 'رمز غير صحيح';

  @override
  String get change => 'تغيير';

  @override
  String get resendCode2 => 'إعادة إرسال الرمز';

  @override
  String get fullNameHint => 'مثال: أحمد حسن';

  @override
  String get fullNameRequired => 'يرجى إدخال اسمك';

  @override
  String get nameTooShort => 'الاسم قصير جداً';

  @override
  String get weNeedYourName => 'نحتاج اسمك للطلبات والتوصيل.';

  @override
  String get failedToSaveName => 'فشل حفظ الاسم';

  @override
  String get verifyYourEmail => 'تحقق من بريدك الإلكتروني';

  @override
  String get emailVerified => 'تم التحقق من البريد الإلكتروني!';

  @override
  String get sentSixDigitCodeTo => 'لقد أرسلنا رمزاً مكوّناً من 6 أرقام إلى:';

  @override
  String get emailVerifiedSuccessfully =>
      'تم التحقق من بريدك الإلكتروني بنجاح!';

  @override
  String get failedToSendVerificationCode => 'فشل إرسال رمز التحقق.';

  @override
  String get failedToSendVerificationCodeRetry =>
      'فشل إرسال رمز التحقق. يرجى المحاولة مجدداً.';

  @override
  String get pleaseEnterSixDigitCode => 'يرجى إدخال الرمز المكوّن من 6 أرقام.';

  @override
  String get invalidCodeError => 'رمز غير صحيح.';

  @override
  String get verificationFailedRetry => 'فشل التحقق. يرجى المحاولة مجدداً.';

  @override
  String get verifyCode => 'تحقق من الرمز';

  @override
  String get sending => 'جاري الإرسال...';

  @override
  String resendInSeconds(int seconds) {
    return 'إعادة الإرسال خلال $seconds ث';
  }

  @override
  String get illVerifyLater => 'سأتحقق لاحقاً';

  @override
  String get chooseYourRole => 'اختر دورك';

  @override
  String get selectHowYouWantToUse => 'اختر كيف تريد استخدام Z Speed Delivery';

  @override
  String get roleCustomer => 'عميل';

  @override
  String get roleCustomerSubtitle => 'اطلب الطعام وتتبع التوصيل';

  @override
  String get roleDriver => 'سائق';

  @override
  String get roleDriverSubtitle => 'وصّل الطلبات واكسب المال';

  @override
  String get roleVendor => 'بائع / شريك';

  @override
  String get roleVendorSubtitle => 'مطعم، سوبرماركت أو صيدلية';

  @override
  String get roleAdmin => 'مدير';

  @override
  String get roleAdminSubtitle => 'إدارة شاملة للمنصة';

  @override
  String get selected => '✓ محدد';

  @override
  String get adminManagement => 'إدارة المشرفين';

  @override
  String get addAdmin => 'إضافة مشرف';

  @override
  String get addNewAdmin => 'إضافة مشرف جديد';

  @override
  String get searchAdmins => 'بحث عن مشرفين...';

  @override
  String get adminsList => 'قائمة المشرفين';

  @override
  String get adminColumnHeader => 'المشرف';

  @override
  String get joinedColumnHeader => 'تاريخ الانضمام';

  @override
  String get noAdminUsersFound => 'لا يوجد مشرفون';

  @override
  String get adminCreatedSuccessfully => 'تم إنشاء المشرف بنجاح';

  @override
  String get userManagement => 'إدارة المستخدمين';

  @override
  String get usersList => 'قائمة المستخدمين';

  @override
  String get userColumnHeader => 'المستخدم';

  @override
  String get actionsColumnHeader => 'الإجراءات';

  @override
  String get searchUsers => 'بحث عن مستخدمين...';

  @override
  String get allRoles => 'كل الأدوار';

  @override
  String get allStatuses => 'جميع الحالات';

  @override
  String get restaurantManagement => 'إدارة المطاعم';

  @override
  String get vendorManagement => 'إدارة الموردين';

  @override
  String get addVendor => 'إضافة مورد';

  @override
  String get noVendorsFound => 'لم يتم العثور على موردين';

  @override
  String get changeVendorType => 'تغيير نوع المورد';

  @override
  String get allFilter => 'الكل';

  @override
  String get systemSettings => 'إعدادات النظام';

  @override
  String get localizationSection => 'اللغة';

  @override
  String get platformConfiguration => 'إعدادات المنصة';

  @override
  String get platformCommission => 'عمولة المنصة';

  @override
  String get maintenanceMode => 'وضع الصيانة';

  @override
  String get platformIsOffline => 'المنصة غير متاحة حالياً';

  @override
  String get platformIsLive => 'المنصة تعمل بشكل طبيعي';

  @override
  String get deleteSection => 'حذف القسم';

  @override
  String deleteSectionConfirm(String name) {
    return 'حذف \"$name\"؟ لا يمكن التراجع عن هذا الإجراء.';
  }

  @override
  String get editSection => 'تعديل القسم';

  @override
  String get statusColumnHeader => 'الحالة';

  @override
  String get roleColumnHeader => 'الدور';

  @override
  String get emailLabel => 'البريد الإلكتروني';

  @override
  String qtyLabel(String qty) {
    return 'الكمية: $qty';
  }

  @override
  String get popular => 'الأكثر طلباً';

  @override
  String get quantity => 'الكمية';

  @override
  String get customizeYourItem => 'خصص طلبك';

  @override
  String get specialInstructions => 'تعليمات خاصة';

  @override
  String get specialInstructionsHint => 'مثال: بدون بصل، حار جداً...';

  @override
  String get addToCartButton => 'أضف إلى السلة';

  @override
  String itemsInSection(int count) {
    return '$count عنصر';
  }

  @override
  String itemsInSectionPlural(int count) {
    return '$count عناصر';
  }

  @override
  String addedToCartItem(String name) {
    return 'تمت إضافة $name إلى السلة';
  }

  @override
  String get viewCart => 'عرض السلة';

  @override
  String get replaceCartContent =>
      'تحتوي سلتك على عناصر من مطعم آخر. هل تريد مسح السلة وإضافة هذا العنصر بدلاً منه؟';

  @override
  String vendorCurrentlyClosed(String vendorType) {
    return 'هذا $vendorType مغلق حالياً. يمكنك تصفح القائمة لكن الطلب غير متاح.';
  }

  @override
  String get ownerChip => 'المالك';

  @override
  String get free => 'مجاني';

  @override
  String addonPricePrefix(String price) {
    return '+ج.م $price';
  }

  @override
  String get choose1Option => 'اختر خياراً واحداً';

  @override
  String get chooseUpTo1Option => 'اختر خياراً واحداً كحد أقصى (اختياري)';

  @override
  String chooseMinToMax(int min, int max) {
    return 'اختر من $min إلى $max خيارات';
  }

  @override
  String chooseAtLeast(int min) {
    return 'اختر على الأقل $min خيار';
  }

  @override
  String chooseAtLeastPlural(int min) {
    return 'اختر على الأقل $min خيارات';
  }

  @override
  String chooseUpToMax(int max) {
    return 'اختر حتى $max خيارات (اختياري)';
  }

  @override
  String get chooseAnyOptions => 'اختر أي عدد من الخيارات (اختياري)';

  @override
  String get topRestaurantsNearYou => 'أفضل المطاعم القريبة منك';

  @override
  String get viewAll => 'عرض الكل';

  @override
  String get viewMenu => 'عرض القائمة';

  @override
  String get openStatus => 'مفتوح';

  @override
  String get closedStatus => 'مغلق';

  @override
  String get deliverySublabel => 'توصيل';

  @override
  String get minOrderSublabel => 'حد أدنى للطلب';

  @override
  String get searchSupermarkets => 'ابحث في السوبرماركت أو المنتجات...';

  @override
  String get searchPharmacies => 'ابحث في الصيدليات أو الأدوية...';

  @override
  String get errorLoadingSupermarkets => 'خطأ في تحميل السوبرماركت';

  @override
  String get errorLoadingPharmacies => 'خطأ في تحميل الصيدليات';

  @override
  String get errorLoadingRestaurants => 'خطأ في تحميل المطاعم';

  @override
  String addressRemoved(String label) {
    return 'تمت إزالة $label';
  }

  @override
  String addressAdded(String label) {
    return 'تمت إضافة $label!';
  }

  @override
  String get addressLabel => 'العنوان';

  @override
  String get buildingOptional => 'المبنى / الفيلا (اختياري)';

  @override
  String get floorAptOptional => 'الطابق / الشقة (اختياري)';

  @override
  String get owner => 'مالك';

  @override
  String sectionItemCount(int count) {
    return '$count عنصر';
  }

  @override
  String sectionItemCountPlural(int count) {
    return '$count عناصر';
  }

  @override
  String addItemWithPrice(String price) {
    return 'إضافة عنصر  $price جنيه';
  }

  @override
  String vendorClosedLabel(String vendorType) {
    return '$vendorType مغلق';
  }

  @override
  String get orderSummary => 'ملخص الطلب';

  @override
  String get needHelpWithOrder => 'تحتاج مساعدة مع طلبك؟';

  @override
  String qtyWithMeasure(String qty, String measure) {
    return 'الكمية: $qty $measure';
  }

  @override
  String get estimatedTime => 'الوقت المتوقع';

  @override
  String get calculating => 'جارٍ الحساب...';

  @override
  String get liveTracking => 'تتبع مباشر';

  @override
  String get ordered => 'تم الطلب';

  @override
  String percentComplete(int percent) {
    return '$percent% مكتمل';
  }

  @override
  String get categories => 'الفئات';

  @override
  String categoriesCount(int count) {
    return '$count فئات';
  }

  @override
  String get quickDelivery => 'توصيل سريع';

  @override
  String get grocery => 'بقالة';

  @override
  String get drinks => 'مشروبات';

  @override
  String get flowers => 'زهور';

  @override
  String get petSupplies => 'مستلزمات الحيوانات';

  @override
  String get freshOrganic => 'طازج وعضوي';

  @override
  String get bakery => 'مخبوزات';

  @override
  String get expired => 'انتهت الصلاحية';

  @override
  String get week => 'أسبوع';

  @override
  String get month => 'شهر';

  @override
  String get items => 'عناصر';

  @override
  String tripsCount(int count) {
    return '$count رحلات';
  }

  @override
  String tripDateAt(String date, String time) {
    return '$date في $time';
  }

  @override
  String egpEarnings(String amount) {
    return '+$amount جنيه';
  }

  @override
  String get toRestaurant => 'إلى المطعم';

  @override
  String get toCustomer => 'إلى العميل';

  @override
  String itemsCount2(int count) {
    return '$count عناصر';
  }

  @override
  String itemsAssigned(int count) {
    return '$count عناصر مُعيَّنة';
  }

  @override
  String get remainingToAccept => 'متبقية للقبول';

  @override
  String get noPendingRequests => 'لا توجد طلبات معلقة';

  @override
  String get newDeliveryRequestsWillAppear => 'ستظهر طلبات التوصيل الجديدة هنا';

  @override
  String get noActiveDeliveries => 'لا توجد توصيلات نشطة';

  @override
  String get acceptedOrdersWillAppear => 'ستظهر الطلبات المقبولة هنا';

  @override
  String get updateLocationFirst => 'قم بتحديث موقعك أولاً قبل الاتصال';

  @override
  String get headingToRestaurant => 'في الطريق إلى المطعم';

  @override
  String get headingToCustomer => 'في الطريق إلى العميل';

  @override
  String get rejectReason => 'السبب (اختياري)';

  @override
  String get rejectReasonHint => 'مثال: بعيد جداً، مشغول بتوصيل آخر';

  @override
  String get areYouSureRejectRequest =>
      'هل أنت متأكد أنك تريد رفض طلب التوصيل هذا؟';

  @override
  String get newLabel => 'جديد';

  @override
  String orderIdShort(String id) {
    return 'طلب #$id';
  }

  @override
  String get callDriver => 'اتصل بالسائق';

  @override
  String get callingDriver2 => 'الاتصال بالسائق:';

  @override
  String get callLabel => 'اتصال';

  @override
  String get messageDriver => 'رسالة إلى السائق';

  @override
  String get sendMessageToDriver => 'أرسل رسالة إلى سائقك:';

  @override
  String get typeMessageHere => 'اكتب رسالتك هنا...';

  @override
  String get driverLocation => 'موقع السائق';

  @override
  String get openingDriverLocation => 'فتح موقع السائق على الخريطة...';

  @override
  String get completeRide => 'إنهاء الرحلة';

  @override
  String get hasRideBeenCompleted => 'هل تمت الرحلة بنجاح؟';

  @override
  String get noButton => 'لا';

  @override
  String get yesComplete => 'نعم، إنهاء';

  @override
  String get cancelRide => 'إلغاء الرحلة';

  @override
  String get areYouSureCancelRide => 'هل أنت متأكد أنك تريد إلغاء هذه الرحلة؟';

  @override
  String get cannotBeUndone => 'لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get yesCancel => 'نعم، إلغاء';

  @override
  String get pickupLocation => 'موقع الاستلام';

  @override
  String get dropoffLocation => 'موقع التوصيل';

  @override
  String get whereToQuestion => 'إلى أين؟';

  @override
  String get availableRides => 'الرحلات المتاحة';

  @override
  String get popularLocations => 'المواقع الشائعة';

  @override
  String get onlineStatus => 'متصل';

  @override
  String get typeYourMessage => 'اكتب رسالتك...';

  @override
  String get pleaseEnterDropoff => 'الرجاء إدخال موقع التوصيل';

  @override
  String get confirmBooking => 'تأكيد الحجز';

  @override
  String bookRideConfirm(String rideType, String driver, String price) {
    return 'هل تريد حجز $rideType مع $driver مقابل $price جنيه؟';
  }

  @override
  String get rideBookedSuccess => 'تم حجز الرحلة بنجاح! السائق في الطريق إليك.';

  @override
  String get rideCompletedThankYou =>
      'اكتملت الرحلة! شكراً لاختيارك Speed Rides.';

  @override
  String get rideCancelledSuccess => 'تم إلغاء الرحلة بنجاح.';

  @override
  String get messageSent => 'تم إرسال الرسالة';

  @override
  String get assignDrivers => 'تعيين السائقين';

  @override
  String get outOfRange => 'خارج النطاق';

  @override
  String kmFromRestaurant(String distance) {
    return '$distance كم من المطعم';
  }

  @override
  String get multipleItems => 'عناصر متعددة';

  @override
  String get perDriver => 'لكل سائق';

  @override
  String totalDriversCount(int count) {
    return 'الإجمالي ($count سائقين)';
  }

  @override
  String get assignedDriversSection => 'السائقون المُعيَّنون';

  @override
  String get noDriversAssigned => 'لم يتم تعيين سائقين بعد';

  @override
  String get availableDriversSection => 'السائقون المتاحون';

  @override
  String get sortedByDistance => 'مرتبون حسب المسافة والتقييم ومعدل القبول';

  @override
  String get noAvailableDrivers => 'لا يوجد سائقون متاحون الآن';

  @override
  String get alreadyAssigned => 'مُعيَّن بالفعل';

  @override
  String get assignDriverQuestion => 'هل تريد تعيين هذا السائق للطلب؟';

  @override
  String get assignDriverNote =>
      'ملاحظة: سيتم تعيين السائق لتوصيل جميع عناصر هذا الطلب.';

  @override
  String removeDriverConfirm(String name) {
    return 'هل أنت متأكد أنك تريد إزالة $name من هذا الطلب؟';
  }

  @override
  String get noActiveRide => 'لا توجد رحلة نشطة';

  @override
  String get bookRideToGetStarted => 'احجز رحلة للبدء';

  @override
  String get bookARide => 'احجز رحلة';

  @override
  String get pickupLabel => 'الاستلام';

  @override
  String get dropoffLabel => 'التوصيل';

  @override
  String get liveMapPlaceholder => 'سيظهر الخريطة المباشرة هنا';

  @override
  String get rideHistory => 'سجل الرحلات';

  @override
  String get noRideHistory => 'لا يوجد سجل رحلات';

  @override
  String get rideDetails => 'تفاصيل الرحلة';

  @override
  String get rideType => 'نوع الرحلة';

  @override
  String etaMinutes(String minutes) {
    return '$minutes دقيقة';
  }

  @override
  String distanceKm(String distance) {
    return '$distance كم';
  }

  @override
  String priceEgp(String price) {
    return '$price جنيه';
  }

  @override
  String get calling => 'جارٍ الاتصال...';

  @override
  String driverLabel(String name) {
    return 'السائق: $name';
  }

  @override
  String get etaLabel => 'وقت الوصول';

  @override
  String get distanceLabel => 'المسافة';

  @override
  String get priceLabel => 'السعر';

  @override
  String get goingToRestaurant => 'في الطريق إلى المطعم';

  @override
  String get arrivedAtRestaurant => 'وصلت إلى المطعم';

  @override
  String get pickingUpOrder => 'جارٍ استلام الطلب';

  @override
  String get orderPickedUp => 'تم استلام الطلب';

  @override
  String get deliveringToCustomer => 'جارٍ التوصيل إلى العميل';

  @override
  String get startNewTrip => 'ابدأ رحلة جديدة';

  @override
  String get unknownStatus => 'غير معروف';

  @override
  String get continueLabel => 'متابعة';

  @override
  String get activeTrip => 'رحلة نشطة';

  @override
  String get tripProgress => 'تقدم الرحلة';

  @override
  String etaAndDistance(int minutes, String distance) {
    return 'الوصول: $minutes دقيقة • $distance كم';
  }

  @override
  String get fareLabel => 'الأجرة';

  @override
  String get pickupTitle => 'الاستلام';

  @override
  String get deliveryTitle => 'التوصيل';

  @override
  String get viewTripDetails => 'عرض تفاصيل الرحلة';

  @override
  String get acceptOrderToStartDriving =>
      'اقبل طلباً من قائمة الطلبات المتاحة لبدء القيادة';

  @override
  String get acceptanceRate => 'معدل القبول';

  @override
  String get onTimeDeliveries => 'التوصيلات في الوقت المحدد';

  @override
  String get cancellationsLabel => 'الإلغاءات';

  @override
  String get avgRating => 'متوسط التقييم';

  @override
  String get orderIdLabel => 'رقم الطلب';

  @override
  String estimatedTimeMin(int minutes) {
    return '$minutes دقيقة';
  }

  @override
  String get uploadFailed => 'فشل الرفع';

  @override
  String get personalInformation => 'المعلومات الشخصية';

  @override
  String get vehicleInformation => 'معلومات المركبة';

  @override
  String get vehicleColor => 'اللون';

  @override
  String get plateNumberLabel => 'رقم اللوحة';

  @override
  String get typeLabel => 'النوع';

  @override
  String get reviewSubtitle =>
      'يرجى مراجعة جميع المعلومات بعناية قبل الإرسال. يمكنك النقر على \"تعديل\" للرجوع وإجراء التغييرات.';

  @override
  String get applicationDisclaimer =>
      'بتقديم هذا الطلب، تؤكد أن جميع المعلومات المقدمة دقيقة. سيتم مراجعة طلبك في غضون 1-3 أيام عمل.';

  @override
  String get basicInfo => 'المعلومات الأساسية';

  @override
  String get vehicleStep => 'المركبة';

  @override
  String get wallet => 'المحفظة';

  @override
  String get currentLocation => 'الموقع الحالي';

  @override
  String get updating => 'جارٍ التحديث...';

  @override
  String get noDeliveryHistory => 'لا يوجد سجل توصيل';

  @override
  String get completedDeliveriesWillAppear => 'ستظهر توصيلاتك المكتملة هنا';

  @override
  String get addressNotAvailable => 'العنوان غير متاح';

  @override
  String get noAddressProvided => 'لم يتم تقديم عنوان';

  @override
  String get orderReceivedByCustomer => 'تم تسليم الطلب إلى العميل';

  @override
  String get startNavigation => 'بدء التنقل';

  @override
  String get zoomIn => 'تكبير';

  @override
  String get zoomOut => 'تصغير';

  @override
  String get inAppNavigationMode => 'وضع التنقل داخل التطبيق';

  @override
  String get externalGoogleMaps => 'خرائط جوجل الخارجية';

  @override
  String get keepZSpeedAppOpen =>
      'حافظ على فتح تطبيق Z-SPEED مع إرشادات حية خطوة بخطوة';

  @override
  String get openTurnByTurnRoute =>
      'افتح مسار التنقل خطوة بخطوة في تطبيق خرائط جوجل';

  @override
  String get waitingForGpsCoordinates => 'بانتظار إحداثيات GPS...';

  @override
  String get reCenter => 'إعادة توسيط';

  @override
  String get driverSpecialty => 'تخصص السائق';

  @override
  String get delivery => 'توصيل';

  @override
  String get foodAndPackages => 'الطرد والبضائع';

  @override
  String get passengersRides => 'الركاب / الرحلات';

  @override
  String couldNotCall(String phone, String error) {
    return 'لا يمكن الاتصال بـ $phone: $error';
  }

  @override
  String get customerPhoneNotAvailable => 'رقم هاتف العميل غير متاح.';

  @override
  String get coordinatesNotAvailable => 'الإحداثيات غير متاحة.';

  @override
  String couldNotOpenMap(String error) {
    return 'لا يمكن فتح الخريطة: $error';
  }

  @override
  String get exit => 'خروج';

  @override
  String get driveTowardYourDestination => 'قد باتجاه وجهتك';

  @override
  String get minLabel => 'دقيقة';

  @override
  String get hrLabel => 'ساعة';

  @override
  String navigationEtaLabel(String eta) {
    return 'الوصول: $eta';
  }

  @override
  String inDistance(String distance) {
    return 'بعد $distance';
  }

  @override
  String get performanceSummary => 'ملخص الأداء';

  @override
  String get earningsAndPayout => 'الأرباح والمدفوعات';

  @override
  String get totalDeliveries => 'إجمالي التوصيلات';

  @override
  String get walletBalance => 'رصيد المحفظة';

  @override
  String get totalEarnings => 'إجمالي الأرباح';

  @override
  String completedCount(int count) {
    return '$count مكتملة';
  }

  @override
  String reviewsCount(int count) {
    return '$count تقييم';
  }

  @override
  String get noApplicationData => 'لم يتم العثور على بيانات الطلب.';

  @override
  String documentNumber(int number) {
    return 'مستند $number';
  }

  @override
  String get chatWithDriver => 'الدردشة مع السائق';

  @override
  String get callingDriverTitle => 'الاتصال بالسائق';

  @override
  String get speedRides => 'سبيد رايدز';

  @override
  String get speedRidesSubtitle => 'نقل آمن وموثوق في العاصمة الإدارية الجديدة';

  @override
  String get bookRide => 'احجز رحلة';

  @override
  String get activeRide => 'الرحلة النشطة';

  @override
  String get history => 'السجل';

  @override
  String stepOfTotal(int step, int total, String label) {
    return 'الخطوة $step من $total: $label';
  }

  @override
  String get driverDeclined => 'رفض السائق';

  @override
  String get unknownRestaurant => 'مطعم غير معروف';

  @override
  String get chatWithSupportAgents => 'تحدث مع وكلاء الدعم';

  @override
  String allCategoryNamed(Object name) {
    return 'كل $name';
  }

  @override
  String get markAllRead => 'تحديد الكل كمقروء';

  @override
  String get noNotificationsYet => 'لا توجد إشعارات بعد';

  @override
  String get orderSummarySection => '📦 ملخص الطلب';

  @override
  String get deliveryAddressSection => '📍 عنوان التوصيل';

  @override
  String get deliveryInstructionsSection => '📝 تعليمات التوصيل (اختياري)';

  @override
  String get paymentMethodSection => '💳 طريقة الدفع';

  @override
  String get promoCodeSection => '🏷 رمز الخصم';

  @override
  String get priceBreakdownSection => '💰 تفاصيل السعر';

  @override
  String get ringDoorbellHint => 'مثال: اضغط الجرس، الطابق الثاني';

  @override
  String get mobileWallet => 'المحفظة الإلكترونية';

  @override
  String get enterPromoCode => 'أدخل رمز الخصم';

  @override
  String get taxFourteen => 'ضريبة (14%)';

  @override
  String get discountLabel => 'خصم';

  @override
  String get totalLabel => 'الإجمالي';

  @override
  String get pleaseFixFollowing => 'يرجى تصحيح ما يلي:';

  @override
  String placeOrderAmount(String amount) {
    return 'تأكيد الطلب — $amount جنيه';
  }

  @override
  String get failedToPlaceOrder => 'فشل في تقديم الطلب';

  @override
  String kmAway(String distance) {
    return '$distance كم';
  }

  @override
  String estimatedMinutes(int min, int max) {
    return '⏱ $min–$max دقيقة';
  }

  @override
  String get fullNameLabel => 'الاسم الكامل';

  @override
  String get enterYourName => 'أدخل اسمك';

  @override
  String get enterPhoneNumber => 'أدخل رقم الهاتف';

  @override
  String get enterYourAddress => 'أدخل عنوانك';

  @override
  String get cityLabel => 'المدينة';

  @override
  String get deliveryOptionLabel => 'خيار التوصيل';

  @override
  String get standardDelivery => 'توصيل عادي';

  @override
  String get expressDelivery => 'توصيل سريع';

  @override
  String get pickupPoint => 'نقطة استلام';

  @override
  String get failedToLoadOrder => 'فشل في تحميل الطلب';

  @override
  String get driverWillBeAssignedSoon => 'سنعيّن سائقاً بمجرد جاهزية طلبك';

  @override
  String get searchingForDriver => 'جارٍ البحث عن سائق…';

  @override
  String get driverFallback => 'السائق';

  @override
  String get cancelReasonChangedMind => 'غيّرت رأيي';

  @override
  String get cancelReasonMistake => 'طلب خاطئ';

  @override
  String get cancelReasonTooLong => 'يستغرق وقتاً طويلاً';

  @override
  String get cancelReasonBetterOption => 'وجدت خياراً أفضل';

  @override
  String get cancelReasonOther => 'أخرى';

  @override
  String get orderCancelledSuccess => 'تم إلغاء الطلب بنجاح';

  @override
  String get failedToCancelOrder => 'فشل إلغاء الطلب';

  @override
  String get restaurantPreparingOrder => 'المطعم يحضر طلبك';

  @override
  String get lookingForDriver => 'جارٍ البحث عن سائق';

  @override
  String get waitingForOrderCompletion => 'في انتظار اكتمال الطلب';

  @override
  String get waitingForPickup => 'في انتظار الاستلام';

  @override
  String get driverBeingDispatched => 'جارٍ إرسال السائق';

  @override
  String get contactSupportLabel => 'تواصل مع الدعم';

  @override
  String get deliveryService => 'خدمة التوصيل';

  @override
  String get faqHowUpdateMenu => 'كيف أحدّث قائمتي؟';

  @override
  String get faqHowUpdateMenuAnswer =>
      'اذهب إلى قسم القائمة ← اضغط زر التعديل ← أجر التغييرات ← احفظ';

  @override
  String get faqManageOrders => 'كيف أدير الطلبات؟';

  @override
  String get faqManageOrdersAnswer =>
      'تبويب الطلبات يعرض جميع الطلبات. اضغط لعرض التفاصيل وتحديث الحالة.';

  @override
  String get faqChangeHours => 'كيف أغير ساعات المطعم؟';

  @override
  String get faqChangeHoursAnswer =>
      'الإعدادات ← ساعات العمل ← تعديل الأوقات لكل يوم';

  @override
  String get faqAddStaff => 'كيف أضيف موظفين جدد؟';

  @override
  String get faqAddStaffAnswer =>
      'الإعدادات ← إدارة الموظفين ← إضافة موظف جديد';

  @override
  String get faqPaymentIssues => 'مشاكل في معالجة الدفع؟';

  @override
  String get faqPaymentIssuesAnswer =>
      'تحقق من إعدادات الدفع أو تواصل مع الدعم لمشاكل محددة.';

  @override
  String get faqPrintReceipts => 'كيف أطبع الإيصالات؟';

  @override
  String get faqPrintReceiptsAnswer =>
      'تفاصيل الطلب ← طباعة الإيصال (يتطلب طابعة متصلة)';

  @override
  String get learnHowToUseApp => 'تعلم كيفية استخدام التطبيق';

  @override
  String get watchStepByStepGuides => 'شاهد الأدلة خطوة بخطوة';

  @override
  String get blogAndUpdates => 'المدونة والتحديثات';

  @override
  String get latestNewsAndUpdates => 'آخر الأخبار والتحديثات';

  @override
  String get subject => 'الموضوع';

  @override
  String get describeYourIssue => 'صف مشكلتك';

  @override
  String get appVersion => 'إصدار التطبيق';

  @override
  String get buildNumber => 'رقم الإصدار';

  @override
  String get developerLabel => 'المطور';

  @override
  String placeOrderEgp(String amount) {
    return 'تأكيد الطلب — $amount جنيه';
  }

  @override
  String get paymentDetails => 'تفاصيل الدفع';

  @override
  String get paymentId => 'رقم الدفع';

  @override
  String get paymentMethodLabel => 'طريقة الدفع';

  @override
  String get createdAt => 'تاريخ الإنشاء';

  @override
  String get completedAt => 'تاريخ الإتمام';

  @override
  String get transactionId => 'رقم المعاملة';

  @override
  String get paymentStatusPending => 'قيد الانتظار';

  @override
  String get paymentStatusCompleted => 'مكتمل';

  @override
  String get paymentStatusFailed => 'فاشل';

  @override
  String get paymentStatusRefunded => 'مسترد';

  @override
  String get paymentMethodCash => 'الدفع عند الاستلام';

  @override
  String get paymentMethodCard => 'بطاقة ائتمان/خصم';

  @override
  String get paymentMethodWallet => 'محفظة إلكترونية';

  @override
  String get paymentMethodsTitle => 'طرق الدفع';

  @override
  String get managePaymentMethods => 'إدارة طرق الدفع الخاصة باستلام المدفوعات';

  @override
  String get noPaymentMethodsSaved => 'لا توجد طرق دفع محفوظة';

  @override
  String get addPaymentMethodBelow => 'أضف طريقة دفع للبدء';

  @override
  String get payoutSettings => 'إعدادات الدفع';

  @override
  String payoutFrequencySetTo(String freq) {
    return 'تم تعيين تكرار الدفع إلى $freq';
  }

  @override
  String minimumPayoutSetTo(String amount) {
    return 'تم تعيين الحد الأدنى للدفع إلى $amount جنيه';
  }

  @override
  String editMethodNameTitle(String methodName) {
    return 'تعديل $methodName';
  }

  @override
  String methodUpdatedSuccess(String methodName) {
    return 'تم تحديث $methodName بنجاح';
  }

  @override
  String get registeredPhone => 'رقم الهاتف المسجل';

  @override
  String get phoneRequired => 'رقم الهاتف مطلوب';

  @override
  String get enterValidPhone => 'أدخل رقم هاتف صحيح';

  @override
  String get amountEgpLabel => 'المبلغ (جنيه)';

  @override
  String get privacySettings => 'إعدادات الخصوصية';

  @override
  String get dataCollection => 'جمع البيانات';

  @override
  String get controlWhatData => 'تحكم في البيانات التي نجمعها';

  @override
  String get dataCollectionEnabled => 'تم تفعيل جمع البيانات';

  @override
  String get dataCollectionDisabled => 'تم إيقاف جمع البيانات';

  @override
  String get analyticsTitle => 'التحليلات';

  @override
  String get helpUsImprove => 'ساعدنا في التحسين بمشاركة بيانات الاستخدام';

  @override
  String get analyticsEnabled => 'تم تفعيل التحليلات';

  @override
  String get analyticsDisabled => 'تم إيقاف التحليلات';

  @override
  String get marketingEmails => 'البريد التسويقي';

  @override
  String get receivePromotionalEmails => 'تلقي رسائل البريد الترويجية';

  @override
  String get marketingEmailsEnabled => 'تم تفعيل البريد التسويقي';

  @override
  String get marketingEmailsDisabled => 'تم إيقاف البريد التسويقي';

  @override
  String get securitySettings => 'إعدادات الأمان';

  @override
  String get biometricEnabled => 'تم تفعيل تسجيل الدخول البيومتري';

  @override
  String get biometricDisabled => 'تم إيقاف تسجيل الدخول البيومتري';

  @override
  String get dataManagement => 'إدارة البيانات';

  @override
  String get additionalOptions => 'خيارات إضافية';

  @override
  String get accountSection => 'الحساب';

  @override
  String get preferencesSection => 'التفضيلات';

  @override
  String get notificationsEnabledMsg => 'تم تفعيل الإشعارات';

  @override
  String get notificationsDisabledMsg => 'تم تعطيل الإشعارات';

  @override
  String get deliveryAreaLabel => 'منطقة التوصيل';

  @override
  String get selectServiceArea => 'اختر منطقة الخدمة';

  @override
  String get aboutSection => 'حول';

  @override
  String get aboutSpeedApp => 'حول تطبيق Speed';

  @override
  String get versionInfo => 'الإصدار 1.0.0';

  @override
  String get supportContact => 'الدعم / التواصل';

  @override
  String get getHelpContact => 'احصل على المساعدة والتواصل مع الدعم';

  @override
  String get privacyPolicyLabel => 'سياسة الخصوصية';

  @override
  String get readPrivacyPolicyLabel => 'اقرأ سياسة الخصوصية';

  @override
  String get termsOfServiceLabel => 'شروط الخدمة';

  @override
  String get readTermsConditions => 'اقرأ الشروط والأحكام';

  @override
  String get logoutButton => 'تسجيل الخروج';

  @override
  String get speedRidesVersion => 'Speed Rides v1.0.0';

  @override
  String languageChangedTo(String language) {
    return 'تم تغيير اللغة إلى $language';
  }

  @override
  String get loadingItems => 'جاري تحميل العناصر...';

  @override
  String get noteLabel => 'ملاحظة';

  @override
  String get savingLabel => 'جارٍ الحفظ...';

  @override
  String get applicationStatus => 'حالة الطلب';

  @override
  String get statusApproved => 'مقبول';

  @override
  String get statusUnderReview => 'قيد المراجعة';

  @override
  String get editWarningContent =>
      'إذا قمت بتعديل هذا القسم، سيعود حسابك إلى حالة الانتظار حتى يتحقق المسؤول مرة أخرى. هل أنت متأكد؟';

  @override
  String get businessInformationSection => 'معلومات العمل';

  @override
  String get locationAndHours => 'الموقع وساعات العمل';

  @override
  String get contactInformation => 'معلومات الاتصال';

  @override
  String get bankInformation => 'معلومات البنك';

  @override
  String get personalInformationSection => 'المعلومات الشخصية';

  @override
  String get vehicleInformationSection => 'معلومات المركبة';

  @override
  String get docCommercialRegistration => 'السجل التجاري';

  @override
  String get docBusinessLicense => 'رخصة العمل';

  @override
  String get docHealthCertificate => 'الشهادة الصحية';

  @override
  String get docTaxRegistration => 'التسجيل الضريبي';

  @override
  String get uploadDocument => 'رفع المستند';

  @override
  String get changeDocument => 'تغيير المستند';

  @override
  String get saveDocuments => 'حفظ المستندات';

  @override
  String vendorIsOpen(String vendorLabel) {
    return '$vendorLabel مفتوح';
  }

  @override
  String vendorIsClosed(String vendorLabel) {
    return '$vendorLabel مغلق';
  }

  @override
  String get avgPickTime => 'متوسط وقت الاستلام';

  @override
  String get avgFillTime => 'متوسط وقت التجهيز';

  @override
  String get statusApprovedLabel => 'مقبول';

  @override
  String get statusRejectedLabel => 'مرفوض';

  @override
  String get statusPendingLabel => 'قيد الانتظار';

  @override
  String get statusUnderReviewLabel => 'قيد المراجعة';

  @override
  String get applicationStatusLabel => 'حالة الطلب';

  @override
  String get savingChanges => 'جارٍ الحفظ...';

  @override
  String get editTooltip => 'تعديل';

  @override
  String get cancelTooltip => 'إلغاء';

  @override
  String get pendingReview => 'قيد المراجعة';

  @override
  String get applicationRejectedDesc =>
      'تم رفض طلبك. يمكنك تعديل ملفك الشخصي وإعادة التقديم.';

  @override
  String get applicationPendingDesc =>
      'طلبك قيد المراجعة من قِبل فريقنا. سيتم إخطارك بمجرد اتخاذ القرار.';

  @override
  String get rejectionReasonLabel => 'السبب:';

  @override
  String get editAndResubmit => 'تعديل وإعادة الإرسال';

  @override
  String get viewApplication => 'عرض الطلب';

  @override
  String get logoutTooltip => 'تسجيل الخروج';

  @override
  String get verifyLabel => 'تحقق';

  @override
  String get verifiedLabel => 'تم التحقق';

  @override
  String get emailVerifiedMsg => 'تم التحقق من البريد الإلكتروني!';

  @override
  String get phoneVerifiedMsg => 'تم التحقق من رقم الهاتف!';

  @override
  String get pleaseVerifyEmail => 'يرجى التحقق من بريدك الإلكتروني';

  @override
  String get pleaseVerifyPhone => 'يرجى التحقق من رقم هاتفك';

  @override
  String get closedLabel => 'مغلق';

  @override
  String daySchedule(String day, String hours) {
    return '$day: $hours';
  }

  @override
  String dayScheduleClosed(String day) {
    return '$day: مغلق';
  }

  @override
  String get editApprovedSectionDesc =>
      'إذا قمت بتعديل هذا القسم، سيعود حسابك إلى حالة الانتظار حتى يتحقق المسؤول منه مرة أخرى. هل أنت متأكد؟';

  @override
  String failedToUploadDocument(String error) {
    return 'فشل رفع المستند: $error';
  }

  @override
  String get failedToLoadDocument => 'فشل تحميل المستند';

  @override
  String get applicationDetailTitle => 'تفاصيل الطلب';

  @override
  String submittedDate(String date) {
    return 'تم التقديم $date';
  }

  @override
  String rejectedReason(String reason) {
    return 'مرفوض: $reason';
  }

  @override
  String get rejectionReasonHint => 'سبب الرفض...';

  @override
  String get noHoursProvided => 'لم يتم تحديد ساعات العمل';

  @override
  String get approvedLabel => 'تمت الموافقة';

  @override
  String get rejectedLabel => 'مرفوض';

  @override
  String sectionApprovedMsg(String section) {
    return 'تمت الموافقة على $section';
  }

  @override
  String sectionRejectedMsg(String section) {
    return 'تم رفض $section';
  }

  @override
  String get businessLicenseDoc => 'ترخيص العمل';

  @override
  String get taxRegistrationDoc => 'التسجيل الضريبي';

  @override
  String notePrefixed(String note) {
    return 'ملاحظة: $note';
  }

  @override
  String addonLine(String name, String price) {
    return '+ $name ($price ج.م)';
  }

  @override
  String get rateYourOrder => 'قيّم طلبك';

  @override
  String rateDialogSubtitle(String restaurantName) {
    return 'كيف كانت تجربتك مع $restaurantName؟';
  }

  @override
  String get tapToRate => 'اضغط للتقييم';

  @override
  String get ratingLabelTerrible => 'سيء جداً';

  @override
  String get ratingLabelBad => 'سيء';

  @override
  String get ratingLabelOkay => 'مقبول';

  @override
  String get ratingLabelGood => 'جيد';

  @override
  String get ratingLabelExcellent => 'ممتاز';

  @override
  String get shareExperienceHint => 'شارك تجربتك (اختياري)';

  @override
  String get pleaseSelectRating => 'يرجى اختيار تقييم.';

  @override
  String get failedSubmitReview => 'فشل إرسال التقييم. حاول مجدداً.';

  @override
  String get skipRating => 'تخطي';

  @override
  String get submitRating => 'إرسال';

  @override
  String get thankYouReview => 'شكراً على تقييمك!';

  @override
  String get alreadyRated => 'تم التقييم';

  @override
  String get customerReviewsTitle => 'تقييمات العملاء';

  @override
  String get noReviewsYet => 'لا يوجد تقييمات بعد. كن أول من يقيّم!';

  @override
  String get rateButtonLabel => 'تقييم';

  @override
  String get phoneVerified => 'تم التحقق من الهاتف!';

  @override
  String get phoneVerifiedSuccessfully => 'تم التحقق من رقم هاتفك بنجاح!';

  @override
  String get phoneAlreadyRegistered =>
      'رقم الهاتف هذا مسجل بالفعل. يرجى تسجيل الدخول بدلاً من ذلك.';

  @override
  String get sessionExpired => 'انتهت الجلسة. يرجى طلب رمز جديد.';

  @override
  String get invalidPhoneNumber => 'تنسيق رقم الهاتف غير صالح.';

  @override
  String get invalidAppCredential =>
      'التحقق من الهاتف غير متاح الآن. يرجى المحاولة لاحقاً أو التواصل مع الدعم.';

  @override
  String get pending => 'قيد الانتظار';

  @override
  String get inactive => 'غير نشط';

  @override
  String get suspended => 'موقوف';

  @override
  String get banned => 'محظور';

  @override
  String get profileImage => 'صورة الملف الشخصي';

  @override
  String get filterByType => 'تصفية حسب النوع';

  @override
  String get refreshTooltip => 'تحديث';

  @override
  String pendingTab(int count) {
    return 'قيد الانتظار ($count)';
  }

  @override
  String approvedTab(int count) {
    return 'مقبول ($count)';
  }

  @override
  String rejectedTab(int count) {
    return 'مرفوض ($count)';
  }

  @override
  String get noPendingApplications => 'لا توجد طلبات معلقة';

  @override
  String get noApprovedApplications => 'لا توجد طلبات مقبولة';

  @override
  String get noRejectedApplications => 'لا توجد طلبات مرفوضة';

  @override
  String get unknownDriver => 'سائق غير معروف';

  @override
  String get unknownRestaurantLabel => 'مطعم غير معروف';

  @override
  String rejectionReasonPrefix(String reason) {
    return 'السبب: $reason';
  }

  @override
  String get rejectionReasonBodyHint =>
      'يرجى تقديم سبب الرفض. سيتم عرضه للمتقدم.';

  @override
  String get rejectionReasonInputHint => 'سبب الرفض...';

  @override
  String get searchHint => 'بحث...';

  @override
  String get adminPanelLabel => 'لوحة الإدارة';

  @override
  String get driverApplicationsTitle => 'طلبات السائقين';

  @override
  String vendorApplicationsTitle(String vendorType) {
    return 'طلبات $vendorType';
  }

  @override
  String get searchByNameEmailPhone => 'بحث بالاسم أو البريد أو الهاتف...';

  @override
  String get analyticsInsights => 'التحليلات والرؤى';

  @override
  String get totalUsersLabel => 'إجمالي المستخدمين';

  @override
  String get totalOrdersLabel => 'إجمالي الطلبات';

  @override
  String get totalRevenueLabel => 'إجمالي الإيرادات';

  @override
  String get avgRevenueDay => 'متوسط الإيراد / يوم';

  @override
  String get userDistribution => 'توزيع المستخدمين';

  @override
  String get noUserData => 'لا توجد بيانات مستخدمين';

  @override
  String get orderStatusBreakdown => 'تفصيل حالات الطلبات';

  @override
  String get noOrderData => 'لا توجد بيانات طلبات';

  @override
  String get dailyRevenueTrend => 'اتجاه الإيراد اليومي';

  @override
  String get noRevenueData => 'لا توجد بيانات إيراد';

  @override
  String get orderManagementTitle => 'إدارة الطلبات';

  @override
  String get allOrdersLabel => 'جميع الطلبات';

  @override
  String get dateRangeLabel => 'النطاق الزمني';

  @override
  String get reportGenerationTitle => 'إنشاء التقارير';

  @override
  String get salesReport => 'تقرير المبيعات';

  @override
  String get userReport => 'تقرير المستخدمين';

  @override
  String get restaurantReport => 'تقرير المطاعم';

  @override
  String get orderReport => 'تقرير الطلبات';

  @override
  String generateDetailedReport(String report) {
    return 'إنشاء $report تفصيلي';
  }

  @override
  String get customerNameLabel => 'اسم العميل';

  @override
  String get numberOfItemsLabel => 'عدد العناصر';

  @override
  String get reportTypeLabel => 'نوع التقرير';

  @override
  String get startDateLabel => 'تاريخ البدء';

  @override
  String get endDateLabel => 'تاريخ الانتهاء';

  @override
  String get restaurantNameLabel => 'اسم المطعم';

  @override
  String get categoryLabel => 'الفئة';

  @override
  String get ratingLabel15 => 'التقييم (1-5)';

  @override
  String get cuisineTypesSection => 'أنواع المطابخ';

  @override
  String get noCuisineTypesYet =>
      'لا توجد أنواع مطابخ بعد. اضغط \"إضافة\" لإنشاء واحد.';

  @override
  String get supermarketSectionsTitle => 'أقسام السوبرماركت';

  @override
  String get pharmacySectionsTitle => 'أقسام الصيدلية';

  @override
  String get noSectionsYet => 'لا توجد أقسام بعد. اضغط \"إضافة\" لإنشاء واحد.';

  @override
  String get addSupermarketSection => 'إضافة قسم سوبرماركت';

  @override
  String get addPharmacySection => 'إضافة قسم صيدلية';

  @override
  String get nameEnglishField => 'الاسم (بالإنجليزية) *';

  @override
  String get nameArabicField => 'الاسم (بالعربية) *';

  @override
  String get nameEnglishHint => 'مثال: إيطالي';

  @override
  String get nameArabicHint => 'مثال: إيطالي';

  @override
  String get tapToUploadImageOptional => 'اضغط لرفع صورة (اختياري)';

  @override
  String get profileInformationSection => 'معلومات الملف الشخصي';

  @override
  String get accountDetailsSection => 'تفاصيل الحساب';

  @override
  String get linkedApplicationsSection => 'الطلبات المرتبطة';

  @override
  String get provideRejectionReason => 'قدم سبب الرفض الذي سيراه المستخدم:';

  @override
  String get rejectFieldHint => 'مثال: الصورة غير واضحة، يرجى إعادة الرفع';

  @override
  String get emailLabel2 => 'البريد الإلكتروني';

  @override
  String get phoneLabel => 'الهاتف';

  @override
  String get addressLabel2 => 'العنوان';

  @override
  String get accountTypeLabel => 'نوع الحساب';

  @override
  String get joinedLabel => 'انضم';

  @override
  String get lastUpdatedLabel => 'آخر تحديث';

  @override
  String get appliedLabel => 'تقدم بطلب';

  @override
  String get approvedLabel2 => 'مقبول';

  @override
  String get globalRejectionReasonLabel => 'سبب الرفض العام';

  @override
  String get driverLabel2 => 'سائق';

  @override
  String get restaurantLabel2 => 'مطعم';

  @override
  String get applicationLabel => 'طلب';

  @override
  String get submittedLabel => 'تم التقديم';

  @override
  String get quickActionAddUser => 'إضافة مستخدم جديد';

  @override
  String get quickActionGenerateReport => 'إنشاء تقرير';

  @override
  String get quickActionManageRestaurants => 'إدارة المطاعم';

  @override
  String get quickActionSystemSettings => 'إعدادات النظام';

  @override
  String deleteOrderConfirm(String orderId) {
    return 'هل أنت متأكد من حذف الطلب $orderId؟';
  }

  @override
  String deleteRestaurantConfirm(String name) {
    return 'هل أنت متأكد من حذف $name؟';
  }

  @override
  String deleteUserConfirm(String name) {
    return 'هل أنت متأكد من حذف $name؟';
  }

  @override
  String deleteItemType(String itemType) {
    return 'حذف $itemType';
  }

  @override
  String deleteItemConfirm(String name) {
    return 'هل أنت متأكد من حذف \"$name\"؟ لا يمكن التراجع عن هذا الإجراء.';
  }

  @override
  String get changeUserStatusTitle => 'تغيير حالة المستخدم';

  @override
  String get changeUserRoleTitle => 'تغيير دور المستخدم';

  @override
  String get updateOrderStatusTitle => 'تحديث حالة الطلب';

  @override
  String get updateRestaurantStatusTitle => 'تحديث حالة المطعم';

  @override
  String get statusLabel => 'الحالة';

  @override
  String get roleLabel => 'الدور';

  @override
  String get comingSoonSuffix => '— قريبًا';

  @override
  String get platformFeeDescription => 'نسبة رسوم المنصة المطبقة على الطلبات';

  @override
  String get navDashboardTitle => 'نظرة عامة على لوحة التحكم';

  @override
  String get navDashboardSubtitle =>
      'مرحبًا بعودتك! إليك ما يحدث في منصتك اليوم.';

  @override
  String get navUserManagementTitle => 'إدارة المستخدمين';

  @override
  String get navUserManagementSubtitle =>
      'إدارة حسابات المستخدمين والأدوار والصلاحيات';

  @override
  String get navAnalyticsTitle => 'التحليلات والتقارير';

  @override
  String get navAnalyticsSubtitle => 'تحليلات مفصلة ورؤى';

  @override
  String get navReviewDriversTitle => 'مراجعة السائقين';

  @override
  String get navReviewDriversSubtitle => 'مراجعة وإدارة طلبات السائقين';

  @override
  String get navReviewRestaurantsTitle => 'مراجعة المطاعم';

  @override
  String get navReviewRestaurantsSubtitle => 'مراجعة وإدارة طلبات المطاعم';

  @override
  String get navReviewSupermarketsTitle => 'مراجعة السوبرماركت';

  @override
  String get navReviewSupermarketsSubtitle => 'مراجعة وإدارة طلبات السوبرماركت';

  @override
  String get navReviewPharmaciesTitle => 'مراجعة الصيدليات';

  @override
  String get navReviewPharmaciesSubtitle => 'مراجعة وإدارة طلبات الصيدليات';

  @override
  String get navReviewBookstoresTitle => 'مراجعة المكتبات';

  @override
  String get navReviewBookstoresSubtitle => 'مراجعة وإدارة طلبات المكتبات';

  @override
  String get navReviewHomeFurnishingTitle => 'مراجعة الأثاث والمفروشات';

  @override
  String get navReviewHomeFurnishingSubtitle =>
      'مراجعة وإدارة طلبات الأثاث والمفروشات';

  @override
  String get navSystemSettingsTitle => 'إعدادات النظام';

  @override
  String get navSystemSettingsSubtitle => 'تكوين إعدادات المنصة والتفضيلات';

  @override
  String get navAdminManagementTitle => 'إدارة المسؤولين';

  @override
  String get navAdminManagementSubtitle => 'إدارة حسابات المسؤولين';

  @override
  String get pendingVerification => 'في انتظار التحقق';

  @override
  String get userTypeAdmin => 'مسؤول';

  @override
  String get userTypeSuperAdmin => 'مسؤول أعلى';

  @override
  String get userTypeRestaurant => 'مطعم';

  @override
  String get userTypeCustomer => 'عميل';

  @override
  String get userTypeDriver => 'سائق';

  @override
  String get statTotalUsers => 'إجمالي المستخدمين';

  @override
  String get statTotalOrders => 'إجمالي الطلبات';

  @override
  String get statTotalRevenue => 'إجمالي الإيرادات';

  @override
  String get statPendingOrders => 'الطلبات المعلقة';

  @override
  String serviceFeeLabel(String percent) {
    return 'رسوم الخدمة ($percent%)';
  }

  @override
  String get serviceFeeSimple => 'رسوم الخدمة';

  @override
  String get continueAsGuest => 'تصفح كضيف';

  @override
  String get signInRequired => 'تسجيل الدخول مطلوب';

  @override
  String get signInToAction => 'يرجى تسجيل الدخول لـ';

  @override
  String get maybeLater => 'ربما لاحقاً';

  @override
  String get viewProfile => 'عرض ملفك الشخصي';

  @override
  String get viewOrders => 'عرض طلباتك';

  @override
  String get paymentStaleCartTitle => 'تم تحديث السلة';

  @override
  String get paymentStaleCartDescription =>
      'بعض العناصر في سلة التسوق قد تغيرت. يرجى المراجعة والتأكيد.';

  @override
  String get paymentStaleCartUpdateCta => 'تحديث السلة والمحاولة مرة أخرى';

  @override
  String get paymentAttemptCapTitle => 'تم حظر الدفع';

  @override
  String get paymentAttemptCapMessage =>
      'لقد وصلت إلى الحد الأقصى لمحاولات الدفع. يرجى المحاولة لاحقاً.';

  @override
  String get paymentAttemptCapNewOrderCta => 'بدء طلب جديد';

  @override
  String get paymentBillingIncompleteTitle => 'أكمل ملفك الشخصي';

  @override
  String get paymentBillingIncompleteMessage =>
      'يرجى إكمال ملف الفوترة قبل إجراء الدفع.';

  @override
  String get paymentRoleForbiddenMessage => 'الدفع بالبطاقة متاح فقط للعملاء.';

  @override
  String get paymentAwaitingConfirmation => 'جاري تأكيد الدفع...';

  @override
  String get paymentSuccessTitle => 'تم الدفع بنجاح';

  @override
  String get paymentSuccessMessage => 'تمت معالجة الدفع بنجاح.';

  @override
  String get paymentFailureGenericMessage =>
      'فشل الدفع. يرجى المحاولة مرة أخرى.';

  @override
  String get payByCard => 'ادفع بالبطاقة';

  @override
  String get securePayment => 'دفع آمن';

  @override
  String get processingPayment => 'جاري معالجة الدفع...';

  @override
  String get locationServicesDisabled => 'خدمات الموقع معطلة.';

  @override
  String get locationPermissionDenied => 'أذونات الموقع مرفوضة.';

  @override
  String get locationPermissionPermanentlyDenied =>
      'أذونات الموقع مرفوضة بشكل دائم.';

  @override
  String get failedToGetCurrentLocation => 'فشل الحصول على الموقع الحالي.';

  @override
  String get loadingLocation => 'جاري تحميل الموقع...';

  @override
  String get selectedLocation => 'الموقع المحدد';

  @override
  String get statusSearching => 'جاري البحث عن سائق';

  @override
  String get statusUnassigned => 'لم يتم العثور على سائق';

  @override
  String get recommendedProducts => 'منتجات قد تعجبك';

  @override
  String get gourmetDining => 'طعام فاخر';

  @override
  String get market => 'أسواق';

  @override
  String get cityTravel => 'رحلات';

  @override
  String get wellnessCheck => 'صحة ورعاية';

  @override
  String get curatedReads => 'متجر كتب';

  @override
  String get cozySpaces => 'أثاث منزلي';

  @override
  String supportEmailSubject(String appName, String orderId) {
    return 'دعم $appName (طلب رقم $orderId)';
  }

  @override
  String supportEmailBody(String orderId) {
    return 'مرحباً، أحتاج إلى مساعدة بخصوص الطلب رقم $orderId.';
  }

  @override
  String get addressDetailsTitle => 'تفاصيل العنوان';

  @override
  String get areaLabel => 'المنطقة';

  @override
  String get typeApartment => 'شقة';

  @override
  String get typeVilla => 'فيلا';

  @override
  String get typeOffice => 'مكتب';

  @override
  String get buildingName => 'اسم المبنى';

  @override
  String get villaNameNumber => 'رقم / اسم الفيلا';

  @override
  String get buildingCompany => 'اسم المبنى / الشركة';

  @override
  String get apartmentNumber => 'رقم الشقة';

  @override
  String get officeNumber => 'رقم المكتب';

  @override
  String get floorOptional => 'الدور (اختياري)';

  @override
  String get street => 'الشارع';

  @override
  String get mobilePhoneNumber => 'رقم الهاتف الجوال';

  @override
  String get uniqueLandmark => 'علامة مميزة (اختياري)';

  @override
  String get confirmAddressDetails => 'تأكيد تفاصيل العنوان';

  @override
  String get phoneRequiredError => 'رقم الهاتف مطلوب';

  @override
  String get phoneLengthError => 'رقم الهاتف غير صحيح';

  @override
  String get fieldRequiredError => 'هذا الحقل مطلوب';

  @override
  String get underMaintenanceTitle => 'تحت الصيانة';

  @override
  String get underMaintenanceMessage =>
      'تطبيق زد سبيد قيد الصيانة المجدولة حالياً لتحسين أنظمتنا. سنعود للعمل في أقرب وقت ممكن.';

  @override
  String get checkBackSoon => 'يرجى التحقق مرة أخرى قريباً!';

  @override
  String get onlySuperAdminCanToggleMaintenance =>
      'يمكن للمسؤول المتميز فقط تفعيل وضع الصيانة';

  @override
  String get onboardingTitle1 => 'توصيل سريع وموثوق';

  @override
  String get onboardingSub1 =>
      'احصل على طعامك، وبقالتك، واحتياجاتك الأساسية واصلة لباب بيتك في دقائق.';

  @override
  String get onboardingTitle2 => 'خدمات متنوعة';

  @override
  String get onboardingSub2 =>
      'تصفح أفضل المطاعم، والصيدليات، والكتب، وخيارات النقل، والمزيد غير ذلك.';

  @override
  String get onboardingTitle3 => 'تتبع في الوقت الفعلي';

  @override
  String get onboardingSub3 =>
      'تتبع مندوبك مباشرة على الخريطة وكن على علم بكل خطوة حتى وصول طلبك.';

  @override
  String get onboardingSkip => 'تخطي';

  @override
  String get onboardingNext => 'التالي';

  @override
  String get onboardingGetStarted => 'ابدأ الآن';

  @override
  String get onboardingLoginSignup => 'تسجيل الدخول / إنشاء حساب';

  @override
  String get onboardingGuest => 'المتابعة كزائر';

  @override
  String get meatAndProteins => 'لحوم وبروتينات';

  @override
  String get clothes => 'ملابس';

  @override
  String get buyAndSell => 'بيع واشتري';

  @override
  String get electronics => 'أجهزة إلكترونية';

  @override
  String get bookstore => 'مكتبة وقرطاسية';

  @override
  String get homeFurnishing => 'الأثاث والمفروشات';

  @override
  String get meatAndProteinsSubtitle =>
      'لحوم طازجة، دواجن، أسماك ومنتجات بروتينية';

  @override
  String get clothesSubtitle => 'ملابس رجالية، نسائية، أطفال ومستلزمات الموضة';

  @override
  String get buyAndSellSubtitle =>
      'سوق متكامل لبيع وشراء السلع الجديدة والمستعملة';

  @override
  String get electronicsSubtitle => 'هواتف ذكية، حواسيب، شاشات وأجهزة منزلية';

  @override
  String get errorLoadingMeatAndProteins => 'حدث خطأ أثناء تحميل محلات اللحوم';

  @override
  String get errorLoadingClothes => 'حدث خطأ أثناء تحميل محلات الملابس';

  @override
  String get errorLoadingBuyAndSell => 'حدث خطأ أثناء تحميل المنتجات';

  @override
  String get errorLoadingElectronics =>
      'حدث خطأ أثناء تحميل الأجهزة الإلكترونية';

  @override
  String get searchMeatAndProteins => 'ابحث عن لحوم، دواجن، أسماك...';

  @override
  String get searchClothes => 'ابحث عن ملابس، أحذية، إكسسوارات...';

  @override
  String get searchBuyAndSell => 'ابحث في سوق بيع واشتري...';

  @override
  String get searchElectronics => 'ابحث عن هواتف، حواسيب، أجهزة...';

  @override
  String get noMeatAndProteinsFound => 'لم يتم العثور على محلات لحوم';

  @override
  String get noClothesFound => 'لم يتم العثور على محلات ملابس';

  @override
  String get noBuyAndSellFound => 'لم يتم العثور على منتجات';

  @override
  String get noElectronicsFound => 'لم يتم العثور على محلات إلكترونيات';

  @override
  String get supportChats => 'محادثات الدعم';

  @override
  String get replyToCustomerSupport =>
      'الرد على استفسارات الدعم المباشر للعملاء';

  @override
  String get activeSupportChats => 'محادثات الدعم النشطة';

  @override
  String get noSupportChats => 'لا توجد محادثات دعم متاحة';

  @override
  String get closeChat => 'إغلاق المحادثة';

  @override
  String get reopenChat => 'إعادة فتح المحادثة';

  @override
  String get chatClosed => 'تم إغلاق المحادثة';

  @override
  String get chatReopened => 'تم إعادة فتح المحادثة';

  @override
  String get supportAgent => 'وكيل الدعم';

  @override
  String get connectingToSupport => 'جاري الاتصال بالدعم...';

  @override
  String get ticketClosed => 'تذكرة الدعم هذه مغلقة.';

  @override
  String get activeDrivers => 'السائقين النشطين';

  @override
  String get onboardingApplications => 'طلبات الانضمام';

  @override
  String get vehicleClassification => 'تصنيف المركبة';

  @override
  String get adjustBalance => 'تعديل الرصيد';

  @override
  String get activeDriversSearchPlaceholder =>
      'البحث عن السائقين النشطين بالاسم، البريد الإلكتروني، الهاتف...';

  @override
  String get applicationsTitle => 'الطلبات والانضمام';

  @override
  String get applicationsSubtitle => 'مراجعة طلبات الانضمام للسائقين والمزودين';

  @override
  String get driversTab => 'السائقين';

  @override
  String get vendorsTab => 'المزودين';

  @override
  String get allCategoriesFilter => 'كل الفئات';

  @override
  String get promoFreeDeliveryApplied => '🎉 تم تطبيق توصيل مجاني!';

  @override
  String get promoApplied => 'تم تطبيق رمز الخصم!';

  @override
  String get promoInvalid => 'رمز خصم غير صحيح. يرجى المحاولة مرة أخرى.';

  @override
  String get promoInactive => 'رمز الخصم هذا لم يعد نشطاً.';

  @override
  String get promoExpired => 'انتهت صلاحية رمز الخصم هذا.';

  @override
  String get promoMaxUsageReached => 'وصل رمز الخصم لجميع استخداماته المتاحة.';

  @override
  String get promoUserLimitReached => 'لقد استخدمت رمز الخصم هذا من قبل.';

  @override
  String promoMinOrderNotMet(String amount) {
    return 'الحد الأدنى للطلب لاستخدام الكود هو $amount جنيه.';
  }

  @override
  String get promoWrongRestaurant => 'رمز الخصم هذا غير سارٍ لهذا المطعم.';

  @override
  String promoPercentageDiscountApplied(String percent, String amount) {
    return '🎉 تم تطبيق خصم $percent%! (وفرت $amount جنيه)';
  }

  @override
  String promoFixedDiscountApplied(String amount) {
    return '🎉 تم تطبيق خصم بقيمة $amount جنيه!';
  }

  @override
  String get placeOrderCalculating => 'تأكيد الطلب — جاري الحساب...';

  @override
  String placeOrderAndPay(String amount) {
    return 'تأكيد الطلب والدفع — $amount جنيه';
  }

  @override
  String get usersTab => 'المستخدمين';

  @override
  String get manageActiveRestaurantsSubtitle => 'إدارة المطاعم والأسواق النشطة';

  @override
  String get transportSystemTitle => 'نظام النقل';

  @override
  String get transportTab => 'النقل';

  @override
  String get transportSystemSubtitle => 'خريطة مباشرة وإحصائيات الرحلات';

  @override
  String get applicationsTab => 'الطلبات';

  @override
  String get analyticsTab => 'التحليلات';

  @override
  String get settingsTab => 'الإعدادات';

  @override
  String get promoCodesTitle => 'الأكواد الترويجية';

  @override
  String get promosTab => 'العروض';

  @override
  String get promoCodesSubtitle => 'إدارة أكواد الخصم';

  @override
  String get settlementsTitle => 'التسويات';

  @override
  String get settlementsTab => 'التسويات';

  @override
  String get settlementsSubtitle => 'مستحقات المطاعم والسائقين';

  @override
  String get supportTab => 'الدعم';

  @override
  String get adminManagementTab => 'إدارة المسؤولين';

  @override
  String get operationsTab => 'العمليات';

  @override
  String get financialsTab => 'الماليات';

  @override
  String get analyticsAndHistoryTab => 'التحليلات والسجل';

  @override
  String get activeRides => 'الرحلات النشطة';

  @override
  String get recentTrips => 'الرحلات الأخيرة';

  @override
  String get noRidesRegisteredToday => 'لا توجد رحلات مسجلة اليوم';

  @override
  String statusAndFare(String status, String fare) {
    return 'الحالة: $status | الأجرة: $fare جنيه';
  }

  @override
  String deliveryFeeFixed(String amount) {
    return 'ثابت: $amount جنيه';
  }

  @override
  String deliveryFeeFormula(String base, String perKm) {
    return 'معادلة: $base + $perKm/كم';
  }

  @override
  String deliveryFeeTiers(String count) {
    return 'شرائح: $count فئات';
  }

  @override
  String get broadcastTabTitle => 'مركز البث المباشر والإشعارات';

  @override
  String get broadcastTabSubtitle =>
      'إرسال إشعارات عامة ومستهدفة للمستخدمين حسب المنطقة والنوع';

  @override
  String get targetAudienceLabel => 'الجمهور المستهدف';

  @override
  String get targetAllUsers => 'جميع المستخدمين';

  @override
  String get targetCustomers => 'العملاء فقط';

  @override
  String get targetDrivers => 'السائقون فقط';

  @override
  String get targetVendors => 'أصحاب المتاجر والمطاعم';

  @override
  String get targetAdmins => 'المشرفون فقط';

  @override
  String get locationAreaLabel => 'فلترة حسب المنطقة والموقع';

  @override
  String get allLocations => 'جميع المناطق والمدن';

  @override
  String get specificArea => 'منطقة / مدينة محددة';

  @override
  String get areaHint => 'مثال: القاهرة، الإسكندرية، المعادي، مدينة نصر';

  @override
  String get geoRadiusLabel => 'نطاق النطاق الجغرافي (نصف القطر)';

  @override
  String radiusKmLabel(String km) {
    return 'نصف القطر: $km كم';
  }

  @override
  String get notificationContent => 'محتوى الإشعار والترجمة';

  @override
  String get notificationTitleEn => 'العنوان (بالإنجليزية)';

  @override
  String get notificationBodyEn => 'نص الإشعار (بالإنجليزية)';

  @override
  String get notificationTitleAr => 'العنوان (بالعربية)';

  @override
  String get notificationBodyAr => 'نص الإشعار (بالعربية)';

  @override
  String get imageUrlLabel => 'رابط صورة الإشعار (اختياري)';

  @override
  String get targetScreenLabel => 'الشاشة / الإجراء عند الضغط';

  @override
  String get screenNone => 'إشعار عام (بدون إجراء)';

  @override
  String get screenPromo => 'شاشة كود الخصم';

  @override
  String get screenVendor => 'تفاصيل المتجر / المطعم';

  @override
  String get screenCategory => 'تصفح القسم';

  @override
  String get screenCustomUrl => 'رابط خارجي مخصص';

  @override
  String get attachedPromoCode => 'كود الخصم المرفق';

  @override
  String get targetEntityIdLabel => 'معرف العنصر / الرابط الخارجي';

  @override
  String get deliveryConfigLabel => 'إعدادات التسليم والأولوية';

  @override
  String get sendFcmPush => 'إرسال إشعار لحظي (Push Notification)';

  @override
  String get storeInAppInbox => 'حفظ في صندوق إشعارات التطبيق';

  @override
  String get priorityLabel => 'أولوية الإشعار';

  @override
  String get priorityHigh => 'عالية (شريط تنبيه بارز)';

  @override
  String get priorityNormal => 'عادية';

  @override
  String get soundLabel => 'صوت الإشعار';

  @override
  String get soundDefault => 'الصوت الافتراضي للنظام';

  @override
  String get soundAlert => 'صوت تنبيه مرتفع';

  @override
  String get soundSilent => 'صامت';

  @override
  String get presetTemplates => 'قوالب سريعة جاهزة';

  @override
  String get templatePromoCode => 'كود خصم وترويج';

  @override
  String get templateSystemUpdate => 'تحديث وصيانة التطبيق';

  @override
  String get templateFlashSale => 'عروض وتخفيضات سريعة';

  @override
  String get templateAreaAlert => 'عروض خاصة لمنطقة محددة';

  @override
  String get previewHeader => 'معاينة الإشعار على الشاشة';

  @override
  String get sendBroadcastButton => 'إرسال الإشعار الجماعي';

  @override
  String get confirmBroadcastTitle => 'تأكيد إرسال الإشعار';

  @override
  String get confirmBroadcastBody =>
      'هل أنت ألكيد من إرسال هذا الإشعار لجميع المستخدمين المستهدفين؟';

  @override
  String get broadcastSuccessTitle => 'تم إرسال الإشعار بنجاح!';

  @override
  String targetedUsersCount(String count) {
    return 'المستخدمون المستهدفون: $count';
  }

  @override
  String pushDeliveredCount(String count) {
    return 'إشعارات الهاتف المباشرة: $count';
  }

  @override
  String pushFailedCount(String count) {
    return 'فشل التسليم: $count';
  }

  @override
  String inAppSavedCount(String count) {
    return 'المحفوظة في صندوق الإشعارات: $count';
  }

  @override
  String get setRadiusCenterMap => 'تحديد منتصف القطر على الخريطة';

  @override
  String radiusCenterSelected(Object lat, Object lng) {
    return 'منتصف القطر المحدد: $lat, $lng';
  }

  @override
  String get selectTargetAreaMap => 'تحديد المنطقة على الخريطة';

  @override
  String get audienceSpecificUser => 'مستخدم محدد';

  @override
  String get targetUserIdLabel =>
      'المستخدم المستهدف (المعرف / الهاتف / البريد)';

  @override
  String get targetUserIdHint =>
      'أدخل معرف UID، رقم الهاتف، أو البريد الإلكتروني';

  @override
  String get filterAll => 'الكل';

  @override
  String get filterUnread => 'غير مقروء';

  @override
  String get filterOrders => 'الطلبات';

  @override
  String get filterPromos => 'العروض';

  @override
  String unreadCountNotice(int count) {
    return 'لديك $count إشعار غير مقروء';
  }

  @override
  String get allNotificationsMarkedRead => 'تم تحديد جميع الإشعارات كمقروءة';

  @override
  String get noUnreadNotifications => 'لا توجد إشعارات غير مقروءة';

  @override
  String get noOrderNotifications => 'لا توجد إشعارات متعلقة بالطلبات';

  @override
  String get noPromoNotifications => 'لا توجد عروض أو خصومات حالياً';

  @override
  String get allNotificationsWillAppear =>
      'ستظهر جميع التحديثات والعروض هنا فور وصولها';

  @override
  String get viewAllNotifications => 'عرض جميع الإشعارات';

  @override
  String promoCodeCopied(String code) {
    return 'تم نسخ كود الخصم: $code';
  }

  @override
  String get selectedOptionUnavailable => 'الخيار المحدد غير متاح حالياً';

  @override
  String get masterLogisticsKpiDashboard =>
      'لوحة التحكم الرئيسية لمؤشرات أداء اللوجستيات';

  @override
  String get kpiDashboardSubtitle =>
      'مقاييس لحظية، الأرباح، مدفوعات السائقين والحسابات المالية للمطاعم';

  @override
  String get exportExcel => 'تصدير إكسل';

  @override
  String get exportPdfPrint => 'تصدير PDF / طباعة';

  @override
  String get excelExportedSuccess => 'تم تصدير الإكسل بنجاح';

  @override
  String get exportFailed => 'فشل التصدير';

  @override
  String get searchOrderIdCustomerHint => 'بحث برقم الطلب / العميل...';

  @override
  String get yesterday => 'أمس';

  @override
  String get last7Days => 'آخر 7 أيام';

  @override
  String get customDateRange => 'نطاق تاريخ مخصص';

  @override
  String get allVendorsCombined => 'جميع المطاعم (المجمع)';

  @override
  String get allRidersCombined => 'جميع السائقين (المجمع)';

  @override
  String get allPaymentMethods => 'جميع طرق الدفع';

  @override
  String get platformDeliveryFeeToggle => 'رسوم التوصيل للمنصة 15%';

  @override
  String get restaurantGrossSales => 'إجمالي مبيعات المطاعم';

  @override
  String get subtotalAcrossOrders => 'المجموع الفرعي للطلبات';

  @override
  String get totalDeliveryFeesCollected => 'إجمالي رسوم التوصيل';

  @override
  String get collectedFromClients => 'تم جمعها من العملاء';

  @override
  String get tripsCompleted => 'الرحلات المكتملة';

  @override
  String get deliveredOrdersSubtitle => 'الطلبات المسلمة';

  @override
  String get activeOrdersKpi => 'الطلبات النشطة';

  @override
  String get inProgressSubtitle => 'قيد التنفيذ';

  @override
  String get rideAcceptanceRate => 'نسبة قبول الرحلات';

  @override
  String get driverResponseRate => 'معدل استجابة السائقين';

  @override
  String get masterNetProfit => 'صافي أرباح المنصة';

  @override
  String get masterCommission => 'عمولة المنصة';

  @override
  String get comm10PlusFee15 => 'العمولة (10%) + رسوم المنصة (15%)';

  @override
  String get comm10Only => 'عمولة الإدارة 10% فقط';

  @override
  String get restaurantFinancialsPayouts => 'المالية ومدفوعات المطاعم';

  @override
  String get noVendorFinancialData => 'لا توجد بيانات مالية للمطاعم';

  @override
  String deliveredOrdersCount(int count) {
    return '$count طلبات مسلّمة';
  }

  @override
  String get netSalesLabel => 'صافي المبيعات';

  @override
  String get adminComm10 => 'عمولة الإدارة (10%)';

  @override
  String get amountDue => 'المبلغ المستحق';

  @override
  String get riderPerformanceEarnings => 'أداء وأرباح السائقين';

  @override
  String get noRiderTripData => 'لا توجد بيانات رحلات للسائقين';

  @override
  String tripsCompletedCount(int count) {
    return '$count رحلات مكتملة';
  }

  @override
  String get totalFeesLabel => 'إجمالي الرسوم';

  @override
  String get riderShare85 => 'حصة السائق (85%)';

  @override
  String get platformCut15 => 'حصة المنصة (15%)';

  @override
  String get tripOrderDetailedRecords => 'السجلات التفصيلية للطلبات والرحلات';

  @override
  String totalOrdersCountLabel(int count) {
    return 'الإجمالي: $count طلبات';
  }

  @override
  String get noOrdersMatchFilter => 'لا توجد طلبات تطابق الفلتر الحالي';

  @override
  String get tableColDate => 'التاريخ';

  @override
  String get tableColOrderTripId => 'رقم الطلب / الرحلة';

  @override
  String get tableColStatus => 'الحالة';

  @override
  String get tableColChangedBy => 'تم بواسطة';

  @override
  String get tableColPayment => 'الدفع';

  @override
  String get tableColSubtotal => 'المجموع الفرعي';

  @override
  String get tableColDeliveryFee => 'رسوم التوصيل';

  @override
  String get tableColRiderCut => 'حصة السائق (85%)';

  @override
  String get tableColAdminComm => 'عمولة الإدارة (10%)';

  @override
  String get tableColPlatformFee => 'رسوم المنصة (15%)';

  @override
  String get actorCustomer => 'العميل';

  @override
  String get actorVendor => 'المتجر';

  @override
  String get actorDriver => 'السائق';

  @override
  String get actorAdmin => 'المسؤول';

  @override
  String get actorSystem => 'النظام';

  @override
  String pageXOfY(int page, int total) {
    return 'صفحة $page من $total';
  }

  @override
  String get customerIdLabel => 'رقم العميل';

  @override
  String get taxLabel => 'الضريبة';

  @override
  String orderDetailsTitleParam(String id) {
    return 'تفاصيل الطلب $id';
  }

  @override
  String orderIdParam(String id) {
    return 'رقم الطلب: $id';
  }

  @override
  String customerIdParam(String id) {
    return 'رقم العميل: $id';
  }

  @override
  String statusParam(String status) {
    return 'الحالة: $status';
  }

  @override
  String changedByParam(String actor) {
    return 'تم بواسطة: $actor';
  }

  @override
  String cancelledByParam(String actor) {
    return 'تم الإلغاء بواسطة: $actor';
  }

  @override
  String cancellationReasonParam(String reason) {
    return 'سبب الإلغاء: $reason';
  }

  @override
  String paymentMethodParam(String method) {
    return 'طريقة الدفع: $method';
  }

  @override
  String subtotalParam(String amount) {
    return 'المجموع الفرعي: $amount';
  }

  @override
  String deliveryFeeParam(String amount) {
    return 'رسوم التوصيل: $amount';
  }

  @override
  String taxParam(String amount) {
    return 'الضريبة: $amount';
  }

  @override
  String totalParam(String amount) {
    return 'الإجمالي: $amount';
  }

  @override
  String errorLoadingKpiMetrics(String error) {
    return 'خطأ في تحميل مؤشرات الأداء: $error';
  }

  @override
  String get itemCurrentlyUnavailable => 'هذا العنصر غير متاح حالياً';

  @override
  String get someItemsUnavailableSkipped =>
      'بعض العناصر في هذا الطلب لم تعد متاحة وتم تجاوزها';

  @override
  String get kpiTabTitle => 'مؤشرات اللوجستيات';

  @override
  String get kpiTabShortTitle => 'لوحة KPI';

  @override
  String get kpiTabSubtitle => 'حسابات شاملة للمطاعم، السائقين والأرباح';

  @override
  String get busyModeLabel => 'وضع الانشغال';

  @override
  String get busyModeActive => 'مشغول (الطلبات متوقفة)';

  @override
  String get busyModeInactive => 'متاح (يستقبل طلبات)';

  @override
  String get busyModeDesc => 'إيقاف استلام الطلبات الجديدة مؤقتاً';

  @override
  String get vendorCurrentlyBusy =>
      'المتجر مشغول حالياً وغير قادر على استقبال الطلبات.';

  @override
  String get notifyMeWhenAvailable => 'نبهني عند العودة للعمل';

  @override
  String get willNotifyWhenAvailable =>
      'سنقوم بتنبيهك فور عودة المتجر للعمل خلال الساعتين القادمتين! 🔔';

  @override
  String get alreadySubscribedNotify => 'سيصلك تنبيه فور عودة المتجر للعمل.';

  @override
  String get storyApprovalStatusPending => 'في انتظار الموافقة';

  @override
  String get storyApprovalStatusApproved => 'مقبول ومباشر';

  @override
  String get storyApprovalStatusRejected => 'مرفوض';

  @override
  String get storySubmittedAwaitingApproval =>
      'تم رفع القصة وهي في انتظار موافقة الإدارة!';

  @override
  String get storiesApprovalTabTitle => 'اعتماد القصص';

  @override
  String get storiesApprovalTabShort => 'القصص';

  @override
  String get addDeliveryArea => 'إضافة منطقة على الخريطة 📍';

  @override
  String get configuredDeliveryAreas => 'مناطق التوصيل المحددة على الخريطة';

  @override
  String get areaNameLabel => 'اسم المنطقة / الزون';

  @override
  String get thresholdKmLabel => 'مسافة الحد الأساسي (كم)';

  @override
  String get extraKmRateLabel => 'سعر الكيلومتر بعد الحد (ج.م/كم)';

  @override
  String get noAreasConfigured => 'لم يتم إضافة مناطق خريطة مخصصة بعد.';

  @override
  String get deleteArea => 'حذف المنطقة';

  @override
  String get editArea => 'تعديل المنطقة';

  @override
  String get areaRulesInfo =>
      'الطلبات داخل هذه المنطقة تحسب الرسوم الأساسية حتى الحد الأساسي + سعر الكم الإضافي.';
}
