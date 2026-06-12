import 'package:progressio_mobile/providers/base_provider.dart';

class PaymentProvider extends BaseProvider<Object> {
  PaymentProvider() : super('payments');

  @override
  Object fromJson(dynamic json) => json;

 
  Future<String> createPaymentIntent(String planType) async {
    final data = await postRaw('payments/create-intent', {'planType': planType});
    return data['clientSecret'] as String;
  }
}