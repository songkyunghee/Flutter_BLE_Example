import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title:'Title',
      home: ConnectingPage(),
    );
  }
}

class ConnectingPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => ConnectingPageState();
}

class ConnectingPageState extends State<ConnectingPage> {
  String connectionText = "Bluetooth Disconnect";
  final String CHARACTERISTIC_UUID = "0000ffe1-0000-1000-8000-00805f9b34fb";
  final String TARGET_DEVICE_NAME = "KLIEN";

  FlutterBlue flutterBlue = FlutterBlue.instance;
  BluetoothDevice targetDevice;
  BluetoothCharacteristic targetCharacteristic;
  StreamSubscription<ScanResult> scanSubScription;

  List result;
  bool check = false;

  @override
  void initState() {

    flutterBlue.scanResults.listen((results) {
      print("검색 중...");
      print("results : $results");
      if(results.isNotEmpty) {
        setState(() {
          result = results;
        });
      }
    });

    flutterBlue.connectedDevices
    .asStream()
    .listen((List<BluetoothDevice> devices) {
      for(BluetoothDevice device in devices) {
        print("device : $device.name");
      }
    });
    super.initState();
  }

  Future blueBtn() async {
    setState(() {
      connectionText = "Start Scanning";
    });

    scanSubScription = flutterBlue.scan().listen((scanResult) {
      if(scanResult.device.name == TARGET_DEVICE_NAME) {
        print('DEVICE found');
        stopScan();
        setState(() {
          connectionText = "Found Target Device";
        });
        targetDevice = scanResult.device;

        connectToDevice(scanResult);
      }
    },onDone: () => stopScan());

    await Future.delayed(Duration(seconds: 13), () async {
      await flutterBlue.stopScan();
      setState(() {
        if(this.result == null) connectionText = "대기중...";
      });
    });
    return;
  }

  stopScan() {
    scanSubScription?.cancel();
    scanSubScription = null;
  }

  connectToDevice(ScanResult scanResult) async {
    if(targetDevice == null) return;
    setState(() {
      connectionText = "Device Connecting";
    });
    await targetDevice.connect();
    print('DEVICE CONNECTED');
    print('$scanResult');
    List<BluetoothService> services = await targetDevice.discoverServices();
    services.forEach((service) {
      print("Service = ${service.uuid}");
      List<BluetoothCharacteristic> blueChar = service.characteristics;
      blueChar.forEach((f) {
        print("Characteristic = ${f.uuid}");
      });
    });
    setState(() {
      check = true;
      connectionText = "Device Connected";
    });
  }

  @override
  Widget build(BuildContext context) {
   return MaterialApp(
     home: Scaffold(
       backgroundColor: Colors.white38,
       body: Column(
         children: <Widget>[
           Expanded(
             child: Container(
               alignment: Alignment.center,
               child: Icon(
                 Icons.bluetooth_searching,
                 size: 160.0,
                 color:Colors.lightBlue,
               ))),
           Container(
             width: 200,
             height: 50,
             color: Colors.white70,
             alignment: Alignment(0,0),
             child: Text(
               connectionText,
               style: Theme.of(context)
                 .primaryTextTheme
                 .subtitle1
                 .copyWith(color: check? Colors.green : Colors.red, fontSize: 18.0, fontWeight: FontWeight.bold),
             )), new Expanded(
               child:new Align(
                 alignment: Alignment.bottomCenter,
                 child: Container(
                   padding: EdgeInsets.only(left: 0, top: 0, bottom: 20),
                   height: 90.0,
                   child: SizedBox(
                     width:300.0,
                     height: 50.0,
                     child:RaisedButton(
                       shape: RoundedRectangleBorder(
                         borderRadius: BorderRadius.circular(18.0)
                       ),
                       child: Text("블루투스 연결하기", style: TextStyle(fontSize: 20.0)),
                       onPressed: this.blueBtn,
                     )),
                 ),
               ))
         ],
       ),
     ),
   );
  }
}




