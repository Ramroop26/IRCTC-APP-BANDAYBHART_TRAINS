import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/auth_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/train_search_screen.dart';
import 'screens/booking_details_screen.dart';
import 'screens/payment_screen.dart';
import 'screens/ticket_screen.dart';
import 'screens/live_status_screen.dart';
import 'screens/pnr_status_screen.dart';
import 'screens/wallet_screen.dart';
import 'screens/order_history_screen.dart';
import 'screens/architecture_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/notification_screen.dart';
import 'screens/chatbot_screen.dart';

void main() {
  runApp(const IRCTCApp());
}

class IRCTCApp extends StatelessWidget {
  const IRCTCApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IRCTC APP',
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/train_search': (context) => const TrainSearchScreen(),
        '/booking_details': (context) => const BookingDetailsScreen(),
        '/payment': (context) => const PaymentScreen(),
        '/ticket_detail': (context) => const TicketDetailScreen(),
        '/live_status': (context) => const LiveStatusScreen(),
        '/pnr_status': (context) => const PnrStatusScreen(),
        '/wallet': (context) => const WalletScreen(),
        '/order_history': (context) => const OrderHistoryScreen(),
        '/architecture': (context) => const ArchitectureScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/notifications': (context) => const NotificationScreen(),
        '/chatbot': (context) => const ChatbotScreen(),
      },
    );
  }
}
