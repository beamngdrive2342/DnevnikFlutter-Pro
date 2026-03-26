import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/ai_service.dart';
import '../data/firestore_service.dart';
import '../data/schedule_data.dart';
import '../theme/app_theme.dart';

final AIChatController aiChatController = AIChatController();

enum AIChatActivity {
  idle,
  thinking,
  typing,
}

class AIChatController extends ChangeNotifier {
  static const String _storageKey = 'ai_chat_history_v3';

  Future<void>? _initialization;
  List<Map<String, dynamic>> _messages = <Map<String, dynamic>>[_welcomeMessage()];
  AIChatActivity _activity = AIChatActivity.idle;
  String? _selectedImageBase64;

  List<Map<String, dynamic>> get messages => List.unmodifiable(_messages);
  AIChatActivity get activity => _activity;
  bool get isBusy => _activity != AIChatActivity.idle;
  bool get isThinking => _activity == AIChatActivity.thinking;
  bool get isTyping => _activity == AIChatActivity.typing;
  String? get selectedImageBase64 => _selectedImageBase64;

  Future<void> initialize() {
    return _initialization ??= _loadHistory();
  }

  void setSelectedImageBase64(String? value) {
    if (_selectedImageBase64 == value) {
      return;
    }
    _selectedImageBase64 = value;
    notifyListeners();
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    _messages = <Map<String, dynamic>>[_welcomeMessage()];
    _selectedImageBase64 = null;
    notifyListeners();
    await _saveHistory();
  }

  Future<bool> sendMessage(String rawText) async {
    await initialize();

    final text = rawText.trim();
    if (isBusy || (text.isEmpty && _selectedImageBase64 == null)) {
      return false;
    }

    final currentImage = _selectedImageBase64;
    _selectedImageBase64 = null;
    _messages.add(<String, dynamic>{
      'isUser': true,
      'text': text,
      'image': currentImage,
      'time': DateTime.now().toIso8601String(),
    });
    _activity = AIChatActivity.thinking;
    notifyListeners();
    await _saveHistory();
    unawaited(HapticFeedback.lightImpact());

    try {
      final diaryContext = await _buildDiaryContext();
      final responseText = await AIService.getAIResponse(
        text.isEmpty
            ? 'Проанализируй изображение и помоги пользователю.'
            : text,
        homeworkContext: diaryContext,
        base64Image: currentImage,
      );
      await _animateAssistantResponse(responseText);
    } catch (e) {
      _messages.add(<String, dynamic>{
        'isUser': false,
        'text': 'Произошла заминка. Попробуй отправить сообщение ещё раз.',
        'time': DateTime.now().toIso8601String(),
      });
      await _saveHistory();
    } finally {
      _activity = AIChatActivity.idle;
      notifyListeners();
    }

    return true;
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_storageKey);
      if (historyJson == null || historyJson.isEmpty) {
        return;
      }

      final decoded = jsonDecode(historyJson);
      if (decoded is! List) {
        return;
      }

      final restored = decoded
          .whereType<Map>()
          .map((raw) => Map<String, dynamic>.from(raw))
          .toList();
      if (restored.isEmpty) {
        return;
      }

