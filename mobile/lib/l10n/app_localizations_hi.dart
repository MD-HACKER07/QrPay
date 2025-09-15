// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'QrPay';

  @override
  String get home => 'होम';

  @override
  String get scan => 'स्कैन';

  @override
  String get send => 'भेजें';

  @override
  String get history => 'इतिहास';

  @override
  String get profile => 'प्रोफ़ाइल';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get securityAuthentication => 'सुरक्षा और प्रमाणीकरण';

  @override
  String get biometricAuthentication => 'बायोमेट्रिक प्रमाणीकरण';

  @override
  String get enabledForPayments => 'भुगतान के लिए सक्षम';

  @override
  String get disabled => 'अक्षम';

  @override
  String get authenticationMethod => 'प्रमाणीकरण विधि';

  @override
  String get pinOnly => 'केवल पिन';

  @override
  String get usePinForPayments => 'सभी भुगतानों के लिए UPI पिन का उपयोग करें';

  @override
  String get biometricOnly => 'केवल बायोमेट्रिक';

  @override
  String get useBiometricForPayments =>
      'सभी भुगतानों के लिए बायोमेट्रिक का उपयोग करें';

  @override
  String get biometricPinFallback => 'बायोमेट्रिक + पिन फॉलबैक';

  @override
  String get tryBiometricFirst => 'पहले बायोमेट्रिक, आवश्यकता पड़ने पर पिन';

  @override
  String get changeUpiPin => 'UPI पिन बदलें';

  @override
  String get updateUpiPin => 'लेन-देन के लिए अपना UPI पिन अपडेट करें';

  @override
  String get twoFactorAuth => 'द्विकारक प्रमाणीकरण';

  @override
  String get addExtraSecurity => 'अपने खाते में अतिरिक्त सुरक्षा जोड़ें';

  @override
  String get general => 'सामान्य';

  @override
  String get notifications => 'सूचनाएं';

  @override
  String get manageNotifications => 'अपनी सूचना प्राथमिकताएं प्रबंधित करें';

  @override
  String get language => 'भाषा';

  @override
  String get theme => 'थीम';

  @override
  String get darkMode => 'डार्क मोड';

  @override
  String get about => 'के बारे में';

  @override
  String get helpSupport => 'सहायता और समर्थन';

  @override
  String get getHelpWithQrPay => 'QrPay के साथ सहायता प्राप्त करें';

  @override
  String get privacyPolicy => 'गोपनीयता नीति';

  @override
  String get readPrivacyPolicy => 'हमारी गोपनीयता नीति पढ़ें';

  @override
  String get aboutQrPay => 'QrPay के बारे में';

  @override
  String get version => 'संस्करण 1.0.0';

  @override
  String get selectLanguage => 'भाषा चुनें';

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
  String get cancel => 'रद्द करें';

  @override
  String get confirm => 'पुष्टि करें';

  @override
  String languageChanged(String language) {
    return 'भाषा $language में बदल दी गई';
  }

  @override
  String get restartRequired =>
      'भाषा परिवर्तन लागू करने के लिए कृपया ऐप को पुनः आरंभ करें';

  @override
  String get biometricNotAvailable =>
      'इस डिवाइस पर बायोमेट्रिक प्रमाणीकरण उपलब्ध नहीं है';

  @override
  String get biometricEnabled =>
      'भुगतान के लिए बायोमेट्रिक प्रमाणीकरण सक्षम किया गया';

  @override
  String get biometricDisabled => 'बायोमेट्रिक प्रमाणीकरण अक्षम किया गया';

  @override
  String authMethodSet(String method) {
    return 'प्रमाणीकरण विधि $method पर सेट की गई';
  }

  @override
  String get failedToAuthenticate =>
      'प्रमाणीकरण विफल। बायोमेट्रिक सक्षम नहीं किया गया।';
}
