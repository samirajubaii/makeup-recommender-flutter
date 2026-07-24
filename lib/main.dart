import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/product_provider.dart';
import 'providers/recommendation_provider.dart';
import 'providers/catalog_provider.dart'; // ✅ ADD THIS
import 'providers/admin_provider.dart';
import 'theme/theme.dart';
import 'screens/home/home_screen.dart';
import 'screens/splash_screen.dart';


void main() {
  runApp(const MakeupApp());
}

class MakeupApp extends StatelessWidget {
  const MakeupApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => RecommendationProvider()),
        ChangeNotifierProvider(create: (_) => CatalogProvider()), // ✅ ADD THIS
        ChangeNotifierProvider(create: (_) => AdminProvider()),

      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Makeup Store',
        theme: buildTheme(),
        routes: {
          "/": (_) => const SplashScreen(),
        },
        initialRoute: "/",
      ),
    );
  }
}


