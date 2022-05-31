import 'dart:developer' as developer;
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:ui';

import 'package:background_locator/background_locator.dart';
import 'package:background_locator/location_dto.dart';
import 'package:background_locator/settings/android_settings.dart';
import 'package:background_locator/settings/ios_settings.dart';
import 'package:background_locator/settings/locator_settings.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';

// import 'package:location/location.dart';
const String _isolateName = "LocatorIsolate";
ReceivePort port = ReceivePort();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  _createLocationService() async {
    // Location location = Location();
    // final status = await location.requestPermission();
    // final isLocationEnabled = await location.requestService();
    //
    // if (status == PermissionStatus.granted && isLocationEnabled) {
    //   final userLocation = await location.getLocation();
    //   developer.log("Location $userLocation");
    //   await location.enableBackgroundMode();
    //   location.onLocationChanged.listen((event) async {
    //     developer.log("Location Events ${event}");
    //     location.changeNotificationOptions(
    //       channelName: 'location_app',
    //       color: Colors.primaries[
    //           math.Random.secure().nextInt(Colors.primaries.length - 1)],
    //       title: "Location: ${event.latitude}|${event.longitude}",
    //       description: "Your current location is accessible",
    //       onTapBringToFront: true,
    //       subtitle: "This is a subheading",
    //     );
    //   });
    // }
  }

  _setLocationBackgroundService() async {
    await BackgroundLocator.initialize();
  }

  static void notificationCallback() {
    print('User clicked on the notification');
  }

  static void locationHandler(data) {
    print('Location Handler ${data}');
  }

  void startLocationService() {
    BackgroundLocator.registerLocationUpdate(LocationCallbackHandler.callback,
        initCallback: LocationCallbackHandler.initCallback,
        initDataCallback: {'countInit': 1},
        disposeCallback: LocationCallbackHandler.disposeCallback,
        autoStop: false,
        iosSettings:
            IOSSettings(accuracy: LocationAccuracy.HIGH, distanceFilter: 0),
        androidSettings: AndroidSettings(
            accuracy: LocationAccuracy.HIGH,
            interval: 1,
            distanceFilter: 0,
            client: LocationClient.android,
            androidNotificationSettings: AndroidNotificationSettings(
                notificationChannelName: 'Location tracking',
                notificationTitle: 'Start Location Tracking',
                notificationMsg: 'Track location in background',
                notificationBigMsg:
                    'Background location is on to keep the app up-tp-date with your location. This is required for main features to work properly when the app is not running.',
                notificationIcon: '',
                notificationIconColor: Colors.grey,
                notificationTapCallback:
                    LocationCallbackHandler.notificationCallback)));
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // startLocationService();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            IconButton(
                onPressed: () async {
                  final androidInfo = await DeviceInfoPlugin().androidInfo;
                  final sdk = androidInfo.version.sdkInt;

                  IsolateNameServer.registerPortWithName(
                      port.sendPort, _isolateName);
                  port.listen((dynamic data) {
                    // do something with data
                    print("Listening Ports $data");
                  });
                  await BackgroundLocator.initialize();
                  startLocationService();
                },
                icon: Icon(Icons.add)),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: AnimatedContainer(
                duration: const Duration(seconds: 2),
                transformAlignment: FractionalOffset.center,
                transform: Matrix4.identity()
                  ..setEntry(0, 2, 0.009)
                  ..rotateZ((math.pi / 180) * 0),
                height: 50,
                width: 50,
                color: Colors.purple,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LocationCallbackHandler {
  static Future<void> initCallback(Map<dynamic, dynamic> params) async {
    developer.log("My Callback init ${params}");
    LocationServiceRepository myLocationCallbackRepository =
        LocationServiceRepository();
    await myLocationCallbackRepository.init(params);
  }

  static Future<void> disposeCallback() async {
    developer.log("My Callback dispose");
    LocationServiceRepository myLocationCallbackRepository =
        LocationServiceRepository();
    await myLocationCallbackRepository.dispose();
  }

  static Future<void> callback(LocationDto locationDto) async {
    developer.log("My Callback background ${locationDto}");
    LocationServiceRepository myLocationCallbackRepository =
        LocationServiceRepository();
    await myLocationCallbackRepository.callback(locationDto);
  }

  static Future<void> notificationCallback() async {
    developer.log("My Callback notification");
    print('***notificationCallback');
  }
}

class LocationServiceRepository {
  static LocationServiceRepository _instance = LocationServiceRepository._();

  LocationServiceRepository._();

  factory LocationServiceRepository() {
    return _instance;
  }

  static const String isolateName = 'LocatorIsolate';

  int _count = -1;

  Future<void> init(Map<dynamic, dynamic> params) async {
    //TODO change logs
    print("***********Init callback handler");
    if (params.containsKey('countInit')) {
      dynamic tmpCount = params['countInit'];
      if (tmpCount is double) {
        _count = tmpCount.toInt();
      } else if (tmpCount is String) {
        _count = int.parse(tmpCount);
      } else if (tmpCount is int) {
        _count = tmpCount;
      } else {
        _count = -2;
      }
    } else {
      _count = 0;
    }
    print("$_count");
    print("Location Data Start");
    final dynamic send = IsolateNameServer.lookupPortByName(isolateName);
    send?.send(null);
  }

  Future<void> dispose() async {
    print("***********Dispose callback handler");
    print("$_count");
    print("Location Data ${_count} Counbter");
    final dynamic send = IsolateNameServer.lookupPortByName(isolateName);
    send?.send(null);
  }

  Future<void> callback(LocationDto locationDto) async {
    print('$_count location in dart: ${locationDto.toString()}');
    print("Location Data ${locationDto}");
    final dynamic send = IsolateNameServer.lookupPortByName(isolateName);
    send?.send(locationDto);
    _count++;
  }
}
