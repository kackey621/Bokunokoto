import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../app/theme.dart';
import '../../models/greeting.dart';

final greetingProvider = StateNotifierProvider.family<
    GreetingNotifier,
    GreetingState,
    String>((ref, greetingId) {
  return GreetingNotifier();
});

class GreetingState {
  final Greeting? greeting;
  final Duration? timeUntilUnlock;
  final bool isLoading;
  final String? error;

  GreetingState({
    this.greeting,
    this.timeUntilUnlock,
    this.isLoading = false,
    this.error,
  });
}

class GreetingNotifier extends StateNotifier<GreetingState> {
  GreetingNotifier() : super(GreetingState());

  void loadGreeting(Greeting greeting) {
    state = GreetingState(
      greeting: greeting,
      timeUntilUnlock: _remaining(greeting),
    );
  }

  void tick() {
    final greeting = state.greeting;
    if (greeting == null || !greeting.locked) return;
    state = GreetingState(
      greeting: greeting,
      timeUntilUnlock: _remaining(greeting),
    );
  }

  void unlockGreeting() {
    if (state.greeting == null) return;
    state = GreetingState(
      greeting: state.greeting!.copyWith(unlockedAt: DateTime.now()),
    );
  }

  Duration _remaining(Greeting greeting) {
    final diff = greeting.scheduledDeliveryTime.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }
}

class GreetingViewerScreen extends ConsumerStatefulWidget {
  final Greeting greeting;

  const GreetingViewerScreen({
    Key? key,
    required this.greeting,
  }) : super(key: key);

  @override
  ConsumerState<GreetingViewerScreen> createState() =>
      _GreetingViewerScreenState();
}

class _GreetingViewerScreenState extends ConsumerState<GreetingViewerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  Timer? _countdown;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(greetingProvider(widget.greeting.id).notifier)
          .loadGreeting(widget.greeting);
      _startCountdown();
    });
  }

  void _startCountdown() {
    if (!widget.greeting.locked) return;
    _countdown?.cancel();
    _countdown = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        _countdown?.cancel();
        return;
      }
      ref.read(greetingProvider(widget.greeting.id).notifier).tick();

      final remaining = ref.read(greetingProvider(widget.greeting.id)).timeUntilUnlock;
      if (remaining != null && remaining.inSeconds <= 0) {
        _countdown?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _countdown?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final greetingState = ref.watch(greetingProvider(widget.greeting.id));

    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue[50]!,
                Colors.purple[50]!,
              ],
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(Spacing.lg),
              child: greetingState.greeting!.locked
                  ? _buildLockedCard(context, greetingState)
                  : _buildUnlockedCard(context, greetingState),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLockedCard(BuildContext context, GreetingState state) {
    final timeUntil = state.timeUntilUnlock ?? Duration.zero;
    final hours = timeUntil.inHours;
    final minutes = timeUntil.inMinutes.remainder(60);
    final seconds = timeUntil.inSeconds.remainder(60);

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock,
              size: 64,
              color: Colors.purple[400],
            ),
            const SizedBox(height: Spacing.md),
            Text(
              'Special Greeting',
              style: AppTypography.h2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.md),
            Text(
              'This greeting will unlock at the scheduled time',
              style: AppTypography.bodyMedium.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.lg),
            Container(
              padding: const EdgeInsets.all(Spacing.md),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Unlocks in',
                    style: AppTypography.labelMedium.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: Spacing.sm),
                  Text(
                    '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                    style: AppTypography.h1.copyWith(
                      color: Colors.purple[700],
                      fontFamily: 'monospace',
                    ),
                    semanticsLabel:
                        'Unlocks in $hours hours, $minutes minutes, $seconds seconds',
                  ),
                  const SizedBox(height: Spacing.sm),
                  Text(
                    DateFormat('MMM d, yyyy • h:mm a')
                        .format(state.greeting!.scheduledDeliveryTime),
                    style: AppTypography.labelSmall.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Spacing.lg),
            if (timeUntil.inSeconds <= 0)
              ElevatedButton(
                onPressed: () {
                  ref
                      .read(greetingProvider(widget.greeting.id).notifier)
                      .unlockGreeting();
                  _animationController.forward();
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.lg,
                    vertical: Spacing.md,
                  ),
                ),
                child: const Text('Unlock Now'),
              )
            else
              ElevatedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.schedule),
                label: const Text('Waiting...'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnlockedCard(BuildContext context, GreetingState state) {
    return FadeTransition(
      opacity: _animation,
      child: ScaleTransition(
        scale: _animation,
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(Spacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.celebration,
                  size: 64,
                  color: Colors.amber[400],
                ),
                const SizedBox(height: Spacing.md),
                Text(
                  'You have a message!',
                  style: AppTypography.h2,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Spacing.lg),
                Container(
                  padding: const EdgeInsets.all(Spacing.md),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SelectableText(
                    state.greeting!.content,
                    style: AppTypography.bodyLarge,
                  ),
                ),
                const SizedBox(height: Spacing.lg),
                Text(
                  'Unlocked ${DateFormat('MMM d, yyyy • h:mm a').format(state.greeting!.unlockedAt!)}',
                  style: AppTypography.labelSmall.copyWith(
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: Spacing.md),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Back'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
