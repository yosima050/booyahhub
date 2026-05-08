import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'core/theme.dart';
import 'core/routes.dart';
import 'shared/models/models.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url:     SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
    // Aktifkan realtime
    realtimeClientOptions: const RealtimeClientOptions(
      logLevel: RealtimeLogLevel.info,
    ),
  );

  runApp(const BooyahHubApp());
}

final supabase = Supabase.instance.client;

class BooyahHubApp extends StatelessWidget {
  const BooyahHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Cek session aktif
    String initialRoute = AppRoutes.login;

// Check session and user safely
    final user = supabase.auth.currentUser;
    if (user != null) {
      // Use a null-safe approach for metadata
      final metadata = user.userMetadata;
      final role = (metadata != null && metadata.containsKey('role')) 
          ? metadata['role'] as String 
          : 'peserta'; // Default role if metadata is missing

      initialRoute = AppRoutes.homeForRole(
        role == 'admin'    ? UserRole.admin    :
        role == 'platform' ? UserRole.platform : UserRole.peserta,
      );
    }

    return MaterialApp(
      title: 'BooyahHub',
      debugShowCheckedModeBanner: false,
      theme: BooyahTheme.dark(),
      initialRoute: initialRoute,
      routes: AppRoutes.routes,
    );
  }
}
