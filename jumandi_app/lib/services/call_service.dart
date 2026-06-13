import 'package:url_launcher/url_launcher.dart';

import 'api_service.dart';

class CallService {
  CallService(this._api);

  final ApiService _api;
  bool _busy = false;

  Future<void> startCall(int bookingId) async {
    if (_busy) return;
    _busy = true;
    try {
      final result = await _api.initiateCall(bookingId);
      final uri = Uri.parse(result.telUri);
      final launched = await launchUrl(uri);
      if (!launched) {
        throw ApiException('Could not open the phone dialer');
      }
    } finally {
      _busy = false;
    }
  }

  Future<void> dialNumber(String phone) async {
    final digits = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$digits');
    final launched = await launchUrl(uri);
    if (!launched) {
      throw ApiException('Could not open the phone dialer');
    }
  }
}
