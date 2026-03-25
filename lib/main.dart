import 'package:flutter/material.dart';
import 'package:logbook_app_001/features/onboarding/onboarding_view.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logbook_app_001/features/logbook/models/log_model.dart';
import 'package:logbook_app_001/features/logbook/models/object_id_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logbook_app_001/features/logbook/log_view.dart';

void main() async {
  // Wajib untuk operasi asinkron sebelum runApp
  WidgetsFlutterBinding.ensureInitialized();
  // Load ENV
  await dotenv.load(fileName: ".env");
  // Di main.dart
  await Hive.initFlutter();

  // Inisialisasi locale Indonesia untuk format tanggal intl
  await initializeDateFormatting('id', null);

  // Daftarkan Adapter untuk ObjectId terelebih dahulu
  Hive.registerAdapter(ObjectIdAdapter());

  // Baru daftarkan Adapter untuk LogModel
  Hive.registerAdapter(LogModelAdapter());
  await Hive.openBox<LogModel>('offline_logs');

  // Mengecek User Login State Pakai SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('is_logged_in') ?? false;

  Widget initialScreen = const OnboardingView();

  if (isLoggedIn) {
    final username = prefs.getString('username') ?? '';
    final userId = prefs.getString('user_id') ?? '';
    final role = prefs.getString('role') ?? '';

    initialScreen = CounterView(
      username: username,
      userId: userId,
      role: role,
      teamId: prefs.getString('team_id') ?? 'MEKTRA_KLP_01',
    );
  }

  runApp(MyApp(initialScreen: initialScreen));
}

class MyApp extends StatelessWidget {
  final Widget initialScreen;
  const MyApp({super.key, required this.initialScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      home: initialScreen,
    );
  }
}
