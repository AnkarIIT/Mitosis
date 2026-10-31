import 'dart:io';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import '../../core/providers/providers.dart';
import '../../core/database/drift_database.dart';
import '../../core/providers/current_user_provider.dart';
import '../../core/services/gemini_chat_service.dart';
import '../../core/services/ncert_book_catalog.dart';
import '../../core/services/ncert_text_index_service.dart';
import '../../core/services/user_pdf_index.dart';
import 'pdf_attachment_bottom_sheet.dart';
import 'photo_crop_screen.dart';

import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final String? imagePath;
  final DateTime timestamp;

  /// For AI replies produced in grounded mode: the NCERT chapter the [p.N]
  /// citations refer to.
  final String? groundedChapterKey;

  /// For AI replies produced in grounded mode: the user PDF the [p.N]
  /// citations refer to.
  final String? groundedUserPdfId;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.imagePath,
    required this.timestamp,
    this.groundedChapterKey,
    this.groundedUserPdfId,
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

  /// Currently selected NCERT chapter for grounded tutoring, or `null` for a
  /// general chat. `_groundedChapter` is its loaded text index (lazy).
  String? _groundedChapterKey;
  NcertChapterText? _groundedChapter;

  /// Currently selected user PDF for grounded tutoring. Mutually exclusive with
  /// `_groundedChapterKey` — only one grounding source at a time.
  String? _groundedUserPdfId;
  UserPdfIndex? _groundedUserPdf;

  bool _showedGroundedToast = false;

  /// Matches the citation format the grounded system prompt demands, e.g.
  /// `[p.12]` or `[NCERT p.12]`.
  static final RegExp _citationPattern = RegExp(r'\[(?:NCERT )?p\.(\d+)\]');

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
              groundedChapterKey: c.groundedChapterKey,
              groundedUserPdfId: c.groundedUserPdfId,
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
    // Captured before any await so we never touch context across an async gap.
    final navigator = Navigator.of(context);
    final geminiService = ref.read(geminiServiceProvider);
    if (!geminiService.isConfigured) {
      _showSettingsPrompt();
      return;
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 80);

    if (pickedFile != null) {
      final compressedPath = await _compressImage(pickedFile.path);
      final imagePath = compressedPath ?? pickedFile.path;

      // Crop step: the student selects just the doubtful part so the vision
      // model sees the question, not the full page. Cancelling aborts the
      // photo (don't silently send a photo the student rejected).
      final croppedPath = await navigator.push<String>(
        MaterialPageRoute(builder: (_) => PhotoCropScreen(imagePath: imagePath)),
      );
      if (croppedPath == null) return;

      _sendMessage(
        "Explain this NEET question step-by-step and provide NCERT reference.",
        imagePath: croppedPath,
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

  /// Selects (or clears) the grounding source (NCERT chapter or user PDF).
  /// A missing index is surfaced honestly — the chat falls back to the
  /// un-grounded path instead of pretending to be grounded.
  Future<void> _selectGroundingSource({
    String? ncertChapterKey,
    String? userPdfId,
  }) async {
    // Mutually exclusive: clear the other
    if (ncertChapterKey != null) {
      setState(() {
        _groundedChapterKey = ncertChapterKey;
        _groundedChapter = null;
        _groundedUserPdfId = null;
        _groundedUserPdf = null;
      });
      if (ncertChapterKey.isEmpty) return;
      final index = ref.read(ncertTextIndexProvider);
      final chapter = await index.load(ncertChapterKey);
      if (!mounted) return;
      setState(() => _groundedChapter = chapter);
      if (chapter == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Text index missing for this chapter — staying in general mode.',
            ),
          ),
        );
      }
    } else if (userPdfId != null) {
      setState(() {
        _groundedUserPdfId = userPdfId;
        _groundedUserPdf = null;
        _groundedChapterKey = null;
        _groundedChapter = null;
      });
      if (userPdfId.isEmpty) return;
      final index = ref.read(userPdfIndexProvider);
      final pdf = await index.load(userPdfId);
      if (!mounted) return;
      setState(() => _groundedUserPdf = pdf);
      if (pdf == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Text index missing for this PDF — staying in general mode.',
            ),
          ),
        );
      }
    } else {
      // Clear all grounding
      setState(() {
        _groundedChapterKey = null;
        _groundedChapter = null;
        _groundedUserPdfId = null;
        _groundedUserPdf = null;
      });
    }
  }

  /// Convenience wrapper for NCERT chapter selection.
  Future<void> _selectGroundedChapter(String? chapterKey) async {
    await _selectGroundingSource(ncertChapterKey: chapterKey);
  }

  /// Convenience wrapper for user PDF selection.
  Future<void> _selectGroundedUserPdf(String? userPdfId) async {
    await _selectGroundingSource(userPdfId: userPdfId);
  }

  /// Maps the visible thread (minus the message currently being asked) to
  /// Gemini turns, bounded by the service's history limit.
  List<GeminiTurn> _geminiHistory() {
    final usable = _messages.length > 1
        ? _messages.sublist(0, _messages.length - 1)
        : const <ChatMessage>[];
    return [
      for (final m in usable) GeminiTurn(isUser: m.isUser, text: m.text),
    ];
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
    final userId = ref.read(currentLocalUserIdProvider) ?? guestOwnerId;
    await db.insertChatMessage(
      ChatsCompanion.insert(
        userId: Value(userId),
        message: text,
        isUser: true,
        timestamp: userMessage.timestamp,
        groundedChapterKey: Value(_groundedChapterKey),
        groundedUserPdfId: Value(_groundedUserPdfId),
      ),
    );

    try {
      String responseText;
      if (imagePath != null) {
        final imageBytes = await File(imagePath).readAsBytes();
        // Cropped photos are re-encoded as PNG by PhotoCropScreen; camera/
        // gallery originals stay JPEG.
        final mime = imagePath.toLowerCase().endsWith('.png')
            ? 'image/png'
            : 'image/jpeg';
        final parts = [DataPart(mime, imageBytes)];
        responseText = await geminiService.sendMultimodalMessage(text, parts);
      } else if (_groundedChapter != null) {
        // Grounded path: whole NCERT chapter text injected, strict citations.
        responseText = await geminiService.sendGrounded(
          prompt: text,
          contextualText: _groundedChapter!.toContextBlock(),
          sourceLabel:
              '${_groundedChapter!.className} ${_groundedChapter!.title}',
          history: _geminiHistory(),
        );
        if (!_showedGroundedToast && mounted) {
          _showedGroundedToast = true;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Grounded reply sent — whole NCERT chapter injected (~40k tokens).',
              ),
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else if (_groundedUserPdf != null) {
        // Grounded path: user PDF text injected, strict citations.
        responseText = await geminiService.sendGrounded(
          prompt: text,
          contextualText: _groundedUserPdf!.toContextBlock(),
          sourceLabel: _groundedUserPdf!.originalName,
          history: _geminiHistory(),
        );
        if (!_showedGroundedToast && mounted) {
          _showedGroundedToast = true;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Grounded reply sent — your PDF injected (~40k tokens).',
              ),
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        responseText = await geminiService.sendMessage(text);
      }

      final aiMessage = ChatMessage(
        text: responseText,
        isUser: false,
        timestamp: DateTime.now(),
        groundedChapterKey: _groundedChapterKey,
        groundedUserPdfId: _groundedUserPdfId,
      );

      if (!mounted) return;

      setState(() {
        _messages.add(aiMessage);
        _isLoading = false;
      });
      _scrollToBottom();

      // Persist AI response
      final userId = ref.read(currentLocalUserIdProvider) ?? guestOwnerId;
      await db.insertChatMessage(
        ChatsCompanion.insert(
          userId: Value(userId),
          message: responseText,
          isUser: false,
          timestamp: aiMessage.timestamp,
          groundedChapterKey: Value(_groundedChapterKey),
          groundedUserPdfId: Value(_groundedUserPdfId),
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
    // Watched (not just read) so the setup banner appears/disappears the
    // moment a key is saved or removed — no dialog-chasing on every tap.
    final isConfigured = ref.watch(geminiServiceProvider).isConfigured;
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Doubt Solver'),
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
                      child: Text(
                        'Clear',
                        style: TextStyle(color: AdaptiveColors.error(context)),
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
                // Fade only: the old easeOutBack scale replayed on every
                // rebuild and felt jittery in long threads.
                return _buildMessageBubble(message).animate().fade();
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

          // Persistent setup path when unconfigured: tapping chips or send
          // otherwise only ever opens a dialog that dumps you back here.
          if (!isConfigured)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AdaptiveColors.primary(
                    context,
                  ).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AdaptiveColors.primary(
                      context,
                    ).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.key_rounded,
                      size: 18,
                      color: AdaptiveColors.primary(context),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'AI Tutor needs a free Gemini API key to answer.',
                        style: TextStyle(fontSize: 12, height: 1.4),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/settings'),
                      child: const Text('SET UP'),
                    ),
                  ],
                ),
              ),
            ),

          _buildGroundedRibbon(),

          _buildInputArea(),
        ],
      ),
    );
  }

  /// The grounded-mode selection ribbon: shows which NCERT chapter or user PDF
  /// the chat is grounded in, or "General" when ungrounded. Tapping opens the
  /// chapter/PDF picker.
  Widget _buildGroundedRibbon() {
    final ncertChapter = _groundedChapter;
    final userPdf = _groundedUserPdf;
    final isNcertGrounded = ncertChapter != null;
    final isUserPdfGrounded = userPdf != null;
    final isGrounded = isNcertGrounded || isUserPdfGrounded;

    String label;
    if (isNcertGrounded) {
      label =
          'Grounded in: ${ncertChapter.className} ${ncertChapter.subject} — ${ncertChapter.title}';
    } else if (isUserPdfGrounded) {
      label = 'Grounded in: Your PDF — ${userPdf.originalName}';
    } else {
      label = 'Grounded in: no chapter (general chat)';
    }

    return Material(
      color: isGrounded
          ? AdaptiveColors.primary(context).withValues(alpha: 0.08)
          : AdaptiveColors.surfaceContainerHighest(context),
      child: InkWell(
        onTap: _showGroundingPicker,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(
                isUserPdfGrounded ? Icons.picture_as_pdf : Icons.menu_book_outlined,
                size: 18,
                color: isGrounded
                    ? AdaptiveColors.primary(context)
                    : AdaptiveColors.textSecondary(context),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isGrounded
                            ? AdaptiveColors.primary(context)
                            : AdaptiveColors.textSecondary(context),
                      ),
                    ),
                    if (isGrounded)
                      Text(
                        '≈40k tokens per message',
                        style: TextStyle(
                          fontSize: 10,
                          color: AdaptiveColors.textSecondary(context),
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.expand_more,
                size: 18,
                color: AdaptiveColors.textSecondary(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Bottom sheet listing NCERT chapters and user PDFs for grounding selection.
  void _showGroundingPicker() {
    final entries = NcertBookCatalog.allByChapterKey;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AdaptiveColors.background(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final sortedKeys = entries.keys.toList()..sort();
        return SafeArea(
          child: FutureBuilder<List<UserPdfIndex>>(
            future: ref.read(userPdfIndexProvider).listIndices(),
            builder: (context, snapshot) {
              final userPdfs = snapshot.data ?? const <UserPdfIndex>[];
              return Column(
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
                  const SizedBox(height: 16),
                  // General chat option
                  ListTile(
                    leading: const Icon(Icons.chat_bubble_outline),
                    title: const Text('General chat (no grounding)'),
                    subtitle: const Text(
                      'Best for questions outside the listed sources',
                    ),
                    onTap: () {
                      context.pop();
                      _selectGroundingSource(ncertChapterKey: '');
                    },
                  ),
                  const Divider(height: 1),
                  // NCERT chapters section
                  if (sortedKeys.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Text(
                        'NCERT Chapters',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AdaptiveColors.textSecondary(context),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: sortedKeys.length,
                        itemBuilder: (context, index) {
                          final key = sortedKeys[index];
                          final entry = entries[key]!;
                          final selected = key == _groundedChapterKey;
                          return ListTile(
                            dense: true,
                            leading: selected
                                ? Icon(
                                    Icons.check_circle,
                                    color: AdaptiveColors.primary(context),
                                  )
                                : const Icon(Icons.menu_book_outlined),
                            title: Text(
                              '${entry.subject} ${entry.classLevel} — '
                              'Ch. ${entry.chapterNumber}: ${entry.chapterTitle}',
                            ),
                            selected: selected,
                            onTap: () {
                              context.pop();
                              _selectGroundedChapter(key);
                            },
                          );
                        },
                      ),
                    ),
                    const Divider(height: 1),
                  ],
                  // User PDFs section
                  if (userPdfs.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Your PDFs',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AdaptiveColors.textSecondary(context),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            tooltip: 'Attach new PDF',
                            icon: const Icon(Icons.add_circle_outline, size: 20),
                            onPressed: () {
                              context.pop();
                              _showAttachPdfSheet();
                            },
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: userPdfs.length,
                        itemBuilder: (context, index) {
                          final pdf = userPdfs[index];
                          final selected = pdf.pdfId == _groundedUserPdfId;
                          return ListTile(
                            dense: true,
                            leading: selected
                                ? Icon(
                                    Icons.check_circle,
                                    color: AdaptiveColors.primary(context),
                                  )
                                : const Icon(Icons.picture_as_pdf_outlined),
                            title: Text(pdf.originalName),
                            subtitle: Text(
                              '${pdf.pageCount} pages · ${pdf.wordCount} words',
                            ),
                            selected: selected,
                            onTap: () {
                              context.pop();
                              _selectGroundedUserPdf(pdf.pdfId);
                            },
                            trailing: IconButton(
                              tooltip: 'Remove',
                              icon: Icon(
                                Icons.delete_outline,
                                color: AdaptiveColors.error(context),
                                size: 20,
                              ),
                              onPressed: () async {
                                final navigator = Navigator.of(context);
                                await ref
                                    .read(userPdfIndexProvider)
                                    .delete(pdf.pdfId);
                                if (!mounted) return;
                                navigator.pop();
                                _showGroundingPicker();
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ] else ...[
                    // Empty state for user PDFs
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      child: Column(
                        children: [
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  'Your PDFs',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AdaptiveColors.textSecondary(
                                      context,
                                    ),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  tooltip: 'Attach new PDF',
                                  icon: const Icon(
                                    Icons.add_circle_outline,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    context.pop();
                                    _showAttachPdfSheet();
                                  },
                                ),
                              ],
                            ),
                          ),
                          ListTile(
                            leading: const Icon(Icons.picture_as_pdf_outlined),
                            title: const Text('No PDFs attached yet'),
                            subtitle: const Text(
                              'Attach a PDF to ground answers in your own documents',
                            ),
                            onTap: () {
                              context.pop();
                              _showAttachPdfSheet();
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _showAttachPdfSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AdaptiveColors.background(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => PdfAttachmentBottomSheet(
        onPdfAdded: () {
          if (mounted) _showGroundingPicker();
        },
      ),
    );
  }

  /// Tappable page-citation chips rendered under grounded AI replies.
  /// Tapping jumps into the chapter's PDF or user PDF at that physical page.
  Widget _buildCitationChips(ChatMessage message) {
    final chapterKey = message.groundedChapterKey;
    final userPdfId = message.groundedUserPdfId;
    if (message.isUser || (chapterKey == null && userPdfId == null)) {
      return const SizedBox.shrink();
    }

    final pages = _citationPattern
        .allMatches(message.text)
        .map((m) => int.parse(m.group(1)!))
        .toSet()
        .toList()
      ..sort();
    if (pages.isEmpty) return const SizedBox.shrink();

    final isUserPdf = userPdfId != null;
    final pdfId = userPdfId!; // non-null when isUserPdf is true
    final chKey = chapterKey!; // non-null when isUserPdf is false
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          for (final page in pages)
            ActionChip(
              visualDensity: VisualDensity.compact,
              avatar: Icon(
                isUserPdf ? Icons.picture_as_pdf : Icons.auto_stories_outlined,
                size: 14,
                color: AdaptiveColors.primary(context),
              ),
              label: Text('p.$page'),
              labelStyle: TextStyle(
                fontSize: 11,
                color: AdaptiveColors.primary(context),
                fontWeight: FontWeight.w600,
              ),
              side: BorderSide(
                color: AdaptiveColors.primary(context).withValues(alpha: 0.4),
              ),
              backgroundColor: AdaptiveColors.primary(
                context,
              ).withValues(alpha: 0.06),
              onPressed: () => context.push(
                isUserPdf
                    ? '/user-pdf?pdfId=${Uri.encodeComponent(pdfId)}&initialPage=$page'
                    : '/pdf?entryId=${Uri.encodeComponent(chKey)}&initialPage=$page',
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final bool isError = message.text.startsWith("ERROR_MSG: ");
    final String displayText = isError
        ? message.text.substring(11)
        : message.text;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
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
                    ? scheme.errorContainer
                    : AdaptiveColors.surfaceContainerHighest(context)),
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: message.isUser ? const Radius.circular(0) : null,
            bottomLeft: !message.isUser ? const Radius.circular(0) : null,
          ),
          border: isError ? Border.all(color: scheme.error) : null,
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
                            ? scheme.onErrorContainer
                            : AdaptiveColors.textPrimary(context)),
                ),
              ),
            ),
          ],
        ),
      ),
        ),
        // Page citations from grounded mode, tap-through to the PDF.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: _buildCitationChips(message),
        ),
      ],
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
                        color: AdaptiveColors.primary(context),
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
            color: AdaptiveColors.outline(context).withValues(alpha: 0.35),
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
                  fillColor: AdaptiveColors.surfaceContainerHighest(context),
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
                tooltip: 'Send',
                onPressed: () => _sendMessage(_messageController.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
