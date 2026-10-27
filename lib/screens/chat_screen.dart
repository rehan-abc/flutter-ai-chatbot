import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/ai_provider.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';
import '../services/storage_service.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/chat_input_field.dart';
import 'widgets/settings_dialog.dart';

/// Main screen containing the Chat interface
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  final StorageService _storageService = StorageService();

  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _hasApiKey = false;
  AiProvider _activeProvider = AiProvider.gemini;
  String _activeModel = 'gemini-1.5-flash';

  final List<String> _quickSuggestions = [
    'Explain quantum computing in simple terms',
    'Write a Flutter counter app snippet',
    'Give me 3 healthy breakfast ideas',
  ];

  @override
  void initState() {
    super.initState();
    _loadActiveConfig();
  }

  Future<void> _loadActiveConfig() async {
    final provider = await _storageService.getActiveProvider();
    final model = await _storageService.getActiveModel(provider);
    final key = await _storageService.getApiKeyForProvider(provider);

    if (mounted) {
      setState(() {
        _activeProvider = provider;
        _activeModel = model;
        _hasApiKey = key.isNotEmpty;
      });

      if (_messages.isEmpty) {
        _addInitialGreeting();
      }
    }
  }

  void _addInitialGreeting() {
    _messages.add(
      ChatMessage(
        id: 'welcome_msg',
        text:
            'Hello! I am your AI assistant powered by ${_activeProvider.displayName} ($_activeModel). How can I help you today?',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage([String? customText]) async {
    final text = customText ?? _inputController.text.trim();
    if (text.isEmpty || _isLoading) return;

    if (customText == null) {
      _inputController.clear();
    }

    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final responseText = await _chatService.sendMessage(
        prompt: text,
        history: _messages,
      );

      final botMessage = ChatMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        text: responseText,
        isUser: false,
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.add(botMessage);
      });
    } catch (e) {
      final errorMessage = ChatMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        text: 'Error: $e',
        isUser: false,
        timestamp: DateTime.now(),
        isError: true,
      );

      setState(() {
        _messages.add(errorMessage);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _openSettings() async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (context) => const SettingsDialog(),
    );

    if (updated == true) {
      await _loadActiveConfig();
    }
  }

  void _clearChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Conversation?'),
        content: const Text('This will reset the current chat history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _messages.clear();
                _addInitialGreeting();
              });
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 1,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _activeProvider.displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    _activeModel,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Settings (Provider, Model & Key)',
            icon: Icon(
              Icons.tune_rounded,
              color: _hasApiKey ? AppColors.primary : AppColors.warning,
            ),
            onPressed: _openSettings,
          ),
          IconButton(
            tooltip: 'Clear Chat',
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textSecondary),
            onPressed: _messages.length > 1 ? _clearChat : null,
          ),
        ],
      ),
      body: Column(
        children: [
          // Missing API Key Alert Banner for Active Provider
          if (!_hasApiKey)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppColors.warning.withValues(alpha: 0.15),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No API key set for ${_activeProvider.displayName}. Tap Configure.',
                      style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                    ),
                  ),
                  TextButton(
                    onPressed: _openSettings,
                    child: const Text('Configure'),
                  ),
                ],
              ),
            ),

          // Message list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return ChatBubble(message: _messages[index]);
              },
            ),
          ),

          // Quick prompt chips (shown when conversation just started)
          if (_messages.length <= 1)
            Container(
              height: 44,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _quickSuggestions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final suggestion = _quickSuggestions[index];
                  return ActionChip(
                    label: Text(
                      suggestion,
                      style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                    ),
                    backgroundColor: AppColors.surface,
                    side: const BorderSide(color: AppColors.border),
                    onPressed: () => _sendMessage(suggestion),
                  );
                },
              ),
            ),

          // Loading indicator
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.only(left: 20, bottom: 8),
              child: Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${_activeProvider.displayName} is thinking...',
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

          // Input field
          ChatInputField(
            controller: _inputController,
            isLoading: _isLoading,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }
}
