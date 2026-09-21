import 'dart:async';

import 'package:filamanager/app/app_dependencies.dart';
import 'package:filamanager/services/nfc_service.dart';
import 'package:flutter/material.dart';

final class FilaManagerApp extends StatelessWidget {
  const FilaManagerApp({required this.dependencies, super.key});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FilaManager',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF325D49)),
        useMaterial3: true,
      ),
      home: _InventoryShell(dependencies: dependencies),
    );
  }
}

final class _InventoryShell extends StatefulWidget {
  const _InventoryShell({required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<_InventoryShell> createState() => _InventoryShellState();
}

final class _InventoryShellState extends State<_InventoryShell> {
  var _selectedIndex = 0;
  late final StreamSubscription<NfcEvent> _nfcEvents;
  late final StreamSubscription<Uri> _incomingLinks;

  @override
  void initState() {
    super.initState();
    _nfcEvents = widget.dependencies.nfcService.events.listen((event) {
      switch (event) {
        case NfcUriPayloadRead():
          _showExternalInput('NFC input received');
      }
    });
    _incomingLinks = widget.dependencies.incomingLinkService.links.listen((_) {
      _showExternalInput('Incoming link received');
    });
  }

  @override
  void dispose() {
    unawaited(_nfcEvents.cancel());
    unawaited(_incomingLinks.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final destinations = [
      _InventoryDestination(
        icon: Icons.nfc,
        label: 'Home',
        content: _HomeView(onScan: widget.dependencies.nfcService.scan),
      ),
      const _InventoryDestination(
        icon: Icons.album_outlined,
        label: 'Spools',
        content: _EmptyArea(
          icon: Icons.album_outlined,
          title: 'Spools',
          message: 'No active filament spools yet',
        ),
      ),
      const _InventoryDestination(
        icon: Icons.shelves,
        label: 'Places',
        content: _EmptyArea(
          icon: Icons.shelves,
          title: 'Places',
          message: 'No storage slots or material units yet',
        ),
      ),
      const _InventoryDestination(
        icon: Icons.archive_outlined,
        label: 'Archive',
        content: _EmptyArea(
          icon: Icons.archive_outlined,
          title: 'Archive',
          message: 'No consumed or retired filament spools',
        ),
      ),
    ];

    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _selectedIndex != 0) {
          setState(() => _selectedIndex = 0);
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final content = destinations[_selectedIndex].content;
              if (constraints.maxWidth >= 600) {
                return Row(
                  children: [
                    NavigationRail(
                      selectedIndex: _selectedIndex,
                      onDestinationSelected: _selectDestination,
                      labelType: NavigationRailLabelType.all,
                      destinations: [
                        for (final destination in destinations)
                          NavigationRailDestination(
                            icon: Icon(destination.icon),
                            label: Text(destination.label),
                          ),
                      ],
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: content),
                  ],
                );
              }

              return content;
            },
          ),
        ),
        bottomNavigationBar: MediaQuery.sizeOf(context).width < 600
            ? NavigationBar(
                selectedIndex: _selectedIndex,
                onDestinationSelected: _selectDestination,
                destinations: [
                  for (final destination in destinations)
                    NavigationDestination(
                      icon: Icon(destination.icon),
                      label: destination.label,
                    ),
                ],
              )
            : null,
      ),
    );
  }

  void _selectDestination(int index) {
    setState(() => _selectedIndex = index);
  }

  void _showExternalInput(String message) {
    if (!mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Semantics(
            container: true,
            liveRegion: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message),
                const Text('No inventory changes were made.'),
              ],
            ),
          ),
        ),
      );
  }
}

final class _InventoryDestination {
  const _InventoryDestination({
    required this.icon,
    required this.label,
    required this.content,
  });

  final IconData icon;
  final String label;
  final Widget content;
}

final class _HomeView extends StatelessWidget {
  const _HomeView({required this.onScan});

  final Future<void> Function() onScan;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.nfc, size: 64),
              const SizedBox(height: 24),
              Text(
                'Scan a storage-slot tag',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Open a storage slot by scanning its tag, or use Places to find it manually.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onScan,
                icon: const Icon(Icons.nfc),
                label: const Text('Scan storage-slot tag'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _EmptyArea extends StatelessWidget {
  const _EmptyArea({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
