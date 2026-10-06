// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:cloud_firestore/cloud_firestore.dart' as _i974;
import 'package:firebase_auth/firebase_auth.dart' as _i59;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:shared_preferences/shared_preferences.dart' as _i460;

import '../features/admin/cubit/admin_analytics_cubit.dart' as _i702;
import '../features/admin/cubit/admin_dashboard_cubit.dart' as _i379;
import '../features/admin/cubit/admin_management_cubit.dart' as _i1059;
import '../features/admin/cubit/admin_orders_cubit.dart' as _i431;
import '../features/admin/cubit/admin_reports_cubit.dart' as _i294;
import '../features/admin/cubit/admin_settings_cubit.dart' as _i1;
import '../features/admin/cubit/admin_transport_cubit.dart' as _i416;
import '../features/admin/cubit/admin_users_cubit.dart' as _i178;
import '../features/admin/cubit/admin_vendors_cubit.dart' as _i877;
import '../features/admin/datasource/admin_firebase_datasource.dart' as _i99;
import '../features/admin/datasource/audit_log_datasource.dart' as _i509;
import '../features/admin/datasource/settings_datasource.dart' as _i180;
import '../features/admin/model/admin_models.dart' as _i318;
import '../features/admin/repository/admin_repository.dart' as _i741;
import '../features/admin/repository/admin_repository_impl.dart' as _i274;
import '../features/admin/repository/application_repository.dart' as _i944;
import '../features/admin/repository/application_repository_impl.dart' as _i240;
import '../features/auth/cubit/auth_cubit.dart' as _i329;
import '../features/auth/datasource/auth_firebase_datasource.dart' as _i682;
import '../features/auth/datasource/auth_local_datasource.dart' as _i453;
import '../features/auth/repository/auth_repository.dart' as _i16;
import '../features/auth/repository/auth_repository_impl.dart' as _i739;
import '../features/cart/cubit/cart_cubit.dart' as _i291;
import '../features/cart/datasource/cart_firebase_datasource.dart' as _i221;
import '../features/cart/datasource/cart_local_datasource.dart' as _i673;
import '../features/cart/repository/cart_repository.dart' as _i559;
import '../features/cart/repository/cart_repository_impl.dart' as _i202;
import '../features/customer/cubit/customer_order_history_cubit.dart' as _i653;
import '../features/customer/cubit/item_detail_cubit.dart' as _i680;
import '../features/customer/cubit/restaurant_browse_cubit.dart' as _i46;
import '../features/customer/cubit/restaurant_detail_cubit.dart' as _i783;
import '../features/customer/repository/customer_restaurant_repository.dart'
    as _i524;
import '../features/customer/repository/customer_restaurant_repository_impl.dart'
    as _i151;
import '../features/driver/cubit/driver_application_cubit.dart' as _i971;
import '../features/driver/cubit/driver_dashboard_cubit.dart' as _i407;
import '../features/driver/cubit/restaurant_driver_assignment_cubit.dart'
    as _i836;
import '../features/driver/datasource/driver_firebase_datasource.dart' as _i37;
import '../features/driver/repository/driver_repository.dart' as _i1064;
import '../features/driver/repository/driver_repository_impl.dart' as _i313;
import '../features/notification/cubit/notification_cubit.dart' as _i1044;
import '../features/notification/datasource/notification_firebase_datasource.dart'
    as _i131;
import '../features/notification/repository/notification_repository.dart'
    as _i594;
import '../features/notification/repository/notification_repository_impl.dart'
    as _i842;
import '../features/order/cubit/order_tracking_cubit.dart' as _i1066;
import '../features/order/datasource/order_firebase_datasource.dart' as _i249;
import '../features/order/repository/order_repository.dart' as _i136;
import '../features/order/repository/order_repository_impl.dart' as _i315;
import '../features/payment/cubit/payment_cubit.dart' as _i97;
import '../features/payment/datasource/payment_firebase_datasource.dart' as _i2;
import '../features/payment/repository/payment_repository.dart' as _i863;
import '../features/payment/repository/payment_repository_impl.dart' as _i268;
import '../features/restaurant/datasource/cuisine_type_datasource.dart'
    as _i812;
import '../features/restaurant/datasource/menu_firebase_datasource.dart'
    as _i115;
import '../features/restaurant/datasource/restaurant_firebase_datasource.dart'
    as _i1014;
