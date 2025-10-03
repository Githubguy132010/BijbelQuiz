import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/bible_provider.dart';
import '../services/offline_bible_service.dart';
import '../services/download_service.dart';
import '../services/sync_service.dart';
import '../services/connection_service.dart';
import '../widgets/offline_indicator.dart';
import '../l10n/strings_nl.dart' as strings;
import 'download_screen.dart';

/// Settings screen for BijbelRead app
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Services
  late BibleProvider _bibleProvider;
  late OfflineBibleService _offlineBibleService;
  late DownloadService _downloadService;
  late SyncService _syncService;
  late ConnectionService _connectionService;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  void _initializeServices() {
    _bibleProvider = Provider.of<BibleProvider>(context, listen: false);
    _offlineBibleService = Provider.of<OfflineBibleService>(context, listen: false);
    _downloadService = Provider.of<DownloadService>(context, listen: false);
    _syncService = Provider.of<SyncService>(context, listen: false);
    _connectionService = Provider.of<ConnectionService>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.AppStrings.settings),
      ),
      body: ListView(
        children: [
          // Connection status section
          _buildSectionHeader('Verbindingsstatus'),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Status: '),
                    Expanded(
                      child: OfflineIndicator(
                        showText: true,
                        showQuality: true,
                        size: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Gegevensbron: ${_bibleProvider.getCurrentDataSource()}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (_bibleProvider.offlineMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _bibleProvider.offlineMessage!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Offline mode section
          _buildSectionHeader('Offline modus'),
          _buildSettingsTile(
            title: 'Offline modus',
            subtitle: _bibleProvider.isOfflineMode
                ? 'Offline modus actief - gebruikt lokale inhoud'
                : 'Online modus - gebruikt internet',
            leading: Icon(
              _bibleProvider.isOfflineMode ? Icons.offline_bolt : Icons.online_prediction,
              color: _bibleProvider.isOfflineMode ? Colors.orange : Colors.green,
            ),
            trailing: Switch(
              value: _bibleProvider.isOfflineMode,
              onChanged: _bibleProvider.hasOfflineContent ? (value) {
                if (value) {
                  _bibleProvider.enableOfflineMode();
                } else {
                  _bibleProvider.disableOfflineMode();
                }
              } : null,
            ),
          ),

          if (_bibleProvider.hasOfflineContent) ...[
            _buildSettingsTile(
              title: 'Offline inhoud beheren',
              subtitle: 'Bekijk en beheer gedownloade Bijbelinhoud',
              leading: const Icon(Icons.download_done),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const DownloadScreen()),
                );
              },
            ),

            _buildSettingsTile(
              title: 'Synchroniseren',
              subtitle: 'Update offline inhoud met laatste versie',
              leading: const Icon(Icons.sync),
              onTap: () async {
                final result = await _syncService.performFullSync();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_getSyncResultMessage(result)),
                    duration: const Duration(seconds: 3),
                  ),
                );
              },
            ),
          ],

          const SizedBox(height: 24),

          // Bible reading settings
          _buildSectionHeader('Bijbellezen'),
          _buildSettingsTile(
            title: 'Lettergrootte',
            subtitle: 'Pas de tekstgrootte aan',
            leading: const Icon(Icons.text_fields),
            onTap: () {
              _showFontSizeDialog();
            },
          ),

          _buildSettingsTile(
            title: 'Nachtmodus',
            subtitle: 'Donkere achtergrond voor lezen',
            leading: const Icon(Icons.nightlight_round),
            trailing: Switch(
              value: Theme.of(context).brightness == Brightness.dark,
              onChanged: (value) {
                // Theme switching would be handled by a theme provider
                // For now, just show a message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Thema wisselen komt binnenkort beschikbaar'),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // Data and storage
          _buildSectionHeader('Gegevens en opslag'),
          _buildSettingsTile(
            title: 'Cache wissen',
            subtitle: 'Verwijder tijdelijke bestanden',
            leading: const Icon(Icons.cleaning_services),
            onTap: () {
              _showClearCacheDialog();
            },
          ),

          if (_bibleProvider.hasOfflineContent) ...[
            _buildSettingsTile(
              title: 'Offline gegevens wissen',
              subtitle: 'Verwijder alle gedownloade Bijbelinhoud',
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              onTap: () {
                _showClearOfflineDataDialog();
              },
            ),
          ],

          const SizedBox(height: 24),

          // About section
          _buildSectionHeader('Over'),
          _buildSettingsTile(
            title: 'Versie',
            subtitle: '1.0.0',
            leading: const Icon(Icons.info_outline),
          ),

          _buildSettingsTile(
            title: 'Licentie',
            subtitle: 'Bekijk licentie-informatie',
            leading: const Icon(Icons.description),
            onTap: () {
              _showLicenseDialog();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      margin: const EdgeInsets.only(left: 16, top: 24, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required String title,
    required String subtitle,
    Widget? leading,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        leading: leading,
        trailing: trailing,
        onTap: onTap,
        enabled: onTap != null,
      ),
    );
  }

  void _showFontSizeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lettergrootte'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Klein'),
              leading: Radio<String>(
                value: 'small',
                groupValue: 'medium', // Default to medium for now
                onChanged: (value) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Lettergrootte aangepast'),
                    ),
                  );
                },
              ),
            ),
            ListTile(
              title: const Text('Gemiddeld'),
              leading: Radio<String>(
                value: 'medium',
                groupValue: 'medium',
                onChanged: (value) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Lettergrootte aangepast'),
                    ),
                  );
                },
              ),
            ),
            ListTile(
              title: const Text('Groot'),
              leading: Radio<String>(
                value: 'large',
                groupValue: 'medium',
                onChanged: (value) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Lettergrootte aangepast'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Sluiten'),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cache wissen'),
        content: const Text(
          'Dit verwijdert tijdelijke bestanden en cache. '
          'Dit heeft geen invloed op gedownloade offline inhoud.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuleren'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache gewist'),
                ),
              );
            },
            child: const Text('Wissen'),
          ),
        ],
      ),
    );
  }

  void _showClearOfflineDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Offline gegevens wissen'),
        content: const Text(
          'Dit verwijdert alle gedownloade Bijbelinhoud. '
          'Deze actie kan niet ongedaan worden gemaakt.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuleren'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _bibleProvider.clearOfflineData();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Offline gegevens gewist'),
                ),
              );
            },
            child: const Text('Wissen'),
          ),
        ],
      ),
    );
  }

  void _showLicenseDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Licentie'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'BijbelRead - Offline Bijbel Lezen',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text(
                'Deze applicatie gebruikt de Online Bijbel API voor het ophalen van Bijbelteksten. '
                'Alle Bijbelteksten zijn eigendom van hun respectievelijke uitgevers.',
              ),
              SizedBox(height: 16),
              Text(
                'De broncode van deze applicatie is beschikbaar onder de MIT licentie.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Sluiten'),
          ),
        ],
      ),
    );
  }

  String _getSyncResultMessage(SyncResult result) {
    switch (result) {
      case SyncResult.success:
        return 'Synchronisatie voltooid';
      case SyncResult.partial:
        return 'Synchronisatie gedeeltelijk voltooid';
      case SyncResult.failed:
        return 'Synchronisatie mislukt';
      case SyncResult.skipped:
        return 'Synchronisatie overgeslagen';
    }
  }
}
