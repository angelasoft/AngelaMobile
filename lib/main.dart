import 'package:flutter/material.dart';

import 'app/angela_app.dart';
import 'core/text_scale/text_scale_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TextScaleController.init();
  runApp(const AngelaApp());
}
