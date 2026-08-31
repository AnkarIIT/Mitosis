import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import '../../core/providers/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/database/drift_database.dart';

import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final String? imagePath;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.imagePath,
    required this.timestamp,
  });
}

class ChatbotScreen extends ConsumerStatefulWidget {
  final String? initialMessage;

  const ChatbotScreen({super.key, this.initialMessage});

  @override
  ConsumerState<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends ConsumerState<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadChatHistory();

    if (widget.initialMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendMessage(widget.initialMessage!);
      });
    }
  }

  Future<void> _loadChatHistory() async {
    final db = ref.read(databaseProvider);
    final history = await db.getAllChats();

    if (!mounted) return;

    setState(() {
      if (history.isEmpty) {
        _messages.add(
          ChatMessage(
            text:
                "Hello! I'm your AI Doubt Solver. You can ask me any NEET-related questions, or tap the camera icon to upload a photo of a question you're stuck on!",
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      } else {
        _messages.addAll(
          history.map(
            (c) => ChatMessage(
              text: c.message,
              isUser: c.isUser,
              timestamp: c.timestamp,
            ),
          ),
        );
      }
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final geminiService = ref.read(geminiServiceProvider);
    if (!geminiService.isConfigured) {
      _showSettingsPrompt();
      return;
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 80);

    if (pickedFile != null) {
      final compressedPath = await _compressImage(pickedFile.path);
      _sendMessage(
        "Explain this NEET question step-by-step and provide NCERT reference.",
        imagePath: compressedPath ?? pickedFile.path,
      );
    }
  }

  Future<String?> _compressImage(String path) async {
    try {
      final tempDir = await path_provider.getTemporaryDirectory();
      final targetPath =
          '${tempDir.path}/temp_question_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        path,
        targetPath,
        quality: 70,
        minWidth: 1024,
        minHeight: 1024,
      );

      return result?.path;
    } catch (e) {
      debugPrint('❌ Compression failed: $e');
      return null;
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AdaptiveColors.background(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AdaptiveColors.divider(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Upload Question',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(
                Icons.camera_alt,
                color: AdaptiveColors.primary(context),
              ),
              title: const Text('Take a Photo'),
              onTap: () {
                context.pop();
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.photo_library,
                color: AdaptiveColors.primary(context),
              ),
              title: const Text('Choose from Gallery'),
              onTap: () {
                context.pop();
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage(String text, {String? imagePath}) async {
    final geminiService = ref.read(geminiServiceProvider);
    final db = ref.read(databaseProvider);

    if (!geminiService.isConfigured) {
      _showSettingsPrompt();
      return;
    }

    if (text.trim().isEmpty && imagePath == null) return;

    final userMessage = ChatMessage(
      text: text,
      isUser: true,
      imagePath: imagePath,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    // Persist user message
    await db.insertChatMessage(
      ChatsCompanion.insert(
        message: text,
        isUser: true,
        timestamp: userMessage.timestamp,
      ),
    );

    try {
      String responseText;
      if (imagePath != null) {
        final imageBytes = await File(imagePath).readAsBytes();
        final parts = [DataPart('image/jpeg', imageBytes)];
        responseText = await geminiService.sendMultimodalMessage(text, parts);
      } else {
        responseText = await geminiService.sendMessage(text);
      }

      final aiMessage = ChatMessage(
        text: responseText,
        isUser: false,
        timestamp: DateTime.now(),
      );

      if (!mounted) return;

      setState(() {
        _messages.add(aiMessage);
        _isLoading = false;
      });
      _scrollToBottom();

      // Persist AI response
      await db.insertChatMessage(
        ChatsCompanion.insert(
          message: responseText,
          isUser: false,
          timestamp: aiMessage.timestamp,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          ChatMessage(
            text: "ERROR_MSG: $e",
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  Future<void> _clearChat() async {
    final db = ref.read(databaseProvider);
    await db.clearChatHistory();
    setState(() {
      _messages.clear();
      _messages.add(
        ChatMessage(
          text: "Chat history cleared. How can I help you today?",
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    });
  }

  void _showSettingsPrompt() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('API Key Required'),
        content: const Text(
          'Please configure your free Gemini API Key in the settings to use the AI Tutor.',
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.pop();
              context.push('/settings');
            },
            child: const Text('Go to Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Doubt Solver 🤖'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear Chat',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear Chat?'),
                  content: const Text(
                    'This will permanently delete your conversation history.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        context.pop();
                        _clearChat();
                      },
                      child: const Text(
                        'Clear',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              context.push('/settings');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message).animate().fade().scaleXY(
                  begin: 0.8,
                  end: 1.0,
                  curve: Curves.easeOutBack,
                  duration: 300.ms,
                );
              },
            ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    'AI is thinking',
                    style: TextStyle(
                      color: AdaptiveColors.primary(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    children: List.generate(3, (index) {
                      return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: AdaptiveColors.primary(context),
                              shape: BoxShape.circle,
                            ),
                          )
                          .animate(onPlay: (controller) => controller.repeat())
                          .scaleXY(
                            begin: 0.5,
                            end: 1.2,
                            curve: Curves.easeInOut,
                            delay: (index * 150).ms,
                            duration: 600.ms,
                          )
                          .then(delay: 600.ms);
                    }),
                  ),
                ],
              ),
            ),

          if (_messages.length <= 1) _buildSuggestedPrompts(),

          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final bool isError = message.text.startsWith("ERROR_MSG: ");
    final String displayText = isError
        ? message.text.substring(11)
        : message.text;

    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: message.isUser
              ? AdaptiveColors.primary(context)
              : (isError
                    ? AppColors.errorLight
                    : AdaptiveColors.secondary(context).withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: message.isUser ? const Radius.circular(0) : null,
            bottomLeft: !message.isUser ? const Radius.circular(0) : null,
          ),
          border: isError ? Border.all(color: AppColors.error) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.imagePath != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(message.imagePath!),
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            MarkdownBody(
              data: displayText,
              styleSheet: MarkdownStyleSheet(
                p: TextStyle(
                  color: message.isUser
                      ? AdaptiveColors.onPrimary(context)
                      : (isError
                            ? AppColors.error
                            : AdaptiveColors.textPrimary(context)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestedPrompts() {
    final prompts = [
      "Explain mitosis",
      "Solve this physics problem",
      "How to balance chemical equations?",
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              "QUICK ACTIONS",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AdaptiveColors.textSecondary(context),
                letterSpacing: 1.2,
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ActionChip(
                    avatar: const Icon(
                      Icons.camera_alt,
                      size: 14,
                      color: Colors.white,
                    ),
                    label: const Text("UPLOAD QUESTION"),
                    labelStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    backgroundColor: AdaptiveColors.primary(context),
                    onPressed: _showImagePickerOptions,
                  ),
                ),
                ...prompts.map((prompt) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ActionChip(
                      label: Text(prompt),
                      labelStyle: TextStyle(
                        color: AdaptiveColors.onPrimary(context),
                        fontSize: 12,
                      ),
                      backgroundColor: AdaptiveColors.primary(
                        context,
                      ).withValues(alpha: 0.1),
                      side: BorderSide(
                        color: AdaptiveColors.primary(
                          context,
                        ).withValues(alpha: 0.3),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      onPressed: () => _sendMessage(prompt),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ).animate().fade().slideY(begin: 0.5, end: 0, duration: 400.ms),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AdaptiveColors.background(context),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: AdaptiveColors.primary(context).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.photo_camera),
                color: AdaptiveColors.primary(context),
                onPressed: _showImagePickerOptions,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type your doubt...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AdaptiveColors.secondary(
                    context,
                  ).withValues(alpha: 0.3),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (text) => _sendMessage(text),
              ),
            ),
            const SizedBox(width: 12),
            CircleAvatar(
                  radius: 24,
                  backgroundColor: AdaptiveColors.primary(context),
                  child: IconButton(
                    icon: Icon(
                      Icons.send,
                      color: AdaptiveColors.onPrimary(context),
                    ),
                    onPressed: () => _sendMessage(_messageController.text),
                  ),
                )
                .animate(target: _isLoading ? 0 : 1)
                .scaleXY(end: 1.1)
                .shake(hz: 4, curve: Curves.easeInOutCubic),
          ],
        ),
      ),
    );
  }
}
