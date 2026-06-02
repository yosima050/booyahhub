import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'core/theme.dart';
import 'core/routes.dart';
import 'shared/models/models.dart';
import 'package:booyahhub/features/notification/notification_screen.dart';
import 'package:booyahhub/features/search/search_screen.dart';

import 'services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
    // Aktifkan realtime
    realtimeClientOptions: const RealtimeClientOptions(
      logLevel: RealtimeLogLevel.info,
    ),
  );

  // Self-Healing Trigger: Jika user sudah dalam keadaan login di perangkat,
  // jalankan sinkronisasi untuk mereparasi profil public.users jika hilang.
  if (Supabase.instance.client.auth.currentUser != null) {
    AuthService.syncOrCreateUserProfile();
  }

  runApp(const BooyahHubApp());
}

final supabase = Supabase.instance.client;

class BooyahHubApp extends StatelessWidget {
  const BooyahHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Cek session aktif
    String initialRoute = AppRoutes.welcome;

    final user = supabase.auth.currentUser;
    if (user != null) {
      final metadata = user.userMetadata;
      final role = (metadata != null && metadata.containsKey('role'))
          ? metadata['role'] as String
          : 'peserta';

      initialRoute = role == 'platform'
          ? AppRoutes.homeForRole(UserRole.platform)
          : AppRoutes.homeForRole(UserRole.peserta);
    }

    return MaterialApp(
      title: 'BooyahHub',
      debugShowCheckedModeBanner: false,
      theme: BooyahTheme.dark(),
      initialRoute: initialRoute,
      routes: {
        ...AppRoutes.routes,

        '/notification': (context) => const NotificationScreen(),
        '/search': (context) => const SearchScreen(),
      },
    );
  }
}
