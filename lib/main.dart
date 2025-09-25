import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'pages/login_page.dart';
import 'pages/bookings_page.dart';
import 'pages/signup_page.dart';
import 'pages/start_trial_page.dart';
import 'pages/org_page.dart';

void main() {
  runApp(EasyQueApp());
}

class EasyQueApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>(create: (_) => AuthService()),
      ],
      child: MaterialApp(
        title: 'EasyQue',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: Root(),
        routes: {
          '/login': (_) => LoginPage(),
          '/signup': (_) => SignupPage(),
          '/start-trial': (_) => StartTrialPage(),
          '/org': (_) => OrgPage(),
          '/bookings': (_) => BookingsPage(),
        },
      ),
    );
  }
}

class Root extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    // Decide initial screen based on authentication
    if (auth.isLoggedIn) {
      return BookingsPage();
    } else {
      return LoginPage();
    }
  }
}
