import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';

const String _kSilverSubscriptionId = 'Qwert_123456';
const String _kGoldSubscriptionId = 'Qwert_17112023';
const List<String> _kProductIds = <String>[
  _kSilverSubscriptionId,
  _kGoldSubscriptionId,
];

class SubscriptionProvider with ChangeNotifier {
  bool _purchasing = false;

  bool get isPurchasing => _purchasing;

  setPurchasing(bool value) {
    notifyListeners();
    _purchasing = value;
    notifyListeners();
  }
}

class SubsCription1 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SubscriptionProvider>(
      create: (context) => SubscriptionProvider(),
      child: MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Subscription Example'),
          ),
          body: _SubsCriptionStateApp(),
        ),
      ),
    );
  }
}

class _SubsCriptionStateApp extends StatefulWidget {
  @override
  State<_SubsCriptionStateApp> createState() => SubsCriptionState();
}

class SubsCriptionState extends State<_SubsCriptionStateApp> {
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;

  List<ProductDetails> _products = <ProductDetails>[];
  bool _isAvailable = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();

    _subscription = _inAppPurchase.purchaseStream.listen(
      (List<PurchaseDetails> purchaseDetailsList) {
        context.read<SubscriptionProvider>().setPurchasing(false);
        _listenToPurchaseUpdated(purchaseDetailsList);
      },
      onDone: () {},
      onError: (Object error) {
        // Handle error here.
        print("Error == > ${error.toString()}");
      },
    );

    initStoreInfo();
  }

  Future<void> initStoreInfo() async {
    final bool isAvailable = await _inAppPurchase.isAvailable();
    if (!isAvailable) {
      setState(() {
        _isAvailable = isAvailable;
        _products = <ProductDetails>[];
        _loading = false;
      });
      return;
    }

    final ProductDetailsResponse productDetailResponse = await _inAppPurchase.queryProductDetails(_kProductIds.toSet());
    if (productDetailResponse.error != null) {
      setState(() {
        _isAvailable = isAvailable;
        _products = productDetailResponse.productDetails;
        _loading = false;
      });
      return;
    }

    setState(() {
      _isAvailable = isAvailable;
      _products = productDetailResponse.productDetails;
      _loading = false;
    });
  }

  @override
  void dispose() {
    // _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> stack = <Widget>[];

    stack.add(
      ListView(
        children: <Widget>[
          _buildConnectionCheckTile(),
          _buildProductList(),
        ],
      ),
    );

    if (context.watch<SubscriptionProvider>().isPurchasing) {
      stack.add(
        Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Stack(children: stack);
  }

  Card _buildConnectionCheckTile() {
    if (_loading) {
      return const Card(child: ListTile(title: Text('Trying to connect...')));
    }

    final Widget storeHeader = ListTile(
      leading: Icon(_isAvailable ? Icons.check : Icons.block, color: _isAvailable ? Colors.green : ThemeData.light().colorScheme.error),
      title: Text('The store is ${_isAvailable ? 'available' : 'unavailable'}.'),
    );

    final List<Widget> children = <Widget>[
      storeHeader
    ];

    if (!_isAvailable) {
      children.addAll(<Widget>[
        const Divider(),
        ListTile(
          title: Text('Not connected', style: TextStyle(color: ThemeData.light().colorScheme.error)),
          subtitle: const Text('Unable to connect to the payments processor. Has this app been configured correctly?'),
        ),
      ]);
    }

    return Card(child: Column(children: children));
  }

  Card _buildProductList() {
    if (_loading) {
      return const Card(child: ListTile(leading: CircularProgressIndicator(), title: Text('Fetching products...')));
    }

    if (!_isAvailable) {
      return const Card();
    }

    final ListTile productHeader = ListTile(title: Text('Subscription Products'));
    final List<ListTile> productList = <ListTile>[];

    productList.addAll(_products.map(
      (ProductDetails productDetails) {
        return ListTile(
          title: Text(
            productDetails.title,
          ),
          subtitle: Text(
            productDetails.description,
          ),
          trailing: TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.green[800],
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              _buySubscription(productDetails);
            },
            child: Text(productDetails.price),
          ),
        );
      },
    ));

    return Card(
        child: Column(
            children: <Widget>[
                  productHeader,
                  const Divider()
                ] +
                productList));
  }

  void _buySubscription(ProductDetails productDetails) async {
    await Future.delayed(Duration(milliseconds: 500));
    context.read<SubscriptionProvider>().setPurchasing(true);

    try {
      final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);

      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      await Future.delayed(Duration(seconds: 5));
    } catch (e) {
      // Handle other errors.
      print("Error: $e");
    }
    context.read<SubscriptionProvider>().setPurchasing(false);
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) async {
    await Future.delayed(Duration(milliseconds: 500));
    context.read<SubscriptionProvider>().setPurchasing(true);

    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Handle pending purchase here if needed.
        if (purchaseDetails.pendingCompletePurchase) {
          // There is a pending transaction, complete it.
          await _inAppPurchase.completePurchase(purchaseDetails);
        }
      } else if (purchaseDetails.status == PurchaseStatus.canceled) {
        print("Subscription canceled");
        print("Subscription status: ${purchaseDetails.status}");

        if (purchaseDetails.pendingCompletePurchase) {
          // There is a pending transaction, complete it.
          await _inAppPurchase.completePurchase(purchaseDetails);
        }
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        if (purchaseDetails.error != null) {
          final platformException = purchaseDetails.error;
          print("Subscription error: ${platformException?.message}");

          // Check if the error code indicates subscription user cancellation
          if (platformException?.code == 'storekit_subscription_user_cancelled') {
            print("Subscription canceled by the user on the App Store");
            // You can handle this case accordingly.
          }
        }
      } else if (purchaseDetails.status == PurchaseStatus.purchased) {
        print("Subscription purchased successfully");
        // Handle other details if needed.
        print("subscription purchaseID = >${purchaseDetails.purchaseID}");
        print("subscription status = >${purchaseDetails.status}");
        print("subscription localVerificationData = >${purchaseDetails.verificationData.localVerificationData}");
        print("subscription serverVerificationData = >${purchaseDetails.verificationData.serverVerificationData}");
        print("subscription transactionDate = >${purchaseDetails.transactionDate}");
        if (purchaseDetails.pendingCompletePurchase) {
          // There is a pending transaction, complete it.
          await _inAppPurchase.completePurchase(purchaseDetails);
        }
      } else if (purchaseDetails.status == PurchaseStatus.restored) {
        print("Subscription restored");
      }
    }
    await Future.delayed(Duration(milliseconds: 500));
    context.read<SubscriptionProvider>().setPurchasing(false);
  }
}
