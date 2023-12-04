import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

const String _kSilverSubscriptionId = 'Qwert_123456';
const String _kGoldSubscriptionId = 'Qwert_17112023';
const List<String> _kProductIds = <String>[
  _kSilverSubscriptionId,
  _kGoldSubscriptionId,
];

class SubsCription extends StatefulWidget {
  @override
  State<SubsCription> createState() => SubsCriptionState();
}

class SubsCriptionState extends State<SubsCription> {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  List<ProductDetails> _products = <ProductDetails>[];
  bool _isAvailable = false;
  bool _loading = true;
  bool _purchasing = false;

  @override
  void initState() {
    super.initState();

    _subscription = _inAppPurchase.purchaseStream.listen(
        (List<PurchaseDetails> purchaseDetailsList) {
          _listenToPurchaseUpdated(purchaseDetailsList);
        },
        onDone: () {},
        onError: (Object error) {
          // Handle error here.
          print("Error == > ${error.toString()}");
        });
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
    if (_purchasing) {
      stack.add(
        Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Subscription Example'),
          leading: InkWell(
            onTap: () {
              Navigator.pop(context);
            },
            child: Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
            ),
          ),
        ),
        body: Stack(children: stack),
      ),
    );
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
    setState(() {
      _purchasing = true;
    });
    try {
      final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);

      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      await Future.delayed(Duration(seconds: 5));
    } catch (e) {
      // Handle other errors.
      print("Error: $e");
    }

    setState(() {
      _purchasing = false;
    });
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) async {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Handle pending purchase here if needed.
        if (purchaseDetails.pendingCompletePurchase) {
          // There is a pending transaction, complete it.
          await _inAppPurchase.completePurchase(purchaseDetails);
        }
      } else if (purchaseDetails.status == PurchaseStatus.canceled) {
        print("subscription canceled");

        print(purchaseDetails.toString());

        if (purchaseDetails.pendingCompletePurchase) {
          // There is a pending transaction, complete it.
          await _inAppPurchase.completePurchase(purchaseDetails);
        }
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        // Handle error here.
        print(purchaseDetails.toString());
        print("subscription error");
      } else if (purchaseDetails.status == PurchaseStatus.purchased) {
        // Handle purchased or restored subscription here.
        // Youct if needed.u can verify the purchase and deliver the prod
        print("subscription purchaseID = >${purchaseDetails.purchaseID}");
        print("subscription purchaseID = >${purchaseDetails.status}");
        print("subscription purchaseID = >${purchaseDetails.verificationData.localVerificationData}");
        print("subscription purchaseID = >${purchaseDetails.verificationData.serverVerificationData}");
        print("subscription purchaseID = >${purchaseDetails.transactionDate}");

        if (purchaseDetails.pendingCompletePurchase) {
          // There is a pending transaction, complete it.
          await _inAppPurchase.completePurchase(purchaseDetails);
        }
      } else if (purchaseDetails.status == PurchaseStatus.restored) {
        print(purchaseDetails.toString());
      }
    }
  }
}
