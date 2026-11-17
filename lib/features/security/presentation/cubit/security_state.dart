import 'package:equatable/equatable.dart';

class SecurityState extends Equatable {
  final bool isInitialized;
  final bool isAppLockEnabled;
  final bool hasPinSet;
  final bool isBiometricsEnabled;
  final bool isBiometricsAvailable;
  final bool isLocked;
  final String? errorMessage;

  const SecurityState({
    this.isInitialized = false,
    this.isAppLockEnabled = false,
    this.hasPinSet = false,
    this.isBiometricsEnabled = false,
    this.isBiometricsAvailable = false,
    this.isLocked = false,
    this.errorMessage,
  });

  const SecurityState.initial()
      : isInitialized = false,
        isAppLockEnabled = false,
        hasPinSet = false,
        isBiometricsEnabled = false,
        isBiometricsAvailable = false,
        isLocked = false,
        errorMessage = null;

  SecurityState copyWith({
    bool? isInitialized,
    bool? isAppLockEnabled,
    bool? hasPinSet,
    bool? isBiometricsEnabled,
    bool? isBiometricsAvailable,
    bool? isLocked,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SecurityState(
      isInitialized: isInitialized ?? this.isInitialized,
      isAppLockEnabled: isAppLockEnabled ?? this.isAppLockEnabled,
      hasPinSet: hasPinSet ?? this.hasPinSet,
      isBiometricsEnabled: isBiometricsEnabled ?? this.isBiometricsEnabled,
      isBiometricsAvailable: isBiometricsAvailable ?? this.isBiometricsAvailable,
      isLocked: isLocked ?? this.isLocked,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        isInitialized,
        isAppLockEnabled,
        hasPinSet,
        isBiometricsEnabled,
        isBiometricsAvailable,
        isLocked,
        errorMessage,
      ];
}
