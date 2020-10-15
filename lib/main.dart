import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:convert/convert.dart';

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
  String recevieData = "No Data";
  final String TARGET_DEVICE_NAME = "KLIEN";

  FlutterBlue flutterBlue = FlutterBlue.instance;
  BluetoothDevice targetDevice;
  BluetoothCharacteristic targetCharacteristic;
  StreamSubscription<ScanResult> scanSubScription;

  Map<Guid, StreamSubscription> valueChangedSubscriptions = {};
  final String CHARACTERISTIC_UUID = "0000ffe1-0000-1000-8000-00805f9b34fb";

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

  void sendButtonPressed() {
    _discoverServices();
    _TurnOnCharacterService();
  }

  _discoverServices() async {
    BluetoothCharacteristic bluetoothCharacteristic;

    List<BluetoothService> services = await targetDevice.discoverServices();
    services.forEach((service) {
      print("${service.uuid}");
      List<BluetoothCharacteristic> blueChar = service.characteristics;
      blueChar.forEach((f) {
        print("Characteristic = ${f.uuid}");
        if(f.uuid.toString().compareTo(CHARACTERISTIC_UUID) == 0)
        {
          bluetoothCharacteristic = f;
        }
      });
    });

      await bluetoothCharacteristic.write(
          [0x4B, 0x01, 0x4E], withoutResponse: true);
      await Future.delayed(Duration(milliseconds:  200));

  }

  _TurnOnCharacterService() async {
    List<BluetoothService> services = await targetDevice.discoverServices();
    services.forEach((service) {
      service.characteristics.forEach((character) {
        if(character.uuid.toString() == CHARACTERISTIC_UUID) {
          _setNotification(character);
        }
      });
    });
  }

  _setNotification(BluetoothCharacteristic bluetoothCharacteristic) async {
    if(bluetoothCharacteristic.isNotifying) {
      await bluetoothCharacteristic.setNotifyValue(false);

      valueChangedSubscriptions[bluetoothCharacteristic.uuid]?.cancel();
      valueChangedSubscriptions.remove(bluetoothCharacteristic.uuid);
    } else {
        await bluetoothCharacteristic.setNotifyValue(true);
        final sub = bluetoothCharacteristic.value.listen((value) {
          setState(() {
            print('onValueChanged $value');
            var data = hex.encode(value);
            print('$data');
            recevieData = data;
          });
        });
    }
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
             width: 235,
             height: 50,
             color: Colors.white70,
             alignment: Alignment(0,0),
             child: Text(
               connectionText,
               style: Theme.of(context)
                 .primaryTextTheme
                 .subtitle1
                 .copyWith(color: check? Colors.green : Colors.red, fontSize: 18.0, fontWeight: FontWeight.bold),
             )),
           Padding(padding: EdgeInsets.all(10)),
          Container(
            width: 235,
            height: 50,
            color: Colors.white70,
            alignment: Alignment(0,0),
            child: Text(
              recevieData,
              style: Theme.of(context)
              .primaryTextTheme
              .subtitle1
              .copyWith(color: Colors.black, fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
          ),
           Padding(padding: EdgeInsets.all(70)),
          SizedBox(
                     width:300.0,
                     height: 70.0,
                     child:RaisedButton(
                       shape: RoundedRectangleBorder(
                         borderRadius: BorderRadius.circular(18.0)
                       ),
                       child: Text("블루투스 연결하기", style: TextStyle(fontSize: 20.0)),
                       onPressed: this.blueBtn,
                     ),
                 ),
           Padding(padding: EdgeInsets.all(10)),
            SizedBox(
                       width:300.0,
                       height: 70.0,
                       child:RaisedButton(
                         shape: RoundedRectangleBorder(
                             borderRadius: BorderRadius.circular(18.0)
                         ),
                         child: Text("데이터 보내기", style: TextStyle(fontSize: 20.0)),
                         onPressed: sendButtonPressed,
                       )),
           Padding(padding: EdgeInsets.all(15)),
         ],
       ),
     ),
   );
  }
}




