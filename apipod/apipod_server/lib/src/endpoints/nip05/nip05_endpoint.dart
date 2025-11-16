import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import 'disallowed_words.dart';
import 'name_suggestions.dart';

class Nip05Endpoint extends Endpoint {
  static final nip05CacheLifetime = Duration(minutes: 10);

  Future<Nip05Response?> getNip05(
    Session session,
    String? name,
    String domain,
  ) async {
    // If name is null or empty, look for a default record for the domain
    bool isDefaultLookup = name == null || name.isEmpty;
    String lookupName = isDefaultLookup ? '_' : name;

    var cacheKey =
        isDefaultLookup ? 'nip05-default-$domain' : 'nip05-$lookupName-$domain';

    final foundData = await session.caches.local.get(
      cacheKey,
      CacheMissHandler(
        () async => await Nip05Data.db.findFirstRow(
          session,
          where: (t) => t.domain.equals(domain) & t.name.equals(lookupName),
          orderBy: (t) => t.createdAt,
          orderDescending: true,
        ),
        lifetime: Duration(minutes: 10),
      ),
    );

    if (foundData == null) {
      return null;
    }

    return Nip05Response(domain: foundData.domain, names: {
      foundData.name: foundData.pubkey,
    }, relays: {
      foundData.pubkey: foundData.relays,
    });
  }

  Future<NameCheckResult> checkName(
    Session session,
    String nameUser,
    String domain,
  ) async {
    final result = NameCheckResult(
      isAvailable: false,
      suggestions: [],
    );

    final cleanedName = nameUser.replaceAll(" ", "");

    // Check if name is in disallowed list
    if (disallowedWords.contains(cleanedName.toLowerCase())) {
      result.reason = 'This name is not allowed';
      // Generate suggestions
      result.suggestions = generateSuggestions(cleanedName);
      return result;
    }

    // Check if name exists in database
    final existingName = await Nip05Data.db.findFirstRow(
      session,
      where: (t) => t.name.equals(cleanedName) & t.domain.equals(domain),
    );

    if (existingName == null) {
      // Name is available
      result.isAvailable = true;
      return result;
    } else {
      result.reason = 'This name is already taken';
      result.suggestions = generateSuggestions(cleanedName);
      return result;
    }
  }
}
