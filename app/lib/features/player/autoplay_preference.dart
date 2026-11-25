import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/backend/backend_providers.dart';

String autoplayKey(String viewerId) => 'player.autoplay.$viewerId';

final autoplayPreferenceProvider =
    AsyncNotifierProvider.family<AutoplayPreference, bool, String>(
      AutoplayPreference.new,
    );

class AutoplayPreference extends AsyncNotifier<bool> {
  AutoplayPreference(this.viewerId);
  final String viewerId;
  @override
  Future<bool> build() async {
    final stored = await ref
        .watch(keyValueStoreProvider)
        .read(autoplayKey(viewerId));
    return stored == null || stored == 'true';
  }

  Future<void> save(bool enabled) async {
    if (state.isLoading) return;
    final previous = state;
    state = const AsyncLoading();
    try {
      await ref
          .read(keyValueStoreProvider)
          .write(autoplayKey(viewerId), enabled.toString());
      if (ref.mounted) state = AsyncData(enabled);
    } catch (_) {
      if (ref.mounted) state = previous;
      rethrow;
    }
  }
}