      _messages = restored.map(_sanitizeLoadedMessage).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Load chat history error: $e');
    }
  }

  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(_messages));
    } catch (e) {
      debugPrint('Save chat history error: $e');
    }
  }

  Future<void> _animateAssistantResponse(String fullText) async {
    final normalizedText = fullText.trim().isEmpty
        ? 'Пока не получилось сформировать ответ.'
        : _removeModelMentions(fullText);
    final assistantMessage = <String, dynamic>{
      'isUser': false,
      'text': '',
      'time': DateTime.now().toIso8601String(),
    };
    _messages.add(assistantMessage);
    _activity = AIChatActivity.typing;
    notifyListeners();

    final tokens = RegExp(r'\S+\s*', multiLine: true)
        .allMatches(normalizedText)
        .map((match) => match.group(0)!)
        .toList();
    if (tokens.isEmpty) {
      tokens.add(normalizedText);
    }

    final buffer = StringBuffer();
    for (final token in tokens) {
      await Future<void>.delayed(const Duration(milliseconds: 30));
      buffer.write(token);
      assistantMessage['text'] = buffer.toString();
      notifyListeners();
    }

    await _saveHistory();
  }

  Future<String> _buildDiaryContext() async {
    final sb = StringBuffer();
    sb.writeln('ТЕКУЩЕЕ РАСПИСАНИЕ НА НЕДЕЛЮ:');
    weekSchedule.forEach((dayIndex, lessons) {
      sb.writeln('${weekdaysFull[dayIndex]}:');
      for (final lesson in lessons) {
        sb.writeln('- ${lesson.num}. ${lesson.subject} (${lesson.time})');
      }
    });

    sb.writeln('\nАКТУАЛЬНЫЕ ДОМАШНИЕ ЗАДАНИЯ:');
    try {
      final homework = await FirestoreService.getHomework();
      for (final item in homework) {
        sb.writeln(
          '- ПРЕДМЕТ: ${item.subject}, ЗАДАНИЕ: ${item.task}, СРОК: ${item.deadline}, СТАТУС: ${item.done ? 'выполнено' : 'не выполнено'}',
        );
      }
    } catch (e) {
      sb.writeln('Ошибка загрузки списка домашних заданий.');
    }

    return sb.toString();
  }

  Map<String, dynamic> _sanitizeLoadedMessage(Map<String, dynamic> message) {
    final sanitized = Map<String, dynamic>.from(message);
    if (sanitized['isUser'] == false && sanitized['text'] is String) {
      sanitized['text'] = _removeModelMentions(
        sanitized['text'] as String,
      );
    }
    return sanitized;
  }

  static Map<String, dynamic> _welcomeMessage() {
    return <String, dynamic>{
      'isUser': false,
      'text':
          'Здравствуй! Я вижу твоё расписание и задания только для помощи по делу. Можешь написать вопрос или прикрепить фото.',
      'time': DateTime.now().toIso8601String(),
    };
  }

  static String _removeModelMentions(String text) {
    return text
        .replaceAll(
          RegExp(r'\bGemma\s*3\s*27B\b', caseSensitive: false),
          'помощник',
        )
        .replaceAll(
          RegExp(r'\bGemma\s*3\b', caseSensitive: false),
          'помощник',
        )
        .replaceAll(RegExp(r'\bGemma\b', caseSensitive: false), 'помощник')
        .replaceAll(RegExp(r'\bGEMMA\b', caseSensitive: false), 'помощник')
        .trim();
  }
}

class AIChatBottomSheet extends StatefulWidget {
  const AIChatBottomSheet({super.key});

  @override
  State<AIChatBottomSheet> createState() => _AIChatBottomSheetState();
}

