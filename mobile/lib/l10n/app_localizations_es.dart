// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'QrPay';

  @override
  String get home => 'Inicio';

  @override
  String get scan => 'Escanear';

  @override
  String get send => 'Enviar';

  @override
  String get history => 'Historial';

  @override
  String get profile => 'Perfil';

  @override
  String get settings => 'Configuración';

  @override
  String get securityAuthentication => 'Seguridad y Autenticación';

  @override
  String get biometricAuthentication => 'Autenticación Biométrica';

  @override
  String get enabledForPayments => 'Habilitado para pagos';

  @override
  String get disabled => 'Deshabilitado';

  @override
  String get authenticationMethod => 'Método de Autenticación';

  @override
  String get pinOnly => 'Solo PIN';

  @override
  String get usePinForPayments => 'Usar PIN UPI para todos los pagos';

  @override
  String get biometricOnly => 'Solo Biométrico';

  @override
  String get useBiometricForPayments => 'Usar biométrico para todos los pagos';

  @override
  String get biometricPinFallback => 'Biométrico + PIN de Respaldo';

  @override
  String get tryBiometricFirst =>
      'Intentar biométrico primero, PIN si es necesario';

  @override
  String get changeUpiPin => 'Cambiar PIN UPI';

  @override
  String get updateUpiPin => 'Actualiza tu PIN UPI para transacciones';

  @override
  String get twoFactorAuth => 'Autenticación de Dos Factores';

  @override
  String get addExtraSecurity => 'Agrega seguridad extra a tu cuenta';

  @override
  String get general => 'General';

  @override
  String get notifications => 'Notificaciones';

  @override
  String get manageNotifications => 'Gestiona tus preferencias de notificación';

  @override
  String get language => 'Idioma';

  @override
  String get theme => 'Tema';

  @override
  String get darkMode => 'Modo oscuro';

  @override
  String get about => 'Acerca de';

  @override
  String get helpSupport => 'Ayuda y Soporte';

  @override
  String get getHelpWithQrPay => 'Obtén ayuda con QrPay';

  @override
  String get privacyPolicy => 'Política de Privacidad';

  @override
  String get readPrivacyPolicy => 'Lee nuestra política de privacidad';

  @override
  String get aboutQrPay => 'Acerca de QrPay';

  @override
  String get version => 'Versión 1.0.0';

  @override
  String get selectLanguage => 'Seleccionar Idioma';

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
  String get cancel => 'Cancelar';

  @override
  String get confirm => 'Confirmar';

  @override
  String languageChanged(String language) {
    return 'Idioma cambiado a $language';
  }

  @override
  String get restartRequired =>
      'Por favor reinicia la aplicación para aplicar los cambios de idioma';

  @override
  String get biometricNotAvailable =>
      'Autenticación biométrica no disponible en este dispositivo';

  @override
  String get biometricEnabled =>
      'Autenticación biométrica habilitada para pagos';

  @override
  String get biometricDisabled => 'Autenticación biométrica deshabilitada';

  @override
  String authMethodSet(String method) {
    return 'Método de autenticación establecido a $method';
  }

  @override
  String get failedToAuthenticate =>
      'Falló la autenticación. Biométrico no habilitado.';
}
