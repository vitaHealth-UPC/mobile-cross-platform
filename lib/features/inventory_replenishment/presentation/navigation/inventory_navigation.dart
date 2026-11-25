import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/common/result/app_result.dart';
import '../../application/usecases/get_inventory.dart';
import '../../application/usecases/register_initial_inventory.dart';
import '../bloc/inventory_bloc.dart';
import '../bloc/inventory_event.dart';
import '../screens/inventory_screen.dart';

/// Opens the inventory of one medication. The route owns and closes its bloc;
/// a failure that ends the session returns to the root and lets the host decide.
final class InventoryNavigation {
  const InventoryNavigation(
    this._createBloc, {
    this._read,
    this._registerInitial,
  });
  final InventoryBloc Function(String medicationId) _createBloc;
  final GetInventory? _read;
  final RegisterInitialInventory? _registerInitial;

  /// Remaining units, or null without stock, without access or offline.
  Future<int?> remainingStock(String medicationId) async {
    final read = _read;
    if (read == null) return null;
    return switch (await read(medicationId)) {
      AppSuccess(:final value) => value.remainingStock,
      AppFailure() => null,
    };
  }

  /// Registers the first stock of a just-created medication; returns null on
  /// success or the stable failure code.
  Future<String?> registerInitialStock(
    String medicationId, {
    required String quantity,
    required String threshold,
  }) async {
    final register = _registerInitial;
    if (register == null) return 'UNAVAILABLE';
    return switch (await register(
      medicationId,
      quantity: quantity,
      threshold: threshold,
    )) {
      AppSuccess() => null,
      AppFailure(:final code) => code,
    };
  }

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
