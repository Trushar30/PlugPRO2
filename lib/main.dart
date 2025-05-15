import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:plugpro/models/user_model.dart';
import 'package:plugpro/models/worker_model.dart';
import 'package:plugpro/models/service_model.dart';
import 'package:plugpro/models/booking_model.dart';
import 'package:plugpro/models/subscription_model.dart';
import 'package:plugpro/providers/auth_provider.dart';
import 'package:plugpro/providers/service_provider.dart';
import 'package:plugpro/providers/booking_provider.dart';
import 'package:plugpro/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Register Hive adapters
  Hive.registerAdapter(UserAdapter());
  Hive.registerAdapter(WorkerAdapter());
  Hive.registerAdapter(ServiceAdapter());
  Hive.registerAdapter(BookingAdapter());
  Hive.registerAdapter(SubscriptionAdapter());
  
  // Open Hive boxes
  await Hive.openBox<User>('users');
  await Hive.openBox<Worker>('workers');
  await Hive.openBox<Service>('services');
  await Hive.openBox<Booking>('bookings');
  await Hive.openBox<Subscription>('subscriptions');
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ServiceProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
      ],
      child: MaterialApp(
        title: 'PlugPRO',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          fontFamily: 'Poppins',
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
