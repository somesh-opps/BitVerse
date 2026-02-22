import 'package:flutter/material.dart';
import 'gradient.dart';
import 'personalization_screen.dart';
import 'api_service.dart';
import 'user_session.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  // Profile edit state
  bool _isEditing = false;
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  final _phoneController    = TextEditingController(text: '');
  final _locationController = TextEditingController(text: '');
  late final String _userId;

  late AnimationController _pageController;
  late Animation<double> _pageFade;
  late Animation<Offset> _pageSlide;

  @override
  void initState() {
    super.initState();

    final session = UserSession.instance;
    _nameController  = TextEditingController(text: session.name);
    _emailController = TextEditingController(text: session.email);
    _userId = session.userId.isNotEmpty ? session.userId : 'N/A';

    _pageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pageFade =
        CurvedAnimation(parent: _pageController, curve: Curves.easeIn);
    _pageSlide =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
      CurvedAnimation(parent: _pageController, curve: Curves.easeOut),
    );

    _pageController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: AuroraGradient(
        child: SafeArea(
          child: _buildProfilePage(),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  //  Profile page
  // ════════════════════════════════════════════════════════

  Widget _buildProfilePage() {
    return FadeTransition(
      opacity: _pageFade,
      child: SlideTransition(
        position: _pageSlide,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Hero banner ─────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF0D1B3E),
                      Color(0xFF1A1550),
                      Color(0xFF0E2040),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: const Color(0xFF00EFDF).withValues(alpha: 0.22),
                      width: 1,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B5BA5).withValues(alpha: 0.22),
                      blurRadius: 32,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Decorative ambient glow orbs
                    Positioned(
                      top: -50,
                      right: -40,
                      child: Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFF3B5BA5).withValues(alpha: 0.28),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -50,
                      left: -40,
                      child: Container(
                        width: 190,
                        height: 190,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFF00EFDF).withValues(alpha: 0.10),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        // Top bar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.maybePop(context),
                          child: Container(
                            width: 38, height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.07),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.10),
                                width: 1,
                              ),
                            ),
                            child: const Icon(Icons.arrow_back_ios_new_rounded,
                                color: Colors.white, size: 16),
                          ),
                        ),
                        const Text(
                          'My Profile',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            if (_isEditing) {
                              // Save: call backend
                              final session = UserSession.instance;
                              final result = await ApiService.updateProfile(
                                email: session.email.isNotEmpty ? session.email : null,
                                userId: session.userId.isNotEmpty ? session.userId : null,
                                name: _nameController.text.trim(),
                              );
                              if (!mounted) return;
                              if (result['status'] == 'success') {
                                session.name = _nameController.text.trim();
                              }
                            }
                            setState(() => _isEditing = !_isEditing);
                            if (!_isEditing) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: const Color(0xFF141E35),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                  content: const Row(
                                    children: [
                                      Icon(Icons.check_circle_rounded,
                                          color: Color(0xFF00EFDF), size: 18),
                                      SizedBox(width: 10),
                                      Text('Profile saved!',
                                          style: TextStyle(
                                              color: Colors.white, fontSize: 13)),
                                    ],
                                  ),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: _isEditing
                                  ? const LinearGradient(
                                      colors: [Color(0xFF00C896), Color(0xFF00EFDF)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : null,
                              color: _isEditing
                                  ? null
                                  : Colors.white.withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(20),
                              border: _isEditing
                                  ? null
                                  : Border.all(
                                      color: Colors.white.withValues(alpha: 0.12),
                                      width: 1,
                                    ),
                              boxShadow: _isEditing
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF00EFDF)
                                            .withValues(alpha: 0.35),
                                        blurRadius: 12,
                                      )
                                    ]
                                  : [],
                            ),
                            child: Text(
                              _isEditing ? 'Save' : 'Edit',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _isEditing
                                    ? const Color(0xFF041810)
                                    : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // Avatar
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 104,
                          height: 104,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF3B5BA5), Color(0xFF5270C0)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF3B5BA5)
                                    .withValues(alpha: 0.50),
                                blurRadius: 24,
                                spreadRadius: 2,
                              ),
                            ],
                            border: Border.all(
                              color: const Color(0xFF00EFDF).withValues(alpha: 0.30),
                              width: 2.5,
                            ),
                          ),
                          child: const Icon(Icons.person_rounded,
                              color: Colors.white, size: 52),
                        ),
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: GestureDetector(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: const Color(0xFF141E35),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                  content: const Row(
                                    children: [
                                      Icon(Icons.photo_camera_rounded,
                                          color: Color(0xFF00EFDF), size: 18),
                                      SizedBox(width: 10),
                                      Text('Photo upload coming soon',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 13)),
                                    ],
                                  ),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            child: Container(
                              width: 32, height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF00C896), Color(0xFF00EFDF)],
                                ),
                                border: Border.all(
                                    color: const Color(0xFF0A1628), width: 2.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00EFDF)
                                        .withValues(alpha: 0.45),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.camera_alt_rounded,
                                  color: Color(0xFF041810), size: 15),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    Text(
                      _nameController.text,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.3,
                        shadows: [
                          Shadow(
                            color: Color(0xFF00EFDF),
                            blurRadius: 18,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    // User ID badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF00EFDF).withValues(alpha: 0.15),
                            const Color(0xFF00C896).withValues(alpha: 0.08),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF00EFDF).withValues(alpha: 0.38),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00EFDF).withValues(alpha: 0.15),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Text(
                        'ID: $_userId',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF00EFDF),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Stats row
                    Row(
                      children: [
                        _buildStatCard('12', 'Crops\nTracked', const Color(0xFF81C784)),
                        _buildStatCard('48', 'Days\nActive',  const Color(0xFF64B5F6)),
                        _buildStatCard('6',  'Alerts\nToday',  const Color(0xFFFFB74D)),
                      ],
                    ),
                  ],
                ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── User Details ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('Account Details'),
                    const SizedBox(height: 14),

                    _buildInfoField(
                      icon: Icons.badge_outlined,
                      iconColor: const Color(0xFF00EFDF),
                      iconBg: const Color(0xFF0D2030),
                      label: 'User ID',
                      value: _userId,
                      readOnly: true,
                    ),
                    const SizedBox(height: 10),
                    _buildEditableField(
                      icon: Icons.person_outline_rounded,
                      iconColor: const Color(0xFF64B5F6),
                      iconBg: const Color(0xFF1A2840),
                      label: 'Full Name',
                      controller: _nameController,
                    ),
                    const SizedBox(height: 10),
                    _buildEditableField(
                      icon: Icons.email_outlined,
                      iconColor: const Color(0xFFCE93D8),
                      iconBg: const Color(0xFF2A1A40),
                      label: 'Email Address',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 10),
                    _buildEditableField(
                      icon: Icons.phone_outlined,
                      iconColor: const Color(0xFF81C784),
                      iconBg: const Color(0xFF1A3020),
                      label: 'Phone Number',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 10),
                    _buildEditableField(
                      icon: Icons.location_on_outlined,
                      iconColor: const Color(0xFFFFB74D),
                      iconBg: const Color(0xFF3A2A10),
                      label: 'Location',
                      controller: _locationController,
                    ),

                    const SizedBox(height: 28),

                    // ── Edit Preferences ──────────────────────────
                    _sectionTitle('Preferences'),
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) =>
                              const PersonalizationScreen(fromProfile: true),
                          transitionsBuilder: (_, anim, __, child) =>
                              FadeTransition(opacity: anim, child: child),
                          transitionDuration:
                              const Duration(milliseconds: 400),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF00EFDF).withValues(alpha: 0.08),
                              const Color(0xFF00C896).withValues(alpha: 0.04),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color:
                                const Color(0xFF00EFDF).withValues(alpha: 0.22),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00EFDF)
                                  .withValues(alpha: 0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF00C896),
                                    Color(0xFF00EFDF),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00EFDF)
                                        .withValues(alpha: 0.35),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.tune_rounded,
                                color: Color(0xFF041810),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Edit Preferences',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    'Gender · Age · Category',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF00EFDF),
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: const Color(0xFF00EFDF)
                                  .withValues(alpha: 0.60),
                              size: 15,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Sign out
                    Center(
                      child: GestureDetector(
                        onTap: () {
                            UserSession.instance.clear();
                            Navigator.pushAndRemoveUntil(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (_, __, ___) =>
                                    const LoginScreen(),
                                transitionsBuilder:
                                    (_, animation, __, child) =>
                                        FadeTransition(
                                            opacity: animation, child: child),
                                transitionDuration:
                                    const Duration(milliseconds: 400),
                              ),
                              (route) => false,
                            );
                          },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFE57373).withValues(alpha: 0.12),
                                const Color(0xFFFF5252).withValues(alpha: 0.06),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: const Color(0xFFE57373).withValues(alpha: 0.38),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFE57373).withValues(alpha: 0.10),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.logout_rounded,
                                  color: Color(0xFFEF9A9A), size: 17),
                              SizedBox(width: 8),
                              Text(
                                'Sign Out',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFEF9A9A),
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.15),
              color.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: color.withValues(alpha: 0.32),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.16),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.18),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.22),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: color.withValues(alpha: 0.78),
                height: 1.3,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoField({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required String value,
    bool readOnly = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF141E35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.38),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          if (readOnly)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF00EFDF).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'READ ONLY',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF00EFDF),
                  letterSpacing: 0.5,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEditableField({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF141E35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isEditing
              ? const Color(0xFF00EFDF).withValues(alpha: 0.30)
              : Colors.white.withValues(alpha: 0.06),
          width: 1,
        ),
        boxShadow: _isEditing
            ? [
                BoxShadow(
                  color: const Color(0xFF00EFDF).withValues(alpha: 0.06),
                  blurRadius: 12,
                )
              ]
            : [],
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.38),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                TextField(
                  controller: controller,
                  enabled: _isEditing,
                  keyboardType: keyboardType,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
          if (_isEditing)
            Icon(Icons.edit_rounded,
                size: 15,
                color: const Color(0xFF00EFDF).withValues(alpha: 0.55)),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00C896), Color(0xFF00EFDF)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00EFDF).withValues(alpha: 0.60),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

}
