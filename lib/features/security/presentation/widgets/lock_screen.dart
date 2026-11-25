import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_spacing.dart';
import '../cubit/security_cubit.dart';
import '../cubit/security_state.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  String _enteredPin = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<SecurityCubit>().state;
      if (state.isBiometricsEnabled && state.isBiometricsAvailable) {
        context.read<SecurityCubit>().unlockWithBiometrics();
      }
    });
  }

  void _onDigitPressed(String digit) {
    if (_enteredPin.length >= 6) return;
    setState(() {
      _enteredPin += digit;
    });

    if (_enteredPin.length >= 4) {
      final pin = _enteredPin;
      context.read<SecurityCubit>().unlockWithPin(pin).then((success) {
        if (!success && mounted) {
          setState(() {
            _enteredPin = '';
          });
        }
      });
    }
  }

  void _onBackspacePressed() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<SecurityCubit, SecurityState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          setState(() {
            _enteredPin = '';
          });
        }
      },
      builder: (context, state) {
        final showBiometrics = state.isBiometricsEnabled && state.isBiometricsAvailable;

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: SafeArea(
            child: Column(
              children: [
                const Spacer(),

                // Security Shield / Lock Icon & Header
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withAlpha(70),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.primary.withAlpha(40),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Icons.lock_outline,
                    size: 44,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Budget Tracker Locked',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Enter PIN to continue',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                // PIN Dots Indicator (4 dots)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    final isFilled = _enteredPin.length > index;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      width: isFilled ? 18 : 16,
                      height: isFilled ? 18 : 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isFilled
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surfaceContainerHighest.withAlpha(120),
                        border: Border.all(
                          color: isFilled
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outlineVariant,
                          width: 1.5,
                        ),
                        boxShadow: isFilled
                            ? [
                                BoxShadow(
                                  color: theme.colorScheme.primary.withAlpha(50),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                    );
                  }),
                ),

                // Error Message Display
                if (state.errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      state.errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],

                const Spacer(),

                // Numeric Keypad (1-9, Bio, 0, Backspace)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 36),
                  child: Column(
                    children: [
                      _buildKeypadRow(['1', '2', '3']),
                      const SizedBox(height: AppSpacing.md),
                      _buildKeypadRow(['4', '5', '6']),
                      const SizedBox(height: AppSpacing.md),
                      _buildKeypadRow(['7', '8', '9']),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Biometric Button or Placeholder
                          SizedBox(
                            width: 68,
                            height: 68,
                            child: showBiometrics
                                ? Material(
                                    color: Colors.transparent,
                                    shape: const CircleBorder(),
                                    clipBehavior: Clip.antiAlias,
                                    child: InkWell(
                                      onTap: () => context
                                          .read<SecurityCubit>()
                                          .unlockWithBiometrics(),
                                      child: Container(
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: theme.colorScheme.primaryContainer.withAlpha(60),
                                          border: Border.all(
                                            color: theme.colorScheme.outlineVariant.withAlpha(80),
                                            width: 1,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.fingerprint,
                                          size: 34,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                          _buildKeypadButton('0'),
                          SizedBox(
                            width: 68,
                            height: 68,
                            child: Material(
                              color: Colors.transparent,
                              shape: const CircleBorder(),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: _onBackspacePressed,
                                child: Container(
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
                                    border: Border.all(
                                      color: theme.colorScheme.outlineVariant.withAlpha(60),
                                      width: 1,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.backspace_outlined,
                                    size: 26,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildKeypadRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map(_buildKeypadButton).toList(),
    );
  }

  Widget _buildKeypadButton(String digit) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 68,
      height: 68,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _onDigitPressed(digit),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.surfaceContainerHighest.withAlpha(90),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withAlpha(60),
                width: 1,
              ),
            ),
            child: Text(
              digit,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
