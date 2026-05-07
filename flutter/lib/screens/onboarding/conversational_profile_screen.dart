import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../providers/api_client_provider.dart';
import '../../providers/auth_provider.dart';

class ConversationalProfileScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? presetContext;

  const ConversationalProfileScreen({
    Key? key,
    this.presetContext,
  }) : super(key: key);

  @override
  ConsumerState<ConversationalProfileScreen> createState() =>
      _ConversationalProfileScreenState();
}

class _ConversationalProfileScreenState extends ConsumerState<ConversationalProfileScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentStep = 0;
  late TextEditingController _realNameController;
  late TextEditingController _relationshipController;
  late TextEditingController _purposeController;
  bool _isSubmitting = false;
  bool _voiceMuted = false;
  late FlutterTts _tts;

  final List<String> _questions = [
    'What\'s your name?',
    'What\'s your relationship to the discloser?',
    'What\'s your purpose for accessing this vault?',
  ];

  final List<String> _hints = [
    'Your full name',
    'e.g., friend, family, colleague, mentor',
    'Why do you need access to this information?',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _realNameController = TextEditingController();
    _relationshipController = TextEditingController();
    _purposeController = TextEditingController();
    _tts = FlutterTts()
      ..setSpeechRate(0.45)
      ..setVolume(0.9)
      ..setPitch(1.0);

    // Pre-fill from preset context if available
    if (widget.presetContext != null) {
      if (widget.presetContext!['real_name'] != null) {
        _realNameController.text = widget.presetContext!['real_name'];
      }
      if (widget.presetContext!['relationship'] != null) {
        _relationshipController.text = widget.presetContext!['relationship'];
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speakCurrentStep();
    });
  }

  @override
  void dispose() {
    _tts.stop();
    _pageController.dispose();
    _realNameController.dispose();
    _relationshipController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  Future<void> _speakCurrentStep() async {
    if (_voiceMuted) return;
    if (_currentStep < 0 || _currentStep >= _questions.length) return;
    final phrase = '${_questions[_currentStep]}. ${_hints[_currentStep]}.';
    await _tts.stop();
    await _tts.speak(phrase);
  }

  Future<void> _toggleVoice() async {
    setState(() => _voiceMuted = !_voiceMuted);
    if (_voiceMuted) {
      await _tts.stop();
    } else {
      await _speakCurrentStep();
    }
  }

  Future<void> _submitProfile() async {
    if (_realNameController.text.isEmpty ||
        _relationshipController.text.isEmpty ||
        _purposeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.patch(
        '/profile',
        data: {
          'profile': {
            'real_name': _realNameController.text,
            'relationship': _relationshipController.text,
            'purpose_of_access': _purposeController.text,
          }
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile completed successfully!')),
        );
        if (mounted) {
          context.push('/home');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save profile: $e')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _nextStep() {
    if (_currentStep < _questions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submitProfile();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _previousStep,
              )
            : null,
        actions: [
          IconButton(
            tooltip: _voiceMuted ? 'Enable audio guidance' : 'Mute audio guidance',
            icon: Icon(_voiceMuted ? Icons.volume_off : Icons.volume_up),
            onPressed: _toggleVoice,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / _questions.length,
              minHeight: 4,
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() => _currentStep = index);
                _speakCurrentStep();
              },
              children: [
                _buildStep(
                  question: _questions[0],
                  hint: _hints[0],
                  controller: _realNameController,
                  icon: Icons.person,
                ),
                _buildStep(
                  question: _questions[1],
                  hint: _hints[1],
                  controller: _relationshipController,
                  icon: Icons.people,
                ),
                _buildStep(
                  question: _questions[2],
                  hint: _hints[2],
                  controller: _purposeController,
                  icon: Icons.help_outline,
                  maxLines: 4,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Spacing.lg),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _nextStep,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Text(_currentStep == _questions.length - 1 ? 'Complete' : 'Next'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep({
    required String question,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    int maxLines = 1,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: const Color(0xFF6366F1)),
          const SizedBox(height: Spacing.lg),
          Text(
            question,
            style: AppTypography.h2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Spacing.xl),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(icon),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            maxLines: maxLines,
            minLines: maxLines,
            enabled: !_isSubmitting,
            autofocus: true,
            onSubmitted: (_) {
              if (_currentStep == _questions.length - 1) {
                _submitProfile();
              } else {
                _nextStep();
              }
            },
          ),
          const SizedBox(height: Spacing.xl),
          Text(
            'Step ${_currentStep + 1} of ${_questions.length}',
            style: AppTypography.bodySmall.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
