import 'dart:async';

import 'package:filamanager/app/app.dart';
import 'package:filamanager/app/app_dependencies.dart';
import 'package:filamanager/app/fila_components.dart';
import 'package:filamanager/app/fila_theme.dart';
import 'package:flutter/material.dart';

final class FilaManagerBootstrap extends StatefulWidget {
  const FilaManagerBootstrap({required this.createDependencies, super.key});

  final Future<AppDependencies> Function() createDependencies;

  @override
  State<FilaManagerBootstrap> createState() => _FilaManagerBootstrapState();
}

final class _FilaManagerBootstrapState extends State<FilaManagerBootstrap> {
  AppDependencies? _dependencies;
  Object? _openError;
  var _opening = true;

  @override
  void initState() {
    super.initState();
    unawaited(_open());
  }

  Future<void> _open() async {
    setState(() {
      _opening = true;
      _openError = null;
    });
    try {
      final dependencies = await widget.createDependencies();
      if (mounted) {
        setState(() {
          _dependencies = dependencies;
          _opening = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _openError = error;
          _opening = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dependencies = _dependencies;
    if (dependencies != null) {
      return FilaManagerApp(dependencies: dependencies);
    }
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FilaManager',
      theme: FilaTheme.light,
      home: Scaffold(
        backgroundColor: FilaColors.canvas,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _opening
                    ? const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Opening local inventory'),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const FilaEyebrow('Local inventory'),
                          const SizedBox(height: 8),
                          Semantics(
                            liveRegion: true,
                            header: true,
                            child: Text(
                              'Inventory could not be opened',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                          ),
                          const SizedBox(height: 18),
                          const FilaCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: FilaColors.error,
                                ),
                                SizedBox(height: 10),
                                Text(
                                  'Local inventory data was left unchanged.',
                                ),
                                SizedBox(height: 6),
                                Text('Check device storage, then try again.'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          FilledButton(
                            onPressed: _open,
                            child: const Text('Retry opening inventory'),
                          ),
                          ExpansionTile(
                            title: const Text('Diagnostics'),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: SelectableText(_openError.toString()),
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
