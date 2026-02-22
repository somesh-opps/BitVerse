import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'gradient.dart';
import 'user_session.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with TickerProviderStateMixin {
  // ── Server config ────────────────────────────────────────────────────
  static const String _serverBaseUrl = 'http://10.35.146.149:8000'; // plant AI (local_ai_server.py)
  static const String _appBaseUrl    = 'http://10.35.146.180:5000'; // main backend (app.py)

  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  bool _isSidebarOpen = false;
  bool _isLoadingSessions = true;

  late AnimationController _typingController;
  late AnimationController _headerController;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;
  late AnimationController _sidebarController;
  late Animation<double> _sidebarAnim;

  // Chat sessions
  final List<_ChatSession> _sessions = [
    _ChatSession(
      id: '1',
      title: 'Welcome to CropIntel',
      messages: [
        _ChatMessage(
          text: 'Hello! I\'m CropIntel AI 🌿\nHow can I help you with your crops today?',
          isUser: false,
          time: '09:00 AM',
        ),
      ],
    ),
  ];
  int _currentSessionIndex = 0;

  List<_ChatMessage> get _messages => _sessions[_currentSessionIndex].messages;

  @override
  void initState() {
    super.initState();

    _typingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _headerFade = CurvedAnimation(
        parent: _headerController, curve: Curves.easeIn);
    _headerSlide = Tween<Offset>(
            begin: const Offset(0, -0.2), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _headerController, curve: Curves.easeOut));
    _headerController.forward();

    _sidebarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _sidebarAnim = CurvedAnimation(
        parent: _sidebarController, curve: Curves.easeOut);

    _loadSessions();
  }

  @override
  void dispose() {
    _typingController.dispose();
    _headerController.dispose();
    _sidebarController.dispose();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Sidebar controls ─────────────────────────────────────────────────

  // ── Backend: load / save / delete ────────────────────────────────────

  Future<void> _loadSessions() async {
    final userId = UserSession.instance.userId;
    if (userId.isEmpty) {
      setState(() => _isLoadingSessions = false);
      return;
    }
    try {
      final response = await http
          .get(Uri.parse('$_appBaseUrl/chat/sessions?user_id=$userId'))
          .timeout(const Duration(seconds: 10));
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final list = data['sessions'] as List<dynamic>;
        if (list.isNotEmpty) {
          final loaded = list.map((s) {
            final msgs = (s['messages'] as List<dynamic>).map((m) {
              return _ChatMessage(
                text: m['text'] as String? ?? '',
                isUser: m['is_user'] as bool? ?? false,
                time: m['time'] as String? ?? '',
              );
            }).toList();
            return _ChatSession(
              id: s['session_id'] as String,
              title: s['title'] as String? ?? 'Chat',
              messages: msgs,
            );
          }).toList();
          setState(() {
            _sessions
              ..clear()
              ..addAll(loaded);
            _currentSessionIndex = 0;
            _isLoadingSessions = false;
          });
          return;
        }
      }
    } catch (_) {}
    setState(() => _isLoadingSessions = false);
  }

  Future<void> _saveSession(int index) async {
    final userId = UserSession.instance.userId;
    if (userId.isEmpty || index < 0 || index >= _sessions.length) return;
    final session = _sessions[index];
    final messagesJson = session.messages.map((m) => {
      'text': m.text,
      'is_user': m.isUser,
      'time': m.time,
      'has_image': m.imagePath != null,
    }).toList();
    try {
      await http
          .post(
            Uri.parse('$_appBaseUrl/chat/sessions/save'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'user_id': userId,
              'session': {
                'session_id': session.id,
                'title': session.title,
                'messages': messagesJson,
              },
            }),
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  Future<void> _deleteSessionRemote(String sessionId) async {
    final userId = UserSession.instance.userId;
    if (userId.isEmpty) return;
    try {
      await http
          .delete(
            Uri.parse('$_appBaseUrl/chat/sessions/$sessionId?user_id=$userId'),
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  void _toggleSidebar() {
    setState(() => _isSidebarOpen = !_isSidebarOpen);
    if (_isSidebarOpen) {
      _sidebarController.forward();
    } else {
      _sidebarController.reverse();
    }
  }

  void _closeSidebar() {
    if (_isSidebarOpen) {
      setState(() => _isSidebarOpen = false);
      _sidebarController.reverse();
    }
  }

  void _startNewChat() {
    final newSession = _ChatSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'New Chat',
      messages: [
        _ChatMessage(
          text: 'Hello! I\'m CropIntel AI 🌿\nHow can I help you with your crops today?',
          isUser: false,
          time: _timeNow(),
        ),
      ],
    );
    setState(() {
      _sessions.insert(0, newSession);
      _currentSessionIndex = 0;
    });
    _saveSession(0);
    _closeSidebar();
    _scrollToBottom();
  }

  void _switchSession(int index) {
    setState(() => _currentSessionIndex = index);
    _closeSidebar();
    _scrollToBottom();
  }

  void _deleteSession(int index) {
    final sessionId = _sessions[index].id;
    _deleteSessionRemote(sessionId);
    if (_sessions.length == 1) {
      setState(() {
        _sessions[0] = _ChatSession(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: 'New Chat',
          messages: [
            _ChatMessage(
              text: 'Hello! I\'m CropIntel AI 🌿\nHow can I help you with your crops today?',
              isUser: false,
              time: _timeNow(),
            ),
          ],
        );
        _currentSessionIndex = 0;
      });
      return;
    }
    setState(() {
      _sessions.removeAt(index);
      if (_currentSessionIndex >= _sessions.length) {
        _currentSessionIndex = _sessions.length - 1;
      } else if (_currentSessionIndex > index) {
        _currentSessionIndex--;
      }
    });
  }

  void _sendMessage() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(
        text: text,
        isUser: true,
        time: _timeNow(),
      ));
      _isTyping = true;

      // Update session title from first user message
      final session = _sessions[_currentSessionIndex];
      if (session.title == 'New Chat' || session.title == 'Welcome to CropIntel') {
        _sessions[_currentSessionIndex] = _ChatSession(
          id: session.id,
          title: text.length > 32 ? '${text.substring(0, 32)}…' : text,
          messages: session.messages,
        );
      }
    });
    _inputController.clear();
    _scrollToBottom();

    // ── Real AI response from Ollama via local_ai_server ──────────────
    _getChatReply(text);
  }

  Future<void> _getChatReply(String userText) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_serverBaseUrl/chat'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'message': userText}),
          )
          .timeout(const Duration(seconds: 120));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final reply = (data['reply'] as String? ?? '').trim();
        setState(() {
          _isTyping = false;
          _messages.add(_ChatMessage(
            text: reply.isNotEmpty ? reply : 'Sorry, I could not generate a response.',
            isUser: false,
            time: _timeNow(),
          ));
        });
      } else {
        setState(() {
          _isTyping = false;
          _messages.add(_ChatMessage(
            text: 'The AI server returned an error (HTTP ${response.statusCode}). Please try again.',
            isUser: false,
            time: _timeNow(),
          ));
        });
      }
    } on SocketException {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(_ChatMessage(
          text: 'Could not reach the AI server. Make sure the local server is running and accessible on this network.',
          isUser: false,
          time: _timeNow(),
        ));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(_ChatMessage(
          text: 'An error occurred: $e',
          isUser: false,
          time: _timeNow(),
        ));
      });
    }
    _scrollToBottom();
    _saveSession(_currentSessionIndex);
  }

  // ── Image analysis ───────────────────────────────────────────────────

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D1830),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Analyze Plant Image',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Select a photo of your plant for AI disease diagnosis',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _sourceOption(Icons.camera_alt_rounded, 'Take a Photo', () {
              Navigator.pop(context);
              _pickAndAnalyzeImage(ImageSource.camera);
            }),
            _sourceOption(Icons.photo_library_rounded, 'Choose from Gallery', () {
              Navigator.pop(context);
              _pickAndAnalyzeImage(ImageSource.gallery);
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _sourceOption(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFF00EFDF).withValues(alpha: 0.12),
        ),
        child: Icon(icon, color: const Color(0xFF00EFDF), size: 22),
      ),
      title: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  Future<void> _pickAndAnalyzeImage(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: source,
      imageQuality: 85,
    );
    if (picked == null) return;
    await _analyzeImage(File(picked.path));
  }

  Future<void> _analyzeImage(File imageFile) async {
    // Show the image as a user message
    setState(() {
      _messages.add(_ChatMessage(
        text: '',
        isUser: true,
        time: _timeNow(),
        imagePath: imageFile.path,
      ));
      _isTyping = true;
      final session = _sessions[_currentSessionIndex];
      if (session.title == 'New Chat' || session.title == 'Welcome to CropIntel') {
        _sessions[_currentSessionIndex] = _ChatSession(
          id: session.id,
          title: 'Plant Disease Scan',
          messages: session.messages,
        );
      }
    });
    _scrollToBottom();

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_serverBaseUrl/analyze-plant'),
      );
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          contentType: MediaType(
            'image',
            imageFile.path.split('.').last.toLowerCase().replaceAll('jpg', 'jpeg'),
          ),
        ),
      );

      final streamed = await request.send().timeout(
        const Duration(seconds: 120),
      );
      final response = await http.Response.fromStream(streamed);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final diagnosis =
            data['diagnosis'] as String? ?? 'No diagnosis returned.';
        setState(() {
          _isTyping = false;
          _messages.add(_ChatMessage(
            text: diagnosis,
            isUser: false,
            time: _timeNow(),
          ));
        });
        _saveSession(_currentSessionIndex);
      } else {
        setState(() {
          _isTyping = false;
          _messages.add(_ChatMessage(
            text:
                'Error analyzing image (HTTP ${response.statusCode}).\nPlease check the server logs.',
            isUser: false,
            time: _timeNow(),
          ));
        });
      }
    } on SocketException {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(_ChatMessage(
          text:
              'Could not reach the AI server. Make sure it is running and accessible from this device.',
          isUser: false,
          time: _timeNow(),
        ));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(_ChatMessage(
          text: 'An error occurred: $e',
          isUser: false,
          time: _timeNow(),
        ));
      });
    }
    _scrollToBottom();
  }

  String _timeNow() {
    final now = DateTime.now();
    final h = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final m = now.minute.toString().padLeft(2, '0');
    final suffix = now.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $suffix';
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      resizeToAvoidBottomInset: true,
      body: AuroraGradient(
        child: SafeArea(
          child: Stack(
            children: [
              // ── Main chat area ─────────────────────────────────────
              Column(
                children: [
                  SlideTransition(
                    position: _headerSlide,
                    child: FadeTransition(
                      opacity: _headerFade,
                      child: _buildHeader(context),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: _closeSidebar,
                      child: _isLoadingSessions
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF00EFDF),
                                strokeWidth: 2,
                              ),
                            )
                          : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        addAutomaticKeepAlives: false,
                        addRepaintBoundaries: false,
                        itemCount: _messages.length + (_isTyping ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _messages.length && _isTyping) {
                            return _buildTypingIndicator();
                          }
                          final msg = _messages[index];
                          return _buildBubble(msg, index);
                        },
                      ),
                    ),
                  ),
                  _buildInputBar(),
                ],
              ),

              // ── Sidebar backdrop ───────────────────────────────────
              AnimatedBuilder(
                animation: _sidebarAnim,
                builder: (_, __) {
                  if (_sidebarAnim.value == 0) return const SizedBox.shrink();
                  return GestureDetector(
                    onTap: _closeSidebar,
                    child: Container(
                      color: Colors.black
                          .withValues(alpha: 0.55 * _sidebarAnim.value),
                    ),
                  );
                },
              ),

              // ── Sidebar panel ──────────────────────────────────────
              AnimatedBuilder(
                animation: _sidebarAnim,
                builder: (_, child) => Transform.translate(
                  offset: Offset(-300 * (1 - _sidebarAnim.value), 0),
                  child: child,
                ),
                child: _buildSidebar(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 18, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1830).withValues(alpha: 0.85),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.07),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // AI avatar
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF00C896), Color(0xFF00EFDF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00EFDF).withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset('images/logo.jpeg', fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 12),

          // Name + active session subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CropIntel AI',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _sessions[_currentSessionIndex].title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.38),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          // Sidebar toggle (hamburger / close)
          GestureDetector(
            onTap: _toggleSidebar,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isSidebarOpen
                    ? const Color(0xFF00EFDF).withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.07),
                border: Border.all(
                  color: _isSidebarOpen
                      ? const Color(0xFF00EFDF).withValues(alpha: 0.35)
                      : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Icon(
                _isSidebarOpen ? Icons.close_rounded : Icons.menu_rounded,
                color: _isSidebarOpen
                    ? const Color(0xFF00EFDF)
                    : Colors.white70,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sidebar ───────────────────────────────────────────────────────────

  Widget _buildSidebar() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: 300,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0B1426), Color(0xFF0D1830)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border(
            right: BorderSide(
              color: const Color(0xFF00EFDF).withValues(alpha: 0.12),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.55),
              blurRadius: 30,
              offset: const Offset(8, 0),
            ),
          ],
        ),
        child: Column(
          children: [
            // Sidebar header
            Container(
              padding: const EdgeInsets.fromLTRB(18, 18, 14, 14),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.06),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00C896), Color(0xFF00EFDF)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00EFDF).withValues(alpha: 0.30),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset('images/logo.jpeg', fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'CropIntel AI',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _closeSidebar,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        color: Colors.white.withValues(alpha: 0.55),
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // New Chat button
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
              child: GestureDetector(
                onTap: _startNewChat,
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00C896), Color(0xFF00EFDF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00EFDF).withValues(alpha: 0.30),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_rounded,
                          color: Color(0xFF041810), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'New Chat',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF041810),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Section label
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'RECENT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.28),
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),

            // Chat history list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 20),
                itemCount: _sessions.length,
                itemBuilder: (context, index) {
                  final session = _sessions[index];
                  final isActive = index == _currentSessionIndex;
                  return GestureDetector(
                    onTap: () => _switchSession(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: isActive
                            ? LinearGradient(
                                colors: [
                                  const Color(0xFF00EFDF)
                                      .withValues(alpha: 0.12),
                                  const Color(0xFF3B5BA5)
                                      .withValues(alpha: 0.10),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isActive
                              ? const Color(0xFF00EFDF).withValues(alpha: 0.25)
                              : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? const Color(0xFF00EFDF)
                                      .withValues(alpha: 0.15)
                                  : Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 15,
                              color: isActive
                                  ? const Color(0xFF00EFDF)
                                  : Colors.white.withValues(alpha: 0.38),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              session.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isActive
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isActive
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.60),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => _deleteSession(index),
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.delete_outline_rounded,
                                size: 14,
                                color: Colors.white.withValues(alpha: 0.25),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Sidebar footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withValues(alpha: 0.06),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B5BA5), Color(0xFF5270C0)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3B5BA5).withValues(alpha: 0.35),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.person_rounded,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          UserSession.instance.name.isNotEmpty
                              ? UserSession.instance.name
                              : 'Farmer',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${_sessions.length} chat${_sessions.length == 1 ? '' : 's'}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Message bubble ───────────────────────────────────────────────────

  Widget _buildBubble(_ChatMessage msg, int index) {
    final isUser = msg.isUser;

    // Group: hide avatar if previous message is from same sender
    final bool showAvatar = !isUser &&
        (index == 0 || _messages[index - 1].isUser);

    return Padding(
      padding: EdgeInsets.only(
        top: 4,
        bottom: 4,
        left: isUser ? 48 : 0,
        right: isUser ? 0 : 48,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          // AI avatar
          if (!isUser)
            Padding(
              padding: const EdgeInsets.only(right: 8, bottom: 2),
              child: showAvatar
                  ? Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFF00C896), Color(0xFF00EFDF)],
                        ),
                      ),
                      child: ClipOval(
                        child: Image.asset('images/logo.jpeg',
                            fit: BoxFit.cover),
                      ),
                    )
                  : const SizedBox(width: 30),
            ),

          // Bubble
          Flexible(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: isUser
                        ? const LinearGradient(
                            colors: [
                              Color(0xFF00BFAE),
                              Color(0xFF0077B6),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isUser ? null : const Color(0xFF141E35),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft:
                          Radius.circular(isUser ? 20 : 4),
                      bottomRight:
                          Radius.circular(isUser ? 4 : 20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isUser
                            ? const Color(0xFF00BFAE)
                                .withValues(alpha: 0.25)
                            : Colors.black.withValues(alpha: 0.20),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: isUser
                        ? null
                        : Border.all(
                            color: Colors.white.withValues(alpha: 0.06),
                            width: 1,
                          ),
                  ),
                  child: msg.imagePath != null
                      ? _buildImageContent(msg)
                      : _buildMessageText(msg.text, isUser),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    msg.time,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.30),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Render image bubble content
  Widget _buildImageContent(_ChatMessage msg) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(msg.imagePath!),
            width: 220,
            height: 220,
            fit: BoxFit.cover,
          ),
        ),
        if (msg.text.isNotEmpty) ...
          [
            const SizedBox(height: 8),
            _buildMessageText(msg.text, msg.isUser),
          ],
      ],
    );
  }

  // Render bold (**text**) inline
  Widget _buildMessageText(String text, bool isUser) {
    final parts = text.split('**');
    final spans = <TextSpan>[];
    for (int i = 0; i < parts.length; i++) {
      spans.add(TextSpan(
        text: parts[i],
        style: TextStyle(
          fontWeight: i.isOdd ? FontWeight.bold : FontWeight.normal,
          fontSize: 14,
          color: isUser ? Colors.white : const Color(0xFFCFE8F0),
          height: 1.55,
        ),
      ));
    }
    return RichText(text: TextSpan(children: spans));
  }

  // ── Typing indicator ────────────────────────────────────────────────

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 0, right: 48),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 2),
            child: Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF00C896), Color(0xFF00EFDF)],
                ),
              ),
              child: ClipOval(
                child:
                    Image.asset('images/logo.jpeg', fit: BoxFit.cover),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF141E35),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(20),
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.06),
                width: 1,
              ),
            ),
            child: AnimatedBuilder(
              animation: _typingController,
              builder: (_, __) {
                final v = _typingController.value;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final t = ((v - i * 0.3).clamp(0.0, 1.0));
                    final dy =
                        -5.0 * (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0);
                    return Transform.translate(
                      offset: Offset(0, dy),
                      child: Container(
                        margin:
                            const EdgeInsets.symmetric(horizontal: 3),
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              Color.fromRGBO(0, 239, 223, 0.7 + 0.3 * t),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Input bar ───────────────────────────────────────────────────────

  Widget _buildInputBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 18),
      child: Container(
        height: 62,
        decoration: BoxDecoration(
          color: const Color(0xFF0B1628),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: const Color(0xFF00EFDF).withValues(alpha: 0.35),
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00EFDF).withValues(alpha: 0.10),
              blurRadius: 22,
              spreadRadius: 1,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 6),

            // + button (image picker → plant analysis)
            GestureDetector(
              onTap: _showImageSourceSheet,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF152030),
                  border: Border.all(
                    color: const Color(0xFF00EFDF).withValues(alpha: 0.20),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.add_rounded,
                  color: const Color(0xFF00EFDF).withValues(alpha: 0.75),
                  size: 24,
                ),
              ),
            ),

            const SizedBox(width: 10),

            // Text field
            Expanded(
              child: Center(
              child: TextField(
                controller: _inputController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                maxLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: 'Ask about your crops...',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.30),
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  suffixIcon: GestureDetector(
                    onTap: () {},
                    child: Icon(
                      Icons.mic_rounded,
                      color: const Color(0xFF00EFDF).withValues(alpha: 0.60),
                      size: 22,
                    ),
                  ),
                ),
              ),
              ),
            ),

            const SizedBox(width: 6),

            // Send button
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF00DDCC),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00EFDF).withValues(alpha: 0.55),
                      blurRadius: 20,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Color(0xFF040E1A),
                  size: 22,
                ),
              ),
            ),

            const SizedBox(width: 6),
          ],
        ),
      ),
    );
  }
}

// ── Data models ───────────────────────────────────────────────────────────────

class _ChatSession {
  final String id;
  final String title;
  final List<_ChatMessage> messages;

  const _ChatSession({
    required this.id,
    required this.title,
    required this.messages,
  });
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final String time;
  final String? imagePath; // local file path when message contains an image

  const _ChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
    this.imagePath,
  });
}
