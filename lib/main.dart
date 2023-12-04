import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_payment_gatway/widget/box.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import 'package:fluttertoast/fluttertoast.dart';
import 'package:pay/pay.dart';

import 'PaymentConfigration/payment_config.dart';
import 'flutterStripe/SubsCription.dart';
import 'flutterStripe/flutter_stripe.dart';
import 'fluttersubscription/SubsCription1.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Stripe.publishableKey = "pk_test_51OA8V1JYZCpvm4VGYouV8l4KiQFAs7s5GpdlAOTPHGZyQ4kard7a5l0WZpXjyTef4VQV00spYQm3aRAhBwVyn4hl00Zn0sMlbC";
  Stripe.merchantIdentifier = "merchant.com.example.flutterPayment";
  await Stripe.instance.applySettings();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedBox = 0;
  var fstripe = Fstripe();
  String os = Platform.operatingSystem;

  var applePayButton = ApplePayButton(
    paymentConfiguration: PaymentConfiguration.fromJsonString(defaultApplePay),
    paymentItems: const [
      PaymentItem(
        label: 'Total',
        amount: '0.02',
        status: PaymentItemStatus.final_price,
      )
    ],
    // style: ApplePayButtonStyle.black,
    width: double.infinity,
    height: 50,
    // type: ApplePayButtonType.buy,
    margin: const EdgeInsets.only(top: 15.0),
    onPaymentResult: (result) => debugPrint('Payment Result $result'),
    loadingIndicator: const Center(
      child: CircularProgressIndicator(),
    ),
  );

  var googlePayButton = GooglePayButton(
    paymentConfiguration: PaymentConfiguration.fromJsonString(defaultGooglePay),
    paymentItems: const [
      PaymentItem(
        label: 'Total',
        amount: '0.01',
        status: PaymentItemStatus.final_price,
      )
    ],
    type: GooglePayButtonType.pay,
    margin: const EdgeInsets.only(top: 15.0),
    onPaymentResult: (result) => debugPrint('Payment Result $result'),
    loadingIndicator: const Center(
      child: CircularProgressIndicator(),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 50),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  Box(56, selectedBox, selectBox),
                  Box(99, selectedBox, selectBox),
                  Box(999, selectedBox, selectBox),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: ElevatedButton(
                  onPressed: () {
                    if (selectedBox > 1) {
                      fstripe.makePayment(context, selectedBox);
                    } else {
                      print("select the box");

                      Fluttertoast.showToast(msg: "please select the ammount", textColor: Colors.red, backgroundColor: Colors.grey);
                    }
                  },
                  child: Text('pay'),
                ),
              ),
              ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SubsCription1()),
                    );
                  },
                  child: Text("Subscription Screen"))
            ],
          ),
        ),
      ),
    );
  }

  void selectBox(int boxNumber) {
    setState(() {
      selectedBox = boxNumber;
    });
  }
}
