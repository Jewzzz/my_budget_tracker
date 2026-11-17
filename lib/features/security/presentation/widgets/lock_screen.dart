import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

                // Lock Icon & Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withAlpha(80),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_outline,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Budget Tracker Locked',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter PIN to continue',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),

                // PIN Dots Indicator (4 dots)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    final isFilled = _enteredPin.length > index;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isFilled
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant.withAlpha(120),
                        border: Border.all(
                          color: isFilled
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline,
                          width: 1.5,
                        ),
                      ),
                    );
                  }),
                ),

                // Error Message Display
                if (state.errorMessage != null) ...[
                  const SizedBox(height: 16),
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
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    children: [
                      _buildKeypadRow(['1', '2', '3']),
                      const SizedBox(height: 16),
                      _buildKeypadRow(['4', '5', '6']),
                      const SizedBox(height: 16),
                      _buildKeypadRow(['7', '8', '9']),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Biometric Button or Placeholder
                          SizedBox(
                            width: 64,
                            height: 64,
                            child: showBiometrics
                                ? IconButton(
                                    icon: Icon(
                                      Icons.fingerprint,
                                      size: 36,
                                      color: theme.colorScheme.primary,
                                    ),
                                    onPressed: () => context
                                        .read<SecurityCubit>()
                                        .unlockWithBiometrics(),
                                  )
                                : const SizedBox.shrink(),
                          ),
                          _buildKeypadButton('0'),
                          SizedBox(
                            width: 64,
                            height: 64,
                            child: IconButton(
                              icon: const Icon(
                                Icons.backspace_outlined,
                                size: 28,
                              ),
                              onPressed: _onBackspacePressed,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
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

    return InkResponse(
      onTap: () => _onDigitPressed(digit),
      radius: 36,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.colorScheme.surfaceContainerHighest.withAlpha(120),
        ),
        alignment: Alignment.center,
        child: Text(
          digit,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
