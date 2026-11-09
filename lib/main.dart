import 'package:flutter/material.dart';

import 'app/angela_app.dart';
import 'core/presidium/current_presidium.dart';
import 'core/push/push_service.dart';
import 'core/text_scale/text_scale_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TextScaleController.init();
  await CurrentPresidium.init();
  await PushService.instance.init();
  runApp(const AngelaApp());
}
