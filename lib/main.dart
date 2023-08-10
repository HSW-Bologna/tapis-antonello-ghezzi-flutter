import 'dart:io'; // for Platform class
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // for PlatformException class
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

// ignore: constant_identifier_names
const String ESP_DEVICE_ID = '7C:DF:A1:61:F3:02';
// ignore: constant_identifier_names
const String ESP_SERVICE_UUID = '000000ff';
// ignore: constant_identifier_names
const String ESP_CHAR_UUID = '0000ff01';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  [
    Permission.location,
    Permission.storage,
    Permission.bluetooth,
    Permission.bluetoothConnect,
    Permission.bluetoothScan
  ].request().then((status) {
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a blue toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: StreamBuilder<BluetoothAdapterState>(
          stream: FlutterBluePlus.adapterState,
          initialData: BluetoothAdapterState.unknown,
          builder: (c, snapshot) {
            final adapterState = snapshot.data;
            if (adapterState == BluetoothAdapterState.on) {
              return const MyHomePage();
            } else {
              FlutterBluePlus.stopScan();
              return BluetoothOffScreen(adapterState: adapterState);
            }
          }),
    );
  }
}

class BluetoothOffScreen extends StatelessWidget {
  const BluetoothOffScreen({super.key, required this.adapterState});

  final BluetoothAdapterState? adapterState;

  static final snackBarKey = GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: snackBarKey,
      child: Scaffold(
        backgroundColor: Colors.lightBlue,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(
                Icons.bluetooth_disabled,
                size: 200.0,
                color: Colors.white54,
              ),
              Text(
                'Bluetooth Adapter is ${adapterState != null ? adapterState.toString().split(".").last : 'not available'}.',
                style: Theme.of(context)
                    .primaryTextTheme
                    .titleSmall
                    ?.copyWith(color: Colors.white),
              ),
              // NOTE: works only on android the turn on from app
              if (Platform.isAndroid)
                ElevatedButton(
                  child: const Text('TURN ON'),
                  onPressed: () async {
                    try {
                      await FlutterBluePlus.turnOn();
                    } catch (e) {
                      final snackBar = SnackBar(
                          content:
                              Text(prettyException("Error Turning On: ", e)));
                      snackBarKey.currentState?.showSnackBar(snackBar);
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  BluetoothDevice? _espDevice;

  void _setEspDevice(BluetoothDevice? device) {
    setState(() {
      _espDevice = device;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_espDevice == null) {
      return DeviceSearch(setDeviceCallback: _setEspDevice);
    } else {
      return DeviceScreen(device: _espDevice, setDeviceCallback: _setEspDevice);
    }
  }
}

class DeviceSearch extends StatefulWidget {
  const DeviceSearch({super.key, required this.setDeviceCallback});

  final Function setDeviceCallback;

  @override
  State<DeviceSearch> createState() => _DeviceSearchState();
}

class _DeviceSearchState extends State<DeviceSearch> {
  static final snackBarKey = GlobalKey<ScaffoldMessengerState>();

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
        if (r.device.remoteId.toString() == ESP_DEVICE_ID) {
          device = r.device;
          print(
              '${r.device.localName} (${r.device.remoteId}) found! rssi: ${r.rssi}');
          break;
        }
      }

      if (device != null) {
        await device.connect(timeout: const Duration(seconds: 4));
        widget.setDeviceCallback(device);
      } else {
        throw "ESP device not found.";
      }
    } catch (e) {
      snackBarKey.currentState?.showSnackBar(
          SnackBar(content: Text(prettyException("Error: ", e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: snackBarKey,
      child: Scaffold(
        appBar: AppBar(
          // TRY THIS: Try changing the color here to a specific color (to
          // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
          // change color while the other colors stay the same.
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: const Text('Device Search'),
        ),
        body: const Center(
          // Center is a layout widget. It takes a single child and positions it
          // in the middle of the parent.
          child: Column(
              // Column is also a layout widget. It takes a list of children and
              // arranges them vertically. By default, it sizes itself to fit its
              // children horizontally, and tries to be as tall as its parent.
              //
              // Column has various properties to control how it sizes itself and
              // how it positions its children. Here we use mainAxisAlignment to
              // center the children vertically; the main axis here is the vertical
              // axis because Columns are vertical (the cross axis would be
              // horizontal).
              //
              // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
              // action in the IDE, or press "p" in the console), to see the
              // wireframe for each widget.
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[]),
        ),
        floatingActionButton: StreamBuilder<bool>(
          stream: FlutterBluePlus.isScanning,
          initialData: false,
          builder: (c, snapshot) {
            if (snapshot.data ?? false) {
              return const FloatingActionButton(
                onPressed: null,
                backgroundColor: Colors.red,
                tooltip: 'Stop scan',
                child: Icon(Icons.search),
              );
            } else {
              return FloatingActionButton(
                onPressed: _startSearchDevice,
                tooltip: 'Start scan',
                child: const Icon(Icons.search),
              );
            }
          },
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class DeviceScreen extends StatefulWidget {
  const DeviceScreen(
      {super.key, required this.device, required this.setDeviceCallback});

  final BluetoothDevice? device; // is never null
  final Function setDeviceCallback;

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  BluetoothCharacteristic? _characteristic;

  @override
  void initState() {
    super.initState();

    _enableNotify();

    // check if device get disconnected
    widget.device?.connectionState.listen((BluetoothConnectionState result) {
      if (result != BluetoothConnectionState.connected) {
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
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: <Widget>[
          Text(
              '${widget.device?.localName} (${widget.device?.remoteId}) found!'),
          StreamBuilder<List<int>>(
              stream: _characteristic?.onValueReceived,
              initialData: const [0, 0, 0, 0],
              builder: (c, snapshot) {
                final vl = snapshot.data;
                final v = (vl![3] << 24) + (vl[2] << 16) + (vl[1] << 8) + vl[0];
                return Text("Value: $v");
              }),
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
