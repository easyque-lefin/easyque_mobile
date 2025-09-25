import 'package:flutter/material.dart';

class StartTrialPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // In real flow: call backend endpoint to create trial (POST /signup/trial) — here we show demo
    return Scaffold(
      appBar: AppBar(title: Text('Start 7-day trial')),
      body: Center(
        child: Card(
          margin: EdgeInsets.all(16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('Start your 7-day free trial', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 12),
              Text('Demo: call backend to start trial and create an org and user.'),
              SizedBox(height: 12),
              ElevatedButton(onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Trial started (demo). Implement API call).')));
              }, child: Text('Start trial now')),
            ]),
          ),
        ),
      ),
    );
  }
}
