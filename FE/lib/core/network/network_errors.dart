import 'package:dio/dio.dart';

/// True when the request may not have reached the server or got no real answer
/// (no signal, timeout, server waking up). Such saves are kept and retried later.
bool isNetworkProblem(Object error) {
  if (error is! DioException) return false;
  switch (error.type) {
    case DioExceptionType.connectionError:
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return true;
    default:
      break;
  }
  final code = error.response?.statusCode;
  return error.response == null || code == 502 || code == 503 || code == 504;
}