import '../features/restaurant/datasource/vendor_section_datasource.dart'
    as _i276;
import '../features/restaurant/model/menu_item.dart' as _i975;
import '../features/restaurant/repository/restaurant_menu_repository.dart'
    as _i940;
import '../features/restaurant/repository/restaurant_menu_repository_impl.dart'
    as _i1000;
import '../features/restaurant_owner/cubit/restaurant_analytics_cubit.dart'
    as _i790;
import '../features/restaurant_owner/cubit/restaurant_application_cubit.dart'
    as _i645;
import '../features/restaurant_owner/cubit/restaurant_dashboard_cubit.dart'
    as _i370;
import '../features/restaurant_owner/cubit/restaurant_menu_cubit.dart' as _i317;
import '../features/restaurant_owner/cubit/restaurant_orders_cubit.dart'
    as _i218;
import '../features/restaurant_owner/cubit/restaurant_profile_cubit.dart'
    as _i629;
import '../features/restaurant_owner/datasource/restaurant_wallet_datasource.dart'
    as _i797;
import '../features/restaurant_owner/repository/restaurant_wallet_repository.dart'
    as _i432;
import '../features/restaurant_owner/repository/restaurant_wallet_repository_impl.dart'
    as _i701;
import '../features/review/datasource/review_firebase_datasource.dart' as _i699;
import '../features/stories/cubit/customer_stories_cubit.dart' as _i1002;
import '../features/stories/cubit/vendor_stories_cubit.dart' as _i639;
import '../features/stories/repository/story_repository.dart' as _i958;
import '../features/transport/cubit/active_ride_cubit.dart' as _i978;
import '../features/transport/cubit/driver_transport_cubit.dart' as _i171;
import '../features/transport/cubit/transport_booking_cubit.dart' as _i916;
import '../features/transport/datasource/transport_firebase_datasource.dart'
    as _i176;
import '../features/transport/datasource/transport_firebase_datasource_impl.dart'
    as _i401;
import '../features/transport/repository/transport_repository.dart' as _i611;
import '../features/transport/repository/transport_repository_impl.dart'
    as _i619;
