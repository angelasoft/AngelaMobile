import '../models/prayer_item.dart';
import 'general_prayers_data.dart';
import 'legion_prayers_data.dart';

/// 주요 기도문 카테고리·목록.
abstract final class PrayersData {
  static const legionCategory = PrayerCategory(
    id: 'legion',
    title: '레지오 마리애 기도문',
    prayers: LegionPrayersData.prayers,
  );

  static final List<PrayerCategory> categories = [
    legionCategory,
    GeneralPrayersData.mainPrayers,
    GeneralPrayersData.monthlyPrayers,
    GeneralPrayersData.invocationPrayers,
    GeneralPrayersData.stationsPrayers,
    GeneralPrayersData.deceasedPrayers,
    GeneralPrayersData.massRitePrayers,
  ];
}
