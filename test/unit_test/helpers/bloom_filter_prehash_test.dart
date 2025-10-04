import 'dart:convert';
import 'package:camelus/data_layer/models/nostr_note_model.dart';
import 'package:camelus/domain_layer/entities/nostr_note.dart';
import 'package:camelus/helpers/bip340.dart';
import 'package:camelus/helpers/bloom_filter_prehash.dart';
import 'package:flutter/foundation.dart';
import 'package:test/test.dart';

void main() {
  group('BloomFilterPrehash', () {
    test('initialization with valid parameters', () {
      final filter =
          BloomFilterPrehash(falsePositiveProbability: 0.01, numItems: 1000);
      expect(filter.size, greaterThan(0));
      expect(filter.numHashFunctions, greaterThan(0));
    });

    test('throws exception with invalid probability', () {
      expect(
          () => BloomFilterPrehash(falsePositiveProbability: 0, numItems: 1000),
          throwsArgumentError);
      expect(
          () => BloomFilterPrehash(falsePositiveProbability: 1, numItems: 1000),
          throwsArgumentError);
      expect(
          () => BloomFilterPrehash(
              falsePositiveProbability: -0.1, numItems: 1000),
          throwsArgumentError);
    });

    test('throws exception with invalid number of items', () {
      expect(
          () => BloomFilterPrehash(falsePositiveProbability: 0.01, numItems: 0),
          throwsArgumentError);
      expect(
          () =>
              BloomFilterPrehash(falsePositiveProbability: 0.01, numItems: -10),
          throwsArgumentError);
    });

    test('add and contains work correctly', () {
      final filter =
          BloomFilterPrehash(falsePositiveProbability: 0.01, numItems: 1000);

      // Add some items
      filter.add(
          '341ac9cefc8364e77f570cf43fb90ce82d53628fd7d1567e3d5716db3852d11a');
      filter.add(
          '9b8b989bcc4c4e618a136965c8f1c82e9cc3db22568a52bdebeb6f2fa0422796');
      filter.add(
          '0f59b606089c756cf02c67012956638a0c0ae78bbf41be0ee3aabceba4803ba0');

      // Check for added items
      expect(
          filter.contains(
              '341ac9cefc8364e77f570cf43fb90ce82d53628fd7d1567e3d5716db3852d11a'),
          isTrue);
      expect(
          filter.contains(
              '9b8b989bcc4c4e618a136965c8f1c82e9cc3db22568a52bdebeb6f2fa0422796'),
          isTrue);
      expect(
          filter.contains(
              '0f59b606089c756cf02c67012956638a0c0ae78bbf41be0ee3aabceba4803ba0'),
          isTrue);

      // Check for non-added items
      expect(
          filter.contains(
              'cc125c8c1025487681e086c6b3c5b64d6bce14fdc6502c18f3c7472130ea211e'),
          isFalse);
      expect(
          filter.contains(
              '2da7850b3bca47cbe6c08685ea844b33659e5f8b94df469b6005cc012849ef15'),
          isFalse);
    });

    test('serialization and deserialization', () {
      final originalFilter =
          BloomFilterPrehash(falsePositiveProbability: 0.01, numItems: 1000);

      // Add some items
      originalFilter.add(
          '301856e2e523686222cfaa317c9d0314dec97ee4387f1bed82ea82d3ad693138');
      originalFilter.add(
          '625bac679a9b02a5b737e3c915209481bb604609247802acd39c1c2c3a68d7a6');
      originalFilter.add(
          'c878f3e84c39f1671dd763c7e96c89926952cdfdf497f075f3441e6590b1a9d3');

      // Serialize
      final serialized = originalFilter.serialize();

      // Deserialize
      final deserializedFilter =
          BloomFilterPrehash.fromNumHashFunctionsAndByteArray(
        numHashFunctions: originalFilter.numHashFunctions,
        byteArray: base64Decode(serialized),
        size: originalFilter.size,
      );

      // Check that deserialized filter behaves the same
      expect(
          deserializedFilter.contains(
              '301856e2e523686222cfaa317c9d0314dec97ee4387f1bed82ea82d3ad693138'),
          isTrue);
      expect(
          deserializedFilter.contains(
              '625bac679a9b02a5b737e3c915209481bb604609247802acd39c1c2c3a68d7a6'),
          isTrue);
      expect(
          deserializedFilter.contains(
              'c878f3e84c39f1671dd763c7e96c89926952cdfdf497f075f3441e6590b1a9d3'),
          isTrue);

      expect(
          deserializedFilter.contains(
              'faf136b76938530e5a6702bf6f25f6f52a714bc7387bdebc64ae0aefbf8e5937'),
          isFalse);
    });

    test('false positive rate is within expected bounds', () {
      // Create a filter with 1% false positive rate for 1000 items
      final falsePositiveRate = 0.01;
      final numItems = 1000;
      final filter = BloomFilterPrehash(
          falsePositiveProbability: falsePositiveRate, numItems: numItems);

      // Add numItems different items
      for (int i = 0; i < numItems; i++) {
        final keypair = Bip340().generatePrivateKey();
        final nostrNote = NostrNote(
          id: "",
          sig: "",
          createdAt: 0,
          pubkey: keypair.publicKey,
          content: "hi$i",
          kind: 1,
          tags: [],
        );
        final ndkEvent = NostrNoteModel.fromEntity(nostrNote).toNDKEvent();

        filter.add(ndkEvent.id);
      }

      // Test with a different set of items to check false positive rate
      int falsePositives = 0;
      final testSize = 1000;

      for (int i = 0; i < testSize; i++) {
        final keypair = Bip340().generatePrivateKey();
        final nostrNote = NostrNote(
          id: "",
          sig: "",
          createdAt: 0,
          pubkey: keypair.publicKey,
          content: "hi$i",
          kind: 1,
          tags: [],
        );
        final testItem = NostrNoteModel.fromEntity(nostrNote).toNDKEvent();

        if (filter.contains(testItem.id)) {
          falsePositives++;
        }
      }

      final actualFalsePositiveRate = falsePositives / testSize;

      // Allow some margin of error (3x the expected rate)
      expect(actualFalsePositiveRate, lessThan(falsePositiveRate * 3));

      if (kDebugMode) {
        print('Expected false positive rate: $falsePositiveRate');
        print('Actual false positive rate: $actualFalsePositiveRate');
      }
    });

    test('fromNumHashFunctionsAndByteArray constructor validation', () {
      expect(
          () => BloomFilterPrehash.fromNumHashFunctionsAndByteArray(
              numHashFunctions: 0, byteArray: Uint8List(10), size: 10),
          throwsArgumentError);

      expect(
          () => BloomFilterPrehash.fromNumHashFunctionsAndByteArray(
              numHashFunctions: -1, byteArray: Uint8List(10), size: 10),
          throwsArgumentError);

      expect(
          () => BloomFilterPrehash.fromNumHashFunctionsAndByteArray(
              numHashFunctions: 5, byteArray: Uint8List(0), size: 10),
          throwsArgumentError);
    });
  });
}
