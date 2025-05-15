import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plugpro/providers/auth_provider.dart';
import 'package:plugpro/providers/service_provider.dart';
import 'package:plugpro/screens/auth/login_screen.dart';
import 'package:plugpro/screens/user/user_home_screen.dart';
import 'package:plugpro/screens/worker/worker_home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Initialize demo data
    await Provider.of<ServiceProvider>(context, listen: false).initializeDemoData();
    
    // Check authentication status
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Simulate loading delay
    await Future.delayed(const Duration(seconds: 2));
    
    if (authProvider.isAuthenticated) {
      if (authProvider.currentRole == UserRole.user) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const UserHomeScreen()),
        );
      } else if (authProvider.currentRole == UserRole.worker) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const WorkerHomeScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 150,
              height: 150,
            ),
            const SizedBox(height: 24),
            const Text(
              'PlugPRO',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Home Services Provider',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
