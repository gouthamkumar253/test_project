//  Copyright (c) 2018 Loup Inc.
//  Licensed under Apache License v2.0

import 'dart:async';

import 'package:beacon_broadcast/beacon_broadcast.dart';
import 'package:beacons/beacons.dart'
    hide MonitoringResult, RangingResult, Beacon;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_beacon/flutter_beacon.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'tab_monitoring.dart';
import 'tab_ranging.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(new MyApp());
}

class MyApp extends StatefulWidget {
  MyApp() {
    Beacons.loggingEnabled = true;

    int notifId = 0;

    Beacons.backgroundMonitoringEvents().listen((event) {
      FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
          new FlutterLocalNotificationsPlugin();
      AndroidInitializationSettings initializationSettingsAndroid =
          new AndroidInitializationSettings('app_icon');
      IOSInitializationSettings initializationSettingsIOS =
          new IOSInitializationSettings();
      InitializationSettings initializationSettings =
          new InitializationSettings(
              initializationSettingsAndroid, initializationSettingsIOS);
      flutterLocalNotificationsPlugin.initialize(initializationSettings);

      AndroidNotificationDetails androidPlatformChannelSpecifics =
          new AndroidNotificationDetails(
              'id10000', 'Local Notification', 'Desc');
      IOSNotificationDetails iOSPlatformChannelSpecifics =
          new IOSNotificationDetails();
      NotificationDetails platformChannelSpecifics = new NotificationDetails(
          androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
      flutterLocalNotificationsPlugin.show(
        ++notifId,
        event.type.toString(),
        event.state.toString(),
        platformChannelSpecifics,
      );
    });

    Beacons.configure(BeaconsSettings(
      android: BeaconsSettingsAndroid(
        logs: BeaconsSettingsAndroidLogs.info,
      ),
    ));
  }

  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final StreamController<BluetoothState> streamController = StreamController();
  StreamSubscription<BluetoothState> _streamBluetooth;
  StreamSubscription<MonitoringResult> _monitorRanging;
  StreamSubscription<RangingResult> _streamRanging;
  final _rangingBeacons = <Beacon>[];

  bool authorizationStatusOk = false;
  bool locationServiceEnabled = false;
  bool bluetoothEnabled = false;
  static const IDENTIFIER = 'beacon';
  static const UUIDBroadcast = '39ED98FF-2900-441A-802F-9C398FC199D4';

  static const MAJOR_ID = 1;
  static const MINOR_ID = 100;
  static const TRANSMISSION_POWER = -59;
  static const LAYOUT = BeaconBroadcast.ALTBEACON_LAYOUT;
  static const MANUFACTURER_ID = 0x0118;
  final _regionBeacons = <Region, List<Beacon>>{};
  final _monitorBeacons = <Beacon>[];
  final regions = <Region>[
    Region(
      identifier: IDENTIFIER,
      proximityUUID: UUIDBroadcast,
    ),
  ];

  BeaconBroadcast beaconBroadcast = BeaconBroadcast();

  BeaconStatus _isTransmissionSupported;
  bool _isAdvertising = false;
  StreamSubscription<bool> _isAdvertisingSubscription;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);

    super.initState();

    listeningState();
    beaconBroadcast
        .checkTransmissionSupported()
        .then((isTransmissionSupported) {
      setState(() {
        _isTransmissionSupported = isTransmissionSupported;
      });
    });

