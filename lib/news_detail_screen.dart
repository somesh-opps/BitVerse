import 'package:flutter/material.dart';
import 'gradient.dart';

class NewsArticle {
  final String title;
  final String category;
  final String summary;
  final String fullContent;

  const NewsArticle({
    required this.title,
    required this.category,
    required this.summary,
    required this.fullContent,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      title: json['title'] ?? '',
      category: json['category'] ?? 'General',
      summary: json['summary'] ?? '',
      fullContent: json['full_content'] ?? '',
    );
  }
}

class NewsDetailScreen extends StatefulWidget {
  final NewsArticle article;
  const NewsDetailScreen({super.key, required this.article});

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cat = widget.article.category;
    final deco = _categoryDeco(cat);

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
                  // ── Header ────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.maybePop(context),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.08),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.10),
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: (deco['color'] as Color)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: (deco['color'] as Color)
                                  .withValues(alpha: 0.35),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                deco['icon'] as IconData,
                                color: deco['color'] as Color,
                                size: 13,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                cat,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: deco['color'] as Color,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Scrollable content ────────────────────────────────
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(22, 24, 22, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon banner
                          Container(
                            width: double.infinity,
                            height: 160,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              gradient: LinearGradient(
                                colors: [
                                  (deco['color'] as Color)
                                      .withValues(alpha: 0.25),
                                  (deco['color'] as Color)
                                      .withValues(alpha: 0.05),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(
                                color: (deco['color'] as Color)
                                    .withValues(alpha: 0.20),
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                deco['icon'] as IconData,
                                color: (deco['color'] as Color)
                                    .withValues(alpha: 0.80),
                                size: 64,
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Title
                          Text(
                            widget.article.title,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.25,
                              letterSpacing: 0.1,
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Summary card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: (deco['color'] as Color)
                                  .withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: (deco['color'] as Color)
                                    .withValues(alpha: 0.20),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 3,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: deco['color'] as Color,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    widget.article.summary,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withValues(alpha: 0.80),
                                      height: 1.55,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Divider
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 1,
                                  color: Colors.white.withValues(alpha: 0.08),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  'Full Article',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        Colors.white.withValues(alpha: 0.30),
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  height: 1,
                                  color: Colors.white.withValues(alpha: 0.08),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Full content — rendered paragraph by paragraph
                          ..._buildParagraphs(widget.article.fullContent),

                          const SizedBox(height: 16),

                          // AI footer
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.auto_awesome_rounded,
                                  color: Colors.white.withValues(alpha: 0.30),
                                  size: 14,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Generated by CropIntel AI · Powered by Gemini',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color:
                                        Colors.white.withValues(alpha: 0.30),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildParagraphs(String content) {
    final paragraphs = content
        .split('\n')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    return paragraphs.map((para) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Text(
          para,
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFFCFDDE6),
            height: 1.7,
            letterSpacing: 0.1,
          ),
        ),
      );
    }).toList();
  }

  Map<String, dynamic> _categoryDeco(String category) {
    switch (category) {
      case 'Disease Alert':
        return {'icon': Icons.coronavirus_outlined, 'color': const Color(0xFFE57373)};
      case 'Weather':
        return {'icon': Icons.wb_sunny_outlined, 'color': const Color(0xFFFFB74D)};
      case 'Market':
        return {'icon': Icons.show_chart_rounded, 'color': const Color(0xFF81C784)};
      case 'Fertilizer':
        return {'icon': Icons.science_outlined, 'color': const Color(0xFF64B5F6)};
      case 'Seasonal Tips':
        return {'icon': Icons.eco_outlined, 'color': const Color(0xFFAED581)};
      case 'Pest Control':
        return {'icon': Icons.pest_control_outlined, 'color': const Color(0xFFFF8A65)};
      case 'Technology':
        return {'icon': Icons.memory_outlined, 'color': const Color(0xFF9575CD)};
      case 'Soil Health':
        return {'icon': Icons.terrain_outlined, 'color': const Color(0xFFA1887F)};
      default:
        return {'icon': Icons.article_outlined, 'color': const Color(0xFF00BFA5)};
    }
  }
}
