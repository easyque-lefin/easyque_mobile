import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);
    return Scaffold(
      appBar: AppBar(title: Text('EasyQue — Login')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Container(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: _email, decoration: InputDecoration(labelText: 'Email')),
                TextField(controller: _password, decoration: InputDecoration(labelText: 'Password'), obscureText: true),
                SizedBox(height: 12),
                if (_error != null) Text(_error!, style: TextStyle(color: Colors.red)),
                SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _loading ? null : () async {
                    setState(() { _loading = true; _error = null; });
                    try {
                      await auth.login(_email.text.trim(), _password.text);
                      Navigator.of(context).pushReplacementNamed('/bookings');
                    } catch (e) {
                      setState(() { _error = e.toString(); });
                    } finally {
                      setState(() { _loading = false; });
                    }
                  },
                  child: _loading ? CircularProgressIndicator() : Text('Login'),
                ),
                SizedBox(height: 10),
                TextButton(onPressed: () => Navigator.of(context).pushNamed('/signup'), child: Text('Sign Up')),
                TextButton(onPressed: () => Navigator.of(context).pushNamed('/start-trial'), child: Text('Start 7-day trial')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
