import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'api.dart';
import 'package:flutter/material.dart';

class PaymentService {
  Razorpay? _razorpay;
  BuildContext context;

  PaymentService(this.context) {
    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void dispose() {
    _razorpay?.clear();
  }

  Future<void> createAndOpenCheckout(Map<String, dynamic> createOrderPayload) async {
    // Call backend to create order
    final resp = await API.post('/payments/create-order', createOrderPayload);
    // expected resp: { ok:true, order_id, amount, currency, key_id }
    final orderId = resp['order_id'] ?? resp['id'];
    final keyId = resp['razorpay_key_id'] ?? resp['key_id'] ?? resp['keyId'];
    final amount = resp['amount'] ?? resp['amount_rupees']; // make sure backend returns paise if necessary

    var options = {
      'key': keyId,
      'amount': (amount is num) ? ( (resp['amount_in_paise'] != null) ? resp['amount_in_paise'] : (amount * 100).toInt() ) : amount,
      'name': 'EasyQue',
      'description': 'Initial payment',
      'order_id': orderId,
      'prefill': {'contact': '', 'email': ''},
    };

    _razorpay!.open(options);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse resp) async {
    // resp.paymentId, resp.orderId, resp.signature
    try {
      await API.post('/payments/verify', {
        'order_id': resp.orderId,
        'payment_id': resp.paymentId,
        'signature': resp.signature
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment verified successfully')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment verify failed: $e')));
    }
  }

  void _handlePaymentError(PaymentFailureResponse resp) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment failed: ${resp.message}')));
  }

  void _handleExternalWallet(ExternalWalletResponse resp) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('External wallet: ${resp.walletName}')));
  }
}
