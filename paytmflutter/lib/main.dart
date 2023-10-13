import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:paytm_allinonesdk/paytm_allinonesdk.dart';

void main() {

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  final TextEditingController _controller = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Paytm Integration"),
      ),
      body: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              margin: const EdgeInsets.all(20),
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.currency_rupee),
                  hintText: "Enter payable amount",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  FocusScope.of(context).requestFocus(FocusNode());
                  String amount = _controller.text.trim();
                  if (amount.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Enter amount"),
                      ),
                    );
                    return;
                  }
                  initiateTransaction(amount);
                },
                child: const Text("Pay"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void initiateTransaction(String amount) async {

    log("Function Calling 3");

     final url = Uri.parse('http://10.0.2.2:5001/api/dashboard/get-paytm-token');

    Map<String, dynamic> body = {
      'amount': 1,
    };
      log("Data: $body");
      // Send the POST request
    final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );


    log(response.body);
    log(response.statusCode.toString());
    var bodyJson = jsonDecode(response.body);

    
if(response.statusCode == 500){
       ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text(bodyJson["error"]),
           ),
         );
}
    if (response.statusCode == 200) {
      var bodyJson = jsonDecode(response.body);
      //  on success of txtoken generation api
      //  start transaction

      log("Function Calling 4");

      var response1 = AllInOneSdk.startTransaction(
        bodyJson['mid'], // merchant id  from api
        bodyJson['orderId'], // order id from api
        amount, // amount
        bodyJson['txToken'], // transaction token from api
        "", // callback url
        true, // isStaging
        false, // restrictAppInvoke
      ).then((value) {
        //  on payment completion we will verify transaction with transaction verify api
        //  after payment completion we will verify this transaction
        //  and this will be final verification for payment

        log(value.toString());
        verifyTransaction(bodyJson['orderId']);
      }).catchError((error, stackTrace) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message),
          ),
        );
      });
    } else {
      log("Function Calling 5");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.body),
        ),
      );
    }
  }

  void verifyTransaction(String orderId) async {


    Map<String, dynamic> body = {
      'orderId': orderId,
    };
      log("Data: $body");
      // Send the POST request

  //verify-paytm-transaction

  final url = Uri.parse('http://10.0.2.2:5001/api/dashboard/verify-paytm-transaction');

    final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );


    log(response.body);
    log(response.statusCode.toString());
    var bodyJson = jsonDecode(response.body);

    log(response.body);
    log(response.statusCode.toString());
// json decode
    var verifyJson = jsonDecode(response.body);
//  display result info > result msg

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(verifyJson['body']['resultInfo']['resultMsg']),
      ),
    );
  }
}
