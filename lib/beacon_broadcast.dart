//import 'dart:async';
//import 'dart:io';
//
//import 'package:beacon_broadcast/beacon_broadcast.dart';
//import 'package:flutter/material.dart';
//import 'package:flutter/services.dart';
//import 'package:flutter_beacon/flutter_beacon.dart';
//
//void main() {
//  runApp(MyApp());
//}
//
//class MyApp extends StatefulWidget {
//  @override
//  _MyAppState createState() => _MyAppState();
//}
//
//class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
//  @override
//  Widget build(BuildContext context) {
//    return MaterialApp(
//      home: Scaffold(
//        body: SingleChildScrollView(
//          child: Padding(
//            padding: const EdgeInsets.all(8.0),
//            child: Column(
//              mainAxisAlignment: MainAxisAlignment.center,
//              mainAxisSize: MainAxisSize.min,
//              crossAxisAlignment: CrossAxisAlignment.start,
//              children: <Widget>[
//                Text('Is transmission supported?',
//                    style: Theme.of(context).textTheme.headline),
//                Text('$_isTransmissionSupported',
//                    style: Theme.of(context).textTheme.subhead),
//                Container(height: 16.0),
//                Text('Is beacon started?',
//                    style: Theme.of(context).textTheme.headline),
//                Text('$_isAdvertising',
//                    style: Theme.of(context).textTheme.subhead),
//                Container(height: 16.0),
//                Center(
//                  child: RaisedButton(
//                    onPressed: () {
//                      beaconBroadcast
//                          .setUUID(UUIDBroadcast)
//                          .setMajorId(MAJOR_ID)
//                          .setMinorId(MINOR_ID)
//                          .setTransmissionPower(-59)
//                          .setIdentifier(IDENTIFIER)
//                          .setLayout(LAYOUT)
//                          .setManufacturerId(MANUFACTURER_ID)
//                          .start();
//                    },
//                    child: Text('START'),
//                  ),
//                ),
//                Center(
//                  child: RaisedButton(
//                    onPressed: () {
//                      beaconBroadcast.stop();
//                    },
//                    child: Text('STOP'),
//                  ),
//                ),
//                Text('Beacon Data',
//                    style: Theme.of(context).textTheme.headline),
//                Text('UUID: $UUIDBroadcast'),
//                Text('Major id: $MAJOR_ID'),
//                Text('Minor id: $MINOR_ID'),
//                Text('Tx Power: $TRANSMISSION_POWER'),
//                Text('Identifier: $IDENTIFIER'),
//                Text('Layout: $LAYOUT'),
//                Text('Manufacturer Id: $MANUFACTURER_ID'),
//                _monitorBeacons == null
//                    ? Center(child: CircularProgressIndicator())
//                    : _monitorBeacons.isEmpty
//                        ? Center(child: Container(child: Text('No Devices')))
//                        : ListView(
//                            children: ListTile.divideTiles(
//                                context: context,
//                                tiles: _monitorBeacons.map((beacon) {
//                                  return ListTile(
//                                    title: Text(beacon.proximityUUID),
//                                    subtitle: new Row(
//                                      mainAxisSize: MainAxisSize.max,
//                                      children: <Widget>[
//                                        Flexible(
//                                            child: Text(
//                                                'Major: ${beacon.major}\nMinor: ${beacon.minor}',
//                                                style:
//                                                    TextStyle(fontSize: 13.0)),
//                                            flex: 1,
//                                            fit: FlexFit.tight),
//                                        Flexible(
//                                            child: Text(
//                                                'Accuracy: ${beacon.accuracy}m\nRSSI: ${beacon.rssi}',
//                                                style:
//                                                    TextStyle(fontSize: 13.0)),
//                                            flex: 2,
//                                            fit: FlexFit.tight)
//                                      ],
//                                    ),
//                                  );
//                                })).toList(),
//                          ),
//              ],
//            ),
//          ),
//        ),
//      ),
//    );
//
////    return MaterialApp(
////      theme: ThemeData(
////        brightness: Brightness.light,
////        primaryColor: Colors.white,
////      ),
////      darkTheme: ThemeData(
////        brightness: Brightness.dark,
////      ),
////      home: Scaffold(
////        body: _monitorBeacons == null
////            ? Center(child: CircularProgressIndicator())
////            : _monitorBeacons.isEmpty
////                ? Center(child: Container(child: Text('No Devices')))
////                : ListView(
////                    children: ListTile.divideTiles(
////                        context: context,
////                        tiles: _monitorBeacons.map((beacon) {
////                          return ListTile(
////                            title: Text(beacon.proximityUUID),
////                            subtitle: new Row(
////                              mainAxisSize: MainAxisSize.max,
////                              children: <Widget>[
////                                Flexible(
////                                    child: Text(
////                                        'Major: ${beacon.major}\nMinor: ${beacon.minor}',
////                                        style: TextStyle(fontSize: 13.0)),
////                                    flex: 1,
////                                    fit: FlexFit.tight),
////                                Flexible(
////                                    child: Text(
////                                        'Accuracy: ${beacon.accuracy}m\nRSSI: ${beacon.rssi}',
////                                        style: TextStyle(fontSize: 13.0)),
////                                    flex: 2,
////                                    fit: FlexFit.tight)
////                              ],
////                            ),
////                          );
////                        })).toList(),
////                  ),
////      ),
////    );
//  }
//}
