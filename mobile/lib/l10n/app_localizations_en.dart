// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'QrPay';

  @override
  String get home => 'Home';

  @override
  String get scan => 'Scan';

  @override
  String get send => 'Send';

  @override
  String get history => 'History';

  @override
  String get profile => 'Profile';

  @override
  String get settings => 'Settings';

  @override
  String get securityAuthentication => 'Security & Authentication';

  @override
  String get biometricAuthentication => 'Biometric Authentication';

  @override
  String get enabledForPayments => 'Enabled for payments';

  @override
  String get disabled => 'Disabled';

  @override
  String get authenticationMethod => 'Authentication Method';

  @override
  String get pinOnly => 'PIN Only';

  @override
  String get usePinForPayments => 'Use UPI PIN for all payments';

  @override
  String get biometricOnly => 'Biometric Only';

  @override
  String get useBiometricForPayments => 'Use biometric for all payments';

  @override
  String get biometricPinFallback => 'Biometric + PIN Fallback';

  @override
  String get tryBiometricFirst => 'Try biometric first, PIN if needed';

  @override
  String get changeUpiPin => 'Change UPI PIN';

  @override
  String get updateUpiPin => 'Update your UPI PIN for transactions';

  @override
  String get twoFactorAuth => 'Two-Factor Authentication';

  @override
  String get addExtraSecurity => 'Add extra security to your account';

  @override
  String get general => 'General';

  @override
  String get notifications => 'Notifications';

  @override
  String get manageNotifications => 'Manage your notification preferences';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Theme';

  @override
  String get darkMode => 'Dark mode';

  @override
  String get about => 'About';

  @override
  String get helpSupport => 'Help & Support';

  @override
  String get getHelpWithQrPay => 'Get help with QrPay';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get readPrivacyPolicy => 'Read our privacy policy';

  @override
  String get aboutQrPay => 'About QrPay';

  @override
  String get version => 'Version 1.0.0';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get english => 'English';

  @override
  String get hindi => 'हिंदी';

  @override
  String get spanish => 'Español';

  @override
  String get french => 'Français';

  @override
  String get german => 'Deutsch';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String languageChanged(String language) {
    return 'Language changed to $language';
  }

  @override
  String get restartRequired =>
      'Please restart the app to apply language changes';

  @override
  String get biometricNotAvailable =>
      'Biometric authentication not available on this device';

  @override
  String get biometricEnabled =>
      'Biometric authentication enabled for payments';

  @override
  String get biometricDisabled => 'Biometric authentication disabled';

  @override
  String authMethodSet(String method) {
    return 'Authentication method set to $method';
  }

  @override
  String get failedToAuthenticate =>
      'Failed to authenticate. Biometric not enabled.';
}
