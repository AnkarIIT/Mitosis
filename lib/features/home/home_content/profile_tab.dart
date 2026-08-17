import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/providers.dart';
import '../../../features/profile/profile_screen.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: const ProfileScreen(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await ref.read(authProvider.notifier).logout();
          if (!context.mounted) return;
          context.go('/auth');
        },
        icon: const Icon(Icons.logout),
        label: const Text('Logout'),
        backgroundColor: Colors.red.shade400,
        foregroundColor: Colors.white,
      ),
    );
  }
}
