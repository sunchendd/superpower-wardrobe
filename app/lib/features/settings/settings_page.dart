import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('个人设置'), centerTitle: true),
      body: ListView(
        children: [
          const SizedBox(height: 16),

          // User info
          ListTile(
            leading: CircleAvatar(
              child: Text(
                user?.email?.isNotEmpty == true
                    ? user!.email![0].toUpperCase()
                    : '?',
              ),
            ),
            title: Text(user?.email ?? '未登录'),
            subtitle: const Text('Superpower Wardrobe 账号'),
          ),

          const Divider(),

          // Location
          ListTile(
            leading: const Icon(Icons.location_city),
            title: const Text('所在城市'),
            subtitle: const Text('Shanghai'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('城市设置（即将支持）')),
            ),
          ),

          // Style preference
          ListTile(
            leading: const Icon(Icons.style),
            title: const Text('偏好风格'),
            subtitle: const Text('日常休闲'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('风格偏好（即将支持）')),
            ),
          ),

          const Divider(),

          // App info
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('版本'),
            subtitle: Text('v1.0.0 MVP'),
          ),

          const Divider(),

          // Sign out
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('退出登录',
                style: TextStyle(color: Colors.red)),
            onTap: () async {
              await Supabase.instance.client.auth.signOut();
            },
          ),

          const SizedBox(height: 32),
          Center(
            child: Text(
              'Superpower Wardrobe v1.0.0',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
