import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';
import '../data/ai_service.dart';
import '../data/firestore_service.dart';
import '../data/schedule_data.dart';

class AIChatBottomSheet extends StatefulWidget {
  const AIChatBottomSheet({super.key});

  @override
  State<AIChatBottomSheet> createState() => _AIChatBottomSheetState();
}

class _AIChatBottomSheetState extends State<AIChatBottomSheet> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  static const String _storageKey = 'ai_chat_history_v3';
  
  List<Map<String, dynamic>> _messages = [
    {
      'isUser': false,
      'text': 'Здравствуй! Я ассистент на базе Gemma 3. Чем могу помочь сегодня? ✨',
      'time': DateTime.now().toIso8601String(),
    },
  ];

  bool _isTyping = false;
  bool _isLoadingHistory = true;
  String? _selectedImageBase64;
  File? _imagePreviewFile;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_storageKey);
      if (historyJson != null) {
        final List<dynamic> decoded = jsonDecode(historyJson);
        setState(() {
          _messages = decoded.map((m) => Map<String, dynamic>.from(m)).toList();
          _isLoadingHistory = false;
        });
        _scrollToBottom(immediate: true);
      } else {
        setState(() => _isLoadingHistory = false);
      }
    } catch (e) {
      debugPrint("Load History Error: $e");
      setState(() => _isLoadingHistory = false);
    }
  }

  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(_messages));
    } catch (e) {
      debugPrint("Save History Error: $e");
    }
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    setState(() {
      _messages = [
        {
          'isUser': false,
          'text': 'История очищена. Жду вопросов! 📩',
          'time': DateTime.now().toIso8601String(),
        },
      ];
    });
  }

  void _scrollToBottom({bool immediate = false}) {
    Future.delayed(Duration(milliseconds: immediate ? 50 : 200), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutQuart,
        );
      }
    });
  }

  Future<String> _getHomeworkContext() async {
    try {
      final list = await FirestoreService.getHomework();
      if (list.isEmpty) return "Заданий пока нет.";
      final buffer = StringBuffer("БАЗА ДАННЫХ ДНЕВНИКА:\n");
      for (final hw in list) {
        buffer.writeln("- ${hw.subject} (${hw.deadline}): ${hw.task}");
      }
      return buffer.toString();
    } catch (e) {
      return "Ошибка доступа к базе.";
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageBase64 = base64Encode(bytes);
          _imagePreviewFile = File(image.path);
        });
        await HapticFeedback.mediumImpact();
      }
    } catch (e) {
      debugPrint("Pick Image Error: $e");
    }
  }

  void _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty && _selectedImageBase64 == null) return;

    final userMsg = {
      'isUser': true,
      'text': text,
      'image': _selectedImageBase64,
      'time': DateTime.now().toIso8601String(),
    };
    final currentImg = _selectedImageBase64;

    setState(() {
      _messages.add(userMsg);
      _controller.clear();
      _selectedImageBase64 = null;
      _imagePreviewFile = null;
      _isTyping = true;
    });
    _saveHistory();
    _scrollToBottom();
    await HapticFeedback.lightImpact();

    try {
      final contextText = await _getHomeworkContext();
      final responseText = await AIService.getAIResponse(
        text.isEmpty ? "Проанализируй фото." : text,
        homeworkContext: contextText,
        base64Image: currentImg,
      );
      
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add({
          'isUser': false,
          'text': responseText,
          'time': DateTime.now().toIso8601String(),
        });
      });
      _saveHistory();
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add({'isUser': false, 'text': 'Техническая заминка. Повторим?'});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.colorsOf(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isDark = ThemeController.isDark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: palette.bg.withValues(alpha: 0.98),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 40)],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 36, height: 4, decoration: BoxDecoration(color: palette.onBg.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(2))),
              
              _buildHeader(palette),
              
              Expanded(
                child: SelectionArea(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) => _buildMessageBubble(_messages[index], palette),
                  ),
                ),
              ),

              if (_isTyping) Align(alignment: Alignment.centerLeft, child: Padding(padding: const EdgeInsets.only(left: 20, bottom: 8), child: _buildTypingIndicator(palette))),

              _buildInputArea(palette, bottomInset),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppPalette palette) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('NVIDIA Nemotron VL', style: TextStyle(fontFamily: AppTheme.fontSerif, fontSize: 24, fontWeight: FontWeight.normal, color: palette.onBg)),
            Row(children: [
              Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text('Умный ассистент', style: TextStyle(fontSize: 10, color: palette.onSurface3, letterSpacing: 0.5)),
            ]),
          ]),
          const Spacer(),
          IconButton(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: palette.bg.withValues(alpha: 1.0), // SOLID OPAQUE BACKGROUND
                  surfaceTintColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  title: Text('Очистить чат?', style: TextStyle(fontFamily: AppTheme.fontSerif, color: palette.onBg)),
                  content: Text('Вся история переписки будет стерта безвозвратно.', style: TextStyle(color: palette.onSurface2)),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Отмена', style: TextStyle(color: palette.onSurface3))),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Очистить', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold))),
                  ],
                ),
              );
              if (confirm == true) _clearHistory();
            },
            icon: Icon(Icons.delete_outline_rounded, color: palette.onSurface3, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, AppPalette palette) {
    final bool isUser = msg['isUser'] ?? false;
    final String text = msg['text'] ?? '';
    final String? imageBase64 = msg['image'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (imageBase64 != null)
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.memory(base64Decode(imageBase64), width: MediaQuery.of(context).size.width * 0.65, fit: BoxFit.cover),
              ),
            ),
          if (text.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
              decoration: BoxDecoration(
                color: isUser ? AppTheme.primary : palette.surface2.withValues(alpha: 0.4),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
              ),
              child: Text(text, style: TextStyle(color: isUser ? Colors.white : palette.onBg, fontSize: 16, height: 1.5)),
            ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(AppPalette palette) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(color: palette.surface2.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(16)), child: Text('• • •', style: TextStyle(color: AppTheme.primary, fontSize: 10)));
  }

  Widget _buildInputArea(AppPalette palette, double bottomInset) {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutQuart,
      padding: EdgeInsets.fromLTRB(20, 8, 20, bottomInset + 32),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(color: palette.surface2.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(28), border: Border.all(color: palette.cardBorder.withValues(alpha: 0.2))),
              child: Row(children: [
                IconButton(onPressed: () => _pickImage(ImageSource.gallery), icon: Icon(Icons.add_photo_alternate_outlined, color: palette.onSurface3, size: 24)),
                Expanded(child: TextField(controller: _controller, maxLines: null, style: TextStyle(color: palette.onBg), decoration: InputDecoration(hintText: 'Ваш вопрос...', hintStyle: TextStyle(color: palette.onSurface3.withValues(alpha: 0.5)), border: InputBorder.none))),
              ]),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(onTap: _handleSend, child: Container(width: 48, height: 48, decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle), child: const Icon(Icons.north_rounded, color: Colors.white, size: 24))),
        ],
      ),
    );
  }
}
