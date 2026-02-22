import 'package:flutter/material.dart';
import 'gradient.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';
import 'api_service.dart';
import 'user_session.dart';
import 'news_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;

  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  List<NewsArticle> _articles = [];
  bool _isLoadingNews = true;
  String? _newsError;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
    _fetchNews();
  }

  Future<void> _fetchNews() async {
    setState(() {
      _isLoadingNews = true;
      _newsError = null;
    });

    try {
      final result = await ApiService.getNewsFeed(
        region: 'General',
        plantsOfInterest: ['Wheat', 'Rice', 'Corn'],
      );

      if (mounted) {
        setState(() {
          if (result['success'] == true) {
            final rawList = result['articles'] as List<dynamic>;
            _articles = rawList
                .map((e) => NewsArticle.fromJson(e as Map<String, dynamic>))
                .toList();
          } else {
            _newsError = result['message'] ?? 'Failed to load news';
          }
          _isLoadingNews = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _newsError = 'Could not connect to the news server.\nMake sure it is running on port 8001.';
          _isLoadingNews = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ── Category decoration helper ─────────────────────────────────────────

  Map<String, dynamic> _categoryDeco(String category) {
    switch (category) {
      case 'Disease Alert':
        return {
          'icon': Icons.coronavirus_outlined,
          'color': const Color(0xFFE57373),
          'bg': const Color(0xFF3A1A1A),
        };
      case 'Weather':
        return {
          'icon': Icons.wb_sunny_outlined,
          'color': const Color(0xFFFFB74D),
          'bg': const Color(0xFF3A2A10),
        };
      case 'Market':
        return {
          'icon': Icons.show_chart_rounded,
          'color': const Color(0xFF81C784),
          'bg': const Color(0xFF1A3020),
        };
      case 'Fertilizer':
        return {
          'icon': Icons.science_outlined,
          'color': const Color(0xFF64B5F6),
          'bg': const Color(0xFF1A2840),
        };
      case 'Seasonal Tips':
        return {
          'icon': Icons.eco_outlined,
          'color': const Color(0xFFAED581),
          'bg': const Color(0xFF1E2A10),
        };
      case 'Pest Control':
        return {
          'icon': Icons.pest_control_outlined,
          'color': const Color(0xFFFF8A65),
          'bg': const Color(0xFF3A2010),
        };
      case 'Technology':
        return {
          'icon': Icons.memory_outlined,
          'color': const Color(0xFF9575CD),
          'bg': const Color(0xFF221835),
        };
      case 'Soil Health':
        return {
          'icon': Icons.terrain_outlined,
          'color': const Color(0xFFA1887F),
          'bg': const Color(0xFF2A1E18),
        };
      default:
        return {
          'icon': Icons.article_outlined,
          'color': const Color(0xFF00BFA5),
          'bg': const Color(0xFF0D2520),
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: AuroraGradient(
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeIn,
            child: SlideTransition(
              position: _slideUp,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 18),

                          // ── Top bar ──────────────────────────────────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () {},
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _menuLine(22),
                                    const SizedBox(height: 5),
                                    _menuLine(16),
                                    const SizedBox(height: 5),
                                    _menuLine(19),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder: (_, __, ___) =>
                                        const ProfileScreen(),
                                    transitionsBuilder:
                                        (_, anim, __, child) =>
                                            FadeTransition(
                                                opacity: anim, child: child),
                                    transitionDuration:
                                        const Duration(milliseconds: 400),
                                  ),
                                ),
                                child: Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF3B5BA5),
                                        Color(0xFF5270C0),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF3B5BA5)
                                            .withValues(alpha: 0.45),
                                        blurRadius: 14,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.person_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 28),

                          // ── Greeting ──────────────────────────────────
                          Text(
                            'Hello, ${UserSession.instance.name.isNotEmpty ? UserSession.instance.name.split(' ')[0] : 'User'}',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.2,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'How can I assist you right now?',
                            style: TextStyle(
                              fontSize: 15,
                              color: Color(0xFF8DAAB8),
                              height: 1.4,
                            ),
                          ),

                          const SizedBox(height: 30),

                          // ── Feature cards grid ────────────────────────
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left big card: Talk with CropIntel
                              Expanded(
                                flex: 45,
                                child: GestureDetector(
                                  onTap: () {},
                                  child: Container(
                                    height: 310,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(26),
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF4FC3F7),
                                          Color(0xFF2979FF),
                                          Color(0xFF9C27B0),
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF2979FF)
                                              .withValues(alpha: 0.40),
                                          blurRadius: 24,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: 80,
                                            height: 80,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.white
                                                  .withValues(alpha: 0.22),
                                            ),
                                            child: const Icon(
                                              Icons.mic_rounded,
                                              color: Colors.white,
                                              size: 38,
                                            ),
                                          ),
                                          const Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              'Talk with\nCropIntel',
                                              textAlign: TextAlign.left,
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                                height: 1.35,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 8),

                              // Right column: two small cards
                              Expanded(
                                flex: 55,
                                child: Column(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          PageRouteBuilder(
                                            pageBuilder: (_, __, ___) =>
                                                const ChatScreen(),
                                            transitionsBuilder:
                                                (_, anim, __, child) =>
                                                    FadeTransition(
                                                        opacity: anim,
                                                        child: child),
                                            transitionDuration:
                                                const Duration(milliseconds: 400),
                                          ),
                                        );
                                      },
                                      child: _buildSmallCard(
                                        iconWidget: Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: const Color(0xFF2A3B28),
                                            border: Border.all(
                                              color: const Color(0xFF4CAF50)
                                                  .withValues(alpha: 0.5),
                                              width: 1.5,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.send_rounded,
                                            color: Color(0xFFBEE64B),
                                            size: 22,
                                          ),
                                        ),
                                        label: 'Chat with\nCropIntel',
                                      ),
                                    ),

                                    const SizedBox(height: 8),

                                    GestureDetector(
                                      onTap: () {},
                                      child: _buildSmallCard(
                                        iconWidget: Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: const Color(0xFF2A2040),
                                            border: Border.all(
                                              color: const Color(0xFF9C27B0)
                                                  .withValues(alpha: 0.5),
                                              width: 1.5,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.document_scanner_outlined,
                                            color: Color(0xFFCE93D8),
                                            size: 22,
                                          ),
                                        ),
                                        label: 'Search By\nImage',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 34),

                          // ── Farm News header ───────────────────────────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'Farm News',
                                    style: TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  if (_isLoadingNews) ...[
                                    const SizedBox(width: 10),
                                    const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF00BFA5),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              GestureDetector(
                                onTap: _isLoadingNews ? null : _fetchNews,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00BFA5)
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(0xFF00BFA5)
                                          .withValues(alpha: 0.25),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.refresh_rounded,
                                        color: _isLoadingNews
                                            ? Colors.white30
                                            : const Color(0xFF00BFA5),
                                        size: 13,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Refresh',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: _isLoadingNews
                                              ? Colors.white30
                                              : const Color(0xFF00BFA5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // ── News feed ─────────────────────────────────
                          if (_isLoadingNews)
                            _buildNewsSkeletons()
                          else if (_newsError != null)
                            _buildErrorWidget()
                          else if (_articles.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 30),
                              child: Center(
                                child: Text(
                                  'No news available at the moment.',
                                  style: TextStyle(color: Colors.white54),
                                ),
                              ),
                            )
                          else
                            Column(
                              children: _articles.asMap().entries.map((entry) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: _buildNewsCard(entry.value),
                                );
                              }).toList(),
                            ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),

                  // ── Bottom nav bar ────────────────────────────────────
                  _buildBottomNav(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── News skeleton loading ────────────────────────────────────────────────

  Widget _buildNewsSkeletons() {
    return Column(
      children: List.generate(3, (i) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Container(
            height: 96,
            decoration: BoxDecoration(
              color: const Color(0xFF141E35),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 20, 16, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          height: 10,
                          width: 70,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        Container(
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        Container(
                          height: 10,
                          width: 140,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ── News card ────────────────────────────────────────────────────────────

  Widget _buildNewsCard(NewsArticle article) {
    final deco = _categoryDeco(article.category);
    final Color color = deco['color'] as Color;
    final Color bg = deco['bg'] as Color;
    final IconData icon = deco['icon'] as IconData;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) =>
              NewsDetailScreen(article: article),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(
            opacity: anim,
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 350),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
          color: const Color(0xFF141E35),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.06),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon block
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: color.withValues(alpha: 0.20),
                  width: 1,
                ),
              ),
              child: Icon(icon, color: color, size: 24),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category tag + arrow
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.13),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          article.category,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: color,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 11,
                        color: Colors.white.withValues(alpha: 0.20),
                      ),
                    ],
                  ),

                  const SizedBox(height: 7),

                  // Title
                  Text(
                    article.title,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 5),

                  // Summary preview
                  Text(
                    article.summary,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.50),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  // Read more hint
                  Row(
                    children: [
                      Text(
                        'Tap to read full article',
                        style: TextStyle(
                          fontSize: 11,
                          color: color.withValues(alpha: 0.70),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Error widget ─────────────────────────────────────────────────────────

  Widget _buildErrorWidget() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF3A1A1A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.20),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded,
              color: Colors.redAccent, size: 36),
          const SizedBox(height: 12),
          Text(
            _newsError!,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: _fetchNews,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF00BFA5).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF00BFA5).withValues(alpha: 0.35),
                  width: 1,
                ),
              ),
              child: const Text(
                'Try Again',
                style: TextStyle(
                  color: Color(0xFF00BFA5),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared helpers ───────────────────────────────────────────────────────

  Widget _menuLine(double width) {
    return Container(
      width: width,
      height: 2.5,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildSmallCard({
    required Widget iconWidget,
    required String label,
  }) {
    return Container(
      height: 148,
      decoration: BoxDecoration(
        color: const Color(0xFF141E35),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: iconWidget,
          ),
          const Spacer(),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.home_rounded, 'label': 'Home'},
      {'icon': Icons.chat_bubble_outline_rounded, 'label': 'Chat'},
      {'icon': Icons.person_outline_rounded, 'label': 'Profile'},
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          color: const Color(0xFF111A2E),
          borderRadius: BorderRadius.circular(36),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.07),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (index) {
            final isActive = index == _currentIndex;
            final icon = items[index]['icon'] as IconData;
            return GestureDetector(
              onTap: () {
                if (index == 1) {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => const ChatScreen(),
                      transitionsBuilder: (_, anim, __, child) =>
                          FadeTransition(opacity: anim, child: child),
                      transitionDuration: const Duration(milliseconds: 400),
                    ),
                  );
                } else if (index == 2) {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => const ProfileScreen(),
                      transitionsBuilder: (_, anim, __, child) =>
                          FadeTransition(opacity: anim, child: child),
                      transitionDuration: const Duration(milliseconds: 400),
                    ),
                  );
                } else {
                  setState(() => _currentIndex = index);
                }
              },
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: 56,
                height: 68,
                child: Center(
                  child: Icon(
                    icon,
                    size: 26,
                    color: isActive
                        ? const Color(0xFF00EFDF)
                        : const Color(0xFF4A6375),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
