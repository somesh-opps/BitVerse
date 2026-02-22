import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'gradient.dart';
import 'home_screen.dart';
import 'api_service.dart';
import 'user_session.dart';

class PersonalizationScreen extends StatefulWidget {
  final bool fromProfile;
  const PersonalizationScreen({super.key, this.fromProfile = false});

  @override
  State<PersonalizationScreen> createState() => _PersonalizationScreenState();
}

class _PersonalizationScreenState extends State<PersonalizationScreen>
    with TickerProviderStateMixin {
  // ── State ─────────────────────────────────────────────────────────────────
  int _step = 0; // 0=basic, 1=crop, 2=region, 3=soil

  final _ageController = TextEditingController();
  String? _gender;
  String? _cropType;
  final _regionController = TextEditingController();
  String? _soilType;

  bool _isLoading = false;
  String? _errorMessage;

  // ── Options ───────────────────────────────────────────────────────────────
  static const _genders = ['Male', 'Female', 'Other'];
  static const _cropTypes = [
    ('🌾', 'Rice / Paddy', 'Kharif staple crop'),
    ('🌿', 'Wheat', 'Rabi staple crop'),
    ('🌽', 'Maize', 'Versatile cereal crop'),
    ('🏭', 'Sugarcane', 'Commercial cash crop'),
    ('☁️', 'Cotton', 'Fibre crop'),
    ('🫘', 'Pulses', 'Dal / legumes'),
    ('🥜', 'Oilseeds', 'Groundnut / soybean / mustard'),
    ('🥦', 'Vegetables', 'Seasonal vegetables'),
    ('🍎', 'Fruits', 'Mango / banana / citrus'),
    ('🌱', 'Other', 'Mixed or other crops'),
  ];
  static const _soilTypes = [
    ('🟤', 'Alluvial Soil', 'Found in river plains — very fertile'),
    ('⚫', 'Black Soil', 'Regur — ideal for cotton'),
    ('🔴', 'Red Soil', 'Iron-rich, suits millets & pulses'),
    ('🟠', 'Laterite Soil', 'Leached soil, suits tea & coffee'),
    ('🟡', 'Sandy / Desert', 'Dry soil found in arid regions'),
    ('🗻', 'Mountain Soil', 'Forest soil, suits spices & fruits'),
  ];
  // ── Animations ────────────────────────────────────────────────────────────
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late AnimationController _progressController;
  late Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 420));
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _progressController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _progressAnim = Tween<double>(begin: 0.0, end: 1 / 4).animate(
        CurvedAnimation(parent: _progressController, curve: Curves.easeInOut));
    _fadeController.forward();
    _progressController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _progressController.dispose();
    _ageController.dispose();
    _regionController.dispose();
    super.dispose();
  }

  // ── Navigation ────────────────────────────────────────────────────────────
  void _animateToStep(int newStep) {
    _fadeController.reset();
    setState(() {
      _step = newStep;
      _errorMessage = null;
    });
    _fadeController.forward();
    final target = (newStep + 1) / 4;
    _progressAnim =
        Tween<double>(begin: _progressAnim.value, end: target).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );
    _progressController
      ..reset()
      ..forward();
  }

  bool _canProceedStep0() =>
      _ageController.text.trim().isNotEmpty &&
      int.tryParse(_ageController.text.trim()) != null &&
      int.parse(_ageController.text.trim()) > 0 &&
      int.parse(_ageController.text.trim()) <= 120 &&
      _gender != null;

  bool _canProceedStep1() => _cropType != null;
  bool _canProceedStep2() => _regionController.text.trim().isNotEmpty;
  bool _canProceedStep3() => _soilType != null;

  void _onNext() {
    if (_step == 0) {
      if (!_canProceedStep0()) {
        setState(() =>
            _errorMessage = 'Please enter a valid age and select a gender.');
        return;
      }
      _animateToStep(1);
    } else if (_step == 1) {
      if (!_canProceedStep1()) {
        setState(() => _errorMessage = 'Please select your primary crop.');
        return;
      }
      _animateToStep(2);
    } else if (_step == 2) {
      if (!_canProceedStep2()) {
        setState(() => _errorMessage = 'Please enter your region or state.');
        return;
      }
      _animateToStep(3);
    } else {
      if (!_canProceedStep3()) {
        setState(() => _errorMessage = 'Please select your soil type.');
        return;
      }
      _submit();
    }
  }

  Future<void> _submit() async {
    final ageText = _ageController.text.trim();
    final age = int.tryParse(ageText);
    if (age == null || age <= 0 || age > 120) {
      setState(() => _errorMessage = 'Invalid age.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final session = UserSession.instance;
    final result = await ApiService.savePersonalization(
      email: session.email.isNotEmpty ? session.email : null,
      userId: session.userId.isNotEmpty ? session.userId : null,
      gender: _gender!,
      age: age,
      cropType: _cropType,
      region: _regionController.text.trim().isNotEmpty
          ? _regionController.text.trim()
          : null,
      soilType: _soilType,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['status'] == 'success' || widget.fromProfile) {
      // even if server errors, proceed; personalization is optional
      _navigateAway();
    } else {
      // Show error but still allow skip
      setState(
          () => _errorMessage = result['message'] ?? 'Failed to save. You can skip.');
    }
  }

  void _navigateAway() {
    if (widget.fromProfile) {
      Navigator.maybePop(context);
    } else {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: AuroraGradient(
        child: SafeArea(
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Column(
              children: [
                _buildTopBar(),
                _buildProgressBar(),
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_errorMessage != null)
                              Container(
                                margin: const EdgeInsets.only(bottom: 14),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3A1010),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: const Color(0xFFEF9A9A)
                                          .withValues(alpha: 0.5)),
                                ),
                                child: Text(_errorMessage!,
                                    style: const TextStyle(
                                        color: Color(0xFFEF9A9A),
                                        fontSize: 13)),
                              ),
                            _buildCurrentStep(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                _buildBottomBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Top bar ───────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          if (_step > 0)
            GestureDetector(
              onTap: () => _animateToStep(_step - 1),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF141E35),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 18),
              ),
            )
          else
            const SizedBox(width: 36),
          const Spacer(),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B3340), Color(0xFF112330)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: const Color(0xFF00C896).withValues(alpha: 0.3)),
            ),
            child: Text(
              'Step ${_step + 1} of 4',
              style: const TextStyle(
                  color: Color(0xFF00C896),
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _navigateAway,
            child: const Text('Skip',
                style: TextStyle(
                    color: Color(0xFF6B8FA0),
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  // ── Progress bar ──────────────────────────────────────────────────────────
  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 10),
      child: Row(
        children: List.generate(4, (i) {
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF1C2E40),
                borderRadius: BorderRadius.circular(4),
              ),
              child: i <= _step
                  ? Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00C896), Color(0xFF00EFDF)],
                        ),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00EFDF)
                                .withValues(alpha: 0.4),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    )
                  : null,
            ),
          );
        }),
      ),
    );
  }

  // ── Step switcher ─────────────────────────────────────────────────────────
  Widget _buildCurrentStep() {
    switch (_step) {
      case 0: return _buildStep0();
      case 1: return _buildStep1();
      case 2: return _buildStep2();
      default: return _buildStep3();
    }
  }

  // ── Step 0: Age + Gender ──────────────────────────────────────────────────
  Widget _buildStep0() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Basic Information',
            style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        const SizedBox(height: 6),
        const Text('Help us personalise your experience',
            style: TextStyle(fontSize: 14, color: Color(0xFF6B8FA0))),
        const SizedBox(height: 28),

        // Age
        _sectionLabel('Your Age'),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF141E35),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: const Color(0xFF00C896).withValues(alpha: 0.2)),
          ),
          child: TextField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => setState(() {}),
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: const InputDecoration(
              hintText: 'Enter your age',
              hintStyle: TextStyle(color: Color(0xFF6B8A99)),
              prefixIcon:
                  Icon(Icons.cake_outlined, color: Color(0xFF00C896), size: 20),
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Gender
        _sectionLabel('Gender'),
        const SizedBox(height: 10),
        Row(
          children: _genders.map((g) {
            final selected = _gender == g;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _gender = g),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: selected
                        ? const LinearGradient(
                            colors: [Color(0xFF00C896), Color(0xFF00EFDF)])
                        : null,
                    color: selected ? null : const Color(0xFF141E35),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected
                          ? Colors.transparent
                          : const Color(0xFF1C2E40),
                    ),
                  ),
                  child: Text(
                    g,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selected ? const Color(0xFF071218) : Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  // ── Step 1: Crop Type ─────────────────────────────────────────────────────
  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Primary Crop',
            style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        const SizedBox(height: 6),
        const Text('What do you mainly grow on your farm?',
            style: TextStyle(fontSize: 14, color: Color(0xFF6B8FA0))),
        const SizedBox(height: 28),
        ..._cropTypes.map((item) {
          final (emoji, name, desc) = item;
          final selected = _cropType == name;
          return GestureDetector(
            onTap: () => setState(() => _cropType = name),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF0D2B1E) : const Color(0xFF141E35),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? const Color(0xFF00C896) : const Color(0xFF1C2E40),
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Row(children: [
                Text(emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: TextStyle(
                              color: selected ? const Color(0xFF00EFDF) : Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 15)),
                      Text(desc,
                          style: const TextStyle(color: Color(0xFF6B8FA0), fontSize: 12)),
                    ],
                  ),
                ),
                if (selected)
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF00C896), size: 20),
              ]),
            ),
          );
        }),
        const SizedBox(height: 40),
      ],
    );
  }

  // ── Step 2: Region ────────────────────────────────────────────────────────
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Your Region',
            style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        const SizedBox(height: 6),
        const Text('Which state or region do you farm in?',
            style: TextStyle(fontSize: 14, color: Color(0xFF6B8FA0))),
        const SizedBox(height: 40),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF141E35),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: const Color(0xFF00C896).withValues(alpha: 0.2)),
          ),
          child: TextField(
            controller: _regionController,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: const InputDecoration(
              hintText: 'e.g. Punjab, Maharashtra, UP',
              hintStyle: TextStyle(color: Color(0xFF6B8A99)),
              prefixIcon: Icon(Icons.location_on_outlined,
                  color: Color(0xFF00C896), size: 20),
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  // ── Step 3: Soil Type ─────────────────────────────────────────────────────
  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Soil Type',
            style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        const SizedBox(height: 6),
        const Text('What type of soil is on your farm?',
            style: TextStyle(fontSize: 14, color: Color(0xFF6B8FA0))),
        const SizedBox(height: 28),
        ..._soilTypes.map((item) {
          final (emoji, name, desc) = item;
          final selected = _soilType == name;
          return GestureDetector(
            onTap: () => setState(() => _soilType = name),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF0D2B1E) : const Color(0xFF141E35),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? const Color(0xFF00C896) : const Color(0xFF1C2E40),
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Row(children: [
                Text(emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: TextStyle(
                              color: selected ? const Color(0xFF00EFDF) : Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 15)),
                      Text(desc,
                          style: const TextStyle(color: Color(0xFF6B8FA0), fontSize: 12)),
                    ],
                  ),
                ),
                if (selected)
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF00C896), size: 20),
              ]),
            ),
          );
        }),
        const SizedBox(height: 40),
      ],
    );
  }

  // ── Bottom bar ────────────────────────────────────────────────────────────
  Widget _buildBottomBar() {
    final canProceed = switch (_step) {
      0 => _canProceedStep0(),
      1 => _canProceedStep1(),
      2 => _canProceedStep2(),
      _ => _canProceedStep3(),
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: BoxDecoration(
        color: const Color(0xFF000000),
        border: Border(
          top: BorderSide(
            color: const Color(0xFF00EFDF).withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 54,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: canProceed
                    ? const LinearGradient(
                        colors: [Color(0xFF00C896), Color(0xFF00EFDF)])
                    : null,
                color: canProceed ? null : const Color(0xFF141E35),
                borderRadius: BorderRadius.circular(30),
                boxShadow: canProceed
                    ? [
                        BoxShadow(
                          color:
                              const Color(0xFF00EFDF).withValues(alpha: 0.3),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        )
                      ]
                    : null,
              ),
              child: ElevatedButton(
                onPressed: canProceed && !_isLoading ? _onNext : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Color(0xFF071218)))
                    : Text(
                        _step < 3 ? 'Continue' : 'Save & Finish',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: canProceed
                              ? const Color(0xFF071218)
                              : const Color(0xFF4A6070),
                          letterSpacing: 0.4,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _navigateAway,
            child: const Text(
              'Skip personalization',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF6B8FA0),
                decoration: TextDecoration.underline,
                decorationColor: Color(0xFF6B8FA0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF6BAABB),
          letterSpacing: 0.4,
        ),
      );
}
