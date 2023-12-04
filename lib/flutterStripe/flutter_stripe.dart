import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

class Fstripe {
  Map<String, dynamic>? paymentIntent;

  void makePayment(BuildContext context, dynamic value) async {
    try {
      paymentIntent = await createPaymentIntent(value);
      var gpay = PaymentSheetGooglePay(merchantCountryCode: "US", currencyCode: "USD", testEnv: true);
      var applepay = PaymentSheetApplePay(
        merchantCountryCode: "US",
        buttonType: PlatformButtonType.buy,
      );
      // Initialize the payment sheet before displaying it.
      await Stripe.instance.initPaymentSheet(
        
        paymentSheetParameters: SetupPaymentSheetParameters(
          customFlow: false,
          paymentIntentClientSecret: paymentIntent!["client_secret"],
          style: ThemeMode.dark,
          merchantDisplayName: "Subhra",
          applePay: applepay,
          googlePay: gpay,
          
        ),

      );
      // displayPaymentSheet();
      displayOemnts(context);
    } catch (e) {
      print("Error: $e");
    }
  }

  void displayPaymentSheet() async {
    try {
      await Stripe.instance.presentPaymentSheet();
      print("done");
    } catch (e) {
      print("failed $e");
    }
  }

  void displayOemnts(BuildContext context) async {
    try {
      await Stripe.instance.presentPaymentSheet().then((value) {
        showDialog(
            context: context,
            builder: (_) => AlertDialog(
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 100.0,
                      ),
                      SizedBox(height: 10.0),
                      Text("Payment Successful!"),
                    ],
                  ),
                ));
        Navigator.pop(context);
        paymentIntent = null;
      }).onError((error, stackTrace) {
        throw Exception(error);
      });
    } on StripeException catch (e) {
      print('Error is:---> $e');
      AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: const [
                Icon(
                  Icons.cancel,
                  color: Colors.red,
                ),
                Text("Payment Failed"),
              ],
            ),
          ],
        ),
      );
    } catch (e) {
      print('$e');
    }
  }

  createPaymentIntent(dynamic val) async {
    try {
      Map<String, dynamic> body = {
        "amount": "${val}00",
        "currency": "USD",
      };
      http.Response response = await http.post(
        Uri.parse("https://api.stripe.com/v1/payment_intents"),
        body: body,
        headers: {
          'Authorization': 'Bearer sk_test_51OA8V1JYZCpvm4VGlgoLqKkOiOhDeyVRrlShRV7ebJwTC10tAALFEUY4ZY8KEFy8NKYzxqolJIuiCdF36ofLZX0l00eg4dL5dl',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      );
      print("daaaaataaaaaa${response.body.toString()}");
      return json.decode(response.body);
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
