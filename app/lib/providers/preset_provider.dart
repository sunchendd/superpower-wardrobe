import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/preset_repository.dart';

final presetRepoProvider = Provider<PresetRepository>((ref) =>
    PresetRepository(Supabase.instance.client));

final presetProvider = FutureProvider<List<PresetOutfit>>((ref) async {
  final repo = ref.read(presetRepoProvider);
  return repo.getAll();
});
