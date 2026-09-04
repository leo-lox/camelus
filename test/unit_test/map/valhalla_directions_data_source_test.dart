import 'package:camelus/data_layer/data_sources/valhalla_directions_data_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses a Valhalla route response into map-neutral entities', () {
    final route = ValhallaDirectionsDataSource.parseRoute({
      'trip': {
        'summary': {'length': 1.25, 'time': 300},
        'legs': [
          {
            'shape': '_ibE_seK_seK_seK',
            'maneuvers': [
              {
                'instruction': 'Head north',
                'length': 1.25,
                'time': 300,
                'begin_shape_index': 0,
              },
            ],
          },
        ],
      },
    });

    expect(route.lengthMeters, 1250);
    expect(route.duration, const Duration(minutes: 5));
    expect(route.geometry, hasLength(2));
    expect(route.geometry.first.latitude, 0.1);
    expect(route.geometry.first.longitude, 0.2);
    expect(route.maneuvers.single.instruction, 'Head north');
  });
}
