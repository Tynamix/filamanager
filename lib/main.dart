import 'package:filamanager/app/app_bootstrap.dart';
import 'package:filamanager/bootstrap/production_composition_root.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  runApp(
    FilaManagerBootstrap(createDependencies: ProductionCompositionRoot.create),
  );
}
