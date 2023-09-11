import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapis_antonello_ghezzi/controller/providers.dart';

class SettingsPage extends ConsumerWidget {
  final TextEditingController cmBetweenSignalsController;
  final TextEditingController metersController;

  SettingsPage({required int cmBetweenSignals, required int meters, super.key})
      : this.cmBetweenSignalsController =
            TextEditingController(text: cmBetweenSignals.toString()),
        this.metersController = TextEditingController(text: meters.toString());

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = ref.watch(modelProvider);
    debugPrint("> ${model.totalSignals()} > ${model.remainingDistanceInMeters()}");

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('To the Moon!'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Text("Centimetri tra le bande segnalatrici"),
              const SizedBox(height: 8),
              TextField(
                controller: this.cmBetweenSignalsController,
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  try {
                    ref
                        .read(modelProvider.notifier)
                        .updateCmBetweenSignals(int.parse(value));
                  } catch (_) {}
                },
              ),
              const SizedBox(height: 32),
              const Text("Metri percorsi"),
              const SizedBox(height: 8),
              TextField(
                controller: this.metersController,
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  try {
                    ref
                        .read(modelProvider.notifier)
                        .updateMeters(int.parse(value));
                  } catch (_) {}
                },
              ),
              const SizedBox(height: 16),
              Text("Rimanenti: ${model.remainingDistanceInMeters()}"),
            ],
          ),
        ),
      ),
    );
  }
}
