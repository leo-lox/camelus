import 'package:ndk/ndk.dart';

import 'key_pair.dart';

enum LoginType {
  register,
  privateKey,
  amber,
  bunkerConnection,
  readOnly,
  anon,
  webExtension,
}

class StartupAccountData {
  final LoginType loginType;
  final LocalStorageAccount? account;

  StartupAccountData({required this.loginType, this.account});
}

class LocalStorageAccount {
  final LoginType loginType;
  final String? pubkey;
  final KeyPair? keyPair;
  final BunkerConnection? bunkerConnection;
  LocalStorageAccount({
    required this.loginType,
    this.pubkey,
    this.keyPair,
    this.bunkerConnection,
  });
  Map<String, Object?> toJson() {
    return {
      'loginType': loginType.toString(),
      'pubkey': pubkey,
      'keyPair': keyPair?.toJson(),
      'bunkerConnection': bunkerConnection?.toJson(),
    };
  }

  factory LocalStorageAccount.fromJson(Map<String, dynamic> json) {
    return LocalStorageAccount(
      loginType: LoginType.values.firstWhere(
        (e) => e.toString() == json['loginType'],
        orElse: () => LoginType.register,
      ),
      pubkey: json['pubkey'],
      keyPair: json['keyPair'] != null
          ? KeyPair.fromJson(json['keyPair'])
          : null,
      bunkerConnection: json['bunkerConnection'] != null
          ? BunkerConnection.fromJson(json['bunkerConnection'])
          : null,
    );
  }
}
