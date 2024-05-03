import 'package:camelus/domain_layer/usecases/follow.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

var followingProvider = Provider<Follow>((ref) {
  final follow = Follow();

  return follow;
});
