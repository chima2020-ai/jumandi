import 'api_service.dart';
import 'link_launcher.dart';

class CallService {
  CallService(this._api);

  final ApiService _api;
  bool _busy = false;

  Future<void> startCall(int bookingId) async {
    if (_busy) return;
    _busy = true;
    try {
      final result = await _api.initiateCall(bookingId);
      final launched = await LinkLauncher.openTel(result.telUri);
      if (!launched) {
        throw ApiException('Could not open the phone dialer');
      }
    } finally {
      _busy = false;
    }
  }

  Future<void> dialNumber(String phone) async {
    final digits = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final launched = await LinkLauncher.openTel('tel:$digits');
    if (!launched) {
      throw ApiException('Could not open the phone dialer');
    }
  }
}
