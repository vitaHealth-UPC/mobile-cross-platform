import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/inventory_bloc.dart';
import '../bloc/inventory_event.dart';
import '../screens/inventory_screen.dart';

/// Opens the inventory of one medication. The route owns and closes its bloc;
/// a failure that ends the session returns to the root and lets the host decide.
final class InventoryNavigation {
  const InventoryNavigation(this._createBloc);
  final InventoryBloc Function(String medicationId) _createBloc;

  Future<void> open(
    BuildContext context, {
    required String medicationId,
    required String medicationLabel,
    required VoidCallback onSessionInvalidated,
    String? personName,
    Widget Function(BuildContext context)? navigationBuilder,
  }) => Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) =>
            _createBloc(medicationId)..add(const InventoryRequested()),
        child: Builder(
          builder: (inner) => InventoryScreen(
            medicationLabel: medicationLabel,
            personName: personName,
            navigationBar: navigationBuilder?.call(inner),
            onSessionInvalidated: () {
              Navigator.of(inner).popUntil((route) => route.isFirst);
              onSessionInvalidated();
            },
          ),
        ),
      ),
    ),
  );
}
