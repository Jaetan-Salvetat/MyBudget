import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mybudget/core/enums/revenue_group_by.dart';
import 'package:mybudget/data/service/preferences_service.dart';
import 'package:mybudget/ui/shared/revenues_view_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PreferencesService.init();
  });

  test('starts on the frequency axis', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(revenuesGroupByProvider), RevenueGroupBy.frequency);
  });

  test('restores the persisted axis', () async {
    SharedPreferences.setMockInitialValues({
      PreferencesService.keyRevenuesGroupBy: RevenueGroupBy.category.name,
    });
    await PreferencesService.init();
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(revenuesGroupByProvider), RevenueGroupBy.category);
  });

  test('set exposes and persists the new axis', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container
        .read(revenuesGroupByProvider.notifier)
        .set(RevenueGroupBy.beneficiary);

    expect(container.read(revenuesGroupByProvider), RevenueGroupBy.beneficiary);
    expect(
      PreferencesService.getRevenuesGroupBy(),
      RevenueGroupBy.beneficiary.name,
    );
  });
}
