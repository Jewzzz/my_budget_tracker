import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/security_cubit.dart';
import '../cubit/security_state.dart';
import 'lock_screen.dart';

class AppLockInterceptor extends StatefulWidget {
  final Widget child;

  const AppLockInterceptor({
    super.key,
    required this.child,
  });

  @override
  State<AppLockInterceptor> createState() => _AppLockInterceptorState();
}

class _AppLockInterceptorState extends State<AppLockInterceptor>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    context.read<SecurityCubit>().initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (lifecycleState == AppLifecycleState.paused ||
        lifecycleState == AppLifecycleState.detached) {
      context.read<SecurityCubit>().lockApp();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SecurityCubit, SecurityState>(
      builder: (context, state) {
        if (state.isLocked) {
          return const LockScreen();
        }
        return widget.child;
      },
    );
  }
}
