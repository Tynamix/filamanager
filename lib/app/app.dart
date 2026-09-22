import 'dart:async';

import 'package:filamanager/app/app_dependencies.dart';
import 'package:filamanager/app/fila_theme.dart';
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
      theme: FilaTheme.light,
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
        content: _HomeView(
          onScan: widget.dependencies.nfcService.scan,
          onShowAll: () => _selectDestination(1),
        ),
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
        backgroundColor: FilaColors.canvas,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final content = destinations[_selectedIndex].content;
              final page = ColoredBox(
                color: FilaColors.surface,
                child: Column(
                  children: [
                    const _AppHeader(),
                    Expanded(child: content),
                  ],
                ),
              );
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
                    Expanded(child: page),
                  ],
                );
              }

              return page;
            },
          ),
        ),
        bottomNavigationBar: MediaQuery.sizeOf(context).width < 600
            ? SafeArea(
                top: false,
                minimum: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: _CompactNavigation(
                  destinations: destinations,
                  selectedIndex: _selectedIndex,
                  onSelected: _selectDestination,
                ),
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

final class _CompactNavigation extends StatelessWidget {
  const _CompactNavigation({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<_InventoryDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        border: Border.all(color: FilaColors.line),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2118281E),
            blurRadius: 35,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          for (var index = 0; index < destinations.length; index++)
            Expanded(
              child: _CompactDestinationButton(
                destination: destinations[index],
                selectedIndex: selectedIndex,
                index: index,
                onSelected: onSelected,
              ),
            ),
        ],
      ),
    );
  }
}

final class _CompactDestinationButton extends StatelessWidget {
  const _CompactDestinationButton({
    required this.destination,
    required this.selectedIndex,
    required this.index,
    required this.onSelected,
  });

  final _InventoryDestination destination;
  final int selectedIndex;
  final int index;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final selected = selectedIndex == index;
    final color = selected ? Colors.white : FilaColors.muted;

    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      child: ExcludeSemantics(
        child: Material(
          color: selected ? FilaColors.green : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: () => onSelected(index),
            borderRadius: BorderRadius.circular(14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(destination.icon, size: 20, color: color),
                const SizedBox(height: 3),
                Text(
                  destination.label,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _AppHeader extends StatelessWidget {
  const _AppHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: FilaColors.green,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Text(
              'F',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.4,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FilaManager',
                  style: TextStyle(
                    color: FilaColors.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Scan-led context',
                  style: TextStyle(color: FilaColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: FilaColors.greenLight,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 9, color: FilaColors.green),
                SizedBox(width: 6),
                Text(
                  'Local',
                  style: TextStyle(
                    color: FilaColors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
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
  const _HomeView({required this.onScan, required this.onShowAll});

  final Future<void> Function() onScan;
  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Eyebrow('Ready when you are'),
              const SizedBox(height: 8),
              Text(
                'Find the slot.\nMove the spool.',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: 10),
              Text(
                'Scanning is the fastest way in. Every action also works manually.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 22),
              _ScanHero(onScan: onScan),
              const SizedBox(height: 30),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _Eyebrow('Manual lookup'),
                        const SizedBox(height: 3),
                        Text(
                          'Find a spool',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: onShowAll,
                    child: const Text('See all'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const _PrototypeCard(
                child: _EmptyCardContent(
                  icon: Icons.album_outlined,
                  title: 'No active filament spools yet',
                  message: 'Registered filament spools will appear here.',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _ScanHero extends StatelessWidget {
  const _ScanHero({required this.onScan});

  final Future<void> Function() onScan;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Scan a storage-slot tag',
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(28),
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [FilaColors.greenDark, Color(0xFF28654B)],
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x24312027),
                  blurRadius: 55,
                  offset: Offset(0, 18),
                ),
              ],
            ),
            child: InkWell(
              onTap: onScan,
              borderRadius: BorderRadius.circular(28),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.75),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.nfc,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                    const SizedBox(width: 17),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Scan a storage-slot tag',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Hold the top of your phone near a tag.',
                            style: TextStyle(
                              color: Color(0xFFC9DBD1),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Eyebrow('Local inventory'),
              const SizedBox(height: 4),
              Text(title, style: Theme.of(context).textTheme.displayMedium),
              const SizedBox(height: 20),
              _PrototypeCard(
                child: _EmptyCardContent(
                  icon: icon,
                  title: message,
                  message: 'This area is ready for your inventory.',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: FilaColors.muted,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.1,
      ),
    );
  }
}

final class _PrototypeCard extends StatelessWidget {
  const _PrototypeCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: FilaColors.line),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D1D3024),
            blurRadius: 20,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}

final class _EmptyCardContent extends StatelessWidget {
  const _EmptyCardContent({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFEDF3ED),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: FilaColors.green),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(message),
            ],
          ),
        ),
      ],
    );
  }
}
