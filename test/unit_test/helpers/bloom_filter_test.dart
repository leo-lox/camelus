import 'dart:convert';
import 'package:camelus/helpers/bloom_filter.dart';
import 'package:flutter/foundation.dart';
import 'package:test/test.dart';

void main() {
  group('BloomFilter', () {
    test('initialization with valid parameters', () {
      final filter =
          BloomFilter(falsePositiveProbability: 0.01, numItems: 1000);
      expect(filter.size, greaterThan(0));
      expect(filter.numHashFunctions, greaterThan(0));
    });

    test('throws exception with invalid probability', () {
      expect(() => BloomFilter(falsePositiveProbability: 0, numItems: 1000),
          throwsArgumentError);
      expect(() => BloomFilter(falsePositiveProbability: 1, numItems: 1000),
          throwsArgumentError);
      expect(() => BloomFilter(falsePositiveProbability: -0.1, numItems: 1000),
          throwsArgumentError);
    });

    test('throws exception with invalid number of items', () {
      expect(() => BloomFilter(falsePositiveProbability: 0.01, numItems: 0),
          throwsArgumentError);
      expect(() => BloomFilter(falsePositiveProbability: 0.01, numItems: -10),
          throwsArgumentError);
    });

    test('add and contains work correctly', () {
      final filter =
          BloomFilter(falsePositiveProbability: 0.01, numItems: 1000);

      // Add some items
      filter.add(
          '395f432aee274459be33c6684fad9471181e0a075bcce8e6fda4050bb1955c51');
      filter.add(
          '9b8b989bcc4c4e618a136965c8f1c82e9cc3db22568a52bdebeb6f2fa0422796');
      filter.add(
          '0f59b606089c756cf02c67012956638a0c0ae78bbf41be0ee3aabceba4803ba0');
      filter.add('gerneric-value');

      // Check for added items
      expect(
          filter.contains(
              '395f432aee274459be33c6684fad9471181e0a075bcce8e6fda4050bb1955c51'),
          isTrue);
      expect(
          filter.contains(
              '9b8b989bcc4c4e618a136965c8f1c82e9cc3db22568a52bdebeb6f2fa0422796'),
          isTrue);
      expect(
          filter.contains(
              '0f59b606089c756cf02c67012956638a0c0ae78bbf41be0ee3aabceba4803ba0'),
          isTrue);
      expect(filter.contains('gerneric-value'), isTrue);

      // Check for non-added items
      expect(filter.contains('notInThere'), isFalse);
      expect(filter.contains('🫠'), isFalse);
    });

    test('serialization and deserialization', () {
      final originalFilter =
          BloomFilter(falsePositiveProbability: 0.01, numItems: 1000);

      // Add some items
      originalFilter.add(
          '301856e2e523686222cfaa317c9d0314dec97ee4387f1bed82ea82d3ad693138');
      originalFilter.add(
          '625bac679a9b02a5b737e3c915209481bb604609247802acd39c1c2c3a68d7a6');
      originalFilter.add(
          'c878f3e84c39f1671dd763c7e96c89926952cdfdf497f075f3441e6590b1a9d3');
      originalFilter.add('generic-value');

      // Serialize
      final serialized = originalFilter.serialize();

      // Deserialize
      final deserializedFilter = BloomFilter.fromNumHashFunctionsAndByteArray(
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
      expect(deserializedFilter.contains('generic-value'), isTrue);
      expect(
          deserializedFilter.contains(
              'faf136b76938530e5a6702bf6f25f6f52a714bc7387bdebc64ae0aefbf8e5937'),
          isFalse);
    });

    test('false positive rate is within expected bounds', () {
      // Create a filter with 1% false positive rate for 1000 items
      final falsePositiveRate = 0.01;
      final numItems = 1000;
      final filter = BloomFilter(
          falsePositiveProbability: falsePositiveRate, numItems: numItems);

      // Add numItems different items
      for (int i = 0; i < numItems; i++) {
        filter.add('item_$i');
      }

      // Test with a different set of items to check false positive rate
      int falsePositives = 0;
      final testSize = 10000;

      for (int i = 0; i < testSize; i++) {
        final testItem = 'test_item_$i';
        if (filter.contains(testItem)) {
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

    test('handles large number of items', () {
      const numberOfItems = 1000000;
      final filter =
          BloomFilter(falsePositiveProbability: 0.01, numItems: numberOfItems);

      // Add many items
      for (int i = 0; i < numberOfItems; i++) {
        filter.add('large_item_$i');
      }

      // Check that all added items are found
      for (int i = 0; i < 10000; i++) {
        expect(filter.contains('large_item_$i'), isTrue);
      }
    });

    test('fromNumHashFunctionsAndByteArray constructor validation', () {
      expect(
          () => BloomFilter.fromNumHashFunctionsAndByteArray(
              numHashFunctions: 0, byteArray: Uint8List(10), size: 10),
          throwsArgumentError);

      expect(
          () => BloomFilter.fromNumHashFunctionsAndByteArray(
              numHashFunctions: -1, byteArray: Uint8List(10), size: 10),
          throwsArgumentError);

      expect(
          () => BloomFilter.fromNumHashFunctionsAndByteArray(
              numHashFunctions: 5, byteArray: Uint8List(0), size: 10),
          throwsArgumentError);
    });
  });
}
