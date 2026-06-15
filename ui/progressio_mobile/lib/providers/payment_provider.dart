import 'package:progressio_mobile/providers/base_provider.dart';

class PaymentProvider extends BaseProvider<Object> {
  PaymentProvider() : super('payments');

  @override
  Object fromJson(dynamic json) => json;

  Future<Map<String, dynamic>> createPaymentIntent(String planType) async {
    final data = await postRaw('payments/create-intent', {'planType': planType});
    return Map<String, dynamic>.from(data as Map);
  }

  Future<Map<String, dynamic>?> getLatestPayment() async {
    final data = await getRaw('payments/me/latest');
    if (data == null) return null;
    return Map<String, dynamic>.from(data as Map);
  }

  Future<Map<String, dynamic>> refund(int paymentId) async {
    final data = await postRaw('payments/refund', {'paymentId': paymentId});
    return Map<String, dynamic>.from(data as Map);
  }
}