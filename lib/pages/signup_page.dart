import 'package:flutter/material.dart';
import '../services/api.dart';

class SignupPage extends StatefulWidget {
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  String mode = 'semi';
  final usersCtrl = TextEditingController(text: '10');
  final bookingsCtrl = TextEditingController(text: '500');
  final emailCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  String? message;

  Future<void> calculate() async {
    setState(() { message = 'Calculating...'; });
    try {
      final q = '?messaging_mode=${Uri.encodeComponent(mode)}&expected_users=${Uri.encodeComponent(usersCtrl.text)}&expected_bookings_per_day=${Uri.encodeComponent(bookingsCtrl.text)}';
      final resp = await API.get('/payments/calc' + q);
      setState(() { message = 'Estimated initial amount: ₹' + (resp['amount_rupees']?.toString() ?? resp['amount']?.toString() ?? 'NA'); });
      // save payload to local storage or pass next
      // here we'll navigate to start-trial or payment
      // For demo, navigate to start-trial page:
      await Future.delayed(Duration(milliseconds: 800));
      Navigator.of(context).pushNamed('/start-trial');
    } catch (e) {
      setState(() { message = 'Calc failed: $e'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sign Up Now')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Container(
          width: 720,
          child: Column(
            children: [
              Row(children: [
                Expanded(child: ListTile(
                  title: Text('Semi-Automatic'),
                  leading: Radio(value: 'semi', groupValue: mode, onChanged: (v) => setState(()=> mode = v as String)),
                )),
                Expanded(child: ListTile(
                  title: Text('Full-Automatic'),
                  leading: Radio(value: 'full', groupValue: mode, onChanged: (v) => setState(()=> mode = v as String)),
                )),
              ]),
              TextField(controller: usersCtrl, decoration: InputDecoration(labelText: 'Number of users')),
              if (mode == 'full') TextField(controller: bookingsCtrl, decoration: InputDecoration(labelText: 'Expected bookings per day')),
              TextField(controller: emailCtrl, decoration: InputDecoration(labelText: 'Email')),
              TextField(controller: nameCtrl, decoration: InputDecoration(labelText: 'Name (optional)')),
              SizedBox(height: 12),
              ElevatedButton(onPressed: calculate, child: Text('Continue to payment')),
              SizedBox(height: 8),
              OutlinedButton(onPressed: () => Navigator.of(context).pushNamed('/start-trial'), child: Text('Start 7 days free trial')),
              if (message != null) Padding(padding: EdgeInsets.only(top:12), child: Text(message!)),
            ],
          ),
        ),
      ),
    );
  }
}
