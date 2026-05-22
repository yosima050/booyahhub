import 'package:flutter/material.dart';
import '../../core/theme.dart';

class TentangAplikasiScreen extends StatelessWidget {
  const TentangAplikasiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TENTANG APLIKASI'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: BooyahTheme.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: BooyahTheme.maroon.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: const [
              Icon(
                Icons.sports_esports,
                size: 70,
                color: BooyahTheme.maroonB,
              ),
              SizedBox(height: 16),
              Text(
                'BOOYAHHUB',
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Platform turnamen dan scrim esports untuk para player kompetitif.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: BooyahTheme.textMuted,
                  fontSize: 13,
                ),
              ),
              SizedBox(height: 24),
              Divider(),
              SizedBox(height: 12),
              Text(
                'Versi Aplikasi',
                style: TextStyle(
                  color: BooyahTheme.textMuted,
                  fontSize: 11,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'v1.0.0',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}