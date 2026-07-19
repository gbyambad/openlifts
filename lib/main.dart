import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openlifts/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // A lifting log is a portrait, one-handed app — lock it so foldables and
  // rotated devices can't hand the UI a landscape coordinate space.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  // ProviderScope is the root of Riverpod's state graph.
  runApp(const ProviderScope(child: OpenLiftsApp()));
}
