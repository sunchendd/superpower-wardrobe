import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/clothing_repository.dart';

final clothingRepoProvider = Provider<ClothingRepository>((ref) =>
    ClothingRepository(Supabase.instance.client));

class WardrobeNotifier extends AsyncNotifier<List<ClothingItem>> {
  @override
  Future<List<ClothingItem>> build() async {
    final repo = ref.read(clothingRepoProvider);
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    if (userId.isEmpty) return [];
    return repo.getItems(userId);
  }

  Future<void> addItem(ClothingItem item) async {
    final repo = ref.read(clothingRepoProvider);
    final newItem = await repo.addItem(item);
    final current = state.value ?? [];
    state = AsyncData([newItem, ...current]);
  }

  Future<void> deleteItem(String id) async {
    final repo = ref.read(clothingRepoProvider);
    await repo.deleteItem(id);
    final current = state.value ?? [];
    state = AsyncData(current.where((i) => i.id != id).toList());
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }
}

final wardrobeProvider =
    AsyncNotifierProvider<WardrobeNotifier, List<ClothingItem>>(
        WardrobeNotifier.new);
