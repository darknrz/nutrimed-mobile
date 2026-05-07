import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_storage.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});
  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final List<_Message> _messages = [];
  final _inputCtrl  = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _loading     = false;

  final List<String> _suggestions = [
    '¿Qué puedo desayunar?',
    '¿Puedo comer arroz?',
    'Alimentos que debo evitar',
    '¿Qué snack es saludable?',
    'Plan para esta semana',
  ];

  @override
  void initState() {
    super.initState();
    _messages.add(_Message(
      text: '¡Hola! Soy NutriBot 🌿\n\nEstoy aquí para ayudarte con tus consultas nutricionales personalizadas según tu perfil de salud.\n\n¿En qué puedo ayudarte hoy?',
      isBot: true,
    ));
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    _inputCtrl.clear();

    setState(() {
      _messages.add(_Message(text: text, isBot: false));
      _loading = true;
    });
    _scrollToBottom();

    try {
      final userId = await sl<SecureStorage>().getUserId() ?? '0';
      final res    = await sl<DioClient>().post(
        ApiConstants.chatbot,
        {'userId': int.parse(userId), 'message': text},
      );
      final reply = res.data['message'] as String? ?? 'No pude procesar tu consulta.';
      setState(() {
        _messages.add(_Message(text: reply, isBot: true));
        _loading = false;
      });
    } on DioException {
      setState(() {
        _messages.add(_Message(
          text: 'Error al conectar. Verifica tu conexión.',
          isBot: true, isError: true,
        ));
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _messages.add(_Message(
          text: 'Ocurrió un error inesperado.',
          isBot: true, isError: true,
        ));
        _loading = false;
      });
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildMessages()),
            if (_messages.length == 1) _buildSuggestions(),
            _buildInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F8EF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF3ECF7C), width: 0.5),
            ),
            child: const Center(child: Text('🌿', style: TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('NutriBot',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              Text('Asistente nutricional IA',
                  style: TextStyle(fontSize: 11, color: Color(0xFF1A7A45))),
            ],
          ),
          const Spacer(),
          Container(
            width: 8, height: 8,
            decoration: const BoxDecoration(
                color: Color(0xFF22C55E), shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          const Text('En línea',
              style: TextStyle(fontSize: 11, color: Color(0xFF1A7A45))),
        ],
      ),
    );
  }

  Widget _buildMessages() {
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      itemCount: _messages.length + (_loading ? 1 : 0),
      itemBuilder: (context, i) {
        if (i == _messages.length) return _buildTyping();
        return _buildMessageBubble(_messages[i]);
      },
    );
  }

  Widget _buildMessageBubble(_Message msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: msg.isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (msg.isBot) ...[
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F8EF),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF3ECF7C), width: 0.5),
              ),
              child: const Center(child: Text('🌿', style: TextStyle(fontSize: 13))),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                // bot → gris claro  |  usuario → rojo suave
                color: msg.isBot
                    ? AppColors.surface
                    : const Color(0xFFFFEEF1),
                borderRadius: BorderRadius.only(
                  topLeft:     const Radius.circular(16),
                  topRight:    const Radius.circular(16),
                  bottomLeft:  Radius.circular(msg.isBot ? 4 : 16),
                  bottomRight: Radius.circular(msg.isBot ? 16 : 4),
                ),
                border: Border.all(
                  color: msg.isError
                      ? AppColors.error.withOpacity(0.4)
                      : msg.isBot
                      ? AppColors.border
                      : const Color(0xFFFFB3C1),
                  width: 0.5,
                ),
              ),
              child: Text(msg.text,
                  style: TextStyle(
                    fontSize: 13,
                    color: msg.isError
                        ? AppColors.error
                        : AppColors.textPrimary,
                    height: 1.5,
                  )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTyping() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F8EF),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF3ECF7C), width: 0.5),
            ),
            child: const Center(child: Text('🌿', style: TextStyle(fontSize: 13))),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.only(
                topLeft:     Radius.circular(16),
                topRight:    Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft:  Radius.circular(4),
              ),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [_dot(0), _dot(150), _dot(300)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(int delayMs) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (context, value, _) => Opacity(
        opacity: value,
        child: Container(
          width: 6, height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: const BoxDecoration(
              color: Color(0xFF22C55E), shape: BoxShape.circle),
        ),
      ),
    );
  }

  Widget _buildSuggestions() {
    return SizedBox(
      height: 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        itemCount: _suggestions.length,
        itemBuilder: (context, i) => GestureDetector(
          onTap: () => _sendMessage(_suggestions[i]),
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Text(_suggestions[i],
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ),
        ),
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: TextField(
                controller: _inputCtrl,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: _sendMessage,
                decoration: const InputDecoration(
                  hintText: 'Escribe tu consulta…',
                  hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _loading ? null : () => _sendMessage(_inputCtrl.text),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: _loading ? AppColors.border : AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: _loading
                  ? Center(
                  child: SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary),
                  ))
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _Message {
  final String text;
  final bool   isBot;
  final bool   isError;
  const _Message({
    required this.text,
    required this.isBot,
    this.isError = false,
  });
}