import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapis_antonello_ghezzi/controller/providers.dart';
import 'package:tapis_antonello_ghezzi/view/pages/settings.dart';
import 'package:tapis_antonello_ghezzi/view/particle_system.dart';
import 'package:intl/intl.dart';

// ignore: constant_identifier_names
const String ESP_DEVICE_ID = '7C:DF:A1:61:F3:02';
// ignore: constant_identifier_names
const String ESP_SERVICE_UUID = '000000ff';
// ignore: constant_identifier_names
const String ESP_CHAR_UUID = '0000ff01';
const String espDeviceName = 'TO_THE_MOON';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  BluetoothDevice? _espDevice;

  void _setEspDevice(BluetoothDevice? device) {
    setState(() {
      _espDevice = device;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('To the Moon!'),
        actions: <Widget>[
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (await _passwordDialogBuilder(context)) {
                if (context.mounted) {
                  final model = ref.read(modelProvider);
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => SettingsPage(
                          cmBetweenSignals: model.cmBetweenSignals,
                          meters: model.distanceInMeters())));
                }
              }
            },
            itemBuilder: (BuildContext context) {
              return {"Impostazioni"}.map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(choice),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: (_espDevice == null)
          ? DeviceSearch(setDeviceCallback: _setEspDevice)
          : DeviceScreen(device: _espDevice, setDeviceCallback: _setEspDevice),
    );
  }
}

class DeviceSearch extends StatefulWidget {
  const DeviceSearch({super.key, required this.setDeviceCallback});

  final Function setDeviceCallback;

  @override
  State<DeviceSearch> createState() => _DeviceSearchState();
}

class _DeviceSearchState extends State<DeviceSearch> {
  @override
  void initState() {
    super.initState();
    _startSearchDevice();
  }

  void _startSearchDevice() async {
    try {
      final scanResults = await FlutterBluePlus.startScan(
          timeout: const Duration(seconds: 5), androidUsesFineLocation: false);

      BluetoothDevice? device;
      for (ScanResult r in scanResults) {
        if (r.device.localName == espDeviceName) {
          device = r.device;
          debugPrint(
              '${r.device.localName} (${r.device.remoteId}) found! rssi: ${r.rssi}');
          break;
        } else {
          debugPrint(
              '${r.device.localName} (${r.device.remoteId}) other device; rssi: ${r.rssi}');
        }
      }

      if (device != null) {
        await device.connect(timeout: const Duration(seconds: 4));
        widget.setDeviceCallback(device);
      } else {
        throw "ESP device not found.";
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(prettyException("Error: ", e))));
      this._startSearchDevice();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: StreamBuilder<bool>(
        stream: FlutterBluePlus.isScanning,
        initialData: false,
        builder: (c, snapshot) {
          if (snapshot.data ?? false) {
            return const Center(
              child: Text(
                "Scansione in corso...",
                style: TextStyle(color: Color(0xFFFFFFFF)),
              ),
            );
          } else {
            return const SizedBox();
          }
        },
      ),
    );
  }
}

class DeviceScreen extends ConsumerStatefulWidget {
  const DeviceScreen(
      {super.key, required this.device, required this.setDeviceCallback});

  final BluetoothDevice? device; // is never null
  final Function setDeviceCallback;

  @override
  ConsumerState<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends ConsumerState<DeviceScreen> {
  BluetoothCharacteristic? _characteristic;

  @override
  void initState() {
    super.initState();

    _enableNotify();

    // check if device get disconnected
    widget.device?.connectionState.listen((BluetoothConnectionState result) {
      if (result != BluetoothConnectionState.connected) {
        ref.read(modelProvider.notifier).resetSignals();
        widget.setDeviceCallback(null);
      }
    });
  }

  void _enableNotify() async {
    final services = await widget.device?.discoverServices();
    for (BluetoothService s in (services ?? [])) {
      if (s.serviceUuid.toString().substring(0, 8) == ESP_SERVICE_UUID) {
        final characteristics = s.characteristics;
        for (BluetoothCharacteristic c in characteristics) {
          if (c.characteristicUuid.toString().substring(0, 8) ==
              ESP_CHAR_UUID) {
            setState(() {
              _characteristic = c;
            });
            c.setNotifyValue(true);
            c.onValueReceived.listen((event) {
              debugPrint(event.toString());
              final vl = event;
              final v = (vl[3] << 24) + (vl[2] << 16) + (vl[1] << 8) + vl[0];
              ref.read(modelProvider.notifier).updateSignals(v);
            });
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final distance = ref.watch(modelProvider).remainingDistanceInMeters();
    var formatter = NumberFormat('###,###,###', "it_IT");

    return WillPopScope(
      onWillPop: () async {
        //await widget.device?.disconnect();
        //widget.setDeviceCallback(null);
        return false;
      },
      child: Stack(
        children: [
          const Center(child: ParticleSystem()),
          Center(
              child: Text(
            "${formatter.format(distance)} m",
            style: const TextStyle(
                fontSize: 80, fontFamily: "Digital", color: Color(0xFFFFFFFF)),
          )),
          /*Text(
                  '${widget.device?.localName} (${widget.device?.remoteId}) found!'),
              StreamBuilder<List<int>>(
                  stream: _characteristic?.onValueReceived,
                  initialData: const [0, 0, 0, 0],
                  builder: (c, snapshot) {
                    final vl = snapshot.data;
                    final v =
                        (vl![3] << 24) + (vl[2] << 16) + (vl[1] << 8) + vl[0];
                    final distance =
                        ref.watch(modelProvider).distanceInMetersFromSignals(v);
                    return Text(
                        "Distanza percorsa: $distance / ${EARTH_MOON_CM ~/ 100}");
                  }),*/
        ],
      ),
    );
  }
}

String prettyException(String prefix, dynamic e) {
  if (e is FlutterBluePlusException) {
    return "$prefix ${e.errorString}";
  } else if (e is PlatformException) {
    return "$prefix ${e.message}";
  }
  return prefix + e.toString();
}

Future<bool> _passwordDialogBuilder(BuildContext context) {
  TextEditingController passwordController = TextEditingController();

  return showDialog<bool?>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        content: SingleChildScrollView(
          child: PasswordInput(controller: passwordController),
        ),
        actions: <Widget>[
          TextButton(
            style: TextButton.styleFrom(
              textStyle: Theme.of(context).textTheme.labelLarge,
            ),
            child: const Text("Conferma"),
            onPressed: () {
              if (passwordController.text == "agmoon") {
                Navigator.of(context).pop(true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Password errata")));
                Navigator.of(context).pop(false);
              }
            },
          ),
        ],
      );
    },
  ).then((value) => value ?? false);
}

class PasswordInput extends StatefulWidget {
  final TextEditingController controller;

  const PasswordInput({
    required this.controller,
    super.key,
  });

  @override
  PasswordInputState createState() => PasswordInputState();
}

class PasswordInputState extends State<PasswordInput> {
  bool obscured = true;

  @override
  Widget build(BuildContext context) {
    return Form(
      autovalidateMode: AutovalidateMode.disabled,
      child: TextFormField(
        controller: this.widget.controller,
        obscureText: this.obscured,
        decoration: InputDecoration(
          hintText: "Password",
          suffixIcon: IconButton(
            icon: Icon(
              // Based on passwordVisible state choose the icon
              this.obscured ? Icons.visibility : Icons.visibility_off,
              color: Theme.of(context).primaryColorDark,
            ),
            onPressed: () => setState(() {
              this.obscured = !this.obscured;
            }),
          ),
        ),
      ),
    );
  }
}
