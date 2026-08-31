import 'package:elostaz_travel/domain/bus/entity/bus_entity.dart';
import 'package:elostaz_travel/presentation/home/tabs/all_trips/all_trips_page.dart';
import 'package:flutter/material.dart';

class BusTripsScreen extends StatelessWidget {
  const BusTripsScreen({
    super.key,
    required this.bus,
  });

  final BusEntity bus;

  @override
  Widget build(BuildContext context) {
    return AllTripsPage(
      entity: bus,
      title: 'رحلات ${bus.busName}',
    );
  }
}
