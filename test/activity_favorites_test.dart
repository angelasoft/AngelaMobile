import 'package:angelamobile/features/activity_report/activity_favorites.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('저장 전에는 기본 이름만 즐겨찾기', () async {
    await ActivityFavorites.load();
    expect(ActivityFavorites.isFavorite(1, '묵주기도'), isTrue);
    expect(ActivityFavorites.isFavorite(2, '병문안'), isFalse);
  });

  test('저장한 즐겨찾기는 다시 불러와도 유지된다', () async {
    await ActivityFavorites.load();
    await ActivityFavorites.save({2, 5});

    SharedPreferences.setMockInitialValues({
      'activity_report.favoriteIds': ['2', '5'],
    });
    await ActivityFavorites.load();

    expect(ActivityFavorites.isFavorite(2, '병문안'), isTrue);
    expect(ActivityFavorites.isFavorite(5, '기타'), isTrue);
    expect(ActivityFavorites.isFavorite(1, '묵주기도'), isFalse);
  });
}
