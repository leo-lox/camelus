import 'package:camelus/domain_layer/entities/onboarding_user_info.dart';
import 'package:camelus/domain_layer/usecases/onboard.dart';
import 'package:camelus/helpers/bip340.dart';
import 'package:riverpod/riverpod.dart';

final onboardingProvider = Provider<Onboard>((ref) {
  OnboardingUserInfo signUpInfo = OnboardingUserInfo(
    keyPair: Bip340().generatePrivateKey(),
  );
  final onboard = Onboard(
    signUpInfo: signUpInfo,
  );

  return onboard;
});
