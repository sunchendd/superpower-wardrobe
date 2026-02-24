import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';

const _supabaseUrl = 'https://gdoqygotjkxedkptimyh.supabase.co';
const _supabaseAnonKey = 'sb_publishable_3ghgg1OkB541HcuqXqexIw_7aybcyjP';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: _supabaseUrl,
    anonKey: _supabaseAnonKey,
  );
  runApp(const ProviderScope(child: SuperpowerWardrobeApp()));
}
