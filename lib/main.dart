import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'features/transactions/ui/transactions_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PFMS',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final user = snapshot.data;
          if (user == null) {
            return const AuthTestPage();
          }

          return const TransactionsPage();
        },
      ),
    );
  }
}

class AuthTestPage extends StatefulWidget {
  const AuthTestPage({super.key});

  @override
  State<AuthTestPage> createState() => _AuthTestPageState();
}

class _AuthTestPageState extends State<AuthTestPage> {
  String _status = 'Chưa đăng nhập';

  Future<void> _loginAnonymous() async {
    setState(() => _status = 'Đang login...');
    try {
      final cred = await FirebaseAuth.instance.signInAnonymously();
      final token = await cred.user!.getIdToken(true);

      // ignore: avoid_print
      print('FIREBASE_ID_TOKEN=$token');

      if (!mounted) return;
      setState(() => _status = 'Login OK ✅ uid=${cred.user!.uid}');
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = 'Login FAIL ❌ $e');
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    setState(() => _status = 'Đã logout');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PFMS - Auth Test')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_status, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loginAnonymous,
              child: const Text('Login (Anonymous)'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _logout,
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}