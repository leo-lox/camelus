import 'package:ndk/data_layer/repositories/wallets/sembast_wallets_repo.dart';
import 'package:ndk/domain_layer/entities/cashu/cashu_keyset.dart';
import 'package:ndk/domain_layer/entities/cashu/cashu_mint_info.dart';
import 'package:ndk/domain_layer/entities/cashu/cashu_proof.dart';
import 'package:ndk/domain_layer/entities/nip_05.dart';
import 'package:ndk/domain_layer/entities/user_relay_list.dart';
import 'package:ndk/domain_layer/entities/wallet/wallet.dart';
import 'package:ndk/domain_layer/entities/wallet/wallet_transaction.dart';
import 'package:ndk/domain_layer/entities/wallet/wallet_type.dart';
import 'package:ndk/ndk.dart';
import 'package:sembast_web/sembast_web.dart';

Future<CacheManager> createNdkCacheManager() async {
  final Database database = await databaseFactoryWeb.openDatabase(
    'camelus_ndk_cache.db',
  );

  final walletsRepo = SembastWalletsRepo(database);

  MyCombinedDb combinedDb = MyCombinedDb(database, walletsRepo: walletsRepo);

  return combinedDb;
}

class MyCombinedDb extends SembastCacheManager implements SembastWalletsRepo {
  final SembastWalletsRepo _walletsRepo;
  MyCombinedDb(super.database, {required SembastWalletsRepo walletsRepo})
    : _walletsRepo = walletsRepo;

  @override
  Future<void> clearWalletRepoData() {
    return _walletsRepo.clearWalletRepoData();
  }

  @override
  String? getDefaultWalletIdForReceiving() {
    return _walletsRepo.getDefaultWalletIdForReceiving();
  }

  @override
  String? getDefaultWalletIdForSending() {
    return _walletsRepo.getDefaultWalletIdForSending();
  }

  @override
  Future<List<WalletTransaction>> getTransactions({
    int? limit,
    int? offset,
    String? walletId,
    String? unit,
    WalletType? walletType,
  }) {
    return _walletsRepo.getTransactions(
      limit: limit,
      offset: offset,
      walletId: walletId,
      unit: unit,
      walletType: walletType,
    );
  }

  @override
  Future<Wallet> getWallet(String id) {
    return _walletsRepo.getWallet(id);
  }

  @override
  Future<List<Wallet>> getWallets({List<String>? ids}) {
    return _walletsRepo.getWallets(ids: ids);
  }

  @override
  Future<void> initializeWalletDefaults() {
    return _walletsRepo.initializeWalletDefaults();
  }

  @override
  Future<void> removeWallet(String walletId) {
    return _walletsRepo.removeWallet(walletId);
  }

  @override
  Future<void> saveTransactions(List<WalletTransaction> transactions) {
    return _walletsRepo.saveTransactions(transactions);
  }

  @override
  void setDefaultWalletForReceiving(String? walletId) {
    _walletsRepo.setDefaultWalletForReceiving(walletId);
  }

  @override
  void setDefaultWalletForSending(String? walletId) {
    _walletsRepo.setDefaultWalletForSending(walletId);
  }

  @override
  Future<void> storeWallet(Wallet wallet) {
    return _walletsRepo.storeWallet(wallet);
  }
}