class _AIChatBottomSheetState extends State<AIChatBottomSheet> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  Timer? _scrollDebounce;

  @override
  void initState() {
    super.initState();
    unawaited(aiChatController.initialize());
    aiChatController.addListener(_handleChatChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _scrollDebounce?.cancel();
    aiChatController.removeListener(_handleChatChanged);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleChatChanged() {
    _scrollDebounce?.cancel();
    _scrollDebounce = Timer(const Duration(milliseconds: 16), () {
      if (!mounted) {
        return;
      }
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      final target = _scrollController.position.maxScrollExtent;
      _scrollController.jumpTo(target);
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final image = await _picker.pickImage(source: source, imageQuality: 50);
      if (image == null) {
        return;
      }
      final bytes = await image.readAsBytes();
      aiChatController.setSelectedImageBase64(base64Encode(bytes));
    } catch (e) {
      debugPrint('Pick image error: $e');
    }
  }

  Future<void> _handleSend() async {
    final didSend = await aiChatController.sendMessage(_controller.text);
    if (!didSend) {
      return;
    }
    _controller.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedBuilder(
      animation: aiChatController,
      builder: (context, _) {
        final messages = aiChatController.messages;
        final selectedImage = aiChatController.selectedImageBase64;

        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          margin: const EdgeInsets.only(top: 8),
          decoration: BoxDecoration(
            color: palette.bg.withValues(alpha: 0.98),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: const <BoxShadow>[
              BoxShadow(color: Colors.black38, blurRadius: 40),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Column(
                children: <Widget>[
                  const SizedBox(height: 12),
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: palette.onBg.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  _buildHeader(palette),
                  Expanded(
                    child: SelectionArea(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                        physics: const BouncingScrollPhysics(),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          return _buildMessageBubble(messages[index], palette);
                        },
                      ),
                    ),
                  ),
                  if (aiChatController.isBusy)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 20, bottom: 8),
                        child: _buildTypingIndicator(palette),
                      ),
                    ),
                  _buildInputArea(
                    palette,
                    bottomInset,
                    selectedImage,
                    aiChatController.isBusy,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(AppPalette palette) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Помощник',
                style: TextStyle(
                  fontFamily: AppTheme.fontSerif,
                  fontSize: 24,
                  fontWeight: FontWeight.normal,
                  color: palette.onBg,
                ),
              ),
              Row(
                children: <Widget>[
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'На связи, когда нужно',
                    style: TextStyle(
                      fontSize: 10,
                      color: palette.onSurface3,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: palette.bg.withValues(alpha: 1),
                  surfaceTintColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  title: Text(
                    'Очистить чат?',
                    style: TextStyle(
                      fontFamily: AppTheme.fontSerif,
                      color: palette.onBg,
                    ),
                  ),
                  content: Text(
                    'Вся переписка будет удалена.',
                    style: TextStyle(color: palette.onSurface2),
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(
                        'Отмена',
                        style: TextStyle(color: palette.onSurface3),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text(
                        'Удалить',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await aiChatController.clearHistory();
              }
            },
            icon: Icon(
              Icons.delete_outline_rounded,
              color: palette.onSurface3,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, AppPalette palette) {
    final isUser = msg['isUser'] == true;
    final text = (msg['text'] ?? '') as String;
    final imageBase64 = msg['image'] as String?;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: <Widget>[
          if (imageBase64 != null)
            Padding(
              padding: const EdgeInsets.all(4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.memory(
                  base64Decode(imageBase64),
                  width: MediaQuery.of(context).size.width * 0.65,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          if (text.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.85,
              ),
              decoration: BoxDecoration(
                color: isUser
                    ? AppTheme.primary
                    : palette.surface2.withValues(alpha: 0.4),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: isUser ? Colors.white : palette.onBg,
                  fontSize: 16,
                  height: 1.5,
                  letterSpacing: 0.1,
                  fontFamily: isUser ? null : AppTheme.fontSerif,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(AppPalette palette) {
    final label = aiChatController.isThinking ? 'Думает...' : 'Печатает...';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: palette.surface2.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.primary,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInputArea(
    AppPalette palette,
    double bottomInset,
    String? selectedImageBase64,
    bool isBusy,
  ) {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutQuart,
      padding: EdgeInsets.fromLTRB(20, 8, 20, bottomInset + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (selectedImageBase64 != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: palette.surface2.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: palette.cardBorder.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: <Widget>[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      base64Decode(selectedImageBase64),
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Фото прикреплено',
                          style: TextStyle(
                            color: palette.onBg,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Перед отправкой видно, что вложение добавлено.',
                          style: TextStyle(
                            color: palette.onSurface2,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: isBusy
                        ? null
                        : () => aiChatController.setSelectedImageBase64(null),
                    icon: Icon(
                      Icons.close_rounded,
                      color: palette.onSurface2,
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: <Widget>[
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: palette.surface2.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: palette.cardBorder.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      IconButton(
                        onPressed: isBusy
                            ? null
                            : () => _pickImage(ImageSource.gallery),
                        icon: Icon(
                          Icons.add_photo_alternate_outlined,
                          color: isBusy
                              ? palette.onSurface3.withValues(alpha: 0.45)
                              : palette.onSurface3,
                          size: 24,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          maxLines: null,
                          enabled: !isBusy,
                          onSubmitted: (_) => _handleSend(),
                          style: TextStyle(color: palette.onBg),
                          decoration: InputDecoration(
                            hintText: 'Напиши сообщение...',
                            hintStyle: TextStyle(
                              color: palette.onSurface3.withValues(alpha: 0.5),
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: isBusy ? null : _handleSend,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 160),
                  opacity: isBusy ? 0.55 : 1,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.north_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