import 'app_module.dart' as _i461;
import 'enums/user_enums.dart' as _i207;
import 'services/connectivity_cubit.dart' as _i534;
import 'services/media_compression_service.dart' as _i299;
import 'services/media_upload_service.dart' as _i724;
import 'services/offline_queue_service.dart' as _i1020;
import 'theme/theme_cubit.dart' as _i448;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final appModule = _$AppModule();
    await gh.factoryAsync<_i460.SharedPreferences>(
      () => appModule.prefs,
      preResolve: true,
    );
    gh.factory<_i448.ThemeCubit>(() => _i448.ThemeCubit());
    gh.factory<_i294.AdminReportsCubit>(() => _i294.AdminReportsCubit());
    gh.factory<_i97.PaymentCubit>(() => _i97.PaymentCubit());
    gh.lazySingleton<_i59.FirebaseAuth>(() => appModule.firebaseAuth);
    gh.lazySingleton<_i974.FirebaseFirestore>(
      () => appModule.firebaseFirestore,
    );
    gh.lazySingleton<_i534.ConnectivityCubit>(() => _i534.ConnectivityCubit());
    gh.lazySingleton<_i299.MediaCompressionService>(
      () => _i299.MediaCompressionService(),
    );
    gh.lazySingleton<_i724.MediaUploadService>(
      () => _i724.MediaUploadService(),
    );
    gh.lazySingleton<_i180.SettingsDatasource>(
      () => _i180.SettingsDatasource(),
    );
    gh.lazySingleton<_i453.AuthLocalDatasource>(
      () => _i453.AuthLocalDatasource(),
    );
    gh.lazySingleton<_i673.CartLocalDatasource>(
      () => _i673.CartLocalDatasource(),
    );
    gh.lazySingleton<_i524.CustomerRestaurantRepository>(
      () => _i151.CustomerRestaurantRepositoryImpl(
        restaurantDs: gh<_i1014.RestaurantFirebaseDatasource>(),
        menuDs: gh<_i115.MenuFirebaseDatasource>(),
      ),
    );
    gh.factory<_i1.AdminSettingsCubit>(
      () => _i1.AdminSettingsCubit(
        cuisineDatasource: gh<_i812.CuisineTypeDatasource>(),
        vendorSectionDatasource: gh<_i276.VendorSectionDatasource>(),
        settingsDatasource: gh<_i180.SettingsDatasource>(),
      ),
    );
    gh.factory<_i653.CustomerOrderHistoryCubit>(
      () => _i653.CustomerOrderHistoryCubit(
        orderRepository: gh<_i136.OrderRepository>(),
        auth: gh<_i59.FirebaseAuth>(),
      ),
    );
    gh.lazySingleton<_i863.PaymentRepository>(
      () => _i268.PaymentRepositoryImpl(
        datasource: gh<_i2.PaymentFirebaseDatasource>(),
      ),
    );
    gh.lazySingleton<_i940.RestaurantMenuRepository>(
      () => _i1000.RestaurantMenuRepositoryImpl(
        restaurantDs: gh<_i1014.RestaurantFirebaseDatasource>(),
        menuDs: gh<_i115.MenuFirebaseDatasource>(),
        uploadService: gh<_i724.MediaUploadService>(),
      ),
    );
    gh.factory<_i790.RestaurantAnalyticsCubit>(
      () => _i790.RestaurantAnalyticsCubit(
        orderRepository: gh<_i136.OrderRepository>(),
        restaurantDatasource: gh<_i1014.RestaurantFirebaseDatasource>(),
        auth: gh<_i59.FirebaseAuth>(),
      ),
    );
    gh.factory<_i370.RestaurantDashboardCubit>(
      () => _i370.RestaurantDashboardCubit(
        orderRepository: gh<_i136.OrderRepository>(),
        restaurantDatasource: gh<_i1014.RestaurantFirebaseDatasource>(),
        auth: gh<_i59.FirebaseAuth>(),
      ),
    );
    gh.factory<_i218.RestaurantOrdersCubit>(
      () => _i218.RestaurantOrdersCubit(
        orderRepository: gh<_i136.OrderRepository>(),
        restaurantDatasource: gh<_i1014.RestaurantFirebaseDatasource>(),
        auth: gh<_i59.FirebaseAuth>(),
      ),
    );
    gh.lazySingleton<_i136.OrderRepository>(
      () => _i315.OrderRepositoryImpl(
        datasource: gh<_i249.OrderFirebaseDatasource>(),
      ),
    );
    gh.factory<_i783.RestaurantDetailCubit>(
      () => _i783.RestaurantDetailCubit(
        restaurantId: gh<String>(),
        repository: gh<_i524.CustomerRestaurantRepository>(),
      ),
    );
    gh.lazySingleton<_i682.AuthFirebaseDatasource>(
      () => _i682.AuthFirebaseDatasource(
        auth: gh<_i59.FirebaseAuth>(),
        firestore: gh<_i974.FirebaseFirestore>(),
      ),
    );
    gh.factory<_i680.ItemDetailCubit>(
      () => _i680.ItemDetailCubit(
        item: gh<_i975.MenuItem>(),
        restaurantId: gh<String>(),
        sectionId: gh<String>(),
      ),
    );
    gh.factory<_i46.RestaurantBrowseCubit>(
      () => _i46.RestaurantBrowseCubit(
        repository: gh<_i524.CustomerRestaurantRepository>(),
        cuisineDatasource: gh<_i812.CuisineTypeDatasource>(),
        vendorType: gh<_i207.VendorType>(),
        initialQuery: gh<String>(),
      ),
    );
    gh.lazySingleton<_i16.AuthRepository>(
      () => _i739.AuthRepositoryImpl(
        datasource: gh<_i682.AuthFirebaseDatasource>(),
      ),
    );
    gh.factory<_i645.RestaurantApplicationCubit>(
      () => _i645.RestaurantApplicationCubit(
        authRepo: gh<_i16.AuthRepository>(),
        appRepo: gh<_i944.ApplicationRepository>(),
        uploadService: gh<_i724.MediaUploadService>(),
        cuisineDatasource: gh<_i812.CuisineTypeDatasource>(),
      ),
    );
    gh.lazySingleton<_i1020.OfflineQueueService>(
      () => _i1020.OfflineQueueService(gh<_i460.SharedPreferences>()),
    );
    gh.factory<_i629.RestaurantProfileCubit>(
      () => _i629.RestaurantProfileCubit(
        repository: gh<_i940.RestaurantMenuRepository>(),
        cuisineDatasource: gh<_i812.CuisineTypeDatasource>(),
        ownerId: gh<String>(),
      ),
    );
    gh.lazySingleton<_i291.CartCubit>(
      () => _i291.CartCubit(repository: gh<_i559.CartRepository>()),
    );
    gh.lazySingleton<_i944.ApplicationRepository>(
      () => _i240.ApplicationRepositoryImpl(
        firestore: gh<_i974.FirebaseFirestore>(),
      ),
    );
    gh.lazySingleton<_i741.AdminRepository>(
      () => _i274.AdminRepositoryImpl(
        datasource: gh<_i99.AdminFirebaseDatasource>(),
      ),
    );
    gh.factory<_i317.RestaurantMenuCubit>(
      () => _i317.RestaurantMenuCubit(
        repository: gh<_i940.RestaurantMenuRepository>(),
        restaurantId: gh<String>(),
        vendorType: gh<_i207.VendorType>(),
        cuisineDatasource: gh<_i812.CuisineTypeDatasource>(),
        vendorSectionDatasource: gh<_i276.VendorSectionDatasource>(),
      ),
    );
    gh.lazySingleton<_i99.AdminFirebaseDatasource>(
      () => _i99.AdminFirebaseDatasource(
        firestore: gh<_i974.FirebaseFirestore>(),
      ),
    );
    gh.lazySingleton<_i509.AuditLogDatasource>(
      () => _i509.AuditLogDatasource(firestore: gh<_i974.FirebaseFirestore>()),
    );
    gh.lazySingleton<_i221.CartFirebaseDatasource>(
      () => _i221.CartFirebaseDatasource(
        firestore: gh<_i974.FirebaseFirestore>(),
      ),
    );
    gh.lazySingleton<_i37.DriverFirebaseDatasource>(
      () => _i37.DriverFirebaseDatasource(
        firestore: gh<_i974.FirebaseFirestore>(),
      ),
    );
    gh.lazySingleton<_i131.NotificationFirebaseDatasource>(
      () => _i131.NotificationFirebaseDatasource(
        firestore: gh<_i974.FirebaseFirestore>(),
      ),
    );
    gh.lazySingleton<_i249.OrderFirebaseDatasource>(
      () => _i249.OrderFirebaseDatasource(
        firestore: gh<_i974.FirebaseFirestore>(),
      ),
    );
    gh.lazySingleton<_i2.PaymentFirebaseDatasource>(
      () => _i2.PaymentFirebaseDatasource(
        firestore: gh<_i974.FirebaseFirestore>(),
      ),
    );
    gh.lazySingleton<_i812.CuisineTypeDatasource>(
      () =>
          _i812.CuisineTypeDatasource(firestore: gh<_i974.FirebaseFirestore>()),
    );
    gh.lazySingleton<_i115.MenuFirebaseDatasource>(
      () => _i115.MenuFirebaseDatasource(
        firestore: gh<_i974.FirebaseFirestore>(),
      ),
    );
    gh.lazySingleton<_i1014.RestaurantFirebaseDatasource>(
      () => _i1014.RestaurantFirebaseDatasource(
        firestore: gh<_i974.FirebaseFirestore>(),
      ),
    );
    gh.lazySingleton<_i276.VendorSectionDatasource>(
      () => _i276.VendorSectionDatasource(
        firestore: gh<_i974.FirebaseFirestore>(),
      ),
    );
    gh.lazySingleton<_i797.RestaurantWalletDatasource>(
      () => _i797.RestaurantWalletDatasource(
        firestore: gh<_i974.FirebaseFirestore>(),
      ),
    );
    gh.lazySingleton<_i699.ReviewFirebaseDatasource>(
      () => _i699.ReviewFirebaseDatasource(
        firestore: gh<_i974.FirebaseFirestore>(),
      ),
    );
    gh.factory<_i702.AdminAnalyticsCubit>(
      () => _i702.AdminAnalyticsCubit(repository: gh<_i741.AdminRepository>()),
    );
    gh.factory<_i1059.AdminManagementCubit>(
      () =>
          _i1059.AdminManagementCubit(repository: gh<_i741.AdminRepository>()),
    );
    gh.factory<_i431.AdminOrdersCubit>(
      () => _i431.AdminOrdersCubit(repository: gh<_i741.AdminRepository>()),
    );
    gh.factory<_i877.AdminVendorsCubit>(
      () => _i877.AdminVendorsCubit(repository: gh<_i741.AdminRepository>()),
    );
    gh.factory<_i178.AdminUsersCubit>(
      () => _i178.AdminUsersCubit(
        repository: gh<_i741.AdminRepository>(),
        auditLogDatasource: gh<_i509.AuditLogDatasource>(),
        currentUser: gh<_i318.AppUser>(),
      ),
    );
    gh.lazySingleton<_i329.AuthCubit>(
      () => _i329.AuthCubit(repository: gh<_i16.AuthRepository>()),
    );
    gh.lazySingleton<_i958.StoryRepository>(
      () => _i958.StoryRepository(
        firestore: gh<_i974.FirebaseFirestore>(),
        uploadService: gh<_i724.MediaUploadService>(),
        compressionService: gh<_i299.MediaCompressionService>(),
      ),
    );
    gh.factory<_i416.AdminTransportCubit>(
      () => _i416.AdminTransportCubit(gh<_i974.FirebaseFirestore>()),
    );
    gh.factory<_i971.DriverApplicationCubit>(
      () => _i971.DriverApplicationCubit(
        authRepo: gh<_i16.AuthRepository>(),
        appRepo: gh<_i944.ApplicationRepository>(),
        mediaService: gh<_i724.MediaUploadService>(),
      ),
    );
    gh.lazySingleton<_i176.TransportFirebaseDatasource>(
      () =>
          _i401.TransportFirebaseDatasourceImpl(gh<_i974.FirebaseFirestore>()),
    );
    gh.lazySingleton<_i559.CartRepository>(
      () => _i202.CartRepositoryImpl(
        localDatasource: gh<_i673.CartLocalDatasource>(),
        firebaseDatasource: gh<_i221.CartFirebaseDatasource>(),
        auth: gh<_i59.FirebaseAuth>(),
      ),
    );
    gh.factory<_i1002.CustomerStoriesCubit>(
      () => _i1002.CustomerStoriesCubit(gh<_i958.StoryRepository>()),
    );
    gh.factory<_i639.VendorStoriesCubit>(
      () => _i639.VendorStoriesCubit(gh<_i958.StoryRepository>()),
    );
    gh.factory<_i1066.OrderTrackingCubit>(
      () => _i1066.OrderTrackingCubit(gh<_i136.OrderRepository>()),
    );
    gh.lazySingleton<_i1064.DriverRepository>(
      () => _i313.DriverRepositoryImpl(
        datasource: gh<_i37.DriverFirebaseDatasource>(),
        orderDatasource: gh<_i249.OrderFirebaseDatasource>(),
      ),
    );
    gh.factory<_i379.AdminDashboardCubit>(
      () => _i379.AdminDashboardCubit(
        adminRepository: gh<_i741.AdminRepository>(),
      ),
    );
    gh.lazySingleton<_i611.TransportRepository>(
      () => _i619.TransportRepositoryImpl(
        gh<_i176.TransportFirebaseDatasource>(),
      ),
    );
    gh.lazySingleton<_i432.RestaurantWalletRepository>(
      () => _i701.RestaurantWalletRepositoryImpl(
        gh<_i797.RestaurantWalletDatasource>(),
      ),
    );
    gh.factory<_i978.ActiveRideCubit>(
      () => _i978.ActiveRideCubit(gh<_i611.TransportRepository>()),
    );
    gh.factory<_i171.DriverTransportCubit>(
      () => _i171.DriverTransportCubit(gh<_i611.TransportRepository>()),
    );
    gh.factory<_i916.TransportBookingCubit>(
      () => _i916.TransportBookingCubit(gh<_i611.TransportRepository>()),
    );
    gh.lazySingleton<_i594.NotificationRepository>(
      () => _i842.NotificationRepositoryImpl(
        gh<_i131.NotificationFirebaseDatasource>(),
      ),
    );
    gh.factory<_i407.DriverDashboardCubit>(
      () =>
          _i407.DriverDashboardCubit(repository: gh<_i1064.DriverRepository>()),
    );
    gh.factory<_i836.RestaurantDriverAssignmentCubit>(
      () => _i836.RestaurantDriverAssignmentCubit(
        repository: gh<_i1064.DriverRepository>(),
      ),
    );
    gh.factoryParam<_i1044.NotificationCubit, String, dynamic>(
      (userId, _) => _i1044.NotificationCubit(
        repository: gh<_i594.NotificationRepository>(),
        userId: userId,
      ),
    );
    return this;
  }
}

class _$AppModule extends _i461.AppModule {}
