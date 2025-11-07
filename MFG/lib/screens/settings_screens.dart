// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:manufacturing_dashboard/services/settings_services.dart';
import '../models/settings_model.dart';


class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late AppSettings _settings;
  final SettingsService _settingsService = SettingsService.instance;
  bool _isLoading = true;
  bool _hasChanges = false;
  
  
  // Controllers for text fields
  final TextEditingController _newLineController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  @override
  void dispose() {
    _newLineController.dispose();
    super.dispose();
  }
  
  Future<void> _loadSettings() async {
    final settings = await _settingsService.loadSettings();
    setState(() {
      _settings = settings;
      _isLoading = false;
      // _settings.fetchIntervalSeconds = _settings.fetchIntervalSeconds;
    });
  }
  
  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    
    final success = await _settingsService.saveSettings(_settings);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() => _hasChanges = false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save settings'),
          backgroundColor: Colors.red,
        ),
      );
    }
    
    setState(() => _isLoading = false);
  }
  
  void _updateSetting(AppSettings newSettings) {
    setState(() {
      _settings = newSettings;
      _hasChanges = true;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return WillPopScope(
      onWillPop: () async {
        if (_hasChanges) {
          final shouldPop = await _showUnsavedChangesDialog();
          return shouldPop ?? false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1E1E2E),
        appBar: AppBar(
          backgroundColor: const Color(0xFF2E4057),
          title: const Text('Settings'),
          actions: [
            if (_hasChanges)
              TextButton(
                onPressed: _saveSettings,
                child: const Text(
                  'SAVE',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.restore),
              onPressed: _showResetDialog,
              tooltip: 'Reset to defaults',
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Production Lines Section
              _buildSectionCard(
                title: 'Production Lines',
                icon: Icons.factory,
                children: [
                  _buildLinesList(),
                  const SizedBox(height: 16),
                  _buildAddLineInput(),
                ],
              ),
              const SizedBox(height: 16),
              
              // Display Preferences Section
              _buildSectionCard(
                title: 'Display Preferences',
                icon: Icons.display_settings,
                children: [
                  _buildHourIndicatorOption(),
                  const Divider(),
                  _buildCardsPerRowOption(),
                  const Divider(),
                 // _buildCardScaleOption(),
                  const Divider(),
                  _buildCommunicationsPanelToggle(),
                ],
              ),
              const SizedBox(height: 16),
              
              // Data Fetching Section
              _buildSectionCard(
                title: 'Data Fetching',
                icon: Icons.sync,
                children: [
                  _buildFetchIntervalOption(),
                  const Divider(),
                  _buildDataExpiryOption(),
                  const Divider(),
                  _buildStaleDataWarningToggle(),
                ],
              ),
              const SizedBox(height: 16),

              // Auto-Scroll Section
              _buildSectionCard(
                title: 'Auto-Scroll',
                icon: Icons.autorenew,
                children: [
                  _buildAutoScrollToggle(),
                  if (_settings.autoScroll) ...[
                    const Divider(),
                    _buildScrollIntervalOption(),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              
              // Appearance Section
              _buildSectionCard(
                title: 'Appearance',
                icon: Icons.palette,
                children: [
                  _buildDarkModeToggle(),
                ],
              ),
              const SizedBox(height: 16),
              
              // Import/Export Section
              _buildSectionCard(
                title: 'Backup & Restore',
                icon: Icons.backup,
                children: [
                  _buildImportExportButtons(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      color: const Color(0xFF2E4057),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.white70, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
  
  Widget _buildLinesList() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ReorderableListView.builder(
        shrinkWrap: true,
        itemCount: _settings.productionLines.length,
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (newIndex > oldIndex) {
              newIndex -= 1;
            }
            final item = _settings.productionLines.removeAt(oldIndex);
            _settings.productionLines.insert(newIndex, item);
            _hasChanges = true;
          });
        },
        itemBuilder: (context, index) {
          final line = _settings.productionLines[index];
          return ListTile(
            key: ValueKey(line),
            leading: const Icon(
              Icons.drag_handle,
              color: Colors.white54,
            ),
            title: Text(
              line,
              style: const TextStyle(color: Colors.white),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                setState(() {
                  _settings.productionLines.removeAt(index);
                  _hasChanges = true;
                });
              },
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildAddLineInput() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _newLineController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter new line name as in CIM (e.g., SMT-L02)',
              hintStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: Colors.white10,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: (_) => _addNewLine(),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: _addNewLine,
          icon: const Icon(Icons.add),
          label: const Text('Add'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
          ),
        ),
      ],
    );
  }
  
  void _addNewLine() {
    final newLine = _newLineController.text.trim();
    if (newLine.isNotEmpty && !_settings.productionLines.contains(newLine)) {
      setState(() {
        _settings.productionLines.add(newLine);
        _newLineController.clear();
        _hasChanges = true;
      });
    }
  }
  
  Widget _buildHourIndicatorOption() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Hour Indicator Display',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(
              value: true,
              label: Text('Numbers'),
              icon: Icon(Icons.numbers),
            ),
            ButtonSegment(
              value: false,
              label: Text('Percentage'),
              icon: Icon(Icons.percent),
            ),
          ],
          selected: {_settings.showProductionNumbers},
          onSelectionChanged: (Set<bool> newSelection) {
            _updateSetting(
              _settings.copyWith(showProductionNumbers: newSelection.first),
            );
          },
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.resolveWith((states) {
              if (states.contains(MaterialState.selected)) {
                return Colors.blue;
              }
              return Colors.white24;
            }),
          ),
        ),
      ],
    );
  }
  
  Widget _buildCardsPerRowOption() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Cards per Row',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        Row(
          children: [
            IconButton(
              onPressed: _settings.cardsPerRow > 3
                  ? () => _updateSetting(
                        _settings.copyWith(cardsPerRow: _settings.cardsPerRow - 1),
                      )
                  : null,
              icon: const Icon(Icons.remove_circle, color: Colors.white70),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _settings.cardsPerRow.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              onPressed: _settings.cardsPerRow < 5
                  ? () => _updateSetting(
                        _settings.copyWith(cardsPerRow: _settings.cardsPerRow + 1),
                      )
                  : null,
              icon: const Icon(Icons.add_circle, color: Colors.white70),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildCardScaleOption() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Card Size',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            Text(
              '${(_settings.cardScale * 100).round()}%',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: _settings.cardScale,
          min: 0.4,
          max: 1.3,
          divisions: 12,
          onChanged: (value) {
            _updateSetting(_settings.copyWith(cardScale: value));
          },
        ),
      ],
    );
  }
  
  Widget _buildFetchIntervalOption() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fetch Interval',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            Text(
              'Seconds between each line update',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              
              onPressed: _settings.fetchIntervalSeconds > 20
                  ? () => _updateSetting(
                        _settings.copyWith(
                          fetchIntervalSeconds: _settings.fetchIntervalSeconds - 5,
                        ),
                      )
                  : null,
              icon: const Icon(Icons.remove_circle, color: Colors.white70),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_settings.fetchIntervalSeconds}s',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              onPressed: _settings.fetchIntervalSeconds < 120
                  ? () => _updateSetting(
                        _settings.copyWith(
                          fetchIntervalSeconds: _settings.fetchIntervalSeconds + 5,
                        ),
                      )
                  : null,
              icon: const Icon(Icons.add_circle, color: Colors.white70),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildDataExpiryOption() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Expiry',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            Text(
              'Minutes before data is marked stale',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              onPressed: _settings.dataExpiryMinutes > 5
                  ? () => _updateSetting(
                        _settings.copyWith(
                          dataExpiryMinutes: _settings.dataExpiryMinutes - 5,
                        ),
                      )
                  : null,
              icon: const Icon(Icons.remove_circle, color: Colors.white70),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_settings.dataExpiryMinutes}m',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              onPressed: _settings.dataExpiryMinutes < 60
                  ? () => _updateSetting(
                        _settings.copyWith(
                          dataExpiryMinutes: _settings.dataExpiryMinutes + 5,
                        ),
                      )
                  : null,
              icon: const Icon(Icons.add_circle, color: Colors.white70),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildStaleDataWarningToggle() {
    return SwitchListTile(
      title: const Text(
        'Show Stale Data Warning',
        style: TextStyle(color: Colors.white),
      ),
      subtitle: const Text(
        'Display warning icon on cards with old data',
        style: TextStyle(color: Colors.white54, fontSize: 12),
      ),
      value: _settings.showStaleDataWarning,
      onChanged: (value) {
        _updateSetting(_settings.copyWith(showStaleDataWarning: value));
      },
      activeColor: Colors.green,
    );
  }
  
  Widget _buildCommunicationsPanelToggle() {
    return SwitchListTile(
      title: const Text(
        'Show Communications Panel',
        style: TextStyle(color: Colors.white),
      ),
      subtitle: const Text(
        'Display the right sidebar with announcements',
        style: TextStyle(color: Colors.white54, fontSize: 12),
      ),
      value: _settings.showCommunicationsPanel,
      onChanged: (value) {
        _updateSetting(_settings.copyWith(showCommunicationsPanel: value));
      },
      activeColor: Colors.green,
    );
  }
  
  Widget _buildDarkModeToggle() {
    return SwitchListTile(
      title: const Text(
        'Dark Mode',
        style: TextStyle(color: Colors.white),
      ),
      subtitle: const Text(
        'Use dark theme throughout the app',
        style: TextStyle(color: Colors.white54, fontSize: 12),
      ),
      value: _settings.darkMode,
      onChanged: (value) {
        _updateSetting(_settings.copyWith(darkMode: value));
      },
      activeColor: Colors.green,
    );
  }
  
  Widget _buildImportExportButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _exportSettings,
            icon: const Icon(Icons.upload),
            label: const Text('Export'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _importSettings,
            icon: const Icon(Icons.download),
            label: const Text('Import'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
          ),
        ),
      ],
    );
  }
  
  void _exportSettings() {
    final json = _settingsService.exportSettings();
    Clipboard.setData(ClipboardData(text: json));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings copied to clipboard'),
        backgroundColor: Colors.green,
      ),
    );
  }
  
  void _importSettings() async {
    final data = await Clipboard.getData('text/plain');
    if (data != null && data.text != null) {
      final success = await _settingsService.importSettings(data.text!);
      if (success) {
        await _loadSettings();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings imported successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid settings format'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<bool?> _showUnsavedChangesDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text('You have unsaved changes. Do you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }
  
  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text('Are you sure you want to reset all settings to defaults?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _settingsService.resetToDefaults();
              await _loadSettings();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Settings reset to defaults'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text('Reset', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // --- Auto-Scroll Widgets ---

  Widget _buildAutoScrollToggle() {
    return SwitchListTile(
      title: const Text(
        'Enable Auto-Scroll',
        style: TextStyle(color: Colors.white),
      ),
      subtitle: const Text(
        'Automatically scroll through the dashboard',
        style: TextStyle(color: Colors.white54, fontSize: 12),
      ),
      value: _settings.autoScroll,
      onChanged: (value) {
        _updateSetting(_settings.copyWith(autoScroll: value));
      },
      activeColor: Colors.green,
    );
  }

  Widget _buildScrollIntervalOption() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Scroll Interval',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            Text(
              'Seconds between each scroll (Min: 20s)',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              onPressed: _settings.scrollIntervalSeconds > 20
                  ? () => _updateSetting(
                        _settings.copyWith(
                          scrollIntervalSeconds: _settings.scrollIntervalSeconds - 5,
                        ),
                      )
                  : null,
              icon: const Icon(Icons.remove_circle, color: Colors.white70),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_settings.scrollIntervalSeconds}s',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              onPressed: _settings.scrollIntervalSeconds < 120
                  ? () => _updateSetting(
                        _settings.copyWith(
                          scrollIntervalSeconds: _settings.scrollIntervalSeconds + 5,
                        ),
                      )
                  : null,
              icon: const Icon(Icons.add_circle, color: Colors.white70),
            ),
          ],
        ),
      ],
    );
  }
}