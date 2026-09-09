import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Regression test for the real runtime failure on the Manufacturer (factory)
/// details page.
///
/// The details page, "View All" and the print/report flow all run optimized
/// Firestore queries of the form:
///
///   where(entityId == ...)
///     [where('type', ...)]
///     orderBy('createdAt', descending: true)
///     [limit(...)]
///
/// These queries require composite indexes. The factory query was failing at
/// runtime (`FACTORY TRIPS LIMITED ERROR` -> "The query requires an index")
/// because the `factoryId + createdAt` composite index was missing from
/// `firestore.indexes.json` (bus and driver already had theirs), so the
/// Manufacturer details page showed its error widget while loading.
///
/// This test guards the index configuration so the factory (and the type-filter
/// variants for all entities) can never silently lose their indexes again.

void main() {
  Map<String, dynamic> indexConfig() {
    final file = File('firestore.indexes.json');
    expect(file.existsSync(), isTrue,
        reason: 'firestore.indexes.json must exist at project root');
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }

  List<Map<String, dynamic>> collectIndexes(Map<String, dynamic> config) {
    final indexes = config['indexes'];
    expect(indexes, isA<List>(), reason: '"indexes" must be an array');
    return List<Map<String, dynamic>>.from(
        (indexes as List).cast<Map<String, dynamic>>());
  }

  List<String> fieldPaths(Map<String, dynamic> index) {
    final fields = index['fields'];
    expect(fields, isA<List>(), reason: 'each index must define "fields"');
    return (fields as List)
        .map((f) => (f as Map<String, dynamic>)['fieldPath'].toString())
        .toList();
  }

  bool hasIndex(
    List<Map<String, dynamic>> indexes, {
    required String collectionGroup,
    required List<String> expectedFields,
  }) {
    for (final index in indexes) {
      if (index['collectionGroup'] != collectionGroup) continue;
      final fields = fieldPaths(index);
      if (fields.length != expectedFields.length) continue;
      var matches = true;
      for (var i = 0; i < expectedFields.length; i++) {
        if (fields[i] != expectedFields[i]) {
          matches = false;
          break;
        }
      }
      if (matches) return true;
    }
    return false;
  }

  group('Firestore composite indexes (trips)', () {
    test('factory details page: factoryId equality + createdAt DESC order', () {
      final indexes = collectIndexes(indexConfig());

      expect(
        hasIndex(
          indexes,
          collectionGroup: 'trips',
          expectedFields: ['factoryId', 'createdAt'],
        ),
        isTrue,
        reason:
            'Missing "factoryId ASC + createdAt DESC" composite index. Without it '
            'the FactoryDetailsScreen limited query throws '
            '"The query requires an index" and the Manufacturer page shows its '
            'error text.',
      );
    });

    test('bus details page: busId equality + createdAt DESC order', () {
      final indexes = collectIndexes(indexConfig());
      expect(
        hasIndex(
          indexes,
          collectionGroup: 'trips',
          expectedFields: ['busId', 'createdAt'],
        ),
        isTrue,
        reason: 'Missing "busId ASC + createdAt DESC" composite index.',
      );
    });

    test('driver details page: driverId equality + createdAt DESC order', () {
      final indexes = collectIndexes(indexConfig());
      expect(
        hasIndex(
          indexes,
          collectionGroup: 'trips',
          expectedFields: ['driverId', 'createdAt'],
        ),
        isTrue,
        reason: 'Missing "driverId ASC + createdAt DESC" composite index.',
      );
    });

    test('View All type filter (bus): busId + type + createdAt DESC', () {
      final indexes = collectIndexes(indexConfig());
      expect(
        hasIndex(
          indexes,
          collectionGroup: 'trips',
          expectedFields: ['busId', 'type', 'createdAt'],
        ),
        isTrue,
        reason:
            'Missing "busId + type + createdAt DESC" index for the trips/night '
            'outings server-side type filter in View All.',
      );
    });

    test('View All type filter (driver): driverId + type + createdAt DESC', () {
      final indexes = collectIndexes(indexConfig());
      expect(
        hasIndex(
          indexes,
          collectionGroup: 'trips',
          expectedFields: ['driverId', 'type', 'createdAt'],
        ),
        isTrue,
        reason:
            'Missing "driverId + type + createdAt DESC" index for the trips/night '
            'outings server-side type filter in View All.',
      );
    });

    test('View All type filter (factory): factoryId + type + createdAt DESC',
        () {
      final indexes = collectIndexes(indexConfig());
      expect(
        hasIndex(
          indexes,
          collectionGroup: 'trips',
          expectedFields: ['factoryId', 'type', 'createdAt'],
        ),
        isTrue,
        reason:
            'Missing "factoryId + type + createdAt DESC" index for the trips/night '
            'outings server-side type filter in View All.',
      );
    });
  });
}
