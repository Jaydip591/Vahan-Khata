import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';

enum UpiStatus { success, failure, pending, unknown, noApp }

/// What came back from the UPI app. The status is what the UPI app said, not a bank check.
class UpiResult {
  const UpiResult(this.status, {this.ref, this.raw});
  final UpiStatus status;

  /// Bank reference (UTR / ApprovalRefNo), else the UPI app's transaction id.
  final String? ref;
  final String? raw;

  /// Reads the "key=value&key=value" text a UPI app returns. Keys differ in case between apps.
  static UpiResult parse({required bool resultOk, String? response}) {
    if (response == null || response.trim().isEmpty) {
      return UpiResult(resultOk ? UpiStatus.unknown : UpiStatus.failure, raw: response);
    }
    final map = <String, String>{};
    for (final part in response.split('&')) {
      final i = part.indexOf('=');
      if (i <= 0) continue;
      map[part.substring(0, i).trim().toLowerCase()] = Uri.decodeComponent(part.substring(i + 1).trim());
    }
    final status = (map['status'] ?? '').toUpperCase();
    final ref = [map['approvalrefno'], map['txnref'], map['txnid']]
        .firstWhere((v) => v != null && v.isNotEmpty && v.toLowerCase() != 'null', orElse: () => null);
    final s = switch (status) {
      'SUCCESS' => UpiStatus.success,
      'FAILURE' || 'FAILED' => UpiStatus.failure,
      'SUBMITTED' || 'PENDING' => UpiStatus.pending,
      _ => map['responsecode'] == '00' ? UpiStatus.success : UpiStatus.unknown,
    };
    return UpiResult(s, ref: ref == null || ref.length <= 40 ? ref : ref.substring(0, 40), raw: response);
  }
}

/// The upi://pay link handed to the UPI app.
Uri upiPayUri({
  required String upiId,
  required String name,
  required String amount,
  required String note,
  required String txnRef,
}) =>
    Uri(scheme: 'upi', host: 'pay', queryParameters: {
      'pa': upiId,
      'pn': name,
      'am': double.parse(amount).toStringAsFixed(2),
      'cu': 'INR',
      'tn': note,
      'tr': txnRef,
    });

/// Opens Google Pay (or the list of UPI apps) through `MainActivity.kt` and waits for its answer.
class UpiService {
  const UpiService();
  static const _channel = MethodChannel('vahan_khata/upi');

  Future<UpiResult> pay(Uri uri) async {
    try {
      final r = await _channel.invokeMapMethod<String, Object?>('pay', {
        'uri': uri.toString(),
        'package': AppConfig.upiOnlyGooglePay ? AppConfig.googlePayPackage : null,
      });
      return UpiResult.parse(resultOk: r?['resultOk'] == true, response: r?['response'] as String?);
    } on PlatformException catch (e) {
      if (e.code == 'NO_UPI_APP') return const UpiResult(UpiStatus.noApp);
      return UpiResult(UpiStatus.failure, raw: e.message);
    } on MissingPluginException {
      return const UpiResult(UpiStatus.noApp);
    }
  }
}

final upiServiceProvider = Provider<UpiService>((ref) => const UpiService());
