import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/ai_provider.dart';
import '../../services/storage_service.dart';

/// Settings dialog to configure AI Provider, Model, and API Key
class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  final StorageService _storageService = StorageService();
  final TextEditingController _keyController = TextEditingController();
  final TextEditingController _customModelController = TextEditingController();

  bool _isLoading = true;
  bool _obscureText = true;
  bool _isCustomModel = false;

  late AiProvider _selectedProvider;
  late String _selectedModel;
  String _currentConfiguredKey = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final provider = await _storageService.getActiveProvider();
    final model = await _storageService.getActiveModel(provider);
    final key = await _storageService.getApiKeyForProvider(provider);

    final isCustom = !provider.availableModels.contains(model);

    if (mounted) {
      setState(() {
        _selectedProvider = provider;
        _selectedModel = model;
        _isCustomModel = isCustom;
        if (isCustom) {
          _customModelController.text = model;
        }
        _currentConfiguredKey = key;
        _keyController.text = key;
        _isLoading = false;
      });
    }
  }

  Future<void> _onProviderChanged(AiProvider? newProvider) async {
    if (newProvider == null || newProvider == _selectedProvider) return;

    final defaultModel = await _storageService.getActiveModel(newProvider);
    final key = await _storageService.getApiKeyForProvider(newProvider);
    final isCustom = !newProvider.availableModels.contains(defaultModel);

    setState(() {
      _selectedProvider = newProvider;
      _selectedModel = defaultModel;
      _isCustomModel = isCustom;
      if (isCustom) {
        _customModelController.text = defaultModel;
      } else {
        _customModelController.clear();
      }
      _currentConfiguredKey = key;
      _keyController.text = key;
    });
  }

  String _maskKey(String key) {
    if (key.isEmpty) return 'No API key set';
    if (key.length <= 8) return '********';
    return '${key.substring(0, 4)}...${key.substring(key.length - 4)}';
  }

  Future<void> _saveSettings() async {
    final finalModel = _isCustomModel
        ? _customModelController.text.trim()
        : _selectedModel;

    if (finalModel.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or enter a valid model')),
      );
      return;
    }

    final newKey = _keyController.text.trim();

    // Save provider and model
    await _storageService.setActiveProvider(_selectedProvider);
    await _storageService.setActiveModel(_selectedProvider, finalModel);

    // Save API key if updated
    if (newKey.isNotEmpty) {
      await _storageService.saveApiKeyForProvider(_selectedProvider, newKey);
    }

    if (mounted) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Settings updated: ${_selectedProvider.displayName} ($finalModel)',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _clearKey() async {
    await _storageService.clearApiKeyForProvider(_selectedProvider);
    setState(() {
      _currentConfiguredKey = '';
      _keyController.clear();
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('API Key cleared for ${_selectedProvider.displayName}.'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _keyController.dispose();
    _customModelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.tune_rounded, color: AppColors.primary),
          SizedBox(width: 8),
          Text('AI Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
      content: _isLoading
          ? const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Provider Selection
                  const Text(
                    'AI Provider',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<AiProvider>(
                        value: _selectedProvider,
                        isExpanded: true,
                        items: AiProvider.values.map((provider) {
                          return DropdownMenuItem<AiProvider>(
                            value: provider,
                            child: Row(
                              children: [
                                Icon(
                                  provider == AiProvider.gemini
                                      ? Icons.auto_awesome
                                      : Icons.psychology_outlined,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  provider.displayName,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: _onProviderChanged,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. Model Selection
                  const Text(
                    'Model',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _isCustomModel ? 'custom' : _selectedModel,
                        isExpanded: true,
                        items: [
                          ..._selectedProvider.availableModels.map((model) {
                            return DropdownMenuItem<String>(
                              value: model,
                              child: Text(model, style: const TextStyle(fontSize: 13)),
                            );
                          }),
                          const DropdownMenuItem<String>(
                            value: 'custom',
                            child: Text(
                              'Custom model...',
                              style: TextStyle(
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          if (val == null) return;
                          setState(() {
                            if (val == 'custom') {
                              _isCustomModel = true;
                            } else {
                              _isCustomModel = false;
                              _selectedModel = val;
                            }
                          });
                        },
                      ),
                    ),
                  ),

                  // Custom Model Text Field if selected
                  if (_isCustomModel) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: _customModelController,
                      decoration: const InputDecoration(
                        labelText: 'Enter Custom Model ID',
                        hintText: 'e.g. gpt-4o, claude-3-opus, etc.',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // 3. API Key Configuration
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_selectedProvider.displayName} API Key',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Active: ${_maskKey(_currentConfiguredKey)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _keyController,
                    obscureText: _obscureText,
                    decoration: InputDecoration(
                      labelText: 'API Key for ${_selectedProvider.displayName}',
                      hintText: 'Enter API key...',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureText
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureText = !_obscureText;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Get an API key at:\n${_selectedProvider.apiKeyUrl}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
      actions: [
        if (_currentConfiguredKey.isNotEmpty)
          TextButton(
            onPressed: _clearKey,
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Reset Key'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveSettings,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('Save Settings'),
        ),
      ],
    );
  }
}
