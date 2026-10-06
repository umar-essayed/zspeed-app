import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @rememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember Me'**
  String get rememberMe;

  /// No description provided for @criticalUpdateTitle.
  ///
  /// In en, this message translates to:
  /// **'Update Required'**
  String get criticalUpdateTitle;

  /// No description provided for @criticalUpdateMessage.
  ///
  /// In en, this message translates to:
  /// **'A new version of Z Speed is available. You must update the app to continue using our services.'**
  String get criticalUpdateMessage;

  /// No description provided for @flexibleUpdateTitle.
  ///
  /// In en, this message translates to:
  /// **'New Update Available!'**
  String get flexibleUpdateTitle;

  /// No description provided for @flexibleUpdateMessage.
  ///
  /// In en, this message translates to:
  /// **'A new version of Z Speed is available with improvements and new features. Would you like to update now?'**
  String get flexibleUpdateMessage;

  /// No description provided for @updateNow.
  ///
  /// In en, this message translates to:
  /// **'Update Now'**
  String get updateNow;

  /// No description provided for @updateLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get updateLater;

  /// No description provided for @versionSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'App Update Configuration'**
  String get versionSettingsTitle;

  /// No description provided for @minRequiredVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Minimum Required Version'**
  String get minRequiredVersionLabel;

  /// No description provided for @latestVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Latest App Version'**
  String get latestVersionLabel;

  /// No description provided for @iosUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'iOS Update URL (App Store)'**
  String get iosUrlLabel;

  /// No description provided for @androidUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Android Update URL (Play Store)'**
  String get androidUrlLabel;

  /// No description provided for @fallbackUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Fallback Update URL'**
  String get fallbackUrlLabel;

  /// No description provided for @saveSettings.
  ///
  /// In en, this message translates to:
  /// **'Save Settings'**
  String get saveSettings;

  /// No description provided for @settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved successfully'**
  String get settingsSaved;

  /// No description provided for @onlySuperAdminCanEdit.
  ///
  /// In en, this message translates to:
  /// **'Only super admin can modify these settings'**
  String get onlySuperAdminCanEdit;

  /// No description provided for @driverEarningsLimitSettings.
  ///
  /// In en, this message translates to:
  /// **'Driver Earnings Limit Settings'**
  String get driverEarningsLimitSettings;

  /// No description provided for @globalEarningsLimit.
  ///
  /// In en, this message translates to:
  /// **'Global Earnings Limit (EGP)'**
  String get globalEarningsLimit;

  /// No description provided for @earningsLimitDescription.
  ///
  /// In en, this message translates to:
  /// **'0.0 or empty means no limit. Drivers will be locked when they exceed this limit.'**
  String get earningsLimitDescription;

  /// No description provided for @settingsError.
  ///
  /// In en, this message translates to:
  /// **'Error saving settings'**
  String get settingsError;

  /// No description provided for @accountLocked.
  ///
  /// In en, this message translates to:
  /// **'Account Locked'**
  String get accountLocked;

  /// No description provided for @earningsLimitReachedDesc.
  ///
  /// In en, this message translates to:
  /// **'You have reached your earnings limit. To continue taking requests, please contact administration or visit a hub to settle your balance.'**
  String get earningsLimitReachedDesc;

  /// No description provided for @currentEarnings.
  ///
  /// In en, this message translates to:
  /// **'Current Earnings:'**
  String get currentEarnings;

  /// No description provided for @limitThreshold.
  ///
  /// In en, this message translates to:
  /// **'Limit Threshold:'**
  String get limitThreshold;

  /// No description provided for @refreshStatus.
  ///
  /// In en, this message translates to:
  /// **'Refresh Status'**
  String get refreshStatus;

  /// No description provided for @lockedDueToEarningsLimit.
  ///
  /// In en, this message translates to:
  /// **'Your account is locked due to earnings limit. Please settle your balance.'**
  String get lockedDueToEarningsLimit;

  /// No description provided for @earningsLimitAndLockStatus.
  ///
  /// In en, this message translates to:
  /// **'Earnings Limit & Lock Status'**
  String get earningsLimitAndLockStatus;

  /// No description provided for @walletBalanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Wallet Balance'**
  String get walletBalanceLabel;

  /// No description provided for @customEarningsLimit.
  ///
  /// In en, this message translates to:
  /// **'Custom Earnings Limit'**
  String get customEarningsLimit;

  /// No description provided for @noCustomLimit.
  ///
  /// In en, this message translates to:
  /// **'No Custom Limit (using global default)'**
  String get noCustomLimit;

  /// No description provided for @settleBalanceAndUnlock.
  ///
  /// In en, this message translates to:
  /// **'Settle Balance & Unlock'**
  String get settleBalanceAndUnlock;

  /// No description provided for @setCustomLimitTitle.
  ///
  /// In en, this message translates to:
  /// **'Set Custom Earnings Limit'**
  String get setCustomLimitTitle;

  /// No description provided for @earningsLimitLabel.
  ///
  /// In en, this message translates to:
  /// **'Earnings Limit (EGP)'**
  String get earningsLimitLabel;

  /// No description provided for @customLimitHint.
  ///
  /// In en, this message translates to:
  /// **'Enter 0 or leave empty to use global limit'**
  String get customLimitHint;

  /// No description provided for @customLimitUpdated.
  ///
  /// In en, this message translates to:
  /// **'Custom earnings limit updated'**
  String get customLimitUpdated;

  /// No description provided for @confirmSettleTitle.
  ///
  /// In en, this message translates to:
  /// **'Settle Balance & Unlock Driver'**
  String get confirmSettleTitle;

  /// No description provided for @confirmSettleBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to reset the balance of EGP {amount} to 0.0 and unlock this driver?'**
  String confirmSettleBody(Object amount);

  /// No description provided for @confirmSettleButton.
  ///
  /// In en, this message translates to:
  /// **'Confirm Settle'**
  String get confirmSettleButton;

  /// No description provided for @settleSuccess.
  ///
  /// In en, this message translates to:
  /// **'Driver balance settled and account unlocked successfully'**
  String get settleSuccess;

  /// No description provided for @settleError.
  ///
  /// In en, this message translates to:
  /// **'Failed to reset: {error}'**
  String settleError(Object error);

  /// No description provided for @accountBlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Account Suspended'**
  String get accountBlockedTitle;

  /// No description provided for @accountBlockedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your account has been suspended by administration. If you believe this is a mistake or need assistance, please contact our support team.'**
  String get accountBlockedMessage;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupport;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @registrationDisabledTitle.
  ///
  /// In en, this message translates to:
  /// **'Registration Closed'**
  String get registrationDisabledTitle;

  /// No description provided for @registrationDisabledMessage.
  ///
  /// In en, this message translates to:
  /// **'New account registrations are temporarily paused. Please check back soon or log in with an existing account.'**
  String get registrationDisabledMessage;

  /// No description provided for @phoneBlacklistedError.
  ///
  /// In en, this message translates to:
  /// **'This phone number has been blocked from registering.'**
  String get phoneBlacklistedError;

  /// No description provided for @emailBlacklistedError.
  ///
  /// In en, this message translates to:
  /// **'This email address has been blocked from registering.'**
  String get emailBlacklistedError;

  /// No description provided for @userBlockedError.
  ///
  /// In en, this message translates to:
  /// **'Your account has been suspended. Please contact customer support.'**
  String get userBlockedError;

  /// No description provided for @allowNewSignupsLabel.
  ///
  /// In en, this message translates to:
  /// **'Allow New Registrations'**
  String get allowNewSignupsLabel;

  /// No description provided for @allowNewSignupsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Toggle whether new users can register on the platform'**
  String get allowNewSignupsSubtitle;

  /// No description provided for @signupDisabledMessageLabel.
  ///
  /// In en, this message translates to:
  /// **'Registration Closed Message'**
  String get signupDisabledMessageLabel;

  /// No description provided for @maintenanceMessageLabel.
  ///
  /// In en, this message translates to:
  /// **'Maintenance Mode Message'**
  String get maintenanceMessageLabel;

  /// No description provided for @blacklistManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Blacklist & Blocked Identifiers'**
  String get blacklistManagementTitle;

  /// No description provided for @blacklistSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage blocked phone numbers, emails, and identifiers'**
  String get blacklistSubtitle;

  /// No description provided for @addToBlacklist.
  ///
  /// In en, this message translates to:
  /// **'Add to Blacklist'**
  String get addToBlacklist;

  /// No description provided for @removeFromBlacklist.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeFromBlacklist;

  /// No description provided for @confirmRemoveBlacklist.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to unblock {identifier}?'**
  String confirmRemoveBlacklist(Object identifier);

  /// No description provided for @blockedIdentifiers.
  ///
  /// In en, this message translates to:
  /// **'Blocked Identifiers'**
  String get blockedIdentifiers;

  /// No description provided for @blockReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get blockReason;

  /// No description provided for @blockReasonHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Fraudulent activity, chargebacks, policy violation'**
  String get blockReasonHint;

  /// No description provided for @blockType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get blockType;

  /// No description provided for @phoneType.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneType;

  /// No description provided for @emailType.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailType;

  /// No description provided for @uidType.
  ///
  /// In en, this message translates to:
  /// **'User ID'**
  String get uidType;

  /// No description provided for @enterIdentifier.
  ///
  /// In en, this message translates to:
  /// **'Enter phone, email, or user ID'**
  String get enterIdentifier;

  /// No description provided for @blacklistEmpty.
  ///
  /// In en, this message translates to:
  /// **'No blocked identifiers found.'**
  String get blacklistEmpty;

  /// No description provided for @addedToBlacklistSuccess.
  ///
  /// In en, this message translates to:
  /// **'Identifier successfully added to blacklist.'**
  String get addedToBlacklistSuccess;

  /// No description provided for @removedFromBlacklistSuccess.
  ///
  /// In en, this message translates to:
  /// **'Identifier removed from blacklist.'**
  String get removedFromBlacklistSuccess;

  /// No description provided for @blacklistUserCheckbox.
  ///
  /// In en, this message translates to:
  /// **'Also blacklist phone number & email to prevent re-registration'**
  String get blacklistUserCheckbox;

  /// The main application title shown in the app bar
  ///
  /// In en, this message translates to:
  /// **'Z_Speed'**
  String get appTitle;

  /// Greeting on the home screen
  ///
  /// In en, this message translates to:
  /// **'Welcome back, {name}!'**
  String welcomeMessage(String name);

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred. Please try again.'**
  String get errorOccurred;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Login to your account'**
  String get loginTitle;

  /// No description provided for @phoneNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumberLabel;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @otpPrompt.
  ///
  /// In en, this message translates to:
  /// **'Enter Verification Code'**
  String get otpPrompt;

  /// No description provided for @didNotReceiveCode.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive the code?'**
  String get didNotReceiveCode;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get resendCode;

  /// No description provided for @enterName.
  ///
  /// In en, this message translates to:
  /// **'What\'s your name?'**
  String get enterName;

  /// No description provided for @accountPending.
  ///
  /// In en, this message translates to:
  /// **'Account Pending Verification'**
  String get accountPending;

  /// No description provided for @forDeliveryService.
  ///
  /// In en, this message translates to:
  /// **'FOR DELIVERY SERVICE'**
  String get forDeliveryService;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @logIn.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get logIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// No description provided for @continueWithPhone.
  ///
  /// In en, this message translates to:
  /// **'Continue with Phone'**
  String get continueWithPhone;

  /// No description provided for @orContinueWith.
  ///
  /// In en, this message translates to:
  /// **'Or continue with'**
  String get orContinueWith;

  /// No description provided for @dontHaveAnAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAnAccount;

  /// No description provided for @alreadyHaveAnAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAnAccount;

  /// No description provided for @orText.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get orText;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back!'**
  String get welcomeBack;

  /// No description provided for @joinOurDeliveryService.
  ///
  /// In en, this message translates to:
  /// **'Join our delivery service'**
  String get joinOurDeliveryService;

  /// No description provided for @loginToYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Login to your account'**
  String get loginToYourAccount;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @emailOrUsername.
  ///
  /// In en, this message translates to:
  /// **'Email or Username'**
  String get emailOrUsername;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., owner@restaurant.com'**
  String get emailHint;

  /// No description provided for @pleaseEnterYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get pleaseEnterYourEmail;

  /// No description provided for @pleaseEnterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get pleaseEnterValidEmail;

  /// No description provided for @enterYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterYourPassword;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @homeTab.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTab;

  /// No description provided for @browseTab.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get browseTab;

  /// No description provided for @cartTab.
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get cartTab;

  /// No description provided for @trackOrderTab.
  ///
  /// In en, this message translates to:
  /// **'Track Order'**
  String get trackOrderTab;

  /// No description provided for @profileTab.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTab;

  /// No description provided for @ourServices.
  ///
  /// In en, this message translates to:
  /// **'Our Services'**
  String get ourServices;

  /// No description provided for @chooseService.
  ///
  /// In en, this message translates to:
  /// **'Choose a service to get started'**
  String get chooseService;

  /// No description provided for @food.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get food;

  /// No description provided for @groceries.
  ///
  /// In en, this message translates to:
  /// **'Groceries'**
  String get groceries;

  /// No description provided for @transport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get transport;

  /// No description provided for @pharmacy.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy'**
  String get pharmacy;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get comingSoon;

  /// No description provided for @searchRestaurants.
  ///
  /// In en, this message translates to:
  /// **'Search restaurants or cuisines...'**
  String get searchRestaurants;

  /// No description provided for @popularCategories.
  ///
  /// In en, this message translates to:
  /// **'Popular Categories'**
  String get popularCategories;

  /// No description provided for @featuredRestaurants.
  ///
  /// In en, this message translates to:
  /// **'Featured Restaurants'**
  String get featuredRestaurants;

  /// No description provided for @freeDelivery.
  ///
  /// In en, this message translates to:
  /// **'Free Delivery'**
  String get freeDelivery;

  /// No description provided for @allRestaurants.
  ///
  /// In en, this message translates to:
  /// **'All Restaurants'**
  String get allRestaurants;

  /// No description provided for @openNow.
  ///
  /// In en, this message translates to:
  /// **'Open Now'**
  String get openNow;

  /// No description provided for @closed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closed;

  /// No description provided for @yourCart.
  ///
  /// In en, this message translates to:
  /// **'Your Cart'**
  String get yourCart;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// No description provided for @deliveryFee.
  ///
  /// In en, this message translates to:
  /// **'Delivery Fee'**
  String get deliveryFee;

  /// No description provided for @taxes.
  ///
  /// In en, this message translates to:
  /// **'Taxes'**
  String get taxes;

  /// No description provided for @proceedToCheckout.
  ///
  /// In en, this message translates to:
  /// **'Proceed to Checkout'**
  String get proceedToCheckout;

  /// No description provided for @emptyCart.
  ///
  /// In en, this message translates to:
  /// **'Your cart is empty'**
  String get emptyCart;

  /// No description provided for @addItems.
  ///
  /// In en, this message translates to:
  /// **'Add items to get started'**
  String get addItems;

  /// No description provided for @addToCart.
  ///
  /// In en, this message translates to:
  /// **'Add to Cart'**
  String get addToCart;

  /// No description provided for @checkout.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get checkout;

  /// No description provided for @myOrders.
  ///
  /// In en, this message translates to:
  /// **'My Orders'**
  String get myOrders;

  /// No description provided for @paymentMethods.
  ///
  /// In en, this message translates to:
  /// **'Payment Methods'**
  String get paymentMethods;

  /// No description provided for @savedAddresses.
  ///
  /// In en, this message translates to:
  /// **'Saved Addresses'**
  String get savedAddresses;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @changeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get changeLanguage;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @deliveryTimeFilter.
  ///
  /// In en, this message translates to:
  /// **'Delivery Time'**
  String get deliveryTimeFilter;

  /// No description provided for @deliveryFeeFilter.
  ///
  /// In en, this message translates to:
  /// **'Delivery Fee'**
  String get deliveryFeeFilter;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @openOnly.
  ///
  /// In en, this message translates to:
  /// **'Open Only'**
  String get openOnly;

  /// No description provided for @noRestaurantsFound.
  ///
  /// In en, this message translates to:
  /// **'No restaurants found'**
  String get noRestaurantsFound;

  /// No description provided for @noPharmaciesFound.
  ///
  /// In en, this message translates to:
  /// **'No pharmacies found'**
  String get noPharmaciesFound;

  /// No description provided for @noSupermarketsFound.
  ///
  /// In en, this message translates to:
  /// **'No supermarkets found'**
  String get noSupermarketsFound;

  /// No description provided for @tryAdjustingFilters.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your filters or search'**
  String get tryAdjustingFilters;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get clearFilters;

  /// No description provided for @addItemsFromRestaurants.
  ///
  /// In en, this message translates to:
  /// **'Add items from restaurants'**
  String get addItemsFromRestaurants;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @tripDetails.
  ///
  /// In en, this message translates to:
  /// **'Trip Details'**
  String get tripDetails;

  /// No description provided for @tripHistory.
  ///
  /// In en, this message translates to:
  /// **'Trip History'**
  String get tripHistory;

  /// No description provided for @callCustomer.
  ///
  /// In en, this message translates to:
  /// **'Call Customer'**
  String get callCustomer;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @callRestaurant.
  ///
  /// In en, this message translates to:
  /// **'Call Restaurant'**
  String get callRestaurant;

  /// No description provided for @itemsInOrder.
  ///
  /// In en, this message translates to:
  /// **'Items in Order:'**
  String get itemsInOrder;

  /// No description provided for @noActiveTrip.
  ///
  /// In en, this message translates to:
  /// **'No Active Trip'**
  String get noActiveTrip;

  /// No description provided for @viewAvailableOrders.
  ///
  /// In en, this message translates to:
  /// **'View Available Orders'**
  String get viewAvailableOrders;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @enterLicensePlateHint.
  ///
  /// In en, this message translates to:
  /// **'Enter 3 or 4 numbers followed by 2, 3 or 4 letters.'**
  String get enterLicensePlateHint;

  /// No description provided for @licensePlate.
  ///
  /// In en, this message translates to:
  /// **'License Plate'**
  String get licensePlate;

  /// No description provided for @navigate.
  ///
  /// In en, this message translates to:
  /// **'Navigate'**
  String get navigate;

  /// No description provided for @driverApplication.
  ///
  /// In en, this message translates to:
  /// **'Driver Application'**
  String get driverApplication;

  /// No description provided for @applicationSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Application Submitted!'**
  String get applicationSubmitted;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @verifyContact.
  ///
  /// In en, this message translates to:
  /// **'Please verify both email and phone number.'**
  String get verifyContact;

  /// No description provided for @uploadRequiredDocs.
  ///
  /// In en, this message translates to:
  /// **'Please upload all required documents.'**
  String get uploadRequiredDocs;

  /// No description provided for @fileExceedsLimit.
  ///
  /// In en, this message translates to:
  /// **'File exceeds the 10MB limit.'**
  String get fileExceedsLimit;

  /// No description provided for @trackDriverLocation.
  ///
  /// In en, this message translates to:
  /// **'Track Driver Location'**
  String get trackDriverLocation;

  /// No description provided for @bookThisRide.
  ///
  /// In en, this message translates to:
  /// **'Book This Ride'**
  String get bookThisRide;

  /// No description provided for @viewRouteMap.
  ///
  /// In en, this message translates to:
  /// **'View Route (Map)'**
  String get viewRouteMap;

  /// No description provided for @markAsPickedUp.
  ///
  /// In en, this message translates to:
  /// **'Mark as Picked Up'**
  String get markAsPickedUp;

  /// No description provided for @markAsDelivered.
  ///
  /// In en, this message translates to:
  /// **'Mark as Delivered'**
  String get markAsDelivered;

  /// No description provided for @confirmDelivery.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delivery'**
  String get confirmDelivery;

  /// No description provided for @activeMission.
  ///
  /// In en, this message translates to:
  /// **'Active Mission'**
  String get activeMission;

  /// No description provided for @restaurant.
  ///
  /// In en, this message translates to:
  /// **'Restaurant'**
  String get restaurant;

  /// No description provided for @customer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customer;

  /// No description provided for @openMap.
  ///
  /// In en, this message translates to:
  /// **'Open Map'**
  String get openMap;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @orderDetails.
  ///
  /// In en, this message translates to:
  /// **'Order Details'**
  String get orderDetails;

  /// No description provided for @itemsToDeliver.
  ///
  /// In en, this message translates to:
  /// **'Items to Deliver:'**
  String get itemsToDeliver;

  /// No description provided for @noItemDetailsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No item details available.'**
  String get noItemDetailsAvailable;

  /// No description provided for @closeDetails.
  ///
  /// In en, this message translates to:
  /// **'Close Details'**
  String get closeDetails;

  /// No description provided for @rejectRequest.
  ///
  /// In en, this message translates to:
  /// **'Reject Request'**
  String get rejectRequest;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @noDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noDataAvailable;

  /// No description provided for @documents.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documents;

  /// No description provided for @couldNotOpenDocLink.
  ///
  /// In en, this message translates to:
  /// **'Could not open document link'**
  String get couldNotOpenDocLink;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @assignToOrder.
  ///
  /// In en, this message translates to:
  /// **'Assign to Order'**
  String get assignToOrder;

  /// No description provided for @assign.
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get assign;

  /// No description provided for @removeDriver.
  ///
  /// In en, this message translates to:
  /// **'Remove Driver'**
  String get removeDriver;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @review.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get review;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @disputeDetails.
  ///
  /// In en, this message translates to:
  /// **'Dispute Details'**
  String get disputeDetails;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description:'**
  String get descriptionLabel;

  /// No description provided for @filterOptionsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Filter options coming soon...'**
  String get filterOptionsComingSoon;

  /// No description provided for @applyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get applyFilters;

  /// No description provided for @filterDisputes.
  ///
  /// In en, this message translates to:
  /// **'Filter Disputes'**
  String get filterDisputes;

  /// No description provided for @disputeResolution.
  ///
  /// In en, this message translates to:
  /// **'Dispute Resolution'**
  String get disputeResolution;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortBy;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @editUser.
  ///
  /// In en, this message translates to:
  /// **'Edit User'**
  String get editUser;

  /// No description provided for @rejectApplication.
  ///
  /// In en, this message translates to:
  /// **'Reject Application'**
  String get rejectApplication;

  /// No description provided for @analyticsDashboard.
  ///
  /// In en, this message translates to:
  /// **'Analytics Dashboard'**
  String get analyticsDashboard;

  /// No description provided for @generateReport.
  ///
  /// In en, this message translates to:
  /// **'Generate Report'**
  String get generateReport;

  /// No description provided for @reportGenerationComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Report generation coming soon'**
  String get reportGenerationComingSoon;

  /// No description provided for @generate.
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get generate;

  /// No description provided for @addRestaurant.
  ///
  /// In en, this message translates to:
  /// **'Add Restaurant'**
  String get addRestaurant;

  /// No description provided for @createOrder.
  ///
  /// In en, this message translates to:
  /// **'Create Order'**
  String get createOrder;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @provideRejectReason.
  ///
  /// In en, this message translates to:
  /// **'Please provide a reason for rejecting this section.'**
  String get provideRejectReason;

  /// No description provided for @applicationApproved.
  ///
  /// In en, this message translates to:
  /// **'Application approved'**
  String get applicationApproved;

  /// No description provided for @applicationRejected.
  ///
  /// In en, this message translates to:
  /// **'Application Rejected'**
  String get applicationRejected;

  /// No description provided for @allSectionsApproved.
  ///
  /// In en, this message translates to:
  /// **'All sections approved — application approved!'**
  String get allSectionsApproved;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivity;

  /// No description provided for @noRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'No recent activity'**
  String get noRecentActivity;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @addNewRestaurant.
  ///
  /// In en, this message translates to:
  /// **'Add New Restaurant'**
  String get addNewRestaurant;

  /// No description provided for @editRestaurant.
  ///
  /// In en, this message translates to:
  /// **'Edit Restaurant'**
  String get editRestaurant;

  /// No description provided for @editVendor.
  ///
  /// In en, this message translates to:
  /// **'Edit Vendor'**
  String get editVendor;

  /// No description provided for @vendorUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Vendor updated successfully'**
  String get vendorUpdatedSuccessfully;

  /// No description provided for @deleteRestaurant.
  ///
  /// In en, this message translates to:
  /// **'Delete Restaurant'**
  String get deleteRestaurant;

  /// No description provided for @addUser.
  ///
  /// In en, this message translates to:
  /// **'Add User'**
  String get addUser;

  /// No description provided for @changeStatus.
  ///
  /// In en, this message translates to:
  /// **'Change Status'**
  String get changeStatus;

  /// No description provided for @updateStatus.
  ///
  /// In en, this message translates to:
  /// **'Update Status'**
  String get updateStatus;

  /// No description provided for @addNewUser.
  ///
  /// In en, this message translates to:
  /// **'Add New User'**
  String get addNewUser;

  /// No description provided for @deleteUser.
  ///
  /// In en, this message translates to:
  /// **'Delete User'**
  String get deleteUser;

  /// No description provided for @userDetails.
  ///
  /// In en, this message translates to:
  /// **'User Details'**
  String get userDetails;

  /// No description provided for @changeUserStatus.
  ///
  /// In en, this message translates to:
  /// **'Change User Status'**
  String get changeUserStatus;

  /// No description provided for @newOrder.
  ///
  /// In en, this message translates to:
  /// **'New Order'**
  String get newOrder;

  /// No description provided for @recentOrders.
  ///
  /// In en, this message translates to:
  /// **'Recent Orders'**
  String get recentOrders;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @deleteCuisineType.
  ///
  /// In en, this message translates to:
  /// **'Delete Cuisine Type'**
  String get deleteCuisineType;

  /// No description provided for @addCuisineType.
  ///
  /// In en, this message translates to:
  /// **'Add Cuisine Type'**
  String get addCuisineType;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @editCuisineType.
  ///
  /// In en, this message translates to:
  /// **'Edit Cuisine Type'**
  String get editCuisineType;

  /// No description provided for @cuisineTypeDeleted.
  ///
  /// In en, this message translates to:
  /// **'Cuisine type deleted'**
  String get cuisineTypeDeleted;

  /// No description provided for @bothNamesRequired.
  ///
  /// In en, this message translates to:
  /// **'Both English and Arabic names are required'**
  String get bothNamesRequired;

  /// No description provided for @cuisineTypeCreated.
  ///
  /// In en, this message translates to:
  /// **'Cuisine type created'**
  String get cuisineTypeCreated;

  /// No description provided for @cuisineTypeUpdated.
  ///
  /// In en, this message translates to:
  /// **'Cuisine type updated'**
  String get cuisineTypeUpdated;

  /// No description provided for @noApplicationsFound.
  ///
  /// In en, this message translates to:
  /// **'No applications found'**
  String get noApplicationsFound;

  /// No description provided for @couldNotLoadImage.
  ///
  /// In en, this message translates to:
  /// **'Could not load image'**
  String get couldNotLoadImage;

  /// No description provided for @createNewOrder.
  ///
  /// In en, this message translates to:
  /// **'Create New Order'**
  String get createNewOrder;

  /// No description provided for @deleteOrder.
  ///
  /// In en, this message translates to:
  /// **'Delete Order'**
  String get deleteOrder;

  /// No description provided for @editOrder.
  ///
  /// In en, this message translates to:
  /// **'Edit Order'**
  String get editOrder;

  /// No description provided for @applicationReview.
  ///
  /// In en, this message translates to:
  /// **'Application Review'**
  String get applicationReview;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @drivers.
  ///
  /// In en, this message translates to:
  /// **'Drivers'**
  String get drivers;

  /// No description provided for @restaurants.
  ///
  /// In en, this message translates to:
  /// **'Restaurants'**
  String get restaurants;

  /// No description provided for @logoutAllOthers.
  ///
  /// In en, this message translates to:
  /// **'Logout All Others'**
  String get logoutAllOthers;

  /// No description provided for @allOtherSessionsLogged.
  ///
  /// In en, this message translates to:
  /// **'All other sessions logged out successfully'**
  String get allOtherSessionsLogged;

  /// No description provided for @samsungGalaxySessionLogged.
  ///
  /// In en, this message translates to:
  /// **'Samsung Galaxy session logged out'**
  String get samsungGalaxySessionLogged;

  /// No description provided for @ipadAirSessionLogged.
  ///
  /// In en, this message translates to:
  /// **'iPad Air session logged out'**
  String get ipadAirSessionLogged;

  /// No description provided for @macbookProSessionLogged.
  ///
  /// In en, this message translates to:
  /// **'MacBook Pro session logged out'**
  String get macbookProSessionLogged;

  /// No description provided for @activeSessions.
  ///
  /// In en, this message translates to:
  /// **'Active Sessions'**
  String get activeSessions;

  /// No description provided for @updatePassword.
  ///
  /// In en, this message translates to:
  /// **'Update Password'**
  String get updatePassword;

  /// No description provided for @passwordChangedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully'**
  String get passwordChangedSuccessfully;

  /// No description provided for @newPasswordsDoNot.
  ///
  /// In en, this message translates to:
  /// **'New passwords do not match'**
  String get newPasswordsDoNot;

  /// No description provided for @passwordMustBeAt.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get passwordMustBeAt;

  /// No description provided for @pleaseFillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill all fields'**
  String get pleaseFillAllFields;

  /// No description provided for @pleaseEnterYourCurrent.
  ///
  /// In en, this message translates to:
  /// **'Please enter your current password'**
  String get pleaseEnterYourCurrent;

  /// No description provided for @oneSpecialCharacter.
  ///
  /// In en, this message translates to:
  /// **'• One special character'**
  String get oneSpecialCharacter;

  /// No description provided for @oneNumber.
  ///
  /// In en, this message translates to:
  /// **'• One number'**
  String get oneNumber;

  /// No description provided for @oneLowercaseLetter.
  ///
  /// In en, this message translates to:
  /// **'• One lowercase letter'**
  String get oneLowercaseLetter;

  /// No description provided for @oneUppercaseLetter.
  ///
  /// In en, this message translates to:
  /// **'• One uppercase letter'**
  String get oneUppercaseLetter;

  /// No description provided for @atLeast8Characters.
  ///
  /// In en, this message translates to:
  /// **'• At least 8 characters'**
  String get atLeast8Characters;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @twoFaSettingsUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'2FA settings updated successfully'**
  String get twoFaSettingsUpdatedSuccessfully;

  /// No description provided for @smsIsGoodFor.
  ///
  /// In en, this message translates to:
  /// **'• SMS is good for backup'**
  String get smsIsGoodFor;

  /// No description provided for @useEmailForPrimary.
  ///
  /// In en, this message translates to:
  /// **'• Use email for primary verification'**
  String get useEmailForPrimary;

  /// No description provided for @enableAtLeastOne.
  ///
  /// In en, this message translates to:
  /// **'• Enable at least one 2FA method'**
  String get enableAtLeastOne;

  /// No description provided for @receiveCodeViaSms.
  ///
  /// In en, this message translates to:
  /// **'Receive code via SMS'**
  String get receiveCodeViaSms;

  /// No description provided for @smsVerification.
  ///
  /// In en, this message translates to:
  /// **'SMS Verification'**
  String get smsVerification;

  /// No description provided for @receiveCodeViaEmail.
  ///
  /// In en, this message translates to:
  /// **'Receive code via email'**
  String get receiveCodeViaEmail;

  /// No description provided for @emailVerification.
  ///
  /// In en, this message translates to:
  /// **'Email Verification'**
  String get emailVerification;

  /// No description provided for @twofactorAuthentication.
  ///
  /// In en, this message translates to:
  /// **'Two-Factor Authentication'**
  String get twofactorAuthentication;

  /// No description provided for @frequentlyAskedQuestions.
  ///
  /// In en, this message translates to:
  /// **'Frequently Asked Questions'**
  String get frequentlyAskedQuestions;

  /// No description provided for @faq.
  ///
  /// In en, this message translates to:
  /// **'Frequently Asked Questions'**
  String get faq;

  /// No description provided for @available9am5pmEst.
  ///
  /// In en, this message translates to:
  /// **'Available 9AM-5PM EST'**
  String get available9am5pmEst;

  /// No description provided for @liveChat.
  ///
  /// In en, this message translates to:
  /// **'Live Chat'**
  String get liveChat;

  /// No description provided for @phoneSupport.
  ///
  /// In en, this message translates to:
  /// **'Phone Support'**
  String get phoneSupport;

  /// No description provided for @emailSupport.
  ///
  /// In en, this message translates to:
  /// **'Email Support'**
  String get emailSupport;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// No description provided for @readFullTerms.
  ///
  /// In en, this message translates to:
  /// **'Read Full Terms'**
  String get readFullTerms;

  /// No description provided for @pricesAndFeesMay.
  ///
  /// In en, this message translates to:
  /// **'• Prices and fees may change'**
  String get pricesAndFeesMay;

  /// No description provided for @serviceMayBeInterrupted.
  ///
  /// In en, this message translates to:
  /// **'• Service may be interrupted for maintenance'**
  String get serviceMayBeInterrupted;

  /// No description provided for @weReserveTheRight.
  ///
  /// In en, this message translates to:
  /// **'• We reserve the right to modify terms'**
  String get weReserveTheRight;

  /// No description provided for @youAreResponsibleFor.
  ///
  /// In en, this message translates to:
  /// **'• You are responsible for your account security'**
  String get youAreResponsibleFor;

  /// No description provided for @youMustBeAt.
  ///
  /// In en, this message translates to:
  /// **'• You must be at least 18 years old'**
  String get youMustBeAt;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @readFullPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Read Full Privacy Policy'**
  String get readFullPrivacyPolicy;

  /// No description provided for @youControlYourPrivacy.
  ///
  /// In en, this message translates to:
  /// **'• You control your privacy settings'**
  String get youControlYourPrivacy;

  /// No description provided for @weNeverSellYour.
  ///
  /// In en, this message translates to:
  /// **'• We never sell your data'**
  String get weNeverSellYour;

  /// No description provided for @yourDataIsEncrypted.
  ///
  /// In en, this message translates to:
  /// **'• Your data is encrypted'**
  String get yourDataIsEncrypted;

  /// No description provided for @weCollectOnlyNecessary.
  ///
  /// In en, this message translates to:
  /// **'• We collect only necessary data'**
  String get weCollectOnlyNecessary;

  /// No description provided for @keyPoints.
  ///
  /// In en, this message translates to:
  /// **'Key Points:'**
  String get keyPoints;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @pleaseTypeDeleteTo.
  ///
  /// In en, this message translates to:
  /// **'Please type DELETE to confirm'**
  String get pleaseTypeDeleteTo;

  /// No description provided for @typeDeleteToConfirm.
  ///
  /// In en, this message translates to:
  /// **'Type \"DELETE\" to confirm:'**
  String get typeDeleteToConfirm;

  /// No description provided for @removePaymentInformation.
  ///
  /// In en, this message translates to:
  /// **'• Remove payment information'**
  String get removePaymentInformation;

  /// No description provided for @deleteAllCustomerReviews.
  ///
  /// In en, this message translates to:
  /// **'• Delete all customer reviews'**
  String get deleteAllCustomerReviews;

  /// No description provided for @removeYourRestaurantFrom.
  ///
  /// In en, this message translates to:
  /// **'• Remove your restaurant from the platform'**
  String get removeYourRestaurantFrom;

  /// No description provided for @cancelAllPendingOrders.
  ///
  /// In en, this message translates to:
  /// **'• Cancel all pending orders'**
  String get cancelAllPendingOrders;

  /// No description provided for @permanentlyDeleteAllYour.
  ///
  /// In en, this message translates to:
  /// **'• Permanently delete all your data'**
  String get permanentlyDeleteAllYour;

  /// No description provided for @thisWill.
  ///
  /// In en, this message translates to:
  /// **'This will:'**
  String get thisWill;

  /// No description provided for @areYouSureYou.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account?'**
  String get areYouSureYou;

  /// No description provided for @requestDownload.
  ///
  /// In en, this message translates to:
  /// **'Request Download'**
  String get requestDownload;

  /// No description provided for @activityLogs.
  ///
  /// In en, this message translates to:
  /// **'• Activity logs'**
  String get activityLogs;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @restaurantSettings.
  ///
  /// In en, this message translates to:
  /// **'• Restaurant settings'**
  String get restaurantSettings;

  /// No description provided for @paymentRecords.
  ///
  /// In en, this message translates to:
  /// **'• Payment records'**
  String get paymentRecords;

  /// No description provided for @orderHistory.
  ///
  /// In en, this message translates to:
  /// **'• Order history'**
  String get orderHistory;

  /// No description provided for @accountInformation.
  ///
  /// In en, this message translates to:
  /// **'• Account information'**
  String get accountInformation;

  /// No description provided for @thisIncludes.
  ///
  /// In en, this message translates to:
  /// **'This includes:'**
  String get thisIncludes;

  /// No description provided for @selectDataFormat.
  ///
  /// In en, this message translates to:
  /// **'Select data format:'**
  String get selectDataFormat;

  /// No description provided for @downloadYourData.
  ///
  /// In en, this message translates to:
  /// **'Download Your Data'**
  String get downloadYourData;

  /// No description provided for @descriptionX.
  ///
  /// In en, this message translates to:
  /// **'Description:'**
  String get descriptionX;

  /// No description provided for @couldNotOpenDocument.
  ///
  /// In en, this message translates to:
  /// **'Could not open document link'**
  String get couldNotOpenDocument;

  /// No description provided for @pleaseProvideAReason.
  ///
  /// In en, this message translates to:
  /// **'Please provide a reason for rejecting this section.'**
  String get pleaseProvideAReason;

  /// No description provided for @allSectionsApprovedApplication.
  ///
  /// In en, this message translates to:
  /// **'All sections approved — application approved!'**
  String get allSectionsApprovedApplication;

  /// No description provided for @bothEnglishAndArabic.
  ///
  /// In en, this message translates to:
  /// **'Both English and Arabic names are required'**
  String get bothEnglishAndArabic;

  /// No description provided for @optionDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Option deleted successfully'**
  String get optionDeletedSuccessfully;

  /// No description provided for @deleteOption.
  ///
  /// In en, this message translates to:
  /// **'Delete Option'**
  String get deleteOption;

  /// No description provided for @groupDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Group deleted successfully'**
  String get groupDeletedSuccessfully;

  /// No description provided for @deleteGroup.
  ///
  /// In en, this message translates to:
  /// **'Delete Group'**
  String get deleteGroup;

  /// No description provided for @optionNameIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Option name is required'**
  String get optionNameIsRequired;

  /// No description provided for @customerCanSelectThis.
  ///
  /// In en, this message translates to:
  /// **'Customer can select this option'**
  String get customerCanSelectThis;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @preselectedForCustomer.
  ///
  /// In en, this message translates to:
  /// **'Pre-selected for customer'**
  String get preselectedForCustomer;

  /// No description provided for @defaultSelection.
  ///
  /// In en, this message translates to:
  /// **'Default Selection'**
  String get defaultSelection;

  /// No description provided for @groupUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Group updated successfully'**
  String get groupUpdatedSuccessfully;

  /// No description provided for @groupCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Group created successfully'**
  String get groupCreatedSuccessfully;

  /// No description provided for @groupNameIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Group name is required'**
  String get groupNameIsRequired;

  /// No description provided for @customerMustSelectAn.
  ///
  /// In en, this message translates to:
  /// **'Customer must select an option'**
  String get customerMustSelectAn;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @multiple.
  ///
  /// In en, this message translates to:
  /// **'Multiple'**
  String get multiple;

  /// No description provided for @single.
  ///
  /// In en, this message translates to:
  /// **'Single'**
  String get single;

  /// No description provided for @selectionType.
  ///
  /// In en, this message translates to:
  /// **'Selection Type:'**
  String get selectionType;

  /// No description provided for @addOption.
  ///
  /// In en, this message translates to:
  /// **'Add Option'**
  String get addOption;

  /// No description provided for @addFirstGroup.
  ///
  /// In en, this message translates to:
  /// **'Add First Group'**
  String get addFirstGroup;

  /// No description provided for @itemNotFound.
  ///
  /// In en, this message translates to:
  /// **'Item not found'**
  String get itemNotFound;

  /// No description provided for @manageAddons.
  ///
  /// In en, this message translates to:
  /// **'Manage Addons'**
  String get manageAddons;

  /// No description provided for @cuisineTypes.
  ///
  /// In en, this message translates to:
  /// **'Cuisine Types'**
  String get cuisineTypes;

  /// No description provided for @loadingCuisines.
  ///
  /// In en, this message translates to:
  /// **'Loading cuisines...'**
  String get loadingCuisines;

  /// No description provided for @cuisineTypesUpdated.
  ///
  /// In en, this message translates to:
  /// **'Cuisine types updated successfully'**
  String get cuisineTypesUpdated;

  /// No description provided for @areYouSureYouX.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get areYouSureYouX;

  /// No description provided for @symbolKey.
  ///
  /// In en, this message translates to:
  /// **' *'**
  String get symbolKey;

  /// No description provided for @track.
  ///
  /// In en, this message translates to:
  /// **'Track'**
  String get track;

  /// No description provided for @assignDriver.
  ///
  /// In en, this message translates to:
  /// **'Assign Driver'**
  String get assignDriver;

  /// No description provided for @noCuisineTypesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No cuisine types available. Please contact admin.'**
  String get noCuisineTypesAvailable;

  /// No description provided for @menuManager.
  ///
  /// In en, this message translates to:
  /// **'Menu Manager'**
  String get menuManager;

  /// No description provided for @pleaseLogInTo.
  ///
  /// In en, this message translates to:
  /// **'Please log in to manage your menu'**
  String get pleaseLogInTo;

  /// No description provided for @itemDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Item deleted successfully'**
  String get itemDeletedSuccessfully;

  /// No description provided for @addItem.
  ///
  /// In en, this message translates to:
  /// **'Add Item'**
  String get addItem;

  /// No description provided for @addFirstItem.
  ///
  /// In en, this message translates to:
  /// **'Add First Item'**
  String get addFirstItem;

  /// No description provided for @coverImage.
  ///
  /// In en, this message translates to:
  /// **'Cover Image *'**
  String get coverImage;

  /// No description provided for @restaurantLogo.
  ///
  /// In en, this message translates to:
  /// **'Restaurant Logo'**
  String get restaurantLogo;

  /// No description provided for @viewReceipt.
  ///
  /// In en, this message translates to:
  /// **'View Receipt'**
  String get viewReceipt;

  /// No description provided for @totalX.
  ///
  /// In en, this message translates to:
  /// **'TOTAL'**
  String get totalX;

  /// No description provided for @tryAdjustingYourSearch.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search or filters'**
  String get tryAdjustingYourSearch;

  /// No description provided for @noOrdersFound.
  ///
  /// In en, this message translates to:
  /// **'No orders found'**
  String get noOrdersFound;

  /// No description provided for @lowestAmount.
  ///
  /// In en, this message translates to:
  /// **'Lowest Amount'**
  String get lowestAmount;

  /// No description provided for @highestAmount.
  ///
  /// In en, this message translates to:
  /// **'Highest Amount'**
  String get highestAmount;

  /// No description provided for @oldestFirst.
  ///
  /// In en, this message translates to:
  /// **'Oldest First'**
  String get oldestFirst;

  /// No description provided for @newestFirst.
  ///
  /// In en, this message translates to:
  /// **'Newest First'**
  String get newestFirst;

  /// No description provided for @manageAndTrackAll.
  ///
  /// In en, this message translates to:
  /// **'Manage and track all orders'**
  String get manageAndTrackAll;

  /// No description provided for @orderHistoryX.
  ///
  /// In en, this message translates to:
  /// **'Order History'**
  String get orderHistoryX;

  /// No description provided for @selectCuisineType.
  ///
  /// In en, this message translates to:
  /// **'Select cuisine type...'**
  String get selectCuisineType;

  /// No description provided for @symbolKeyX.
  ///
  /// In en, this message translates to:
  /// **'X'**
  String get symbolKeyX;

  /// No description provided for @operatingHours.
  ///
  /// In en, this message translates to:
  /// **'Operating Hours'**
  String get operatingHours;

  /// No description provided for @workingHours.
  ///
  /// In en, this message translates to:
  /// **'Working Hours'**
  String get workingHours;

  /// No description provided for @basicInformation.
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get basicInformation;

  /// No description provided for @minDeliveryTime.
  ///
  /// In en, this message translates to:
  /// **'Min Delivery Time'**
  String get minDeliveryTime;

  /// No description provided for @maxDeliveryTime.
  ///
  /// In en, this message translates to:
  /// **'Max Delivery Time'**
  String get maxDeliveryTime;

  /// No description provided for @pickOnMap.
  ///
  /// In en, this message translates to:
  /// **'Pick on Map'**
  String get pickOnMap;

  /// No description provided for @coordinates.
  ///
  /// In en, this message translates to:
  /// **'Coordinates'**
  String get coordinates;

  /// No description provided for @documentation.
  ///
  /// In en, this message translates to:
  /// **'Documentation'**
  String get documentation;

  /// No description provided for @supportCenter.
  ///
  /// In en, this message translates to:
  /// **'Support Center'**
  String get supportCenter;

  /// No description provided for @checkOurDocumentationOr.
  ///
  /// In en, this message translates to:
  /// **'Check our documentation or contact support.'**
  String get checkOurDocumentationOr;

  /// No description provided for @needHelp.
  ///
  /// In en, this message translates to:
  /// **'Need Help?'**
  String get needHelp;

  /// No description provided for @noOrdersYet.
  ///
  /// In en, this message translates to:
  /// **'No orders yet'**
  String get noOrdersYet;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @restaurantCreatedWelcomeAboard.
  ///
  /// In en, this message translates to:
  /// **'Restaurant created! Welcome aboard 🎉'**
  String get restaurantCreatedWelcomeAboard;

  /// No description provided for @restaurantNameIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Restaurant name is required'**
  String get restaurantNameIsRequired;

  /// No description provided for @createRestaurant.
  ///
  /// In en, this message translates to:
  /// **'Create Restaurant'**
  String get createRestaurant;

  /// No description provided for @notAuthenticatedPleaseLog.
  ///
  /// In en, this message translates to:
  /// **'Not authenticated. Please log in.'**
  String get notAuthenticatedPleaseLog;

  /// No description provided for @restaurantDetailsMissing.
  ///
  /// In en, this message translates to:
  /// **'Restaurant details missing.'**
  String get restaurantDetailsMissing;

  /// No description provided for @orderRejected.
  ///
  /// In en, this message translates to:
  /// **'Order rejected'**
  String get orderRejected;

  /// No description provided for @selectAReasonFor.
  ///
  /// In en, this message translates to:
  /// **'Select a reason for rejecting this order:'**
  String get selectAReasonFor;

  /// No description provided for @rejectOrder.
  ///
  /// In en, this message translates to:
  /// **'Reject Order'**
  String get rejectOrder;

  /// No description provided for @orderMarkedAsReady.
  ///
  /// In en, this message translates to:
  /// **'Order marked as ready for pickup'**
  String get orderMarkedAsReady;

  /// No description provided for @orderPreparationStarted.
  ///
  /// In en, this message translates to:
  /// **'Order preparation started'**
  String get orderPreparationStarted;

  /// No description provided for @orderAcceptedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Order accepted successfully'**
  String get orderAcceptedSuccessfully;

  /// No description provided for @awaitingDriverPickup.
  ///
  /// In en, this message translates to:
  /// **'Awaiting driver pickup...'**
  String get awaitingDriverPickup;

  /// No description provided for @assignDriverOptional.
  ///
  /// In en, this message translates to:
  /// **'Assign Driver (Optional)'**
  String get assignDriverOptional;

  /// No description provided for @markAsReadyFor.
  ///
  /// In en, this message translates to:
  /// **'Mark as Ready for Pickup'**
  String get markAsReadyFor;

  /// No description provided for @startPreparing.
  ///
  /// In en, this message translates to:
  /// **'Start Preparing'**
  String get startPreparing;

  /// No description provided for @trackDriver.
  ///
  /// In en, this message translates to:
  /// **'Track Driver'**
  String get trackDriver;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethod;

  /// No description provided for @placedAt.
  ///
  /// In en, this message translates to:
  /// **'Placed At'**
  String get placedAt;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @chooseLogoFrom.
  ///
  /// In en, this message translates to:
  /// **'Choose logo from:'**
  String get chooseLogoFrom;

  /// No description provided for @changeLogo.
  ///
  /// In en, this message translates to:
  /// **'Change Logo'**
  String get changeLogo;

  /// No description provided for @closingTime.
  ///
  /// In en, this message translates to:
  /// **'Closing Time'**
  String get closingTime;

  /// No description provided for @openingTime.
  ///
  /// In en, this message translates to:
  /// **'Opening Time'**
  String get openingTime;

  /// No description provided for @markAsReady.
  ///
  /// In en, this message translates to:
  /// **'Mark as Ready'**
  String get markAsReady;

  /// No description provided for @waitingForDriverLocation.
  ///
  /// In en, this message translates to:
  /// **'Waiting for driver location...'**
  String get waitingForDriverLocation;

  /// No description provided for @map.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get map;

  /// No description provided for @uploadingCover.
  ///
  /// In en, this message translates to:
  /// **'Uploading cover...'**
  String get uploadingCover;

  /// No description provided for @locationUpdatedFromMap.
  ///
  /// In en, this message translates to:
  /// **'Location updated from map'**
  String get locationUpdatedFromMap;

  /// No description provided for @goToDashboard.
  ///
  /// In en, this message translates to:
  /// **'Go to Dashboard'**
  String get goToDashboard;

  /// No description provided for @fileExceedsThe10mb.
  ///
  /// In en, this message translates to:
  /// **'File exceeds the 10MB limit.'**
  String get fileExceedsThe10mb;

  /// No description provided for @pleaseUploadBothLogo.
  ///
  /// In en, this message translates to:
  /// **'Please upload both logo and cover image.'**
  String get pleaseUploadBothLogo;

  /// No description provided for @pleaseUploadAllRequired.
  ///
  /// In en, this message translates to:
  /// **'Please upload all required documents.'**
  String get pleaseUploadAllRequired;

  /// No description provided for @selectAtLeastOne.
  ///
  /// In en, this message translates to:
  /// **'Select at least one cuisine type.'**
  String get selectAtLeastOne;

  /// No description provided for @pleaseVerifyBothEmail.
  ///
  /// In en, this message translates to:
  /// **'Please verify both email and phone number.'**
  String get pleaseVerifyBothEmail;

  /// No description provided for @restaurantApplication.
  ///
  /// In en, this message translates to:
  /// **'Restaurant Application'**
  String get restaurantApplication;

  /// No description provided for @vendorApplication.
  ///
  /// In en, this message translates to:
  /// **'{vendorType} Application'**
  String vendorApplication(String vendorType);

  /// No description provided for @vendorTypeStep.
  ///
  /// In en, this message translates to:
  /// **'Vendor Type'**
  String get vendorTypeStep;

  /// No description provided for @vendorTypeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'What kind of business are you registering?'**
  String get vendorTypeSubtitle;

  /// No description provided for @supermarket.
  ///
  /// In en, this message translates to:
  /// **'Supermarket'**
  String get supermarket;

  /// No description provided for @foodAndDining.
  ///
  /// In en, this message translates to:
  /// **'Food & dining'**
  String get foodAndDining;

  /// No description provided for @groceriesAndDailyNeeds.
  ///
  /// In en, this message translates to:
  /// **'Groceries & daily needs'**
  String get groceriesAndDailyNeeds;

  /// No description provided for @medicineAndHealthProducts.
  ///
  /// In en, this message translates to:
  /// **'Medicine & health products'**
  String get medicineAndHealthProducts;

  /// No description provided for @deliveryFeeSettingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Delivery fee settings saved'**
  String get deliveryFeeSettingsSaved;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @discardChanges.
  ///
  /// In en, this message translates to:
  /// **'Discard Changes?'**
  String get discardChanges;

  /// No description provided for @addTier.
  ///
  /// In en, this message translates to:
  /// **'Add Tier'**
  String get addTier;

  /// No description provided for @differentRatesForDistance.
  ///
  /// In en, this message translates to:
  /// **'Different rates for distance ranges'**
  String get differentRatesForDistance;

  /// No description provided for @tieredPricing.
  ///
  /// In en, this message translates to:
  /// **'Tiered Pricing'**
  String get tieredPricing;

  /// No description provided for @baseFeePerKm.
  ///
  /// In en, this message translates to:
  /// **'Base fee + per km rate'**
  String get baseFeePerKm;

  /// No description provided for @perKilometer.
  ///
  /// In en, this message translates to:
  /// **'Per Kilometer'**
  String get perKilometer;

  /// No description provided for @calculateFeeBasedOn.
  ///
  /// In en, this message translates to:
  /// **'Calculate fee based on delivery distance'**
  String get calculateFeeBasedOn;

  /// No description provided for @distancebasedFee.
  ///
  /// In en, this message translates to:
  /// **'Distance-Based Fee'**
  String get distancebasedFee;

  /// No description provided for @chargeAFixedDelivery.
  ///
  /// In en, this message translates to:
  /// **'Charge a fixed delivery fee per order'**
  String get chargeAFixedDelivery;

  /// No description provided for @fixedFee.
  ///
  /// In en, this message translates to:
  /// **'Fixed Fee'**
  String get fixedFee;

  /// No description provided for @youHaveTheLatest.
  ///
  /// In en, this message translates to:
  /// **'You have the latest version'**
  String get youHaveTheLatest;

  /// No description provided for @checkingForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Checking for updates...'**
  String get checkingForUpdates;

  /// No description provided for @checkForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Check for Updates'**
  String get checkForUpdates;

  /// No description provided for @privacyPolicyContent.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy Content...'**
  String get privacyPolicyContent;

  /// No description provided for @termsOfServiceContent.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service Content...'**
  String get termsOfServiceContent;

  /// No description provided for @issueReportedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Issue reported successfully. We\\'**
  String get issueReportedSuccessfully;

  /// No description provided for @files.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get files;

  /// No description provided for @fileAttachedFromFiles.
  ///
  /// In en, this message translates to:
  /// **'File attached from files'**
  String get fileAttachedFromFiles;

  /// No description provided for @fileAttachedFromCamera.
  ///
  /// In en, this message translates to:
  /// **'File attached from camera'**
  String get fileAttachedFromCamera;

  /// No description provided for @fileAttachedFromGallery.
  ///
  /// In en, this message translates to:
  /// **'File attached from gallery'**
  String get fileAttachedFromGallery;

  /// No description provided for @chooseFileFrom.
  ///
  /// In en, this message translates to:
  /// **'Choose file from:'**
  String get chooseFileFrom;

  /// No description provided for @attachFile.
  ///
  /// In en, this message translates to:
  /// **'Attach File'**
  String get attachFile;

  /// No description provided for @blogContent.
  ///
  /// In en, this message translates to:
  /// **'Blog Content'**
  String get blogContent;

  /// No description provided for @blogUpdates.
  ///
  /// In en, this message translates to:
  /// **'Blog & Updates'**
  String get blogUpdates;

  /// No description provided for @technicalDocumentation.
  ///
  /// In en, this message translates to:
  /// **'Technical Documentation'**
  String get technicalDocumentation;

  /// No description provided for @videoTutorials.
  ///
  /// In en, this message translates to:
  /// **'Video Tutorials'**
  String get videoTutorials;

  /// No description provided for @userGuideContent.
  ///
  /// In en, this message translates to:
  /// **'User Guide Content'**
  String get userGuideContent;

  /// No description provided for @userGuide.
  ///
  /// In en, this message translates to:
  /// **'User Guide'**
  String get userGuide;

  /// No description provided for @connectedToSupportAgent.
  ///
  /// In en, this message translates to:
  /// **'Connected to support agent'**
  String get connectedToSupportAgent;

  /// No description provided for @connectingToSupportAgent.
  ///
  /// In en, this message translates to:
  /// **'Connecting to support agent...'**
  String get connectingToSupportAgent;

  /// No description provided for @openingLiveChat.
  ///
  /// In en, this message translates to:
  /// **'Opening live chat...'**
  String get openingLiveChat;

  /// No description provided for @available247.
  ///
  /// In en, this message translates to:
  /// **'Available 24/7'**
  String get available247;

  /// No description provided for @openingEmail.
  ///
  /// In en, this message translates to:
  /// **'Opening email...'**
  String get openingEmail;

  /// No description provided for @supportspeedridescom.
  ///
  /// In en, this message translates to:
  /// **'support@speedrides.com'**
  String get supportspeedridescom;

  /// No description provided for @callingSupport.
  ///
  /// In en, this message translates to:
  /// **'Calling support...'**
  String get callingSupport;

  /// No description provided for @phoneNumberExample.
  ///
  /// In en, this message translates to:
  /// **'+201000000000'**
  String get phoneNumberExample;

  /// No description provided for @openMaps.
  ///
  /// In en, this message translates to:
  /// **'Open Maps'**
  String get openMaps;

  /// No description provided for @locationOpenedInMaps.
  ///
  /// In en, this message translates to:
  /// **'Location opened in maps!'**
  String get locationOpenedInMaps;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @messageSentToDriver.
  ///
  /// In en, this message translates to:
  /// **'Message sent to driver!'**
  String get messageSentToDriver;

  /// No description provided for @callingDriver.
  ///
  /// In en, this message translates to:
  /// **'Calling driver...'**
  String get callingDriver;

  /// No description provided for @shareOrder.
  ///
  /// In en, this message translates to:
  /// **'Share Order'**
  String get shareOrder;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @addedToCart.
  ///
  /// In en, this message translates to:
  /// **'Added to cart'**
  String get addedToCart;

  /// No description provided for @labelAndAddressAre.
  ///
  /// In en, this message translates to:
  /// **'Label and Address are required'**
  String get labelAndAddressAre;

  /// No description provided for @addSavedAddress.
  ///
  /// In en, this message translates to:
  /// **'Add Saved Address'**
  String get addSavedAddress;

  /// No description provided for @addNew.
  ///
  /// In en, this message translates to:
  /// **'Add New'**
  String get addNew;

  /// No description provided for @noAddressesSavedYet.
  ///
  /// In en, this message translates to:
  /// **'No addresses saved yet'**
  String get noAddressesSavedYet;

  /// No description provided for @pleaseLogin.
  ///
  /// In en, this message translates to:
  /// **'Please login'**
  String get pleaseLogin;

  /// No description provided for @ratingFeatureComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Rating feature coming soon'**
  String get ratingFeatureComingSoon;

  /// No description provided for @noMenuItemsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No menu items available'**
  String get noMenuItemsAvailable;

  /// No description provided for @goBack.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get goBack;

  /// No description provided for @restaurantNotFound.
  ///
  /// In en, this message translates to:
  /// **'Restaurant not found'**
  String get restaurantNotFound;

  /// No description provided for @errorLoadingRestaurant.
  ///
  /// In en, this message translates to:
  /// **'Error loading restaurant'**
  String get errorLoadingRestaurant;

  /// No description provided for @createAMenuSection.
  ///
  /// In en, this message translates to:
  /// **'Create a menu section first'**
  String get createAMenuSection;

  /// No description provided for @replace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get replace;

  /// No description provided for @replaceCartItems.
  ///
  /// In en, this message translates to:
  /// **'Replace cart items?'**
  String get replaceCartItems;

  /// No description provided for @noMenuItemsYet.
  ///
  /// In en, this message translates to:
  /// **'No menu items yet'**
  String get noMenuItemsYet;

  /// No description provided for @cancelOrder.
  ///
  /// In en, this message translates to:
  /// **'Cancel Order'**
  String get cancelOrder;

  /// No description provided for @keepOrder.
  ///
  /// In en, this message translates to:
  /// **'Keep Order'**
  String get keepOrder;

  /// No description provided for @pleaseSelectAReason.
  ///
  /// In en, this message translates to:
  /// **'Please select a reason for cancellation:'**
  String get pleaseSelectAReason;

  /// No description provided for @contactSupportFeatureComing.
  ///
  /// In en, this message translates to:
  /// **'Contact support feature coming soon'**
  String get contactSupportFeatureComing;

  /// No description provided for @orderNotFound.
  ///
  /// In en, this message translates to:
  /// **'Order not found'**
  String get orderNotFound;

  /// No description provided for @trackOrder.
  ///
  /// In en, this message translates to:
  /// **'Track Order'**
  String get trackOrder;

  /// No description provided for @estimatedDelivery3045Minutes.
  ///
  /// In en, this message translates to:
  /// **'Estimated delivery: 30-45 minutes'**
  String get estimatedDelivery3045Minutes;

  /// No description provided for @orderPlaced.
  ///
  /// In en, this message translates to:
  /// **'Order Placed'**
  String get orderPlaced;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @useCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Use current location'**
  String get useCurrentLocation;

  /// No description provided for @locationPickerComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Location picker coming soon'**
  String get locationPickerComingSoon;

  /// No description provided for @enter3Or4.
  ///
  /// In en, this message translates to:
  /// **'Enter 3 or 4 numbers followed by 2, 3 or 4 letters.'**
  String get enter3Or4;

  /// No description provided for @symbolKeyXX.
  ///
  /// In en, this message translates to:
  /// **'-'**
  String get symbolKeyXX;

  /// No description provided for @myAccount.
  ///
  /// In en, this message translates to:
  /// **'My Account'**
  String get myAccount;

  /// No description provided for @noDocumentsUploaded.
  ///
  /// In en, this message translates to:
  /// **'No documents uploaded.'**
  String get noDocumentsUploaded;

  /// No description provided for @editAnyway.
  ///
  /// In en, this message translates to:
  /// **'Edit Anyway'**
  String get editAnyway;

  /// No description provided for @editApprovedSection.
  ///
  /// In en, this message translates to:
  /// **'Edit Approved Section?'**
  String get editApprovedSection;

  /// No description provided for @sectionUpdatedSentBack.
  ///
  /// In en, this message translates to:
  /// **'Section updated — sent back for review.'**
  String get sectionUpdatedSentBack;

  /// No description provided for @noApplicationFound.
  ///
  /// In en, this message translates to:
  /// **'No application found.'**
  String get noApplicationFound;

  /// No description provided for @myApplication.
  ///
  /// In en, this message translates to:
  /// **'My Application'**
  String get myApplication;

  /// No description provided for @notificationDeleted.
  ///
  /// In en, this message translates to:
  /// **'Notification deleted'**
  String get notificationDeleted;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @shareReceipt.
  ///
  /// In en, this message translates to:
  /// **'Share Receipt'**
  String get shareReceipt;

  /// No description provided for @shareReceiptFeatureComing.
  ///
  /// In en, this message translates to:
  /// **'Share receipt feature coming soon!'**
  String get shareReceiptFeatureComing;

  /// No description provided for @paymentReceipt.
  ///
  /// In en, this message translates to:
  /// **'Payment Receipt'**
  String get paymentReceipt;

  /// No description provided for @minimumPayoutAmount.
  ///
  /// In en, this message translates to:
  /// **'Minimum Payout Amount'**
  String get minimumPayoutAmount;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @payoutFrequency.
  ///
  /// In en, this message translates to:
  /// **'Payout Frequency'**
  String get payoutFrequency;

  /// No description provided for @savePaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Save Payment Method'**
  String get savePaymentMethod;

  /// No description provided for @receivePaymentsViaVodafone.
  ///
  /// In en, this message translates to:
  /// **'Receive payments via Vodafone Cash'**
  String get receivePaymentsViaVodafone;

  /// No description provided for @vodafoneCash.
  ///
  /// In en, this message translates to:
  /// **'Vodafone Cash'**
  String get vodafoneCash;

  /// No description provided for @receivePaymentsViaInstapay.
  ///
  /// In en, this message translates to:
  /// **'Receive payments via InstaPay'**
  String get receivePaymentsViaInstapay;

  /// No description provided for @instapay.
  ///
  /// In en, this message translates to:
  /// **'InstaPay'**
  String get instapay;

  /// No description provided for @addPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Add Payment Method'**
  String get addPaymentMethod;

  /// No description provided for @paymentMethodSaved.
  ///
  /// In en, this message translates to:
  /// **'Payment method saved'**
  String get paymentMethodSaved;

  /// No description provided for @notSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Not signed in'**
  String get notSignedIn;

  /// No description provided for @taxInformationPage.
  ///
  /// In en, this message translates to:
  /// **'Tax Information Page'**
  String get taxInformationPage;

  /// No description provided for @taxInformation.
  ///
  /// In en, this message translates to:
  /// **'Tax Information'**
  String get taxInformation;

  /// No description provided for @digitalWallet.
  ///
  /// In en, this message translates to:
  /// **'Digital Wallet'**
  String get digitalWallet;

  /// No description provided for @creditdebitCard.
  ///
  /// In en, this message translates to:
  /// **'Credit/Debit Card'**
  String get creditdebitCard;

  /// No description provided for @editDetails.
  ///
  /// In en, this message translates to:
  /// **'Edit Details'**
  String get editDetails;

  /// No description provided for @setAsDefault.
  ///
  /// In en, this message translates to:
  /// **'Set as Default'**
  String get setAsDefault;

  /// No description provided for @defaultText.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultText;

  /// No description provided for @addNewPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Add New Payment Method'**
  String get addNewPaymentMethod;

  /// No description provided for @addWallet.
  ///
  /// In en, this message translates to:
  /// **'Add Wallet'**
  String get addWallet;

  /// No description provided for @addDigitalWallet.
  ///
  /// In en, this message translates to:
  /// **'Add Digital Wallet'**
  String get addDigitalWallet;

  /// No description provided for @addCard.
  ///
  /// In en, this message translates to:
  /// **'Add Card'**
  String get addCard;

  /// No description provided for @alreadyHaveAnAccountX.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Login'**
  String get alreadyHaveAnAccountX;

  /// No description provided for @getHelpWithPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Get help with privacy issues'**
  String get getHelpWithPrivacy;

  /// No description provided for @readOurTermsOf.
  ///
  /// In en, this message translates to:
  /// **'Read our terms of service'**
  String get readOurTermsOf;

  /// No description provided for @readOurPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Read our privacy policy'**
  String get readOurPrivacyPolicy;

  /// No description provided for @permanentlyDeleteYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete your account'**
  String get permanentlyDeleteYourAccount;

  /// No description provided for @getACopyOf.
  ///
  /// In en, this message translates to:
  /// **'Get a copy of your data'**
  String get getACopyOf;

  /// No description provided for @manageLoggedInDevices.
  ///
  /// In en, this message translates to:
  /// **'Manage logged-in devices'**
  String get manageLoggedInDevices;

  /// No description provided for @updateYourPasswordRegularly.
  ///
  /// In en, this message translates to:
  /// **'Update your password regularly'**
  String get updateYourPasswordRegularly;

  /// No description provided for @addAnExtraLayer.
  ///
  /// In en, this message translates to:
  /// **'Add an extra layer of security'**
  String get addAnExtraLayer;

  /// No description provided for @useFingerprintOrFace.
  ///
  /// In en, this message translates to:
  /// **'Use fingerprint or face ID'**
  String get useFingerprintOrFace;

  /// No description provided for @biometricLogin.
  ///
  /// In en, this message translates to:
  /// **'Biometric Login'**
  String get biometricLogin;

  /// No description provided for @privacySecurity.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Security'**
  String get privacySecurity;

  /// No description provided for @continueToPayment.
  ///
  /// In en, this message translates to:
  /// **'Continue to Payment'**
  String get continueToPayment;

  /// No description provided for @deliveryDetails.
  ///
  /// In en, this message translates to:
  /// **'Delivery Details'**
  String get deliveryDetails;

  /// No description provided for @configureTaxSettings.
  ///
  /// In en, this message translates to:
  /// **'Configure Tax Settings'**
  String get configureTaxSettings;

  /// No description provided for @minimumPayout.
  ///
  /// In en, this message translates to:
  /// **'Minimum Payout'**
  String get minimumPayout;

  /// No description provided for @symbolKeyXXX.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get symbolKeyXXX;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @loggedOutSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Logged out successfully'**
  String get loggedOutSuccessfully;

  /// No description provided for @appInformation.
  ///
  /// In en, this message translates to:
  /// **'App Information'**
  String get appInformation;

  /// No description provided for @submitReport.
  ///
  /// In en, this message translates to:
  /// **'Submit Report'**
  String get submitReport;

  /// No description provided for @attachScreenshotsIfNeeded.
  ///
  /// In en, this message translates to:
  /// **'Attach screenshots if needed'**
  String get attachScreenshotsIfNeeded;

  /// No description provided for @foundABugOr.
  ///
  /// In en, this message translates to:
  /// **'Found a bug or have a question?'**
  String get foundABugOr;

  /// No description provided for @reportAProblem.
  ///
  /// In en, this message translates to:
  /// **'Report a Problem'**
  String get reportAProblem;

  /// No description provided for @resources.
  ///
  /// In en, this message translates to:
  /// **'Resources'**
  String get resources;

  /// No description provided for @getInTouchWith.
  ///
  /// In en, this message translates to:
  /// **'Get in touch with our support team'**
  String get getInTouchWith;

  /// No description provided for @orderPlacedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Order placed successfully!'**
  String get orderPlacedSuccessfully;

  /// No description provided for @creditDebitCard.
  ///
  /// In en, this message translates to:
  /// **'Credit / Debit Card'**
  String get creditDebitCard;

  /// No description provided for @cashOnDelivery.
  ///
  /// In en, this message translates to:
  /// **'Cash on Delivery'**
  String get cashOnDelivery;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// No description provided for @createYourRestaurantFirst.
  ///
  /// In en, this message translates to:
  /// **'Create your restaurant first.'**
  String get createYourRestaurantFirst;

  /// No description provided for @notAuthenticated.
  ///
  /// In en, this message translates to:
  /// **'Not authenticated.'**
  String get notAuthenticated;

  /// No description provided for @confirmLocation.
  ///
  /// In en, this message translates to:
  /// **'Confirm Location'**
  String get confirmLocation;

  /// No description provided for @couldNotDetectLocation.
  ///
  /// In en, this message translates to:
  /// **'Could not detect location'**
  String get couldNotDetectLocation;

  /// No description provided for @ordersHistory.
  ///
  /// In en, this message translates to:
  /// **'Orders History'**
  String get ordersHistory;

  /// No description provided for @offersPage.
  ///
  /// In en, this message translates to:
  /// **'Offers Page'**
  String get offersPage;

  /// No description provided for @restaurantsList.
  ///
  /// In en, this message translates to:
  /// **'Restaurants List'**
  String get restaurantsList;

  /// No description provided for @speed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get speed;

  /// No description provided for @downloadReceipt.
  ///
  /// In en, this message translates to:
  /// **'Download Receipt'**
  String get downloadReceipt;

  /// No description provided for @orderReceipt.
  ///
  /// In en, this message translates to:
  /// **'Order Receipt'**
  String get orderReceipt;

  /// No description provided for @pleaseEnterYourPasswordValidation.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get pleaseEnterYourPasswordValidation;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMinLength;

  /// No description provided for @pleaseConfirmYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get pleaseConfirmYourPassword;

  /// No description provided for @bySigningUp.
  ///
  /// In en, this message translates to:
  /// **'By signing up, you agree to our Terms & Privacy Policy'**
  String get bySigningUp;

  /// No description provided for @wantToPartnerWithUs.
  ///
  /// In en, this message translates to:
  /// **'Want to partner with us?'**
  String get wantToPartnerWithUs;

  /// No description provided for @joinAsDriver.
  ///
  /// In en, this message translates to:
  /// **'Join as Driver'**
  String get joinAsDriver;

  /// No description provided for @joinAsRestaurant.
  ///
  /// In en, this message translates to:
  /// **'Join as Vendor'**
  String get joinAsRestaurant;

  /// No description provided for @google.
  ///
  /// In en, this message translates to:
  /// **'Google'**
  String get google;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @drawerMain.
  ///
  /// In en, this message translates to:
  /// **'Main'**
  String get drawerMain;

  /// No description provided for @drawerEngage.
  ///
  /// In en, this message translates to:
  /// **'Engage'**
  String get drawerEngage;

  /// No description provided for @drawerMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get drawerMore;

  /// No description provided for @drawerDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get drawerDashboard;

  /// No description provided for @drawerOrders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get drawerOrders;

  /// No description provided for @drawerMenu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get drawerMenu;

  /// No description provided for @drawerAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get drawerAnalytics;

  /// No description provided for @drawerProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get drawerProfile;

  /// No description provided for @drawerPromotions.
  ///
  /// In en, this message translates to:
  /// **'Promotions'**
  String get drawerPromotions;

  /// No description provided for @drawerReviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get drawerReviews;

  /// No description provided for @drawerSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get drawerSettings;

  /// No description provided for @drawerDeliveryFees.
  ///
  /// In en, this message translates to:
  /// **'Delivery Fees'**
  String get drawerDeliveryFees;

  /// No description provided for @drawerSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get drawerSupport;

  /// No description provided for @drawerAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get drawerAbout;

  /// No description provided for @myRestaurant.
  ///
  /// In en, this message translates to:
  /// **'My Restaurant'**
  String get myRestaurant;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @dashboardOverview.
  ///
  /// In en, this message translates to:
  /// **'Dashboard Overview'**
  String get dashboardOverview;

  /// No description provided for @monitorPerformance.
  ///
  /// In en, this message translates to:
  /// **'Monitor your {vendorLabel} performance'**
  String monitorPerformance(String vendorLabel);

  /// No description provided for @totalRevenue.
  ///
  /// In en, this message translates to:
  /// **'Total Revenue'**
  String get totalRevenue;

  /// No description provided for @activeOrders.
  ///
  /// In en, this message translates to:
  /// **'Active Orders'**
  String get activeOrders;

  /// No description provided for @newCustomers.
  ///
  /// In en, this message translates to:
  /// **'New Customers'**
  String get newCustomers;

  /// No description provided for @avgPrepTime.
  ///
  /// In en, this message translates to:
  /// **'Avg. Prep Time'**
  String get avgPrepTime;

  /// No description provided for @restaurantIsOpen.
  ///
  /// In en, this message translates to:
  /// **'Restaurant is Open'**
  String get restaurantIsOpen;

  /// No description provided for @restaurantIsClosed.
  ///
  /// In en, this message translates to:
  /// **'Restaurant is Closed'**
  String get restaurantIsClosed;

  /// No description provided for @customersCanPlaceOrders.
  ///
  /// In en, this message translates to:
  /// **'Customers can place orders now'**
  String get customersCanPlaceOrders;

  /// No description provided for @tapToStartAcceptingOrders.
  ///
  /// In en, this message translates to:
  /// **'Tap to start accepting orders'**
  String get tapToStartAcceptingOrders;

  /// No description provided for @revenueOverview.
  ///
  /// In en, this message translates to:
  /// **'Revenue Overview'**
  String get revenueOverview;

  /// No description provided for @vsLastWeek.
  ///
  /// In en, this message translates to:
  /// **'vs. last week'**
  String get vsLastWeek;

  /// No description provided for @sameAsLastWeek.
  ///
  /// In en, this message translates to:
  /// **'Same as last week'**
  String get sameAsLastWeek;

  /// No description provided for @gettingFaster.
  ///
  /// In en, this message translates to:
  /// **'Getting faster'**
  String get gettingFaster;

  /// No description provided for @slower.
  ///
  /// In en, this message translates to:
  /// **'Slower'**
  String get slower;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @setUpYourRestaurant.
  ///
  /// In en, this message translates to:
  /// **'Set up your restaurant'**
  String get setUpYourRestaurant;

  /// No description provided for @fillInDetailsBelow.
  ///
  /// In en, this message translates to:
  /// **'Fill in the details below to create your restaurant\nand start managing your menu and orders.'**
  String get fillInDetailsBelow;

  /// No description provided for @restaurantName.
  ///
  /// In en, this message translates to:
  /// **'Restaurant Name'**
  String get restaurantName;

  /// No description provided for @descriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (Optional)'**
  String get descriptionOptional;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @cuisineTypesCommaSeparated.
  ///
  /// In en, this message translates to:
  /// **'Cuisine Types (comma-separated)'**
  String get cuisineTypesCommaSeparated;

  /// No description provided for @cuisineTypesHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Italian, Pizza, Pasta'**
  String get cuisineTypesHint;

  /// No description provided for @creating.
  ///
  /// In en, this message translates to:
  /// **'Creating...'**
  String get creating;

  /// No description provided for @welcomeTo.
  ///
  /// In en, this message translates to:
  /// **'Welcome to {name}'**
  String welcomeTo(String name);

  /// No description provided for @fieldIsRequired.
  ///
  /// In en, this message translates to:
  /// **'{field} is required'**
  String fieldIsRequired(String field);

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get statusAccepted;

  /// No description provided for @statusPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing'**
  String get statusPreparing;

  /// No description provided for @statusReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get statusReady;

  /// No description provided for @statusDriverAssigned.
  ///
  /// In en, this message translates to:
  /// **'Driver Assigned'**
  String get statusDriverAssigned;

  /// No description provided for @statusPickedUp.
  ///
  /// In en, this message translates to:
  /// **'Picked Up'**
  String get statusPickedUp;

  /// No description provided for @statusOnTheWay.
  ///
  /// In en, this message translates to:
  /// **'On the way'**
  String get statusOnTheWay;

  /// No description provided for @statusDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get statusDelivered;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @statusRefunded.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get statusRefunded;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} mins ago'**
  String minutesAgo(int count);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} hours ago'**
  String hoursAgo(int count);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String daysAgo(int count);

  /// No description provided for @dayMon.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get dayMon;

  /// No description provided for @dayTue.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get dayTue;

  /// No description provided for @dayWed.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get dayWed;

  /// No description provided for @dayThu.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get dayThu;

  /// No description provided for @dayFri.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get dayFri;

  /// No description provided for @daySat.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get daySat;

  /// No description provided for @daySun.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get daySun;

  /// No description provided for @failedToLoadOrders.
  ///
  /// In en, this message translates to:
  /// **'Failed to load orders'**
  String get failedToLoadOrders;

  /// No description provided for @allCount.
  ///
  /// In en, this message translates to:
  /// **'All ({count})'**
  String allCount(int count);

  /// No description provided for @newCount.
  ///
  /// In en, this message translates to:
  /// **'New ({count})'**
  String newCount(int count);

  /// No description provided for @activeCount.
  ///
  /// In en, this message translates to:
  /// **'Active ({count})'**
  String activeCount(int count);

  /// No description provided for @readyCount.
  ///
  /// In en, this message translates to:
  /// **'Ready ({count})'**
  String readyCount(int count);

  /// No description provided for @order.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get order;

  /// No description provided for @cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cash;

  /// No description provided for @driverAssignedAwaitingPickup.
  ///
  /// In en, this message translates to:
  /// **'Driver assigned — awaiting pickup'**
  String get driverAssignedAwaitingPickup;

  /// No description provided for @readyAssignDriver.
  ///
  /// In en, this message translates to:
  /// **'Ready — Assign a driver'**
  String get readyAssignDriver;

  /// No description provided for @manageDriversCount.
  ///
  /// In en, this message translates to:
  /// **'Manage Drivers ({count} assigned)'**
  String manageDriversCount(int count);

  /// No description provided for @itemsNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Items not available'**
  String get itemsNotAvailable;

  /// No description provided for @tooBusy.
  ///
  /// In en, this message translates to:
  /// **'Too busy'**
  String get tooBusy;

  /// No description provided for @closingSoon.
  ///
  /// In en, this message translates to:
  /// **'Closing soon'**
  String get closingSoon;

  /// No description provided for @duplicateOrder.
  ///
  /// In en, this message translates to:
  /// **'Duplicate order'**
  String get duplicateOrder;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @assignedDriversCount.
  ///
  /// In en, this message translates to:
  /// **'Assigned Drivers ({count})'**
  String assignedDriversCount(int count);

  /// No description provided for @reason.
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}'**
  String reason(String reason);

  /// No description provided for @statusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get statusRejected;

  /// No description provided for @notAuthenticatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Not Authenticated'**
  String get notAuthenticatedTitle;

  /// No description provided for @pleaseLogInToViewProfile.
  ///
  /// In en, this message translates to:
  /// **'Please log in to view your profile.'**
  String get pleaseLogInToViewProfile;

  /// No description provided for @noRestaurantProfileYet.
  ///
  /// In en, this message translates to:
  /// **'No restaurant profile yet'**
  String get noRestaurantProfileYet;

  /// No description provided for @createRestaurantFromDashboard.
  ///
  /// In en, this message translates to:
  /// **'Create your restaurant from the dashboard\nto start managing your profile here.'**
  String get createRestaurantFromDashboard;

  /// No description provided for @businessInformation.
  ///
  /// In en, this message translates to:
  /// **'Business Information'**
  String get businessInformation;

  /// No description provided for @arabicName.
  ///
  /// In en, this message translates to:
  /// **'Arabic Name'**
  String get arabicName;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @deliverySettings.
  ///
  /// In en, this message translates to:
  /// **'Delivery Settings'**
  String get deliverySettings;

  /// No description provided for @deliveryTime.
  ///
  /// In en, this message translates to:
  /// **'Delivery Time'**
  String get deliveryTime;

  /// No description provided for @minimumOrder.
  ///
  /// In en, this message translates to:
  /// **'Minimum Order'**
  String get minimumOrder;

  /// No description provided for @deliveryRadius.
  ///
  /// In en, this message translates to:
  /// **'{km} km'**
  String deliveryRadius(String km);

  /// No description provided for @feeMode.
  ///
  /// In en, this message translates to:
  /// **'Fee Mode'**
  String get feeMode;

  /// No description provided for @ratingsAndStats.
  ///
  /// In en, this message translates to:
  /// **'Ratings & Stats'**
  String get ratingsAndStats;

  /// No description provided for @noRatingsYet.
  ///
  /// In en, this message translates to:
  /// **'No ratings yet'**
  String get noRatingsYet;

  /// No description provided for @totalReviews.
  ///
  /// In en, this message translates to:
  /// **'Total Reviews'**
  String get totalReviews;

  /// No description provided for @memberSince.
  ///
  /// In en, this message translates to:
  /// **'Member Since'**
  String get memberSince;

  /// No description provided for @lastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated'**
  String get lastUpdated;

  /// No description provided for @currentlyOpen.
  ///
  /// In en, this message translates to:
  /// **'Currently Open'**
  String get currentlyOpen;

  /// No description provided for @currentlyClosed.
  ///
  /// In en, this message translates to:
  /// **'Currently Closed'**
  String get currentlyClosed;

  /// No description provided for @customersCanOrderFromRestaurant.
  ///
  /// In en, this message translates to:
  /// **'Customers can order from your restaurant'**
  String get customersCanOrderFromRestaurant;

  /// No description provided for @restaurantNotAcceptingOrders.
  ///
  /// In en, this message translates to:
  /// **'Your restaurant isn\'t accepting orders'**
  String get restaurantNotAcceptingOrders;

  /// No description provided for @wait.
  ///
  /// In en, this message translates to:
  /// **'Wait'**
  String get wait;

  /// No description provided for @gps.
  ///
  /// In en, this message translates to:
  /// **'GPS'**
  String get gps;

  /// No description provided for @monday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get friday;

  /// No description provided for @saturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get saturday;

  /// No description provided for @sunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sunday;

  /// No description provided for @noHoursSet.
  ///
  /// In en, this message translates to:
  /// **'No hours set'**
  String get noHoursSet;

  /// No description provided for @editOperatingHours.
  ///
  /// In en, this message translates to:
  /// **'Edit Operating Hours'**
  String get editOperatingHours;

  /// No description provided for @operatingHoursSaved.
  ///
  /// In en, this message translates to:
  /// **'Operating hours saved'**
  String get operatingHoursSaved;

  /// No description provided for @failed.
  ///
  /// In en, this message translates to:
  /// **'Failed: {error}'**
  String failed(String error);

  /// No description provided for @totalOrders.
  ///
  /// In en, this message translates to:
  /// **'Total Orders'**
  String get totalOrders;

  /// No description provided for @completionRate.
  ///
  /// In en, this message translates to:
  /// **'Completion Rate'**
  String get completionRate;

  /// No description provided for @avgOrderValue.
  ///
  /// In en, this message translates to:
  /// **'Avg. Order Value'**
  String get avgOrderValue;

  /// No description provided for @revenueTrend.
  ///
  /// In en, this message translates to:
  /// **'Revenue Trend'**
  String get revenueTrend;

  /// No description provided for @orderVolume.
  ///
  /// In en, this message translates to:
  /// **'Order Volume'**
  String get orderVolume;

  /// No description provided for @topSellingItems.
  ///
  /// In en, this message translates to:
  /// **'Top Selling Items'**
  String get topSellingItems;

  /// No description provided for @noItemDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No item data available'**
  String get noItemDataAvailable;

  /// No description provided for @peakHours.
  ///
  /// In en, this message translates to:
  /// **'Peak Hours'**
  String get peakHours;

  /// No description provided for @noHourlyDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No hourly data available'**
  String get noHourlyDataAvailable;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// No description provided for @lastMonth.
  ///
  /// In en, this message translates to:
  /// **'Last Month'**
  String get lastMonth;

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @noDataForThisPeriod.
  ///
  /// In en, this message translates to:
  /// **'No data for this period'**
  String get noDataForThisPeriod;

  /// No description provided for @delivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get delivered;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @refunded.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get refunded;

  /// No description provided for @customerInsights.
  ///
  /// In en, this message translates to:
  /// **'Customer Insights'**
  String get customerInsights;

  /// No description provided for @totalCustomers.
  ///
  /// In en, this message translates to:
  /// **'Total Customers'**
  String get totalCustomers;

  /// No description provided for @new_.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get new_;

  /// No description provided for @returning.
  ///
  /// In en, this message translates to:
  /// **'Returning'**
  String get returning;

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get unknownError;

  /// No description provided for @createYourRestaurant.
  ///
  /// In en, this message translates to:
  /// **'Create Your Restaurant'**
  String get createYourRestaurant;

  /// No description provided for @setUpRestaurantProfile.
  ///
  /// In en, this message translates to:
  /// **'Set up your restaurant profile to start managing menu and orders.'**
  String get setUpRestaurantProfile;

  /// No description provided for @settingsPreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get settingsPreferences;

  /// No description provided for @manageSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage notifications, payment, and account preferences.'**
  String get manageSettingsSubtitle;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @configureAlerts.
  ///
  /// In en, this message translates to:
  /// **'Configure how you receive alerts.'**
  String get configureAlerts;

  /// No description provided for @newOrderAlert.
  ///
  /// In en, this message translates to:
  /// **'New Order Alert'**
  String get newOrderAlert;

  /// No description provided for @showNotificationForNewOrders.
  ///
  /// In en, this message translates to:
  /// **'Show notification for new orders'**
  String get showNotificationForNewOrders;

  /// No description provided for @emailNotifications.
  ///
  /// In en, this message translates to:
  /// **'Email Notifications'**
  String get emailNotifications;

  /// No description provided for @receiveEmailUpdates.
  ///
  /// In en, this message translates to:
  /// **'Receive email updates'**
  String get receiveEmailUpdates;

  /// No description provided for @autoAcceptOrders.
  ///
  /// In en, this message translates to:
  /// **'Auto-Accept Orders'**
  String get autoAcceptOrders;

  /// No description provided for @automaticallyAcceptOrders.
  ///
  /// In en, this message translates to:
  /// **'Automatically accept incoming orders'**
  String get automaticallyAcceptOrders;

  /// No description provided for @restaurantNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Restaurant Name *'**
  String get restaurantNameRequired;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @restaurantCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Restaurant created successfully!'**
  String get restaurantCreatedSuccessfully;

  /// No description provided for @failedToCreateRestaurant.
  ///
  /// In en, this message translates to:
  /// **'Failed to create restaurant: {error}'**
  String failedToCreateRestaurant(String error);

  /// No description provided for @promotionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Promotions'**
  String get promotionsTitle;

  /// No description provided for @promotionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create and manage promotions to attract more customers.'**
  String get promotionsSubtitle;

  /// No description provided for @discountCodes.
  ///
  /// In en, this message translates to:
  /// **'Discount Codes'**
  String get discountCodes;

  /// No description provided for @discountCodesDesc.
  ///
  /// In en, this message translates to:
  /// **'Create percentage or fixed amount discount codes'**
  String get discountCodesDesc;

  /// No description provided for @specialOffers.
  ///
  /// In en, this message translates to:
  /// **'Special Offers'**
  String get specialOffers;

  /// No description provided for @specialOffersDesc.
  ///
  /// In en, this message translates to:
  /// **'Set up BOGO, meal deals, and more'**
  String get specialOffersDesc;

  /// No description provided for @scheduledPromotions.
  ///
  /// In en, this message translates to:
  /// **'Scheduled Promotions'**
  String get scheduledPromotions;

  /// No description provided for @scheduledPromotionsDesc.
  ///
  /// In en, this message translates to:
  /// **'Plan promotions for holidays and peak hours'**
  String get scheduledPromotionsDesc;

  /// No description provided for @performanceTracking.
  ///
  /// In en, this message translates to:
  /// **'Performance Tracking'**
  String get performanceTracking;

  /// No description provided for @performanceTrackingDesc.
  ///
  /// In en, this message translates to:
  /// **'See how your promotions have performed'**
  String get performanceTrackingDesc;

  /// No description provided for @reviewsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviewsTitle;

  /// No description provided for @reviewsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'See what your customers are saying about your restaurant.'**
  String get reviewsSubtitle;

  /// No description provided for @customerFeedback.
  ///
  /// In en, this message translates to:
  /// **'Customer Feedback'**
  String get customerFeedback;

  /// No description provided for @customerFeedbackDesc.
  ///
  /// In en, this message translates to:
  /// **'Read and reply to customer reviews'**
  String get customerFeedbackDesc;

  /// No description provided for @ratingBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Rating Breakdown'**
  String get ratingBreakdown;

  /// No description provided for @ratingBreakdownDesc.
  ///
  /// In en, this message translates to:
  /// **'Detailed breakdown of your ratings by category'**
  String get ratingBreakdownDesc;

  /// No description provided for @sentimentTrends.
  ///
  /// In en, this message translates to:
  /// **'Sentiment Trends'**
  String get sentimentTrends;

  /// No description provided for @sentimentTrendsDesc.
  ///
  /// In en, this message translates to:
  /// **'Track how your ratings change over time'**
  String get sentimentTrendsDesc;

  /// No description provided for @replyToReviews.
  ///
  /// In en, this message translates to:
  /// **'Reply to Reviews'**
  String get replyToReviews;

  /// No description provided for @soldCount.
  ///
  /// In en, this message translates to:
  /// **'{count} sold'**
  String soldCount(int count);

  /// No description provided for @setUpRestaurantProfilePrompt.
  ///
  /// In en, this message translates to:
  /// **'Set up your restaurant profile to start managing your menu and orders.'**
  String get setUpRestaurantProfilePrompt;

  /// No description provided for @configureAlertsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Configure how you receive alerts.'**
  String get configureAlertsSubtitle;

  /// No description provided for @newOrderAlertDescription.
  ///
  /// In en, this message translates to:
  /// **'Show notification for new orders'**
  String get newOrderAlertDescription;

  /// No description provided for @emailNotificationsDescription.
  ///
  /// In en, this message translates to:
  /// **'Receive email updates'**
  String get emailNotificationsDescription;

  /// No description provided for @autoAcceptOrdersDescription.
  ///
  /// In en, this message translates to:
  /// **'Automatically accept incoming orders'**
  String get autoAcceptOrdersDescription;

  /// No description provided for @restaurantNameAsterisk.
  ///
  /// In en, this message translates to:
  /// **'Restaurant Name *'**
  String get restaurantNameAsterisk;

  /// No description provided for @discountCodesDescription.
  ///
  /// In en, this message translates to:
  /// **'Create percentage or fixed-amount discount codes'**
  String get discountCodesDescription;

  /// No description provided for @specialOffersDescription.
  ///
  /// In en, this message translates to:
  /// **'Set up buy-one-get-one, combo deals, and more'**
  String get specialOffersDescription;

  /// No description provided for @scheduledPromotionsDescription.
  ///
  /// In en, this message translates to:
  /// **'Plan promotions for holidays and peak hours'**
  String get scheduledPromotionsDescription;

  /// No description provided for @performanceTrackingDescription.
  ///
  /// In en, this message translates to:
  /// **'See how your promotions are performing'**
  String get performanceTrackingDescription;

  /// No description provided for @customerFeedbackDescription.
  ///
  /// In en, this message translates to:
  /// **'Read and respond to customer reviews'**
  String get customerFeedbackDescription;

  /// No description provided for @ratingBreakdownDescription.
  ///
  /// In en, this message translates to:
  /// **'Detailed breakdown of your ratings by category'**
  String get ratingBreakdownDescription;

  /// No description provided for @sentimentTrendsDescription.
  ///
  /// In en, this message translates to:
  /// **'Track how your ratings change over time'**
  String get sentimentTrendsDescription;

  /// No description provided for @replyToReviewsDescription.
  ///
  /// In en, this message translates to:
  /// **'Engage with customers by responding to their feedback'**
  String get replyToReviewsDescription;

  /// No description provided for @howCanWeHelp.
  ///
  /// In en, this message translates to:
  /// **'How can we help?'**
  String get howCanWeHelp;

  /// No description provided for @supportTeamAssist.
  ///
  /// In en, this message translates to:
  /// **'Our support team is here to assist you.'**
  String get supportTeamAssist;

  /// No description provided for @liveChatAvailability.
  ///
  /// In en, this message translates to:
  /// **'Available 9 AM - 9 PM'**
  String get liveChatAvailability;

  /// No description provided for @faqQuestion1.
  ///
  /// In en, this message translates to:
  /// **'How do I update my menu?'**
  String get faqQuestion1;

  /// No description provided for @faqAnswer1.
  ///
  /// In en, this message translates to:
  /// **'Go to the Menu page from the sidebar. You can add, edit, or remove items and sections. Changes are reflected to customers in real-time.'**
  String get faqAnswer1;

  /// No description provided for @faqQuestion2.
  ///
  /// In en, this message translates to:
  /// **'How do I change my operating hours?'**
  String get faqQuestion2;

  /// No description provided for @faqAnswer2.
  ///
  /// In en, this message translates to:
  /// **'Go to your Profile page and scroll to the Operating Hours section. Tap the edit icon next to any day to update your hours.'**
  String get faqAnswer2;

  /// No description provided for @faqQuestion3.
  ///
  /// In en, this message translates to:
  /// **'How are delivery fees calculated?'**
  String get faqQuestion3;

  /// No description provided for @faqAnswer3.
  ///
  /// In en, this message translates to:
  /// **'Go to Delivery Fees in the sidebar. You can set a fixed fee or distance-based pricing with tiers.'**
  String get faqAnswer3;

  /// No description provided for @faqQuestion4.
  ///
  /// In en, this message translates to:
  /// **'How do I handle a rejected order?'**
  String get faqQuestion4;

  /// No description provided for @faqAnswer4.
  ///
  /// In en, this message translates to:
  /// **'When you reject an order, select a reason. The customer will be notified and refunded automatically.'**
  String get faqAnswer4;

  /// No description provided for @faqQuestion5.
  ///
  /// In en, this message translates to:
  /// **'How do I contact a driver?'**
  String get faqQuestion5;

  /// No description provided for @faqAnswer5.
  ///
  /// In en, this message translates to:
  /// **'On the Orders page, assigned orders show the driver\'s name and phone number. Tap to call directly.'**
  String get faqAnswer5;

  /// No description provided for @aboutZSpeed.
  ///
  /// In en, this message translates to:
  /// **'About Z Speed'**
  String get aboutZSpeed;

  /// No description provided for @aboutZSpeedDescription.
  ///
  /// In en, this message translates to:
  /// **'Z Speed is a fast and reliable delivery platform connecting restaurants with customers across Egypt. We empower restaurant owners with modern tools to manage their business efficiently.'**
  String get aboutZSpeedDescription;

  /// No description provided for @openSourceLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open Source Licenses'**
  String get openSourceLicenses;

  /// No description provided for @copyright.
  ///
  /// In en, this message translates to:
  /// **'© 2026 Z Speed. All rights reserved.'**
  String get copyright;

  /// No description provided for @whatsPlanned.
  ///
  /// In en, this message translates to:
  /// **'What\'s planned:'**
  String get whatsPlanned;

  /// No description provided for @editField.
  ///
  /// In en, this message translates to:
  /// **'Edit {field}'**
  String editField(String field);

  /// No description provided for @enterField.
  ///
  /// In en, this message translates to:
  /// **'Enter {field}'**
  String enterField(String field);

  /// No description provided for @fieldUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'{field} updated successfully'**
  String fieldUpdatedSuccessfully(String field);

  /// No description provided for @editDayHours.
  ///
  /// In en, this message translates to:
  /// **'Edit {day} Hours'**
  String editDayHours(String day);

  /// No description provided for @dayHoursUpdated.
  ///
  /// In en, this message translates to:
  /// **'{day} hours updated'**
  String dayHoursUpdated(String day);

  /// No description provided for @selectBothTimes.
  ///
  /// In en, this message translates to:
  /// **'Please select both opening and closing times'**
  String get selectBothTimes;

  /// No description provided for @logoChangedFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Logo changed from gallery'**
  String get logoChangedFromGallery;

  /// No description provided for @logoChangedFromCamera.
  ///
  /// In en, this message translates to:
  /// **'Logo changed from camera'**
  String get logoChangedFromCamera;

  /// No description provided for @orderWithId.
  ///
  /// In en, this message translates to:
  /// **'Order #{id}'**
  String orderWithId(String id);

  /// No description provided for @deleteItem.
  ///
  /// In en, this message translates to:
  /// **'Delete Item'**
  String get deleteItem;

  /// No description provided for @confirmDeleteItem.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \'{name}\'?'**
  String confirmDeleteItem(String name);

  /// No description provided for @currencyEgp.
  ///
  /// In en, this message translates to:
  /// **'{amount} EGP'**
  String currencyEgp(String amount);

  /// No description provided for @outOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of Stock'**
  String get outOfStock;

  /// No description provided for @stockCount.
  ///
  /// In en, this message translates to:
  /// **'Stock: {count}'**
  String stockCount(int count);

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @failedToPickImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to pick image: {error}'**
  String failedToPickImage(String error);

  /// No description provided for @pleaseSelectCuisineType.
  ///
  /// In en, this message translates to:
  /// **'Please select a cuisine type'**
  String get pleaseSelectCuisineType;

  /// No description provided for @englishNameRequired.
  ///
  /// In en, this message translates to:
  /// **'English name is required'**
  String get englishNameRequired;

  /// No description provided for @arabicNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Arabic name is required'**
  String get arabicNameRequired;

  /// No description provided for @englishDescriptionRequired.
  ///
  /// In en, this message translates to:
  /// **'English description is required'**
  String get englishDescriptionRequired;

  /// No description provided for @arabicDescriptionRequired.
  ///
  /// In en, this message translates to:
  /// **'Arabic description is required'**
  String get arabicDescriptionRequired;

  /// No description provided for @priceRequired.
  ///
  /// In en, this message translates to:
  /// **'Price is required'**
  String get priceRequired;

  /// No description provided for @invalidPrice.
  ///
  /// In en, this message translates to:
  /// **'Invalid price'**
  String get invalidPrice;

  /// No description provided for @salePriceError.
  ///
  /// In en, this message translates to:
  /// **'Sale price must be less than regular price'**
  String get salePriceError;

  /// No description provided for @pleaseUploadImage.
  ///
  /// In en, this message translates to:
  /// **'Please upload an image for this item'**
  String get pleaseUploadImage;

  /// No description provided for @failedToUploadImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload image'**
  String get failedToUploadImage;

  /// No description provided for @itemCreated.
  ///
  /// In en, this message translates to:
  /// **'Item created'**
  String get itemCreated;

  /// No description provided for @itemUpdated.
  ///
  /// In en, this message translates to:
  /// **'Item updated'**
  String get itemUpdated;

  /// No description provided for @failedToSaveItem.
  ///
  /// In en, this message translates to:
  /// **'Failed to save item: {error}'**
  String failedToSaveItem(String error);

  /// No description provided for @addMenuItem.
  ///
  /// In en, this message translates to:
  /// **'Add Menu Item'**
  String get addMenuItem;

  /// No description provided for @editMenuItem.
  ///
  /// In en, this message translates to:
  /// **'Edit Menu Item'**
  String get editMenuItem;

  /// No description provided for @cuisineTypeRequired.
  ///
  /// In en, this message translates to:
  /// **'Cuisine Type *'**
  String get cuisineTypeRequired;

  /// No description provided for @itemImageRequired.
  ///
  /// In en, this message translates to:
  /// **'Item Image *'**
  String get itemImageRequired;

  /// No description provided for @itemNameEnglishRequired.
  ///
  /// In en, this message translates to:
  /// **'Item Name (English) *'**
  String get itemNameEnglishRequired;

  /// No description provided for @itemNameEnglishHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Grilled Chicken'**
  String get itemNameEnglishHint;

  /// No description provided for @itemNameArabicRequired.
  ///
  /// In en, this message translates to:
  /// **'Item Name (Arabic) *'**
  String get itemNameArabicRequired;

  /// No description provided for @itemNameArabicHint.
  ///
  /// In en, this message translates to:
  /// **'مثال: دجاج مشوي'**
  String get itemNameArabicHint;

  /// No description provided for @descriptionEnglishRequired.
  ///
  /// In en, this message translates to:
  /// **'Description (English) *'**
  String get descriptionEnglishRequired;

  /// No description provided for @descriptionEnglishHint.
  ///
  /// In en, this message translates to:
  /// **'Brief description of the item'**
  String get descriptionEnglishHint;

  /// No description provided for @descriptionArabicRequired.
  ///
  /// In en, this message translates to:
  /// **'Description (Arabic) *'**
  String get descriptionArabicRequired;

  /// No description provided for @descriptionArabicHint.
  ///
  /// In en, this message translates to:
  /// **'وصف مختصر للصنف'**
  String get descriptionArabicHint;

  /// No description provided for @priceEgpRequired.
  ///
  /// In en, this message translates to:
  /// **'Price (EGP) *'**
  String get priceEgpRequired;

  /// No description provided for @salePriceEgp.
  ///
  /// In en, this message translates to:
  /// **'Sale Price (EGP)'**
  String get salePriceEgp;

  /// No description provided for @unavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get unavailable;

  /// No description provided for @createItem.
  ///
  /// In en, this message translates to:
  /// **'Create Item'**
  String get createItem;

  /// No description provided for @tapToUploadImage.
  ///
  /// In en, this message translates to:
  /// **'Tap to upload image'**
  String get tapToUploadImage;

  /// No description provided for @imageRequirements.
  ///
  /// In en, this message translates to:
  /// **'Required • JPG or PNG'**
  String get imageRequirements;

  /// No description provided for @noAddonGroupsYet.
  ///
  /// In en, this message translates to:
  /// **'No addon groups yet'**
  String get noAddonGroupsYet;

  /// No description provided for @addGroupPrompt.
  ///
  /// In en, this message translates to:
  /// **'Add groups like \"Choose Size\" or \"Extra Toppings\"'**
  String get addGroupPrompt;

  /// No description provided for @optionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{no options} =1{1 option} other{{count} options}}'**
  String optionsCount(int count);

  /// No description provided for @editGroup.
  ///
  /// In en, this message translates to:
  /// **'Edit group'**
  String get editGroup;

  /// No description provided for @noOptionsYet.
  ///
  /// In en, this message translates to:
  /// **'No options yet'**
  String get noOptionsYet;

  /// No description provided for @defaultLabel.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultLabel;

  /// No description provided for @extraPriceEgp.
  ///
  /// In en, this message translates to:
  /// **'+EGP {price}'**
  String extraPriceEgp(String price);

  /// No description provided for @editOption.
  ///
  /// In en, this message translates to:
  /// **'Edit option'**
  String get editOption;

  /// No description provided for @addAddonGroup.
  ///
  /// In en, this message translates to:
  /// **'Add Addon Group'**
  String get addAddonGroup;

  /// No description provided for @editAddonGroup.
  ///
  /// In en, this message translates to:
  /// **'Edit Addon Group'**
  String get editAddonGroup;

  /// No description provided for @groupNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Group Name *'**
  String get groupNameRequired;

  /// No description provided for @groupNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Choose Size'**
  String get groupNameHint;

  /// No description provided for @arabicNameOptional.
  ///
  /// In en, this message translates to:
  /// **'Arabic Name (optional)'**
  String get arabicNameOptional;

  /// No description provided for @arabicNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., اختر الحجم'**
  String get arabicNameHint;

  /// No description provided for @minSelections.
  ///
  /// In en, this message translates to:
  /// **'Min Selections'**
  String get minSelections;

  /// No description provided for @maxSelections.
  ///
  /// In en, this message translates to:
  /// **'Max Selections'**
  String get maxSelections;

  /// No description provided for @failedToSaveGroup.
  ///
  /// In en, this message translates to:
  /// **'Failed to save group: {error}'**
  String failedToSaveGroup(String error);

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @addOptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Add Option'**
  String get addOptionLabel;

  /// No description provided for @editOptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Edit Option'**
  String get editOptionLabel;

  /// No description provided for @optionNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Option Name *'**
  String get optionNameRequired;

  /// No description provided for @optionNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Large'**
  String get optionNameHint;

  /// No description provided for @extraPriceEgpLabel.
  ///
  /// In en, this message translates to:
  /// **'Extra Price (EGP)'**
  String get extraPriceEgpLabel;

  /// No description provided for @optionAdded.
  ///
  /// In en, this message translates to:
  /// **'Option added'**
  String get optionAdded;

  /// No description provided for @optionUpdated.
  ///
  /// In en, this message translates to:
  /// **'Option updated'**
  String get optionUpdated;

  /// No description provided for @failedToSaveOption.
  ///
  /// In en, this message translates to:
  /// **'Failed to save option: {error}'**
  String failedToSaveOption(String error);

  /// No description provided for @confirmDeleteGroup.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \'{name}\'?'**
  String confirmDeleteGroup(String name);

  /// No description provided for @confirmDeleteGroupWarning.
  ///
  /// In en, this message translates to:
  /// **'This will remove all {count} option(s) in this group.'**
  String confirmDeleteGroupWarning(int count);

  /// No description provided for @failedToDeleteGroup.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete group: {error}'**
  String failedToDeleteGroup(String error);

  /// No description provided for @confirmDeleteOption.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \'{name}\'?'**
  String confirmDeleteOption(String name);

  /// No description provided for @failedToDeleteOption.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete option: {error}'**
  String failedToDeleteOption(String error);

  /// No description provided for @andMoreItems.
  ///
  /// In en, this message translates to:
  /// **'{mainItem} + {count} more'**
  String andMoreItems(String mainItem, int count);

  /// No description provided for @headingTo.
  ///
  /// In en, this message translates to:
  /// **'Heading to {name}'**
  String headingTo(String name);

  /// No description provided for @eta.
  ///
  /// In en, this message translates to:
  /// **'ETA: {time}'**
  String eta(Object time);

  /// No description provided for @distance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;

  /// No description provided for @minutesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} min'**
  String minutesCount(int count);

  /// No description provided for @creatingAccount.
  ///
  /// In en, this message translates to:
  /// **'Creating your account...'**
  String get creatingAccount;

  /// No description provided for @uploadingDocuments.
  ///
  /// In en, this message translates to:
  /// **'Uploading documents...'**
  String get uploadingDocuments;

  /// No description provided for @uploadingBranding.
  ///
  /// In en, this message translates to:
  /// **'Uploading branding images...'**
  String get uploadingBranding;

  /// No description provided for @savingApplication.
  ///
  /// In en, this message translates to:
  /// **'Saving your application...'**
  String get savingApplication;

  /// No description provided for @applicationSubmittedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your restaurant application has been submitted successfully. We will review your application and notify you within 1-3 business days.'**
  String get applicationSubmittedSubtitle;

  /// No description provided for @stepProgress.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}: {label}'**
  String stepProgress(int current, int total, String label);

  /// No description provided for @accountSetupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your email and phone number to get started.'**
  String get accountSetupSubtitle;

  /// No description provided for @submitting.
  ///
  /// In en, this message translates to:
  /// **'Submitting...'**
  String get submitting;

  /// No description provided for @businessInfoStep.
  ///
  /// In en, this message translates to:
  /// **'Business Info'**
  String get businessInfoStep;

  /// No description provided for @locationAndHoursStep.
  ///
  /// In en, this message translates to:
  /// **'Location & Hours'**
  String get locationAndHoursStep;

  /// No description provided for @documentsStep.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documentsStep;

  /// No description provided for @brandingStep.
  ///
  /// In en, this message translates to:
  /// **'Branding'**
  String get brandingStep;

  /// No description provided for @bankInfoStep.
  ///
  /// In en, this message translates to:
  /// **'Bank Info'**
  String get bankInfoStep;

  /// No description provided for @reviewStep.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get reviewStep;

  /// No description provided for @completedOrders.
  ///
  /// In en, this message translates to:
  /// **'Completed Orders'**
  String get completedOrders;

  /// No description provided for @cancelledOrders.
  ///
  /// In en, this message translates to:
  /// **'Cancelled Orders'**
  String get cancelledOrders;

  /// No description provided for @searchOrdersHint.
  ///
  /// In en, this message translates to:
  /// **'Search by order ID or customer...'**
  String get searchOrdersHint;

  /// No description provided for @allOrders.
  ///
  /// In en, this message translates to:
  /// **'All Orders'**
  String get allOrders;

  /// No description provided for @ordersFound.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{order} other{orders}} found'**
  String ordersFound(int count);

  /// No description provided for @configureDeliveryFees.
  ///
  /// In en, this message translates to:
  /// **'Configure how delivery fees are calculated for your orders'**
  String get configureDeliveryFees;

  /// No description provided for @deliveryFeeMode.
  ///
  /// In en, this message translates to:
  /// **'Delivery Fee Mode'**
  String get deliveryFeeMode;

  /// No description provided for @fixedDeliveryFee.
  ///
  /// In en, this message translates to:
  /// **'Fixed Delivery Fee'**
  String get fixedDeliveryFee;

  /// No description provided for @distanceBasedFeeLabel.
  ///
  /// In en, this message translates to:
  /// **'Distance-Based Fee'**
  String get distanceBasedFeeLabel;

  /// No description provided for @subMode.
  ///
  /// In en, this message translates to:
  /// **'Sub-Mode'**
  String get subMode;

  /// No description provided for @pricingTiers.
  ///
  /// In en, this message translates to:
  /// **'Pricing Tiers'**
  String get pricingTiers;

  /// No description provided for @noTiersConfigured.
  ///
  /// In en, this message translates to:
  /// **'No tiers configured. Add a tier to get started.'**
  String get noTiersConfigured;

  /// No description provided for @tierWithNumber.
  ///
  /// In en, this message translates to:
  /// **'Tier {number}'**
  String tierWithNumber(int number);

  /// No description provided for @minKm.
  ///
  /// In en, this message translates to:
  /// **'Min (km)'**
  String get minKm;

  /// No description provided for @maxKm.
  ///
  /// In en, this message translates to:
  /// **'Max (km)'**
  String get maxKm;

  /// No description provided for @feeEgp.
  ///
  /// In en, this message translates to:
  /// **'Fee (EGP)'**
  String get feeEgp;

  /// No description provided for @fixedFeeEgp.
  ///
  /// In en, this message translates to:
  /// **'Fixed Fee (EGP)'**
  String get fixedFeeEgp;

  /// No description provided for @baseFeeEgp.
  ///
  /// In en, this message translates to:
  /// **'Base Fee (EGP)'**
  String get baseFeeEgp;

  /// No description provided for @perKmRateEgp.
  ///
  /// In en, this message translates to:
  /// **'Per Km Rate (EGP)'**
  String get perKmRateEgp;

  /// No description provided for @maxDeliveryDistanceKm.
  ///
  /// In en, this message translates to:
  /// **'Maximum Delivery Distance (km)'**
  String get maxDeliveryDistanceKm;

  /// No description provided for @fixedFeeDescription.
  ///
  /// In en, this message translates to:
  /// **'This fee will be charged for all orders regardless of distance'**
  String get fixedFeeDescription;

  /// No description provided for @radiusDescription.
  ///
  /// In en, this message translates to:
  /// **'Orders beyond this distance will be rejected'**
  String get radiusDescription;

  /// No description provided for @formulaDescription.
  ///
  /// In en, this message translates to:
  /// **'Formula: Base Fee + (Distance × Per Km Rate)'**
  String get formulaDescription;

  /// No description provided for @invalidBaseFee.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid base fee'**
  String get invalidBaseFee;

  /// No description provided for @invalidRadius.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid delivery radius'**
  String get invalidRadius;

  /// No description provided for @invalidPerKmRate.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid per km rate'**
  String get invalidPerKmRate;

  /// No description provided for @addAtLeastOneTier.
  ///
  /// In en, this message translates to:
  /// **'Please add at least one pricing tier'**
  String get addAtLeastOneTier;

  /// No description provided for @unsavedChangesDescription.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Are you sure you want to go back?'**
  String get unsavedChangesDescription;

  /// No description provided for @reviewYourApplication.
  ///
  /// In en, this message translates to:
  /// **'Review Your Application'**
  String get reviewYourApplication;

  /// No description provided for @reviewInstructions.
  ///
  /// In en, this message translates to:
  /// **'Please review all information carefully before submitting. You can tap \"Edit\" to go back and make changes.'**
  String get reviewInstructions;

  /// No description provided for @accountAndContact.
  ///
  /// In en, this message translates to:
  /// **'Account & Contact'**
  String get accountAndContact;

  /// No description provided for @notUploaded.
  ///
  /// In en, this message translates to:
  /// **'Not uploaded'**
  String get notUploaded;

  /// No description provided for @reviewDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'By submitting this application, you confirm that all information provided is accurate. Your application will be reviewed within 1-3 business days.'**
  String get reviewDisclaimer;

  /// No description provided for @notConfigured.
  ///
  /// In en, this message translates to:
  /// **'Not configured'**
  String get notConfigured;

  /// No description provided for @tapToChange.
  ///
  /// In en, this message translates to:
  /// **'Tap to change'**
  String get tapToChange;

  /// No description provided for @am.
  ///
  /// In en, this message translates to:
  /// **'AM'**
  String get am;

  /// No description provided for @pm.
  ///
  /// In en, this message translates to:
  /// **'PM'**
  String get pm;

  /// No description provided for @descriptionPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionPlaceholder;

  /// No description provided for @deliveryTimeRange.
  ///
  /// In en, this message translates to:
  /// **'{min} – {max} min'**
  String deliveryTimeRange(int min, int max);

  /// No description provided for @timeRange.
  ///
  /// In en, this message translates to:
  /// **'{open} – {close}'**
  String timeRange(String open, String close);

  /// No description provided for @failedWithMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed: {error}'**
  String failedWithMessage(String error);

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String error(String error);

  /// No description provided for @egyptian.
  ///
  /// In en, this message translates to:
  /// **'Egyptian'**
  String get egyptian;

  /// No description provided for @lebanese.
  ///
  /// In en, this message translates to:
  /// **'Lebanese'**
  String get lebanese;

  /// No description provided for @syrian.
  ///
  /// In en, this message translates to:
  /// **'Syrian'**
  String get syrian;

  /// No description provided for @italian.
  ///
  /// In en, this message translates to:
  /// **'Italian'**
  String get italian;

  /// No description provided for @fastFood.
  ///
  /// In en, this message translates to:
  /// **'Fast Food'**
  String get fastFood;

  /// No description provided for @seafood.
  ///
  /// In en, this message translates to:
  /// **'Seafood'**
  String get seafood;

  /// No description provided for @grills.
  ///
  /// In en, this message translates to:
  /// **'Grills'**
  String get grills;

  /// No description provided for @desserts.
  ///
  /// In en, this message translates to:
  /// **'Desserts'**
  String get desserts;

  /// No description provided for @beverages.
  ///
  /// In en, this message translates to:
  /// **'Beverages'**
  String get beverages;

  /// No description provided for @healthy.
  ///
  /// In en, this message translates to:
  /// **'Healthy'**
  String get healthy;

  /// No description provided for @indian.
  ///
  /// In en, this message translates to:
  /// **'Indian'**
  String get indian;

  /// No description provided for @turkish.
  ///
  /// In en, this message translates to:
  /// **'Turkish'**
  String get turkish;

  /// No description provided for @chinese.
  ///
  /// In en, this message translates to:
  /// **'Chinese'**
  String get chinese;

  /// No description provided for @japanese.
  ///
  /// In en, this message translates to:
  /// **'Japanese'**
  String get japanese;

  /// No description provided for @mexican.
  ///
  /// In en, this message translates to:
  /// **'Mexican'**
  String get mexican;

  /// No description provided for @setHours.
  ///
  /// In en, this message translates to:
  /// **'Set Hours'**
  String get setHours;

  /// No description provided for @businessDocuments.
  ///
  /// In en, this message translates to:
  /// **'Business Documents'**
  String get businessDocuments;

  /// No description provided for @provideBusinessDocs.
  ///
  /// In en, this message translates to:
  /// **'Upload required legal documents for your restaurant.'**
  String get provideBusinessDocs;

  /// No description provided for @commercialRegistration.
  ///
  /// In en, this message translates to:
  /// **'Commercial Registration'**
  String get commercialRegistration;

  /// No description provided for @commercialRegistrationDesc.
  ///
  /// In en, this message translates to:
  /// **'Official commercial registration certificate'**
  String get commercialRegistrationDesc;

  /// No description provided for @businessLicense.
  ///
  /// In en, this message translates to:
  /// **'Business License'**
  String get businessLicense;

  /// No description provided for @businessLicenseDesc.
  ///
  /// In en, this message translates to:
  /// **'Valid business/restaurant operating license'**
  String get businessLicenseDesc;

  /// No description provided for @healthCertificate.
  ///
  /// In en, this message translates to:
  /// **'Health Certificate'**
  String get healthCertificate;

  /// No description provided for @healthCertificateDesc.
  ///
  /// In en, this message translates to:
  /// **'Health and safety inspection certificate'**
  String get healthCertificateDesc;

  /// No description provided for @taxRegistration.
  ///
  /// In en, this message translates to:
  /// **'Tax Registration'**
  String get taxRegistration;

  /// No description provided for @taxRegistrationDesc.
  ///
  /// In en, this message translates to:
  /// **'Tax registration card or certificate'**
  String get taxRegistrationDesc;

  /// No description provided for @restaurantBranding.
  ///
  /// In en, this message translates to:
  /// **'Restaurant Branding'**
  String get restaurantBranding;

  /// No description provided for @uploadLogoCover.
  ///
  /// In en, this message translates to:
  /// **'Upload your restaurant logo and cover photo. These will be shown to customers.'**
  String get uploadLogoCover;

  /// No description provided for @squareImageRecommended.
  ///
  /// In en, this message translates to:
  /// **'Square image recommended (e.g. 512x512).'**
  String get squareImageRecommended;

  /// No description provided for @tapToUploadLogo.
  ///
  /// In en, this message translates to:
  /// **'Tap to upload logo'**
  String get tapToUploadLogo;

  /// No description provided for @coverPhoto.
  ///
  /// In en, this message translates to:
  /// **'Cover Photo'**
  String get coverPhoto;

  /// No description provided for @wideImageRecommended.
  ///
  /// In en, this message translates to:
  /// **'Wide image recommended (e.g. 1200x600).'**
  String get wideImageRecommended;

  /// No description provided for @tapToUploadCover.
  ///
  /// In en, this message translates to:
  /// **'Tap to upload cover'**
  String get tapToUploadCover;

  /// No description provided for @imagesRequiredToProceed.
  ///
  /// In en, this message translates to:
  /// **'Both images are required to proceed.'**
  String get imagesRequiredToProceed;

  /// No description provided for @bankAccountDetails.
  ///
  /// In en, this message translates to:
  /// **'Bank Account Details'**
  String get bankAccountDetails;

  /// No description provided for @payoutInfoDesc.
  ///
  /// In en, this message translates to:
  /// **'Provide your bank account information for receiving payments.'**
  String get payoutInfoDesc;

  /// No description provided for @bankName.
  ///
  /// In en, this message translates to:
  /// **'Bank Name'**
  String get bankName;

  /// No description provided for @bankNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g: CIB, QNB, NBE...'**
  String get bankNameHint;

  /// No description provided for @bankNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Bank Name is required'**
  String get bankNameRequired;

  /// No description provided for @accountHolderName.
  ///
  /// In en, this message translates to:
  /// **'Account Holder Name'**
  String get accountHolderName;

  /// No description provided for @accountHolderNameHint.
  ///
  /// In en, this message translates to:
  /// **'Name as it appears on bank records'**
  String get accountHolderNameHint;

  /// No description provided for @accountHolderNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Account Holder Name is required'**
  String get accountHolderNameRequired;

  /// No description provided for @accountNumberIban.
  ///
  /// In en, this message translates to:
  /// **'Account Number / IBAN'**
  String get accountNumberIban;

  /// No description provided for @accountNumberIbanHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your full IBAN or account number'**
  String get accountNumberIbanHint;

  /// No description provided for @accountNumberIbanRequired.
  ///
  /// In en, this message translates to:
  /// **'Account Number / IBAN is required'**
  String get accountNumberIbanRequired;

  /// No description provided for @branchNameOptional.
  ///
  /// In en, this message translates to:
  /// **'Branch Name (Optional)'**
  String get branchNameOptional;

  /// No description provided for @branchNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g: Maadi, Zamalek...'**
  String get branchNameHint;

  /// No description provided for @bankSecurityNote.
  ///
  /// In en, this message translates to:
  /// **'Security Note'**
  String get bankSecurityNote;

  /// No description provided for @bankSecurityDesc.
  ///
  /// In en, this message translates to:
  /// **'Your bank details are kept secure and encrypted.'**
  String get bankSecurityDesc;

  /// No description provided for @iban.
  ///
  /// In en, this message translates to:
  /// **'IBAN'**
  String get iban;

  /// No description provided for @ibanHint.
  ///
  /// In en, this message translates to:
  /// **'EG XX XXXX XXXX XXXX XXXX XXXX'**
  String get ibanHint;

  /// No description provided for @ibanRequired.
  ///
  /// In en, this message translates to:
  /// **'IBAN is required'**
  String get ibanRequired;

  /// No description provided for @ibanMustStartWithEG.
  ///
  /// In en, this message translates to:
  /// **'IBAN must start with EG'**
  String get ibanMustStartWithEG;

  /// No description provided for @ibanLengthValidation.
  ///
  /// In en, this message translates to:
  /// **'IBAN must be between 15 and 34 characters (current: {length})'**
  String ibanLengthValidation(int length);

  /// No description provided for @driverPersonalInfo.
  ///
  /// In en, this message translates to:
  /// **'Driver Personal Info'**
  String get driverPersonalInfo;

  /// No description provided for @provideBasicDetails.
  ///
  /// In en, this message translates to:
  /// **'Provide your basic details'**
  String get provideBasicDetails;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @enterFullName.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get enterFullName;

  /// No description provided for @nameAlphaOnly.
  ///
  /// In en, this message translates to:
  /// **'Name must contain only letters'**
  String get nameAlphaOnly;

  /// No description provided for @dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get dateOfBirth;

  /// No description provided for @nationalId.
  ///
  /// In en, this message translates to:
  /// **'National ID'**
  String get nationalId;

  /// No description provided for @nationalIdNumber.
  ///
  /// In en, this message translates to:
  /// **'National ID Number'**
  String get nationalIdNumber;

  /// No description provided for @nationalIdRequired.
  ///
  /// In en, this message translates to:
  /// **'National ID number is required'**
  String get nationalIdRequired;

  /// No description provided for @nationalIdLength.
  ///
  /// In en, this message translates to:
  /// **'National ID must be exactly 14 digits'**
  String get nationalIdLength;

  /// No description provided for @nationalIdDesc.
  ///
  /// In en, this message translates to:
  /// **'Front and back of your national ID'**
  String get nationalIdDesc;

  /// No description provided for @driversLicense.
  ///
  /// In en, this message translates to:
  /// **'Driver\'s License'**
  String get driversLicense;

  /// No description provided for @driversLicenseDesc.
  ///
  /// In en, this message translates to:
  /// **'Valid driver\'s license'**
  String get driversLicenseDesc;

  /// No description provided for @vehicleRegistration.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Registration'**
  String get vehicleRegistration;

  /// No description provided for @vehicleRegistrationDesc.
  ///
  /// In en, this message translates to:
  /// **'Valid vehicle registration'**
  String get vehicleRegistrationDesc;

  /// No description provided for @vehicleInsurance.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Insurance'**
  String get vehicleInsurance;

  /// No description provided for @vehicleInsuranceDesc.
  ///
  /// In en, this message translates to:
  /// **'Valid vehicle insurance'**
  String get vehicleInsuranceDesc;

  /// No description provided for @policeClearance.
  ///
  /// In en, this message translates to:
  /// **'Police Clearance'**
  String get policeClearance;

  /// No description provided for @policeClearanceDesc.
  ///
  /// In en, this message translates to:
  /// **'Recent police clearance certificate'**
  String get policeClearanceDesc;

  /// No description provided for @facePhoto.
  ///
  /// In en, this message translates to:
  /// **'Face Photo'**
  String get facePhoto;

  /// No description provided for @facePhotoDesc.
  ///
  /// In en, this message translates to:
  /// **'Clear photo of your face'**
  String get facePhotoDesc;

  /// No description provided for @vehiclePhoto.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Photo'**
  String get vehiclePhoto;

  /// No description provided for @vehiclePhotoDesc.
  ///
  /// In en, this message translates to:
  /// **'Clear photo of your vehicle'**
  String get vehiclePhotoDesc;

  /// No description provided for @requiredDocuments.
  ///
  /// In en, this message translates to:
  /// **'Required Documents'**
  String get requiredDocuments;

  /// No description provided for @uploadClearPhotos.
  ///
  /// In en, this message translates to:
  /// **'Upload clear photos or scans of the required documents'**
  String get uploadClearPhotos;

  /// No description provided for @tapToUploadDoc.
  ///
  /// In en, this message translates to:
  /// **'Tap to upload {doc}'**
  String tapToUploadDoc(String doc);

  /// No description provided for @uploaded.
  ///
  /// In en, this message translates to:
  /// **'Uploaded'**
  String get uploaded;

  /// No description provided for @vehicleInfo.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Information'**
  String get vehicleInfo;

  /// No description provided for @provideVehicleDetails.
  ///
  /// In en, this message translates to:
  /// **'Provide details about your vehicle'**
  String get provideVehicleDetails;

  /// No description provided for @vehicleType.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Type'**
  String get vehicleType;

  /// No description provided for @car.
  ///
  /// In en, this message translates to:
  /// **'Car'**
  String get car;

  /// No description provided for @motorcycle.
  ///
  /// In en, this message translates to:
  /// **'Motorcycle'**
  String get motorcycle;

  /// No description provided for @cycle.
  ///
  /// In en, this message translates to:
  /// **'Cycle'**
  String get cycle;

  /// No description provided for @cycleType.
  ///
  /// In en, this message translates to:
  /// **'Cycle Type'**
  String get cycleType;

  /// No description provided for @normalCycle.
  ///
  /// In en, this message translates to:
  /// **'Normal Cycle'**
  String get normalCycle;

  /// No description provided for @electronicCycle.
  ///
  /// In en, this message translates to:
  /// **'Electronic Cycle'**
  String get electronicCycle;

  /// No description provided for @selectCycleType.
  ///
  /// In en, this message translates to:
  /// **'Select a cycle type'**
  String get selectCycleType;

  /// No description provided for @make.
  ///
  /// In en, this message translates to:
  /// **'Make'**
  String get make;

  /// No description provided for @makeRequired.
  ///
  /// In en, this message translates to:
  /// **'Make is required'**
  String get makeRequired;

  /// No description provided for @specifyMake.
  ///
  /// In en, this message translates to:
  /// **'Specify Make'**
  String get specifyMake;

  /// No description provided for @enterBrandManually.
  ///
  /// In en, this message translates to:
  /// **'Enter brand manually'**
  String get enterBrandManually;

  /// No description provided for @model.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get model;

  /// No description provided for @corollaCivic.
  ///
  /// In en, this message translates to:
  /// **'e.g., Corolla, Civic'**
  String get corollaCivic;

  /// No description provided for @modelRequired.
  ///
  /// In en, this message translates to:
  /// **'Model is required'**
  String get modelRequired;

  /// No description provided for @year.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get year;

  /// No description provided for @yearRequired.
  ///
  /// In en, this message translates to:
  /// **'Year is required'**
  String get yearRequired;

  /// No description provided for @invalidYear.
  ///
  /// In en, this message translates to:
  /// **'Invalid year'**
  String get invalidYear;

  /// No description provided for @exactColor.
  ///
  /// In en, this message translates to:
  /// **'Exact Color'**
  String get exactColor;

  /// No description provided for @matteBlack.
  ///
  /// In en, this message translates to:
  /// **'e.g., Matte Black'**
  String get matteBlack;

  /// No description provided for @colorRequired.
  ///
  /// In en, this message translates to:
  /// **'Color is required'**
  String get colorRequired;

  /// No description provided for @ownerFullName.
  ///
  /// In en, this message translates to:
  /// **'Owner Full Name'**
  String get ownerFullName;

  /// No description provided for @restaurantPhone.
  ///
  /// In en, this message translates to:
  /// **'Restaurant Phone'**
  String get restaurantPhone;

  /// No description provided for @vendorNameLabel.
  ///
  /// In en, this message translates to:
  /// **'{vendorType} Name'**
  String vendorNameLabel(String vendorType);

  /// No description provided for @vendorNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter {vendorType} name'**
  String vendorNameHint(String vendorType);

  /// No description provided for @vendorNameRequired.
  ///
  /// In en, this message translates to:
  /// **'{vendorType} Name is required'**
  String vendorNameRequired(String vendorType);

  /// No description provided for @vendorPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'{vendorType} Phone'**
  String vendorPhoneLabel(String vendorType);

  /// No description provided for @vendorPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'Enter {vendorType} phone'**
  String vendorPhoneHint(String vendorType);

  /// No description provided for @vendorPhoneRequired.
  ///
  /// In en, this message translates to:
  /// **'{vendorType} Phone is required'**
  String vendorPhoneRequired(String vendorType);

  /// No description provided for @vendorBrandingTitle.
  ///
  /// In en, this message translates to:
  /// **'{vendorType} Branding'**
  String vendorBrandingTitle(String vendorType);

  /// No description provided for @vendorLogoLabel.
  ///
  /// In en, this message translates to:
  /// **'{vendorType} Logo'**
  String vendorLogoLabel(String vendorType);

  /// No description provided for @noCuisinesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No cuisines available'**
  String get noCuisinesAvailable;

  /// No description provided for @contactInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact Information'**
  String get contactInfoTitle;

  /// No description provided for @contactInfoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Provide contact details for the business owner and restaurant.'**
  String get contactInfoSubtitle;

  /// No description provided for @ownerEmail.
  ///
  /// In en, this message translates to:
  /// **'Owner Email'**
  String get ownerEmail;

  /// No description provided for @ownerEmailHint.
  ///
  /// In en, this message translates to:
  /// **'your.email@example.com'**
  String get ownerEmailHint;

  /// No description provided for @ownerPhone.
  ///
  /// In en, this message translates to:
  /// **'Owner Phone'**
  String get ownerPhone;

  /// No description provided for @ownerPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'+20 1XX XXX XXXX'**
  String get ownerPhoneHint;

  /// No description provided for @contactRestaurantPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'Customer-facing phone number'**
  String get contactRestaurantPhoneHint;

  /// No description provided for @contactRestaurantPhoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Restaurant phone is required'**
  String get contactRestaurantPhoneRequired;

  /// No description provided for @fullAddress.
  ///
  /// In en, this message translates to:
  /// **'Full Address'**
  String get fullAddress;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @newSection.
  ///
  /// In en, this message translates to:
  /// **'New Section'**
  String get newSection;

  /// No description provided for @enterSectionName.
  ///
  /// In en, this message translates to:
  /// **'Enter section name'**
  String get enterSectionName;

  /// No description provided for @addNewSection.
  ///
  /// In en, this message translates to:
  /// **'Add New Section'**
  String get addNewSection;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @onSale.
  ///
  /// In en, this message translates to:
  /// **'On Sale'**
  String get onSale;

  /// No description provided for @tapAddItemToCreate.
  ///
  /// In en, this message translates to:
  /// **'Tap \'Add Item\' to create your first menu item'**
  String get tapAddItemToCreate;

  /// No description provided for @failedToDeleteItem.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete item'**
  String get failedToDeleteItem;

  /// No description provided for @accountSetup.
  ///
  /// In en, this message translates to:
  /// **'Account Setup'**
  String get accountSetup;

  /// No description provided for @fillDetailsToGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Fill out your details to get started'**
  String get fillDetailsToGetStarted;

  /// No description provided for @applicationSubmittedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your application has been submitted successfully!'**
  String get applicationSubmittedSuccess;

  /// No description provided for @enterCity.
  ///
  /// In en, this message translates to:
  /// **'Enter city'**
  String get enterCity;

  /// No description provided for @businessInfo.
  ///
  /// In en, this message translates to:
  /// **'Business Information'**
  String get businessInfo;

  /// No description provided for @provideBusinessDetails.
  ///
  /// In en, this message translates to:
  /// **'Provide your business details'**
  String get provideBusinessDetails;

  /// No description provided for @enterRestaurantName.
  ///
  /// In en, this message translates to:
  /// **'Enter restaurant name'**
  String get enterRestaurantName;

  /// No description provided for @enterDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter description'**
  String get enterDescription;

  /// No description provided for @enterOwnerName.
  ///
  /// In en, this message translates to:
  /// **'Enter owner name'**
  String get enterOwnerName;

  /// No description provided for @selectCuisinesPrompt.
  ///
  /// In en, this message translates to:
  /// **'Select at least one cuisine type'**
  String get selectCuisinesPrompt;

  /// No description provided for @selectAtLeastOneCuisine.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one cuisine'**
  String get selectAtLeastOneCuisine;

  /// No description provided for @enterRestaurantPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter restaurant phone'**
  String get enterRestaurantPhone;

  /// No description provided for @phoneHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., 01012345678'**
  String get phoneHint;

  /// No description provided for @whereIsRestaurant.
  ///
  /// In en, this message translates to:
  /// **'Where is your restaurant located?'**
  String get whereIsRestaurant;

  /// No description provided for @streetBuildingFloor.
  ///
  /// In en, this message translates to:
  /// **'Street, Building, Floor'**
  String get streetBuildingFloor;

  /// No description provided for @addressRequired.
  ///
  /// In en, this message translates to:
  /// **'Address is required'**
  String get addressRequired;

  /// No description provided for @cityRequired.
  ///
  /// In en, this message translates to:
  /// **'City is required'**
  String get cityRequired;

  /// No description provided for @pinpointLocation.
  ///
  /// In en, this message translates to:
  /// **'Pinpoint Location'**
  String get pinpointLocation;

  /// No description provided for @locationNotSet.
  ///
  /// In en, this message translates to:
  /// **'Location not set'**
  String get locationNotSet;

  /// No description provided for @setOpeningClosingTimes.
  ///
  /// In en, this message translates to:
  /// **'Set opening and closing times'**
  String get setOpeningClosingTimes;

  /// No description provided for @noRestaurantFound.
  ///
  /// In en, this message translates to:
  /// **'No restaurant found'**
  String get noRestaurantFound;

  /// No description provided for @completeRestaurantSetup.
  ///
  /// In en, this message translates to:
  /// **'Please complete your restaurant profile setup'**
  String get completeRestaurantSetup;

  /// No description provided for @searchMenuItems.
  ///
  /// In en, this message translates to:
  /// **'Search menu items…'**
  String get searchMenuItems;

  /// No description provided for @totalItems.
  ///
  /// In en, this message translates to:
  /// **'Total Items'**
  String get totalItems;

  /// No description provided for @tapToUploadCoverImage.
  ///
  /// In en, this message translates to:
  /// **'Tap to upload cover image'**
  String get tapToUploadCoverImage;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @deliveryRadiusLabel.
  ///
  /// In en, this message translates to:
  /// **'Delivery Radius'**
  String get deliveryRadiusLabel;

  /// No description provided for @updated.
  ///
  /// In en, this message translates to:
  /// **'{item} updated successfully'**
  String updated(String item);

  /// No description provided for @statusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get statusClosed;

  /// No description provided for @branding.
  ///
  /// In en, this message translates to:
  /// **'Branding'**
  String get branding;

  /// No description provided for @uploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get uploading;

  /// No description provided for @tapToUpload.
  ///
  /// In en, this message translates to:
  /// **'Tap to upload'**
  String get tapToUpload;

  /// No description provided for @uploadedDocuments.
  ///
  /// In en, this message translates to:
  /// **'Uploaded Documents'**
  String get uploadedDocuments;

  /// No description provided for @documentWithIndex.
  ///
  /// In en, this message translates to:
  /// **'Document {index}'**
  String documentWithIndex(String index);

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @currencySymbol.
  ///
  /// In en, this message translates to:
  /// **'\$'**
  String get currencySymbol;

  /// No description provided for @promotions.
  ///
  /// In en, this message translates to:
  /// **'Promotions'**
  String get promotions;

  /// No description provided for @reviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviews;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactUs;

  /// No description provided for @restaurantDashboard.
  ///
  /// In en, this message translates to:
  /// **'Restaurant Dashboard'**
  String get restaurantDashboard;

  /// No description provided for @paymentCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get paymentCash;

  /// No description provided for @paymentCard.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get paymentCard;

  /// No description provided for @paymentWallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get paymentWallet;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get statusFailed;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// No description provided for @statusSuspended.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get statusSuspended;

  /// No description provided for @protectYourAccountWithAnExtraLayerOfSecurity.
  ///
  /// In en, this message translates to:
  /// **'Protect your account with an extra layer of security.'**
  String get protectYourAccountWithAnExtraLayerOfSecurity;

  /// No description provided for @yourDataWillBePreparedAndSentToYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Your data will be prepared and sent to your email.'**
  String get yourDataWillBePreparedAndSentToYourEmail;

  /// No description provided for @accountDeletionScheduledYouWillReceiveAConfirmatio.
  ///
  /// In en, this message translates to:
  /// **'Account deletion scheduled. You will receive a confirmation email.'**
  String get accountDeletionScheduledYouWillReceiveAConfirmatio;

  /// No description provided for @loadMore.
  ///
  /// In en, this message translates to:
  /// **'Load More'**
  String get loadMore;

  /// No description provided for @locationUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Location updated successfully'**
  String get locationUpdatedSuccessfully;

  /// No description provided for @editPaymentMethodFunctionalityWillBeImplementedHer.
  ///
  /// In en, this message translates to:
  /// **'Edit payment method functionality will be implemented here.'**
  String get editPaymentMethodFunctionalityWillBeImplementedHer;

  /// No description provided for @egpAmount.
  ///
  /// In en, this message translates to:
  /// **'EGP {amount}'**
  String egpAmount(String amount);

  /// No description provided for @reportedOnDate.
  ///
  /// In en, this message translates to:
  /// **'Reported on {date}'**
  String reportedOnDate(String date);

  /// No description provided for @disputeId.
  ///
  /// In en, this message translates to:
  /// **'Dispute - {id}'**
  String disputeId(String id);

  /// No description provided for @disputeStatusUpdated.
  ///
  /// In en, this message translates to:
  /// **'Dispute {id} status updated to {status}'**
  String disputeStatusUpdated(String id, String status);

  /// No description provided for @allDisputesCount.
  ///
  /// In en, this message translates to:
  /// **'All Disputes ({count})'**
  String allDisputesCount(int count);

  /// No description provided for @userStatusUpdated.
  ///
  /// In en, this message translates to:
  /// **'User {id} status updated to {status}'**
  String userStatusUpdated(String id, String status);

  /// No description provided for @downloadingReport.
  ///
  /// In en, this message translates to:
  /// **'Downloading {report}...'**
  String downloadingReport(String report);

  /// No description provided for @previewingReport.
  ///
  /// In en, this message translates to:
  /// **'Previewing {report}...'**
  String previewingReport(String report);

  /// No description provided for @noTypeApplications.
  ///
  /// In en, this message translates to:
  /// **'No {type} applications'**
  String noTypeApplications(String type);

  /// No description provided for @rejectSection.
  ///
  /// In en, this message translates to:
  /// **'Reject {section}'**
  String rejectSection(String section);

  /// No description provided for @allCountParentheses.
  ///
  /// In en, this message translates to:
  /// **'All ({count})'**
  String allCountParentheses(String count);

  /// No description provided for @nameValue.
  ///
  /// In en, this message translates to:
  /// **'Name: {value}'**
  String nameValue(String value);

  /// No description provided for @emailValue.
  ///
  /// In en, this message translates to:
  /// **'Email: {value}'**
  String emailValue(String value);

  /// No description provided for @phoneValue.
  ///
  /// In en, this message translates to:
  /// **'Phone: {value}'**
  String phoneValue(String value);

  /// No description provided for @roleValue.
  ///
  /// In en, this message translates to:
  /// **'Role: {value}'**
  String roleValue(String value);

  /// No description provided for @statusValue.
  ///
  /// In en, this message translates to:
  /// **'Status: {value}'**
  String statusValue(String value);

  /// No description provided for @joinDateValue.
  ///
  /// In en, this message translates to:
  /// **'Join Date: {value}'**
  String joinDateValue(String value);

  /// No description provided for @deleteConfirmItem.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{item}\"?\nThis action cannot be undone.'**
  String deleteConfirmItem(String item);

  /// No description provided for @errorValue.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorValue(String error);

  /// No description provided for @failedToUpdate.
  ///
  /// In en, this message translates to:
  /// **'Failed to update: {error}'**
  String failedToUpdate(String error);

  /// No description provided for @rejectionReasonValue.
  ///
  /// In en, this message translates to:
  /// **'Rejection reason: {reason}'**
  String rejectionReasonValue(String reason);

  /// No description provided for @rejectItem.
  ///
  /// In en, this message translates to:
  /// **'Reject \"{item}\"'**
  String rejectItem(String item);

  /// No description provided for @orderIdValue.
  ///
  /// In en, this message translates to:
  /// **'Order ID: {id}'**
  String orderIdValue(String id);

  /// No description provided for @customerValue.
  ///
  /// In en, this message translates to:
  /// **'Customer: {name}'**
  String customerValue(String name);

  /// No description provided for @restaurantValue.
  ///
  /// In en, this message translates to:
  /// **'Restaurant: {name}'**
  String restaurantValue(String name);

  /// No description provided for @amountEgpValue.
  ///
  /// In en, this message translates to:
  /// **'Amount: EGP {amount}'**
  String amountEgpValue(String amount);

  /// No description provided for @itemsValue.
  ///
  /// In en, this message translates to:
  /// **'Items: {count}'**
  String itemsValue(String count);

  /// No description provided for @dateValue.
  ///
  /// In en, this message translates to:
  /// **'Date: {date}'**
  String dateValue(String date);

  /// No description provided for @timeValue.
  ///
  /// In en, this message translates to:
  /// **'Time: {time}'**
  String timeValue(String time);

  /// No description provided for @failedToReorder.
  ///
  /// In en, this message translates to:
  /// **'Failed to reorder: {error}'**
  String failedToReorder(String error);

  /// No description provided for @callCustomerName.
  ///
  /// In en, this message translates to:
  /// **'Call {name}?'**
  String callCustomerName(String name);

  /// No description provided for @callRestaurantName.
  ///
  /// In en, this message translates to:
  /// **'Call {name}?'**
  String callRestaurantName(String name);

  /// No description provided for @assignDriverId.
  ///
  /// In en, this message translates to:
  /// **'Assign {id}'**
  String assignDriverId(String id);

  /// No description provided for @failedToSave.
  ///
  /// In en, this message translates to:
  /// **'Failed to save: {error}'**
  String failedToSave(String error);

  /// No description provided for @payoutFrequencySet.
  ///
  /// In en, this message translates to:
  /// **'Payout frequency set to {freq}'**
  String payoutFrequencySet(String freq);

  /// No description provided for @minimumPayoutSet.
  ///
  /// In en, this message translates to:
  /// **'Minimum payout set to \${amount}'**
  String minimumPayoutSet(String amount);

  /// No description provided for @editMethodName.
  ///
  /// In en, this message translates to:
  /// **'Edit {name}'**
  String editMethodName(String name);

  /// No description provided for @expiresDate.
  ///
  /// In en, this message translates to:
  /// **'Expires {date}'**
  String expiresDate(String date);

  /// No description provided for @addWalletType.
  ///
  /// In en, this message translates to:
  /// **'Add {type}'**
  String addWalletType(String type);

  /// No description provided for @enterWalletPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter your {type} phone number'**
  String enterWalletPhone(String type);

  /// No description provided for @restaurantIndex.
  ///
  /// In en, this message translates to:
  /// **'Restaurant {index}'**
  String restaurantIndex(String index);

  /// No description provided for @lastActiveDate.
  ///
  /// In en, this message translates to:
  /// **'Last active: {date}'**
  String lastActiveDate(String date);

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network error, please check your connection.'**
  String get networkError;

  /// No description provided for @serverError.
  ///
  /// In en, this message translates to:
  /// **'Server connection failed.'**
  String get serverError;

  /// No description provided for @invalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password.'**
  String get invalidCredentials;

  /// No description provided for @emailInUse.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered.'**
  String get emailInUse;

  /// No description provided for @tooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Please try again later.'**
  String get tooManyRequests;

  /// No description provided for @authFailed.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed. Please try again.'**
  String get authFailed;

  /// No description provided for @unexpectedError.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred.'**
  String get unexpectedError;

  /// No description provided for @driverDeliveries.
  ///
  /// In en, this message translates to:
  /// **'Deliveries'**
  String get driverDeliveries;

  /// No description provided for @driverHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get driverHistory;

  /// No description provided for @youAreOnline.
  ///
  /// In en, this message translates to:
  /// **'You\'re Online'**
  String get youAreOnline;

  /// No description provided for @youAreOffline.
  ///
  /// In en, this message translates to:
  /// **'You\'re Offline'**
  String get youAreOffline;

  /// No description provided for @readyToAcceptDeliveries.
  ///
  /// In en, this message translates to:
  /// **'Ready to accept deliveries'**
  String get readyToAcceptDeliveries;

  /// No description provided for @notReceivingRequests.
  ///
  /// In en, this message translates to:
  /// **'You will not receive delivery requests'**
  String get notReceivingRequests;

  /// No description provided for @goOffline.
  ///
  /// In en, this message translates to:
  /// **'Go Offline'**
  String get goOffline;

  /// No description provided for @goOnline.
  ///
  /// In en, this message translates to:
  /// **'Go Online'**
  String get goOnline;

  /// No description provided for @todaysEarnings.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Earnings'**
  String get todaysEarnings;

  /// No description provided for @keepDeliveringToIncrease.
  ///
  /// In en, this message translates to:
  /// **'Keep delivering to increase your earnings!'**
  String get keepDeliveringToIncrease;

  /// No description provided for @activeTrips.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeTrips;

  /// No description provided for @pendingTrips.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pendingTrips;

  /// No description provided for @totalTrips.
  ///
  /// In en, this message translates to:
  /// **'Total Trips'**
  String get totalTrips;

  /// No description provided for @confirmDeliveryProceed.
  ///
  /// In en, this message translates to:
  /// **'Have you delivered all items to the customer?'**
  String get confirmDeliveryProceed;

  /// No description provided for @turnOnToStartReceivingOrders.
  ///
  /// In en, this message translates to:
  /// **'Turn on to start receiving orders'**
  String get turnOnToStartReceivingOrders;

  /// No description provided for @cantGoOfflineWithActiveOrder.
  ///
  /// In en, this message translates to:
  /// **'You can\'t go offline while you have an active order'**
  String get cantGoOfflineWithActiveOrder;

  /// No description provided for @chooseTheFoodYouLove.
  ///
  /// In en, this message translates to:
  /// **'Choose the Food you love'**
  String get chooseTheFoodYouLove;

  /// No description provided for @orderBestDishes.
  ///
  /// In en, this message translates to:
  /// **'Order the best dishes from your favorite restaurants with fast delivery to your door.'**
  String get orderBestDishes;

  /// No description provided for @searchForFoodItem.
  ///
  /// In en, this message translates to:
  /// **'Search for a food item...'**
  String get searchForFoodItem;

  /// No description provided for @orderNow.
  ///
  /// In en, this message translates to:
  /// **'Order Now'**
  String get orderNow;

  /// No description provided for @whatDoYouNeed.
  ///
  /// In en, this message translates to:
  /// **'WHAT ARE WE DELIVERING TODAY?'**
  String get whatDoYouNeed;

  /// No description provided for @soon.
  ///
  /// In en, this message translates to:
  /// **'Soon'**
  String get soon;

  /// No description provided for @fastDelivery.
  ///
  /// In en, this message translates to:
  /// **'Fast Delivery'**
  String get fastDelivery;

  /// No description provided for @orderFoodBestRestaurants.
  ///
  /// In en, this message translates to:
  /// **'Order food from the best restaurants near you with lightning-fast delivery.'**
  String get orderFoodBestRestaurants;

  /// No description provided for @browseRestaurantsBtn.
  ///
  /// In en, this message translates to:
  /// **'Browse Restaurants'**
  String get browseRestaurantsBtn;

  /// No description provided for @activeOrdersTab.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeOrdersTab;

  /// No description provided for @pastOrdersTab.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get pastOrdersTab;

  /// No description provided for @noActiveOrders.
  ///
  /// In en, this message translates to:
  /// **'No active orders'**
  String get noActiveOrders;

  /// No description provided for @noPastOrders.
  ///
  /// In en, this message translates to:
  /// **'No past orders'**
  String get noPastOrders;

  /// No description provided for @activeOrdersAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Your active orders will appear here'**
  String get activeOrdersAppearHere;

  /// No description provided for @pastOrdersAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Your past orders will appear here'**
  String get pastOrdersAppearHere;

  /// No description provided for @reorder.
  ///
  /// In en, this message translates to:
  /// **'Reorder'**
  String get reorder;

  /// No description provided for @rate.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get rate;

  /// No description provided for @etaCalculating.
  ///
  /// In en, this message translates to:
  /// **'Calculating...'**
  String get etaCalculating;

  /// No description provided for @orderTimeline.
  ///
  /// In en, this message translates to:
  /// **'Order Timeline'**
  String get orderTimeline;

  /// No description provided for @waitingForRestaurant.
  ///
  /// In en, this message translates to:
  /// **'Waiting for restaurant'**
  String get waitingForRestaurant;

  /// No description provided for @dispatching.
  ///
  /// In en, this message translates to:
  /// **'Dispatching'**
  String get dispatching;

  /// No description provided for @waitingToAssignDriver.
  ///
  /// In en, this message translates to:
  /// **'Waiting to assign driver'**
  String get waitingToAssignDriver;

  /// No description provided for @outForDelivery.
  ///
  /// In en, this message translates to:
  /// **'Out for Delivery'**
  String get outForDelivery;

  /// No description provided for @waitingForPickUp.
  ///
  /// In en, this message translates to:
  /// **'Waiting for pick up'**
  String get waitingForPickUp;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @driverRole.
  ///
  /// In en, this message translates to:
  /// **'DRIVER'**
  String get driverRole;

  /// No description provided for @drawerWallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get drawerWallet;

  /// No description provided for @drawerLogout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get drawerLogout;

  /// No description provided for @drawerHelpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get drawerHelpSupport;

  /// No description provided for @excelImportBtn.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get excelImportBtn;

  /// No description provided for @excelImportTitle.
  ///
  /// In en, this message translates to:
  /// **'Bulk Import from Excel'**
  String get excelImportTitle;

  /// No description provided for @excelImportPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Preview ({count} rows)'**
  String excelImportPreviewTitle(int count);

  /// No description provided for @excelImportingTitle.
  ///
  /// In en, this message translates to:
  /// **'Importing…'**
  String get excelImportingTitle;

  /// No description provided for @excelImportDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Import Complete'**
  String get excelImportDoneTitle;

  /// No description provided for @excelImportStep1.
  ///
  /// In en, this message translates to:
  /// **'1. Download the template Excel file below.'**
  String get excelImportStep1;

  /// No description provided for @excelImportStep2.
  ///
  /// In en, this message translates to:
  /// **'2. Fill in your items — Section and Available columns have dropdowns.'**
  String get excelImportStep2;

  /// No description provided for @excelImportStep3.
  ///
  /// In en, this message translates to:
  /// **'3. Upload the filled file and preview before importing.'**
  String get excelImportStep3;

  /// No description provided for @excelImportStep4.
  ///
  /// In en, this message translates to:
  /// **'4. Add item images after import using the edit button on each item.'**
  String get excelImportStep4;

  /// No description provided for @excelImportSectionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Sections for {vendorType}'**
  String excelImportSectionsLabel(String vendorType);

  /// No description provided for @excelImportDownloadTemplate.
  ///
  /// In en, this message translates to:
  /// **'Download Template'**
  String get excelImportDownloadTemplate;

  /// No description provided for @excelImportUploadFile.
  ///
  /// In en, this message translates to:
  /// **'Upload Excel File (.xlsx)'**
  String get excelImportUploadFile;

  /// No description provided for @excelImportFailedTemplate.
  ///
  /// In en, this message translates to:
  /// **'Failed to generate template: {error}'**
  String excelImportFailedTemplate(String error);

  /// No description provided for @excelImportCouldNotRead.
  ///
  /// In en, this message translates to:
  /// **'Could not read file bytes.'**
  String get excelImportCouldNotRead;

  /// No description provided for @excelImportNoData.
  ///
  /// In en, this message translates to:
  /// **'No data rows found. Make sure the file has a \"Menu Items\" sheet and data starting from row 3.'**
  String get excelImportNoData;

  /// No description provided for @excelImportFailedRead.
  ///
  /// In en, this message translates to:
  /// **'Failed to read file: {error}'**
  String excelImportFailedRead(String error);

  /// No description provided for @excelImportFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed. Check your connection and try again.'**
  String get excelImportFailed;

  /// No description provided for @excelImportSuccessCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items imported successfully.'**
  String excelImportSuccessCount(int count);

  /// No description provided for @excelImportAddImages.
  ///
  /// In en, this message translates to:
  /// **'To add item images, tap the edit button on any item in your menu.'**
  String get excelImportAddImages;

  /// No description provided for @excelImportSkippedRows.
  ///
  /// In en, this message translates to:
  /// **'{count} row(s) were skipped.'**
  String excelImportSkippedRows(int count);

  /// No description provided for @excelImportDownloadSkipLog.
  ///
  /// In en, this message translates to:
  /// **'Download Skip Log'**
  String get excelImportDownloadSkipLog;

  /// No description provided for @excelImportClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get excelImportClose;

  /// No description provided for @excelImportReupload.
  ///
  /// In en, this message translates to:
  /// **'Re-upload'**
  String get excelImportReupload;

  /// No description provided for @excelImportConfirmBtn.
  ///
  /// In en, this message translates to:
  /// **'Import {count} Item(s)'**
  String excelImportConfirmBtn(int count);

  /// No description provided for @excelImportValid.
  ///
  /// In en, this message translates to:
  /// **'valid'**
  String get excelImportValid;

  /// No description provided for @excelImportErrors.
  ///
  /// In en, this message translates to:
  /// **'errors (skipped)'**
  String get excelImportErrors;

  /// No description provided for @excelImportProgress.
  ///
  /// In en, this message translates to:
  /// **'Importing item {current} of {total}…'**
  String excelImportProgress(int current, int total);

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @editProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update your personal information'**
  String get editProfileSubtitle;

  /// No description provided for @changePasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update your login password'**
  String get changePasswordSubtitle;

  /// No description provided for @savedAddressesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your delivery locations'**
  String get savedAddressesSubtitle;

  /// No description provided for @preferencesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your language and display settings'**
  String get preferencesSubtitle;

  /// No description provided for @liveChatSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Chat with our support agents'**
  String get liveChatSubtitle;

  /// No description provided for @emailUs.
  ///
  /// In en, this message translates to:
  /// **'Email Us'**
  String get emailUs;

  /// No description provided for @emailUsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'support@zspeed.app'**
  String get emailUsSubtitle;

  /// No description provided for @callUs.
  ///
  /// In en, this message translates to:
  /// **'Call Us'**
  String get callUs;

  /// No description provided for @callUsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'+20 100 000 0000'**
  String get callUsSubtitle;

  /// No description provided for @faqSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Frequently asked questions'**
  String get faqSubtitle;

  /// No description provided for @userGuideSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Learn how to use the app'**
  String get userGuideSubtitle;

  /// No description provided for @videoTutorialsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Watch step-by-step guides'**
  String get videoTutorialsSubtitle;

  /// No description provided for @contactSupportTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupportTitle;

  /// No description provided for @contactSupportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reach out to our support team'**
  String get contactSupportSubtitle;

  /// No description provided for @resourcesTitle.
  ///
  /// In en, this message translates to:
  /// **'Resources'**
  String get resourcesTitle;

  /// No description provided for @orderDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get orderDelivered;

  /// No description provided for @enjoyYourMeal.
  ///
  /// In en, this message translates to:
  /// **'Enjoy your meal!'**
  String get enjoyYourMeal;

  /// No description provided for @arrivingSoon.
  ///
  /// In en, this message translates to:
  /// **'Arriving soon'**
  String get arrivingSoon;

  /// No description provided for @driverAssigned.
  ///
  /// In en, this message translates to:
  /// **'Driver assigned!'**
  String get driverAssigned;

  /// No description provided for @searchingForNearbyDriver.
  ///
  /// In en, this message translates to:
  /// **'Searching for nearby driver...'**
  String get searchingForNearbyDriver;

  /// No description provided for @noDriversAvailableVicinity.
  ///
  /// In en, this message translates to:
  /// **'No drivers available in vicinity'**
  String get noDriversAvailableVicinity;

  /// No description provided for @assigningDriver.
  ///
  /// In en, this message translates to:
  /// **'Assigning driver...'**
  String get assigningDriver;

  /// No description provided for @verifyYourPhone.
  ///
  /// In en, this message translates to:
  /// **'Verify your phone'**
  String get verifyYourPhone;

  /// No description provided for @addYourPhoneNumberUpdates.
  ///
  /// In en, this message translates to:
  /// **'Add your phone number for order updates and delivery coordination'**
  String get addYourPhoneNumberUpdates;

  /// No description provided for @phoneNum.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNum;

  /// No description provided for @sendCode.
  ///
  /// In en, this message translates to:
  /// **'Send Code'**
  String get sendCode;

  /// No description provided for @illDoThisLater.
  ///
  /// In en, this message translates to:
  /// **'I\'ll do this later'**
  String get illDoThisLater;

  /// No description provided for @verifyPhone.
  ///
  /// In en, this message translates to:
  /// **'Verify Phone'**
  String get verifyPhone;

  /// No description provided for @minOrderInfo.
  ///
  /// In en, this message translates to:
  /// **'min order'**
  String get minOrderInfo;

  /// No description provided for @deliveryFeeInfo.
  ///
  /// In en, this message translates to:
  /// **'delivery'**
  String get deliveryFeeInfo;

  /// No description provided for @deliveryMinInfo.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get deliveryMinInfo;

  /// No description provided for @noItemsInSection.
  ///
  /// In en, this message translates to:
  /// **'No items in this section'**
  String get noItemsInSection;

  /// No description provided for @viewCartBtn.
  ///
  /// In en, this message translates to:
  /// **'VIEW CART'**
  String get viewCartBtn;

  /// No description provided for @setDeliveryAddress.
  ///
  /// In en, this message translates to:
  /// **'Set your delivery address'**
  String get setDeliveryAddress;

  /// No description provided for @searchRestaurantsDishes.
  ///
  /// In en, this message translates to:
  /// **'Search restaurants, dishes or cuisines...'**
  String get searchRestaurantsDishes;

  /// No description provided for @acceptance.
  ///
  /// In en, this message translates to:
  /// **'Acceptance'**
  String get acceptance;

  /// No description provided for @currentLocationUpdate.
  ///
  /// In en, this message translates to:
  /// **'Current Location'**
  String get currentLocationUpdate;

  /// No description provided for @updateBtn.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get updateBtn;

  /// No description provided for @gpsTrackingActive.
  ///
  /// In en, this message translates to:
  /// **'GPS tracking active - Location updates every 30 seconds'**
  String get gpsTrackingActive;

  /// No description provided for @checkoutLabel.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get checkoutLabel;

  /// No description provided for @orderSummaryLabel.
  ///
  /// In en, this message translates to:
  /// **'Order Summary'**
  String get orderSummaryLabel;

  /// No description provided for @deliveryAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Delivery Address'**
  String get deliveryAddressLabel;

  /// No description provided for @enterYourDeliveryAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter your delivery address'**
  String get enterYourDeliveryAddress;

  /// No description provided for @deliveryInstructionsOptional.
  ///
  /// In en, this message translates to:
  /// **'Delivery Instructions (Optional)'**
  String get deliveryInstructionsOptional;

  /// No description provided for @egRingDoorbell.
  ///
  /// In en, this message translates to:
  /// **'e.g., Ring doorbell, 2nd floor'**
  String get egRingDoorbell;

  /// No description provided for @placeOrderLabel.
  ///
  /// In en, this message translates to:
  /// **'Place Order'**
  String get placeOrderLabel;

  /// No description provided for @subtotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotalLabel;

  /// No description provided for @deliveryFeeLabel.
  ///
  /// In en, this message translates to:
  /// **'Delivery Fee'**
  String get deliveryFeeLabel;

  /// No description provided for @itemsCount.
  ///
  /// In en, this message translates to:
  /// **'items {count}'**
  String itemsCount(int count);

  /// No description provided for @searchRestaurantsPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'...Search restaurants, dishes or cuisines'**
  String get searchRestaurantsPlaceholder;

  /// No description provided for @setYourDeliveryAddress.
  ///
  /// In en, this message translates to:
  /// **'Set your delivery address'**
  String get setYourDeliveryAddress;

  /// No description provided for @customerPortal.
  ///
  /// In en, this message translates to:
  /// **'CUSTOMER PORTAL'**
  String get customerPortal;

  /// No description provided for @sortByLabel.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortByLabel;

  /// No description provided for @fastFoodCategory.
  ///
  /// In en, this message translates to:
  /// **'Fast Food'**
  String get fastFoodCategory;

  /// No description provided for @egyptianCategory.
  ///
  /// In en, this message translates to:
  /// **'Egyptian'**
  String get egyptianCategory;

  /// No description provided for @allCategory.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allCategory;

  /// No description provided for @editProfileLabel.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfileLabel;

  /// No description provided for @updatePersonalInfo.
  ///
  /// In en, this message translates to:
  /// **'Update your personal information'**
  String get updatePersonalInfo;

  /// No description provided for @changePasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePasswordLabel;

  /// No description provided for @updateLoginPassword.
  ///
  /// In en, this message translates to:
  /// **'Update your login password'**
  String get updateLoginPassword;

  /// No description provided for @paymentMethodsLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment Methods'**
  String get paymentMethodsLabel;

  /// No description provided for @managePaymentOptions.
  ///
  /// In en, this message translates to:
  /// **'Manage your payment options'**
  String get managePaymentOptions;

  /// No description provided for @savedAddressesLabel.
  ///
  /// In en, this message translates to:
  /// **'Saved Addresses'**
  String get savedAddressesLabel;

  /// No description provided for @manageDeliveryLocations.
  ///
  /// In en, this message translates to:
  /// **'Manage your delivery locations'**
  String get manageDeliveryLocations;

  /// No description provided for @preferencesLabel.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferencesLabel;

  /// No description provided for @notificationsLabel.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsLabel;

  /// No description provided for @receiveOrderUpdates.
  ///
  /// In en, this message translates to:
  /// **'Receive order updates and promotions'**
  String get receiveOrderUpdates;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @choosePreferredLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred language'**
  String get choosePreferredLanguage;

  /// No description provided for @englishLanguage.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get englishLanguage;

  /// No description provided for @arabicLanguage.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabicLanguage;

  /// No description provided for @verifyPhoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your phone'**
  String get verifyPhoneTitle;

  /// No description provided for @verifyPhoneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add your phone number for order updates and delivery coordination.'**
  String get verifyPhoneSubtitle;

  /// No description provided for @phoneNumberPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumberPlaceholder;

  /// No description provided for @sendCodeButton.
  ///
  /// In en, this message translates to:
  /// **'Send Code'**
  String get sendCodeButton;

  /// No description provided for @deliveryDriver.
  ///
  /// In en, this message translates to:
  /// **'Delivery Driver'**
  String get deliveryDriver;

  /// No description provided for @driverNotAssignedYet.
  ///
  /// In en, this message translates to:
  /// **'Driver not assigned yet'**
  String get driverNotAssignedYet;

  /// No description provided for @assignDriverOnceReady.
  ///
  /// In en, this message translates to:
  /// **'We\'ll assign a driver once your order is ready'**
  String get assignDriverOnceReady;

  /// No description provided for @paymentSection.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get paymentSection;

  /// No description provided for @welcomeBackToast.
  ///
  /// In en, this message translates to:
  /// **'Welcome back, {firstName}! 👋'**
  String welcomeBackToast(String firstName);

  /// No description provided for @whatAreYouCravingToday.
  ///
  /// In en, this message translates to:
  /// **'What are you craving today?'**
  String get whatAreYouCravingToday;

  /// No description provided for @chooseFoodYouLove.
  ///
  /// In en, this message translates to:
  /// **'Choose Food You Love'**
  String get chooseFoodYouLove;

  /// No description provided for @selectLocationOnMap.
  ///
  /// In en, this message translates to:
  /// **'Select Location on Map'**
  String get selectLocationOnMap;

  /// No description provided for @tapToPinYourDeliveryLocation.
  ///
  /// In en, this message translates to:
  /// **'Tap to pin your delivery location'**
  String get tapToPinYourDeliveryLocation;

  /// No description provided for @deliveryLocation.
  ///
  /// In en, this message translates to:
  /// **'Delivery Location'**
  String get deliveryLocation;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @signOutWarning.
  ///
  /// In en, this message translates to:
  /// **'You will be signed out of your account. Sign in again to continue.'**
  String get signOutWarning;

  /// No description provided for @logoutFailed.
  ///
  /// In en, this message translates to:
  /// **'Logout failed'**
  String get logoutFailed;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @resetPasswordInstructions.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we\'ll send a reset link.'**
  String get resetPasswordInstructions;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get sendResetLink;

  /// No description provided for @resetLinkSent.
  ///
  /// In en, this message translates to:
  /// **'Reset link sent! Check your inbox.'**
  String get resetLinkSent;

  /// No description provided for @failedToSendResetEmail.
  ///
  /// In en, this message translates to:
  /// **'Failed to send reset email. Try again.'**
  String get failedToSendResetEmail;

  /// No description provided for @signUpFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign up failed'**
  String get signUpFailed;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get loginFailed;

  /// No description provided for @googleSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed'**
  String get googleSignInFailed;

  /// No description provided for @signInWithPhone.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Phone'**
  String get signInWithPhone;

  /// No description provided for @phoneVerificationSmsHint.
  ///
  /// In en, this message translates to:
  /// **'We\'ll send a verification code via SMS'**
  String get phoneVerificationSmsHint;

  /// No description provided for @enterValidPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number (e.g. 01012345678 or +201012345678)'**
  String get enterValidPhoneNumber;

  /// No description provided for @failedToSendCode.
  ///
  /// In en, this message translates to:
  /// **'Failed to send code'**
  String get failedToSendCode;

  /// No description provided for @autoVerificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Auto-verification failed'**
  String get autoVerificationFailed;

  /// No description provided for @failedToSendSms.
  ///
  /// In en, this message translates to:
  /// **'Failed to send SMS'**
  String get failedToSendSms;

  /// No description provided for @verifyAndSignIn.
  ///
  /// In en, this message translates to:
  /// **'Verify & Sign In'**
  String get verifyAndSignIn;

  /// No description provided for @sendVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Send Verification Code'**
  String get sendVerificationCode;

  /// No description provided for @enterSixDigitCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code'**
  String get enterSixDigitCode;

  /// No description provided for @verificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Verification failed'**
  String get verificationFailed;

  /// No description provided for @invalidCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid code'**
  String get invalidCode;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @resendCode2.
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get resendCode2;

  /// No description provided for @fullNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Ahmed Hassan'**
  String get fullNameHint;

  /// No description provided for @fullNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get fullNameRequired;

  /// No description provided for @nameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Name is too short'**
  String get nameTooShort;

  /// No description provided for @weNeedYourName.
  ///
  /// In en, this message translates to:
  /// **'We need your name for orders and delivery.'**
  String get weNeedYourName;

  /// No description provided for @failedToSaveName.
  ///
  /// In en, this message translates to:
  /// **'Failed to save name'**
  String get failedToSaveName;

  /// No description provided for @verifyYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Verify your email'**
  String get verifyYourEmail;

  /// No description provided for @emailVerified.
  ///
  /// In en, this message translates to:
  /// **'Email Verified!'**
  String get emailVerified;

  /// No description provided for @sentSixDigitCodeTo.
  ///
  /// In en, this message translates to:
  /// **'We\'ve sent a 6-digit code to:'**
  String get sentSixDigitCodeTo;

  /// No description provided for @emailVerifiedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Your email has been verified successfully!'**
  String get emailVerifiedSuccessfully;

  /// No description provided for @failedToSendVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Failed to send verification code.'**
  String get failedToSendVerificationCode;

  /// No description provided for @failedToSendVerificationCodeRetry.
  ///
  /// In en, this message translates to:
  /// **'Failed to send verification code. Please try again.'**
  String get failedToSendVerificationCodeRetry;

  /// No description provided for @pleaseEnterSixDigitCode.
  ///
  /// In en, this message translates to:
  /// **'Please enter the 6-digit code.'**
  String get pleaseEnterSixDigitCode;

  /// No description provided for @invalidCodeError.
  ///
  /// In en, this message translates to:
  /// **'Invalid code.'**
  String get invalidCodeError;

  /// No description provided for @verificationFailedRetry.
  ///
  /// In en, this message translates to:
  /// **'Verification failed. Please try again.'**
  String get verificationFailedRetry;

  /// No description provided for @verifyCode.
  ///
  /// In en, this message translates to:
  /// **'Verify Code'**
  String get verifyCode;

  /// No description provided for @sending.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get sending;

  /// No description provided for @resendInSeconds.
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds}s'**
  String resendInSeconds(int seconds);

  /// No description provided for @illVerifyLater.
  ///
  /// In en, this message translates to:
  /// **'I\'ll verify later'**
  String get illVerifyLater;

  /// No description provided for @chooseYourRole.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Role'**
  String get chooseYourRole;

  /// No description provided for @selectHowYouWantToUse.
  ///
  /// In en, this message translates to:
  /// **'Select how you want to use Z Speed Delivery'**
  String get selectHowYouWantToUse;

  /// No description provided for @roleCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get roleCustomer;

  /// No description provided for @roleCustomerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Order food & track delivery'**
  String get roleCustomerSubtitle;

  /// No description provided for @roleDriver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get roleDriver;

  /// No description provided for @roleDriverSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Deliver orders & earn money'**
  String get roleDriverSubtitle;

  /// No description provided for @roleVendor.
  ///
  /// In en, this message translates to:
  /// **'Vendor / Partner'**
  String get roleVendor;

  /// No description provided for @roleVendorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Restaurant, Supermarket or Pharmacy'**
  String get roleVendorSubtitle;

  /// No description provided for @roleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get roleAdmin;

  /// No description provided for @roleAdminSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Full platform management'**
  String get roleAdminSubtitle;

  /// No description provided for @selected.
  ///
  /// In en, this message translates to:
  /// **'✓ Selected'**
  String get selected;

  /// No description provided for @adminManagement.
  ///
  /// In en, this message translates to:
  /// **'Admin Management'**
  String get adminManagement;

  /// No description provided for @addAdmin.
  ///
  /// In en, this message translates to:
  /// **'Add Admin'**
  String get addAdmin;

  /// No description provided for @addNewAdmin.
  ///
  /// In en, this message translates to:
  /// **'Add New Admin'**
  String get addNewAdmin;

  /// No description provided for @searchAdmins.
  ///
  /// In en, this message translates to:
  /// **'Search admins...'**
  String get searchAdmins;

  /// No description provided for @adminsList.
  ///
  /// In en, this message translates to:
  /// **'Admins List'**
  String get adminsList;

  /// No description provided for @adminColumnHeader.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get adminColumnHeader;

  /// No description provided for @joinedColumnHeader.
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get joinedColumnHeader;

  /// No description provided for @noAdminUsersFound.
  ///
  /// In en, this message translates to:
  /// **'No admin users found'**
  String get noAdminUsersFound;

  /// No description provided for @adminCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Admin created successfully'**
  String get adminCreatedSuccessfully;

  /// No description provided for @userManagement.
  ///
  /// In en, this message translates to:
  /// **'User Management'**
  String get userManagement;

  /// No description provided for @usersList.
  ///
  /// In en, this message translates to:
  /// **'Users List'**
  String get usersList;

  /// No description provided for @userColumnHeader.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get userColumnHeader;

  /// No description provided for @actionsColumnHeader.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actionsColumnHeader;

  /// No description provided for @searchUsers.
  ///
  /// In en, this message translates to:
  /// **'Search users...'**
  String get searchUsers;

  /// No description provided for @allRoles.
  ///
  /// In en, this message translates to:
  /// **'All Roles'**
  String get allRoles;

  /// No description provided for @allStatuses.
  ///
  /// In en, this message translates to:
  /// **'All Statuses'**
  String get allStatuses;

  /// No description provided for @restaurantManagement.
  ///
  /// In en, this message translates to:
  /// **'Restaurant Management'**
  String get restaurantManagement;

  /// No description provided for @vendorManagement.
  ///
  /// In en, this message translates to:
  /// **'Vendor Management'**
  String get vendorManagement;

  /// No description provided for @addVendor.
  ///
  /// In en, this message translates to:
  /// **'Add Vendor'**
  String get addVendor;

  /// No description provided for @noVendorsFound.
  ///
  /// In en, this message translates to:
  /// **'No vendors found'**
  String get noVendorsFound;

  /// No description provided for @changeVendorType.
  ///
  /// In en, this message translates to:
  /// **'Change Vendor Type'**
  String get changeVendorType;

  /// No description provided for @allFilter.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allFilter;

  /// No description provided for @systemSettings.
  ///
  /// In en, this message translates to:
  /// **'System Settings'**
  String get systemSettings;

  /// No description provided for @localizationSection.
  ///
  /// In en, this message translates to:
  /// **'Localization'**
  String get localizationSection;

  /// No description provided for @platformConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Platform Configuration'**
  String get platformConfiguration;

  /// No description provided for @platformCommission.
  ///
  /// In en, this message translates to:
  /// **'Platform Commission'**
  String get platformCommission;

  /// No description provided for @maintenanceMode.
  ///
  /// In en, this message translates to:
  /// **'Maintenance Mode'**
  String get maintenanceMode;

  /// No description provided for @platformIsOffline.
  ///
  /// In en, this message translates to:
  /// **'Platform is offline'**
  String get platformIsOffline;

  /// No description provided for @platformIsLive.
  ///
  /// In en, this message translates to:
  /// **'Platform is live'**
  String get platformIsLive;

  /// No description provided for @deleteSection.
  ///
  /// In en, this message translates to:
  /// **'Delete Section'**
  String get deleteSection;

  /// No description provided for @deleteSectionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"? This cannot be undone.'**
  String deleteSectionConfirm(String name);

  /// No description provided for @editSection.
  ///
  /// In en, this message translates to:
  /// **'Edit Section'**
  String get editSection;

  /// No description provided for @statusColumnHeader.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusColumnHeader;

  /// No description provided for @roleColumnHeader.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get roleColumnHeader;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @qtyLabel.
  ///
  /// In en, this message translates to:
  /// **'Qty: {qty}'**
  String qtyLabel(String qty);

  /// No description provided for @popular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get popular;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @customizeYourItem.
  ///
  /// In en, this message translates to:
  /// **'Customize Your Item'**
  String get customizeYourItem;

  /// No description provided for @specialInstructions.
  ///
  /// In en, this message translates to:
  /// **'Special Instructions'**
  String get specialInstructions;

  /// No description provided for @specialInstructionsHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., No onions, extra spicy...'**
  String get specialInstructionsHint;

  /// No description provided for @addToCartButton.
  ///
  /// In en, this message translates to:
  /// **'Add to Cart'**
  String get addToCartButton;

  /// No description provided for @itemsInSection.
  ///
  /// In en, this message translates to:
  /// **'{count} item'**
  String itemsInSection(int count);

  /// No description provided for @itemsInSectionPlural.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String itemsInSectionPlural(int count);

  /// No description provided for @addedToCartItem.
  ///
  /// In en, this message translates to:
  /// **'{name} added to cart'**
  String addedToCartItem(String name);

  /// No description provided for @viewCart.
  ///
  /// In en, this message translates to:
  /// **'VIEW CART'**
  String get viewCart;

  /// No description provided for @replaceCartContent.
  ///
  /// In en, this message translates to:
  /// **'Your cart contains items from another restaurant. Would you like to clear the cart and add this item instead?'**
  String get replaceCartContent;

  /// No description provided for @vendorCurrentlyClosed.
  ///
  /// In en, this message translates to:
  /// **'This {vendorType} is currently closed. You can browse the menu but ordering is unavailable.'**
  String vendorCurrentlyClosed(String vendorType);

  /// No description provided for @ownerChip.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get ownerChip;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get free;

  /// No description provided for @addonPricePrefix.
  ///
  /// In en, this message translates to:
  /// **'+EGP {price}'**
  String addonPricePrefix(String price);

  /// No description provided for @choose1Option.
  ///
  /// In en, this message translates to:
  /// **'Choose 1 option'**
  String get choose1Option;

  /// No description provided for @chooseUpTo1Option.
  ///
  /// In en, this message translates to:
  /// **'Choose up to 1 option (optional)'**
  String get chooseUpTo1Option;

  /// No description provided for @chooseMinToMax.
  ///
  /// In en, this message translates to:
  /// **'Choose {min} to {max} options'**
  String chooseMinToMax(int min, int max);

  /// No description provided for @chooseAtLeast.
  ///
  /// In en, this message translates to:
  /// **'Choose at least {min} option'**
  String chooseAtLeast(int min);

  /// No description provided for @chooseAtLeastPlural.
  ///
  /// In en, this message translates to:
  /// **'Choose at least {min} options'**
  String chooseAtLeastPlural(int min);

  /// No description provided for @chooseUpToMax.
  ///
  /// In en, this message translates to:
  /// **'Choose up to {max} options (optional)'**
  String chooseUpToMax(int max);

  /// No description provided for @chooseAnyOptions.
  ///
  /// In en, this message translates to:
  /// **'Choose any number of options (optional)'**
  String get chooseAnyOptions;

  /// No description provided for @topRestaurantsNearYou.
  ///
  /// In en, this message translates to:
  /// **'Top Restaurants Near You'**
  String get topRestaurantsNearYou;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @viewMenu.
  ///
  /// In en, this message translates to:
  /// **'View Menu'**
  String get viewMenu;

  /// No description provided for @openStatus.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openStatus;

  /// No description provided for @closedStatus.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closedStatus;

  /// No description provided for @deliverySublabel.
  ///
  /// In en, this message translates to:
  /// **'delivery'**
  String get deliverySublabel;

  /// No description provided for @minOrderSublabel.
  ///
  /// In en, this message translates to:
  /// **'min order'**
  String get minOrderSublabel;

  /// No description provided for @searchSupermarkets.
  ///
  /// In en, this message translates to:
  /// **'Search supermarkets or products...'**
  String get searchSupermarkets;

  /// No description provided for @searchPharmacies.
  ///
  /// In en, this message translates to:
  /// **'Search pharmacies or medicines...'**
  String get searchPharmacies;

  /// No description provided for @errorLoadingSupermarkets.
  ///
  /// In en, this message translates to:
  /// **'Error loading supermarkets'**
  String get errorLoadingSupermarkets;

  /// No description provided for @errorLoadingPharmacies.
  ///
  /// In en, this message translates to:
  /// **'Error loading pharmacies'**
  String get errorLoadingPharmacies;

  /// No description provided for @errorLoadingRestaurants.
  ///
  /// In en, this message translates to:
  /// **'Error loading restaurants'**
  String get errorLoadingRestaurants;

  /// No description provided for @addressRemoved.
  ///
  /// In en, this message translates to:
  /// **'{label} removed'**
  String addressRemoved(String label);

  /// No description provided for @addressAdded.
  ///
  /// In en, this message translates to:
  /// **'{label} added!'**
  String addressAdded(String label);

  /// No description provided for @addressLabel.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get addressLabel;

  /// No description provided for @buildingOptional.
  ///
  /// In en, this message translates to:
  /// **'Building / Villa (Optional)'**
  String get buildingOptional;

  /// No description provided for @floorAptOptional.
  ///
  /// In en, this message translates to:
  /// **'Floor / Apt (Optional)'**
  String get floorAptOptional;

  /// No description provided for @owner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get owner;

  /// No description provided for @sectionItemCount.
  ///
  /// In en, this message translates to:
  /// **'{count} item'**
  String sectionItemCount(int count);

  /// No description provided for @sectionItemCountPlural.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String sectionItemCountPlural(int count);

  /// No description provided for @addItemWithPrice.
  ///
  /// In en, this message translates to:
  /// **'Add item  EGP {price}'**
  String addItemWithPrice(String price);

  /// No description provided for @vendorClosedLabel.
  ///
  /// In en, this message translates to:
  /// **'{vendorType} Closed'**
  String vendorClosedLabel(String vendorType);

  /// No description provided for @orderSummary.
  ///
  /// In en, this message translates to:
  /// **'Order Summary'**
  String get orderSummary;

  /// No description provided for @needHelpWithOrder.
  ///
  /// In en, this message translates to:
  /// **'Need help with your order?'**
  String get needHelpWithOrder;

  /// No description provided for @qtyWithMeasure.
  ///
  /// In en, this message translates to:
  /// **'Qty: {qty} {measure}'**
  String qtyWithMeasure(String qty, String measure);

  /// No description provided for @estimatedTime.
  ///
  /// In en, this message translates to:
  /// **'Estimated Time'**
  String get estimatedTime;

  /// No description provided for @calculating.
  ///
  /// In en, this message translates to:
  /// **'Calculating...'**
  String get calculating;

  /// No description provided for @liveTracking.
  ///
  /// In en, this message translates to:
  /// **'Live Tracking'**
  String get liveTracking;

  /// No description provided for @ordered.
  ///
  /// In en, this message translates to:
  /// **'Ordered'**
  String get ordered;

  /// No description provided for @percentComplete.
  ///
  /// In en, this message translates to:
  /// **'{percent}% Complete'**
  String percentComplete(int percent);

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @categoriesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} categories'**
  String categoriesCount(int count);

  /// No description provided for @quickDelivery.
  ///
  /// In en, this message translates to:
  /// **'Quick Delivery'**
  String get quickDelivery;

  /// No description provided for @grocery.
  ///
  /// In en, this message translates to:
  /// **'Grocery'**
  String get grocery;

  /// No description provided for @drinks.
  ///
  /// In en, this message translates to:
  /// **'Drinks'**
  String get drinks;

  /// No description provided for @flowers.
  ///
  /// In en, this message translates to:
  /// **'Flowers'**
  String get flowers;

  /// No description provided for @petSupplies.
  ///
  /// In en, this message translates to:
  /// **'Pet Supplies'**
  String get petSupplies;

  /// No description provided for @freshOrganic.
  ///
  /// In en, this message translates to:
  /// **'Fresh & Organic'**
  String get freshOrganic;

  /// No description provided for @bakery.
  ///
  /// In en, this message translates to:
  /// **'Bakery'**
  String get bakery;

  /// No description provided for @expired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expired;

  /// No description provided for @week.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get week;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get month;

  /// No description provided for @items.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get items;

  /// No description provided for @tripsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} trips'**
  String tripsCount(int count);

  /// No description provided for @tripDateAt.
  ///
  /// In en, this message translates to:
  /// **'{date} at {time}'**
  String tripDateAt(String date, String time);

  /// No description provided for @egpEarnings.
  ///
  /// In en, this message translates to:
  /// **'+EGP {amount}'**
  String egpEarnings(String amount);

  /// No description provided for @toRestaurant.
  ///
  /// In en, this message translates to:
  /// **'To Restaurant'**
  String get toRestaurant;

  /// No description provided for @toCustomer.
  ///
  /// In en, this message translates to:
  /// **'To Customer'**
  String get toCustomer;

  /// No description provided for @itemsCount2.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String itemsCount2(int count);

  /// No description provided for @itemsAssigned.
  ///
  /// In en, this message translates to:
  /// **'{count} items assigned'**
  String itemsAssigned(int count);

  /// No description provided for @remainingToAccept.
  ///
  /// In en, this message translates to:
  /// **'remaining to accept'**
  String get remainingToAccept;

  /// No description provided for @noPendingRequests.
  ///
  /// In en, this message translates to:
  /// **'No pending requests'**
  String get noPendingRequests;

  /// No description provided for @newDeliveryRequestsWillAppear.
  ///
  /// In en, this message translates to:
  /// **'New delivery requests will appear here'**
  String get newDeliveryRequestsWillAppear;

  /// No description provided for @noActiveDeliveries.
  ///
  /// In en, this message translates to:
  /// **'No active deliveries'**
  String get noActiveDeliveries;

  /// No description provided for @acceptedOrdersWillAppear.
  ///
  /// In en, this message translates to:
  /// **'Accepted orders will appear here'**
  String get acceptedOrdersWillAppear;

  /// No description provided for @updateLocationFirst.
  ///
  /// In en, this message translates to:
  /// **'Update your location first before going online'**
  String get updateLocationFirst;

  /// No description provided for @headingToRestaurant.
  ///
  /// In en, this message translates to:
  /// **'Heading to Restaurant'**
  String get headingToRestaurant;

  /// No description provided for @headingToCustomer.
  ///
  /// In en, this message translates to:
  /// **'Heading to Customer'**
  String get headingToCustomer;

  /// No description provided for @rejectReason.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional)'**
  String get rejectReason;

  /// No description provided for @rejectReasonHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Too far, Busy with other delivery'**
  String get rejectReasonHint;

  /// No description provided for @areYouSureRejectRequest.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to reject this delivery request?'**
  String get areYouSureRejectRequest;

  /// No description provided for @newLabel.
  ///
  /// In en, this message translates to:
  /// **'NEW'**
  String get newLabel;

  /// No description provided for @orderIdShort.
  ///
  /// In en, this message translates to:
  /// **'Order #{id}'**
  String orderIdShort(String id);

  /// No description provided for @callDriver.
  ///
  /// In en, this message translates to:
  /// **'Call Driver'**
  String get callDriver;

  /// No description provided for @callingDriver2.
  ///
  /// In en, this message translates to:
  /// **'Calling driver:'**
  String get callingDriver2;

  /// No description provided for @callLabel.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get callLabel;

  /// No description provided for @messageDriver.
  ///
  /// In en, this message translates to:
  /// **'Message Driver'**
  String get messageDriver;

  /// No description provided for @sendMessageToDriver.
  ///
  /// In en, this message translates to:
  /// **'Send a message to your driver:'**
  String get sendMessageToDriver;

  /// No description provided for @typeMessageHere.
  ///
  /// In en, this message translates to:
  /// **'Type your message here...'**
  String get typeMessageHere;

  /// No description provided for @driverLocation.
  ///
  /// In en, this message translates to:
  /// **'Driver Location'**
  String get driverLocation;

  /// No description provided for @openingDriverLocation.
  ///
  /// In en, this message translates to:
  /// **'Opening driver\'s location on map...'**
  String get openingDriverLocation;

  /// No description provided for @completeRide.
  ///
  /// In en, this message translates to:
  /// **'Complete Ride'**
  String get completeRide;

  /// No description provided for @hasRideBeenCompleted.
  ///
  /// In en, this message translates to:
  /// **'Has the ride been completed successfully?'**
  String get hasRideBeenCompleted;

  /// No description provided for @noButton.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get noButton;

  /// No description provided for @yesComplete.
  ///
  /// In en, this message translates to:
  /// **'Yes, Complete'**
  String get yesComplete;

  /// No description provided for @cancelRide.
  ///
  /// In en, this message translates to:
  /// **'Cancel Ride'**
  String get cancelRide;

  /// No description provided for @areYouSureCancelRide.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this ride?'**
  String get areYouSureCancelRide;

  /// No description provided for @cannotBeUndone.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get cannotBeUndone;

  /// No description provided for @yesCancel.
  ///
  /// In en, this message translates to:
  /// **'Yes, Cancel'**
  String get yesCancel;

  /// No description provided for @pickupLocation.
  ///
  /// In en, this message translates to:
  /// **'Pickup location'**
  String get pickupLocation;

  /// No description provided for @dropoffLocation.
  ///
  /// In en, this message translates to:
  /// **'Dropoff location'**
  String get dropoffLocation;

  /// No description provided for @whereToQuestion.
  ///
  /// In en, this message translates to:
  /// **'Where to?'**
  String get whereToQuestion;

  /// No description provided for @availableRides.
  ///
  /// In en, this message translates to:
  /// **'Available Rides'**
  String get availableRides;

  /// No description provided for @popularLocations.
  ///
  /// In en, this message translates to:
  /// **'Popular Locations'**
  String get popularLocations;

  /// No description provided for @onlineStatus.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get onlineStatus;

  /// No description provided for @typeYourMessage.
  ///
  /// In en, this message translates to:
  /// **'Type your message...'**
  String get typeYourMessage;

  /// No description provided for @pleaseEnterDropoff.
  ///
  /// In en, this message translates to:
  /// **'Please enter a dropoff location'**
  String get pleaseEnterDropoff;

  /// No description provided for @confirmBooking.
  ///
  /// In en, this message translates to:
  /// **'Confirm Booking'**
  String get confirmBooking;

  /// No description provided for @bookRideConfirm.
  ///
  /// In en, this message translates to:
  /// **'Book {rideType} with {driver} for {price} EGP?'**
  String bookRideConfirm(String rideType, String driver, String price);

  /// No description provided for @rideBookedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Ride booked successfully! Driver is on the way.'**
  String get rideBookedSuccess;

  /// No description provided for @rideCompletedThankYou.
  ///
  /// In en, this message translates to:
  /// **'Ride completed! Thank you for choosing Speed Rides.'**
  String get rideCompletedThankYou;

  /// No description provided for @rideCancelledSuccess.
  ///
  /// In en, this message translates to:
  /// **'Ride cancelled successfully.'**
  String get rideCancelledSuccess;

  /// No description provided for @messageSent.
  ///
  /// In en, this message translates to:
  /// **'Message sent'**
  String get messageSent;

  /// No description provided for @assignDrivers.
  ///
  /// In en, this message translates to:
  /// **'Assign Drivers'**
  String get assignDrivers;

  /// No description provided for @outOfRange.
  ///
  /// In en, this message translates to:
  /// **'Out of range'**
  String get outOfRange;

  /// No description provided for @kmFromRestaurant.
  ///
  /// In en, this message translates to:
  /// **'{distance} km from restaurant'**
  String kmFromRestaurant(String distance);

  /// No description provided for @multipleItems.
  ///
  /// In en, this message translates to:
  /// **'Multiple items'**
  String get multipleItems;

  /// No description provided for @perDriver.
  ///
  /// In en, this message translates to:
  /// **'Per Driver'**
  String get perDriver;

  /// No description provided for @totalDriversCount.
  ///
  /// In en, this message translates to:
  /// **'Total ({count} drivers)'**
  String totalDriversCount(int count);

  /// No description provided for @assignedDriversSection.
  ///
  /// In en, this message translates to:
  /// **'Assigned Drivers'**
  String get assignedDriversSection;

  /// No description provided for @noDriversAssigned.
  ///
  /// In en, this message translates to:
  /// **'No drivers assigned yet'**
  String get noDriversAssigned;

  /// No description provided for @availableDriversSection.
  ///
  /// In en, this message translates to:
  /// **'Available Drivers'**
  String get availableDriversSection;

  /// No description provided for @sortedByDistance.
  ///
  /// In en, this message translates to:
  /// **'Sorted by distance, rating, and acceptance rate'**
  String get sortedByDistance;

  /// No description provided for @noAvailableDrivers.
  ///
  /// In en, this message translates to:
  /// **'No available drivers online'**
  String get noAvailableDrivers;

  /// No description provided for @alreadyAssigned.
  ///
  /// In en, this message translates to:
  /// **'Already Assigned'**
  String get alreadyAssigned;

  /// No description provided for @assignDriverQuestion.
  ///
  /// In en, this message translates to:
  /// **'Assign this driver to the order?'**
  String get assignDriverQuestion;

  /// No description provided for @assignDriverNote.
  ///
  /// In en, this message translates to:
  /// **'Note: The driver will be assigned to deliver all items in this order.'**
  String get assignDriverNote;

  /// No description provided for @removeDriverConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove {name} from this order?'**
  String removeDriverConfirm(String name);

  /// No description provided for @noActiveRide.
  ///
  /// In en, this message translates to:
  /// **'No Active Ride'**
  String get noActiveRide;

  /// No description provided for @bookRideToGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Book a ride to get started'**
  String get bookRideToGetStarted;

  /// No description provided for @bookARide.
  ///
  /// In en, this message translates to:
  /// **'Book a Ride'**
  String get bookARide;

  /// No description provided for @pickupLabel.
  ///
  /// In en, this message translates to:
  /// **'PICKUP'**
  String get pickupLabel;

  /// No description provided for @dropoffLabel.
  ///
  /// In en, this message translates to:
  /// **'DROPOFF'**
  String get dropoffLabel;

  /// No description provided for @liveMapPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Live map would display here'**
  String get liveMapPlaceholder;

  /// No description provided for @rideHistory.
  ///
  /// In en, this message translates to:
  /// **'Ride History'**
  String get rideHistory;

  /// No description provided for @noRideHistory.
  ///
  /// In en, this message translates to:
  /// **'No Ride History'**
  String get noRideHistory;

  /// No description provided for @rideDetails.
  ///
  /// In en, this message translates to:
  /// **'Ride Details'**
  String get rideDetails;

  /// No description provided for @rideType.
  ///
  /// In en, this message translates to:
  /// **'Ride Type'**
  String get rideType;

  /// No description provided for @etaMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes'**
  String etaMinutes(String minutes);

  /// No description provided for @distanceKm.
  ///
  /// In en, this message translates to:
  /// **'{distance} km'**
  String distanceKm(String distance);

  /// No description provided for @priceEgp.
  ///
  /// In en, this message translates to:
  /// **'{price} EGP'**
  String priceEgp(String price);

  /// No description provided for @calling.
  ///
  /// In en, this message translates to:
  /// **'Calling...'**
  String get calling;

  /// No description provided for @driverLabel.
  ///
  /// In en, this message translates to:
  /// **'Driver: {name}'**
  String driverLabel(String name);

  /// No description provided for @etaLabel.
  ///
  /// In en, this message translates to:
  /// **'ETA'**
  String get etaLabel;

  /// No description provided for @distanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distanceLabel;

  /// No description provided for @priceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get priceLabel;

  /// No description provided for @goingToRestaurant.
  ///
  /// In en, this message translates to:
  /// **'Going to Restaurant'**
  String get goingToRestaurant;

  /// No description provided for @arrivedAtRestaurant.
  ///
  /// In en, this message translates to:
  /// **'Arrived at Restaurant'**
  String get arrivedAtRestaurant;

  /// No description provided for @pickingUpOrder.
  ///
  /// In en, this message translates to:
  /// **'Picking Up Order'**
  String get pickingUpOrder;

  /// No description provided for @orderPickedUp.
  ///
  /// In en, this message translates to:
  /// **'Order Picked Up'**
  String get orderPickedUp;

  /// No description provided for @deliveringToCustomer.
  ///
  /// In en, this message translates to:
  /// **'Delivering to Customer'**
  String get deliveringToCustomer;

  /// No description provided for @startNewTrip.
  ///
  /// In en, this message translates to:
  /// **'Start New Trip'**
  String get startNewTrip;

  /// No description provided for @unknownStatus.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknownStatus;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @activeTrip.
  ///
  /// In en, this message translates to:
  /// **'Active Trip'**
  String get activeTrip;

  /// No description provided for @tripProgress.
  ///
  /// In en, this message translates to:
  /// **'Trip Progress'**
  String get tripProgress;

  /// No description provided for @etaAndDistance.
  ///
  /// In en, this message translates to:
  /// **'ETA: {minutes} min • {distance} km'**
  String etaAndDistance(int minutes, String distance);

  /// No description provided for @fareLabel.
  ///
  /// In en, this message translates to:
  /// **'Fare'**
  String get fareLabel;

  /// No description provided for @pickupTitle.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get pickupTitle;

  /// No description provided for @deliveryTitle.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get deliveryTitle;

  /// No description provided for @viewTripDetails.
  ///
  /// In en, this message translates to:
  /// **'View Trip Details'**
  String get viewTripDetails;

  /// No description provided for @acceptOrderToStartDriving.
  ///
  /// In en, this message translates to:
  /// **'Accept an order from the available orders list to start driving'**
  String get acceptOrderToStartDriving;

  /// No description provided for @acceptanceRate.
  ///
  /// In en, this message translates to:
  /// **'Acceptance Rate'**
  String get acceptanceRate;

  /// No description provided for @onTimeDeliveries.
  ///
  /// In en, this message translates to:
  /// **'On-time Deliveries'**
  String get onTimeDeliveries;

  /// No description provided for @cancellationsLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancellations'**
  String get cancellationsLabel;

  /// No description provided for @avgRating.
  ///
  /// In en, this message translates to:
  /// **'Avg Rating'**
  String get avgRating;

  /// No description provided for @orderIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Order ID'**
  String get orderIdLabel;

  /// No description provided for @estimatedTimeMin.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String estimatedTimeMin(int minutes);

  /// No description provided for @uploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed'**
  String get uploadFailed;

  /// No description provided for @personalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInformation;

  /// No description provided for @vehicleInformation.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Information'**
  String get vehicleInformation;

  /// No description provided for @vehicleColor.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get vehicleColor;

  /// No description provided for @plateNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Plate Number'**
  String get plateNumberLabel;

  /// No description provided for @typeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get typeLabel;

  /// No description provided for @reviewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Please review all information carefully before submitting. You can tap \"Edit\" to go back and make changes.'**
  String get reviewSubtitle;

  /// No description provided for @applicationDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'By submitting this application, you confirm that all information provided is accurate. Your application will be reviewed within 1-3 business days.'**
  String get applicationDisclaimer;

  /// No description provided for @basicInfo.
  ///
  /// In en, this message translates to:
  /// **'Basic Info'**
  String get basicInfo;

  /// No description provided for @vehicleStep.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get vehicleStep;

  /// No description provided for @wallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get wallet;

  /// No description provided for @currentLocation.
  ///
  /// In en, this message translates to:
  /// **'Current Location'**
  String get currentLocation;

  /// No description provided for @updating.
  ///
  /// In en, this message translates to:
  /// **'Updating...'**
  String get updating;

  /// No description provided for @noDeliveryHistory.
  ///
  /// In en, this message translates to:
  /// **'No Delivery History'**
  String get noDeliveryHistory;

  /// No description provided for @completedDeliveriesWillAppear.
  ///
  /// In en, this message translates to:
  /// **'Your completed deliveries will appear here'**
  String get completedDeliveriesWillAppear;

  /// No description provided for @addressNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Address not available'**
  String get addressNotAvailable;

  /// No description provided for @noAddressProvided.
  ///
  /// In en, this message translates to:
  /// **'No address provided'**
  String get noAddressProvided;

  /// No description provided for @orderReceivedByCustomer.
  ///
  /// In en, this message translates to:
  /// **'Order Received by Customer'**
  String get orderReceivedByCustomer;

  /// No description provided for @startNavigation.
  ///
  /// In en, this message translates to:
  /// **'Start Navigation'**
  String get startNavigation;

  /// No description provided for @zoomIn.
  ///
  /// In en, this message translates to:
  /// **'Zoom In'**
  String get zoomIn;

  /// No description provided for @zoomOut.
  ///
  /// In en, this message translates to:
  /// **'Zoom Out'**
  String get zoomOut;

  /// No description provided for @inAppNavigationMode.
  ///
  /// In en, this message translates to:
  /// **'In-App Navigation Mode'**
  String get inAppNavigationMode;

  /// No description provided for @externalGoogleMaps.
  ///
  /// In en, this message translates to:
  /// **'External Google Maps'**
  String get externalGoogleMaps;

  /// No description provided for @keepZSpeedAppOpen.
  ///
  /// In en, this message translates to:
  /// **'Keep Z-SPEED app open with live turn-by-turn guidance'**
  String get keepZSpeedAppOpen;

  /// No description provided for @openTurnByTurnRoute.
  ///
  /// In en, this message translates to:
  /// **'Open turn-by-turn route in Google Maps app'**
  String get openTurnByTurnRoute;

  /// No description provided for @waitingForGpsCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Waiting for GPS coordinates...'**
  String get waitingForGpsCoordinates;

  /// No description provided for @reCenter.
  ///
  /// In en, this message translates to:
  /// **'Re-center'**
  String get reCenter;

  /// No description provided for @driverSpecialty.
  ///
  /// In en, this message translates to:
  /// **'Driver Specialty'**
  String get driverSpecialty;

  /// No description provided for @delivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get delivery;

  /// No description provided for @foodAndPackages.
  ///
  /// In en, this message translates to:
  /// **'Food & Packages'**
  String get foodAndPackages;

  /// No description provided for @passengersRides.
  ///
  /// In en, this message translates to:
  /// **'Passengers / Rides'**
  String get passengersRides;

  /// No description provided for @couldNotCall.
  ///
  /// In en, this message translates to:
  /// **'Could not call {phone}: {error}'**
  String couldNotCall(String phone, String error);

  /// No description provided for @customerPhoneNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Customer phone number is not available.'**
  String get customerPhoneNotAvailable;

  /// No description provided for @coordinatesNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Coordinates are not available.'**
  String get coordinatesNotAvailable;

  /// No description provided for @couldNotOpenMap.
  ///
  /// In en, this message translates to:
  /// **'Could not open map: {error}'**
  String couldNotOpenMap(String error);

  /// No description provided for @exit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exit;

  /// No description provided for @driveTowardYourDestination.
  ///
  /// In en, this message translates to:
  /// **'Drive toward your destination'**
  String get driveTowardYourDestination;

  /// No description provided for @minLabel.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get minLabel;

  /// No description provided for @hrLabel.
  ///
  /// In en, this message translates to:
  /// **'hr'**
  String get hrLabel;

  /// No description provided for @navigationEtaLabel.
  ///
  /// In en, this message translates to:
  /// **'ETA: {eta}'**
  String navigationEtaLabel(String eta);

  /// No description provided for @inDistance.
  ///
  /// In en, this message translates to:
  /// **'In {distance}'**
  String inDistance(String distance);

  /// No description provided for @performanceSummary.
  ///
  /// In en, this message translates to:
  /// **'Performance Summary'**
  String get performanceSummary;

  /// No description provided for @earningsAndPayout.
  ///
  /// In en, this message translates to:
  /// **'Earnings & Payout'**
  String get earningsAndPayout;

  /// No description provided for @totalDeliveries.
  ///
  /// In en, this message translates to:
  /// **'Total Deliveries'**
  String get totalDeliveries;

  /// No description provided for @walletBalance.
  ///
  /// In en, this message translates to:
  /// **'Wallet Balance'**
  String get walletBalance;

  /// No description provided for @totalEarnings.
  ///
  /// In en, this message translates to:
  /// **'Total Earnings'**
  String get totalEarnings;

  /// No description provided for @completedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} completed'**
  String completedCount(int count);

  /// No description provided for @reviewsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} reviews'**
  String reviewsCount(int count);

  /// No description provided for @noApplicationData.
  ///
  /// In en, this message translates to:
  /// **'No application data found.'**
  String get noApplicationData;

  /// No description provided for @documentNumber.
  ///
  /// In en, this message translates to:
  /// **'Document {number}'**
  String documentNumber(int number);

  /// No description provided for @chatWithDriver.
  ///
  /// In en, this message translates to:
  /// **'Chat with Driver'**
  String get chatWithDriver;

  /// No description provided for @callingDriverTitle.
  ///
  /// In en, this message translates to:
  /// **'Calling Driver'**
  String get callingDriverTitle;

  /// No description provided for @speedRides.
  ///
  /// In en, this message translates to:
  /// **'Speed Rides'**
  String get speedRides;

  /// No description provided for @speedRidesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Safe, reliable transportation in New Administrative Capital'**
  String get speedRidesSubtitle;

  /// No description provided for @bookRide.
  ///
  /// In en, this message translates to:
  /// **'Book Ride'**
  String get bookRide;

  /// No description provided for @activeRide.
  ///
  /// In en, this message translates to:
  /// **'Active Ride'**
  String get activeRide;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @stepOfTotal.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {total}: {label}'**
  String stepOfTotal(int step, int total, String label);

  /// No description provided for @driverDeclined.
  ///
  /// In en, this message translates to:
  /// **'Driver declined'**
  String get driverDeclined;

  /// No description provided for @unknownRestaurant.
  ///
  /// In en, this message translates to:
  /// **'Unknown Restaurant'**
  String get unknownRestaurant;

  /// No description provided for @chatWithSupportAgents.
  ///
  /// In en, this message translates to:
  /// **'Chat with our support agents'**
  String get chatWithSupportAgents;

  /// No description provided for @allCategoryNamed.
  ///
  /// In en, this message translates to:
  /// **'All {name}'**
  String allCategoryNamed(Object name);

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get markAllRead;

  /// No description provided for @noNotificationsYet.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotificationsYet;

  /// No description provided for @orderSummarySection.
  ///
  /// In en, this message translates to:
  /// **'📦 Order Summary'**
  String get orderSummarySection;

  /// No description provided for @deliveryAddressSection.
  ///
  /// In en, this message translates to:
  /// **'📍 Delivery Address'**
  String get deliveryAddressSection;

  /// No description provided for @deliveryInstructionsSection.
  ///
  /// In en, this message translates to:
  /// **'📝 Delivery Instructions (Optional)'**
  String get deliveryInstructionsSection;

  /// No description provided for @paymentMethodSection.
  ///
  /// In en, this message translates to:
  /// **'💳 Payment Method'**
  String get paymentMethodSection;

  /// No description provided for @promoCodeSection.
  ///
  /// In en, this message translates to:
  /// **'🏷 Promo Code'**
  String get promoCodeSection;

  /// No description provided for @priceBreakdownSection.
  ///
  /// In en, this message translates to:
  /// **'💰 Price Breakdown'**
  String get priceBreakdownSection;

  /// No description provided for @ringDoorbellHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Ring doorbell, 2nd floor'**
  String get ringDoorbellHint;

  /// No description provided for @mobileWallet.
  ///
  /// In en, this message translates to:
  /// **'Mobile Wallet'**
  String get mobileWallet;

  /// No description provided for @enterPromoCode.
  ///
  /// In en, this message translates to:
  /// **'Enter promo code'**
  String get enterPromoCode;

  /// No description provided for @taxFourteen.
  ///
  /// In en, this message translates to:
  /// **'Tax (14%)'**
  String get taxFourteen;

  /// No description provided for @discountLabel.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discountLabel;

  /// No description provided for @totalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalLabel;

  /// No description provided for @pleaseFixFollowing.
  ///
  /// In en, this message translates to:
  /// **'Please fix the following:'**
  String get pleaseFixFollowing;

  /// No description provided for @placeOrderAmount.
  ///
  /// In en, this message translates to:
  /// **'Place Order — EGP {amount}'**
  String placeOrderAmount(String amount);

  /// No description provided for @failedToPlaceOrder.
  ///
  /// In en, this message translates to:
  /// **'Failed to place order'**
  String get failedToPlaceOrder;

  /// No description provided for @kmAway.
  ///
  /// In en, this message translates to:
  /// **'{distance} km away'**
  String kmAway(String distance);

  /// No description provided for @estimatedMinutes.
  ///
  /// In en, this message translates to:
  /// **'⏱ {min}–{max} min'**
  String estimatedMinutes(int min, int max);

  /// No description provided for @fullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullNameLabel;

  /// No description provided for @enterYourName.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get enterYourName;

  /// No description provided for @enterPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter phone number'**
  String get enterPhoneNumber;

  /// No description provided for @enterYourAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter your address'**
  String get enterYourAddress;

  /// No description provided for @cityLabel.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get cityLabel;

  /// No description provided for @deliveryOptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Delivery Option'**
  String get deliveryOptionLabel;

  /// No description provided for @standardDelivery.
  ///
  /// In en, this message translates to:
  /// **'Standard Delivery'**
  String get standardDelivery;

  /// No description provided for @expressDelivery.
  ///
  /// In en, this message translates to:
  /// **'Express Delivery'**
  String get expressDelivery;

  /// No description provided for @pickupPoint.
  ///
  /// In en, this message translates to:
  /// **'Pickup Point'**
  String get pickupPoint;

  /// No description provided for @failedToLoadOrder.
  ///
  /// In en, this message translates to:
  /// **'Failed to load order'**
  String get failedToLoadOrder;

  /// No description provided for @driverWillBeAssignedSoon.
  ///
  /// In en, this message translates to:
  /// **'We\'ll assign a driver once your order is ready'**
  String get driverWillBeAssignedSoon;

  /// No description provided for @searchingForDriver.
  ///
  /// In en, this message translates to:
  /// **'Searching for a driver…'**
  String get searchingForDriver;

  /// No description provided for @driverFallback.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get driverFallback;

  /// No description provided for @cancelReasonChangedMind.
  ///
  /// In en, this message translates to:
  /// **'Changed my mind'**
  String get cancelReasonChangedMind;

  /// No description provided for @cancelReasonMistake.
  ///
  /// In en, this message translates to:
  /// **'Ordered by mistake'**
  String get cancelReasonMistake;

  /// No description provided for @cancelReasonTooLong.
  ///
  /// In en, this message translates to:
  /// **'Taking too long'**
  String get cancelReasonTooLong;

  /// No description provided for @cancelReasonBetterOption.
  ///
  /// In en, this message translates to:
  /// **'Found a better option'**
  String get cancelReasonBetterOption;

  /// No description provided for @cancelReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get cancelReasonOther;

  /// No description provided for @orderCancelledSuccess.
  ///
  /// In en, this message translates to:
  /// **'Order cancelled successfully'**
  String get orderCancelledSuccess;

  /// No description provided for @failedToCancelOrder.
  ///
  /// In en, this message translates to:
  /// **'Failed to cancel order'**
  String get failedToCancelOrder;

  /// No description provided for @restaurantPreparingOrder.
  ///
  /// In en, this message translates to:
  /// **'Restaurant is preparing your order'**
  String get restaurantPreparingOrder;

  /// No description provided for @lookingForDriver.
  ///
  /// In en, this message translates to:
  /// **'Looking for a driver'**
  String get lookingForDriver;

  /// No description provided for @waitingForOrderCompletion.
  ///
  /// In en, this message translates to:
  /// **'Waiting for order completion'**
  String get waitingForOrderCompletion;

  /// No description provided for @waitingForPickup.
  ///
  /// In en, this message translates to:
  /// **'Waiting for pickup'**
  String get waitingForPickup;

  /// No description provided for @driverBeingDispatched.
  ///
  /// In en, this message translates to:
  /// **'Driver is being dispatched'**
  String get driverBeingDispatched;

  /// No description provided for @contactSupportLabel.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupportLabel;

  /// No description provided for @deliveryService.
  ///
  /// In en, this message translates to:
  /// **'DELIVERY SERVICE'**
  String get deliveryService;

  /// No description provided for @faqHowUpdateMenu.
  ///
  /// In en, this message translates to:
  /// **'How do I update my menu?'**
  String get faqHowUpdateMenu;

  /// No description provided for @faqHowUpdateMenuAnswer.
  ///
  /// In en, this message translates to:
  /// **'Go to Menu section → Tap edit button → Make changes → Save'**
  String get faqHowUpdateMenuAnswer;

  /// No description provided for @faqManageOrders.
  ///
  /// In en, this message translates to:
  /// **'How to manage orders?'**
  String get faqManageOrders;

  /// No description provided for @faqManageOrdersAnswer.
  ///
  /// In en, this message translates to:
  /// **'Orders tab shows all orders. Tap to view details and update status.'**
  String get faqManageOrdersAnswer;

  /// No description provided for @faqChangeHours.
  ///
  /// In en, this message translates to:
  /// **'How to change restaurant hours?'**
  String get faqChangeHours;

  /// No description provided for @faqChangeHoursAnswer.
  ///
  /// In en, this message translates to:
  /// **'Settings → Operating Hours → Edit times for each day'**
  String get faqChangeHoursAnswer;

  /// No description provided for @faqAddStaff.
  ///
  /// In en, this message translates to:
  /// **'How to add new staff members?'**
  String get faqAddStaff;

  /// No description provided for @faqAddStaffAnswer.
  ///
  /// In en, this message translates to:
  /// **'Settings → Staff Management → Add New Staff'**
  String get faqAddStaffAnswer;

  /// No description provided for @faqPaymentIssues.
  ///
  /// In en, this message translates to:
  /// **'Payment processing issues?'**
  String get faqPaymentIssues;

  /// No description provided for @faqPaymentIssuesAnswer.
  ///
  /// In en, this message translates to:
  /// **'Check Payment Settings or contact support for specific issues.'**
  String get faqPaymentIssuesAnswer;

  /// No description provided for @faqPrintReceipts.
  ///
  /// In en, this message translates to:
  /// **'How to print receipts?'**
  String get faqPrintReceipts;

  /// No description provided for @faqPrintReceiptsAnswer.
  ///
  /// In en, this message translates to:
  /// **'Order details → Print Receipt (requires connected printer)'**
  String get faqPrintReceiptsAnswer;

  /// No description provided for @learnHowToUseApp.
  ///
  /// In en, this message translates to:
  /// **'Learn how to use the app'**
  String get learnHowToUseApp;

  /// No description provided for @watchStepByStepGuides.
  ///
  /// In en, this message translates to:
  /// **'Watch step-by-step guides'**
  String get watchStepByStepGuides;

  /// No description provided for @blogAndUpdates.
  ///
  /// In en, this message translates to:
  /// **'Blog & Updates'**
  String get blogAndUpdates;

  /// No description provided for @latestNewsAndUpdates.
  ///
  /// In en, this message translates to:
  /// **'Latest news and updates'**
  String get latestNewsAndUpdates;

  /// No description provided for @subject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get subject;

  /// No description provided for @describeYourIssue.
  ///
  /// In en, this message translates to:
  /// **'Describe your issue'**
  String get describeYourIssue;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get appVersion;

  /// No description provided for @buildNumber.
  ///
  /// In en, this message translates to:
  /// **'Build Number'**
  String get buildNumber;

  /// No description provided for @developerLabel.
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get developerLabel;

  /// No description provided for @placeOrderEgp.
  ///
  /// In en, this message translates to:
  /// **'Place Order — EGP {amount}'**
  String placeOrderEgp(String amount);

  /// No description provided for @paymentDetails.
  ///
  /// In en, this message translates to:
  /// **'Payment Details'**
  String get paymentDetails;

  /// No description provided for @paymentId.
  ///
  /// In en, this message translates to:
  /// **'Payment ID'**
  String get paymentId;

  /// No description provided for @paymentMethodLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethodLabel;

  /// No description provided for @createdAt.
  ///
  /// In en, this message translates to:
  /// **'Created At'**
  String get createdAt;

  /// No description provided for @completedAt.
  ///
  /// In en, this message translates to:
  /// **'Completed At'**
  String get completedAt;

  /// No description provided for @transactionId.
  ///
  /// In en, this message translates to:
  /// **'Transaction ID'**
  String get transactionId;

  /// No description provided for @paymentStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get paymentStatusPending;

  /// No description provided for @paymentStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get paymentStatusCompleted;

  /// No description provided for @paymentStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get paymentStatusFailed;

  /// No description provided for @paymentStatusRefunded.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get paymentStatusRefunded;

  /// No description provided for @paymentMethodCash.
  ///
  /// In en, this message translates to:
  /// **'Cash on Delivery'**
  String get paymentMethodCash;

  /// No description provided for @paymentMethodCard.
  ///
  /// In en, this message translates to:
  /// **'Credit/Debit Card'**
  String get paymentMethodCard;

  /// No description provided for @paymentMethodWallet.
  ///
  /// In en, this message translates to:
  /// **'Mobile Wallet'**
  String get paymentMethodWallet;

  /// No description provided for @paymentMethodsTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment Methods'**
  String get paymentMethodsTitle;

  /// No description provided for @managePaymentMethods.
  ///
  /// In en, this message translates to:
  /// **'Manage your payment methods for receiving payments'**
  String get managePaymentMethods;

  /// No description provided for @noPaymentMethodsSaved.
  ///
  /// In en, this message translates to:
  /// **'No payment methods saved'**
  String get noPaymentMethodsSaved;

  /// No description provided for @addPaymentMethodBelow.
  ///
  /// In en, this message translates to:
  /// **'Add a payment method below to get started'**
  String get addPaymentMethodBelow;

  /// No description provided for @payoutSettings.
  ///
  /// In en, this message translates to:
  /// **'Payout Settings'**
  String get payoutSettings;

  /// No description provided for @payoutFrequencySetTo.
  ///
  /// In en, this message translates to:
  /// **'Payout frequency set to {freq}'**
  String payoutFrequencySetTo(String freq);

  /// No description provided for @minimumPayoutSetTo.
  ///
  /// In en, this message translates to:
  /// **'Minimum payout set to EGP {amount}'**
  String minimumPayoutSetTo(String amount);

  /// No description provided for @editMethodNameTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit {methodName}'**
  String editMethodNameTitle(String methodName);

  /// No description provided for @methodUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'{methodName} updated successfully'**
  String methodUpdatedSuccess(String methodName);

  /// No description provided for @registeredPhone.
  ///
  /// In en, this message translates to:
  /// **'Registered phone number'**
  String get registeredPhone;

  /// No description provided for @phoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get phoneRequired;

  /// No description provided for @enterValidPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number'**
  String get enterValidPhone;

  /// No description provided for @amountEgpLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount (EGP)'**
  String get amountEgpLabel;

  /// No description provided for @privacySettings.
  ///
  /// In en, this message translates to:
  /// **'Privacy Settings'**
  String get privacySettings;

  /// No description provided for @dataCollection.
  ///
  /// In en, this message translates to:
  /// **'Data Collection'**
  String get dataCollection;

  /// No description provided for @controlWhatData.
  ///
  /// In en, this message translates to:
  /// **'Control what data we collect'**
  String get controlWhatData;

  /// No description provided for @dataCollectionEnabled.
  ///
  /// In en, this message translates to:
  /// **'Data collection enabled'**
  String get dataCollectionEnabled;

  /// No description provided for @dataCollectionDisabled.
  ///
  /// In en, this message translates to:
  /// **'Data collection disabled'**
  String get dataCollectionDisabled;

  /// No description provided for @analyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analyticsTitle;

  /// No description provided for @helpUsImprove.
  ///
  /// In en, this message translates to:
  /// **'Help us improve by sharing usage data'**
  String get helpUsImprove;

  /// No description provided for @analyticsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Analytics enabled'**
  String get analyticsEnabled;

  /// No description provided for @analyticsDisabled.
  ///
  /// In en, this message translates to:
  /// **'Analytics disabled'**
  String get analyticsDisabled;

  /// No description provided for @marketingEmails.
  ///
  /// In en, this message translates to:
  /// **'Marketing Emails'**
  String get marketingEmails;

  /// No description provided for @receivePromotionalEmails.
  ///
  /// In en, this message translates to:
  /// **'Receive promotional emails'**
  String get receivePromotionalEmails;

  /// No description provided for @marketingEmailsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Marketing emails enabled'**
  String get marketingEmailsEnabled;

  /// No description provided for @marketingEmailsDisabled.
  ///
  /// In en, this message translates to:
  /// **'Marketing emails disabled'**
  String get marketingEmailsDisabled;

  /// No description provided for @securitySettings.
  ///
  /// In en, this message translates to:
  /// **'Security Settings'**
  String get securitySettings;

  /// No description provided for @biometricEnabled.
  ///
  /// In en, this message translates to:
  /// **'Biometric login enabled'**
  String get biometricEnabled;

  /// No description provided for @biometricDisabled.
  ///
  /// In en, this message translates to:
  /// **'Biometric login disabled'**
  String get biometricDisabled;

  /// No description provided for @dataManagement.
  ///
  /// In en, this message translates to:
  /// **'Data Management'**
  String get dataManagement;

  /// No description provided for @additionalOptions.
  ///
  /// In en, this message translates to:
  /// **'Additional Options'**
  String get additionalOptions;

  /// No description provided for @accountSection.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountSection;

  /// No description provided for @preferencesSection.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferencesSection;

  /// No description provided for @notificationsEnabledMsg.
  ///
  /// In en, this message translates to:
  /// **'Notifications enabled'**
  String get notificationsEnabledMsg;

  /// No description provided for @notificationsDisabledMsg.
  ///
  /// In en, this message translates to:
  /// **'Notifications disabled'**
  String get notificationsDisabledMsg;

  /// No description provided for @deliveryAreaLabel.
  ///
  /// In en, this message translates to:
  /// **'Delivery Area'**
  String get deliveryAreaLabel;

  /// No description provided for @selectServiceArea.
  ///
  /// In en, this message translates to:
  /// **'Select your service area'**
  String get selectServiceArea;

  /// No description provided for @aboutSection.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutSection;

  /// No description provided for @aboutSpeedApp.
  ///
  /// In en, this message translates to:
  /// **'About Speed App'**
  String get aboutSpeedApp;

  /// No description provided for @versionInfo.
  ///
  /// In en, this message translates to:
  /// **'Version 1.0.0'**
  String get versionInfo;

  /// No description provided for @supportContact.
  ///
  /// In en, this message translates to:
  /// **'Support / Contact'**
  String get supportContact;

  /// No description provided for @getHelpContact.
  ///
  /// In en, this message translates to:
  /// **'Get help and contact support'**
  String get getHelpContact;

  /// No description provided for @privacyPolicyLabel.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicyLabel;

  /// No description provided for @readPrivacyPolicyLabel.
  ///
  /// In en, this message translates to:
  /// **'Read our privacy policy'**
  String get readPrivacyPolicyLabel;

  /// No description provided for @termsOfServiceLabel.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfServiceLabel;

  /// No description provided for @readTermsConditions.
  ///
  /// In en, this message translates to:
  /// **'Read our terms and conditions'**
  String get readTermsConditions;

  /// No description provided for @logoutButton.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutButton;

  /// No description provided for @speedRidesVersion.
  ///
  /// In en, this message translates to:
  /// **'Speed Rides v1.0.0'**
  String get speedRidesVersion;

  /// No description provided for @languageChangedTo.
  ///
  /// In en, this message translates to:
  /// **'Language changed to {language}'**
  String languageChangedTo(String language);

  /// No description provided for @loadingItems.
  ///
  /// In en, this message translates to:
  /// **'Loading items...'**
  String get loadingItems;

  /// No description provided for @noteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get noteLabel;

  /// No description provided for @savingLabel.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get savingLabel;

  /// No description provided for @applicationStatus.
  ///
  /// In en, this message translates to:
  /// **'Application Status'**
  String get applicationStatus;

  /// No description provided for @statusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get statusApproved;

  /// No description provided for @statusUnderReview.
  ///
  /// In en, this message translates to:
  /// **'Under Review'**
  String get statusUnderReview;

  /// No description provided for @editWarningContent.
  ///
  /// In en, this message translates to:
  /// **'If you edit this section, your account will go back to pending until the admin verifies it again. Are you sure?'**
  String get editWarningContent;

  /// No description provided for @businessInformationSection.
  ///
  /// In en, this message translates to:
  /// **'Business Information'**
  String get businessInformationSection;

  /// No description provided for @locationAndHours.
  ///
  /// In en, this message translates to:
  /// **'Location & Hours'**
  String get locationAndHours;

  /// No description provided for @contactInformation.
  ///
  /// In en, this message translates to:
  /// **'Contact Information'**
  String get contactInformation;

  /// No description provided for @bankInformation.
  ///
  /// In en, this message translates to:
  /// **'Bank Information'**
  String get bankInformation;

  /// No description provided for @personalInformationSection.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInformationSection;

  /// No description provided for @vehicleInformationSection.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Information'**
  String get vehicleInformationSection;

  /// No description provided for @docCommercialRegistration.
  ///
  /// In en, this message translates to:
  /// **'Commercial Registration'**
  String get docCommercialRegistration;

  /// No description provided for @docBusinessLicense.
  ///
  /// In en, this message translates to:
  /// **'Business License'**
  String get docBusinessLicense;

  /// No description provided for @docHealthCertificate.
  ///
  /// In en, this message translates to:
  /// **'Health Certificate'**
  String get docHealthCertificate;

  /// No description provided for @docTaxRegistration.
  ///
  /// In en, this message translates to:
  /// **'Tax Registration'**
  String get docTaxRegistration;

  /// No description provided for @uploadDocument.
  ///
  /// In en, this message translates to:
  /// **'Upload Document'**
  String get uploadDocument;

  /// No description provided for @changeDocument.
  ///
  /// In en, this message translates to:
  /// **'Change Document'**
  String get changeDocument;

  /// No description provided for @saveDocuments.
  ///
  /// In en, this message translates to:
  /// **'Save Documents'**
  String get saveDocuments;

  /// No description provided for @vendorIsOpen.
  ///
  /// In en, this message translates to:
  /// **'{vendorLabel} is Open'**
  String vendorIsOpen(String vendorLabel);

  /// No description provided for @vendorIsClosed.
  ///
  /// In en, this message translates to:
  /// **'{vendorLabel} is Closed'**
  String vendorIsClosed(String vendorLabel);

  /// No description provided for @avgPickTime.
  ///
  /// In en, this message translates to:
  /// **'Avg. Pick Time'**
  String get avgPickTime;

  /// No description provided for @avgFillTime.
  ///
  /// In en, this message translates to:
  /// **'Avg. Fill Time'**
  String get avgFillTime;

  /// No description provided for @statusApprovedLabel.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get statusApprovedLabel;

  /// No description provided for @statusRejectedLabel.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get statusRejectedLabel;

  /// No description provided for @statusPendingLabel.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPendingLabel;

  /// No description provided for @statusUnderReviewLabel.
  ///
  /// In en, this message translates to:
  /// **'Under Review'**
  String get statusUnderReviewLabel;

  /// No description provided for @applicationStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Application Status'**
  String get applicationStatusLabel;

  /// No description provided for @savingChanges.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get savingChanges;

  /// No description provided for @editTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editTooltip;

  /// No description provided for @cancelTooltip.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelTooltip;

  /// No description provided for @pendingReview.
  ///
  /// In en, this message translates to:
  /// **'Pending Review'**
  String get pendingReview;

  /// No description provided for @applicationRejectedDesc.
  ///
  /// In en, this message translates to:
  /// **'Your application has been rejected. You can edit your profile and resubmit.'**
  String get applicationRejectedDesc;

  /// No description provided for @applicationPendingDesc.
  ///
  /// In en, this message translates to:
  /// **'Your application is being reviewed by our team. You will be notified once a decision is made.'**
  String get applicationPendingDesc;

  /// No description provided for @rejectionReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason:'**
  String get rejectionReasonLabel;

  /// No description provided for @editAndResubmit.
  ///
  /// In en, this message translates to:
  /// **'Edit & Resubmit'**
  String get editAndResubmit;

  /// No description provided for @viewApplication.
  ///
  /// In en, this message translates to:
  /// **'View Application'**
  String get viewApplication;

  /// No description provided for @logoutTooltip.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutTooltip;

  /// No description provided for @verifyLabel.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verifyLabel;

  /// No description provided for @verifiedLabel.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verifiedLabel;

  /// No description provided for @emailVerifiedMsg.
  ///
  /// In en, this message translates to:
  /// **'Email verified!'**
  String get emailVerifiedMsg;

  /// No description provided for @phoneVerifiedMsg.
  ///
  /// In en, this message translates to:
  /// **'Phone verified!'**
  String get phoneVerifiedMsg;

  /// No description provided for @pleaseVerifyEmail.
  ///
  /// In en, this message translates to:
  /// **'Please verify your email'**
  String get pleaseVerifyEmail;

  /// No description provided for @pleaseVerifyPhone.
  ///
  /// In en, this message translates to:
  /// **'Please verify your phone number'**
  String get pleaseVerifyPhone;

  /// No description provided for @closedLabel.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closedLabel;

  /// No description provided for @daySchedule.
  ///
  /// In en, this message translates to:
  /// **'{day}: {hours}'**
  String daySchedule(String day, String hours);

  /// No description provided for @dayScheduleClosed.
  ///
  /// In en, this message translates to:
  /// **'{day}: Closed'**
  String dayScheduleClosed(String day);

  /// No description provided for @editApprovedSectionDesc.
  ///
  /// In en, this message translates to:
  /// **'If you edit this section, your account will go back to pending until the admin verifies it again. Are you sure?'**
  String get editApprovedSectionDesc;

  /// No description provided for @failedToUploadDocument.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload document: {error}'**
  String failedToUploadDocument(String error);

  /// No description provided for @failedToLoadDocument.
  ///
  /// In en, this message translates to:
  /// **'Failed to load document'**
  String get failedToLoadDocument;

  /// No description provided for @applicationDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Application Detail'**
  String get applicationDetailTitle;

  /// No description provided for @submittedDate.
  ///
  /// In en, this message translates to:
  /// **'Submitted {date}'**
  String submittedDate(String date);

  /// No description provided for @rejectedReason.
  ///
  /// In en, this message translates to:
  /// **'Rejected: {reason}'**
  String rejectedReason(String reason);

  /// No description provided for @rejectionReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Reason for rejection...'**
  String get rejectionReasonHint;

  /// No description provided for @noHoursProvided.
  ///
  /// In en, this message translates to:
  /// **'No hours provided'**
  String get noHoursProvided;

  /// No description provided for @approvedLabel.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approvedLabel;

  /// No description provided for @rejectedLabel.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejectedLabel;

  /// No description provided for @sectionApprovedMsg.
  ///
  /// In en, this message translates to:
  /// **'{section} approved'**
  String sectionApprovedMsg(String section);

  /// No description provided for @sectionRejectedMsg.
  ///
  /// In en, this message translates to:
  /// **'{section} rejected'**
  String sectionRejectedMsg(String section);

  /// No description provided for @businessLicenseDoc.
  ///
  /// In en, this message translates to:
  /// **'Business License'**
  String get businessLicenseDoc;

  /// No description provided for @taxRegistrationDoc.
  ///
  /// In en, this message translates to:
  /// **'Tax Registration'**
  String get taxRegistrationDoc;

  /// No description provided for @notePrefixed.
  ///
  /// In en, this message translates to:
  /// **'Note: {note}'**
  String notePrefixed(String note);

  /// No description provided for @addonLine.
  ///
  /// In en, this message translates to:
  /// **'+ {name} (EGP {price})'**
  String addonLine(String name, String price);

  /// No description provided for @rateYourOrder.
  ///
  /// In en, this message translates to:
  /// **'Rate your order'**
  String get rateYourOrder;

  /// No description provided for @rateDialogSubtitle.
  ///
  /// In en, this message translates to:
  /// **'How was your experience with {restaurantName}?'**
  String rateDialogSubtitle(String restaurantName);

  /// No description provided for @tapToRate.
  ///
  /// In en, this message translates to:
  /// **'Tap to rate'**
  String get tapToRate;

  /// No description provided for @ratingLabelTerrible.
  ///
  /// In en, this message translates to:
  /// **'Terrible'**
  String get ratingLabelTerrible;

  /// No description provided for @ratingLabelBad.
  ///
  /// In en, this message translates to:
  /// **'Bad'**
  String get ratingLabelBad;

  /// No description provided for @ratingLabelOkay.
  ///
  /// In en, this message translates to:
  /// **'Okay'**
  String get ratingLabelOkay;

  /// No description provided for @ratingLabelGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get ratingLabelGood;

  /// No description provided for @ratingLabelExcellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get ratingLabelExcellent;

  /// No description provided for @shareExperienceHint.
  ///
  /// In en, this message translates to:
  /// **'Share your experience (optional)'**
  String get shareExperienceHint;

  /// No description provided for @pleaseSelectRating.
  ///
  /// In en, this message translates to:
  /// **'Please select a rating.'**
  String get pleaseSelectRating;

  /// No description provided for @failedSubmitReview.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit review. Please try again.'**
  String get failedSubmitReview;

  /// No description provided for @skipRating.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skipRating;

  /// No description provided for @submitRating.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submitRating;

  /// No description provided for @thankYouReview.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your review!'**
  String get thankYouReview;

  /// No description provided for @alreadyRated.
  ///
  /// In en, this message translates to:
  /// **'Rated'**
  String get alreadyRated;

  /// No description provided for @customerReviewsTitle.
  ///
  /// In en, this message translates to:
  /// **'Customer Reviews'**
  String get customerReviewsTitle;

  /// No description provided for @noReviewsYet.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet. Be the first!'**
  String get noReviewsYet;

  /// No description provided for @rateButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get rateButtonLabel;

  /// No description provided for @phoneVerified.
  ///
  /// In en, this message translates to:
  /// **'Phone Verified!'**
  String get phoneVerified;

  /// No description provided for @phoneVerifiedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Your phone number has been verified successfully!'**
  String get phoneVerifiedSuccessfully;

  /// No description provided for @phoneAlreadyRegistered.
  ///
  /// In en, this message translates to:
  /// **'This phone number is already registered. Please login instead.'**
  String get phoneAlreadyRegistered;

  /// No description provided for @sessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please request a new code.'**
  String get sessionExpired;

  /// No description provided for @invalidPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Invalid phone number format.'**
  String get invalidPhoneNumber;

  /// No description provided for @invalidAppCredential.
  ///
  /// In en, this message translates to:
  /// **'Phone verification is unavailable right now. Please try again later or contact support.'**
  String get invalidAppCredential;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @suspended.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get suspended;

  /// No description provided for @banned.
  ///
  /// In en, this message translates to:
  /// **'Banned'**
  String get banned;

  /// No description provided for @profileImage.
  ///
  /// In en, this message translates to:
  /// **'Profile Image'**
  String get profileImage;

  /// No description provided for @filterByType.
  ///
  /// In en, this message translates to:
  /// **'Filter by type'**
  String get filterByType;

  /// No description provided for @refreshTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refreshTooltip;

  /// No description provided for @pendingTab.
  ///
  /// In en, this message translates to:
  /// **'Pending ({count})'**
  String pendingTab(int count);

  /// No description provided for @approvedTab.
  ///
  /// In en, this message translates to:
  /// **'Approved ({count})'**
  String approvedTab(int count);

  /// No description provided for @rejectedTab.
  ///
  /// In en, this message translates to:
  /// **'Rejected ({count})'**
  String rejectedTab(int count);

  /// No description provided for @noPendingApplications.
  ///
  /// In en, this message translates to:
  /// **'No pending applications'**
  String get noPendingApplications;

  /// No description provided for @noApprovedApplications.
  ///
  /// In en, this message translates to:
  /// **'No approved applications'**
  String get noApprovedApplications;

  /// No description provided for @noRejectedApplications.
  ///
  /// In en, this message translates to:
  /// **'No rejected applications'**
  String get noRejectedApplications;

  /// No description provided for @unknownDriver.
  ///
  /// In en, this message translates to:
  /// **'Unknown Driver'**
  String get unknownDriver;

  /// No description provided for @unknownRestaurantLabel.
  ///
  /// In en, this message translates to:
  /// **'Unknown Restaurant'**
  String get unknownRestaurantLabel;

  /// No description provided for @rejectionReasonPrefix.
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}'**
  String rejectionReasonPrefix(String reason);

  /// No description provided for @rejectionReasonBodyHint.
  ///
  /// In en, this message translates to:
  /// **'Please provide a reason for rejection. This will be shown to the applicant.'**
  String get rejectionReasonBodyHint;

  /// No description provided for @rejectionReasonInputHint.
  ///
  /// In en, this message translates to:
  /// **'Reason for rejection...'**
  String get rejectionReasonInputHint;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get searchHint;

  /// No description provided for @adminPanelLabel.
  ///
  /// In en, this message translates to:
  /// **'Admin Panel'**
  String get adminPanelLabel;

  /// No description provided for @driverApplicationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Driver Applications'**
  String get driverApplicationsTitle;

  /// No description provided for @vendorApplicationsTitle.
  ///
  /// In en, this message translates to:
  /// **'{vendorType} Applications'**
  String vendorApplicationsTitle(String vendorType);

  /// No description provided for @searchByNameEmailPhone.
  ///
  /// In en, this message translates to:
  /// **'Search by name, email, phone...'**
  String get searchByNameEmailPhone;

  /// No description provided for @analyticsInsights.
  ///
  /// In en, this message translates to:
  /// **'Analytics & Insights'**
  String get analyticsInsights;

  /// No description provided for @totalUsersLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Users'**
  String get totalUsersLabel;

  /// No description provided for @totalOrdersLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Orders'**
  String get totalOrdersLabel;

  /// No description provided for @totalRevenueLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Revenue'**
  String get totalRevenueLabel;

  /// No description provided for @avgRevenueDay.
  ///
  /// In en, this message translates to:
  /// **'Avg Revenue/Day'**
  String get avgRevenueDay;

  /// No description provided for @userDistribution.
  ///
  /// In en, this message translates to:
  /// **'User Distribution'**
  String get userDistribution;

  /// No description provided for @noUserData.
  ///
  /// In en, this message translates to:
  /// **'No user data available'**
  String get noUserData;

  /// No description provided for @orderStatusBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Order Status Breakdown'**
  String get orderStatusBreakdown;

  /// No description provided for @noOrderData.
  ///
  /// In en, this message translates to:
  /// **'No order data available'**
  String get noOrderData;

  /// No description provided for @dailyRevenueTrend.
  ///
  /// In en, this message translates to:
  /// **'Daily Revenue Trend'**
  String get dailyRevenueTrend;

  /// No description provided for @noRevenueData.
  ///
  /// In en, this message translates to:
  /// **'No revenue data available'**
  String get noRevenueData;

  /// No description provided for @orderManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Order Management'**
  String get orderManagementTitle;

  /// No description provided for @allOrdersLabel.
  ///
  /// In en, this message translates to:
  /// **'All Orders'**
  String get allOrdersLabel;

  /// No description provided for @dateRangeLabel.
  ///
  /// In en, this message translates to:
  /// **'Date Range'**
  String get dateRangeLabel;

  /// No description provided for @reportGenerationTitle.
  ///
  /// In en, this message translates to:
  /// **'Report Generation'**
  String get reportGenerationTitle;

  /// No description provided for @salesReport.
  ///
  /// In en, this message translates to:
  /// **'Sales Report'**
  String get salesReport;

  /// No description provided for @userReport.
  ///
  /// In en, this message translates to:
  /// **'User Report'**
  String get userReport;

  /// No description provided for @restaurantReport.
  ///
  /// In en, this message translates to:
  /// **'Restaurant Report'**
  String get restaurantReport;

  /// No description provided for @orderReport.
  ///
  /// In en, this message translates to:
  /// **'Order Report'**
  String get orderReport;

  /// No description provided for @generateDetailedReport.
  ///
  /// In en, this message translates to:
  /// **'Generate detailed {report}'**
  String generateDetailedReport(String report);

  /// No description provided for @customerNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Customer Name'**
  String get customerNameLabel;

  /// No description provided for @numberOfItemsLabel.
  ///
  /// In en, this message translates to:
  /// **'Number of Items'**
  String get numberOfItemsLabel;

  /// No description provided for @reportTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Report Type'**
  String get reportTypeLabel;

  /// No description provided for @startDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDateLabel;

  /// No description provided for @endDateLabel.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get endDateLabel;

  /// No description provided for @restaurantNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Restaurant Name'**
  String get restaurantNameLabel;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @ratingLabel15.
  ///
  /// In en, this message translates to:
  /// **'Rating (1-5)'**
  String get ratingLabel15;

  /// No description provided for @cuisineTypesSection.
  ///
  /// In en, this message translates to:
  /// **'Cuisine Types'**
  String get cuisineTypesSection;

  /// No description provided for @noCuisineTypesYet.
  ///
  /// In en, this message translates to:
  /// **'No cuisine types yet. Tap \"Add\" to create one.'**
  String get noCuisineTypesYet;

  /// No description provided for @supermarketSectionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Supermarket Sections'**
  String get supermarketSectionsTitle;

  /// No description provided for @pharmacySectionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy Sections'**
  String get pharmacySectionsTitle;

  /// No description provided for @noSectionsYet.
  ///
  /// In en, this message translates to:
  /// **'No sections yet. Tap \"Add\" to create one.'**
  String get noSectionsYet;

  /// No description provided for @addSupermarketSection.
  ///
  /// In en, this message translates to:
  /// **'Add Supermarket Section'**
  String get addSupermarketSection;

  /// No description provided for @addPharmacySection.
  ///
  /// In en, this message translates to:
  /// **'Add Pharmacy Section'**
  String get addPharmacySection;

  /// No description provided for @nameEnglishField.
  ///
  /// In en, this message translates to:
  /// **'Name (English) *'**
  String get nameEnglishField;

  /// No description provided for @nameArabicField.
  ///
  /// In en, this message translates to:
  /// **'Name (Arabic) *'**
  String get nameArabicField;

  /// No description provided for @nameEnglishHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Italian'**
  String get nameEnglishHint;

  /// No description provided for @nameArabicHint.
  ///
  /// In en, this message translates to:
  /// **'مثال: إيطالي'**
  String get nameArabicHint;

  /// No description provided for @tapToUploadImageOptional.
  ///
  /// In en, this message translates to:
  /// **'Tap to upload image (optional)'**
  String get tapToUploadImageOptional;

  /// No description provided for @profileInformationSection.
  ///
  /// In en, this message translates to:
  /// **'Profile Information'**
  String get profileInformationSection;

  /// No description provided for @accountDetailsSection.
  ///
  /// In en, this message translates to:
  /// **'Account Details'**
  String get accountDetailsSection;

  /// No description provided for @linkedApplicationsSection.
  ///
  /// In en, this message translates to:
  /// **'Linked Applications'**
  String get linkedApplicationsSection;

  /// No description provided for @provideRejectionReason.
  ///
  /// In en, this message translates to:
  /// **'Provide a rejection reason that the user will see:'**
  String get provideRejectionReason;

  /// No description provided for @rejectFieldHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Photo is unclear, please re-upload'**
  String get rejectFieldHint;

  /// No description provided for @emailLabel2.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel2;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phoneLabel;

  /// No description provided for @addressLabel2.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get addressLabel2;

  /// No description provided for @accountTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Account Type'**
  String get accountTypeLabel;

  /// No description provided for @joinedLabel.
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get joinedLabel;

  /// No description provided for @lastUpdatedLabel.
  ///
  /// In en, this message translates to:
  /// **'Last Updated'**
  String get lastUpdatedLabel;

  /// No description provided for @appliedLabel.
  ///
  /// In en, this message translates to:
  /// **'Applied'**
  String get appliedLabel;

  /// No description provided for @approvedLabel2.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approvedLabel2;

  /// No description provided for @globalRejectionReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Global Rejection Reason'**
  String get globalRejectionReasonLabel;

  /// No description provided for @driverLabel2.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get driverLabel2;

  /// No description provided for @restaurantLabel2.
  ///
  /// In en, this message translates to:
  /// **'Restaurant'**
  String get restaurantLabel2;

  /// No description provided for @applicationLabel.
  ///
  /// In en, this message translates to:
  /// **'Application'**
  String get applicationLabel;

  /// No description provided for @submittedLabel.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get submittedLabel;

  /// No description provided for @quickActionAddUser.
  ///
  /// In en, this message translates to:
  /// **'Add New User'**
  String get quickActionAddUser;

  /// No description provided for @quickActionGenerateReport.
  ///
  /// In en, this message translates to:
  /// **'Generate Report'**
  String get quickActionGenerateReport;

  /// No description provided for @quickActionManageRestaurants.
  ///
  /// In en, this message translates to:
  /// **'Manage Restaurants'**
  String get quickActionManageRestaurants;

  /// No description provided for @quickActionSystemSettings.
  ///
  /// In en, this message translates to:
  /// **'System Settings'**
  String get quickActionSystemSettings;

  /// No description provided for @deleteOrderConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete order {orderId}?'**
  String deleteOrderConfirm(String orderId);

  /// No description provided for @deleteRestaurantConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {name}?'**
  String deleteRestaurantConfirm(String name);

  /// No description provided for @deleteUserConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {name}?'**
  String deleteUserConfirm(String name);

  /// No description provided for @deleteItemType.
  ///
  /// In en, this message translates to:
  /// **'Delete {itemType}'**
  String deleteItemType(String itemType);

  /// No description provided for @deleteItemConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"? This action cannot be undone.'**
  String deleteItemConfirm(String name);

  /// No description provided for @changeUserStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Change User Status'**
  String get changeUserStatusTitle;

  /// No description provided for @changeUserRoleTitle.
  ///
  /// In en, this message translates to:
  /// **'Change User Role'**
  String get changeUserRoleTitle;

  /// No description provided for @updateOrderStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Update Order Status'**
  String get updateOrderStatusTitle;

  /// No description provided for @updateRestaurantStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Update Restaurant Status'**
  String get updateRestaurantStatusTitle;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusLabel;

  /// No description provided for @roleLabel.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get roleLabel;

  /// No description provided for @comingSoonSuffix.
  ///
  /// In en, this message translates to:
  /// **'— coming soon'**
  String get comingSoonSuffix;

  /// No description provided for @platformFeeDescription.
  ///
  /// In en, this message translates to:
  /// **'Platform fee percentage applied to orders'**
  String get platformFeeDescription;

  /// No description provided for @navDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard Overview'**
  String get navDashboardTitle;

  /// No description provided for @navDashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back! Here\'s what\'s happening with your platform today.'**
  String get navDashboardSubtitle;

  /// No description provided for @navUserManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'User Management'**
  String get navUserManagementTitle;

  /// No description provided for @navUserManagementSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage user accounts, roles, and permissions'**
  String get navUserManagementSubtitle;

  /// No description provided for @navAnalyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Analytics & Reports'**
  String get navAnalyticsTitle;

  /// No description provided for @navAnalyticsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Detailed analytics and insights'**
  String get navAnalyticsSubtitle;

  /// No description provided for @navReviewDriversTitle.
  ///
  /// In en, this message translates to:
  /// **'Review Drivers'**
  String get navReviewDriversTitle;

  /// No description provided for @navReviewDriversSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review and manage driver applications'**
  String get navReviewDriversSubtitle;

  /// No description provided for @navReviewRestaurantsTitle.
  ///
  /// In en, this message translates to:
  /// **'Review Restaurants'**
  String get navReviewRestaurantsTitle;

  /// No description provided for @navReviewRestaurantsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review and manage restaurant applications'**
  String get navReviewRestaurantsSubtitle;

  /// No description provided for @navReviewSupermarketsTitle.
  ///
  /// In en, this message translates to:
  /// **'Review Supermarkets'**
  String get navReviewSupermarketsTitle;

  /// No description provided for @navReviewSupermarketsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review and manage supermarket applications'**
  String get navReviewSupermarketsSubtitle;

  /// No description provided for @navReviewPharmaciesTitle.
  ///
  /// In en, this message translates to:
  /// **'Review Pharmacies'**
  String get navReviewPharmaciesTitle;

  /// No description provided for @navReviewPharmaciesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review and manage pharmacy applications'**
  String get navReviewPharmaciesSubtitle;

  /// No description provided for @navReviewBookstoresTitle.
  ///
  /// In en, this message translates to:
  /// **'Review Bookstores'**
  String get navReviewBookstoresTitle;

  /// No description provided for @navReviewBookstoresSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review and manage bookstore applications'**
  String get navReviewBookstoresSubtitle;

  /// No description provided for @navReviewHomeFurnishingTitle.
  ///
  /// In en, this message translates to:
  /// **'Review Home & Furnishing'**
  String get navReviewHomeFurnishingTitle;

  /// No description provided for @navReviewHomeFurnishingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review and manage home & furnishing applications'**
  String get navReviewHomeFurnishingSubtitle;

  /// No description provided for @navSystemSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'System Settings'**
  String get navSystemSettingsTitle;

  /// No description provided for @navSystemSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Configure platform settings and preferences'**
  String get navSystemSettingsSubtitle;

  /// No description provided for @navAdminManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Admin Management'**
  String get navAdminManagementTitle;

  /// No description provided for @navAdminManagementSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage administrator accounts'**
  String get navAdminManagementSubtitle;

  /// No description provided for @pendingVerification.
  ///
  /// In en, this message translates to:
  /// **'Pending Verification'**
  String get pendingVerification;

  /// No description provided for @userTypeAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get userTypeAdmin;

  /// No description provided for @userTypeSuperAdmin.
  ///
  /// In en, this message translates to:
  /// **'Super Admin'**
  String get userTypeSuperAdmin;

  /// No description provided for @userTypeRestaurant.
  ///
  /// In en, this message translates to:
  /// **'Restaurant'**
  String get userTypeRestaurant;

  /// No description provided for @userTypeCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get userTypeCustomer;

  /// No description provided for @userTypeDriver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get userTypeDriver;

  /// No description provided for @statTotalUsers.
  ///
  /// In en, this message translates to:
  /// **'Total Users'**
  String get statTotalUsers;

  /// No description provided for @statTotalOrders.
  ///
  /// In en, this message translates to:
  /// **'Total Orders'**
  String get statTotalOrders;

  /// No description provided for @statTotalRevenue.
  ///
  /// In en, this message translates to:
  /// **'Total Revenue'**
  String get statTotalRevenue;

  /// No description provided for @statPendingOrders.
  ///
  /// In en, this message translates to:
  /// **'Pending Orders'**
  String get statPendingOrders;

  /// No description provided for @serviceFeeLabel.
  ///
  /// In en, this message translates to:
  /// **'Service Fee ({percent}%)'**
  String serviceFeeLabel(String percent);

  /// No description provided for @serviceFeeSimple.
  ///
  /// In en, this message translates to:
  /// **'Service Fee'**
  String get serviceFeeSimple;

  /// No description provided for @continueAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as Guest'**
  String get continueAsGuest;

  /// No description provided for @signInRequired.
  ///
  /// In en, this message translates to:
  /// **'Sign in required'**
  String get signInRequired;

  /// No description provided for @signInToAction.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to'**
  String get signInToAction;

  /// No description provided for @maybeLater.
  ///
  /// In en, this message translates to:
  /// **'Maybe later'**
  String get maybeLater;

  /// No description provided for @viewProfile.
  ///
  /// In en, this message translates to:
  /// **'View your profile'**
  String get viewProfile;

  /// No description provided for @viewOrders.
  ///
  /// In en, this message translates to:
  /// **'View your orders'**
  String get viewOrders;

  /// No description provided for @paymentStaleCartTitle.
  ///
  /// In en, this message translates to:
  /// **'Cart Updated'**
  String get paymentStaleCartTitle;

  /// No description provided for @paymentStaleCartDescription.
  ///
  /// In en, this message translates to:
  /// **'Some items in your cart have changed. Please review and confirm.'**
  String get paymentStaleCartDescription;

  /// No description provided for @paymentStaleCartUpdateCta.
  ///
  /// In en, this message translates to:
  /// **'Update Cart & Try Again'**
  String get paymentStaleCartUpdateCta;

  /// No description provided for @paymentAttemptCapTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment Blocked'**
  String get paymentAttemptCapTitle;

  /// No description provided for @paymentAttemptCapMessage.
  ///
  /// In en, this message translates to:
  /// **'You have reached the maximum number of payment attempts. Please try again later.'**
  String get paymentAttemptCapMessage;

  /// No description provided for @paymentAttemptCapNewOrderCta.
  ///
  /// In en, this message translates to:
  /// **'Start a New Order'**
  String get paymentAttemptCapNewOrderCta;

  /// No description provided for @paymentBillingIncompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete Your Profile'**
  String get paymentBillingIncompleteTitle;

  /// No description provided for @paymentBillingIncompleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Please complete your billing profile before making a payment.'**
  String get paymentBillingIncompleteMessage;

  /// No description provided for @paymentRoleForbiddenMessage.
  ///
  /// In en, this message translates to:
  /// **'Card payments are only available for customers.'**
  String get paymentRoleForbiddenMessage;

  /// No description provided for @paymentAwaitingConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Confirming payment...'**
  String get paymentAwaitingConfirmation;

  /// No description provided for @paymentSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment Successful'**
  String get paymentSuccessTitle;

  /// No description provided for @paymentSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Your payment has been processed successfully.'**
  String get paymentSuccessMessage;

  /// No description provided for @paymentFailureGenericMessage.
  ///
  /// In en, this message translates to:
  /// **'Payment failed. Please try again.'**
  String get paymentFailureGenericMessage;

  /// No description provided for @payByCard.
  ///
  /// In en, this message translates to:
  /// **'Pay by Card'**
  String get payByCard;

  /// No description provided for @securePayment.
  ///
  /// In en, this message translates to:
  /// **'Secure Payment'**
  String get securePayment;

  /// No description provided for @processingPayment.
  ///
  /// In en, this message translates to:
  /// **'Processing payment...'**
  String get processingPayment;

  /// No description provided for @locationServicesDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location services are disabled.'**
  String get locationServicesDisabled;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permissions are denied.'**
  String get locationPermissionDenied;

  /// No description provided for @locationPermissionPermanentlyDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permissions are permanently denied.'**
  String get locationPermissionPermanentlyDenied;

  /// No description provided for @failedToGetCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Failed to get current location.'**
  String get failedToGetCurrentLocation;

  /// No description provided for @loadingLocation.
  ///
  /// In en, this message translates to:
  /// **'Loading location...'**
  String get loadingLocation;

  /// No description provided for @selectedLocation.
  ///
  /// In en, this message translates to:
  /// **'Selected Location'**
  String get selectedLocation;

  /// No description provided for @statusSearching.
  ///
  /// In en, this message translates to:
  /// **'Searching for Driver'**
  String get statusSearching;

  /// No description provided for @statusUnassigned.
  ///
  /// In en, this message translates to:
  /// **'No Driver Found'**
  String get statusUnassigned;

  /// No description provided for @recommendedProducts.
  ///
  /// In en, this message translates to:
  /// **'Recommended Products'**
  String get recommendedProducts;

  /// No description provided for @gourmetDining.
  ///
  /// In en, this message translates to:
  /// **'Gourmet Dining'**
  String get gourmetDining;

  /// No description provided for @market.
  ///
  /// In en, this message translates to:
  /// **'Market'**
  String get market;

  /// No description provided for @cityTravel.
  ///
  /// In en, this message translates to:
  /// **'City Travel'**
  String get cityTravel;

  /// No description provided for @wellnessCheck.
  ///
  /// In en, this message translates to:
  /// **'Wellness Check'**
  String get wellnessCheck;

  /// No description provided for @curatedReads.
  ///
  /// In en, this message translates to:
  /// **'Curated Reads'**
  String get curatedReads;

  /// No description provided for @cozySpaces.
  ///
  /// In en, this message translates to:
  /// **'Cozy Spaces'**
  String get cozySpaces;

  /// No description provided for @supportEmailSubject.
  ///
  /// In en, this message translates to:
  /// **'{appName} Support (Order #{orderId})'**
  String supportEmailSubject(String appName, String orderId);

  /// No description provided for @supportEmailBody.
  ///
  /// In en, this message translates to:
  /// **'Hello, I need help with order #{orderId}.'**
  String supportEmailBody(String orderId);

  /// No description provided for @addressDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Address Details'**
  String get addressDetailsTitle;

  /// No description provided for @areaLabel.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get areaLabel;

  /// No description provided for @typeApartment.
  ///
  /// In en, this message translates to:
  /// **'Apartment'**
  String get typeApartment;

  /// No description provided for @typeVilla.
  ///
  /// In en, this message translates to:
  /// **'Villa'**
  String get typeVilla;

  /// No description provided for @typeOffice.
  ///
  /// In en, this message translates to:
  /// **'Office'**
  String get typeOffice;

  /// No description provided for @buildingName.
  ///
  /// In en, this message translates to:
  /// **'Building Name'**
  String get buildingName;

  /// No description provided for @villaNameNumber.
  ///
  /// In en, this message translates to:
  /// **'Villa Name / Number'**
  String get villaNameNumber;

  /// No description provided for @buildingCompany.
  ///
  /// In en, this message translates to:
  /// **'Building / Company Name'**
  String get buildingCompany;

  /// No description provided for @apartmentNumber.
  ///
  /// In en, this message translates to:
  /// **'Apartment Number'**
  String get apartmentNumber;

  /// No description provided for @officeNumber.
  ///
  /// In en, this message translates to:
  /// **'Office Number'**
  String get officeNumber;

  /// No description provided for @floorOptional.
  ///
  /// In en, this message translates to:
  /// **'Floor (Optional)'**
  String get floorOptional;

  /// No description provided for @street.
  ///
  /// In en, this message translates to:
  /// **'Street'**
  String get street;

  /// No description provided for @mobilePhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Mobile Phone Number'**
  String get mobilePhoneNumber;

  /// No description provided for @uniqueLandmark.
  ///
  /// In en, this message translates to:
  /// **'Unique Landmark (Optional)'**
  String get uniqueLandmark;

  /// No description provided for @confirmAddressDetails.
  ///
  /// In en, this message translates to:
  /// **'Confirm Address Details'**
  String get confirmAddressDetails;

  /// No description provided for @phoneRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get phoneRequiredError;

  /// No description provided for @phoneLengthError.
  ///
  /// In en, this message translates to:
  /// **'Invalid phone number length'**
  String get phoneLengthError;

  /// No description provided for @fieldRequiredError.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get fieldRequiredError;

  /// No description provided for @underMaintenanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Under Maintenance'**
  String get underMaintenanceTitle;

  /// No description provided for @underMaintenanceMessage.
  ///
  /// In en, this message translates to:
  /// **'Z Speed is currently undergoing scheduled maintenance to improve our systems. We\'ll be back online shortly.'**
  String get underMaintenanceMessage;

  /// No description provided for @checkBackSoon.
  ///
  /// In en, this message translates to:
  /// **'Please check back soon!'**
  String get checkBackSoon;

  /// No description provided for @onlySuperAdminCanToggleMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Only Super Admin can toggle maintenance mode'**
  String get onlySuperAdminCanToggleMaintenance;

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'Fast & Reliable Delivery'**
  String get onboardingTitle1;

  /// No description provided for @onboardingSub1.
  ///
  /// In en, this message translates to:
  /// **'Get your food, groceries, and essential items delivered to your doorstep in minutes.'**
  String get onboardingSub1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'Diverse Services'**
  String get onboardingTitle2;

  /// No description provided for @onboardingSub2.
  ///
  /// In en, this message translates to:
  /// **'Explore top restaurants, pharmacies, books, transport options, and much more.'**
  String get onboardingSub2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'Real-time Tracking'**
  String get onboardingTitle3;

  /// No description provided for @onboardingSub3.
  ///
  /// In en, this message translates to:
  /// **'Track your courier live on the map and stay updated at every stage of the delivery.'**
  String get onboardingSub3;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get onboardingGetStarted;

  /// No description provided for @onboardingLoginSignup.
  ///
  /// In en, this message translates to:
  /// **'Login / Sign Up'**
  String get onboardingLoginSignup;

  /// No description provided for @onboardingGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as Guest'**
  String get onboardingGuest;

  /// No description provided for @meatAndProteins.
  ///
  /// In en, this message translates to:
  /// **'Meat & Proteins'**
  String get meatAndProteins;

  /// No description provided for @clothes.
  ///
  /// In en, this message translates to:
  /// **'Clothing & Fashion'**
  String get clothes;

  /// No description provided for @buyAndSell.
  ///
  /// In en, this message translates to:
  /// **'Buy & Sell'**
  String get buyAndSell;

  /// No description provided for @electronics.
  ///
  /// In en, this message translates to:
  /// **'Electronics'**
  String get electronics;

  /// No description provided for @bookstore.
  ///
  /// In en, this message translates to:
  /// **'Bookstore & Stationery'**
  String get bookstore;

  /// No description provided for @homeFurnishing.
  ///
  /// In en, this message translates to:
  /// **'Home & Furnishing'**
  String get homeFurnishing;

  /// No description provided for @meatAndProteinsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fresh meat, poultry, fish and protein products'**
  String get meatAndProteinsSubtitle;

  /// No description provided for @clothesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Men, women, kids clothing and fashion products'**
  String get clothesSubtitle;

  /// No description provided for @buyAndSellSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Marketplace for buying and selling new and used goods'**
  String get buyAndSellSubtitle;

  /// No description provided for @electronicsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Smartphones, computers, screens and home appliances'**
  String get electronicsSubtitle;

  /// No description provided for @errorLoadingMeatAndProteins.
  ///
  /// In en, this message translates to:
  /// **'Error loading meat & protein shops'**
  String get errorLoadingMeatAndProteins;

  /// No description provided for @errorLoadingClothes.
  ///
  /// In en, this message translates to:
  /// **'Error loading clothing shops'**
  String get errorLoadingClothes;

  /// No description provided for @errorLoadingBuyAndSell.
  ///
  /// In en, this message translates to:
  /// **'Error loading items'**
  String get errorLoadingBuyAndSell;

  /// No description provided for @errorLoadingElectronics.
  ///
  /// In en, this message translates to:
  /// **'Error loading electronic shops'**
  String get errorLoadingElectronics;

  /// No description provided for @searchMeatAndProteins.
  ///
  /// In en, this message translates to:
  /// **'Search for meat, poultry, fish...'**
  String get searchMeatAndProteins;

  /// No description provided for @searchClothes.
  ///
  /// In en, this message translates to:
  /// **'Search for clothes, shoes, accessories...'**
  String get searchClothes;

  /// No description provided for @searchBuyAndSell.
  ///
  /// In en, this message translates to:
  /// **'Search marketplace...'**
  String get searchBuyAndSell;

  /// No description provided for @searchElectronics.
  ///
  /// In en, this message translates to:
  /// **'Search for phones, computers, devices...'**
  String get searchElectronics;

  /// No description provided for @noMeatAndProteinsFound.
  ///
  /// In en, this message translates to:
  /// **'No meat shops found'**
  String get noMeatAndProteinsFound;

  /// No description provided for @noClothesFound.
  ///
  /// In en, this message translates to:
  /// **'No clothing shops found'**
  String get noClothesFound;

  /// No description provided for @noBuyAndSellFound.
  ///
  /// In en, this message translates to:
  /// **'No marketplace items found'**
  String get noBuyAndSellFound;

  /// No description provided for @noElectronicsFound.
  ///
  /// In en, this message translates to:
  /// **'No electronic shops found'**
  String get noElectronicsFound;

  /// No description provided for @supportChats.
  ///
  /// In en, this message translates to:
  /// **'Support Chats'**
  String get supportChats;

  /// No description provided for @replyToCustomerSupport.
  ///
  /// In en, this message translates to:
  /// **'Reply to customer live chat inquiries'**
  String get replyToCustomerSupport;

  /// No description provided for @activeSupportChats.
  ///
  /// In en, this message translates to:
  /// **'Active Support Chats'**
  String get activeSupportChats;

  /// No description provided for @noSupportChats.
  ///
  /// In en, this message translates to:
  /// **'No support chats available'**
  String get noSupportChats;

  /// No description provided for @closeChat.
  ///
  /// In en, this message translates to:
  /// **'Close Chat'**
  String get closeChat;

  /// No description provided for @reopenChat.
  ///
  /// In en, this message translates to:
  /// **'Reopen Chat'**
  String get reopenChat;

  /// No description provided for @chatClosed.
  ///
  /// In en, this message translates to:
  /// **'Chat Closed'**
  String get chatClosed;

  /// No description provided for @chatReopened.
  ///
  /// In en, this message translates to:
  /// **'Chat Reopened'**
  String get chatReopened;

  /// No description provided for @supportAgent.
  ///
  /// In en, this message translates to:
  /// **'Support Agent'**
  String get supportAgent;

  /// No description provided for @connectingToSupport.
  ///
  /// In en, this message translates to:
  /// **'Connecting to support...'**
  String get connectingToSupport;

  /// No description provided for @ticketClosed.
  ///
  /// In en, this message translates to:
  /// **'This support ticket is closed.'**
  String get ticketClosed;

  /// No description provided for @activeDrivers.
  ///
  /// In en, this message translates to:
  /// **'Active Drivers'**
  String get activeDrivers;

  /// No description provided for @onboardingApplications.
  ///
  /// In en, this message translates to:
  /// **'Onboarding Applications'**
  String get onboardingApplications;

  /// No description provided for @vehicleClassification.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Classification'**
  String get vehicleClassification;

  /// No description provided for @adjustBalance.
  ///
  /// In en, this message translates to:
  /// **'Adjust Balance'**
  String get adjustBalance;

  /// No description provided for @activeDriversSearchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search active drivers by name, email, phone...'**
  String get activeDriversSearchPlaceholder;

  /// No description provided for @applicationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Applications & Onboarding'**
  String get applicationsTitle;

  /// No description provided for @applicationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review onboarding requests for drivers and vendors'**
  String get applicationsSubtitle;

  /// No description provided for @driversTab.
  ///
  /// In en, this message translates to:
  /// **'Drivers'**
  String get driversTab;

  /// No description provided for @vendorsTab.
  ///
  /// In en, this message translates to:
  /// **'Vendors'**
  String get vendorsTab;

  /// No description provided for @allCategoriesFilter.
  ///
  /// In en, this message translates to:
  /// **'All Categories'**
  String get allCategoriesFilter;

  /// No description provided for @promoFreeDeliveryApplied.
  ///
  /// In en, this message translates to:
  /// **'🎉 Free delivery applied!'**
  String get promoFreeDeliveryApplied;

  /// No description provided for @promoApplied.
  ///
  /// In en, this message translates to:
  /// **'Promo code applied!'**
  String get promoApplied;

  /// No description provided for @promoInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid promo code. Please try again.'**
  String get promoInvalid;

  /// No description provided for @promoInactive.
  ///
  /// In en, this message translates to:
  /// **'This promo code is no longer active.'**
  String get promoInactive;

  /// No description provided for @promoExpired.
  ///
  /// In en, this message translates to:
  /// **'This promo code has expired.'**
  String get promoExpired;

  /// No description provided for @promoMaxUsageReached.
  ///
  /// In en, this message translates to:
  /// **'This promo code is no longer available.'**
  String get promoMaxUsageReached;

  /// No description provided for @promoUserLimitReached.
  ///
  /// In en, this message translates to:
  /// **'You\'ve already used this promo code.'**
  String get promoUserLimitReached;

  /// No description provided for @promoMinOrderNotMet.
  ///
  /// In en, this message translates to:
  /// **'Minimum order of EGP {amount} required.'**
  String promoMinOrderNotMet(String amount);

  /// No description provided for @promoWrongRestaurant.
  ///
  /// In en, this message translates to:
  /// **'This promo code is not valid for this restaurant.'**
  String get promoWrongRestaurant;

  /// No description provided for @promoPercentageDiscountApplied.
  ///
  /// In en, this message translates to:
  /// **'🎉 {percent}% discount applied! (EGP {amount} off)'**
  String promoPercentageDiscountApplied(String percent, String amount);

  /// No description provided for @promoFixedDiscountApplied.
  ///
  /// In en, this message translates to:
  /// **'🎉 EGP {amount} discount applied!'**
  String promoFixedDiscountApplied(String amount);

  /// No description provided for @placeOrderCalculating.
  ///
  /// In en, this message translates to:
  /// **'Place Order — Calculating...'**
  String get placeOrderCalculating;

  /// No description provided for @placeOrderAndPay.
  ///
  /// In en, this message translates to:
  /// **'Place Order & Pay — EGP {amount}'**
  String placeOrderAndPay(String amount);

  /// No description provided for @usersTab.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get usersTab;

  /// No description provided for @manageActiveRestaurantsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage active restaurants & markets'**
  String get manageActiveRestaurantsSubtitle;

  /// No description provided for @transportSystemTitle.
  ///
  /// In en, this message translates to:
  /// **'Transport System'**
  String get transportSystemTitle;

  /// No description provided for @transportTab.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get transportTab;

  /// No description provided for @transportSystemSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Live map & ride statistics'**
  String get transportSystemSubtitle;

  /// No description provided for @applicationsTab.
  ///
  /// In en, this message translates to:
  /// **'Applications'**
  String get applicationsTab;

  /// No description provided for @analyticsTab.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analyticsTab;

  /// No description provided for @settingsTab.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTab;

  /// No description provided for @promoCodesTitle.
  ///
  /// In en, this message translates to:
  /// **'Promo Codes'**
  String get promoCodesTitle;

  /// No description provided for @promosTab.
  ///
  /// In en, this message translates to:
  /// **'Promos'**
  String get promosTab;

  /// No description provided for @promoCodesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage discount codes'**
  String get promoCodesSubtitle;

  /// No description provided for @settlementsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settlements'**
  String get settlementsTitle;

  /// No description provided for @settlementsTab.
  ///
  /// In en, this message translates to:
  /// **'Settlements'**
  String get settlementsTab;

  /// No description provided for @settlementsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pay out restaurants & drivers'**
  String get settlementsSubtitle;

  /// No description provided for @supportTab.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get supportTab;

  /// No description provided for @adminManagementTab.
  ///
  /// In en, this message translates to:
  /// **'Admins'**
  String get adminManagementTab;

  /// No description provided for @operationsTab.
  ///
  /// In en, this message translates to:
  /// **'Operations'**
  String get operationsTab;

  /// No description provided for @financialsTab.
  ///
  /// In en, this message translates to:
  /// **'Financials'**
  String get financialsTab;

  /// No description provided for @analyticsAndHistoryTab.
  ///
  /// In en, this message translates to:
  /// **'Analytics & History'**
  String get analyticsAndHistoryTab;

  /// No description provided for @activeRides.
  ///
  /// In en, this message translates to:
  /// **'Active Rides'**
  String get activeRides;

  /// No description provided for @recentTrips.
  ///
  /// In en, this message translates to:
  /// **'Recent Trips'**
  String get recentTrips;

  /// No description provided for @noRidesRegisteredToday.
  ///
  /// In en, this message translates to:
  /// **'No rides registered today'**
  String get noRidesRegisteredToday;

  /// No description provided for @statusAndFare.
  ///
  /// In en, this message translates to:
  /// **'Status: {status} | Fare: EGP {fare}'**
  String statusAndFare(String status, String fare);

  /// No description provided for @deliveryFeeFixed.
  ///
  /// In en, this message translates to:
  /// **'Fixed: EGP {amount}'**
  String deliveryFeeFixed(String amount);

  /// No description provided for @deliveryFeeFormula.
  ///
  /// In en, this message translates to:
  /// **'Formula: {base} + {perKm}/km'**
  String deliveryFeeFormula(String base, String perKm);

  /// No description provided for @deliveryFeeTiers.
  ///
  /// In en, this message translates to:
  /// **'Tiers: {count} Brackets'**
  String deliveryFeeTiers(String count);

  /// No description provided for @broadcastTabTitle.
  ///
  /// In en, this message translates to:
  /// **'Broadcast Center'**
  String get broadcastTabTitle;

  /// No description provided for @broadcastTabSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send targeted push & in-app notifications to users across regions'**
  String get broadcastTabSubtitle;

  /// No description provided for @targetAudienceLabel.
  ///
  /// In en, this message translates to:
  /// **'Target Audience'**
  String get targetAudienceLabel;

  /// No description provided for @targetAllUsers.
  ///
  /// In en, this message translates to:
  /// **'All Users'**
  String get targetAllUsers;

  /// No description provided for @targetCustomers.
  ///
  /// In en, this message translates to:
  /// **'Customers Only'**
  String get targetCustomers;

  /// No description provided for @targetDrivers.
  ///
  /// In en, this message translates to:
  /// **'Drivers Only'**
  String get targetDrivers;

  /// No description provided for @targetVendors.
  ///
  /// In en, this message translates to:
  /// **'Vendors Only'**
  String get targetVendors;

  /// No description provided for @targetAdmins.
  ///
  /// In en, this message translates to:
  /// **'Admins Only'**
  String get targetAdmins;

  /// No description provided for @locationAreaLabel.
  ///
  /// In en, this message translates to:
  /// **'Location & Area Filter'**
  String get locationAreaLabel;

  /// No description provided for @allLocations.
  ///
  /// In en, this message translates to:
  /// **'All Locations'**
  String get allLocations;

  /// No description provided for @specificArea.
  ///
  /// In en, this message translates to:
  /// **'Specific Area / City Filter'**
  String get specificArea;

  /// No description provided for @areaHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Cairo, Alexandria, Maadi, Nasr City'**
  String get areaHint;

  /// No description provided for @geoRadiusLabel.
  ///
  /// In en, this message translates to:
  /// **'Geo-Fence Radius Filter'**
  String get geoRadiusLabel;

  /// No description provided for @radiusKmLabel.
  ///
  /// In en, this message translates to:
  /// **'Radius: {km} km'**
  String radiusKmLabel(String km);

  /// No description provided for @notificationContent.
  ///
  /// In en, this message translates to:
  /// **'Notification Content & Localization'**
  String get notificationContent;

  /// No description provided for @notificationTitleEn.
  ///
  /// In en, this message translates to:
  /// **'Title (English)'**
  String get notificationTitleEn;

  /// No description provided for @notificationBodyEn.
  ///
  /// In en, this message translates to:
  /// **'Body Message (English)'**
  String get notificationBodyEn;

  /// No description provided for @notificationTitleAr.
  ///
  /// In en, this message translates to:
  /// **'Title (Arabic)'**
  String get notificationTitleAr;

  /// No description provided for @notificationBodyAr.
  ///
  /// In en, this message translates to:
  /// **'Body Message (Arabic)'**
  String get notificationBodyAr;

  /// No description provided for @imageUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Banner Image URL (Optional)'**
  String get imageUrlLabel;

  /// No description provided for @targetScreenLabel.
  ///
  /// In en, this message translates to:
  /// **'Target Screen / Action'**
  String get targetScreenLabel;

  /// No description provided for @screenNone.
  ///
  /// In en, this message translates to:
  /// **'General (No Action)'**
  String get screenNone;

  /// No description provided for @screenPromo.
  ///
  /// In en, this message translates to:
  /// **'Promo Code Screen'**
  String get screenPromo;

  /// No description provided for @screenVendor.
  ///
  /// In en, this message translates to:
  /// **'Vendor Details'**
  String get screenVendor;

  /// No description provided for @screenCategory.
  ///
  /// In en, this message translates to:
  /// **'Category Browse'**
  String get screenCategory;

  /// No description provided for @screenCustomUrl.
  ///
  /// In en, this message translates to:
  /// **'Custom External Link / URL'**
  String get screenCustomUrl;

  /// No description provided for @attachedPromoCode.
  ///
  /// In en, this message translates to:
  /// **'Attached Promo Code'**
  String get attachedPromoCode;

  /// No description provided for @targetEntityIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Entity ID / External URL'**
  String get targetEntityIdLabel;

  /// No description provided for @deliveryConfigLabel.
  ///
  /// In en, this message translates to:
  /// **'Delivery & Priority Configurations'**
  String get deliveryConfigLabel;

  /// No description provided for @sendFcmPush.
  ///
  /// In en, this message translates to:
  /// **'Send FCM Push Notification'**
  String get sendFcmPush;

  /// No description provided for @storeInAppInbox.
  ///
  /// In en, this message translates to:
  /// **'Save to User In-App Inbox'**
  String get storeInAppInbox;

  /// No description provided for @priorityLabel.
  ///
  /// In en, this message translates to:
  /// **'Delivery Priority'**
  String get priorityLabel;

  /// No description provided for @priorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High (Heads-up alert banner)'**
  String get priorityHigh;

  /// No description provided for @priorityNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get priorityNormal;

  /// No description provided for @soundLabel.
  ///
  /// In en, this message translates to:
  /// **'Notification Sound'**
  String get soundLabel;

  /// No description provided for @soundDefault.
  ///
  /// In en, this message translates to:
  /// **'Default System Sound'**
  String get soundDefault;

  /// No description provided for @soundAlert.
  ///
  /// In en, this message translates to:
  /// **'High Alert Sound'**
  String get soundAlert;

  /// No description provided for @soundSilent.
  ///
  /// In en, this message translates to:
  /// **'Silent'**
  String get soundSilent;

  /// No description provided for @presetTemplates.
  ///
  /// In en, this message translates to:
  /// **'Quick Preset Templates'**
  String get presetTemplates;

  /// No description provided for @templatePromoCode.
  ///
  /// In en, this message translates to:
  /// **'Promo Discount Code'**
  String get templatePromoCode;

  /// No description provided for @templateSystemUpdate.
  ///
  /// In en, this message translates to:
  /// **'App Maintenance Update'**
  String get templateSystemUpdate;

  /// No description provided for @templateFlashSale.
  ///
  /// In en, this message translates to:
  /// **'Flash Sale & Offer'**
  String get templateFlashSale;

  /// No description provided for @templateAreaAlert.
  ///
  /// In en, this message translates to:
  /// **'Area Special Offer'**
  String get templateAreaAlert;

  /// No description provided for @previewHeader.
  ///
  /// In en, this message translates to:
  /// **'Interactive Lockscreen Preview'**
  String get previewHeader;

  /// No description provided for @sendBroadcastButton.
  ///
  /// In en, this message translates to:
  /// **'Send Broadcast Notification'**
  String get sendBroadcastButton;

  /// No description provided for @confirmBroadcastTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Broadcast Dispatch'**
  String get confirmBroadcastTitle;

  /// No description provided for @confirmBroadcastBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to send this broadcast notification to all targeted users?'**
  String get confirmBroadcastBody;

  /// No description provided for @broadcastSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Broadcast Sent Successfully!'**
  String get broadcastSuccessTitle;

  /// No description provided for @targetedUsersCount.
  ///
  /// In en, this message translates to:
  /// **'Targeted Users: {count}'**
  String targetedUsersCount(String count);

  /// No description provided for @pushDeliveredCount.
  ///
  /// In en, this message translates to:
  /// **'Push Messages Delivered: {count}'**
  String pushDeliveredCount(String count);

  /// No description provided for @pushFailedCount.
  ///
  /// In en, this message translates to:
  /// **'Push Delivery Failures: {count}'**
  String pushFailedCount(String count);

  /// No description provided for @inAppSavedCount.
  ///
  /// In en, this message translates to:
  /// **'In-App Records Saved: {count}'**
  String inAppSavedCount(String count);

  /// No description provided for @setRadiusCenterMap.
  ///
  /// In en, this message translates to:
  /// **'Set Radius Center on Map 📍'**
  String get setRadiusCenterMap;

  /// No description provided for @radiusCenterSelected.
  ///
  /// In en, this message translates to:
  /// **'Center Location: {lat}, {lng}'**
  String radiusCenterSelected(Object lat, Object lng);

  /// No description provided for @selectTargetAreaMap.
  ///
  /// In en, this message translates to:
  /// **'Select Area on Map 📍'**
  String get selectTargetAreaMap;

  /// No description provided for @audienceSpecificUser.
  ///
  /// In en, this message translates to:
  /// **'Specific User'**
  String get audienceSpecificUser;

  /// No description provided for @targetUserIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Target User (UID / Phone / Email)'**
  String get targetUserIdLabel;

  /// No description provided for @targetUserIdHint.
  ///
  /// In en, this message translates to:
  /// **'Enter user UID, phone number, or email address'**
  String get targetUserIdHint;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get filterUnread;

  /// No description provided for @filterOrders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get filterOrders;

  /// No description provided for @filterPromos.
  ///
  /// In en, this message translates to:
  /// **'Offers'**
  String get filterPromos;

  /// No description provided for @unreadCountNotice.
  ///
  /// In en, this message translates to:
  /// **'You have {count} unread notifications'**
  String unreadCountNotice(int count);

  /// No description provided for @allNotificationsMarkedRead.
  ///
  /// In en, this message translates to:
  /// **'All notifications marked as read'**
  String get allNotificationsMarkedRead;

  /// No description provided for @noUnreadNotifications.
  ///
  /// In en, this message translates to:
  /// **'No unread notifications'**
  String get noUnreadNotifications;

  /// No description provided for @noOrderNotifications.
  ///
  /// In en, this message translates to:
  /// **'No order notifications'**
  String get noOrderNotifications;

  /// No description provided for @noPromoNotifications.
  ///
  /// In en, this message translates to:
  /// **'No offers or discounts available'**
  String get noPromoNotifications;

  /// No description provided for @allNotificationsWillAppear.
  ///
  /// In en, this message translates to:
  /// **'All updates and offers will appear here'**
  String get allNotificationsWillAppear;

  /// No description provided for @viewAllNotifications.
  ///
  /// In en, this message translates to:
  /// **'View all notifications'**
  String get viewAllNotifications;

  /// No description provided for @promoCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Promo code copied: {code}'**
  String promoCodeCopied(String code);

  /// No description provided for @selectedOptionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The selected option is currently unavailable'**
  String get selectedOptionUnavailable;

  /// No description provided for @masterLogisticsKpiDashboard.
  ///
  /// In en, this message translates to:
  /// **'Master Logistics KPI Dashboard'**
  String get masterLogisticsKpiDashboard;

  /// No description provided for @kpiDashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Real-time metrics, profits, driver payouts and vendor financial calculations'**
  String get kpiDashboardSubtitle;

  /// No description provided for @exportExcel.
  ///
  /// In en, this message translates to:
  /// **'Export Excel'**
  String get exportExcel;

  /// No description provided for @exportPdfPrint.
  ///
  /// In en, this message translates to:
  /// **'Export PDF / Print'**
  String get exportPdfPrint;

  /// No description provided for @excelExportedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Excel exported successfully'**
  String get excelExportedSuccess;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed'**
  String get exportFailed;

  /// No description provided for @searchOrderIdCustomerHint.
  ///
  /// In en, this message translates to:
  /// **'Search Order ID / Customer...'**
  String get searchOrderIdCustomerHint;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @last7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 Days'**
  String get last7Days;

  /// No description provided for @customDateRange.
  ///
  /// In en, this message translates to:
  /// **'Custom Date Range'**
  String get customDateRange;

  /// No description provided for @allVendorsCombined.
  ///
  /// In en, this message translates to:
  /// **'All Vendors (Combined)'**
  String get allVendorsCombined;

  /// No description provided for @allRidersCombined.
  ///
  /// In en, this message translates to:
  /// **'All Riders (Combined)'**
  String get allRidersCombined;

  /// No description provided for @allPaymentMethods.
  ///
  /// In en, this message translates to:
  /// **'All Payment Methods'**
  String get allPaymentMethods;

  /// No description provided for @platformDeliveryFeeToggle.
  ///
  /// In en, this message translates to:
  /// **'15% Platform Delivery Fee'**
  String get platformDeliveryFeeToggle;

  /// No description provided for @restaurantGrossSales.
  ///
  /// In en, this message translates to:
  /// **'Restaurant Gross Sales'**
  String get restaurantGrossSales;

  /// No description provided for @subtotalAcrossOrders.
  ///
  /// In en, this message translates to:
  /// **'Subtotal across orders'**
  String get subtotalAcrossOrders;

  /// No description provided for @totalDeliveryFeesCollected.
  ///
  /// In en, this message translates to:
  /// **'Total Delivery Fees'**
  String get totalDeliveryFeesCollected;

  /// No description provided for @collectedFromClients.
  ///
  /// In en, this message translates to:
  /// **'Collected from clients'**
  String get collectedFromClients;

  /// No description provided for @tripsCompleted.
  ///
  /// In en, this message translates to:
  /// **'Trips Completed'**
  String get tripsCompleted;

  /// No description provided for @deliveredOrdersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Delivered orders'**
  String get deliveredOrdersSubtitle;

  /// No description provided for @activeOrdersKpi.
  ///
  /// In en, this message translates to:
  /// **'Active Orders'**
  String get activeOrdersKpi;

  /// No description provided for @inProgressSubtitle.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get inProgressSubtitle;

  /// No description provided for @rideAcceptanceRate.
  ///
  /// In en, this message translates to:
  /// **'Ride Acceptance'**
  String get rideAcceptanceRate;

  /// No description provided for @driverResponseRate.
  ///
  /// In en, this message translates to:
  /// **'Driver response rate'**
  String get driverResponseRate;

  /// No description provided for @masterNetProfit.
  ///
  /// In en, this message translates to:
  /// **'Master Net Profit'**
  String get masterNetProfit;

  /// No description provided for @masterCommission.
  ///
  /// In en, this message translates to:
  /// **'Master Commission'**
  String get masterCommission;

  /// No description provided for @comm10PlusFee15.
  ///
  /// In en, this message translates to:
  /// **'Comm (10%) + Platform Fee (15%)'**
  String get comm10PlusFee15;

  /// No description provided for @comm10Only.
  ///
  /// In en, this message translates to:
  /// **'10% Admin Commission Only'**
  String get comm10Only;

  /// No description provided for @restaurantFinancialsPayouts.
  ///
  /// In en, this message translates to:
  /// **'Restaurant Financials & Payouts'**
  String get restaurantFinancialsPayouts;

  /// No description provided for @noVendorFinancialData.
  ///
  /// In en, this message translates to:
  /// **'No vendor financial data available'**
  String get noVendorFinancialData;

  /// No description provided for @deliveredOrdersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Delivered Orders'**
  String deliveredOrdersCount(int count);

  /// No description provided for @netSalesLabel.
  ///
  /// In en, this message translates to:
  /// **'Net Sales'**
  String get netSalesLabel;

  /// No description provided for @adminComm10.
  ///
  /// In en, this message translates to:
  /// **'Admin Comm (10%)'**
  String get adminComm10;

  /// No description provided for @amountDue.
  ///
  /// In en, this message translates to:
  /// **'Amount Due'**
  String get amountDue;

  /// No description provided for @riderPerformanceEarnings.
  ///
  /// In en, this message translates to:
  /// **'Rider Performance & Earnings'**
  String get riderPerformanceEarnings;

  /// No description provided for @noRiderTripData.
  ///
  /// In en, this message translates to:
  /// **'No rider trip data available'**
  String get noRiderTripData;

  /// No description provided for @tripsCompletedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Trips Completed'**
  String tripsCompletedCount(int count);

  /// No description provided for @totalFeesLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Fees'**
  String get totalFeesLabel;

  /// No description provided for @riderShare85.
  ///
  /// In en, this message translates to:
  /// **'Rider Share (85%)'**
  String get riderShare85;

  /// No description provided for @platformCut15.
  ///
  /// In en, this message translates to:
  /// **'Platform Cut (15%)'**
  String get platformCut15;

  /// No description provided for @tripOrderDetailedRecords.
  ///
  /// In en, this message translates to:
  /// **'Trip & Order Detailed Records'**
  String get tripOrderDetailedRecords;

  /// No description provided for @totalOrdersCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Total: {count} orders'**
  String totalOrdersCountLabel(int count);

  /// No description provided for @noOrdersMatchFilter.
  ///
  /// In en, this message translates to:
  /// **'No orders match current filter'**
  String get noOrdersMatchFilter;

  /// No description provided for @tableColDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get tableColDate;

  /// No description provided for @tableColOrderTripId.
  ///
  /// In en, this message translates to:
  /// **'Order / Trip ID'**
  String get tableColOrderTripId;

  /// No description provided for @tableColStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get tableColStatus;

  /// No description provided for @tableColChangedBy.
  ///
  /// In en, this message translates to:
  /// **'Changed By'**
  String get tableColChangedBy;

  /// No description provided for @tableColPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get tableColPayment;

  /// No description provided for @tableColSubtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get tableColSubtotal;

  /// No description provided for @tableColDeliveryFee.
  ///
  /// In en, this message translates to:
  /// **'Delivery Fee'**
  String get tableColDeliveryFee;

  /// No description provided for @tableColRiderCut.
  ///
  /// In en, this message translates to:
  /// **'Rider Cut (85%)'**
  String get tableColRiderCut;

  /// No description provided for @tableColAdminComm.
  ///
  /// In en, this message translates to:
  /// **'Admin Comm (10%)'**
  String get tableColAdminComm;

  /// No description provided for @tableColPlatformFee.
  ///
  /// In en, this message translates to:
  /// **'Platform Fee (15%)'**
  String get tableColPlatformFee;

  /// No description provided for @actorCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get actorCustomer;

  /// No description provided for @actorVendor.
  ///
  /// In en, this message translates to:
  /// **'Vendor'**
  String get actorVendor;

  /// No description provided for @actorDriver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get actorDriver;

  /// No description provided for @actorAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get actorAdmin;

  /// No description provided for @actorSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get actorSystem;

  /// No description provided for @pageXOfY.
  ///
  /// In en, this message translates to:
  /// **'Page {page} of {total}'**
  String pageXOfY(int page, int total);

  /// No description provided for @customerIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Customer ID'**
  String get customerIdLabel;

  /// No description provided for @taxLabel.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get taxLabel;

  /// No description provided for @orderDetailsTitleParam.
  ///
  /// In en, this message translates to:
  /// **'Order Details {id}'**
  String orderDetailsTitleParam(String id);

  /// No description provided for @orderIdParam.
  ///
  /// In en, this message translates to:
  /// **'Order ID: {id}'**
  String orderIdParam(String id);

  /// No description provided for @customerIdParam.
  ///
  /// In en, this message translates to:
  /// **'Customer ID: {id}'**
  String customerIdParam(String id);

  /// No description provided for @statusParam.
  ///
  /// In en, this message translates to:
  /// **'Status: {status}'**
  String statusParam(String status);

  /// No description provided for @changedByParam.
  ///
  /// In en, this message translates to:
  /// **'Changed By: {actor}'**
  String changedByParam(String actor);

  /// No description provided for @cancelledByParam.
  ///
  /// In en, this message translates to:
  /// **'Cancelled By: {actor}'**
  String cancelledByParam(String actor);

  /// No description provided for @cancellationReasonParam.
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}'**
  String cancellationReasonParam(String reason);

  /// No description provided for @paymentMethodParam.
  ///
  /// In en, this message translates to:
  /// **'Payment Method: {method}'**
  String paymentMethodParam(String method);

  /// No description provided for @subtotalParam.
  ///
  /// In en, this message translates to:
  /// **'Subtotal: {amount}'**
  String subtotalParam(String amount);

  /// No description provided for @deliveryFeeParam.
  ///
  /// In en, this message translates to:
  /// **'Delivery Fee: {amount}'**
  String deliveryFeeParam(String amount);

  /// No description provided for @taxParam.
  ///
  /// In en, this message translates to:
  /// **'Tax: {amount}'**
  String taxParam(String amount);

  /// No description provided for @totalParam.
  ///
  /// In en, this message translates to:
  /// **'Total: {amount}'**
  String totalParam(String amount);

  /// No description provided for @errorLoadingKpiMetrics.
  ///
  /// In en, this message translates to:
  /// **'Error loading KPI metrics: {error}'**
  String errorLoadingKpiMetrics(String error);

  /// No description provided for @itemCurrentlyUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This item is currently unavailable'**
  String get itemCurrentlyUnavailable;

  /// No description provided for @someItemsUnavailableSkipped.
  ///
  /// In en, this message translates to:
  /// **'Some items in this order are no longer available and were skipped'**
  String get someItemsUnavailableSkipped;

  /// No description provided for @kpiTabTitle.
  ///
  /// In en, this message translates to:
  /// **'Logistics KPI'**
  String get kpiTabTitle;

  /// No description provided for @kpiTabShortTitle.
  ///
  /// In en, this message translates to:
  /// **'KPI Dashboard'**
  String get kpiTabShortTitle;

  /// No description provided for @kpiTabSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Comprehensive vendor, rider & profit calculations'**
  String get kpiTabSubtitle;

  /// No description provided for @busyModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Busy Mode'**
  String get busyModeLabel;

  /// No description provided for @busyModeActive.
  ///
  /// In en, this message translates to:
  /// **'Busy (Orders Paused)'**
  String get busyModeActive;

  /// No description provided for @busyModeInactive.
  ///
  /// In en, this message translates to:
  /// **'Available (Accepting Orders)'**
  String get busyModeInactive;

  /// No description provided for @busyModeDesc.
  ///
  /// In en, this message translates to:
  /// **'Temporarily stop accepting new orders'**
  String get busyModeDesc;

  /// No description provided for @vendorCurrentlyBusy.
  ///
  /// In en, this message translates to:
  /// **'This store is currently busy and not accepting orders.'**
  String get vendorCurrentlyBusy;

  /// No description provided for @notifyMeWhenAvailable.
  ///
  /// In en, this message translates to:
  /// **'Notify Me When Available'**
  String get notifyMeWhenAvailable;

  /// No description provided for @willNotifyWhenAvailable.
  ///
  /// In en, this message translates to:
  /// **'We\'ll notify you if this store comes back online within the next 2 hours! 🔔'**
  String get willNotifyWhenAvailable;

  /// No description provided for @alreadySubscribedNotify.
  ///
  /// In en, this message translates to:
  /// **'You will be notified as soon as this store is available.'**
  String get alreadySubscribedNotify;

  /// No description provided for @storyApprovalStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending Approval'**
  String get storyApprovalStatusPending;

  /// No description provided for @storyApprovalStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get storyApprovalStatusApproved;

  /// No description provided for @storyApprovalStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get storyApprovalStatusRejected;

  /// No description provided for @storySubmittedAwaitingApproval.
  ///
  /// In en, this message translates to:
  /// **'Story submitted! Awaiting admin approval.'**
  String get storySubmittedAwaitingApproval;

  /// No description provided for @storiesApprovalTabTitle.
  ///
  /// In en, this message translates to:
  /// **'Story Approvals'**
  String get storiesApprovalTabTitle;

  /// No description provided for @storiesApprovalTabShort.
  ///
  /// In en, this message translates to:
  /// **'Stories'**
  String get storiesApprovalTabShort;

  /// No description provided for @addDeliveryArea.
  ///
  /// In en, this message translates to:
  /// **'Add Area on Map 📍'**
  String get addDeliveryArea;

  /// No description provided for @configuredDeliveryAreas.
  ///
  /// In en, this message translates to:
  /// **'Custom Delivery Map Areas'**
  String get configuredDeliveryAreas;

  /// No description provided for @areaNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Area / Zone Name'**
  String get areaNameLabel;

  /// No description provided for @thresholdKmLabel.
  ///
  /// In en, this message translates to:
  /// **'Base Distance Threshold (km)'**
  String get thresholdKmLabel;

  /// No description provided for @extraKmRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Rate after threshold (EGP/km)'**
  String get extraKmRateLabel;

  /// No description provided for @noAreasConfigured.
  ///
  /// In en, this message translates to:
  /// **'No custom map areas added yet.'**
  String get noAreasConfigured;

  /// No description provided for @deleteArea.
  ///
  /// In en, this message translates to:
  /// **'Delete Area'**
  String get deleteArea;

  /// No description provided for @editArea.
  ///
  /// In en, this message translates to:
  /// **'Edit Area'**
  String get editArea;

  /// No description provided for @areaRulesInfo.
  ///
  /// In en, this message translates to:
  /// **'Orders within this area charge base fee up to threshold + extra km rate.'**
  String get areaRulesInfo;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
