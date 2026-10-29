import 'package:flutter/services.dart';

import '../models/prayer_item.dart';
import 'prayer_text_parser.dart';

/// 주요 기도문 탭. 내용은 assets/prayers 의 텍스트 파일에서 읽는다.
abstract final class PrayersData {
  static const tabs = [
    (id: 'legion', title: '레지오 마리애 기도문', asset: 'assets/prayers/00_legion.txt'),
    (id: 'main', title: '주요기도', asset: 'assets/prayers/01_main.txt'),
    (id: 'monthly', title: '성월기도', asset: 'assets/prayers/02_monthly.txt'),
    (id: 'litany', title: '호칭기도', asset: 'assets/prayers/03_litany.txt'),
    (id: 'various', title: '여러가지기도', asset: 'assets/prayers/04_various.txt'),
    (id: 'confession', title: '고해성사', asset: 'assets/prayers/05_confession.txt'),
    (id: 'rosary', title: '묵주기도', asset: 'assets/prayers/06_rosary.txt'),
    (id: 'stations', title: '십자가의 길', asset: 'assets/prayers/07_stations.txt'),
  ];

  static Future<List<PrayerCategory>>? _cache;

  static Future<List<PrayerCategory>> load([AssetBundle? bundle]) {
    return _cache ??= _load(bundle ?? rootBundle).catchError((Object e) {
      _cache = null;
      throw e;
    });
  }

  static Future<List<PrayerCategory>> _load(AssetBundle bundle) async {
    return [
      for (final tab in tabs)
        PrayerCategory(
          id: tab.id,
          title: tab.title,
          prayers: PrayerTextParser.parse(tab.id, await bundle.loadString(tab.asset)),
        ),
    ];
  }
}
