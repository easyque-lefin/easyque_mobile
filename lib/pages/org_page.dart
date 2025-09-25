import 'package:flutter/material.dart';
import '../services/api.dart';

class OrgPage extends StatefulWidget {
  @override
  _OrgPageState createState() => _OrgPageState();
}

class _OrgPageState extends State<OrgPage> {
  List fees = [];
  String keyInput = '';
  String valInput = '';
  String msg = '';

  @override
  void initState() {
    super.initState();
    loadFees();
  }

  Future<void> loadFees() async {
    setState(() { msg = 'Loading...'; });
    try {
      final r = await API.get('/admin/fees'); // adjust if your backend route is different
      setState(() {
        fees = r['fees'] ?? r ?? [];
        msg = '';
      });
    } catch (e) {
      setState(() { msg = 'Load failed: $e'; });
    }
  }

  Future<void> saveFee() async {
    setState(() { msg = 'Saving...'; });
    try {
      await API.post('/admin/fees', {'key': keyInput, 'value': valInput});
      setState(() { keyInput = ''; valInput = ''; });
      await loadFees();
    } catch (e) {
      setState(() { msg = 'Save failed: $e'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Fee settings')),
      body: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            Text('Fee settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Expanded(child: SingleChildScrollView(child: Text(fees.toString()))),
            TextField(decoration: InputDecoration(labelText: 'Key'), onChanged: (v)=>keyInput=v),
            TextField(decoration: InputDecoration(labelText: 'Value'), onChanged: (v)=>valInput=v),
            SizedBox(height: 8),
            ElevatedButton(onPressed: saveFee, child: Text('Save')),
            SizedBox(height: 8),
            Text(msg),
          ],
        ),
      ),
    );
  }
}