    _isAdvertisingSubscription =
        beaconBroadcast.getAdvertisingStateChange().listen((isAdvertising) {
      setState(() {
        _isAdvertising = isAdvertising;
      });
    });
  }

  listeningState() async {
    _streamBluetooth = flutterBeacon
        .bluetoothStateChanged()
        .listen((BluetoothState state) async {
      streamController.add(state);

      switch (state) {
        case BluetoothState.stateOn:
          initScanBeacon();
          break;
        case BluetoothState.stateOff:
          await pauseScanBeacon();
          await checkAllRequirements();
          break;
      }
    });
  }

  checkAllRequirements() async {
    final bluetoothState = await flutterBeacon.bluetoothState;
    final bluetoothEnabled = bluetoothState == BluetoothState.stateOn;
    final authorizationStatus = await flutterBeacon.authorizationStatus;
    final authorizationStatusOk =
        authorizationStatus == AuthorizationStatus.allowed ||
            authorizationStatus == AuthorizationStatus.always;
    final locationServiceEnabled =
        await flutterBeacon.checkLocationServicesIfEnabled;

    setState(() {
      this.authorizationStatusOk = authorizationStatusOk;
      this.locationServiceEnabled = locationServiceEnabled;
      this.bluetoothEnabled = bluetoothEnabled;
    });
  }

  initScanBeacon() async {
    await flutterBeacon.initializeScanning;
    await checkAllRequirements();
    if (!authorizationStatusOk ||
        !locationServiceEnabled ||
        !bluetoothEnabled) {
      print('RETURNED, authorizationStatusOk=$authorizationStatusOk, '
          'locationServiceEnabled=$locationServiceEnabled, '
          'bluetoothEnabled=$bluetoothEnabled');
      return;
    }

    if (_streamRanging != null) {
      if (_streamRanging.isPaused) {
        _streamRanging.resume();
        return;
      }
    }

    _streamRanging =
        flutterBeacon.ranging(regions).listen((RangingResult result) {
      print(result);
      if (result != null && mounted) {
        setState(() {
          _regionBeacons[result.region] = result.beacons;
          _rangingBeacons.clear();
          _regionBeacons.values.forEach((list) {
            _rangingBeacons.addAll(list);
          });
          _rangingBeacons.sort(_compareParameters);
        });
      }
    });
  }

  pauseScanBeacon() async {
    _streamRanging?.pause();
//    _monitorRanging?.pause();
    if (_rangingBeacons.isNotEmpty) {
      setState(() {
        _rangingBeacons.clear();
      });
    }
  }

  int _compareParameters(Beacon a, Beacon b) {
    int compare = a.proximityUUID.compareTo(b.proximityUUID);

    if (compare == 0) {
      compare = a.major.compareTo(b.major);
    }

    if (compare == 0) {
      compare = a.minor.compareTo(b.minor);
    }

    return compare;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      if (_streamBluetooth != null && _streamBluetooth.isPaused) {
        _streamBluetooth.resume();
      }
      await checkAllRequirements();
      if (authorizationStatusOk && locationServiceEnabled && bluetoothEnabled) {
        await initScanBeacon();
      } else {
        await pauseScanBeacon();
        await checkAllRequirements();
      }
    } else if (state == AppLifecycleState.paused) {
      _streamBluetooth?.pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    streamController?.close();
    _streamRanging?.cancel();
    _monitorRanging?.cancel();
    _streamBluetooth?.cancel();
    flutterBeacon.close;

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new CupertinoTabScaffold(
        tabBar: new CupertinoTabBar(
          items: <BottomNavigationBarItem>[
            new BottomNavigationBarItem(
              title: new Text('Track'),
              icon: new Icon(Icons.location_searching),
            ),
            new BottomNavigationBarItem(
              title: new Text('Monitoring'),
              icon: new Icon(Icons.settings_remote),
            ),
            new BottomNavigationBarItem(
              title: new Text('Settings'),
              icon: new Icon(Icons.settings_input_antenna),
            ),
          ],
        ),
        tabBuilder: (BuildContext context, int index) {
          return new CupertinoTabView(
            builder: (BuildContext context) {
              switch (index) {
                case 0:
                  return new RangingTab();
                case 1:
                  return new MonitoringTab();
                default:
                  return new SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('Is transmission supported?',
                              style: Theme.of(context).textTheme.headline),
                          Text('$_isTransmissionSupported',
                              style: Theme.of(context).textTheme.subhead),
                          Container(height: 16.0),
                          Text('Is beacon started?',
                              style: Theme.of(context).textTheme.headline),
                          Text('$_isAdvertising',
                              style: Theme.of(context).textTheme.subhead),
                          Container(height: 16.0),
                          Center(
                            child: RaisedButton(
                              onPressed: () {
                                beaconBroadcast
                                    .setUUID(UUIDBroadcast)
                                    .setMajorId(MAJOR_ID)
                                    .setMinorId(MINOR_ID)
                                    .setTransmissionPower(-59)
                                    .setIdentifier(IDENTIFIER)
                                    .setLayout(LAYOUT)
                                    .setManufacturerId(MANUFACTURER_ID)
                                    .start();
                              },
                              child: Text('START'),
                            ),
                          ),
                          Center(
                            child: RaisedButton(
                              onPressed: () {
                                beaconBroadcast.stop();
                              },
                              child: Text('STOP'),
                            ),
                          ),
                          Text('Beacon Data',
                              style: Theme.of(context).textTheme.headline),
                          Text('UUID: $UUIDBroadcast'),
                          Text('Major id: $MAJOR_ID'),
                          Text('Minor id: $MINOR_ID'),
                          Text('Tx Power: $TRANSMISSION_POWER'),
                          Text('Identifier: $IDENTIFIER'),
                          Text('Layout: $LAYOUT'),
                          Text('Manufacturer Id: $MANUFACTURER_ID'),
                          _monitorBeacons == null
                              ? Center(child: CircularProgressIndicator())
                              : _monitorBeacons.isEmpty
                                  ? Center(
                                      child:
                                          Container(child: Text('No Devices')))
                                  : ListView(
                                      children: ListTile.divideTiles(
                                          context: context,
                                          tiles: _monitorBeacons.map((beacon) {
                                            return ListTile(
                                              title: Text(beacon.proximityUUID),
                                              subtitle: new Row(
                                                mainAxisSize: MainAxisSize.max,
                                                children: <Widget>[
                                                  Flexible(
                                                      child: Text(
                                                          'Major: ${beacon.major}\nMinor: ${beacon.minor}',
                                                          style: TextStyle(
                                                              fontSize: 13.0)),
                                                      flex: 1,
                                                      fit: FlexFit.tight),
                                                  Flexible(
                                                      child: Text(
                                                          'Accuracy: ${beacon.accuracy}m\nRSSI: ${beacon.rssi}',
                                                          style: TextStyle(
                                                              fontSize: 13.0)),
                                                      flex: 2,
                                                      fit: FlexFit.tight)
                                                ],
                                              ),
                                            );
                                          })).toList(),
                                    ),
                        ],
                      ),
                    ),
                  );
              }
            },
          );
        },
      ),
    );
  }
}
