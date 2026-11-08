import 'package:dio/dio.dart';

import '../../l10n/app_localizations.dart';

/// Turns any failure into a short message in the app language.
String errorMessage(AppL10n t, Object error) {
  if (error is DioException) {
    switch (error.response?.statusCode) {
      case 409:
        return t.errorDuplicate;
      case 400:
      case 422:
        return t.errorInvalid;
    }
    switch (error.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return t.errorNoConnection;
      default:
        break;
    }
  }
  return t.errorGeneric;
}
