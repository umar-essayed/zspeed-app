// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get rememberMe => 'Remember Me';

  @override
  String get criticalUpdateTitle => 'Update Required';

  @override
  String get criticalUpdateMessage =>
      'A new version of Z Speed is available. You must update the app to continue using our services.';

  @override
  String get flexibleUpdateTitle => 'New Update Available!';

  @override
  String get flexibleUpdateMessage =>
      'A new version of Z Speed is available with improvements and new features. Would you like to update now?';

  @override
  String get updateNow => 'Update Now';

  @override
  String get updateLater => 'Later';

  @override
  String get versionSettingsTitle => 'App Update Configuration';

  @override
  String get minRequiredVersionLabel => 'Minimum Required Version';

  @override
  String get latestVersionLabel => 'Latest App Version';

  @override
  String get iosUrlLabel => 'iOS Update URL (App Store)';

  @override
  String get androidUrlLabel => 'Android Update URL (Play Store)';

  @override
  String get fallbackUrlLabel => 'Fallback Update URL';

  @override
  String get saveSettings => 'Save Settings';

  @override
  String get settingsSaved => 'Settings saved successfully';

  @override
  String get onlySuperAdminCanEdit =>
      'Only super admin can modify these settings';

  @override
  String get driverEarningsLimitSettings => 'Driver Earnings Limit Settings';

  @override
  String get globalEarningsLimit => 'Global Earnings Limit (EGP)';

  @override
  String get earningsLimitDescription =>
      '0.0 or empty means no limit. Drivers will be locked when they exceed this limit.';

  @override
  String get settingsError => 'Error saving settings';

  @override
  String get accountLocked => 'Account Locked';

  @override
  String get earningsLimitReachedDesc =>
      'You have reached your earnings limit. To continue taking requests, please contact administration or visit a hub to settle your balance.';

  @override
  String get currentEarnings => 'Current Earnings:';

  @override
  String get limitThreshold => 'Limit Threshold:';

  @override
  String get refreshStatus => 'Refresh Status';

  @override
  String get lockedDueToEarningsLimit =>
      'Your account is locked due to earnings limit. Please settle your balance.';

  @override
  String get earningsLimitAndLockStatus => 'Earnings Limit & Lock Status';

  @override
  String get walletBalanceLabel => 'Wallet Balance';

  @override
  String get customEarningsLimit => 'Custom Earnings Limit';

  @override
  String get noCustomLimit => 'No Custom Limit (using global default)';

  @override
  String get settleBalanceAndUnlock => 'Settle Balance & Unlock';

  @override
  String get setCustomLimitTitle => 'Set Custom Earnings Limit';

  @override
  String get earningsLimitLabel => 'Earnings Limit (EGP)';

  @override
  String get customLimitHint => 'Enter 0 or leave empty to use global limit';

  @override
  String get customLimitUpdated => 'Custom earnings limit updated';

  @override
  String get confirmSettleTitle => 'Settle Balance & Unlock Driver';

  @override
  String confirmSettleBody(Object amount) {
    return 'Are you sure you want to reset the balance of EGP $amount to 0.0 and unlock this driver?';
  }

  @override
  String get confirmSettleButton => 'Confirm Settle';

  @override
  String get settleSuccess =>
      'Driver balance settled and account unlocked successfully';

  @override
  String settleError(Object error) {
    return 'Failed to reset: $error';
  }

  @override
  String get accountBlockedTitle => 'Account Suspended';

  @override
  String get accountBlockedMessage =>
      'Your account has been suspended by administration. If you believe this is a mistake or need assistance, please contact our support team.';

  @override
  String get contactSupport => 'Contact Support';

  @override
  String get logout => 'Logout';

  @override
  String get registrationDisabledTitle => 'Registration Closed';

  @override
  String get registrationDisabledMessage =>
      'New account registrations are temporarily paused. Please check back soon or log in with an existing account.';

  @override
  String get phoneBlacklistedError =>
      'This phone number has been blocked from registering.';

  @override
  String get emailBlacklistedError =>
      'This email address has been blocked from registering.';

  @override
  String get userBlockedError =>
      'Your account has been suspended. Please contact customer support.';

  @override
  String get allowNewSignupsLabel => 'Allow New Registrations';

  @override
  String get allowNewSignupsSubtitle =>
      'Toggle whether new users can register on the platform';

  @override
  String get signupDisabledMessageLabel => 'Registration Closed Message';

  @override
  String get maintenanceMessageLabel => 'Maintenance Mode Message';

  @override
  String get blacklistManagementTitle => 'Blacklist & Blocked Identifiers';

  @override
  String get blacklistSubtitle =>
      'Manage blocked phone numbers, emails, and identifiers';

  @override
  String get addToBlacklist => 'Add to Blacklist';

  @override
  String get removeFromBlacklist => 'Remove';

  @override
  String confirmRemoveBlacklist(Object identifier) {
    return 'Are you sure you want to unblock $identifier?';
  }

  @override
  String get blockedIdentifiers => 'Blocked Identifiers';

  @override
  String get blockReason => 'Reason';

  @override
  String get blockReasonHint =>
      'e.g. Fraudulent activity, chargebacks, policy violation';

  @override
  String get blockType => 'Type';

  @override
  String get phoneType => 'Phone Number';

  @override
  String get emailType => 'Email Address';

  @override
  String get uidType => 'User ID';

  @override
  String get enterIdentifier => 'Enter phone, email, or user ID';

  @override
  String get blacklistEmpty => 'No blocked identifiers found.';

  @override
  String get addedToBlacklistSuccess =>
      'Identifier successfully added to blacklist.';

  @override
  String get removedFromBlacklistSuccess =>
      'Identifier removed from blacklist.';

  @override
  String get blacklistUserCheckbox =>
      'Also blacklist phone number & email to prevent re-registration';

  @override
  String get appTitle => 'Z_Speed';

  @override
  String welcomeMessage(String name) {
    return 'Welcome back, $name!';
  }

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancel';

  @override
  String get submit => 'Submit';

  @override
  String get save => 'Save';

  @override
  String get loading => 'Loading...';

  @override
  String get errorOccurred => 'An error occurred. Please try again.';

  @override
  String get retry => 'Retry';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get success => 'Success';

  @override
  String get confirm => 'Confirm';

  @override
  String get loginTitle => 'Login to your account';

  @override
  String get phoneNumberLabel => 'Phone Number';

  @override
  String get continueButton => 'Continue';

  @override
  String get otpPrompt => 'Enter Verification Code';

  @override
  String get didNotReceiveCode => 'Didn\'t receive the code?';

  @override
  String get resendCode => 'Resend';

  @override
  String get enterName => 'What\'s your name?';

  @override
  String get accountPending => 'Account Pending Verification';

  @override
  String get forDeliveryService => 'FOR DELIVERY SERVICE';

  @override
  String get emailAddress => 'Email Address';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get logIn => 'Log In';

  @override
  String get signUp => 'Sign Up';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get continueWithPhone => 'Continue with Phone';

  @override
  String get orContinueWith => 'Or continue with';

  @override
  String get dontHaveAnAccount => 'Don\'t have an account?';

  @override
  String get alreadyHaveAnAccount => 'Already have an account?';

  @override
  String get orText => 'OR';

  @override
  String get createAccount => 'Create Account';

  @override
  String get welcomeBack => 'Welcome Back!';

  @override
  String get joinOurDeliveryService => 'Join our delivery service';

  @override
  String get loginToYourAccount => 'Login to your account';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get emailOrUsername => 'Email or Username';

  @override
  String get emailHint => 'e.g., owner@restaurant.com';

  @override
  String get pleaseEnterYourEmail => 'Please enter your email';

  @override
  String get pleaseEnterValidEmail => 'Please enter a valid email';

  @override
  String get enterYourPassword => 'Enter your password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get homeTab => 'Home';

  @override
  String get browseTab => 'Browse';

  @override
  String get cartTab => 'Cart';

  @override
  String get trackOrderTab => 'Track Order';

  @override
  String get profileTab => 'Profile';

  @override
  String get ourServices => 'Our Services';

  @override
  String get chooseService => 'Choose a service to get started';

  @override
  String get food => 'Food';

  @override
  String get groceries => 'Groceries';

  @override
  String get transport => 'Transport';

  @override
  String get pharmacy => 'Pharmacy';

  @override
  String get comingSoon => 'Coming Soon';

  @override
  String get searchRestaurants => 'Search restaurants or cuisines...';

  @override
  String get popularCategories => 'Popular Categories';

  @override
  String get featuredRestaurants => 'Featured Restaurants';

  @override
  String get freeDelivery => 'Free Delivery';

  @override
  String get allRestaurants => 'All Restaurants';

  @override
  String get openNow => 'Open Now';

  @override
  String get closed => 'Closed';

  @override
  String get yourCart => 'Your Cart';

  @override
  String get total => 'Total';

  @override
  String get subtotal => 'Subtotal';

  @override
  String get deliveryFee => 'Delivery Fee';

  @override
  String get taxes => 'Taxes';

  @override
  String get proceedToCheckout => 'Proceed to Checkout';

  @override
  String get emptyCart => 'Your cart is empty';

  @override
  String get addItems => 'Add items to get started';

  @override
  String get addToCart => 'Add to Cart';

  @override
  String get checkout => 'Checkout';

  @override
  String get myOrders => 'My Orders';

  @override
  String get paymentMethods => 'Payment Methods';

  @override
  String get savedAddresses => 'Saved Addresses';

  @override
  String get settings => 'Settings';

  @override
  String get changeLanguage => 'Change Language';

  @override
  String get rating => 'Rating';

  @override
  String get deliveryTimeFilter => 'Delivery Time';

  @override
  String get deliveryFeeFilter => 'Delivery Fee';

  @override
  String get name => 'Name';

  @override
  String get openOnly => 'Open Only';

  @override
  String get noRestaurantsFound => 'No restaurants found';

  @override
  String get noPharmaciesFound => 'No pharmacies found';

  @override
  String get noSupermarketsFound => 'No supermarkets found';

  @override
  String get tryAdjustingFilters => 'Try adjusting your filters or search';

  @override
  String get clearFilters => 'Clear Filters';

  @override
  String get addItemsFromRestaurants => 'Add items from restaurants';

  @override
  String get completed => 'Completed';

  @override
  String get viewDetails => 'View Details';

  @override
  String get edit => 'Edit';

  @override
  String get close => 'Close';

  @override
  String get tripDetails => 'Trip Details';

  @override
  String get tripHistory => 'Trip History';

  @override
  String get callCustomer => 'Call Customer';

  @override
  String get call => 'Call';

  @override
  String get callRestaurant => 'Call Restaurant';

  @override
  String get itemsInOrder => 'Items in Order:';

  @override
  String get noActiveTrip => 'No Active Trip';

  @override
  String get viewAvailableOrders => 'View Available Orders';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get enterLicensePlateHint =>
      'Enter 3 or 4 numbers followed by 2, 3 or 4 letters.';

  @override
  String get licensePlate => 'License Plate';

  @override
  String get navigate => 'Navigate';

  @override
  String get driverApplication => 'Driver Application';

  @override
  String get applicationSubmitted => 'Application Submitted!';

  @override
  String get done => 'Done';

  @override
  String get verifyContact => 'Please verify both email and phone number.';

  @override
  String get uploadRequiredDocs => 'Please upload all required documents.';

  @override
  String get fileExceedsLimit => 'File exceeds the 10MB limit.';

  @override
  String get trackDriverLocation => 'Track Driver Location';

  @override
  String get bookThisRide => 'Book This Ride';

  @override
  String get viewRouteMap => 'View Route (Map)';

  @override
  String get markAsPickedUp => 'Mark as Picked Up';

  @override
  String get markAsDelivered => 'Mark as Delivered';

  @override
  String get confirmDelivery => 'Confirm Delivery';

  @override
  String get activeMission => 'Active Mission';

  @override
  String get restaurant => 'Restaurant';

  @override
  String get customer => 'Customer';

  @override
  String get openMap => 'Open Map';

  @override
  String get reject => 'Reject';

  @override
  String get accept => 'Accept';

  @override
  String get orderDetails => 'Order Details';

  @override
  String get itemsToDeliver => 'Items to Deliver:';

  @override
  String get noItemDetailsAvailable => 'No item details available.';

  @override
  String get closeDetails => 'Close Details';

  @override
  String get rejectRequest => 'Reject Request';

  @override
  String get myProfile => 'My Profile';

  @override
  String get noDataAvailable => 'No data available';

  @override
  String get documents => 'Documents';

  @override
  String get couldNotOpenDocLink => 'Could not open document link';

  @override
  String get remove => 'Remove';

  @override
  String get assignToOrder => 'Assign to Order';

  @override
  String get assign => 'Assign';

  @override
  String get removeDriver => 'Remove Driver';

  @override
  String get amount => 'Amount';

  @override
  String get description => 'Description';

  @override
  String get review => 'Review';

  @override
  String get approve => 'Approve';

  @override
  String get disputeDetails => 'Dispute Details';

  @override
  String get descriptionLabel => 'Description:';

  @override
  String get filterOptionsComingSoon => 'Filter options coming soon...';

  @override
  String get applyFilters => 'Apply Filters';

  @override
  String get filterDisputes => 'Filter Disputes';

  @override
  String get disputeResolution => 'Dispute Resolution';

  @override
  String get sortBy => 'Sort by';

  @override
  String get gotIt => 'Got it';

  @override
  String get editUser => 'Edit User';

  @override
  String get rejectApplication => 'Reject Application';

  @override
  String get analyticsDashboard => 'Analytics Dashboard';

  @override
  String get generateReport => 'Generate Report';

  @override
  String get reportGenerationComingSoon => 'Report generation coming soon';

  @override
  String get generate => 'Generate';

  @override
  String get addRestaurant => 'Add Restaurant';

  @override
  String get createOrder => 'Create Order';

  @override
  String get delete => 'Delete';

  @override
  String get provideRejectReason =>
      'Please provide a reason for rejecting this section.';

  @override
  String get applicationApproved => 'Application approved';

  @override
  String get applicationRejected => 'Application Rejected';

  @override
  String get allSectionsApproved =>
      'All sections approved — application approved!';

  @override
  String get recentActivity => 'Recent Activity';

  @override
  String get noRecentActivity => 'No recent activity';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get addNewRestaurant => 'Add New Restaurant';

  @override
  String get editRestaurant => 'Edit Restaurant';

  @override
  String get editVendor => 'Edit Vendor';

  @override
  String get vendorUpdatedSuccessfully => 'Vendor updated successfully';

  @override
  String get deleteRestaurant => 'Delete Restaurant';

  @override
  String get addUser => 'Add User';

  @override
  String get changeStatus => 'Change Status';

  @override
  String get updateStatus => 'Update Status';

  @override
  String get addNewUser => 'Add New User';

  @override
  String get deleteUser => 'Delete User';

  @override
  String get userDetails => 'User Details';

  @override
  String get changeUserStatus => 'Change User Status';

  @override
  String get newOrder => 'New Order';

  @override
  String get recentOrders => 'Recent Orders';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get add => 'Add';

  @override
  String get deleteCuisineType => 'Delete Cuisine Type';

  @override
  String get addCuisineType => 'Add Cuisine Type';

  @override
  String get create => 'Create';

  @override
  String get editCuisineType => 'Edit Cuisine Type';

  @override
  String get cuisineTypeDeleted => 'Cuisine type deleted';

  @override
  String get bothNamesRequired => 'Both English and Arabic names are required';

  @override
  String get cuisineTypeCreated => 'Cuisine type created';

  @override
  String get cuisineTypeUpdated => 'Cuisine type updated';

  @override
  String get noApplicationsFound => 'No applications found';

  @override
  String get couldNotLoadImage => 'Could not load image';

  @override
  String get createNewOrder => 'Create New Order';

  @override
  String get deleteOrder => 'Delete Order';

  @override
  String get editOrder => 'Edit Order';

  @override
  String get applicationReview => 'Application Review';

  @override
  String get all => 'All';

  @override
  String get drivers => 'Drivers';

  @override
  String get restaurants => 'Restaurants';

  @override
  String get logoutAllOthers => 'Logout All Others';

  @override
  String get allOtherSessionsLogged =>
      'All other sessions logged out successfully';

  @override
  String get samsungGalaxySessionLogged => 'Samsung Galaxy session logged out';

  @override
  String get ipadAirSessionLogged => 'iPad Air session logged out';

  @override
  String get macbookProSessionLogged => 'MacBook Pro session logged out';

  @override
  String get activeSessions => 'Active Sessions';

  @override
  String get updatePassword => 'Update Password';

  @override
  String get passwordChangedSuccessfully => 'Password changed successfully';

  @override
  String get newPasswordsDoNot => 'New passwords do not match';

  @override
  String get passwordMustBeAt => 'Password must be at least 8 characters';

  @override
  String get pleaseFillAllFields => 'Please fill all fields';

  @override
  String get pleaseEnterYourCurrent => 'Please enter your current password';

  @override
  String get oneSpecialCharacter => '• One special character';

  @override
  String get oneNumber => '• One number';

  @override
  String get oneLowercaseLetter => '• One lowercase letter';

  @override
  String get oneUppercaseLetter => '• One uppercase letter';

  @override
  String get atLeast8Characters => '• At least 8 characters';

  @override
  String get changePassword => 'Change Password';

  @override
  String get twoFaSettingsUpdatedSuccessfully =>
      '2FA settings updated successfully';

  @override
  String get smsIsGoodFor => '• SMS is good for backup';

  @override
  String get useEmailForPrimary => '• Use email for primary verification';

  @override
  String get enableAtLeastOne => '• Enable at least one 2FA method';

  @override
  String get receiveCodeViaSms => 'Receive code via SMS';

  @override
  String get smsVerification => 'SMS Verification';

  @override
  String get receiveCodeViaEmail => 'Receive code via email';

  @override
  String get emailVerification => 'Email Verification';

  @override
  String get twofactorAuthentication => 'Two-Factor Authentication';

  @override
  String get frequentlyAskedQuestions => 'Frequently Asked Questions';

  @override
  String get faq => 'Frequently Asked Questions';

  @override
  String get available9am5pmEst => 'Available 9AM-5PM EST';

  @override
  String get liveChat => 'Live Chat';

  @override
  String get phoneSupport => 'Phone Support';

  @override
  String get emailSupport => 'Email Support';

  @override
  String get helpSupport => 'Help & Support';

  @override
  String get readFullTerms => 'Read Full Terms';

  @override
  String get pricesAndFeesMay => '• Prices and fees may change';

  @override
  String get serviceMayBeInterrupted =>
      '• Service may be interrupted for maintenance';

  @override
  String get weReserveTheRight => '• We reserve the right to modify terms';

  @override
  String get youAreResponsibleFor =>
      '• You are responsible for your account security';

  @override
  String get youMustBeAt => '• You must be at least 18 years old';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get readFullPrivacyPolicy => 'Read Full Privacy Policy';

  @override
  String get youControlYourPrivacy => '• You control your privacy settings';

  @override
  String get weNeverSellYour => '• We never sell your data';

  @override
  String get yourDataIsEncrypted => '• Your data is encrypted';

  @override
  String get weCollectOnlyNecessary => '• We collect only necessary data';

  @override
  String get keyPoints => 'Key Points:';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get pleaseTypeDeleteTo => 'Please type DELETE to confirm';

  @override
  String get typeDeleteToConfirm => 'Type \"DELETE\" to confirm:';

  @override
  String get removePaymentInformation => '• Remove payment information';

  @override
  String get deleteAllCustomerReviews => '• Delete all customer reviews';

  @override
  String get removeYourRestaurantFrom =>
      '• Remove your restaurant from the platform';

  @override
  String get cancelAllPendingOrders => '• Cancel all pending orders';

  @override
  String get permanentlyDeleteAllYour => '• Permanently delete all your data';

  @override
  String get thisWill => 'This will:';

  @override
  String get areYouSureYou => 'Are you sure you want to delete your account?';

  @override
  String get requestDownload => 'Request Download';

  @override
  String get activityLogs => '• Activity logs';

  @override
  String get preferences => 'Preferences';

  @override
  String get restaurantSettings => '• Restaurant settings';

  @override
  String get paymentRecords => '• Payment records';

  @override
  String get orderHistory => '• Order history';

  @override
  String get accountInformation => '• Account information';

  @override
  String get thisIncludes => 'This includes:';

  @override
  String get selectDataFormat => 'Select data format:';

  @override
  String get downloadYourData => 'Download Your Data';

  @override
  String get descriptionX => 'Description:';

  @override
  String get couldNotOpenDocument => 'Could not open document link';

  @override
  String get pleaseProvideAReason =>
      'Please provide a reason for rejecting this section.';

  @override
  String get allSectionsApprovedApplication =>
      'All sections approved — application approved!';

  @override
  String get bothEnglishAndArabic =>
      'Both English and Arabic names are required';

  @override
  String get optionDeletedSuccessfully => 'Option deleted successfully';

  @override
  String get deleteOption => 'Delete Option';

  @override
  String get groupDeletedSuccessfully => 'Group deleted successfully';

  @override
  String get deleteGroup => 'Delete Group';

  @override
  String get optionNameIsRequired => 'Option name is required';

  @override
  String get customerCanSelectThis => 'Customer can select this option';

  @override
  String get available => 'Available';

  @override
  String get preselectedForCustomer => 'Pre-selected for customer';

  @override
  String get defaultSelection => 'Default Selection';

  @override
  String get groupUpdatedSuccessfully => 'Group updated successfully';

  @override
  String get groupCreatedSuccessfully => 'Group created successfully';

  @override
  String get groupNameIsRequired => 'Group name is required';

  @override
  String get customerMustSelectAn => 'Customer must select an option';

  @override
  String get required => 'Required';

  @override
  String get multiple => 'Multiple';

  @override
  String get single => 'Single';

  @override
  String get selectionType => 'Selection Type:';

  @override
  String get addOption => 'Add Option';

  @override
  String get addFirstGroup => 'Add First Group';

  @override
  String get itemNotFound => 'Item not found';

  @override
  String get manageAddons => 'Manage Addons';

  @override
  String get cuisineTypes => 'Cuisine Types';

  @override
  String get loadingCuisines => 'Loading cuisines...';

  @override
  String get cuisineTypesUpdated => 'Cuisine types updated successfully';

  @override
  String get areYouSureYouX => 'Are you sure you want to logout?';

  @override
  String get symbolKey => ' *';

  @override
  String get track => 'Track';

  @override
  String get assignDriver => 'Assign Driver';

  @override
  String get noCuisineTypesAvailable =>
      'No cuisine types available. Please contact admin.';

  @override
  String get menuManager => 'Menu Manager';

  @override
  String get pleaseLogInTo => 'Please log in to manage your menu';

  @override
  String get itemDeletedSuccessfully => 'Item deleted successfully';

  @override
  String get addItem => 'Add Item';

  @override
  String get addFirstItem => 'Add First Item';

  @override
  String get coverImage => 'Cover Image *';

  @override
  String get restaurantLogo => 'Restaurant Logo';

  @override
  String get viewReceipt => 'View Receipt';

  @override
  String get totalX => 'TOTAL';

  @override
  String get tryAdjustingYourSearch => 'Try adjusting your search or filters';

  @override
  String get noOrdersFound => 'No orders found';

  @override
  String get lowestAmount => 'Lowest Amount';

  @override
  String get highestAmount => 'Highest Amount';

  @override
  String get oldestFirst => 'Oldest First';

  @override
  String get newestFirst => 'Newest First';

  @override
  String get manageAndTrackAll => 'Manage and track all orders';

  @override
  String get orderHistoryX => 'Order History';

  @override
  String get selectCuisineType => 'Select cuisine type...';

  @override
  String get symbolKeyX => 'X';

  @override
  String get operatingHours => 'Operating Hours';

  @override
  String get workingHours => 'Working Hours';

  @override
  String get basicInformation => 'Basic Information';

  @override
  String get minDeliveryTime => 'Min Delivery Time';

  @override
  String get maxDeliveryTime => 'Max Delivery Time';

  @override
  String get pickOnMap => 'Pick on Map';

  @override
  String get coordinates => 'Coordinates';

  @override
  String get documentation => 'Documentation';

  @override
  String get supportCenter => 'Support Center';

  @override
  String get checkOurDocumentationOr =>
      'Check our documentation or contact support.';

  @override
  String get needHelp => 'Need Help?';

  @override
  String get noOrdersYet => 'No orders yet';

  @override
  String get thisWeek => 'This Week';

  @override
  String get restaurantCreatedWelcomeAboard =>
      'Restaurant created! Welcome aboard 🎉';

  @override
  String get restaurantNameIsRequired => 'Restaurant name is required';

  @override
  String get createRestaurant => 'Create Restaurant';

  @override
  String get notAuthenticatedPleaseLog => 'Not authenticated. Please log in.';

  @override
  String get restaurantDetailsMissing => 'Restaurant details missing.';

  @override
  String get orderRejected => 'Order rejected';

  @override
  String get selectAReasonFor => 'Select a reason for rejecting this order:';

  @override
  String get rejectOrder => 'Reject Order';

  @override
  String get orderMarkedAsReady => 'Order marked as ready for pickup';

  @override
  String get orderPreparationStarted => 'Order preparation started';

  @override
  String get orderAcceptedSuccessfully => 'Order accepted successfully';

  @override
  String get awaitingDriverPickup => 'Awaiting driver pickup...';

  @override
  String get assignDriverOptional => 'Assign Driver (Optional)';

  @override
  String get markAsReadyFor => 'Mark as Ready for Pickup';

  @override
  String get startPreparing => 'Start Preparing';

  @override
  String get trackDriver => 'Track Driver';

  @override
  String get paymentMethod => 'Payment Method';

  @override
  String get placedAt => 'Placed At';

  @override
  String get status => 'Status';

  @override
  String get camera => 'Camera';

  @override
  String get gallery => 'Gallery';

  @override
  String get chooseLogoFrom => 'Choose logo from:';

  @override
  String get changeLogo => 'Change Logo';

  @override
  String get closingTime => 'Closing Time';

  @override
  String get openingTime => 'Opening Time';

  @override
  String get markAsReady => 'Mark as Ready';

  @override
  String get waitingForDriverLocation => 'Waiting for driver location...';

  @override
  String get map => 'Map';

  @override
  String get uploadingCover => 'Uploading cover...';

  @override
  String get locationUpdatedFromMap => 'Location updated from map';

  @override
  String get goToDashboard => 'Go to Dashboard';

  @override
  String get fileExceedsThe10mb => 'File exceeds the 10MB limit.';

  @override
  String get pleaseUploadBothLogo => 'Please upload both logo and cover image.';

  @override
  String get pleaseUploadAllRequired => 'Please upload all required documents.';

  @override
  String get selectAtLeastOne => 'Select at least one cuisine type.';

  @override
  String get pleaseVerifyBothEmail =>
      'Please verify both email and phone number.';

  @override
  String get restaurantApplication => 'Restaurant Application';

  @override
  String vendorApplication(String vendorType) {
    return '$vendorType Application';
  }

  @override
  String get vendorTypeStep => 'Vendor Type';

  @override
  String get vendorTypeSubtitle => 'What kind of business are you registering?';

  @override
  String get supermarket => 'Supermarket';

  @override
  String get foodAndDining => 'Food & dining';

  @override
  String get groceriesAndDailyNeeds => 'Groceries & daily needs';

  @override
  String get medicineAndHealthProducts => 'Medicine & health products';

  @override
  String get deliveryFeeSettingsSaved => 'Delivery fee settings saved';

  @override
  String get discard => 'Discard';

  @override
  String get discardChanges => 'Discard Changes?';

  @override
  String get addTier => 'Add Tier';

  @override
  String get differentRatesForDistance => 'Different rates for distance ranges';

  @override
  String get tieredPricing => 'Tiered Pricing';

  @override
  String get baseFeePerKm => 'Base fee + per km rate';

  @override
  String get perKilometer => 'Per Kilometer';

  @override
  String get calculateFeeBasedOn => 'Calculate fee based on delivery distance';

  @override
  String get distancebasedFee => 'Distance-Based Fee';

  @override
  String get chargeAFixedDelivery => 'Charge a fixed delivery fee per order';

  @override
  String get fixedFee => 'Fixed Fee';

  @override
  String get youHaveTheLatest => 'You have the latest version';

  @override
  String get checkingForUpdates => 'Checking for updates...';

  @override
  String get checkForUpdates => 'Check for Updates';

  @override
  String get privacyPolicyContent => 'Privacy Policy Content...';

  @override
  String get termsOfServiceContent => 'Terms of Service Content...';

  @override
  String get issueReportedSuccessfully => 'Issue reported successfully. We\\';

  @override
  String get files => 'Files';

  @override
  String get fileAttachedFromFiles => 'File attached from files';

  @override
  String get fileAttachedFromCamera => 'File attached from camera';

  @override
  String get fileAttachedFromGallery => 'File attached from gallery';

  @override
  String get chooseFileFrom => 'Choose file from:';

  @override
  String get attachFile => 'Attach File';

  @override
  String get blogContent => 'Blog Content';

  @override
  String get blogUpdates => 'Blog & Updates';

  @override
  String get technicalDocumentation => 'Technical Documentation';

  @override
  String get videoTutorials => 'Video Tutorials';

  @override
  String get userGuideContent => 'User Guide Content';

  @override
  String get userGuide => 'User Guide';

  @override
  String get connectedToSupportAgent => 'Connected to support agent';

  @override
  String get connectingToSupportAgent => 'Connecting to support agent...';

  @override
  String get openingLiveChat => 'Opening live chat...';

  @override
  String get available247 => 'Available 24/7';

  @override
  String get openingEmail => 'Opening email...';

  @override
  String get supportspeedridescom => 'support@speedrides.com';

  @override
  String get callingSupport => 'Calling support...';

  @override
  String get phoneNumberExample => '+201000000000';

  @override
  String get openMaps => 'Open Maps';

  @override
  String get locationOpenedInMaps => 'Location opened in maps!';

  @override
  String get send => 'Send';

  @override
  String get messageSentToDriver => 'Message sent to driver!';

  @override
  String get callingDriver => 'Calling driver...';

  @override
  String get shareOrder => 'Share Order';

  @override
  String get signIn => 'Sign In';

  @override
  String get message => 'Message';

  @override
  String get addedToCart => 'Added to cart';

  @override
  String get labelAndAddressAre => 'Label and Address are required';

  @override
  String get addSavedAddress => 'Add Saved Address';

  @override
  String get addNew => 'Add New';

  @override
  String get noAddressesSavedYet => 'No addresses saved yet';

  @override
  String get pleaseLogin => 'Please login';

  @override
  String get ratingFeatureComingSoon => 'Rating feature coming soon';

  @override
  String get noMenuItemsAvailable => 'No menu items available';

  @override
  String get goBack => 'Go Back';

  @override
  String get restaurantNotFound => 'Restaurant not found';

  @override
  String get errorLoadingRestaurant => 'Error loading restaurant';

  @override
  String get createAMenuSection => 'Create a menu section first';

  @override
  String get replace => 'Replace';

  @override
  String get replaceCartItems => 'Replace cart items?';

  @override
  String get noMenuItemsYet => 'No menu items yet';

  @override
  String get cancelOrder => 'Cancel Order';

  @override
  String get keepOrder => 'Keep Order';

  @override
  String get pleaseSelectAReason => 'Please select a reason for cancellation:';

  @override
  String get contactSupportFeatureComing =>
      'Contact support feature coming soon';

  @override
  String get orderNotFound => 'Order not found';

  @override
  String get trackOrder => 'Track Order';

  @override
  String get estimatedDelivery3045Minutes =>
      'Estimated delivery: 30-45 minutes';

  @override
  String get orderPlaced => 'Order Placed';

  @override
  String get apply => 'Apply';

  @override
  String get useCurrentLocation => 'Use current location';

  @override
  String get locationPickerComingSoon => 'Location picker coming soon';

  @override
  String get enter3Or4 => 'Enter 3 or 4 numbers followed by 2, 3 or 4 letters.';

  @override
  String get symbolKeyXX => '-';

  @override
  String get myAccount => 'My Account';

  @override
  String get noDocumentsUploaded => 'No documents uploaded.';

  @override
  String get editAnyway => 'Edit Anyway';

  @override
  String get editApprovedSection => 'Edit Approved Section?';

  @override
  String get sectionUpdatedSentBack =>
      'Section updated — sent back for review.';

  @override
  String get noApplicationFound => 'No application found.';

  @override
  String get myApplication => 'My Application';

  @override
  String get notificationDeleted => 'Notification deleted';

  @override
  String get notifications => 'Notifications';

  @override
  String get shareReceipt => 'Share Receipt';

  @override
  String get shareReceiptFeatureComing => 'Share receipt feature coming soon!';

  @override
  String get paymentReceipt => 'Payment Receipt';

  @override
  String get minimumPayoutAmount => 'Minimum Payout Amount';

  @override
  String get monthly => 'Monthly';

  @override
  String get weekly => 'Weekly';

  @override
  String get daily => 'Daily';

  @override
  String get payoutFrequency => 'Payout Frequency';

  @override
  String get savePaymentMethod => 'Save Payment Method';

  @override
  String get receivePaymentsViaVodafone => 'Receive payments via Vodafone Cash';

  @override
  String get vodafoneCash => 'Vodafone Cash';

  @override
  String get receivePaymentsViaInstapay => 'Receive payments via InstaPay';

  @override
  String get instapay => 'InstaPay';

  @override
  String get addPaymentMethod => 'Add Payment Method';

  @override
  String get paymentMethodSaved => 'Payment method saved';

  @override
  String get notSignedIn => 'Not signed in';

  @override
  String get taxInformationPage => 'Tax Information Page';

  @override
  String get taxInformation => 'Tax Information';

  @override
  String get digitalWallet => 'Digital Wallet';

  @override
  String get creditdebitCard => 'Credit/Debit Card';

  @override
  String get editDetails => 'Edit Details';

  @override
  String get setAsDefault => 'Set as Default';

  @override
  String get defaultText => 'Default';

  @override
  String get addNewPaymentMethod => 'Add New Payment Method';

  @override
  String get addWallet => 'Add Wallet';

  @override
  String get addDigitalWallet => 'Add Digital Wallet';

  @override
  String get addCard => 'Add Card';

  @override
  String get alreadyHaveAnAccountX => 'Already have an account? Login';

  @override
  String get getHelpWithPrivacy => 'Get help with privacy issues';

  @override
  String get readOurTermsOf => 'Read our terms of service';

  @override
  String get readOurPrivacyPolicy => 'Read our privacy policy';

  @override
  String get permanentlyDeleteYourAccount => 'Permanently delete your account';

  @override
  String get getACopyOf => 'Get a copy of your data';

  @override
  String get manageLoggedInDevices => 'Manage logged-in devices';

  @override
  String get updateYourPasswordRegularly => 'Update your password regularly';

  @override
  String get addAnExtraLayer => 'Add an extra layer of security';

  @override
  String get useFingerprintOrFace => 'Use fingerprint or face ID';

  @override
  String get biometricLogin => 'Biometric Login';

  @override
  String get privacySecurity => 'Privacy & Security';

  @override
  String get continueToPayment => 'Continue to Payment';

  @override
  String get deliveryDetails => 'Delivery Details';

  @override
  String get configureTaxSettings => 'Configure Tax Settings';

  @override
  String get minimumPayout => 'Minimum Payout';

  @override
  String get symbolKeyXXX => 'English';

  @override
  String get english => 'English';

  @override
  String get loggedOutSuccessfully => 'Logged out successfully';

  @override
  String get appInformation => 'App Information';

  @override
  String get submitReport => 'Submit Report';

  @override
  String get attachScreenshotsIfNeeded => 'Attach screenshots if needed';

  @override
  String get foundABugOr => 'Found a bug or have a question?';

  @override
  String get reportAProblem => 'Report a Problem';

  @override
  String get resources => 'Resources';

  @override
  String get getInTouchWith => 'Get in touch with our support team';

  @override
  String get orderPlacedSuccessfully => 'Order placed successfully!';

  @override
  String get creditDebitCard => 'Credit / Debit Card';

  @override
  String get cashOnDelivery => 'Cash on Delivery';

  @override
  String get payment => 'Payment';

  @override
  String get createYourRestaurantFirst => 'Create your restaurant first.';

  @override
  String get notAuthenticated => 'Not authenticated.';

  @override
  String get confirmLocation => 'Confirm Location';

  @override
  String get couldNotDetectLocation => 'Could not detect location';

  @override
  String get ordersHistory => 'Orders History';

  @override
  String get offersPage => 'Offers Page';

  @override
  String get restaurantsList => 'Restaurants List';

  @override
  String get speed => 'Speed';

  @override
  String get downloadReceipt => 'Download Receipt';

  @override
  String get orderReceipt => 'Order Receipt';

  @override
  String get pleaseEnterYourPasswordValidation => 'Please enter your password';

  @override
  String get passwordMinLength => 'Password must be at least 6 characters';

  @override
  String get pleaseConfirmYourPassword => 'Please confirm your password';

  @override
  String get bySigningUp =>
      'By signing up, you agree to our Terms & Privacy Policy';

  @override
  String get wantToPartnerWithUs => 'Want to partner with us?';

  @override
  String get joinAsDriver => 'Join as Driver';

  @override
  String get joinAsRestaurant => 'Join as Vendor';

  @override
  String get google => 'Google';

  @override
  String get phone => 'Phone';

  @override
  String get drawerMain => 'Main';

  @override
  String get drawerEngage => 'Engage';

  @override
  String get drawerMore => 'More';

  @override
  String get drawerDashboard => 'Dashboard';

  @override
  String get drawerOrders => 'Orders';

  @override
  String get drawerMenu => 'Menu';

  @override
  String get drawerAnalytics => 'Analytics';

  @override
  String get drawerProfile => 'Profile';

  @override
  String get drawerPromotions => 'Promotions';

  @override
  String get drawerReviews => 'Reviews';

  @override
  String get drawerSettings => 'Settings';

  @override
  String get drawerDeliveryFees => 'Delivery Fees';

  @override
  String get drawerSupport => 'Support';

  @override
  String get drawerAbout => 'About';

  @override
  String get myRestaurant => 'My Restaurant';

  @override
  String get open => 'Open';

  @override
  String get dashboardOverview => 'Dashboard Overview';

  @override
  String monitorPerformance(String vendorLabel) {
    return 'Monitor your $vendorLabel performance';
  }

  @override
  String get totalRevenue => 'Total Revenue';

  @override
  String get activeOrders => 'Active Orders';

  @override
  String get newCustomers => 'New Customers';

  @override
  String get avgPrepTime => 'Avg. Prep Time';

  @override
  String get restaurantIsOpen => 'Restaurant is Open';

  @override
  String get restaurantIsClosed => 'Restaurant is Closed';

  @override
  String get customersCanPlaceOrders => 'Customers can place orders now';

  @override
  String get tapToStartAcceptingOrders => 'Tap to start accepting orders';

  @override
  String get revenueOverview => 'Revenue Overview';

  @override
  String get vsLastWeek => 'vs. last week';

  @override
  String get sameAsLastWeek => 'Same as last week';

  @override
  String get gettingFaster => 'Getting faster';

  @override
  String get slower => 'Slower';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get setUpYourRestaurant => 'Set up your restaurant';

  @override
  String get fillInDetailsBelow =>
      'Fill in the details below to create your restaurant\nand start managing your menu and orders.';

  @override
  String get restaurantName => 'Restaurant Name';

  @override
  String get descriptionOptional => 'Description (Optional)';

  @override
  String get address => 'Address';

  @override
  String get cuisineTypesCommaSeparated => 'Cuisine Types (comma-separated)';

  @override
  String get cuisineTypesHint => 'e.g., Italian, Pizza, Pasta';

  @override
  String get creating => 'Creating...';

  @override
  String welcomeTo(String name) {
    return 'Welcome to $name';
  }

  @override
  String fieldIsRequired(String field) {
    return '$field is required';
  }

  @override
  String get statusPending => 'Pending';

  @override
  String get statusAccepted => 'Accepted';

  @override
  String get statusPreparing => 'Preparing';

  @override
  String get statusReady => 'Ready';

  @override
  String get statusDriverAssigned => 'Driver Assigned';

  @override
  String get statusPickedUp => 'Picked Up';

  @override
  String get statusOnTheWay => 'On the way';

  @override
  String get statusDelivered => 'Delivered';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get statusRefunded => 'Refunded';

  @override
  String get justNow => 'Just now';

  @override
  String minutesAgo(int count) {
    return '$count mins ago';
  }

  @override
  String hoursAgo(int count) {
    return '$count hours ago';
  }

  @override
  String daysAgo(int count) {
    return '$count days ago';
  }

  @override
  String get dayMon => 'Monday';

  @override
  String get dayTue => 'Tuesday';

  @override
  String get dayWed => 'Wednesday';

  @override
  String get dayThu => 'Thursday';

  @override
  String get dayFri => 'Friday';

  @override
  String get daySat => 'Saturday';

  @override
  String get daySun => 'Sunday';

  @override
  String get failedToLoadOrders => 'Failed to load orders';

  @override
  String allCount(int count) {
    return 'All ($count)';
  }

  @override
  String newCount(int count) {
    return 'New ($count)';
  }

  @override
  String activeCount(int count) {
    return 'Active ($count)';
  }

  @override
  String readyCount(int count) {
    return 'Ready ($count)';
  }

  @override
  String get order => 'Order';

  @override
  String get cash => 'Cash';

  @override
  String get driverAssignedAwaitingPickup =>
      'Driver assigned — awaiting pickup';

  @override
  String get readyAssignDriver => 'Ready — Assign a driver';

  @override
  String manageDriversCount(int count) {
    return 'Manage Drivers ($count assigned)';
  }

  @override
  String get itemsNotAvailable => 'Items not available';

  @override
  String get tooBusy => 'Too busy';

  @override
  String get closingSoon => 'Closing soon';

  @override
  String get duplicateOrder => 'Duplicate order';

  @override
  String get other => 'Other';

  @override
  String assignedDriversCount(int count) {
    return 'Assigned Drivers ($count)';
  }

  @override
  String reason(String reason) {
    return 'Reason: $reason';
  }

  @override
  String get statusRejected => 'Rejected';

  @override
  String get notAuthenticatedTitle => 'Not Authenticated';

  @override
  String get pleaseLogInToViewProfile => 'Please log in to view your profile.';

  @override
  String get noRestaurantProfileYet => 'No restaurant profile yet';

  @override
  String get createRestaurantFromDashboard =>
      'Create your restaurant from the dashboard\nto start managing your profile here.';

  @override
  String get businessInformation => 'Business Information';

  @override
  String get arabicName => 'Arabic Name';

  @override
  String get notSet => 'Not set';

  @override
  String get location => 'Location';

  @override
  String get deliverySettings => 'Delivery Settings';

  @override
  String get deliveryTime => 'Delivery Time';

  @override
  String get minimumOrder => 'Minimum Order';

  @override
  String deliveryRadius(String km) {
    return '$km km';
  }

  @override
  String get feeMode => 'Fee Mode';

  @override
  String get ratingsAndStats => 'Ratings & Stats';

  @override
  String get noRatingsYet => 'No ratings yet';

  @override
  String get totalReviews => 'Total Reviews';

  @override
  String get memberSince => 'Member Since';

  @override
  String get lastUpdated => 'Last updated';

  @override
  String get currentlyOpen => 'Currently Open';

  @override
  String get currentlyClosed => 'Currently Closed';

  @override
  String get customersCanOrderFromRestaurant =>
      'Customers can order from your restaurant';

  @override
  String get restaurantNotAcceptingOrders =>
      'Your restaurant isn\'t accepting orders';

  @override
  String get wait => 'Wait';

  @override
  String get gps => 'GPS';

  @override
  String get monday => 'Monday';

  @override
  String get tuesday => 'Tuesday';

  @override
  String get wednesday => 'Wednesday';

  @override
  String get thursday => 'Thursday';

  @override
  String get friday => 'Friday';

  @override
  String get saturday => 'Saturday';

  @override
  String get sunday => 'Sunday';

  @override
  String get noHoursSet => 'No hours set';

  @override
  String get editOperatingHours => 'Edit Operating Hours';

  @override
  String get operatingHoursSaved => 'Operating hours saved';

  @override
  String failed(String error) {
    return 'Failed: $error';
  }

  @override
  String get totalOrders => 'Total Orders';

  @override
  String get completionRate => 'Completion Rate';

  @override
  String get avgOrderValue => 'Avg. Order Value';

  @override
  String get revenueTrend => 'Revenue Trend';

  @override
  String get orderVolume => 'Order Volume';

  @override
  String get topSellingItems => 'Top Selling Items';

  @override
  String get noItemDataAvailable => 'No item data available';

  @override
  String get peakHours => 'Peak Hours';

  @override
  String get noHourlyDataAvailable => 'No hourly data available';

  @override
  String get today => 'Today';

  @override
  String get thisMonth => 'This Month';

  @override
  String get lastMonth => 'Last Month';

  @override
  String get custom => 'Custom';

  @override
  String get noDataForThisPeriod => 'No data for this period';

  @override
  String get delivered => 'Delivered';

  @override
  String get cancelled => 'Cancelled';

  @override
  String get refunded => 'Refunded';

  @override
  String get customerInsights => 'Customer Insights';

  @override
  String get totalCustomers => 'Total Customers';

  @override
  String get new_ => 'New';

  @override
  String get returning => 'Returning';

  @override
  String get unknownError => 'Unknown error';

  @override
  String get createYourRestaurant => 'Create Your Restaurant';

  @override
  String get setUpRestaurantProfile =>
      'Set up your restaurant profile to start managing menu and orders.';

  @override
  String get settingsPreferences => 'Preferences';

  @override
  String get manageSettingsSubtitle =>
      'Manage notifications, payment, and account preferences.';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get configureAlerts => 'Configure how you receive alerts.';

  @override
  String get newOrderAlert => 'New Order Alert';

  @override
  String get showNotificationForNewOrders => 'Show notification for new orders';

  @override
  String get emailNotifications => 'Email Notifications';

  @override
  String get receiveEmailUpdates => 'Receive email updates';

  @override
  String get autoAcceptOrders => 'Auto-Accept Orders';

  @override
  String get automaticallyAcceptOrders =>
      'Automatically accept incoming orders';

  @override
  String get restaurantNameRequired => 'Restaurant Name *';

  @override
  String get email => 'Email';

  @override
  String get restaurantCreatedSuccessfully =>
      'Restaurant created successfully!';

  @override
  String failedToCreateRestaurant(String error) {
    return 'Failed to create restaurant: $error';
  }

  @override
  String get promotionsTitle => 'Promotions';

  @override
  String get promotionsSubtitle =>
      'Create and manage promotions to attract more customers.';

  @override
  String get discountCodes => 'Discount Codes';

  @override
  String get discountCodesDesc =>
      'Create percentage or fixed amount discount codes';

  @override
  String get specialOffers => 'Special Offers';

  @override
  String get specialOffersDesc => 'Set up BOGO, meal deals, and more';

  @override
  String get scheduledPromotions => 'Scheduled Promotions';

  @override
  String get scheduledPromotionsDesc =>
      'Plan promotions for holidays and peak hours';

  @override
  String get performanceTracking => 'Performance Tracking';

  @override
  String get performanceTrackingDesc =>
      'See how your promotions have performed';

  @override
  String get reviewsTitle => 'Reviews';

  @override
  String get reviewsSubtitle =>
      'See what your customers are saying about your restaurant.';

  @override
  String get customerFeedback => 'Customer Feedback';

  @override
  String get customerFeedbackDesc => 'Read and reply to customer reviews';

  @override
  String get ratingBreakdown => 'Rating Breakdown';

  @override
  String get ratingBreakdownDesc =>
      'Detailed breakdown of your ratings by category';

  @override
  String get sentimentTrends => 'Sentiment Trends';

  @override
  String get sentimentTrendsDesc => 'Track how your ratings change over time';

  @override
  String get replyToReviews => 'Reply to Reviews';

  @override
  String soldCount(int count) {
    return '$count sold';
  }

  @override
  String get setUpRestaurantProfilePrompt =>
      'Set up your restaurant profile to start managing your menu and orders.';

  @override
  String get configureAlertsSubtitle => 'Configure how you receive alerts.';

  @override
  String get newOrderAlertDescription => 'Show notification for new orders';

  @override
  String get emailNotificationsDescription => 'Receive email updates';

  @override
  String get autoAcceptOrdersDescription =>
      'Automatically accept incoming orders';

  @override
  String get restaurantNameAsterisk => 'Restaurant Name *';

  @override
  String get discountCodesDescription =>
      'Create percentage or fixed-amount discount codes';

  @override
  String get specialOffersDescription =>
      'Set up buy-one-get-one, combo deals, and more';

  @override
  String get scheduledPromotionsDescription =>
      'Plan promotions for holidays and peak hours';

  @override
  String get performanceTrackingDescription =>
      'See how your promotions are performing';

  @override
  String get customerFeedbackDescription =>
      'Read and respond to customer reviews';

  @override
  String get ratingBreakdownDescription =>
      'Detailed breakdown of your ratings by category';

  @override
  String get sentimentTrendsDescription =>
      'Track how your ratings change over time';

  @override
  String get replyToReviewsDescription =>
      'Engage with customers by responding to their feedback';

  @override
  String get howCanWeHelp => 'How can we help?';

  @override
  String get supportTeamAssist => 'Our support team is here to assist you.';

  @override
  String get liveChatAvailability => 'Available 9 AM - 9 PM';

  @override
  String get faqQuestion1 => 'How do I update my menu?';

  @override
  String get faqAnswer1 =>
      'Go to the Menu page from the sidebar. You can add, edit, or remove items and sections. Changes are reflected to customers in real-time.';

  @override
  String get faqQuestion2 => 'How do I change my operating hours?';

  @override
  String get faqAnswer2 =>
      'Go to your Profile page and scroll to the Operating Hours section. Tap the edit icon next to any day to update your hours.';

  @override
  String get faqQuestion3 => 'How are delivery fees calculated?';

  @override
  String get faqAnswer3 =>
      'Go to Delivery Fees in the sidebar. You can set a fixed fee or distance-based pricing with tiers.';

  @override
  String get faqQuestion4 => 'How do I handle a rejected order?';

  @override
  String get faqAnswer4 =>
      'When you reject an order, select a reason. The customer will be notified and refunded automatically.';

  @override
  String get faqQuestion5 => 'How do I contact a driver?';

  @override
  String get faqAnswer5 =>
      'On the Orders page, assigned orders show the driver\'s name and phone number. Tap to call directly.';

  @override
  String get aboutZSpeed => 'About Z Speed';

  @override
  String get aboutZSpeedDescription =>
      'Z Speed is a fast and reliable delivery platform connecting restaurants with customers across Egypt. We empower restaurant owners with modern tools to manage their business efficiently.';

  @override
  String get openSourceLicenses => 'Open Source Licenses';

  @override
  String get copyright => '© 2026 Z Speed. All rights reserved.';

  @override
  String get whatsPlanned => 'What\'s planned:';

  @override
  String editField(String field) {
    return 'Edit $field';
  }

  @override
  String enterField(String field) {
    return 'Enter $field';
  }

  @override
  String fieldUpdatedSuccessfully(String field) {
    return '$field updated successfully';
  }

  @override
  String editDayHours(String day) {
    return 'Edit $day Hours';
  }

  @override
  String dayHoursUpdated(String day) {
    return '$day hours updated';
  }

  @override
  String get selectBothTimes => 'Please select both opening and closing times';

  @override
  String get logoChangedFromGallery => 'Logo changed from gallery';

  @override
  String get logoChangedFromCamera => 'Logo changed from camera';

  @override
  String orderWithId(String id) {
    return 'Order #$id';
  }

  @override
  String get deleteItem => 'Delete Item';

  @override
  String confirmDeleteItem(String name) {
    return 'Are you sure you want to delete \'$name\'?';
  }

  @override
  String currencyEgp(String amount) {
    return '$amount EGP';
  }

  @override
  String get outOfStock => 'Out of Stock';

  @override
  String stockCount(int count) {
    return 'Stock: $count';
  }

  @override
  String get preview => 'Preview';

  @override
  String failedToPickImage(String error) {
    return 'Failed to pick image: $error';
  }

  @override
  String get pleaseSelectCuisineType => 'Please select a cuisine type';

  @override
  String get englishNameRequired => 'English name is required';

  @override
  String get arabicNameRequired => 'Arabic name is required';

  @override
  String get englishDescriptionRequired => 'English description is required';

  @override
  String get arabicDescriptionRequired => 'Arabic description is required';

  @override
  String get priceRequired => 'Price is required';

  @override
  String get invalidPrice => 'Invalid price';

  @override
  String get salePriceError => 'Sale price must be less than regular price';

  @override
  String get pleaseUploadImage => 'Please upload an image for this item';

  @override
  String get failedToUploadImage => 'Failed to upload image';

  @override
  String get itemCreated => 'Item created';

  @override
  String get itemUpdated => 'Item updated';

  @override
  String failedToSaveItem(String error) {
    return 'Failed to save item: $error';
  }

  @override
  String get addMenuItem => 'Add Menu Item';

  @override
  String get editMenuItem => 'Edit Menu Item';

  @override
  String get cuisineTypeRequired => 'Cuisine Type *';

  @override
  String get itemImageRequired => 'Item Image *';

  @override
  String get itemNameEnglishRequired => 'Item Name (English) *';

  @override
  String get itemNameEnglishHint => 'e.g., Grilled Chicken';

  @override
  String get itemNameArabicRequired => 'Item Name (Arabic) *';

  @override
  String get itemNameArabicHint => 'مثال: دجاج مشوي';

  @override
  String get descriptionEnglishRequired => 'Description (English) *';

  @override
  String get descriptionEnglishHint => 'Brief description of the item';

  @override
  String get descriptionArabicRequired => 'Description (Arabic) *';

  @override
  String get descriptionArabicHint => 'وصف مختصر للصنف';

  @override
  String get priceEgpRequired => 'Price (EGP) *';

  @override
  String get salePriceEgp => 'Sale Price (EGP)';

  @override
  String get unavailable => 'Unavailable';

  @override
  String get createItem => 'Create Item';

  @override
  String get tapToUploadImage => 'Tap to upload image';

  @override
  String get imageRequirements => 'Required • JPG or PNG';

  @override
  String get noAddonGroupsYet => 'No addon groups yet';

  @override
  String get addGroupPrompt =>
      'Add groups like \"Choose Size\" or \"Extra Toppings\"';

  @override
  String optionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count options',
      one: '1 option',
      zero: 'no options',
    );
    return '$_temp0';
  }

  @override
  String get editGroup => 'Edit group';

  @override
  String get noOptionsYet => 'No options yet';

  @override
  String get defaultLabel => 'Default';

  @override
  String extraPriceEgp(String price) {
    return '+EGP $price';
  }

  @override
  String get editOption => 'Edit option';

  @override
  String get addAddonGroup => 'Add Addon Group';

  @override
  String get editAddonGroup => 'Edit Addon Group';

  @override
  String get groupNameRequired => 'Group Name *';

  @override
  String get groupNameHint => 'e.g., Choose Size';

  @override
  String get arabicNameOptional => 'Arabic Name (optional)';

  @override
  String get arabicNameHint => 'e.g., اختر الحجم';

  @override
  String get minSelections => 'Min Selections';

  @override
  String get maxSelections => 'Max Selections';

  @override
  String failedToSaveGroup(String error) {
    return 'Failed to save group: $error';
  }

  @override
  String get update => 'Update';

  @override
  String get addOptionLabel => 'Add Option';

  @override
  String get editOptionLabel => 'Edit Option';

  @override
  String get optionNameRequired => 'Option Name *';

  @override
  String get optionNameHint => 'e.g., Large';

  @override
  String get extraPriceEgpLabel => 'Extra Price (EGP)';

  @override
  String get optionAdded => 'Option added';

  @override
  String get optionUpdated => 'Option updated';

  @override
  String failedToSaveOption(String error) {
    return 'Failed to save option: $error';
  }

  @override
  String confirmDeleteGroup(String name) {
    return 'Are you sure you want to delete \'$name\'?';
  }

  @override
  String confirmDeleteGroupWarning(int count) {
    return 'This will remove all $count option(s) in this group.';
  }

  @override
  String failedToDeleteGroup(String error) {
    return 'Failed to delete group: $error';
  }

  @override
  String confirmDeleteOption(String name) {
    return 'Are you sure you want to delete \'$name\'?';
  }

  @override
  String failedToDeleteOption(String error) {
    return 'Failed to delete option: $error';
  }

  @override
  String andMoreItems(String mainItem, int count) {
    return '$mainItem + $count more';
  }

  @override
  String headingTo(String name) {
    return 'Heading to $name';
  }

  @override
  String eta(Object time) {
    return 'ETA: $time';
  }

  @override
  String get distance => 'Distance';

  @override
  String minutesCount(int count) {
    return '$count min';
  }

  @override
  String get creatingAccount => 'Creating your account...';

  @override
  String get uploadingDocuments => 'Uploading documents...';

  @override
  String get uploadingBranding => 'Uploading branding images...';

  @override
  String get savingApplication => 'Saving your application...';

  @override
  String get applicationSubmittedSubtitle =>
      'Your restaurant application has been submitted successfully. We will review your application and notify you within 1-3 business days.';

  @override
  String stepProgress(int current, int total, String label) {
    return 'Step $current of $total: $label';
  }

  @override
  String get accountSetupSubtitle =>
      'Verify your email and phone number to get started.';

  @override
  String get submitting => 'Submitting...';

  @override
  String get businessInfoStep => 'Business Info';

  @override
  String get locationAndHoursStep => 'Location & Hours';

  @override
  String get documentsStep => 'Documents';

  @override
  String get brandingStep => 'Branding';

  @override
  String get bankInfoStep => 'Bank Info';

  @override
  String get reviewStep => 'Review';

  @override
  String get completedOrders => 'Completed Orders';

  @override
  String get cancelledOrders => 'Cancelled Orders';

  @override
  String get searchOrdersHint => 'Search by order ID or customer...';

  @override
  String get allOrders => 'All Orders';

  @override
  String ordersFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'orders',
      one: 'order',
    );
    return '$count $_temp0 found';
  }

  @override
  String get configureDeliveryFees =>
      'Configure how delivery fees are calculated for your orders';

  @override
  String get deliveryFeeMode => 'Delivery Fee Mode';

  @override
  String get fixedDeliveryFee => 'Fixed Delivery Fee';

  @override
  String get distanceBasedFeeLabel => 'Distance-Based Fee';

  @override
  String get subMode => 'Sub-Mode';

  @override
  String get pricingTiers => 'Pricing Tiers';

  @override
  String get noTiersConfigured =>
      'No tiers configured. Add a tier to get started.';

  @override
  String tierWithNumber(int number) {
    return 'Tier $number';
  }

  @override
  String get minKm => 'Min (km)';

  @override
  String get maxKm => 'Max (km)';

  @override
  String get feeEgp => 'Fee (EGP)';

  @override
  String get fixedFeeEgp => 'Fixed Fee (EGP)';

  @override
  String get baseFeeEgp => 'Base Fee (EGP)';

  @override
  String get perKmRateEgp => 'Per Km Rate (EGP)';

  @override
  String get maxDeliveryDistanceKm => 'Maximum Delivery Distance (km)';

  @override
  String get fixedFeeDescription =>
      'This fee will be charged for all orders regardless of distance';

  @override
  String get radiusDescription =>
      'Orders beyond this distance will be rejected';

  @override
  String get formulaDescription =>
      'Formula: Base Fee + (Distance × Per Km Rate)';

  @override
  String get invalidBaseFee => 'Please enter a valid base fee';

  @override
  String get invalidRadius => 'Please enter a valid delivery radius';

  @override
  String get invalidPerKmRate => 'Please enter a valid per km rate';

  @override
  String get addAtLeastOneTier => 'Please add at least one pricing tier';

  @override
  String get unsavedChangesDescription =>
      'You have unsaved changes. Are you sure you want to go back?';

  @override
  String get reviewYourApplication => 'Review Your Application';

  @override
  String get reviewInstructions =>
      'Please review all information carefully before submitting. You can tap \"Edit\" to go back and make changes.';

  @override
  String get accountAndContact => 'Account & Contact';

  @override
  String get notUploaded => 'Not uploaded';

  @override
  String get reviewDisclaimer =>
      'By submitting this application, you confirm that all information provided is accurate. Your application will be reviewed within 1-3 business days.';

  @override
  String get notConfigured => 'Not configured';

  @override
  String get tapToChange => 'Tap to change';

  @override
  String get am => 'AM';

  @override
  String get pm => 'PM';

  @override
  String get descriptionPlaceholder => 'Description';

  @override
  String deliveryTimeRange(int min, int max) {
    return '$min – $max min';
  }

  @override
  String timeRange(String open, String close) {
    return '$open – $close';
  }

  @override
  String failedWithMessage(String error) {
    return 'Failed: $error';
  }

  @override
  String error(String error) {
    return 'Error: $error';
  }

  @override
  String get egyptian => 'Egyptian';

  @override
  String get lebanese => 'Lebanese';

  @override
  String get syrian => 'Syrian';

  @override
  String get italian => 'Italian';

  @override
  String get fastFood => 'Fast Food';

  @override
  String get seafood => 'Seafood';

  @override
  String get grills => 'Grills';

  @override
  String get desserts => 'Desserts';

  @override
  String get beverages => 'Beverages';

  @override
  String get healthy => 'Healthy';

  @override
  String get indian => 'Indian';

  @override
  String get turkish => 'Turkish';

  @override
  String get chinese => 'Chinese';

  @override
  String get japanese => 'Japanese';

  @override
  String get mexican => 'Mexican';

  @override
  String get setHours => 'Set Hours';

  @override
  String get businessDocuments => 'Business Documents';

  @override
  String get provideBusinessDocs =>
      'Upload required legal documents for your restaurant.';

  @override
  String get commercialRegistration => 'Commercial Registration';

  @override
  String get commercialRegistrationDesc =>
      'Official commercial registration certificate';

  @override
  String get businessLicense => 'Business License';

  @override
  String get businessLicenseDesc =>
      'Valid business/restaurant operating license';

  @override
  String get healthCertificate => 'Health Certificate';

  @override
  String get healthCertificateDesc =>
      'Health and safety inspection certificate';

  @override
  String get taxRegistration => 'Tax Registration';

  @override
  String get taxRegistrationDesc => 'Tax registration card or certificate';

  @override
  String get restaurantBranding => 'Restaurant Branding';

  @override
  String get uploadLogoCover =>
      'Upload your restaurant logo and cover photo. These will be shown to customers.';

  @override
  String get squareImageRecommended =>
      'Square image recommended (e.g. 512x512).';

  @override
  String get tapToUploadLogo => 'Tap to upload logo';

  @override
  String get coverPhoto => 'Cover Photo';

  @override
  String get wideImageRecommended => 'Wide image recommended (e.g. 1200x600).';

  @override
  String get tapToUploadCover => 'Tap to upload cover';

  @override
  String get imagesRequiredToProceed => 'Both images are required to proceed.';

  @override
  String get bankAccountDetails => 'Bank Account Details';

  @override
  String get payoutInfoDesc =>
      'Provide your bank account information for receiving payments.';

  @override
  String get bankName => 'Bank Name';

  @override
  String get bankNameHint => 'e.g: CIB, QNB, NBE...';

  @override
  String get bankNameRequired => 'Bank Name is required';

  @override
  String get accountHolderName => 'Account Holder Name';

  @override
  String get accountHolderNameHint => 'Name as it appears on bank records';

  @override
  String get accountHolderNameRequired => 'Account Holder Name is required';

  @override
  String get accountNumberIban => 'Account Number / IBAN';

  @override
  String get accountNumberIbanHint => 'Enter your full IBAN or account number';

  @override
  String get accountNumberIbanRequired => 'Account Number / IBAN is required';

  @override
  String get branchNameOptional => 'Branch Name (Optional)';

  @override
  String get branchNameHint => 'e.g: Maadi, Zamalek...';

  @override
  String get bankSecurityNote => 'Security Note';

  @override
  String get bankSecurityDesc =>
      'Your bank details are kept secure and encrypted.';

  @override
  String get iban => 'IBAN';

  @override
  String get ibanHint => 'EG XX XXXX XXXX XXXX XXXX XXXX';

  @override
  String get ibanRequired => 'IBAN is required';

  @override
  String get ibanMustStartWithEG => 'IBAN must start with EG';

  @override
  String ibanLengthValidation(int length) {
    return 'IBAN must be between 15 and 34 characters (current: $length)';
  }

  @override
  String get driverPersonalInfo => 'Driver Personal Info';

  @override
  String get provideBasicDetails => 'Provide your basic details';

  @override
  String get fullName => 'Full Name';

  @override
  String get enterFullName => 'Enter your full name';

  @override
  String get nameAlphaOnly => 'Name must contain only letters';

  @override
  String get dateOfBirth => 'Date of Birth';

  @override
  String get nationalId => 'National ID';

  @override
  String get nationalIdNumber => 'National ID Number';

  @override
  String get nationalIdRequired => 'National ID number is required';

  @override
  String get nationalIdLength => 'National ID must be exactly 14 digits';

  @override
  String get nationalIdDesc => 'Front and back of your national ID';

  @override
  String get driversLicense => 'Driver\'s License';

  @override
  String get driversLicenseDesc => 'Valid driver\'s license';

  @override
  String get vehicleRegistration => 'Vehicle Registration';

  @override
  String get vehicleRegistrationDesc => 'Valid vehicle registration';

  @override
  String get vehicleInsurance => 'Vehicle Insurance';

  @override
  String get vehicleInsuranceDesc => 'Valid vehicle insurance';

  @override
  String get policeClearance => 'Police Clearance';

  @override
  String get policeClearanceDesc => 'Recent police clearance certificate';

  @override
  String get facePhoto => 'Face Photo';

  @override
  String get facePhotoDesc => 'Clear photo of your face';

  @override
  String get vehiclePhoto => 'Vehicle Photo';

  @override
  String get vehiclePhotoDesc => 'Clear photo of your vehicle';

  @override
  String get requiredDocuments => 'Required Documents';

  @override
  String get uploadClearPhotos =>
      'Upload clear photos or scans of the required documents';

  @override
  String tapToUploadDoc(String doc) {
    return 'Tap to upload $doc';
  }

  @override
  String get uploaded => 'Uploaded';

  @override
  String get vehicleInfo => 'Vehicle Information';

  @override
  String get provideVehicleDetails => 'Provide details about your vehicle';

  @override
  String get vehicleType => 'Vehicle Type';

  @override
  String get car => 'Car';

  @override
  String get motorcycle => 'Motorcycle';

  @override
  String get cycle => 'Cycle';

  @override
  String get cycleType => 'Cycle Type';

  @override
  String get normalCycle => 'Normal Cycle';

  @override
  String get electronicCycle => 'Electronic Cycle';

  @override
  String get selectCycleType => 'Select a cycle type';

  @override
  String get make => 'Make';

  @override
  String get makeRequired => 'Make is required';

  @override
  String get specifyMake => 'Specify Make';

  @override
  String get enterBrandManually => 'Enter brand manually';

  @override
  String get model => 'Model';

  @override
  String get corollaCivic => 'e.g., Corolla, Civic';

  @override
  String get modelRequired => 'Model is required';

  @override
  String get year => 'Year';

  @override
  String get yearRequired => 'Year is required';

  @override
  String get invalidYear => 'Invalid year';

  @override
  String get exactColor => 'Exact Color';

  @override
  String get matteBlack => 'e.g., Matte Black';

  @override
  String get colorRequired => 'Color is required';

  @override
  String get ownerFullName => 'Owner Full Name';

  @override
  String get restaurantPhone => 'Restaurant Phone';

  @override
  String vendorNameLabel(String vendorType) {
    return '$vendorType Name';
  }

  @override
  String vendorNameHint(String vendorType) {
    return 'Enter $vendorType name';
  }

  @override
  String vendorNameRequired(String vendorType) {
    return '$vendorType Name is required';
  }

  @override
  String vendorPhoneLabel(String vendorType) {
    return '$vendorType Phone';
  }

  @override
  String vendorPhoneHint(String vendorType) {
    return 'Enter $vendorType phone';
  }

  @override
  String vendorPhoneRequired(String vendorType) {
    return '$vendorType Phone is required';
  }

  @override
  String vendorBrandingTitle(String vendorType) {
    return '$vendorType Branding';
  }

  @override
  String vendorLogoLabel(String vendorType) {
    return '$vendorType Logo';
  }

  @override
  String get noCuisinesAvailable => 'No cuisines available';

  @override
  String get contactInfoTitle => 'Contact Information';

  @override
  String get contactInfoSubtitle =>
      'Provide contact details for the business owner and restaurant.';

  @override
  String get ownerEmail => 'Owner Email';

  @override
  String get ownerEmailHint => 'your.email@example.com';

  @override
  String get ownerPhone => 'Owner Phone';

  @override
  String get ownerPhoneHint => '+20 1XX XXX XXXX';

  @override
  String get contactRestaurantPhoneHint => 'Customer-facing phone number';

  @override
  String get contactRestaurantPhoneRequired => 'Restaurant phone is required';

  @override
  String get fullAddress => 'Full Address';

  @override
  String get city => 'City';

  @override
  String get newSection => 'New Section';

  @override
  String get enterSectionName => 'Enter section name';

  @override
  String get addNewSection => 'Add New Section';

  @override
  String get active => 'Active';

  @override
  String get onSale => 'On Sale';

  @override
  String get tapAddItemToCreate =>
      'Tap \'Add Item\' to create your first menu item';

  @override
  String get failedToDeleteItem => 'Failed to delete item';

  @override
  String get accountSetup => 'Account Setup';

  @override
  String get fillDetailsToGetStarted => 'Fill out your details to get started';

  @override
  String get applicationSubmittedSuccess =>
      'Your application has been submitted successfully!';

  @override
  String get enterCity => 'Enter city';

  @override
  String get businessInfo => 'Business Information';

  @override
  String get provideBusinessDetails => 'Provide your business details';

  @override
  String get enterRestaurantName => 'Enter restaurant name';

  @override
  String get enterDescription => 'Enter description';

  @override
  String get enterOwnerName => 'Enter owner name';

  @override
  String get selectCuisinesPrompt => 'Select at least one cuisine type';

  @override
  String get selectAtLeastOneCuisine => 'Please select at least one cuisine';

  @override
  String get enterRestaurantPhone => 'Enter restaurant phone';

  @override
  String get phoneHint => 'e.g., 01012345678';

  @override
  String get whereIsRestaurant => 'Where is your restaurant located?';

  @override
  String get streetBuildingFloor => 'Street, Building, Floor';

  @override
  String get addressRequired => 'Address is required';

  @override
  String get cityRequired => 'City is required';

  @override
  String get pinpointLocation => 'Pinpoint Location';

  @override
  String get locationNotSet => 'Location not set';

  @override
  String get setOpeningClosingTimes => 'Set opening and closing times';

  @override
  String get noRestaurantFound => 'No restaurant found';

  @override
  String get completeRestaurantSetup =>
      'Please complete your restaurant profile setup';

  @override
  String get searchMenuItems => 'Search menu items…';

  @override
  String get totalItems => 'Total Items';

  @override
  String get tapToUploadCoverImage => 'Tap to upload cover image';

  @override
  String get optional => 'Optional';

  @override
  String get deliveryRadiusLabel => 'Delivery Radius';

  @override
  String updated(String item) {
    return '$item updated successfully';
  }

  @override
  String get statusClosed => 'Closed';

  @override
  String get branding => 'Branding';

  @override
  String get uploading => 'Uploading...';

  @override
  String get tapToUpload => 'Tap to upload';

  @override
  String get uploadedDocuments => 'Uploaded Documents';

  @override
  String documentWithIndex(String index) {
    return 'Document $index';
  }

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get currencySymbol => '\$';

  @override
  String get promotions => 'Promotions';

  @override
  String get reviews => 'Reviews';

  @override
  String get contactUs => 'Contact Us';

  @override
  String get restaurantDashboard => 'Restaurant Dashboard';

  @override
  String get paymentCash => 'Cash';

  @override
  String get paymentCard => 'Card';

  @override
  String get paymentWallet => 'Wallet';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusFailed => 'Failed';

  @override
  String get statusActive => 'Active';

  @override
  String get statusSuspended => 'Suspended';

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
      'Edit payment method functionality will be implemented here.';

  @override
  String egpAmount(String amount) {
    return 'EGP $amount';
  }

  @override
  String reportedOnDate(String date) {
    return 'Reported on $date';
  }

  @override
  String disputeId(String id) {
    return 'Dispute - $id';
  }

  @override
  String disputeStatusUpdated(String id, String status) {
    return 'Dispute $id status updated to $status';
  }

  @override
  String allDisputesCount(int count) {
    return 'All Disputes ($count)';
  }

  @override
  String userStatusUpdated(String id, String status) {
    return 'User $id status updated to $status';
  }

  @override
  String downloadingReport(String report) {
    return 'Downloading $report...';
  }

  @override
  String previewingReport(String report) {
    return 'Previewing $report...';
  }

  @override
  String noTypeApplications(String type) {
    return 'No $type applications';
  }

  @override
  String rejectSection(String section) {
    return 'Reject $section';
  }

  @override
  String allCountParentheses(String count) {
    return 'All ($count)';
  }

  @override
  String nameValue(String value) {
    return 'Name: $value';
  }

  @override
  String emailValue(String value) {
    return 'Email: $value';
  }

  @override
  String phoneValue(String value) {
    return 'Phone: $value';
  }

  @override
  String roleValue(String value) {
    return 'Role: $value';
  }

  @override
  String statusValue(String value) {
    return 'Status: $value';
  }

  @override
  String joinDateValue(String value) {
    return 'Join Date: $value';
  }

  @override
  String deleteConfirmItem(String item) {
    return 'Are you sure you want to delete \"$item\"?\nThis action cannot be undone.';
  }

  @override
  String errorValue(String error) {
    return 'Error: $error';
  }

  @override
  String failedToUpdate(String error) {
    return 'Failed to update: $error';
  }

  @override
  String rejectionReasonValue(String reason) {
    return 'Rejection reason: $reason';
  }

  @override
  String rejectItem(String item) {
    return 'Reject \"$item\"';
  }

  @override
  String orderIdValue(String id) {
    return 'Order ID: $id';
  }

  @override
  String customerValue(String name) {
    return 'Customer: $name';
  }

  @override
  String restaurantValue(String name) {
    return 'Restaurant: $name';
  }

  @override
  String amountEgpValue(String amount) {
    return 'Amount: EGP $amount';
  }

  @override
  String itemsValue(String count) {
    return 'Items: $count';
  }

  @override
  String dateValue(String date) {
    return 'Date: $date';
  }

  @override
  String timeValue(String time) {
    return 'Time: $time';
  }

  @override
  String failedToReorder(String error) {
    return 'Failed to reorder: $error';
  }

  @override
  String callCustomerName(String name) {
    return 'Call $name?';
  }

  @override
  String callRestaurantName(String name) {
    return 'Call $name?';
  }

  @override
  String assignDriverId(String id) {
    return 'Assign $id';
  }

  @override
  String failedToSave(String error) {
    return 'Failed to save: $error';
  }

  @override
  String payoutFrequencySet(String freq) {
    return 'Payout frequency set to $freq';
  }

  @override
  String minimumPayoutSet(String amount) {
    return 'Minimum payout set to \$$amount';
  }

  @override
  String editMethodName(String name) {
    return 'Edit $name';
  }

  @override
  String expiresDate(String date) {
    return 'Expires $date';
  }

  @override
  String addWalletType(String type) {
    return 'Add $type';
  }

  @override
  String enterWalletPhone(String type) {
    return 'Enter your $type phone number';
  }

  @override
  String restaurantIndex(String index) {
    return 'Restaurant $index';
  }

  @override
  String lastActiveDate(String date) {
    return 'Last active: $date';
  }

  @override
  String get networkError => 'Network error, please check your connection.';

  @override
  String get serverError => 'Server connection failed.';

  @override
  String get invalidCredentials => 'Invalid email or password.';

  @override
  String get emailInUse => 'This email is already registered.';

  @override
  String get tooManyRequests => 'Too many requests. Please try again later.';

  @override
  String get authFailed => 'Authentication failed. Please try again.';

  @override
  String get unexpectedError => 'An unexpected error occurred.';

  @override
  String get driverDeliveries => 'Deliveries';

  @override
  String get driverHistory => 'History';

  @override
  String get youAreOnline => 'You\'re Online';

  @override
  String get youAreOffline => 'You\'re Offline';

  @override
  String get readyToAcceptDeliveries => 'Ready to accept deliveries';

  @override
  String get notReceivingRequests => 'You will not receive delivery requests';

  @override
  String get goOffline => 'Go Offline';

  @override
  String get goOnline => 'Go Online';

  @override
  String get todaysEarnings => 'Today\'s Earnings';

  @override
  String get keepDeliveringToIncrease =>
      'Keep delivering to increase your earnings!';

  @override
  String get activeTrips => 'Active';

  @override
  String get pendingTrips => 'Pending';

  @override
  String get totalTrips => 'Total Trips';

  @override
  String get confirmDeliveryProceed =>
      'Have you delivered all items to the customer?';

  @override
  String get turnOnToStartReceivingOrders =>
      'Turn on to start receiving orders';

  @override
  String get cantGoOfflineWithActiveOrder =>
      'You can\'t go offline while you have an active order';

  @override
  String get chooseTheFoodYouLove => 'Choose the Food you love';

  @override
  String get orderBestDishes =>
      'Order the best dishes from your favorite restaurants with fast delivery to your door.';

  @override
  String get searchForFoodItem => 'Search for a food item...';

  @override
  String get orderNow => 'Order Now';

  @override
  String get whatDoYouNeed => 'WHAT ARE WE DELIVERING TODAY?';

  @override
  String get soon => 'Soon';

  @override
  String get fastDelivery => 'Fast Delivery';

  @override
  String get orderFoodBestRestaurants =>
      'Order food from the best restaurants near you with lightning-fast delivery.';

  @override
  String get browseRestaurantsBtn => 'Browse Restaurants';

  @override
  String get activeOrdersTab => 'Active';

  @override
  String get pastOrdersTab => 'Past';

  @override
  String get noActiveOrders => 'No active orders';

  @override
  String get noPastOrders => 'No past orders';

  @override
  String get activeOrdersAppearHere => 'Your active orders will appear here';

  @override
  String get pastOrdersAppearHere => 'Your past orders will appear here';

  @override
  String get reorder => 'Reorder';

  @override
  String get rate => 'Rate';

  @override
  String get etaCalculating => 'Calculating...';

  @override
  String get orderTimeline => 'Order Timeline';

  @override
  String get waitingForRestaurant => 'Waiting for restaurant';

  @override
  String get dispatching => 'Dispatching';

  @override
  String get waitingToAssignDriver => 'Waiting to assign driver';

  @override
  String get outForDelivery => 'Out for Delivery';

  @override
  String get waitingForPickUp => 'Waiting for pick up';

  @override
  String get account => 'Account';

  @override
  String get driverRole => 'DRIVER';

  @override
  String get drawerWallet => 'Wallet';

  @override
  String get drawerLogout => 'Logout';

  @override
  String get drawerHelpSupport => 'Help & Support';

  @override
  String get excelImportBtn => 'Import';

  @override
  String get excelImportTitle => 'Bulk Import from Excel';

  @override
  String excelImportPreviewTitle(int count) {
    return 'Preview ($count rows)';
  }

  @override
  String get excelImportingTitle => 'Importing…';

  @override
  String get excelImportDoneTitle => 'Import Complete';

  @override
  String get excelImportStep1 => '1. Download the template Excel file below.';

  @override
  String get excelImportStep2 =>
      '2. Fill in your items — Section and Available columns have dropdowns.';

  @override
  String get excelImportStep3 =>
      '3. Upload the filled file and preview before importing.';

  @override
  String get excelImportStep4 =>
      '4. Add item images after import using the edit button on each item.';

  @override
  String excelImportSectionsLabel(String vendorType) {
    return 'Sections for $vendorType';
  }

  @override
  String get excelImportDownloadTemplate => 'Download Template';

  @override
  String get excelImportUploadFile => 'Upload Excel File (.xlsx)';

  @override
  String excelImportFailedTemplate(String error) {
    return 'Failed to generate template: $error';
  }

  @override
  String get excelImportCouldNotRead => 'Could not read file bytes.';

  @override
  String get excelImportNoData =>
      'No data rows found. Make sure the file has a \"Menu Items\" sheet and data starting from row 3.';

  @override
  String excelImportFailedRead(String error) {
    return 'Failed to read file: $error';
  }

  @override
  String get excelImportFailed =>
      'Import failed. Check your connection and try again.';

  @override
  String excelImportSuccessCount(int count) {
    return '$count items imported successfully.';
  }

  @override
  String get excelImportAddImages =>
      'To add item images, tap the edit button on any item in your menu.';

  @override
  String excelImportSkippedRows(int count) {
    return '$count row(s) were skipped.';
  }

  @override
  String get excelImportDownloadSkipLog => 'Download Skip Log';

  @override
  String get excelImportClose => 'Close';

  @override
  String get excelImportReupload => 'Re-upload';

  @override
  String excelImportConfirmBtn(int count) {
    return 'Import $count Item(s)';
  }

  @override
  String get excelImportValid => 'valid';

  @override
  String get excelImportErrors => 'errors (skipped)';

  @override
  String excelImportProgress(int current, int total) {
    return 'Importing item $current of $total…';
  }

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get editProfileSubtitle => 'Update your personal information';

  @override
  String get changePasswordSubtitle => 'Update your login password';

  @override
  String get savedAddressesSubtitle => 'Manage your delivery locations';

  @override
  String get preferencesSubtitle => 'Manage your language and display settings';

  @override
  String get liveChatSubtitle => 'Chat with our support agents';

  @override
  String get emailUs => 'Email Us';

  @override
  String get emailUsSubtitle => 'support@zspeed.app';

  @override
  String get callUs => 'Call Us';

  @override
  String get callUsSubtitle => '+20 100 000 0000';

  @override
  String get faqSubtitle => 'Frequently asked questions';

  @override
  String get userGuideSubtitle => 'Learn how to use the app';

  @override
  String get videoTutorialsSubtitle => 'Watch step-by-step guides';

  @override
  String get contactSupportTitle => 'Contact Support';

  @override
  String get contactSupportSubtitle => 'Reach out to our support team';

  @override
  String get resourcesTitle => 'Resources';

  @override
  String get orderDelivered => 'Delivered';

  @override
  String get enjoyYourMeal => 'Enjoy your meal!';

  @override
  String get arrivingSoon => 'Arriving soon';

  @override
  String get driverAssigned => 'Driver assigned!';

  @override
  String get searchingForNearbyDriver => 'Searching for nearby driver...';

  @override
  String get noDriversAvailableVicinity => 'No drivers available in vicinity';

  @override
  String get assigningDriver => 'Assigning driver...';

  @override
  String get verifyYourPhone => 'Verify your phone';

  @override
  String get addYourPhoneNumberUpdates =>
      'Add your phone number for order updates and delivery coordination';

  @override
  String get phoneNum => 'Phone Number';

  @override
  String get sendCode => 'Send Code';

  @override
  String get illDoThisLater => 'I\'ll do this later';

  @override
  String get verifyPhone => 'Verify Phone';

  @override
  String get minOrderInfo => 'min order';

  @override
  String get deliveryFeeInfo => 'delivery';

  @override
  String get deliveryMinInfo => 'min';

  @override
  String get noItemsInSection => 'No items in this section';

  @override
  String get viewCartBtn => 'VIEW CART';

  @override
  String get setDeliveryAddress => 'Set your delivery address';

  @override
  String get searchRestaurantsDishes =>
      'Search restaurants, dishes or cuisines...';

  @override
  String get acceptance => 'Acceptance';

  @override
  String get currentLocationUpdate => 'Current Location';

  @override
  String get updateBtn => 'Update';

  @override
  String get gpsTrackingActive =>
      'GPS tracking active - Location updates every 30 seconds';

  @override
  String get checkoutLabel => 'Checkout';

  @override
  String get orderSummaryLabel => 'Order Summary';

  @override
  String get deliveryAddressLabel => 'Delivery Address';

  @override
  String get enterYourDeliveryAddress => 'Enter your delivery address';

  @override
  String get deliveryInstructionsOptional => 'Delivery Instructions (Optional)';

  @override
  String get egRingDoorbell => 'e.g., Ring doorbell, 2nd floor';

  @override
  String get placeOrderLabel => 'Place Order';

  @override
  String get subtotalLabel => 'Subtotal';

  @override
  String get deliveryFeeLabel => 'Delivery Fee';

  @override
  String itemsCount(int count) {
    return 'items $count';
  }

  @override
  String get searchRestaurantsPlaceholder =>
      '...Search restaurants, dishes or cuisines';

  @override
  String get setYourDeliveryAddress => 'Set your delivery address';

  @override
  String get customerPortal => 'CUSTOMER PORTAL';

  @override
  String get sortByLabel => 'Sort by';

  @override
  String get fastFoodCategory => 'Fast Food';

  @override
  String get egyptianCategory => 'Egyptian';

  @override
  String get allCategory => 'All';

  @override
  String get editProfileLabel => 'Edit Profile';

  @override
  String get updatePersonalInfo => 'Update your personal information';

  @override
  String get changePasswordLabel => 'Change Password';

  @override
  String get updateLoginPassword => 'Update your login password';

  @override
  String get paymentMethodsLabel => 'Payment Methods';

  @override
  String get managePaymentOptions => 'Manage your payment options';

  @override
  String get savedAddressesLabel => 'Saved Addresses';

  @override
  String get manageDeliveryLocations => 'Manage your delivery locations';

  @override
  String get preferencesLabel => 'Preferences';

  @override
  String get notificationsLabel => 'Notifications';

  @override
  String get receiveOrderUpdates => 'Receive order updates and promotions';

  @override
  String get languageLabel => 'Language';

  @override
  String get choosePreferredLanguage => 'Choose your preferred language';

  @override
  String get englishLanguage => 'English';

  @override
  String get arabicLanguage => 'Arabic';

  @override
  String get verifyPhoneTitle => 'Verify your phone';

  @override
  String get verifyPhoneSubtitle =>
      'Add your phone number for order updates and delivery coordination.';

  @override
  String get phoneNumberPlaceholder => 'Phone Number';

  @override
  String get sendCodeButton => 'Send Code';

  @override
  String get deliveryDriver => 'Delivery Driver';

  @override
  String get driverNotAssignedYet => 'Driver not assigned yet';

  @override
  String get assignDriverOnceReady =>
      'We\'ll assign a driver once your order is ready';

  @override
  String get paymentSection => 'Payment';

  @override
  String welcomeBackToast(String firstName) {
    return 'Welcome back, $firstName! 👋';
  }

  @override
  String get whatAreYouCravingToday => 'What are you craving today?';

  @override
  String get chooseFoodYouLove => 'Choose Food You Love';

  @override
  String get selectLocationOnMap => 'Select Location on Map';

  @override
  String get tapToPinYourDeliveryLocation =>
      'Tap to pin your delivery location';

  @override
  String get deliveryLocation => 'Delivery Location';

  @override
  String get signOut => 'Sign Out';

  @override
  String get signOutWarning =>
      'You will be signed out of your account. Sign in again to continue.';

  @override
  String get logoutFailed => 'Logout failed';

  @override
  String get role => 'Role';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get resetPasswordInstructions =>
      'Enter your email and we\'ll send a reset link.';

  @override
  String get sendResetLink => 'Send Reset Link';

  @override
  String get resetLinkSent => 'Reset link sent! Check your inbox.';

  @override
  String get failedToSendResetEmail => 'Failed to send reset email. Try again.';

  @override
  String get signUpFailed => 'Sign up failed';

  @override
  String get loginFailed => 'Login failed';

  @override
  String get googleSignInFailed => 'Google sign-in failed';

  @override
  String get signInWithPhone => 'Sign in with Phone';

  @override
  String get phoneVerificationSmsHint =>
      'We\'ll send a verification code via SMS';

  @override
  String get enterValidPhoneNumber =>
      'Enter a valid phone number (e.g. 01012345678 or +201012345678)';

  @override
  String get failedToSendCode => 'Failed to send code';

  @override
  String get autoVerificationFailed => 'Auto-verification failed';

  @override
  String get failedToSendSms => 'Failed to send SMS';

  @override
  String get verifyAndSignIn => 'Verify & Sign In';

  @override
  String get sendVerificationCode => 'Send Verification Code';

  @override
  String get enterSixDigitCode => 'Enter the 6-digit code';

  @override
  String get verificationFailed => 'Verification failed';

  @override
  String get invalidCode => 'Invalid code';

  @override
  String get change => 'Change';

  @override
  String get resendCode2 => 'Resend Code';

  @override
  String get fullNameHint => 'e.g. Ahmed Hassan';

  @override
  String get fullNameRequired => 'Please enter your name';

  @override
  String get nameTooShort => 'Name is too short';

  @override
  String get weNeedYourName => 'We need your name for orders and delivery.';

  @override
  String get failedToSaveName => 'Failed to save name';

  @override
  String get verifyYourEmail => 'Verify your email';

  @override
  String get emailVerified => 'Email Verified!';

  @override
  String get sentSixDigitCodeTo => 'We\'ve sent a 6-digit code to:';

  @override
  String get emailVerifiedSuccessfully =>
      'Your email has been verified successfully!';

  @override
  String get failedToSendVerificationCode =>
      'Failed to send verification code.';

  @override
  String get failedToSendVerificationCodeRetry =>
      'Failed to send verification code. Please try again.';

  @override
  String get pleaseEnterSixDigitCode => 'Please enter the 6-digit code.';

  @override
  String get invalidCodeError => 'Invalid code.';

  @override
  String get verificationFailedRetry =>
      'Verification failed. Please try again.';

  @override
  String get verifyCode => 'Verify Code';

  @override
  String get sending => 'Sending...';

  @override
  String resendInSeconds(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get illVerifyLater => 'I\'ll verify later';

  @override
  String get chooseYourRole => 'Choose Your Role';

  @override
  String get selectHowYouWantToUse =>
      'Select how you want to use Z Speed Delivery';

  @override
  String get roleCustomer => 'Customer';

  @override
  String get roleCustomerSubtitle => 'Order food & track delivery';

  @override
  String get roleDriver => 'Driver';

  @override
  String get roleDriverSubtitle => 'Deliver orders & earn money';

  @override
  String get roleVendor => 'Vendor / Partner';

  @override
  String get roleVendorSubtitle => 'Restaurant, Supermarket or Pharmacy';

  @override
  String get roleAdmin => 'Administrator';

  @override
  String get roleAdminSubtitle => 'Full platform management';

  @override
  String get selected => '✓ Selected';

  @override
  String get adminManagement => 'Admin Management';

  @override
  String get addAdmin => 'Add Admin';

  @override
  String get addNewAdmin => 'Add New Admin';

  @override
  String get searchAdmins => 'Search admins...';

  @override
  String get adminsList => 'Admins List';

  @override
  String get adminColumnHeader => 'Admin';

  @override
  String get joinedColumnHeader => 'Joined';

  @override
  String get noAdminUsersFound => 'No admin users found';

  @override
  String get adminCreatedSuccessfully => 'Admin created successfully';

  @override
  String get userManagement => 'User Management';

  @override
  String get usersList => 'Users List';

  @override
  String get userColumnHeader => 'User';

  @override
  String get actionsColumnHeader => 'Actions';

  @override
  String get searchUsers => 'Search users...';

  @override
  String get allRoles => 'All Roles';

  @override
  String get allStatuses => 'All Statuses';

  @override
  String get restaurantManagement => 'Restaurant Management';

  @override
  String get vendorManagement => 'Vendor Management';

  @override
  String get addVendor => 'Add Vendor';

  @override
  String get noVendorsFound => 'No vendors found';

  @override
  String get changeVendorType => 'Change Vendor Type';

  @override
  String get allFilter => 'All';

  @override
  String get systemSettings => 'System Settings';

  @override
  String get localizationSection => 'Localization';

  @override
  String get platformConfiguration => 'Platform Configuration';

  @override
  String get platformCommission => 'Platform Commission';

  @override
  String get maintenanceMode => 'Maintenance Mode';

  @override
  String get platformIsOffline => 'Platform is offline';

  @override
  String get platformIsLive => 'Platform is live';

  @override
  String get deleteSection => 'Delete Section';

  @override
  String deleteSectionConfirm(String name) {
    return 'Delete \"$name\"? This cannot be undone.';
  }

  @override
  String get editSection => 'Edit Section';

  @override
  String get statusColumnHeader => 'Status';

  @override
  String get roleColumnHeader => 'Role';

  @override
  String get emailLabel => 'Email';

  @override
  String qtyLabel(String qty) {
    return 'Qty: $qty';
  }

  @override
  String get popular => 'Popular';

  @override
  String get quantity => 'Quantity';

  @override
  String get customizeYourItem => 'Customize Your Item';

  @override
  String get specialInstructions => 'Special Instructions';

  @override
  String get specialInstructionsHint => 'e.g., No onions, extra spicy...';

  @override
  String get addToCartButton => 'Add to Cart';

  @override
  String itemsInSection(int count) {
    return '$count item';
  }

  @override
  String itemsInSectionPlural(int count) {
    return '$count items';
  }

  @override
  String addedToCartItem(String name) {
    return '$name added to cart';
  }

  @override
  String get viewCart => 'VIEW CART';

  @override
  String get replaceCartContent =>
      'Your cart contains items from another restaurant. Would you like to clear the cart and add this item instead?';

  @override
  String vendorCurrentlyClosed(String vendorType) {
    return 'This $vendorType is currently closed. You can browse the menu but ordering is unavailable.';
  }

  @override
  String get ownerChip => 'Owner';

  @override
  String get free => 'Free';

  @override
  String addonPricePrefix(String price) {
    return '+EGP $price';
  }

  @override
  String get choose1Option => 'Choose 1 option';

  @override
  String get chooseUpTo1Option => 'Choose up to 1 option (optional)';

  @override
  String chooseMinToMax(int min, int max) {
    return 'Choose $min to $max options';
  }

  @override
  String chooseAtLeast(int min) {
    return 'Choose at least $min option';
  }

  @override
  String chooseAtLeastPlural(int min) {
    return 'Choose at least $min options';
  }

  @override
  String chooseUpToMax(int max) {
    return 'Choose up to $max options (optional)';
  }

  @override
  String get chooseAnyOptions => 'Choose any number of options (optional)';

  @override
  String get topRestaurantsNearYou => 'Top Restaurants Near You';

  @override
  String get viewAll => 'View All';

  @override
  String get viewMenu => 'View Menu';

  @override
  String get openStatus => 'Open';

  @override
  String get closedStatus => 'Closed';

  @override
  String get deliverySublabel => 'delivery';

  @override
  String get minOrderSublabel => 'min order';

  @override
  String get searchSupermarkets => 'Search supermarkets or products...';

  @override
  String get searchPharmacies => 'Search pharmacies or medicines...';

  @override
  String get errorLoadingSupermarkets => 'Error loading supermarkets';

  @override
  String get errorLoadingPharmacies => 'Error loading pharmacies';

  @override
  String get errorLoadingRestaurants => 'Error loading restaurants';

  @override
  String addressRemoved(String label) {
    return '$label removed';
  }

  @override
  String addressAdded(String label) {
    return '$label added!';
  }

  @override
  String get addressLabel => 'Address';

  @override
  String get buildingOptional => 'Building / Villa (Optional)';

  @override
  String get floorAptOptional => 'Floor / Apt (Optional)';

  @override
  String get owner => 'Owner';

  @override
  String sectionItemCount(int count) {
    return '$count item';
  }

  @override
  String sectionItemCountPlural(int count) {
    return '$count items';
  }

  @override
  String addItemWithPrice(String price) {
    return 'Add item  EGP $price';
  }

  @override
  String vendorClosedLabel(String vendorType) {
    return '$vendorType Closed';
  }

  @override
  String get orderSummary => 'Order Summary';

  @override
  String get needHelpWithOrder => 'Need help with your order?';

  @override
  String qtyWithMeasure(String qty, String measure) {
    return 'Qty: $qty $measure';
  }

  @override
  String get estimatedTime => 'Estimated Time';

  @override
  String get calculating => 'Calculating...';

  @override
  String get liveTracking => 'Live Tracking';

  @override
  String get ordered => 'Ordered';

  @override
  String percentComplete(int percent) {
    return '$percent% Complete';
  }

  @override
  String get categories => 'Categories';

  @override
  String categoriesCount(int count) {
    return '$count categories';
  }

  @override
  String get quickDelivery => 'Quick Delivery';

  @override
  String get grocery => 'Grocery';

  @override
  String get drinks => 'Drinks';

  @override
  String get flowers => 'Flowers';

  @override
  String get petSupplies => 'Pet Supplies';

  @override
  String get freshOrganic => 'Fresh & Organic';

  @override
  String get bakery => 'Bakery';

  @override
  String get expired => 'Expired';

  @override
  String get week => 'Week';

  @override
  String get month => 'Month';

  @override
  String get items => 'Items';

  @override
  String tripsCount(int count) {
    return '$count trips';
  }

  @override
  String tripDateAt(String date, String time) {
    return '$date at $time';
  }

  @override
  String egpEarnings(String amount) {
    return '+EGP $amount';
  }

  @override
  String get toRestaurant => 'To Restaurant';

  @override
  String get toCustomer => 'To Customer';

  @override
  String itemsCount2(int count) {
    return '$count items';
  }

  @override
  String itemsAssigned(int count) {
    return '$count items assigned';
  }

  @override
  String get remainingToAccept => 'remaining to accept';

  @override
  String get noPendingRequests => 'No pending requests';

  @override
  String get newDeliveryRequestsWillAppear =>
      'New delivery requests will appear here';

  @override
  String get noActiveDeliveries => 'No active deliveries';

  @override
  String get acceptedOrdersWillAppear => 'Accepted orders will appear here';

  @override
  String get updateLocationFirst =>
      'Update your location first before going online';

  @override
  String get headingToRestaurant => 'Heading to Restaurant';

  @override
  String get headingToCustomer => 'Heading to Customer';

  @override
  String get rejectReason => 'Reason (optional)';

  @override
  String get rejectReasonHint => 'e.g., Too far, Busy with other delivery';

  @override
  String get areYouSureRejectRequest =>
      'Are you sure you want to reject this delivery request?';

  @override
  String get newLabel => 'NEW';

  @override
  String orderIdShort(String id) {
    return 'Order #$id';
  }

  @override
  String get callDriver => 'Call Driver';

  @override
  String get callingDriver2 => 'Calling driver:';

  @override
  String get callLabel => 'Call';

  @override
  String get messageDriver => 'Message Driver';

  @override
  String get sendMessageToDriver => 'Send a message to your driver:';

  @override
  String get typeMessageHere => 'Type your message here...';

  @override
  String get driverLocation => 'Driver Location';

  @override
  String get openingDriverLocation => 'Opening driver\'s location on map...';

  @override
  String get completeRide => 'Complete Ride';

  @override
  String get hasRideBeenCompleted =>
      'Has the ride been completed successfully?';

  @override
  String get noButton => 'No';

  @override
  String get yesComplete => 'Yes, Complete';

  @override
  String get cancelRide => 'Cancel Ride';

  @override
  String get areYouSureCancelRide =>
      'Are you sure you want to cancel this ride?';

  @override
  String get cannotBeUndone => 'This action cannot be undone.';

  @override
  String get yesCancel => 'Yes, Cancel';

  @override
  String get pickupLocation => 'Pickup location';

  @override
  String get dropoffLocation => 'Dropoff location';

  @override
  String get whereToQuestion => 'Where to?';

  @override
  String get availableRides => 'Available Rides';

  @override
  String get popularLocations => 'Popular Locations';

  @override
  String get onlineStatus => 'Online';

  @override
  String get typeYourMessage => 'Type your message...';

  @override
  String get pleaseEnterDropoff => 'Please enter a dropoff location';

  @override
  String get confirmBooking => 'Confirm Booking';

  @override
  String bookRideConfirm(String rideType, String driver, String price) {
    return 'Book $rideType with $driver for $price EGP?';
  }

  @override
  String get rideBookedSuccess =>
      'Ride booked successfully! Driver is on the way.';

  @override
  String get rideCompletedThankYou =>
      'Ride completed! Thank you for choosing Speed Rides.';

  @override
  String get rideCancelledSuccess => 'Ride cancelled successfully.';

  @override
  String get messageSent => 'Message sent';

  @override
  String get assignDrivers => 'Assign Drivers';

  @override
  String get outOfRange => 'Out of range';

  @override
  String kmFromRestaurant(String distance) {
    return '$distance km from restaurant';
  }

  @override
  String get multipleItems => 'Multiple items';

  @override
  String get perDriver => 'Per Driver';

  @override
  String totalDriversCount(int count) {
    return 'Total ($count drivers)';
  }

  @override
  String get assignedDriversSection => 'Assigned Drivers';

  @override
  String get noDriversAssigned => 'No drivers assigned yet';

  @override
  String get availableDriversSection => 'Available Drivers';

  @override
  String get sortedByDistance =>
      'Sorted by distance, rating, and acceptance rate';

  @override
  String get noAvailableDrivers => 'No available drivers online';

  @override
  String get alreadyAssigned => 'Already Assigned';

  @override
  String get assignDriverQuestion => 'Assign this driver to the order?';

  @override
  String get assignDriverNote =>
      'Note: The driver will be assigned to deliver all items in this order.';

  @override
  String removeDriverConfirm(String name) {
    return 'Are you sure you want to remove $name from this order?';
  }

  @override
  String get noActiveRide => 'No Active Ride';

  @override
  String get bookRideToGetStarted => 'Book a ride to get started';

  @override
  String get bookARide => 'Book a Ride';

  @override
  String get pickupLabel => 'PICKUP';

  @override
  String get dropoffLabel => 'DROPOFF';

  @override
  String get liveMapPlaceholder => 'Live map would display here';

  @override
  String get rideHistory => 'Ride History';

  @override
  String get noRideHistory => 'No Ride History';

  @override
  String get rideDetails => 'Ride Details';

  @override
  String get rideType => 'Ride Type';

  @override
  String etaMinutes(String minutes) {
    return '$minutes minutes';
  }

  @override
  String distanceKm(String distance) {
    return '$distance km';
  }

  @override
  String priceEgp(String price) {
    return '$price EGP';
  }

  @override
  String get calling => 'Calling...';

  @override
  String driverLabel(String name) {
    return 'Driver: $name';
  }

  @override
  String get etaLabel => 'ETA';

  @override
  String get distanceLabel => 'Distance';

  @override
  String get priceLabel => 'Price';

  @override
  String get goingToRestaurant => 'Going to Restaurant';

  @override
  String get arrivedAtRestaurant => 'Arrived at Restaurant';

  @override
  String get pickingUpOrder => 'Picking Up Order';

  @override
  String get orderPickedUp => 'Order Picked Up';

  @override
  String get deliveringToCustomer => 'Delivering to Customer';

  @override
  String get startNewTrip => 'Start New Trip';

  @override
  String get unknownStatus => 'Unknown';

  @override
  String get continueLabel => 'Continue';

  @override
  String get activeTrip => 'Active Trip';

  @override
  String get tripProgress => 'Trip Progress';

  @override
  String etaAndDistance(int minutes, String distance) {
    return 'ETA: $minutes min • $distance km';
  }

  @override
  String get fareLabel => 'Fare';

  @override
  String get pickupTitle => 'Pickup';

  @override
  String get deliveryTitle => 'Delivery';

  @override
  String get viewTripDetails => 'View Trip Details';

  @override
  String get acceptOrderToStartDriving =>
      'Accept an order from the available orders list to start driving';

  @override
  String get acceptanceRate => 'Acceptance Rate';

  @override
  String get onTimeDeliveries => 'On-time Deliveries';

  @override
  String get cancellationsLabel => 'Cancellations';

  @override
  String get avgRating => 'Avg Rating';

  @override
  String get orderIdLabel => 'Order ID';

  @override
  String estimatedTimeMin(int minutes) {
    return '$minutes min';
  }

  @override
  String get uploadFailed => 'Upload failed';

  @override
  String get personalInformation => 'Personal Information';

  @override
  String get vehicleInformation => 'Vehicle Information';

  @override
  String get vehicleColor => 'Color';

  @override
  String get plateNumberLabel => 'Plate Number';

  @override
  String get typeLabel => 'Type';

  @override
  String get reviewSubtitle =>
      'Please review all information carefully before submitting. You can tap \"Edit\" to go back and make changes.';

  @override
  String get applicationDisclaimer =>
      'By submitting this application, you confirm that all information provided is accurate. Your application will be reviewed within 1-3 business days.';

  @override
  String get basicInfo => 'Basic Info';

  @override
  String get vehicleStep => 'Vehicle';

  @override
  String get wallet => 'Wallet';

  @override
  String get currentLocation => 'Current Location';

  @override
  String get updating => 'Updating...';

  @override
  String get noDeliveryHistory => 'No Delivery History';

  @override
  String get completedDeliveriesWillAppear =>
      'Your completed deliveries will appear here';

  @override
  String get addressNotAvailable => 'Address not available';

  @override
  String get noAddressProvided => 'No address provided';

  @override
  String get orderReceivedByCustomer => 'Order Received by Customer';

  @override
  String get startNavigation => 'Start Navigation';

  @override
  String get zoomIn => 'Zoom In';

  @override
  String get zoomOut => 'Zoom Out';

  @override
  String get inAppNavigationMode => 'In-App Navigation Mode';

  @override
  String get externalGoogleMaps => 'External Google Maps';

  @override
  String get keepZSpeedAppOpen =>
      'Keep Z-SPEED app open with live turn-by-turn guidance';

  @override
  String get openTurnByTurnRoute =>
      'Open turn-by-turn route in Google Maps app';

  @override
  String get waitingForGpsCoordinates => 'Waiting for GPS coordinates...';

  @override
  String get reCenter => 'Re-center';

  @override
  String get driverSpecialty => 'Driver Specialty';

  @override
  String get delivery => 'Delivery';

  @override
  String get foodAndPackages => 'Food & Packages';

  @override
  String get passengersRides => 'Passengers / Rides';

  @override
  String couldNotCall(String phone, String error) {
    return 'Could not call $phone: $error';
  }

  @override
  String get customerPhoneNotAvailable =>
      'Customer phone number is not available.';

  @override
  String get coordinatesNotAvailable => 'Coordinates are not available.';

  @override
  String couldNotOpenMap(String error) {
    return 'Could not open map: $error';
  }

  @override
  String get exit => 'Exit';

  @override
  String get driveTowardYourDestination => 'Drive toward your destination';

  @override
  String get minLabel => 'min';

  @override
  String get hrLabel => 'hr';

  @override
  String navigationEtaLabel(String eta) {
    return 'ETA: $eta';
  }

  @override
  String inDistance(String distance) {
    return 'In $distance';
  }

  @override
  String get performanceSummary => 'Performance Summary';

  @override
  String get earningsAndPayout => 'Earnings & Payout';

  @override
  String get totalDeliveries => 'Total Deliveries';

  @override
  String get walletBalance => 'Wallet Balance';

  @override
  String get totalEarnings => 'Total Earnings';

  @override
  String completedCount(int count) {
    return '$count completed';
  }

  @override
  String reviewsCount(int count) {
    return '$count reviews';
  }

  @override
  String get noApplicationData => 'No application data found.';

  @override
  String documentNumber(int number) {
    return 'Document $number';
  }

  @override
  String get chatWithDriver => 'Chat with Driver';

  @override
  String get callingDriverTitle => 'Calling Driver';

  @override
  String get speedRides => 'Speed Rides';

  @override
  String get speedRidesSubtitle =>
      'Safe, reliable transportation in New Administrative Capital';

  @override
  String get bookRide => 'Book Ride';

  @override
  String get activeRide => 'Active Ride';

  @override
  String get history => 'History';

  @override
  String stepOfTotal(int step, int total, String label) {
    return 'Step $step of $total: $label';
  }

  @override
  String get driverDeclined => 'Driver declined';

  @override
  String get unknownRestaurant => 'Unknown Restaurant';

  @override
  String get chatWithSupportAgents => 'Chat with our support agents';

  @override
  String allCategoryNamed(Object name) {
    return 'All $name';
  }

  @override
  String get markAllRead => 'Mark all read';

  @override
  String get noNotificationsYet => 'No notifications yet';

  @override
  String get orderSummarySection => '📦 Order Summary';

  @override
  String get deliveryAddressSection => '📍 Delivery Address';

  @override
  String get deliveryInstructionsSection =>
      '📝 Delivery Instructions (Optional)';

  @override
  String get paymentMethodSection => '💳 Payment Method';

  @override
  String get promoCodeSection => '🏷 Promo Code';

  @override
  String get priceBreakdownSection => '💰 Price Breakdown';

  @override
  String get ringDoorbellHint => 'e.g., Ring doorbell, 2nd floor';

  @override
  String get mobileWallet => 'Mobile Wallet';

  @override
  String get enterPromoCode => 'Enter promo code';

  @override
  String get taxFourteen => 'Tax (14%)';

  @override
  String get discountLabel => 'Discount';

  @override
  String get totalLabel => 'Total';

  @override
  String get pleaseFixFollowing => 'Please fix the following:';

  @override
  String placeOrderAmount(String amount) {
    return 'Place Order — EGP $amount';
  }

  @override
  String get failedToPlaceOrder => 'Failed to place order';

  @override
  String kmAway(String distance) {
    return '$distance km away';
  }

  @override
  String estimatedMinutes(int min, int max) {
    return '⏱ $min–$max min';
  }

  @override
  String get fullNameLabel => 'Full Name';

  @override
  String get enterYourName => 'Enter your name';

  @override
  String get enterPhoneNumber => 'Enter phone number';

  @override
  String get enterYourAddress => 'Enter your address';

  @override
  String get cityLabel => 'City';

  @override
  String get deliveryOptionLabel => 'Delivery Option';

  @override
  String get standardDelivery => 'Standard Delivery';

  @override
  String get expressDelivery => 'Express Delivery';

  @override
  String get pickupPoint => 'Pickup Point';

  @override
  String get failedToLoadOrder => 'Failed to load order';

  @override
  String get driverWillBeAssignedSoon =>
      'We\'ll assign a driver once your order is ready';

  @override
  String get searchingForDriver => 'Searching for a driver…';

  @override
  String get driverFallback => 'Driver';

  @override
  String get cancelReasonChangedMind => 'Changed my mind';

  @override
  String get cancelReasonMistake => 'Ordered by mistake';

  @override
  String get cancelReasonTooLong => 'Taking too long';

  @override
  String get cancelReasonBetterOption => 'Found a better option';

  @override
  String get cancelReasonOther => 'Other';

  @override
  String get orderCancelledSuccess => 'Order cancelled successfully';

  @override
  String get failedToCancelOrder => 'Failed to cancel order';

  @override
  String get restaurantPreparingOrder => 'Restaurant is preparing your order';

  @override
  String get lookingForDriver => 'Looking for a driver';

  @override
  String get waitingForOrderCompletion => 'Waiting for order completion';

  @override
  String get waitingForPickup => 'Waiting for pickup';

  @override
  String get driverBeingDispatched => 'Driver is being dispatched';

  @override
  String get contactSupportLabel => 'Contact Support';

  @override
  String get deliveryService => 'DELIVERY SERVICE';

  @override
  String get faqHowUpdateMenu => 'How do I update my menu?';

  @override
  String get faqHowUpdateMenuAnswer =>
      'Go to Menu section → Tap edit button → Make changes → Save';

  @override
  String get faqManageOrders => 'How to manage orders?';

  @override
  String get faqManageOrdersAnswer =>
      'Orders tab shows all orders. Tap to view details and update status.';

  @override
  String get faqChangeHours => 'How to change restaurant hours?';

  @override
  String get faqChangeHoursAnswer =>
      'Settings → Operating Hours → Edit times for each day';

  @override
  String get faqAddStaff => 'How to add new staff members?';

  @override
  String get faqAddStaffAnswer => 'Settings → Staff Management → Add New Staff';

  @override
  String get faqPaymentIssues => 'Payment processing issues?';

  @override
  String get faqPaymentIssuesAnswer =>
      'Check Payment Settings or contact support for specific issues.';

  @override
  String get faqPrintReceipts => 'How to print receipts?';

  @override
  String get faqPrintReceiptsAnswer =>
      'Order details → Print Receipt (requires connected printer)';

  @override
  String get learnHowToUseApp => 'Learn how to use the app';

  @override
  String get watchStepByStepGuides => 'Watch step-by-step guides';

  @override
  String get blogAndUpdates => 'Blog & Updates';

  @override
  String get latestNewsAndUpdates => 'Latest news and updates';

  @override
  String get subject => 'Subject';

  @override
  String get describeYourIssue => 'Describe your issue';

  @override
  String get appVersion => 'App Version';

  @override
  String get buildNumber => 'Build Number';

  @override
  String get developerLabel => 'Developer';

  @override
  String placeOrderEgp(String amount) {
    return 'Place Order — EGP $amount';
  }

  @override
  String get paymentDetails => 'Payment Details';

  @override
  String get paymentId => 'Payment ID';

  @override
  String get paymentMethodLabel => 'Payment Method';

  @override
  String get createdAt => 'Created At';

  @override
  String get completedAt => 'Completed At';

  @override
  String get transactionId => 'Transaction ID';

  @override
  String get paymentStatusPending => 'Pending';

  @override
  String get paymentStatusCompleted => 'Completed';

  @override
  String get paymentStatusFailed => 'Failed';

  @override
  String get paymentStatusRefunded => 'Refunded';

  @override
  String get paymentMethodCash => 'Cash on Delivery';

  @override
  String get paymentMethodCard => 'Credit/Debit Card';

  @override
  String get paymentMethodWallet => 'Mobile Wallet';

  @override
  String get paymentMethodsTitle => 'Payment Methods';

  @override
  String get managePaymentMethods =>
      'Manage your payment methods for receiving payments';

  @override
  String get noPaymentMethodsSaved => 'No payment methods saved';

  @override
  String get addPaymentMethodBelow =>
      'Add a payment method below to get started';

  @override
  String get payoutSettings => 'Payout Settings';

  @override
  String payoutFrequencySetTo(String freq) {
    return 'Payout frequency set to $freq';
  }

  @override
  String minimumPayoutSetTo(String amount) {
    return 'Minimum payout set to EGP $amount';
  }

  @override
  String editMethodNameTitle(String methodName) {
    return 'Edit $methodName';
  }

  @override
  String methodUpdatedSuccess(String methodName) {
    return '$methodName updated successfully';
  }

  @override
  String get registeredPhone => 'Registered phone number';

  @override
  String get phoneRequired => 'Phone number is required';

  @override
  String get enterValidPhone => 'Enter a valid phone number';

  @override
  String get amountEgpLabel => 'Amount (EGP)';

  @override
  String get privacySettings => 'Privacy Settings';

  @override
  String get dataCollection => 'Data Collection';

  @override
  String get controlWhatData => 'Control what data we collect';

  @override
  String get dataCollectionEnabled => 'Data collection enabled';

  @override
  String get dataCollectionDisabled => 'Data collection disabled';

  @override
  String get analyticsTitle => 'Analytics';

  @override
  String get helpUsImprove => 'Help us improve by sharing usage data';

  @override
  String get analyticsEnabled => 'Analytics enabled';

  @override
  String get analyticsDisabled => 'Analytics disabled';

  @override
  String get marketingEmails => 'Marketing Emails';

  @override
  String get receivePromotionalEmails => 'Receive promotional emails';

  @override
  String get marketingEmailsEnabled => 'Marketing emails enabled';

  @override
  String get marketingEmailsDisabled => 'Marketing emails disabled';

  @override
  String get securitySettings => 'Security Settings';

  @override
  String get biometricEnabled => 'Biometric login enabled';

  @override
  String get biometricDisabled => 'Biometric login disabled';

  @override
  String get dataManagement => 'Data Management';

  @override
  String get additionalOptions => 'Additional Options';

  @override
  String get accountSection => 'Account';

  @override
  String get preferencesSection => 'Preferences';

  @override
  String get notificationsEnabledMsg => 'Notifications enabled';

  @override
  String get notificationsDisabledMsg => 'Notifications disabled';

  @override
  String get deliveryAreaLabel => 'Delivery Area';

  @override
  String get selectServiceArea => 'Select your service area';

  @override
  String get aboutSection => 'About';

  @override
  String get aboutSpeedApp => 'About Speed App';

  @override
  String get versionInfo => 'Version 1.0.0';

  @override
  String get supportContact => 'Support / Contact';

  @override
  String get getHelpContact => 'Get help and contact support';

  @override
  String get privacyPolicyLabel => 'Privacy Policy';

  @override
  String get readPrivacyPolicyLabel => 'Read our privacy policy';

  @override
  String get termsOfServiceLabel => 'Terms of Service';

  @override
  String get readTermsConditions => 'Read our terms and conditions';

  @override
  String get logoutButton => 'Logout';

  @override
  String get speedRidesVersion => 'Speed Rides v1.0.0';

  @override
  String languageChangedTo(String language) {
    return 'Language changed to $language';
  }

  @override
  String get loadingItems => 'Loading items...';

  @override
  String get noteLabel => 'Note';

  @override
  String get savingLabel => 'Saving...';

  @override
  String get applicationStatus => 'Application Status';

  @override
  String get statusApproved => 'Approved';

  @override
  String get statusUnderReview => 'Under Review';

  @override
  String get editWarningContent =>
      'If you edit this section, your account will go back to pending until the admin verifies it again. Are you sure?';

  @override
  String get businessInformationSection => 'Business Information';

  @override
  String get locationAndHours => 'Location & Hours';

  @override
  String get contactInformation => 'Contact Information';

  @override
  String get bankInformation => 'Bank Information';

  @override
  String get personalInformationSection => 'Personal Information';

  @override
  String get vehicleInformationSection => 'Vehicle Information';

  @override
  String get docCommercialRegistration => 'Commercial Registration';

  @override
  String get docBusinessLicense => 'Business License';

  @override
  String get docHealthCertificate => 'Health Certificate';

  @override
  String get docTaxRegistration => 'Tax Registration';

  @override
  String get uploadDocument => 'Upload Document';

  @override
  String get changeDocument => 'Change Document';

  @override
  String get saveDocuments => 'Save Documents';

  @override
  String vendorIsOpen(String vendorLabel) {
    return '$vendorLabel is Open';
  }

  @override
  String vendorIsClosed(String vendorLabel) {
    return '$vendorLabel is Closed';
  }

  @override
  String get avgPickTime => 'Avg. Pick Time';

  @override
  String get avgFillTime => 'Avg. Fill Time';

  @override
  String get statusApprovedLabel => 'Approved';

  @override
  String get statusRejectedLabel => 'Rejected';

  @override
  String get statusPendingLabel => 'Pending';

  @override
  String get statusUnderReviewLabel => 'Under Review';

  @override
  String get applicationStatusLabel => 'Application Status';

  @override
  String get savingChanges => 'Saving...';

  @override
  String get editTooltip => 'Edit';

  @override
  String get cancelTooltip => 'Cancel';

  @override
  String get pendingReview => 'Pending Review';

  @override
  String get applicationRejectedDesc =>
      'Your application has been rejected. You can edit your profile and resubmit.';

  @override
  String get applicationPendingDesc =>
      'Your application is being reviewed by our team. You will be notified once a decision is made.';

  @override
  String get rejectionReasonLabel => 'Reason:';

  @override
  String get editAndResubmit => 'Edit & Resubmit';

  @override
  String get viewApplication => 'View Application';

  @override
  String get logoutTooltip => 'Logout';

  @override
  String get verifyLabel => 'Verify';

  @override
  String get verifiedLabel => 'Verified';

  @override
  String get emailVerifiedMsg => 'Email verified!';

  @override
  String get phoneVerifiedMsg => 'Phone verified!';

  @override
  String get pleaseVerifyEmail => 'Please verify your email';

  @override
  String get pleaseVerifyPhone => 'Please verify your phone number';

  @override
  String get closedLabel => 'Closed';

  @override
  String daySchedule(String day, String hours) {
    return '$day: $hours';
  }

  @override
  String dayScheduleClosed(String day) {
    return '$day: Closed';
  }

  @override
  String get editApprovedSectionDesc =>
      'If you edit this section, your account will go back to pending until the admin verifies it again. Are you sure?';

  @override
  String failedToUploadDocument(String error) {
    return 'Failed to upload document: $error';
  }

  @override
  String get failedToLoadDocument => 'Failed to load document';

  @override
  String get applicationDetailTitle => 'Application Detail';

  @override
  String submittedDate(String date) {
    return 'Submitted $date';
  }

  @override
  String rejectedReason(String reason) {
    return 'Rejected: $reason';
  }

  @override
  String get rejectionReasonHint => 'Reason for rejection...';

  @override
  String get noHoursProvided => 'No hours provided';

  @override
  String get approvedLabel => 'Approved';

  @override
  String get rejectedLabel => 'Rejected';

  @override
  String sectionApprovedMsg(String section) {
    return '$section approved';
  }

  @override
  String sectionRejectedMsg(String section) {
    return '$section rejected';
  }

  @override
  String get businessLicenseDoc => 'Business License';

  @override
  String get taxRegistrationDoc => 'Tax Registration';

  @override
  String notePrefixed(String note) {
    return 'Note: $note';
  }

  @override
  String addonLine(String name, String price) {
    return '+ $name (EGP $price)';
  }

  @override
  String get rateYourOrder => 'Rate your order';

  @override
  String rateDialogSubtitle(String restaurantName) {
    return 'How was your experience with $restaurantName?';
  }

  @override
  String get tapToRate => 'Tap to rate';

  @override
  String get ratingLabelTerrible => 'Terrible';

  @override
  String get ratingLabelBad => 'Bad';

  @override
  String get ratingLabelOkay => 'Okay';

  @override
  String get ratingLabelGood => 'Good';

  @override
  String get ratingLabelExcellent => 'Excellent';

  @override
  String get shareExperienceHint => 'Share your experience (optional)';

  @override
  String get pleaseSelectRating => 'Please select a rating.';

  @override
  String get failedSubmitReview => 'Failed to submit review. Please try again.';

  @override
  String get skipRating => 'Skip';

  @override
  String get submitRating => 'Submit';

  @override
  String get thankYouReview => 'Thank you for your review!';

  @override
  String get alreadyRated => 'Rated';

  @override
  String get customerReviewsTitle => 'Customer Reviews';

  @override
  String get noReviewsYet => 'No reviews yet. Be the first!';

  @override
  String get rateButtonLabel => 'Rate';

  @override
  String get phoneVerified => 'Phone Verified!';

  @override
  String get phoneVerifiedSuccessfully =>
      'Your phone number has been verified successfully!';

  @override
  String get phoneAlreadyRegistered =>
      'This phone number is already registered. Please login instead.';

  @override
  String get sessionExpired => 'Session expired. Please request a new code.';

  @override
  String get invalidPhoneNumber => 'Invalid phone number format.';

  @override
  String get invalidAppCredential =>
      'Phone verification is unavailable right now. Please try again later or contact support.';

  @override
  String get pending => 'Pending';

  @override
  String get inactive => 'Inactive';

  @override
  String get suspended => 'Suspended';

  @override
  String get banned => 'Banned';

  @override
  String get profileImage => 'Profile Image';

  @override
  String get filterByType => 'Filter by type';

  @override
  String get refreshTooltip => 'Refresh';

  @override
  String pendingTab(int count) {
    return 'Pending ($count)';
  }

  @override
  String approvedTab(int count) {
    return 'Approved ($count)';
  }

  @override
  String rejectedTab(int count) {
    return 'Rejected ($count)';
  }

  @override
  String get noPendingApplications => 'No pending applications';

  @override
  String get noApprovedApplications => 'No approved applications';

  @override
  String get noRejectedApplications => 'No rejected applications';

  @override
  String get unknownDriver => 'Unknown Driver';

  @override
  String get unknownRestaurantLabel => 'Unknown Restaurant';

  @override
  String rejectionReasonPrefix(String reason) {
    return 'Reason: $reason';
  }

  @override
  String get rejectionReasonBodyHint =>
      'Please provide a reason for rejection. This will be shown to the applicant.';

  @override
  String get rejectionReasonInputHint => 'Reason for rejection...';

  @override
  String get searchHint => 'Search...';

  @override
  String get adminPanelLabel => 'Admin Panel';

  @override
  String get driverApplicationsTitle => 'Driver Applications';

  @override
  String vendorApplicationsTitle(String vendorType) {
    return '$vendorType Applications';
  }

  @override
  String get searchByNameEmailPhone => 'Search by name, email, phone...';

  @override
  String get analyticsInsights => 'Analytics & Insights';

  @override
  String get totalUsersLabel => 'Total Users';

  @override
  String get totalOrdersLabel => 'Total Orders';

  @override
  String get totalRevenueLabel => 'Total Revenue';

  @override
  String get avgRevenueDay => 'Avg Revenue/Day';

  @override
  String get userDistribution => 'User Distribution';

  @override
  String get noUserData => 'No user data available';

  @override
  String get orderStatusBreakdown => 'Order Status Breakdown';

  @override
  String get noOrderData => 'No order data available';

  @override
  String get dailyRevenueTrend => 'Daily Revenue Trend';

  @override
  String get noRevenueData => 'No revenue data available';

  @override
  String get orderManagementTitle => 'Order Management';

  @override
  String get allOrdersLabel => 'All Orders';

  @override
  String get dateRangeLabel => 'Date Range';

  @override
  String get reportGenerationTitle => 'Report Generation';

  @override
  String get salesReport => 'Sales Report';

  @override
  String get userReport => 'User Report';

  @override
  String get restaurantReport => 'Restaurant Report';

  @override
  String get orderReport => 'Order Report';

  @override
  String generateDetailedReport(String report) {
    return 'Generate detailed $report';
  }

  @override
  String get customerNameLabel => 'Customer Name';

  @override
  String get numberOfItemsLabel => 'Number of Items';

  @override
  String get reportTypeLabel => 'Report Type';

  @override
  String get startDateLabel => 'Start Date';

  @override
  String get endDateLabel => 'End Date';

  @override
  String get restaurantNameLabel => 'Restaurant Name';

  @override
  String get categoryLabel => 'Category';

  @override
  String get ratingLabel15 => 'Rating (1-5)';

  @override
  String get cuisineTypesSection => 'Cuisine Types';

  @override
  String get noCuisineTypesYet =>
      'No cuisine types yet. Tap \"Add\" to create one.';

  @override
  String get supermarketSectionsTitle => 'Supermarket Sections';

  @override
  String get pharmacySectionsTitle => 'Pharmacy Sections';

  @override
  String get noSectionsYet => 'No sections yet. Tap \"Add\" to create one.';

  @override
  String get addSupermarketSection => 'Add Supermarket Section';

  @override
  String get addPharmacySection => 'Add Pharmacy Section';

  @override
  String get nameEnglishField => 'Name (English) *';

  @override
  String get nameArabicField => 'Name (Arabic) *';

  @override
  String get nameEnglishHint => 'e.g., Italian';

  @override
  String get nameArabicHint => 'مثال: إيطالي';

  @override
  String get tapToUploadImageOptional => 'Tap to upload image (optional)';

  @override
  String get profileInformationSection => 'Profile Information';

  @override
  String get accountDetailsSection => 'Account Details';

  @override
  String get linkedApplicationsSection => 'Linked Applications';

  @override
  String get provideRejectionReason =>
      'Provide a rejection reason that the user will see:';

  @override
  String get rejectFieldHint => 'e.g. Photo is unclear, please re-upload';

  @override
  String get emailLabel2 => 'Email';

  @override
  String get phoneLabel => 'Phone';

  @override
  String get addressLabel2 => 'Address';

  @override
  String get accountTypeLabel => 'Account Type';

  @override
  String get joinedLabel => 'Joined';

  @override
  String get lastUpdatedLabel => 'Last Updated';

  @override
  String get appliedLabel => 'Applied';

  @override
  String get approvedLabel2 => 'Approved';

  @override
  String get globalRejectionReasonLabel => 'Global Rejection Reason';

  @override
  String get driverLabel2 => 'Driver';

  @override
  String get restaurantLabel2 => 'Restaurant';

  @override
  String get applicationLabel => 'Application';

  @override
  String get submittedLabel => 'Submitted';

  @override
  String get quickActionAddUser => 'Add New User';

  @override
  String get quickActionGenerateReport => 'Generate Report';

  @override
  String get quickActionManageRestaurants => 'Manage Restaurants';

  @override
  String get quickActionSystemSettings => 'System Settings';

  @override
  String deleteOrderConfirm(String orderId) {
    return 'Are you sure you want to delete order $orderId?';
  }

  @override
  String deleteRestaurantConfirm(String name) {
    return 'Are you sure you want to delete $name?';
  }

  @override
  String deleteUserConfirm(String name) {
    return 'Are you sure you want to delete $name?';
  }

  @override
  String deleteItemType(String itemType) {
    return 'Delete $itemType';
  }

  @override
  String deleteItemConfirm(String name) {
    return 'Are you sure you want to delete \"$name\"? This action cannot be undone.';
  }

  @override
  String get changeUserStatusTitle => 'Change User Status';

  @override
  String get changeUserRoleTitle => 'Change User Role';

  @override
  String get updateOrderStatusTitle => 'Update Order Status';

  @override
  String get updateRestaurantStatusTitle => 'Update Restaurant Status';

  @override
  String get statusLabel => 'Status';

  @override
  String get roleLabel => 'Role';

  @override
  String get comingSoonSuffix => '— coming soon';

  @override
  String get platformFeeDescription =>
      'Platform fee percentage applied to orders';

  @override
  String get navDashboardTitle => 'Dashboard Overview';

  @override
  String get navDashboardSubtitle =>
      'Welcome back! Here\'s what\'s happening with your platform today.';

  @override
  String get navUserManagementTitle => 'User Management';

  @override
  String get navUserManagementSubtitle =>
      'Manage user accounts, roles, and permissions';

  @override
  String get navAnalyticsTitle => 'Analytics & Reports';

  @override
  String get navAnalyticsSubtitle => 'Detailed analytics and insights';

  @override
  String get navReviewDriversTitle => 'Review Drivers';

  @override
  String get navReviewDriversSubtitle =>
      'Review and manage driver applications';

  @override
  String get navReviewRestaurantsTitle => 'Review Restaurants';

  @override
  String get navReviewRestaurantsSubtitle =>
      'Review and manage restaurant applications';

  @override
  String get navReviewSupermarketsTitle => 'Review Supermarkets';

  @override
  String get navReviewSupermarketsSubtitle =>
      'Review and manage supermarket applications';

  @override
  String get navReviewPharmaciesTitle => 'Review Pharmacies';

  @override
  String get navReviewPharmaciesSubtitle =>
      'Review and manage pharmacy applications';

  @override
  String get navReviewBookstoresTitle => 'Review Bookstores';

  @override
  String get navReviewBookstoresSubtitle =>
      'Review and manage bookstore applications';

  @override
  String get navReviewHomeFurnishingTitle => 'Review Home & Furnishing';

  @override
  String get navReviewHomeFurnishingSubtitle =>
      'Review and manage home & furnishing applications';

  @override
  String get navSystemSettingsTitle => 'System Settings';

  @override
  String get navSystemSettingsSubtitle =>
      'Configure platform settings and preferences';

  @override
  String get navAdminManagementTitle => 'Admin Management';

  @override
  String get navAdminManagementSubtitle => 'Manage administrator accounts';

  @override
  String get pendingVerification => 'Pending Verification';

  @override
  String get userTypeAdmin => 'Admin';

  @override
  String get userTypeSuperAdmin => 'Super Admin';

  @override
  String get userTypeRestaurant => 'Restaurant';

  @override
  String get userTypeCustomer => 'Customer';

  @override
  String get userTypeDriver => 'Driver';

  @override
  String get statTotalUsers => 'Total Users';

  @override
  String get statTotalOrders => 'Total Orders';

  @override
  String get statTotalRevenue => 'Total Revenue';

  @override
  String get statPendingOrders => 'Pending Orders';

  @override
  String serviceFeeLabel(String percent) {
    return 'Service Fee ($percent%)';
  }

  @override
  String get serviceFeeSimple => 'Service Fee';

  @override
  String get continueAsGuest => 'Continue as Guest';

  @override
  String get signInRequired => 'Sign in required';

  @override
  String get signInToAction => 'Please sign in to';

  @override
  String get maybeLater => 'Maybe later';

  @override
  String get viewProfile => 'View your profile';

  @override
  String get viewOrders => 'View your orders';

  @override
  String get paymentStaleCartTitle => 'Cart Updated';

  @override
  String get paymentStaleCartDescription =>
      'Some items in your cart have changed. Please review and confirm.';

  @override
  String get paymentStaleCartUpdateCta => 'Update Cart & Try Again';

  @override
  String get paymentAttemptCapTitle => 'Payment Blocked';

  @override
  String get paymentAttemptCapMessage =>
      'You have reached the maximum number of payment attempts. Please try again later.';

  @override
  String get paymentAttemptCapNewOrderCta => 'Start a New Order';

  @override
  String get paymentBillingIncompleteTitle => 'Complete Your Profile';

  @override
  String get paymentBillingIncompleteMessage =>
      'Please complete your billing profile before making a payment.';

  @override
  String get paymentRoleForbiddenMessage =>
      'Card payments are only available for customers.';

  @override
  String get paymentAwaitingConfirmation => 'Confirming payment...';

  @override
  String get paymentSuccessTitle => 'Payment Successful';

  @override
  String get paymentSuccessMessage =>
      'Your payment has been processed successfully.';

  @override
  String get paymentFailureGenericMessage =>
      'Payment failed. Please try again.';

  @override
  String get payByCard => 'Pay by Card';

  @override
  String get securePayment => 'Secure Payment';

  @override
  String get processingPayment => 'Processing payment...';

  @override
  String get locationServicesDisabled => 'Location services are disabled.';

  @override
  String get locationPermissionDenied => 'Location permissions are denied.';

  @override
  String get locationPermissionPermanentlyDenied =>
      'Location permissions are permanently denied.';

  @override
  String get failedToGetCurrentLocation => 'Failed to get current location.';

  @override
  String get loadingLocation => 'Loading location...';

  @override
  String get selectedLocation => 'Selected Location';

  @override
  String get statusSearching => 'Searching for Driver';

  @override
  String get statusUnassigned => 'No Driver Found';

  @override
  String get recommendedProducts => 'Recommended Products';

  @override
  String get gourmetDining => 'Gourmet Dining';

  @override
  String get market => 'Market';

  @override
  String get cityTravel => 'City Travel';

  @override
  String get wellnessCheck => 'Wellness Check';

  @override
  String get curatedReads => 'Curated Reads';

  @override
  String get cozySpaces => 'Cozy Spaces';

  @override
  String supportEmailSubject(String appName, String orderId) {
    return '$appName Support (Order #$orderId)';
  }

  @override
  String supportEmailBody(String orderId) {
    return 'Hello, I need help with order #$orderId.';
  }

  @override
  String get addressDetailsTitle => 'Address Details';

  @override
  String get areaLabel => 'Area';

  @override
  String get typeApartment => 'Apartment';

  @override
  String get typeVilla => 'Villa';

  @override
  String get typeOffice => 'Office';

  @override
  String get buildingName => 'Building Name';

  @override
  String get villaNameNumber => 'Villa Name / Number';

  @override
  String get buildingCompany => 'Building / Company Name';

  @override
  String get apartmentNumber => 'Apartment Number';

  @override
  String get officeNumber => 'Office Number';

  @override
  String get floorOptional => 'Floor (Optional)';

  @override
  String get street => 'Street';

  @override
  String get mobilePhoneNumber => 'Mobile Phone Number';

  @override
  String get uniqueLandmark => 'Unique Landmark (Optional)';

  @override
  String get confirmAddressDetails => 'Confirm Address Details';

  @override
  String get phoneRequiredError => 'Phone number is required';

  @override
  String get phoneLengthError => 'Invalid phone number length';

  @override
  String get fieldRequiredError => 'This field is required';

  @override
  String get underMaintenanceTitle => 'Under Maintenance';

  @override
  String get underMaintenanceMessage =>
      'Z Speed is currently undergoing scheduled maintenance to improve our systems. We\'ll be back online shortly.';

  @override
  String get checkBackSoon => 'Please check back soon!';

  @override
  String get onlySuperAdminCanToggleMaintenance =>
      'Only Super Admin can toggle maintenance mode';

  @override
  String get onboardingTitle1 => 'Fast & Reliable Delivery';

  @override
  String get onboardingSub1 =>
      'Get your food, groceries, and essential items delivered to your doorstep in minutes.';

  @override
  String get onboardingTitle2 => 'Diverse Services';

  @override
  String get onboardingSub2 =>
      'Explore top restaurants, pharmacies, books, transport options, and much more.';

  @override
  String get onboardingTitle3 => 'Real-time Tracking';

  @override
  String get onboardingSub3 =>
      'Track your courier live on the map and stay updated at every stage of the delivery.';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingGetStarted => 'Get Started';

  @override
  String get onboardingLoginSignup => 'Login / Sign Up';

  @override
  String get onboardingGuest => 'Continue as Guest';

  @override
  String get meatAndProteins => 'Meat & Proteins';

  @override
  String get clothes => 'Clothing & Fashion';

  @override
  String get buyAndSell => 'Buy & Sell';

  @override
  String get electronics => 'Electronics';

  @override
  String get bookstore => 'Bookstore & Stationery';

  @override
  String get homeFurnishing => 'Home & Furnishing';

  @override
  String get meatAndProteinsSubtitle =>
      'Fresh meat, poultry, fish and protein products';

  @override
  String get clothesSubtitle =>
      'Men, women, kids clothing and fashion products';

  @override
  String get buyAndSellSubtitle =>
      'Marketplace for buying and selling new and used goods';

  @override
  String get electronicsSubtitle =>
      'Smartphones, computers, screens and home appliances';

  @override
  String get errorLoadingMeatAndProteins =>
      'Error loading meat & protein shops';

  @override
  String get errorLoadingClothes => 'Error loading clothing shops';

  @override
  String get errorLoadingBuyAndSell => 'Error loading items';

  @override
  String get errorLoadingElectronics => 'Error loading electronic shops';

  @override
  String get searchMeatAndProteins => 'Search for meat, poultry, fish...';

  @override
  String get searchClothes => 'Search for clothes, shoes, accessories...';

  @override
  String get searchBuyAndSell => 'Search marketplace...';

  @override
  String get searchElectronics => 'Search for phones, computers, devices...';

  @override
  String get noMeatAndProteinsFound => 'No meat shops found';

  @override
  String get noClothesFound => 'No clothing shops found';

  @override
  String get noBuyAndSellFound => 'No marketplace items found';

  @override
  String get noElectronicsFound => 'No electronic shops found';

  @override
  String get supportChats => 'Support Chats';

  @override
  String get replyToCustomerSupport => 'Reply to customer live chat inquiries';

  @override
  String get activeSupportChats => 'Active Support Chats';

  @override
  String get noSupportChats => 'No support chats available';

  @override
  String get closeChat => 'Close Chat';

  @override
  String get reopenChat => 'Reopen Chat';

  @override
  String get chatClosed => 'Chat Closed';

  @override
  String get chatReopened => 'Chat Reopened';

  @override
  String get supportAgent => 'Support Agent';

  @override
  String get connectingToSupport => 'Connecting to support...';

  @override
  String get ticketClosed => 'This support ticket is closed.';

  @override
  String get activeDrivers => 'Active Drivers';

  @override
  String get onboardingApplications => 'Onboarding Applications';

  @override
  String get vehicleClassification => 'Vehicle Classification';

  @override
  String get adjustBalance => 'Adjust Balance';

  @override
  String get activeDriversSearchPlaceholder =>
      'Search active drivers by name, email, phone...';

  @override
  String get applicationsTitle => 'Applications & Onboarding';

  @override
  String get applicationsSubtitle =>
      'Review onboarding requests for drivers and vendors';

  @override
  String get driversTab => 'Drivers';

  @override
  String get vendorsTab => 'Vendors';

  @override
  String get allCategoriesFilter => 'All Categories';

  @override
  String get promoFreeDeliveryApplied => '🎉 Free delivery applied!';

  @override
  String get promoApplied => 'Promo code applied!';

  @override
  String get promoInvalid => 'Invalid promo code. Please try again.';

  @override
  String get promoInactive => 'This promo code is no longer active.';

  @override
  String get promoExpired => 'This promo code has expired.';

  @override
  String get promoMaxUsageReached => 'This promo code is no longer available.';

  @override
  String get promoUserLimitReached => 'You\'ve already used this promo code.';

  @override
  String promoMinOrderNotMet(String amount) {
    return 'Minimum order of EGP $amount required.';
  }

  @override
  String get promoWrongRestaurant =>
      'This promo code is not valid for this restaurant.';

  @override
  String promoPercentageDiscountApplied(String percent, String amount) {
    return '🎉 $percent% discount applied! (EGP $amount off)';
  }

  @override
  String promoFixedDiscountApplied(String amount) {
    return '🎉 EGP $amount discount applied!';
  }

  @override
  String get placeOrderCalculating => 'Place Order — Calculating...';

  @override
  String placeOrderAndPay(String amount) {
    return 'Place Order & Pay — EGP $amount';
  }

  @override
  String get usersTab => 'Users';

  @override
  String get manageActiveRestaurantsSubtitle =>
      'Manage active restaurants & markets';

  @override
  String get transportSystemTitle => 'Transport System';

  @override
  String get transportTab => 'Transport';

  @override
  String get transportSystemSubtitle => 'Live map & ride statistics';

  @override
  String get applicationsTab => 'Applications';

  @override
  String get analyticsTab => 'Analytics';

  @override
  String get settingsTab => 'Settings';

  @override
  String get promoCodesTitle => 'Promo Codes';

  @override
  String get promosTab => 'Promos';

  @override
  String get promoCodesSubtitle => 'Manage discount codes';

  @override
  String get settlementsTitle => 'Settlements';

  @override
  String get settlementsTab => 'Settlements';

  @override
  String get settlementsSubtitle => 'Pay out restaurants & drivers';

  @override
  String get supportTab => 'Support';

  @override
  String get adminManagementTab => 'Admins';

  @override
  String get operationsTab => 'Operations';

  @override
  String get financialsTab => 'Financials';

  @override
  String get analyticsAndHistoryTab => 'Analytics & History';

  @override
  String get activeRides => 'Active Rides';

  @override
  String get recentTrips => 'Recent Trips';

  @override
  String get noRidesRegisteredToday => 'No rides registered today';

  @override
  String statusAndFare(String status, String fare) {
    return 'Status: $status | Fare: EGP $fare';
  }

  @override
  String deliveryFeeFixed(String amount) {
    return 'Fixed: EGP $amount';
  }

  @override
  String deliveryFeeFormula(String base, String perKm) {
    return 'Formula: $base + $perKm/km';
  }

  @override
  String deliveryFeeTiers(String count) {
    return 'Tiers: $count Brackets';
  }

  @override
  String get broadcastTabTitle => 'Broadcast Center';

  @override
  String get broadcastTabSubtitle =>
      'Send targeted push & in-app notifications to users across regions';

  @override
  String get targetAudienceLabel => 'Target Audience';

  @override
  String get targetAllUsers => 'All Users';

  @override
  String get targetCustomers => 'Customers Only';

  @override
  String get targetDrivers => 'Drivers Only';

  @override
  String get targetVendors => 'Vendors Only';

  @override
  String get targetAdmins => 'Admins Only';

  @override
  String get locationAreaLabel => 'Location & Area Filter';

  @override
  String get allLocations => 'All Locations';

  @override
  String get specificArea => 'Specific Area / City Filter';

  @override
  String get areaHint => 'e.g. Cairo, Alexandria, Maadi, Nasr City';

  @override
  String get geoRadiusLabel => 'Geo-Fence Radius Filter';

  @override
  String radiusKmLabel(String km) {
    return 'Radius: $km km';
  }

  @override
  String get notificationContent => 'Notification Content & Localization';

  @override
  String get notificationTitleEn => 'Title (English)';

  @override
  String get notificationBodyEn => 'Body Message (English)';

  @override
  String get notificationTitleAr => 'Title (Arabic)';

  @override
  String get notificationBodyAr => 'Body Message (Arabic)';

  @override
  String get imageUrlLabel => 'Banner Image URL (Optional)';

  @override
  String get targetScreenLabel => 'Target Screen / Action';

  @override
  String get screenNone => 'General (No Action)';

  @override
  String get screenPromo => 'Promo Code Screen';

  @override
  String get screenVendor => 'Vendor Details';

  @override
  String get screenCategory => 'Category Browse';

  @override
  String get screenCustomUrl => 'Custom External Link / URL';

  @override
  String get attachedPromoCode => 'Attached Promo Code';

  @override
  String get targetEntityIdLabel => 'Entity ID / External URL';

  @override
  String get deliveryConfigLabel => 'Delivery & Priority Configurations';

  @override
  String get sendFcmPush => 'Send FCM Push Notification';

  @override
  String get storeInAppInbox => 'Save to User In-App Inbox';

  @override
  String get priorityLabel => 'Delivery Priority';

  @override
  String get priorityHigh => 'High (Heads-up alert banner)';

  @override
  String get priorityNormal => 'Normal';

  @override
  String get soundLabel => 'Notification Sound';

  @override
  String get soundDefault => 'Default System Sound';

  @override
  String get soundAlert => 'High Alert Sound';

  @override
  String get soundSilent => 'Silent';

  @override
  String get presetTemplates => 'Quick Preset Templates';

  @override
  String get templatePromoCode => 'Promo Discount Code';

  @override
  String get templateSystemUpdate => 'App Maintenance Update';

  @override
  String get templateFlashSale => 'Flash Sale & Offer';

  @override
  String get templateAreaAlert => 'Area Special Offer';

  @override
  String get previewHeader => 'Interactive Lockscreen Preview';

  @override
  String get sendBroadcastButton => 'Send Broadcast Notification';

  @override
  String get confirmBroadcastTitle => 'Confirm Broadcast Dispatch';

  @override
  String get confirmBroadcastBody =>
      'Are you sure you want to send this broadcast notification to all targeted users?';

  @override
  String get broadcastSuccessTitle => 'Broadcast Sent Successfully!';

  @override
  String targetedUsersCount(String count) {
    return 'Targeted Users: $count';
  }

  @override
  String pushDeliveredCount(String count) {
    return 'Push Messages Delivered: $count';
  }

  @override
  String pushFailedCount(String count) {
    return 'Push Delivery Failures: $count';
  }

  @override
  String inAppSavedCount(String count) {
    return 'In-App Records Saved: $count';
  }

  @override
  String get setRadiusCenterMap => 'Set Radius Center on Map 📍';

  @override
  String radiusCenterSelected(Object lat, Object lng) {
    return 'Center Location: $lat, $lng';
  }

  @override
  String get selectTargetAreaMap => 'Select Area on Map 📍';

  @override
  String get audienceSpecificUser => 'Specific User';

  @override
  String get targetUserIdLabel => 'Target User (UID / Phone / Email)';

  @override
  String get targetUserIdHint =>
      'Enter user UID, phone number, or email address';

  @override
  String get filterAll => 'All';

  @override
  String get filterUnread => 'Unread';

  @override
  String get filterOrders => 'Orders';

  @override
  String get filterPromos => 'Offers';

  @override
  String unreadCountNotice(int count) {
    return 'You have $count unread notifications';
  }

  @override
  String get allNotificationsMarkedRead => 'All notifications marked as read';

  @override
  String get noUnreadNotifications => 'No unread notifications';

  @override
  String get noOrderNotifications => 'No order notifications';

  @override
  String get noPromoNotifications => 'No offers or discounts available';

  @override
  String get allNotificationsWillAppear =>
      'All updates and offers will appear here';

  @override
  String get viewAllNotifications => 'View all notifications';

  @override
  String promoCodeCopied(String code) {
    return 'Promo code copied: $code';
  }

  @override
  String get selectedOptionUnavailable =>
      'The selected option is currently unavailable';

  @override
  String get masterLogisticsKpiDashboard => 'Master Logistics KPI Dashboard';

  @override
  String get kpiDashboardSubtitle =>
      'Real-time metrics, profits, driver payouts and vendor financial calculations';

  @override
  String get exportExcel => 'Export Excel';

  @override
  String get exportPdfPrint => 'Export PDF / Print';

  @override
  String get excelExportedSuccess => 'Excel exported successfully';

  @override
  String get exportFailed => 'Export failed';

  @override
  String get searchOrderIdCustomerHint => 'Search Order ID / Customer...';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get last7Days => 'Last 7 Days';

  @override
  String get customDateRange => 'Custom Date Range';

  @override
  String get allVendorsCombined => 'All Vendors (Combined)';

  @override
  String get allRidersCombined => 'All Riders (Combined)';

  @override
  String get allPaymentMethods => 'All Payment Methods';

  @override
  String get platformDeliveryFeeToggle => '15% Platform Delivery Fee';

  @override
  String get restaurantGrossSales => 'Restaurant Gross Sales';

  @override
  String get subtotalAcrossOrders => 'Subtotal across orders';

  @override
  String get totalDeliveryFeesCollected => 'Total Delivery Fees';

  @override
  String get collectedFromClients => 'Collected from clients';

  @override
  String get tripsCompleted => 'Trips Completed';

  @override
  String get deliveredOrdersSubtitle => 'Delivered orders';

  @override
  String get activeOrdersKpi => 'Active Orders';

  @override
  String get inProgressSubtitle => 'In progress';

  @override
  String get rideAcceptanceRate => 'Ride Acceptance';

  @override
  String get driverResponseRate => 'Driver response rate';

  @override
  String get masterNetProfit => 'Master Net Profit';

  @override
  String get masterCommission => 'Master Commission';

  @override
  String get comm10PlusFee15 => 'Comm (10%) + Platform Fee (15%)';

  @override
  String get comm10Only => '10% Admin Commission Only';

  @override
  String get restaurantFinancialsPayouts => 'Restaurant Financials & Payouts';

  @override
  String get noVendorFinancialData => 'No vendor financial data available';

  @override
  String deliveredOrdersCount(int count) {
    return '$count Delivered Orders';
  }

  @override
  String get netSalesLabel => 'Net Sales';

  @override
  String get adminComm10 => 'Admin Comm (10%)';

  @override
  String get amountDue => 'Amount Due';

  @override
  String get riderPerformanceEarnings => 'Rider Performance & Earnings';

  @override
  String get noRiderTripData => 'No rider trip data available';

  @override
  String tripsCompletedCount(int count) {
    return '$count Trips Completed';
  }

  @override
  String get totalFeesLabel => 'Total Fees';

  @override
  String get riderShare85 => 'Rider Share (85%)';

  @override
  String get platformCut15 => 'Platform Cut (15%)';

  @override
  String get tripOrderDetailedRecords => 'Trip & Order Detailed Records';

  @override
  String totalOrdersCountLabel(int count) {
    return 'Total: $count orders';
  }

  @override
  String get noOrdersMatchFilter => 'No orders match current filter';

  @override
  String get tableColDate => 'Date';

  @override
  String get tableColOrderTripId => 'Order / Trip ID';

  @override
  String get tableColStatus => 'Status';

  @override
  String get tableColChangedBy => 'Changed By';

  @override
  String get tableColPayment => 'Payment';

  @override
  String get tableColSubtotal => 'Subtotal';

  @override
  String get tableColDeliveryFee => 'Delivery Fee';

  @override
  String get tableColRiderCut => 'Rider Cut (85%)';

  @override
  String get tableColAdminComm => 'Admin Comm (10%)';

  @override
  String get tableColPlatformFee => 'Platform Fee (15%)';

  @override
  String get actorCustomer => 'Customer';

  @override
  String get actorVendor => 'Vendor';

  @override
  String get actorDriver => 'Driver';

  @override
  String get actorAdmin => 'Admin';

  @override
  String get actorSystem => 'System';

  @override
  String pageXOfY(int page, int total) {
    return 'Page $page of $total';
  }

  @override
  String get customerIdLabel => 'Customer ID';

  @override
  String get taxLabel => 'Tax';

  @override
  String orderDetailsTitleParam(String id) {
    return 'Order Details $id';
  }

  @override
  String orderIdParam(String id) {
    return 'Order ID: $id';
  }

  @override
  String customerIdParam(String id) {
    return 'Customer ID: $id';
  }

  @override
  String statusParam(String status) {
    return 'Status: $status';
  }

  @override
  String changedByParam(String actor) {
    return 'Changed By: $actor';
  }

  @override
  String cancelledByParam(String actor) {
    return 'Cancelled By: $actor';
  }

  @override
  String cancellationReasonParam(String reason) {
    return 'Reason: $reason';
  }

  @override
  String paymentMethodParam(String method) {
    return 'Payment Method: $method';
  }

  @override
  String subtotalParam(String amount) {
    return 'Subtotal: $amount';
  }

  @override
  String deliveryFeeParam(String amount) {
    return 'Delivery Fee: $amount';
  }

  @override
  String taxParam(String amount) {
    return 'Tax: $amount';
  }

  @override
  String totalParam(String amount) {
    return 'Total: $amount';
  }

  @override
  String errorLoadingKpiMetrics(String error) {
    return 'Error loading KPI metrics: $error';
  }

  @override
  String get itemCurrentlyUnavailable => 'This item is currently unavailable';

  @override
  String get someItemsUnavailableSkipped =>
      'Some items in this order are no longer available and were skipped';

  @override
  String get kpiTabTitle => 'Logistics KPI';

  @override
  String get kpiTabShortTitle => 'KPI Dashboard';

  @override
  String get kpiTabSubtitle =>
      'Comprehensive vendor, rider & profit calculations';

  @override
  String get busyModeLabel => 'Busy Mode';

  @override
  String get busyModeActive => 'Busy (Orders Paused)';

  @override
  String get busyModeInactive => 'Available (Accepting Orders)';

  @override
  String get busyModeDesc => 'Temporarily stop accepting new orders';

  @override
  String get vendorCurrentlyBusy =>
      'This store is currently busy and not accepting orders.';

  @override
  String get notifyMeWhenAvailable => 'Notify Me When Available';

  @override
  String get willNotifyWhenAvailable =>
      'We\'ll notify you if this store comes back online within the next 2 hours! 🔔';

  @override
  String get alreadySubscribedNotify =>
      'You will be notified as soon as this store is available.';

  @override
  String get storyApprovalStatusPending => 'Pending Approval';

  @override
  String get storyApprovalStatusApproved => 'Approved';

  @override
  String get storyApprovalStatusRejected => 'Rejected';

  @override
  String get storySubmittedAwaitingApproval =>
      'Story submitted! Awaiting admin approval.';

  @override
  String get storiesApprovalTabTitle => 'Story Approvals';

  @override
  String get storiesApprovalTabShort => 'Stories';

  @override
  String get addDeliveryArea => 'Add Area on Map 📍';

  @override
  String get configuredDeliveryAreas => 'Custom Delivery Map Areas';

  @override
  String get areaNameLabel => 'Area / Zone Name';

  @override
  String get thresholdKmLabel => 'Base Distance Threshold (km)';

  @override
  String get extraKmRateLabel => 'Rate after threshold (EGP/km)';

  @override
  String get noAreasConfigured => 'No custom map areas added yet.';

  @override
  String get deleteArea => 'Delete Area';

  @override
  String get editArea => 'Edit Area';

  @override
  String get areaRulesInfo =>
      'Orders within this area charge base fee up to threshold + extra km rate.';
}
