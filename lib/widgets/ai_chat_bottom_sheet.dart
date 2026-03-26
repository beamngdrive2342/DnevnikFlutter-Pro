import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';
import '../data/ai_service.dart';

class AIChatBottomSheet extends StatefulWidget {
  const AIChatBottomSheet({super.key});

  @override
  State<AIChatBottomSheet> createState() => _AIChatBottomSheetState();
}

class _AIChatBottomSheetState extends State<AIChatBottomSheet> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  static const String _storageKey = 'ai_chat_history';
  
  List<Map<String, dynamic>> _messages = [
    {
      'isUser': false,
      'text': 'Привет! Я твой ИИ-помощник. Чем могу помочь с учёбой сегодня?',
      'time': DateTime.now().toIso8601String(),
    },
  ];
  bool _isTyping = false;
  bool _isLoadingHistory = true;

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
      debugPrint("Error loading chat history: $e");
      setState(() => _isLoadingHistory = false);
    }
  }

  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(_messages));
    } catch (e) {
      debugPrint("Error saving chat history: $e");
    }
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    setState(() {
      _messages = [
        {
          'isUser': false,
          'text': 'Привет! Я твой ИИ-помощник. Чем могу помочь с учёбой сегодня?',
          'time': DateTime.now().toIso8601String(),
        },
      ];
    });
  }

  void _scrollToBottom({bool immediate = false}) {
    Future.delayed(Duration(milliseconds: immediate ? 50 : 150), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: immediate ? 10 : 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final userMsg = {
      'isUser': true,
      'text': text,
      'time': DateTime.now().toIso8601String(),
    };

    setState(() {
      _messages.add(userMsg);
      _controller.clear();
      _isTyping = true;
    });
    _saveHistory();
    _scrollToBottom();
    await HapticFeedback.lightImpact();

    try {
      final responseText = await AIService.getAIResponse(text);
      if (!mounted) return;
      
      final aiMsg = {
        'isUser': false,
        'text': responseText,
        'time': DateTime.now().toIso8601String(),
      };

      setState(() {
        _isTyping = false;
        _messages.add(aiMsg);
      });
      _saveHistory();
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add({
          'isUser': false,
          'text': 'Произошла ошибка. Попробуй еще раз!',
          'time': DateTime.now().toIso8601String(),
        });
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = ThemeController.isDark;
    final palette = AppTheme.colorsOf(context);

    // Dynamic height based on keyboard
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Container(
      height: MediaQuery.of(context).size.height * (isKeyboardOpen ? 0.95 : 0.85),
      decoration: BoxDecoration(
        color: palette.bg.withValues(alpha: 0.93),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Column(
            children: [
              // Handle
              const SizedBox(height: 12),
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: palette.onBg.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              const SizedBox(height: 12),
              
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.3),
                            blurRadius: 10,
                            spreadRadius: -2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: AppTheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Помощник',
                          style: TextStyle(
                            fontFamily: AppTheme.fontSerif,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: palette.onBg,
                          ),
                        ),
                        Text(
                          _isTyping ? 'Печатает...' : 'В сети',
                          style: TextStyle(
                            fontSize: 12,
                            color: _isTyping ? AppTheme.primary : Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Clear History Button
                    IconButton(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: palette.cardBg,
                            title: const Text('Очистить чат?'),
                            content: const Text('Вся история переписки будет удалена навсегда.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: Text('Отмена', style: TextStyle(color: palette.onSurface3)),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Очистить', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          _clearHistory();
                          HapticFeedback.mediumImpact();
                        }
                      },
                      icon: Icon(Icons.delete_sweep_rounded, color: palette.onSurface3, size: 22),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close_rounded, color: palette.onSurface2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: palette.cardBorder),
              
              // Chat List
              Expanded(
                child: _isLoadingHistory 
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                      physics: const BouncingScrollPhysics(),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        return _buildMessageBubble(_messages[index]);
                      },
                    ),
              ),

              if (_isTyping)
                Padding(
                  padding: const EdgeInsets.only(left: 20, bottom: 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _buildTypingIndicator(),
                  ),
                ),

              // Input
              _buildInputArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    final bool isUser = msg['isUser'] ?? false;
    final palette = AppTheme.colorsOf(context);
    final String text = msg['text'] ?? '';
    final String timeStr = msg['time'] ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) ...[
                _buildAvatar(),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: GestureDetector(
                  onLongPress: () {
                    Clipboard.setData(ClipboardData(text: text));
                    HapticFeedback.vibrate();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Текст скопирован'),
                        duration: Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: isUser
                          ? const LinearGradient(
                              colors: [AppTheme.primary, AppTheme.primaryDim],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : LinearGradient(
                              colors: [
                                palette.surface2.withValues(alpha: 0.95),
                                palette.surface3.withValues(alpha: 0.8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(24),
                        topRight: const Radius.circular(24),
                        bottomLeft: Radius.circular(isUser ? 24 : 6),
                        bottomRight: Radius.circular(isUser ? 6 : 24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Text(
                      text,
                      style: TextStyle(
                        color: isUser ? Colors.white : palette.onBg,
                        fontSize: 15.5,
                        height: 1.45,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ),
              if (isUser) ...[
                const SizedBox(width: 8),
                _buildUserAvatar(),
              ],
            ],
          ),
          const SizedBox(height: 5),
          Padding(
            padding: EdgeInsets.only(
              left: isUser ? 0 : 44,
              right: isUser ? 44 : 0,
            ),
            child: Text(
              _formatTimeString(timeStr),
              style: TextStyle(
                fontSize: 10,
                color: palette.onSurface3.withValues(alpha: 0.6),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
      ),
      child: const Icon(Icons.auto_awesome_rounded, color: AppTheme.primary, size: 16),
    );
  }

  Widget _buildUserAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppTheme.primaryDim.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.primaryDim.withValues(alpha: 0.3)),
      ),
      child: const Center(
        child: Text('И',
            style: TextStyle(
                color: AppTheme.primaryDim,
                fontSize: 14,
                fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    final palette = AppTheme.colorsOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: palette.surface2.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) => _buildTypingDot(i)),
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return Container(
      width: 5,
      height: 5,
      margin: const EdgeInsets.symmetric(horizontal: 2.5),
      decoration: const BoxDecoration(
        color: AppTheme.primary,
        shape: BoxShape.circle,
      ),
    ).animateTyping(index);
  }

  Widget _buildInputArea() {
    final palette = AppTheme.colorsOf(context);
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: palette.surface.withValues(alpha: 0.6),
        border: Border(top: BorderSide(color: palette.cardBorder.withValues(alpha: 0.5))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: palette.surface2.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: palette.cardBorder),
              ),
              child: TextField(
                controller: _controller,
                style: TextStyle(color: palette.onBg, fontSize: 16),
                maxLines: null,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  hintText: 'Спроси что-нибудь...',
                  hintStyle: TextStyle(
                    color: palette.onSurface3.withValues(alpha: 0.5),
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _handleSend(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _handleSend,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryDim],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeString(String isoString) {
    try {
      final time = DateTime.parse(isoString);
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }
}

extension TypingAnimation on Widget {
  Widget animateTyping(int index) {
    return _TypingDotAnimation(index: index, child: this);
  }
}

class _TypingDotAnimation extends StatefulWidget {
  final int index;
  final Widget child;
  const _TypingDotAnimation({required this.index, required this.child});

  @override
  State<_TypingDotAnimation> createState() => _TypingDotAnimationState();
}

class _TypingDotAnimationState extends State<_TypingDotAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = Tween<double>(begin: 0, end: -8).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(
          widget.index * 0.2,
          0.6 + widget.index * 0.2,
          curve: Curves.easeInOut,
        ),
      ),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _controller.forward();
      }
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
